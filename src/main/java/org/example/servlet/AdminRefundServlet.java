package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.OrderMapper;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;
import org.example.service.MessageService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理员 - 退款审批 Servlet
 *
 * URL 模式：/admin/refund
 *   - GET  /admin/refund?action=list&status=&keyword=&page=  → 退款审批列表（JSP，受 AdminAuthFilter 保护）
 *   - POST /admin/refund?action=approve                      → 同意退款 status 4→5（JSON）
 *   - POST /admin/refund?action=reject                       → 驳回退款 status 4→1（JSON）
 *
 * 业务约束：
 *   - 同意退款：order.status 必须为 4（申请退款中）
 *   - 驳回退款：order.status 必须为 4（申请退款中）
 *   - 同意后 → 状态 5 已退款（实际操作中需要外部支付通道配合退款，本项目标记状态即可）
 */
@WebServlet("/admin/refund")
public class AdminRefundServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";
        if (!"list".equals(action)) {
            resp.sendRedirect(req.getContextPath() + "/admin/refund?action=list");
            return;
        }
        showList(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "approve":
                doApprove(req, resp);
                break;
            case "reject":
                doReject(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 列表页 ============

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

        // 默认：4 待审核 / 5 已完成 / null 全部
        Map<String, Object> params = new HashMap<>();
        params.put("status", status);   // null = 全部（4+5）
        params.put("keyword", keyword == null ? null : keyword.trim());
        params.put("offset", offset);
        params.put("limit", pageSize);

        List<Map<String, Object>> rows = new ArrayList<>();
        int total = 0;
        int pendingCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);

            List<OrderInfo> orders = orderMapper.findRefundByCondition(params);
            total = orderMapper.countRefundByCondition(params);
            pendingCount = orderMapper.countPendingRefund();

            for (OrderInfo o : orders) {
                Map<String, Object> row = new HashMap<>();
                row.put("orderId", o.getId());
                row.put("orderNo", o.getOrderNo());
                row.put("itemId", o.getItemId());
                row.put("itemTitle", o.getItemTitle());
                row.put("coverImage", o.getCoverImage());
                row.put("finalPrice", o.getFinalPrice());
                row.put("status", o.getStatus());
                row.put("buyerId", o.getBuyerId());
                row.put("sellerId", o.getSellerId());
                row.put("refundReason", o.getRefundReason());
                row.put("refundAuditTime", o.getRefundAuditTime());
                row.put("refundAuditResult", o.getRefundAuditResult());
                row.put("createTime", o.getCreateTime());
                row.put("payTime", o.getPayTime());
                row.put("deliverTime", o.getDeliverTime());

                // 买家信息
                User buyer = userMapper.findById(o.getBuyerId());
                row.put("buyerUsername", buyer == null ? "用户#" + o.getBuyerId() : buyer.getUsername());

                rows.add(row);
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "退款列表");
            req.setAttribute("error", "加载退款列表失败，请稍后重试");
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
        req.getRequestDispatcher("/WEB-INF/jsp/admin/refunds.jsp").forward(req, resp);
    }

    // ============ 同意退款（4→5，平台账户 → 买家余额） ============

    private void doApprove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员账号")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        String result = req.getParameter("result");
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (result == null || result.trim().isEmpty()) {
            result = "管理员 " + admin.getAdminName() + " 同意退款";
        }
        if (result.length() > 500) { writeJson(resp, errorOf("审核结果不超过 500 字")); return; }

        // 调 PayService：平台账户 -= finalPrice → 买家余额 += finalPrice → order.status 4→5
        Map<String, Object> r = org.example.service.PayService.refundToBuyer(id, result.trim(), true);

        if (Boolean.TRUE.equals(r.get("success"))) {
            // 查订单给买家发通知
            try (SqlSession session = MyBatisUtil.openSession()) {
                OrderMapper mapper = session.getMapper(OrderMapper.class);
                OrderInfo o = mapper.findById(id);
                if (o != null) {
                    MessageService.send(o.getBuyerId(), MessageService.TYPE_AUDIT_RESULT,
                            "退款已通过",
                            "订单 " + o.getOrderNo() + "（" + o.getItemTitle() +
                                    "）的退款申请已通过，¥" + o.getFinalPrice().toPlainString() +
                                    " 已退回您的账户余额。审核说明：" + result.trim(),
                            o.getId());
                    // 同时通知卖家
                    MessageService.send(o.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                            "订单已退款",
                            "订单 " + o.getOrderNo() + "（" + o.getItemTitle() +
                                    "）买家已退款 ¥" + o.getFinalPrice().toPlainString() +
                                    "，从平台账户出。审核说明：" + result.trim(),
                            o.getId());
                }
            } catch (Exception ex) { ex.printStackTrace(); }
        }

        writeJson(resp, r);
    }

    // ============ 驳回退款（4→1） ============

    private void doReject(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员账号")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        String result = req.getParameter("result");
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (result == null || result.trim().isEmpty()) {
            result = "管理员 " + admin.getAdminName() + " 驳回退款";
        }
        if (result.length() > 500) { writeJson(resp, errorOf("审核结果不超过 500 字")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);
            OrderInfo o = mapper.findById(id);
            if (o == null) { writeJson(resp, errorOf("订单不存在")); return; }
            if (o.getStatus() == null || o.getStatus() != 4) {
                writeJson(resp, errorOf("只有申请退款中（status=4）的订单才能审核"));
                return;
            }
            int rows = mapper.markRefundRejected(id, result.trim());
            session.commit();
            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "已驳回退款，订单状态回到「已付款」");
                writeJson(resp, data);

                // 通知买家：退款已驳回（独立事务）
                MessageService.send(o.getBuyerId(), MessageService.TYPE_AUDIT_RESULT,
                        "退款已驳回",
                        "订单 " + o.getOrderNo() + "（" + o.getItemTitle() +
                                "）的退款申请已驳回，订单回到「已付款」状态。审核说明：" + result.trim(),
                        o.getId());
            } else {
                writeJson(resp, errorOf("操作失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "驳回退款"));
        }
    }

    // ============ 工具方法 ============

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
