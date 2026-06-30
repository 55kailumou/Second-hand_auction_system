package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.Deposit;
import org.example.entity.User;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.DepositMapper;
import org.example.service.PayService;
import org.example.util.MyBatisUtil;

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

/**
 * 押金 Servlet
 *
 * URL 模式：/deposit?action=xxx
 *   - GET  /deposit?action=checkout&itemId=xx   → 押金收银台（JSP）
 *   - POST /deposit?action=pay                   → 提交押金支付（JSON）
 *   - GET  /deposit?action=status&itemId=xx      → 查押金状态（JSON，给 item/detail.jsp 用）
 *   - GET  /deposit?action=my                    → 我的押金记录（JSP）
 */
@WebServlet("/deposit")
public class DepositServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "my";

        switch (action) {
            case "checkout":
                showCheckout(req, resp);
                break;
            case "status":
                sendStatus(req, resp);
                break;
            case "my":
                showMyDeposits(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/deposit?action=my");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if ("pay".equals(action)) {
            doPay(req, resp);
        } else {
            doGet(req, resp);
        }
    }

    // ===================== 押金收银台（页面） =====================

    private void showCheckout(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            String back = "/deposit?action=checkout&itemId=" + req.getParameter("itemId");
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode(back, "UTF-8"));
            return;
        }

        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        if (itemId == null) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "itemId 必填");
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            AuctionItem item = itemMapper.findById(itemId);
            if (item == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "拍品不存在");
                return;
            }
            req.setAttribute("item", item);
            req.setAttribute("balance", PayService.getUserBalance(user.getId()));
            req.getRequestDispatcher("/WEB-INF/jsp/pay/deposit.jsp").forward(req, resp);
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "加载失败：" + e.getMessage());
        }
    }

    // ===================== 押金状态查询（JSON） =====================

    private void sendStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        Integer itemId = parseIntOrNull(req.getParameter("itemId"));

        Map<String, Object> data = new HashMap<>();
        data.put("loggedIn", user != null);
        if (user == null || itemId == null) {
            data.put("deposited", false);
            data.put("status", "none");
            writeJson(resp, data);
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            DepositMapper mapper = session.getMapper(DepositMapper.class);
            Deposit d = mapper.findByUserAndItem(user.getId(), itemId);
            if (d == null) {
                data.put("deposited", false);
                data.put("status", "none");
            } else {
                data.put("deposited", d.getStatus() == 0 || d.getStatus() == 1);
                data.put("status", d.getStatus());
                data.put("statusText", d.getStatusText());
                data.put("amount", d.getAmount() == null ? "0.00" : d.getAmount().toPlainString());
            }
            writeJson(resp, data);
        } catch (Exception e) {
            e.printStackTrace();
            data.put("error", e.getMessage());
            writeJson(resp, data);
        }
    }

    // ===================== 提交押金支付 =====================

    private void doPay(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        String method = req.getParameter("method");
        if (itemId == null) { writeJson(resp, errorOf("参数错误")); return; }
        if (method == null || method.isEmpty()) method = "balance";

        // 余额支付：直接走 PayService
        if ("balance".equals(method)) {
            Map<String, Object> r = PayService.payDeposit(user.getId(), itemId, "balance");
            writeJson(resp, r);
            return;
        }

        // 模拟支付（alipay/wechat）：跳到模拟收银台
        // 这里不立即扣款，等用户在模拟页面点"确认支付"才走 PaymentCallbackServlet
        Map<String, Object> data = new HashMap<>();
        data.put("success", true);
        data.put("redirect", req.getContextPath() +
                "/payment?action=sim&type=deposit&itemId=" + itemId + "&method=" + method);
        writeJson(resp, data);
    }

    // ===================== 我的押金记录（页面） =====================

    private void showMyDeposits(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login");
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            DepositMapper mapper = session.getMapper(DepositMapper.class);
            List<Deposit> deposits = mapper.findByUserId(user.getId());
            req.setAttribute("deposits", deposits);
            req.setAttribute("balance", PayService.getUserBalance(user.getId()));
            req.getRequestDispatcher("/WEB-INF/jsp/pay/my_deposits.jsp").forward(req, resp);
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "加载失败：" + e.getMessage());
        }
    }

    // ===================== 工具 =====================

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
