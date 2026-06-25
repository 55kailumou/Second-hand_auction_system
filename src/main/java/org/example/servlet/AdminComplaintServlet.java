package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.Complaint;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.ComplaintMapper;
import org.example.mapper.OrderMapper;
import org.example.mapper.UserMapper;
import org.example.service.MessageService;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 - 投诉审批 Servlet
 *
 * URL 模式：/admin/complaint
 *   - GET  /admin/complaint?action=list&status=&page=  → 投诉列表（JSP，受 AdminAuthFilter 保护）
 *   - POST /admin/complaint?action=process              → 处理投诉（JSON）
 *     参数：id, status (2=已处理 / 3=已驳回), result
 *
 * 业务约束：
 *   - 状态流转：0待处理 → 1处理中 → 2已处理 / 3已驳回
 *   - 处理时强制把 status 从 0/1 → 2/3（乐观锁：SQL WHERE status IN (0, 1)）
 *   - 处理后通过 MessageService 通知投诉人
 */
@WebServlet("/admin/complaint")
public class AdminComplaintServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";
        if (!"list".equals(action)) {
            resp.sendRedirect(req.getContextPath() + "/admin/complaint?action=list");
            return;
        }
        showList(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "process":
                doProcess(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        Integer status = parseIntOrNull(req.getParameter("status"));
        String keyword = req.getParameter("keyword");
        int pageNo = 1;
        try { pageNo = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (pageNo < 1) pageNo = 1;
        int pageSize = 10;
        int offset = (pageNo - 1) * pageSize;

        List<Map<String, Object>> rows = new ArrayList<>();
        int total = 0;
        int pendingCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            ComplaintMapper mapper = session.getMapper(ComplaintMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("userId", null);   // admin 看全部
            params.put("role", "all");
            params.put("status", status);
            params.put("keyword", keyword == null ? null : keyword.trim());
            params.put("offset", offset);
            params.put("limit", pageSize);

            List<Complaint> complaints = mapper.findByCondition(params);
            total = mapper.countByCondition(params);
            pendingCount = mapper.countPending();

            for (Complaint c : complaints) {
                OrderInfo order = orderMapper.findById(c.getOrderId());
                User complainant = userMapper.findById(c.getComplainantId());
                User respondent = userMapper.findById(c.getRespondentId());

                Map<String, Object> row = new HashMap<>();
                row.put("id", c.getId());
                row.put("orderId", c.getOrderId());
                row.put("orderNo", order == null ? "未知" : order.getOrderNo());
                row.put("itemTitle", order == null ? "(订单已删除)" : order.getItemTitle());
                row.put("coverImage", order == null ? null : order.getCoverImage());
                row.put("reason", c.getReason());
                row.put("evidence", c.getEvidence());
                row.put("status", c.getStatus());
                row.put("statusText", c.getStatusText());
                row.put("complainantId", c.getComplainantId());
                row.put("complainantUsername", complainant == null ? "用户#" + c.getComplainantId() : complainant.getUsername());
                row.put("respondentId", c.getRespondentId());
                row.put("respondentUsername", respondent == null ? "用户#" + c.getRespondentId() : respondent.getUsername());
                row.put("handleResult", c.getHandleResult());
                row.put("createTime", c.getCreateTime());
                row.put("handleTime", c.getHandleTime());
                rows.add(row);
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "投诉列表");
            req.setAttribute("error", "加载投诉列表失败，请稍后重试");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("admin", admin);
        req.setAttribute("rowsJson", safeToJson(rows));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("status", status);
        req.setAttribute("keyword", keyword == null ? "" : keyword);
        req.setAttribute("pendingCount", pendingCount);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/complaints.jsp").forward(req, resp);
    }

    private void doProcess(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer targetStatus = parseIntOrNull(req.getParameter("status"));
        String result = req.getParameter("result");

        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (targetStatus == null || (targetStatus != 2 && targetStatus != 3)) {
            writeJson(resp, errorOf("处理结果必须为 2（已处理）或 3（已驳回）"));
            return;
        }
        if (result == null || result.trim().isEmpty()) {
            result = "管理员 " + admin.getAdminName() + " 已处理";
        }
        if (result.length() > 500) { writeJson(resp, errorOf("处理结果不超过 500 字")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            ComplaintMapper mapper = session.getMapper(ComplaintMapper.class);
            Complaint c = mapper.findById(id);
            if (c == null) { writeJson(resp, errorOf("投诉不存在")); return; }
            if (c.getStatus() == null || (c.getStatus() != 0 && c.getStatus() != 1)) {
                writeJson(resp, errorOf("只有待处理（0）或处理中（1）的投诉才能处理"));
                return;
            }

            int rows = mapper.processComplaint(id, targetStatus, admin.getId(), result.trim());
            session.commit();
            if (rows > 0) {
                // 通知投诉人
                String title = targetStatus == 2 ? "您的投诉已处理" : "您的投诉已驳回";
                String content = "投诉 #" + id + "（订单 " + c.getOrderId() + "）" +
                        (targetStatus == 2 ? "已处理" : "已驳回") + "。处理说明：" + result.trim();
                MessageService.send(c.getComplainantId(), MessageService.TYPE_AUDIT_RESULT,
                        title, content, c.getOrderId());

                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", targetStatus == 2 ? "已处理" : "已驳回");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("处理失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "处理投诉"));
        }
    }

    // ============ 工具 ============

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String safeToJson(Object obj) {
        try { return JSON.writeValueAsString(obj); }
        catch (Exception e) { ResponseUtil.handleException(e, "JSON 序列化"); return "[]"; }
    }

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(JSON.writeValueAsString(obj));
        out.flush();
    }

    private Map<String, Object> errorOf(String msg) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", false);
        r.put("message", msg);
        return r;
    }
}
