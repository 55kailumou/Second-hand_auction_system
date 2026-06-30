package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Address;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.AddressMapper;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.mapper.ComplaintMapper;
import org.example.mapper.MessageMapper;
import org.example.mapper.OrderMapper;
import org.example.mapper.UserMapper;
import org.example.mapper.WatchListMapper;
import org.example.util.MyBatisUtil;
import org.example.util.PasswordUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 用户 Servlet：处理注册/登录/登出/字段查重
 *
 * URL 模式：/user?action=xxx
 *   - GET  /user?action=login          → 跳转到登录页
 *   - POST /user?action=login          → 处理登录
 *   - GET  /user?action=register       → 跳转到注册页
 *   - POST /user?action=register       → 处理注册
 *   - GET  /user?action=logout         → 退出登录
 *   - GET  /user?action=check-username → AJAX 查重用户名
 *   - GET  /user?action=check-phone    → AJAX 查重手机号
 */
@WebServlet("/user")
public class UserServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "login";

        switch (action) {
            case "login":
                showLoginPage(req, resp);
                break;
            case "register":
                showRegisterPage(req, resp);
                break;
            case "logout":
                logout(req, resp);
                break;
            case "check-username":
                checkUsername(req, resp);
                break;
            case "check-phone":
                checkPhone(req, resp);
                break;
            case "center":
                showCenter(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // POST 走业务逻辑：登录/注册
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "login":
                doLogin(req, resp);
                break;
            case "register":
                doRegister(req, resp);
                break;
            default:
                // 未知的 POST action：交给 doGet 兜底
                doGet(req, resp);
        }
    }

    // ============ 页面跳转 ============

    private void showLoginPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 如果已登录，直接跳首页
        if (req.getSession().getAttribute("currentUser") != null) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
    }

    private void showRegisterPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/jsp/user/register.jsp").forward(req, resp);
    }

    // ============ 登录处理 ============

    private void doLogin(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String account = trim(req.getParameter("account"));  // 手机号 或 邮箱
        String password = req.getParameter("password");
        String returnUrl = req.getParameter("returnUrl");

        // 基础校验
        if (account == null || account.isEmpty() || password == null || password.isEmpty()) {
            req.setAttribute("error", "请输入手机号/邮箱和密码");
            req.setAttribute("returnUrl", returnUrl);  // 错误时也保留 returnUrl
            req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
            return;
        }

        User user;
        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);
            // 一条 SQL：按 phone 或 email 匹配 + 校验密码
            user = mapper.loginByPhoneOrEmail(account, PasswordUtil.encrypt(password));
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "用户登录");
            req.setAttribute("error", "登录失败，请稍后重试");
            req.setAttribute("returnUrl", returnUrl);
            req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
            return;
        }

        if (user == null) {
            req.setAttribute("error", "手机号/邮箱或密码错误");
            req.setAttribute("returnUrl", returnUrl);
            req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
            return;
        }

        // 登录成功：写入 session
        req.getSession().setAttribute("currentUser", user);

        // 登录成功后跳转：优先 returnUrl（防 open redirect 攻击），否则回首页
        // 安全规则：returnUrl 必须以 / 开头，且不能以 // 或 /\ 开头（防外站跳转）
        String target = req.getContextPath() + "/index.jsp";
        if (returnUrl != null && !returnUrl.isEmpty() && isSafeRedirect(returnUrl)) {
            target = req.getContextPath() + returnUrl;
        }
        resp.sendRedirect(target);
    }

    /**
     * 检查 returnUrl 是否安全的站内跳转
     * 安全：必须以 / 开头，且不能以 // 或 /\ 开头（防 //evil.com 这种伪协议）
     */
    private boolean isSafeRedirect(String url) {
        if (url == null || url.isEmpty()) return false;
        if (!url.startsWith("/")) return false;
        if (url.startsWith("//") || url.startsWith("/\\")) return false;
        return true;
    }

    // ============ 注册处理 ============

    private void doRegister(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String username = trim(req.getParameter("username"));
        String password = req.getParameter("password");
        String confirm  = req.getParameter("confirmPassword");
        String phone    = trim(req.getParameter("phone"));
        String email    = trim(req.getParameter("email"));

        // ========== 1. 用户名校验（必填，可重复） ==========
        if (username == null || username.isEmpty()) {
            fail(req, resp, "用户名不能为空", username, phone, email);
            return;
        }
        if (username.length() < 2 || username.length() > 20) {
            fail(req, resp, "用户名长度必须 2-20 个字符", username, phone, email);
            return;
        }
        if (!username.matches("^[a-zA-Z0-9_\\u4e00-\\u9fa5]+$")) {
            fail(req, resp, "用户名只能包含字母、数字、下划线和中文", username, phone, email);
            return;
        }

        // ========== 2. 密码校验 ==========
        if (password == null || password.length() < 6 || password.length() > 20) {
            fail(req, resp, "密码长度必须 6-20 个字符", username, phone, email);
            return;
        }
        if (!password.equals(confirm)) {
            fail(req, resp, "两次密码不一致", username, phone, email);
            return;
        }

        // ========== 3. 手机号校验（必填） ==========
        if (phone == null || phone.isEmpty()) {
            fail(req, resp, "手机号不能为空", username, phone, email);
            return;
        }
        if (!phone.matches("^1[3-9]\\d{9}$")) {
            fail(req, resp, "手机号格式不正确", username, phone, email);
            return;
        }

        // ========== 4. 邮箱校验（选填，但格式要对） ==========
        if (email != null && !email.isEmpty()
                && !email.matches("^[\\w.+-]+@[\\w-]+\\.[a-zA-Z]{2,}$")) {
            fail(req, resp, "邮箱格式不正确", username, phone, email);
            return;
        }
        // 邮箱空字符串转 NULL（避免 UNIQUE 约束冲突）
        if (email != null && email.isEmpty()) {
            email = null;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);

            // ========== 5. 查重：手机号 + 邮箱 ==========
            if (mapper.findByPhone(phone) != null) {
                fail(req, resp, "手机号已被注册", username, phone, email);
                return;
            }
            if (email != null && mapper.findByEmail(email) != null) {
                fail(req, resp, "邮箱已被注册", username, phone, email);
                return;
            }
            // 用户名可以重复，不再查重

            // ========== 6. 构造 User 插入 ==========
            User user = new User();
            user.setUsername(username);              // 可为 null
            user.setPassword(PasswordUtil.encrypt(password));
            user.setPhone(phone);                    // 必填
            user.setEmail(email);                    // 可为 null
            user.setCreditScore(100);
            user.setBalance(new BigDecimal("0.00"));
            user.setStatus(0);
            user.setRegisterTime(LocalDateTime.now());

            int rows = mapper.insert(user);
            session.commit();

            if (rows > 0) {
                // 注册成功：先从 DB 回查拿到完整 user（含自增 id），再写 session
                User freshUser = mapper.findById(user.getId());
                if (freshUser == null) {
                    freshUser = user;  // 兜底
                }
                req.getSession().setAttribute("currentUser", freshUser);
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
            } else {
                fail(req, resp, "注册失败，请稍后再试", username, phone, email);
            }
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "用户注册");
            fail(req, resp, "注册出错，请稍后重试", username, phone, email);
        }
    }

    private void fail(HttpServletRequest req, HttpServletResponse resp, String msg,
                      String username, String phone, String email) throws ServletException, IOException {
        req.setAttribute("error", msg);
        req.setAttribute("preUsername", username);
        req.setAttribute("prePhone", phone);
        req.setAttribute("preEmail", email);
        req.getRequestDispatcher("/WEB-INF/jsp/user/register.jsp").forward(req, resp);
    }

    // ============ 登出 ============

    private void logout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.invalidate();
        resp.sendRedirect(req.getContextPath() + "/index.jsp");
    }

    // ============ 个人中心 ============

    private void showCenter(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User currentUser = (User) req.getSession().getAttribute("currentUser");
        if (currentUser == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/user?action=center", "UTF-8"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper userMapper = session.getMapper(UserMapper.class);
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);

            // 1. 刷新最新用户信息（信用分、余额可能变化）
            User freshUser = userMapper.findById(currentUser.getId());
            if (freshUser != null) {
                currentUser = freshUser;
                req.getSession().setAttribute("currentUser", freshUser);
            }

            // 2. 卖家视角：发布拍品统计
            int itemActive = itemMapper.countBySellerAndStatus(currentUser.getId(), 1);
            int itemSold   = itemMapper.countBySellerAndStatus(currentUser.getId(), 2);
            int itemFailed = itemMapper.countBySellerAndStatus(currentUser.getId(), 3);
            int itemTotal  = itemActive + itemSold + itemFailed;
            Map<String, Integer> sellerStats = new HashMap<>();
            sellerStats.put("total", itemTotal);
            sellerStats.put("active", itemActive);
            sellerStats.put("sold", itemSold);
            sellerStats.put("failed", itemFailed);

            // 3. 买家视角：订单状态计数
            int ordersPending = orderMapper.countByBuyerAndStatus(currentUser.getId(), 0);
            int ordersPaid    = orderMapper.countByBuyerAndStatus(currentUser.getId(), 1);
            int ordersShipped = orderMapper.countByBuyerAndStatus(currentUser.getId(), 2);
            int ordersDone    = orderMapper.countByBuyerAndStatus(currentUser.getId(), 3);

            // 4. 买家视角：我的出价数
            List<BidRecord> myBids = bidMapper.findByBidderId(currentUser.getId());
            int myBidsCount = myBids == null ? 0 : myBids.size();

            // 4.5 我的收藏数
            int favoritesCount = session.getMapper(WatchListMapper.class).countByUserId(currentUser.getId());

            // 4.6 我的地址数
            int addressCount = session.getMapper(AddressMapper.class).findByUserId(currentUser.getId()).size();

            // 4.7 未读消息数
            int unreadMessageCount = session.getMapper(MessageMapper.class).countUnreadByUserId(currentUser.getId());

            // 4.8 我发起的投诉数
            int myComplaintCount = session.getMapper(ComplaintMapper.class).countMyComplaints(currentUser.getId());

            // 5. 卖家视角：待发货订单数
            Map<String, Object> sellerShipParams = new HashMap<>();
            sellerShipParams.put("userId", currentUser.getId());
            sellerShipParams.put("role", "seller");
            sellerShipParams.put("status", 1);
            int sellerOrdersToShip = orderMapper.countByCondition(sellerShipParams);

            // 6. 我的拍品按状态分组（每组最多 12 个，给前端 tab 切换用）
            int recentLimit = 12;
            List<AuctionItem> activeItems = itemMapper.findByCondition(buildItemParams(currentUser.getId(), 1, recentLimit));
            List<AuctionItem> soldItems   = itemMapper.findByCondition(buildItemParams(currentUser.getId(), 2, recentLimit));
            List<AuctionItem> failedItems = itemMapper.findByCondition(buildItemParams(currentUser.getId(), 3, recentLimit));

            req.setAttribute("user", currentUser);
            req.setAttribute("sellerStats", sellerStats);
            req.setAttribute("ordersPending", ordersPending);
            req.setAttribute("ordersPaid", ordersPaid);
            req.setAttribute("ordersShipped", ordersShipped);
            req.setAttribute("ordersDone", ordersDone);
            req.setAttribute("myBidsCount", myBidsCount);
            req.setAttribute("favoritesCount", favoritesCount);
            req.setAttribute("addressCount", addressCount);
            req.setAttribute("unreadMessageCount", unreadMessageCount);
            req.setAttribute("myComplaintCount", myComplaintCount);
            req.setAttribute("sellerOrdersToShip", sellerOrdersToShip);
            req.setAttribute("activeItems", activeItems);
            req.setAttribute("soldItems", soldItems);
            req.setAttribute("failedItems", failedItems);

            req.getRequestDispatcher("/WEB-INF/jsp/user/center.jsp").forward(req, resp);
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "个人中心加载");
            req.setAttribute("error", "加载个人中心失败，请稍后重试");
            req.getRequestDispatcher("/WEB-INF/jsp/user/center.jsp").forward(req, resp);
        }
    }

    // ============ AJAX 查重（返回 JSON） ============

    /** 拼装「按卖家 + 状态」查拍品的条件 map（offset=0, limit 外部指定） */
    private static Map<String, Object> buildItemParams(int sellerId, int status, int limit) {
        Map<String, Object> p = new HashMap<>();
        p.put("sellerId", sellerId);
        p.put("status", status);
        p.put("offset", 0);
        p.put("limit", limit);
        return p;
    }

    private void checkUsername(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String username = trim(req.getParameter("username"));
        Map<String, Object> result = new HashMap<>();

        if (username == null || username.isEmpty()) {
            result.put("exists", false);
            result.put("available", false);
            result.put("message", "用户名不能为空");
        } else {
            try (SqlSession session = MyBatisUtil.openSession()) {
                UserMapper mapper = session.getMapper(UserMapper.class);
                boolean exists = mapper.findByUsername(username) != null;
                result.put("exists", exists);
                result.put("available", !exists);
                result.put("message", exists ? "用户名已被占用" : "用户名可用");
            }
        }
        writeJson(resp, result);
    }

    private void checkPhone(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String phone = trim(req.getParameter("phone"));
        Map<String, Object> result = new HashMap<>();

        if (phone == null || phone.isEmpty()) {
            result.put("exists", false);
            result.put("available", false);
            result.put("message", "手机号不能为空");
        } else if (!phone.matches("^1[3-9]\\d{9}$")) {
            result.put("exists", false);
            result.put("available", false);
            result.put("message", "手机号格式不正确");
        } else {
            try (SqlSession session = MyBatisUtil.openSession()) {
                UserMapper mapper = session.getMapper(UserMapper.class);
                boolean exists = mapper.findByPhone(phone) != null;
                result.put("exists", exists);
                result.put("available", !exists);
                result.put("message", exists ? "手机号已被注册" : "手机号可用");
            }
        }
        writeJson(resp, result);
    }

    // ============ 工具方法 ============

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(JSON.writeValueAsString(obj));
        out.flush();
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
    }
}