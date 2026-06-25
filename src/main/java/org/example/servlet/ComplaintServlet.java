package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Complaint;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.ComplaintMapper;
import org.example.mapper.OrderMapper;
import org.example.mapper.UserMapper;
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
 * 投诉 Servlet（用户端）
 *
 * URL 模式：/complaint?action=xxx
 *   - GET  /complaint?action=list&role=complainant|respondent|all&status=&page=   → 我的投诉（JSP）
 *   - GET  /complaint?action=for-order&orderNo=                                    → 查某订单当前用户是否已投诉（JSON，订单详情页用）
 *   - POST /complaint?action=submit                                                → 提交投诉（JSON）
 *
 * 业务规则：
 *   - 投诉必须关联已存在的订单
 *   - 投诉人必须是订单的 buyer 或 seller
 *   - 被投诉人 = 对方
 *   - 同一订单同一投诉人只能一次（业务层 + UNIQUE 索引双保险）
 *   - 状态流转：0待处理 → 1处理中 → 2已处理 / 3已驳回（管理员控制）
 */
@WebServlet("/complaint")
public class ComplaintServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":
                showList(req, resp);
                break;
            case "for-order":
                getForOrder(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/complaint?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "submit":
                doSubmit(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 我的投诉列表 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/complaint?action=list", "UTF-8"));
            return;
        }

        String role = req.getParameter("role");
        if (role == null) role = "complainant";   // 默认"我发起的"
        if (!"complainant".equals(role) && !"respondent".equals(role) && !"all".equals(role)) {
            role = "complainant";
        }
        Integer statusFilter = parseIntOrNull(req.getParameter("status"));
        String keyword = req.getParameter("keyword");
        int pageNo = 1;
        try { pageNo = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (pageNo < 1) pageNo = 1;
        int pageSize = 10;
        int offset = (pageNo - 1) * pageSize;

        List<Map<String, Object>> rows = new ArrayList<>();
        int total = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            ComplaintMapper mapper = session.getMapper(ComplaintMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("userId", user.getId());
            params.put("role", role);
            params.put("status", statusFilter);
            params.put("keyword", keyword == null ? null : keyword.trim());
            params.put("offset", offset);
            params.put("limit", pageSize);

            List<Complaint> complaints = mapper.findByCondition(params);
            total = mapper.countByCondition(params);

            for (Complaint c : complaints) {
                OrderInfo order = orderMapper.findById(c.getOrderId());
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

        req.setAttribute("rowsJson", safeToJson(rows));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("role", role);
        req.setAttribute("statusFilter", statusFilter);
        req.setAttribute("keyword", keyword == null ? "" : keyword);
        req.getRequestDispatcher("/WEB-INF/jsp/complaint/list.jsp").forward(req, resp);
    }

    // ============ 查某订单当前用户是否已投诉 ============

    private void getForOrder(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("缺少订单号")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            ComplaintMapper complaintMapper = session.getMapper(ComplaintMapper.class);

            OrderInfo order = orderMapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }
            if (!order.getBuyerId().equals(user.getId()) && !order.getSellerId().equals(user.getId())) {
                writeJson(resp, errorOf("无权查看此订单"));
                return;
            }

            Complaint existing = complaintMapper.findByOrderAndComplainant(order.getId(), user.getId());

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("orderNo", order.getOrderNo());
            data.put("complained", existing != null);
            if (existing != null) {
                data.put("complaintId", existing.getId());
                data.put("status", existing.getStatus());
                data.put("statusText", existing.getStatusText());
                data.put("reason", existing.getReason());
                data.put("handleResult", existing.getHandleResult());
            }
            // 被投诉人 = 对方
            data.put("respondentId",
                    order.getBuyerId().equals(user.getId()) ? order.getSellerId() : order.getBuyerId());
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "查订单投诉"));
        }
    }

    // ============ 提交投诉 ============

    private void doSubmit(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        String reason = req.getParameter("reason");
        String evidence = req.getParameter("evidence");

        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("缺少订单号")); return; }
        if (reason == null || reason.trim().isEmpty()) { writeJson(resp, errorOf("请填写投诉原因")); return; }
        if (reason.trim().length() > 500) { writeJson(resp, errorOf("投诉原因不超过 500 字")); return; }
        if (evidence != null && evidence.length() > 500) {
            writeJson(resp, errorOf("证据 URL 不超过 500 字"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            ComplaintMapper complaintMapper = session.getMapper(ComplaintMapper.class);

            OrderInfo order = orderMapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }

            // 必须是订单的买家或卖家
            boolean isBuyer = order.getBuyerId().equals(user.getId());
            boolean isSeller = order.getSellerId().equals(user.getId());
            if (!isBuyer && !isSeller) {
                writeJson(resp, errorOf("只有订单的买家或卖家才能投诉"));
                return;
            }

            // 被投诉人 = 对方
            Integer respondentId = isBuyer ? order.getSellerId() : order.getBuyerId();

            // 不能投诉自己
            if (respondentId.equals(user.getId())) {
                writeJson(resp, errorOf("不能投诉自己"));
                return;
            }

            // 唯一性
            Complaint existing = complaintMapper.findByOrderAndComplainant(order.getId(), user.getId());
            if (existing != null) {
                writeJson(resp, errorOf("此订单你已经投诉过，请勿重复提交"));
                return;
            }

            Complaint c = new Complaint();
            c.setOrderId(order.getId());
            c.setComplainantId(user.getId());
            c.setRespondentId(respondentId);
            c.setReason(reason.trim());
            c.setEvidence(evidence == null || evidence.trim().isEmpty() ? null : evidence.trim());
            c.setStatus(0);
            complaintMapper.insert(c);
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "投诉已提交，管理员将在 1-3 个工作日内处理");
            data.put("complaintId", c.getId());
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "提交投诉"));
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
