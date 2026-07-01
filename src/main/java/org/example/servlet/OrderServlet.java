package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Address;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.AddressMapper;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.mapper.OrderMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;
import org.example.service.MessageService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 订单 Servlet：中标 → 创建订单 → 付款 → 发货 → 收货 全流程
 *
 * URL 模式：/order?action=xxx
 *   - GET  /order?action=list              → 我的订单列表（JSP）
 *   - GET  /order?action=detail&id=xx      → 订单详情（JSP）
 *   - POST /order?action=create            → 创建订单（中拍后调用，JSON）
 *   - POST /order?action=pay&orderNo=xx    → 付款（JSON）
 *   - POST /order?action=deliver           → 卖家发货，body: orderNo, company, tracking（JSON）
 *   - POST /order?action=confirm-receive   → 买家确认收货（JSON）
 *   - POST /order?action=cancel            → 取消订单（JSON）
 *
 * 地址管理：地址操作放在 UserCenterServlet（个人中心模块），这里只查询。
 */
@WebServlet("/order")
public class OrderServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":
                showOrderList(req, resp);
                break;
            case "detail":
                showOrderDetail(req, resp);
                break;
            case "lookup":
                lookupByOrderNo(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/order?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "create":
                doCreate(req, resp);
                break;
            case "pay":
                doPay(req, resp);
                break;
            case "deliver":
                doDeliver(req, resp);
                break;
            case "confirm-receive":
                doConfirmReceive(req, resp);
                break;
            case "cancel":
                doCancel(req, resp);
                break;
            case "apply-refund":
                doApplyRefund(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 页面渲染 ============

    private void showOrderList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/order?action=list", "UTF-8"));
            return;
        }

        String role = req.getParameter("role");
        if (role == null || role.isEmpty()) role = "buyer";
        if (!"buyer".equals(role) && !"seller".equals(role) && !"all".equals(role)) {
            role = "buyer";
        }
        String statusStr = req.getParameter("status");
        Integer status = (statusStr == null || statusStr.isEmpty()) ? null : parseIntOrNull(statusStr);
        String keyword = req.getParameter("keyword");
        int page = 1;
        try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (page < 1) page = 1;
        int pageSize = 10;
        int offset = (page - 1) * pageSize;

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("userId", user.getId());
            params.put("role", role);
            params.put("status", status);
            params.put("keyword", keyword);
            params.put("offset", offset);
            params.put("limit", pageSize);

            List<OrderInfo> orders = mapper.findByCondition(params);
            int total = mapper.countByCondition(params);
            int totalPages = (total + pageSize - 1) / pageSize;

            req.setAttribute("orders", orders);
            req.setAttribute("total", total);
            req.setAttribute("page", page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("role", role);
            req.setAttribute("status", status);
            req.setAttribute("keyword", keyword);
            req.setAttribute("pageSize", pageSize);
            req.getRequestDispatcher("/WEB-INF/jsp/order/list.jsp").forward(req, resp);
        } catch (Exception e) {
            ResponseUtil.handleException(e, "加载订单列表");
            req.setAttribute("error", "加载订单失败，请稍后重试");
            req.getRequestDispatcher("/WEB-INF/jsp/order/list.jsp").forward(req, resp);
        }
    }

    private void showOrderDetail(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            // 未登录跳登录页，登录后跳回当前 URL（含 query string，如 ?id=123）
            String back = req.getRequestURI();
            String query = req.getQueryString();
            if (query != null) back = back + "?" + query;
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode(back, "UTF-8"));
            return;
        }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            resp.sendRedirect(req.getContextPath() + "/order?action=list");
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            AddressMapper addressMapper = session.getMapper(AddressMapper.class);
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);

            OrderInfo order = orderMapper.findById(id);
            if (order == null) {
                req.setAttribute("error", "订单不存在");
                req.getRequestDispatcher("/WEB-INF/jsp/order/detail.jsp").forward(req, resp);
                return;
            }

            // 权限校验：只有买家/卖家本人能看
            if (!order.getBuyerId().equals(user.getId()) && !order.getSellerId().equals(user.getId())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "无权查看此订单");
                return;
            }

            // 加载地址
            Address address = addressMapper.findById(order.getAddressId());

            // 加载拍品
            AuctionItem item = itemMapper.findById(order.getItemId());

            req.setAttribute("order", order);
            req.setAttribute("address", address);
            req.setAttribute("item", item);
            req.setAttribute("isBuyer", order.getBuyerId().equals(user.getId()));
            req.getRequestDispatcher("/WEB-INF/jsp/order/detail.jsp").forward(req, resp);
        } catch (Exception e) {
            ResponseUtil.handleException(e, "加载订单详情");
            req.setAttribute("error", "加载订单详情失败，请稍后重试");
            req.getRequestDispatcher("/WEB-INF/jsp/order/detail.jsp").forward(req, resp);
        }
    }

    // ============ 根据订单号查 ID（JSON） ============

    private void lookupByOrderNo(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String orderNo = req.getParameter("orderNo");
        Map<String, Object> data = new HashMap<>();
        if (orderNo == null || orderNo.isEmpty()) {
            data.put("success", false);
            data.put("message", "orderNo 必填");
            writeJson(resp, data);
            return;
        }
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);
            OrderInfo order = mapper.findByOrderNo(orderNo);
            if (order == null) {
                data.put("success", false);
                data.put("message", "订单不存在");
            } else {
                data.put("success", true);
                data.put("id", order.getId());
                data.put("status", order.getStatus());
            }
        } catch (Exception e) {
            data.put("success", false);
            data.put("message", e.getMessage());
        }
        writeJson(resp, data);
    }

    // ============ 创建订单 ============

    private void doCreate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        Integer addressId = parseIntOrNull(req.getParameter("addressId"));
        if (itemId == null || addressId == null) { writeJson(resp, errorOf("参数错误")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            AddressMapper addressMapper = session.getMapper(AddressMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            org.example.mapper.DepositMapper depositMapper = session.getMapper(org.example.mapper.DepositMapper.class);

            // 1. 拍品必须存在 + 状态为已成交(2)
            AuctionItem item = itemMapper.findById(itemId);
            if (item == null) { writeJson(resp, errorOf("拍品不存在")); return; }
            if (item.getStatus() == null || item.getStatus() != 2) {
                writeJson(resp, errorOf("该拍品尚未成交，无法下单"));
                return;
            }

            // 2. 必须是最高出价人
            BidRecord winningBid = bidMapper.findCurrentWinning(itemId);
            if (winningBid == null) { writeJson(resp, errorOf("该拍品无人出价")); return; }
            if (!winningBid.getBidderId().equals(user.getId())) {
                writeJson(resp, errorOf("只有中拍人才能下单"));
                return;
            }

            // 3. 地址必须属于当前用户
            Address address = addressMapper.findById(addressId);
            if (address == null || !address.getUserId().equals(user.getId())) {
                writeJson(resp, errorOf("收货地址无效"));
                return;
            }

            // 4. 检查是否已存在订单（避免重复下单）
            Map<String, Object> checkParams = new HashMap<>();
            checkParams.put("userId", user.getId());
            checkParams.put("role", "buyer");
            List<OrderInfo> existing = orderMapper.findByCondition(checkParams);
            for (OrderInfo o : existing) {
                if (o.getItemId().equals(itemId) && o.getStatus() != null && o.getStatus() != 6) {
                    writeJson(resp, errorOf("该拍品已存在订单，请勿重复下单"));
                    return;
                }
            }

            // 5. 计算押金抵用 + 尾款
            org.example.entity.Deposit winnerDeposit = depositMapper.findByUserAndItem(user.getId(), itemId);
            java.math.BigDecimal depositAmount = java.math.BigDecimal.ZERO;
            if (winnerDeposit != null
                    && winnerDeposit.getStatus() != null
                    && winnerDeposit.getStatus() == 1) {
                depositAmount = winnerDeposit.getAmount();
            }
            java.math.BigDecimal finalPrice = winningBid.getBidAmount();
            java.math.BigDecimal finalPayAmount = finalPrice.subtract(depositAmount);
            if (finalPayAmount.compareTo(java.math.BigDecimal.ZERO) < 0) finalPayAmount = java.math.BigDecimal.ZERO;

            // 6. 生成真实订单号 + 更新押金的 related_order_no
            String realOrderNo = UUID.randomUUID().toString().replace("-", "");
            if (winnerDeposit != null
                    && winnerDeposit.getStatus() != null
                    && winnerDeposit.getStatus() == 1) {
                depositMapper.updateRelatedOrderNo(winnerDeposit.getId(), realOrderNo);
            }

            // 7. 创建订单
            OrderInfo order = new OrderInfo();
            order.setOrderNo(realOrderNo);
            order.setItemId(itemId);
            order.setItemTitle(item.getTitle());
            order.setCoverImage(item.getCoverImage());
            order.setBuyerId(user.getId());
            order.setSellerId(item.getSellerId());
            order.setFinalPrice(finalPrice);
            order.setDepositAmount(depositAmount);
            order.setFinalPayAmount(finalPayAmount);
            order.setAddressId(addressId);
            order.setStatus(0);  // 待付款
            order.setCreateTime(java.time.LocalDateTime.now());

            orderMapper.insert(order);
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            StringBuilder msg = new StringBuilder("订单创建成功");
            if (depositAmount.compareTo(java.math.BigDecimal.ZERO) > 0) {
                msg.append("（已抵用押金 ¥").append(depositAmount.toPlainString())
                        .append("，待付尾款 ¥").append(finalPayAmount.toPlainString()).append("）");
            }
            data.put("message", msg.toString());
            data.put("orderId", order.getId());
            data.put("orderNo", order.getOrderNo());
            data.put("depositAmount", depositAmount.toPlainString());
            data.put("finalPayAmount", finalPayAmount.toPlainString());
            writeJson(resp, data);

        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "创建订单"));
        }
    }

    // ============ 付款 ============

    private void doPay(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        String method = req.getParameter("method");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("订单号不能为空")); return; }
        if (method == null || method.isEmpty()) method = "balance";

        // 余额支付：直接调 PayService.payFinal（实际扣款 + 平台账户 + 写流水）
        if ("balance".equals(method)) {
            Map<String, Object> r;
            try {
                Integer orderId = null;
                try (SqlSession session = MyBatisUtil.openSession()) {
                    OrderMapper mapper = session.getMapper(OrderMapper.class);
                    OrderInfo o = mapper.findByOrderNo(orderNo);
                    if (o == null) { writeJson(resp, errorOf("订单不存在")); return; }
                    orderId = o.getId();
                }
                r = org.example.service.PayService.payFinal(orderId, "balance");
            } catch (Exception e) {
                writeJson(resp, ResponseUtil.handleException(e, "付款"));
                return;
            }
            // 付款成功 → 通知卖家
            if (Boolean.TRUE.equals(r.get("success"))) {
                try (SqlSession session = MyBatisUtil.openSession()) {
                    OrderMapper mapper = session.getMapper(OrderMapper.class);
                    OrderInfo o = mapper.findByOrderNo(orderNo);
                    if (o != null) {
                        MessageService.send(o.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                                "买家已付款，请尽快发货",
                                "订单 " + o.getOrderNo() + "（" + o.getItemTitle() +
                                        "）买家已支付 ¥" + o.getFinalPrice().toPlainString() + "，请尽快发货",
                                o.getId());
                    }
                } catch (Exception ignored) {}
            }
            writeJson(resp, r);
            return;
        }

        // 模拟支付（alipay/wechat）：跳到模拟收银台，等用户点确认后由 PaymentCallbackServlet 处理
        Map<String, Object> data = new HashMap<>();
        data.put("success", true);
        data.put("redirect", req.getContextPath() +
                "/payment?action=sim&type=final&orderNo=" + orderNo + "&method=" + method);
        writeJson(resp, data);
    }

    // ============ 卖家发货 ============

    private void doDeliver(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        String company = req.getParameter("logisticsCompany");
        String tracking = req.getParameter("trackingNumber");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("订单号不能为空")); return; }
        if (company == null || company.isEmpty()) { writeJson(resp, errorOf("请填写物流公司")); return; }
        if (tracking == null || tracking.isEmpty()) { writeJson(resp, errorOf("请填写物流单号")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);
            OrderInfo order = mapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }
            if (!order.getSellerId().equals(user.getId())) { writeJson(resp, errorOf("只有卖家能发货")); return; }
            if (order.getStatus() == null || order.getStatus() != 1) {
                writeJson(resp, errorOf("该订单当前状态不能发货"));
                return;
            }

            int updated = mapper.markDelivered(order.getId(), company.trim(), tracking.trim());
            session.commit();

            if (updated > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "发货成功");
                writeJson(resp, data);

                // 通知买家：卖家已发货（独立事务）
                MessageService.send(order.getBuyerId(), MessageService.TYPE_ORDER_STATUS,
                        "卖家已发货",
                        "订单 " + order.getOrderNo() + "（" + order.getItemTitle() +
                                "）已通过 " + company.trim() + " 发货，运单号：" + tracking.trim(),
                        order.getId());
            } else {
                writeJson(resp, errorOf("发货失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "发货"));
        }
    }

    // ============ 买家确认收货（平台打款给卖家） ============

    private void doConfirmReceive(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("订单号不能为空")); return; }

        Integer orderId = null;
        OrderInfo orderForMsg = null;
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);
            OrderInfo order = mapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }
            if (!order.getBuyerId().equals(user.getId())) { writeJson(resp, errorOf("只有买家能确认收货")); return; }
            if (order.getStatus() == null || order.getStatus() != 2) {
                writeJson(resp, errorOf("该订单当前状态不能确认收货"));
                return;
            }
            orderId = order.getId();
            orderForMsg = order;
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "确认收货"));
            return;
        }

        // 调 PayService：平台账户 -amount → 卖家余额 +amount → order.status 2→3 + settled_time
        Map<String, Object> r = org.example.service.PayService.settleToSeller(orderId);

        if (Boolean.TRUE.equals(r.get("success"))) {
            // 通知卖家：买家已确认收货 + 平台已打款
            try {
                MessageService.send(orderForMsg.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                        "买家已确认收货，平台已打款",
                        "订单 " + orderForMsg.getOrderNo() + "（" + orderForMsg.getItemTitle() +
                                "）买家已确认收货，平台已打款 ¥" + orderForMsg.getFinalPrice().toPlainString() +
                                " 到您的账户余额",
                        orderForMsg.getId());
            } catch (Exception ex) { ex.printStackTrace(); }
        }

        writeJson(resp, r);
    }

    // ============ 取消订单 ============

    private void doCancel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("订单号不能为空")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);
            OrderInfo order = mapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }
            if (!order.getBuyerId().equals(user.getId())) { writeJson(resp, errorOf("只有买家能取消订单")); return; }
            if (order.getStatus() == null || order.getStatus() != 0) {
                writeJson(resp, errorOf("只有待付款订单可以取消"));
                return;
            }

            int updated = mapper.cancel(order.getId());
            session.commit();

            if (updated > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "订单已取消");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("取消失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "取消订单"));
        }
    }

    // ============ 买家申请退款（status 1/2 → 4） ============

    private void doApplyRefund(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        String reason = req.getParameter("refundReason");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("订单号不能为空")); return; }
        if (reason == null || reason.trim().isEmpty()) { writeJson(resp, errorOf("请填写退款理由")); return; }
        if (reason.trim().length() > 500) { writeJson(resp, errorOf("退款理由不超过 500 字")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper mapper = session.getMapper(OrderMapper.class);
            OrderInfo order = mapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }
            if (!order.getBuyerId().equals(user.getId())) {
                writeJson(resp, errorOf("只有买家能申请退款"));
                return;
            }
            if (order.getStatus() == null
                    || (order.getStatus() != 1 && order.getStatus() != 2)) {
                writeJson(resp, errorOf("只有已付款或已发货的订单才能申请退款"));
                return;
            }
            if (order.getStatus() == 4) {
                writeJson(resp, errorOf("此订单已经在申请退款中，请等待管理员处理"));
                return;
            }

            int updated = mapper.markRefundRequested(order.getId(), reason.trim());
            session.commit();

            if (updated > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "退款申请已提交，请等待管理员审核");
                writeJson(resp, data);

                // 通知卖家：买家申请退款（独立事务）
                MessageService.send(order.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                        "买家申请退款",
                        "订单 " + order.getOrderNo() + "（" + order.getItemTitle() +
                                "）买家申请退款：\n" + reason.trim(),
                        order.getId());
            } else {
                writeJson(resp, errorOf("申请失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "申请退款"));
        }
    }

    // ============ 工具方法 ============

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

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }
}