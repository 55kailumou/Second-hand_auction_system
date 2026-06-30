package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.example.entity.AuctionItem;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.service.PayService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * 支付 Servlet（统一处理模拟支付和真实余额支付）
 *
 * URL 模式：/payment?action=xxx
 *   - GET  /payment?action=sim&type=deposit&itemId=xx&method=alipay|wechat
 *        → 显示模拟支付收银台（alipay_sim.jsp / wechat_sim.jsp）
 *   - GET  /payment?action=sim&type=final&orderNo=xx&method=alipay|wechat
 *        → 显示模拟支付收银台（支付尾款）
 *   - POST /payment?action=callback
 *        → 模拟支付页面"确认支付"按钮调用，走 PayService 实际扣款 → 跳到结果页
 *   - GET  /payment?action=result&type=xxx&status=success|fail&...
 *        → 支付结果展示页
 *   - POST /payment?action=final&orderNo=xx&method=balance
 *        → 余额支付尾款（不走模拟）
 *   - POST /payment?action=deposit&itemId=xx&method=balance
 *        → 余额支付押金（直接走，不走模拟。其实在 DepositServlet 已处理，留作接口统一）
 */
@WebServlet("/payment")
public class PaymentCallbackServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "sim":
                showSimPage(req, resp);
                break;
            case "result":
                showResult(req, resp);
                break;
            case "ledger":
                showLedger(req, resp);
                break;
            default:
                resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "unknown action");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "callback":
                doCallback(req, resp);
                break;
            case "cancel":
                doCancel(req, resp);
                break;
            default:
                doGet(req, resp);
        }
    }

    // ===================== 显示模拟支付页 =====================

    private void showSimPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login");
            return;
        }

        String type = req.getParameter("type");   // deposit / final
        String method = req.getParameter("method"); // alipay / wechat
        if (type == null) type = "deposit";
        if (method == null) method = "alipay";

        // 取金额
        BigDecimal amount = null;
        String title = "";
        String itemTitle = "";
        String orderNo = null;
        Integer itemId = null;

        if ("deposit".equals(type)) {
            Integer itemIdParam = parseIntOrNull(req.getParameter("itemId"));
            if (itemIdParam == null) { resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "itemId 必填"); return; }
            AuctionItem item = null;
            try {
                org.apache.ibatis.session.SqlSession session = org.example.util.MyBatisUtil.openSession();
                org.example.mapper.AuctionItemMapper itemMapper = session.getMapper(org.example.mapper.AuctionItemMapper.class);
                item = itemMapper.findById(itemIdParam);
                session.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            if (item == null) { resp.sendError(HttpServletResponse.SC_NOT_FOUND, "拍品不存在"); return; }
            amount = item.getDeposit();
            title = "缴纳参拍押金";
            itemTitle = item.getTitle();
            itemId = itemIdParam;
        } else if ("final".equals(type)) {
            orderNo = req.getParameter("orderNo");
            if (orderNo == null) { resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "orderNo 必填"); return; }
            OrderInfo order = null;
            try {
                org.apache.ibatis.session.SqlSession session = org.example.util.MyBatisUtil.openSession();
                org.example.mapper.OrderMapper orderMapper = session.getMapper(org.example.mapper.OrderMapper.class);
                order = orderMapper.findByOrderNo(orderNo);
                session.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            if (order == null) { resp.sendError(HttpServletResponse.SC_NOT_FOUND, "订单不存在"); return; }
            if (!order.getBuyerId().equals(user.getId())) { resp.sendError(HttpServletResponse.SC_FORBIDDEN, "无权操作"); return; }
            amount = order.getFinalPayAmount();
            if (amount == null) amount = order.getFinalPrice();
            title = "支付尾款";
            itemTitle = order.getItemTitle();
            itemId = order.getItemId();
        }

        if (amount == null) amount = BigDecimal.ZERO;

        // 给 JSP 的参数
        req.setAttribute("type", type);
        req.setAttribute("method", method);
        req.setAttribute("amount", amount.toPlainString());
        req.setAttribute("title", title);
        req.setAttribute("itemTitle", itemTitle);
        req.setAttribute("itemId", itemId == null ? "" : itemId.toString());
        req.setAttribute("orderNo", orderNo == null ? "" : orderNo);

        // 跳到对应的模拟支付页
        if ("alipay".equals(method)) {
            req.getRequestDispatcher("/WEB-INF/jsp/pay/alipay_sim.jsp").forward(req, resp);
        } else if ("wechat".equals(method)) {
            req.getRequestDispatcher("/WEB-INF/jsp/pay/wechat_sim.jsp").forward(req, resp);
        } else {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "不支持的支付方式");
        }
    }

    // ===================== 模拟支付回调 =====================

    private void doCallback(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login");
            return;
        }

        String type = req.getParameter("type");      // deposit / final
        String method = req.getParameter("method");  // alipay / wechat
        String tradeNo = req.getParameter("tradeNo"); // 模拟的交易号（前端生成）
        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        String orderNo = req.getParameter("orderNo");

        if (type == null) type = "deposit";
        if (method == null) method = "alipay";

        Map<String, Object> r = new HashMap<>();

        if ("deposit".equals(type)) {
            if (itemId == null) {
                failRedirect(req, resp, "参数错误");
                return;
            }
            // 走 PayService 缴押金（不扣余额，记"平台代收"）
            r = PayService.payDeposit(user.getId(), itemId, method);
        } else if ("final".equals(type)) {
            if (orderNo == null) {
                failRedirect(req, resp, "参数错误");
                return;
            }
            // 查订单 → 调 payFinal
            try (org.apache.ibatis.session.SqlSession session = org.example.util.MyBatisUtil.openSession()) {
                org.example.mapper.OrderMapper orderMapper = session.getMapper(org.example.mapper.OrderMapper.class);
                OrderInfo order = orderMapper.findByOrderNo(orderNo);
                if (order == null) { failRedirect(req, resp, "订单不存在"); return; }
                r = PayService.payFinal(order.getId(), method);
                // 付款成功 → 通知卖家发货（独立事务，失败不影响主流程）
                if (Boolean.TRUE.equals(r.get("success"))) {
                    try {
                        org.example.service.MessageService.send(order.getSellerId(),
                                org.example.service.MessageService.TYPE_ORDER_STATUS,
                                "买家已付款，请尽快发货",
                                "订单 " + order.getOrderNo() + "（" + order.getItemTitle() +
                                        "）买家已支付 ¥" + order.getFinalPrice().toPlainString() + "，请尽快发货",
                                order.getId());
                    } catch (Exception ex) { ex.printStackTrace(); }
                }
            }
        } else {
            failRedirect(req, resp, "unknown type");
            return;
        }

        // 跳到结果页
        StringBuilder url = new StringBuilder(req.getContextPath())
                .append("/payment?action=result&type=").append(type)
                .append("&status=").append(Boolean.TRUE.equals(r.get("success")) ? "success" : "fail")
                .append("&message=").append(java.net.URLEncoder.encode(
                        String.valueOf(r.get("message")), "UTF-8"));
        if (itemId != null) url.append("&itemId=").append(itemId);
        if (orderNo != null) url.append("&orderNo=").append(orderNo);
        resp.sendRedirect(url.toString());
    }

    // ===================== 用户取消支付 =====================

    private void doCancel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String type = req.getParameter("type");
        String itemId = req.getParameter("itemId");
        String orderNo = req.getParameter("orderNo");

        StringBuilder url = new StringBuilder(req.getContextPath())
                .append("/payment?action=result&type=").append(type == null ? "deposit" : type)
                .append("&status=cancel")
                .append("&message=").append(java.net.URLEncoder.encode("您已取消支付", "UTF-8"));
        if (itemId != null) url.append("&itemId=").append(itemId);
        if (orderNo != null) url.append("&orderNo=").append(orderNo);
        resp.sendRedirect(url.toString());
    }

    // ===================== 支付结果页 =====================

    private void showResult(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String type = req.getParameter("type");
        String status = req.getParameter("status");
        String message = req.getParameter("message");
        String itemId = req.getParameter("itemId");
        String orderNo = req.getParameter("orderNo");

        if (type == null) type = "deposit";
        if (status == null) status = "fail";
        if (message == null) message = "";

        req.setAttribute("type", type);
        req.setAttribute("status", status);
        req.setAttribute("message", message);
        req.setAttribute("itemId", itemId);
        req.setAttribute("orderNo", orderNo);
        req.getRequestDispatcher("/WEB-INF/jsp/pay/result.jsp").forward(req, resp);
    }

    // ===================== 账户流水（个人中心） =====================

    private void showLedger(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/user?action=login"); return; }

        Integer type = null;
        String typeStr = req.getParameter("type");
        if (typeStr != null && !typeStr.isEmpty()) {
            try { type = Integer.parseInt(typeStr); } catch (Exception ignored) {}
        }
        int page = 1;
        try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (page < 1) page = 1;
        int pageSize = 20;
        int offset = (page - 1) * pageSize;

        try (org.apache.ibatis.session.SqlSession session = org.example.util.MyBatisUtil.openSession()) {
            org.example.mapper.PaymentRecordMapper mapper =
                    session.getMapper(org.example.mapper.PaymentRecordMapper.class);
            org.example.mapper.UserMapper userMapper =
                    session.getMapper(org.example.mapper.UserMapper.class);
            org.example.mapper.SystemAccountMapper saMapper =
                    session.getMapper(org.example.mapper.SystemAccountMapper.class);

            java.util.Map<String, Object> params = new java.util.HashMap<>();
            params.put("userId", user.getId());
            params.put("type", type);
            params.put("offset", offset);
            params.put("limit", pageSize);
            java.util.List<org.example.entity.PaymentRecord> records = mapper.findByUserIdPaged(params);
            int total = mapper.countByUserId(params);
            int totalPages = (total + pageSize - 1) / pageSize;

            org.example.entity.User freshUser = userMapper.findById(user.getId());
            org.example.entity.SystemAccount sa = saMapper.get();

            req.setAttribute("records", records);
            req.setAttribute("total", total);
            req.setAttribute("page", page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("type", type);
            req.setAttribute("balance", freshUser == null ? java.math.BigDecimal.ZERO : freshUser.getBalance());
            req.setAttribute("platformBalance", sa == null ? java.math.BigDecimal.ZERO : sa.getBalance());
            req.getRequestDispatcher("/WEB-INF/jsp/pay/ledger.jsp").forward(req, resp);
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "加载流水失败：" + e.getMessage());
        }
    }

    // ===================== 工具 =====================

    private void failRedirect(HttpServletRequest req, HttpServletResponse resp, String msg) throws IOException {
        String url = req.getContextPath() + "/payment?action=result&status=fail&message=" +
                java.net.URLEncoder.encode(msg, "UTF-8");
        resp.sendRedirect(url);
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }
}
