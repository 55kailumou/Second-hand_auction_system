package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.User;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;
import org.example.util.PasswordUtil;

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
            default:
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // POST 请求统一交给 doGet 处理（业务逻辑一致）
        doGet(req, resp);
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
        String username = trim(req.getParameter("username"));
        String password = req.getParameter("password");

        // 基础校验
        if (username == null || username.isEmpty() || password == null || password.isEmpty()) {
            req.setAttribute("error", "用户名/手机号和密码不能为空");
            req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
            return;
        }

        User user;
        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);

            // 智能判断：纯数字当作手机号，否则当作用户名
            if (username.matches("^1[3-9]\\d{9}$")) {
                user = mapper.findByPhone(username);
                if (user != null && !user.getPassword().equals(PasswordUtil.encrypt(password))) {
                    user = null;
                }
            } else {
                user = mapper.login(username, PasswordUtil.encrypt(password));
            }
        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("error", "登录失败：" + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
            return;
        }

        if (user == null) {
            req.setAttribute("error", "用户名/手机号或密码错误");
            req.getRequestDispatcher("/WEB-INF/jsp/user/login.jsp").forward(req, resp);
            return;
        }

        // 登录成功：写入 session，更新最后登录时间
        req.getSession().setAttribute("currentUser", user);
        resp.sendRedirect(req.getContextPath() + "/index.jsp");
    }

    // ============ 注册处理 ============

    private void doRegister(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String username = trim(req.getParameter("username"));
        String password = req.getParameter("password");
        String confirm  = req.getParameter("confirmPassword");
        String phone    = trim(req.getParameter("phone"));
        String email    = trim(req.getParameter("email"));

        // 校验
        if (username == null || username.length() < 3 || username.length() > 20) {
            fail(req, resp, "用户名长度必须 3-20 个字符", username, phone, email);
            return;
        }
        if (!username.matches("^[a-zA-Z0-9_\\u4e00-\\u9fa5]+$")) {
            fail(req, resp, "用户名只能包含字母、数字、下划线和中文", username, phone, email);
            return;
        }
        if (password == null || password.length() < 6 || password.length() > 20) {
            fail(req, resp, "密码长度必须 6-20 个字符", username, phone, email);
            return;
        }
        if (!password.equals(confirm)) {
            fail(req, resp, "两次密码不一致", username, phone, email);
            return;
        }
        if (phone != null && !phone.isEmpty() && !phone.matches("^1[3-9]\\d{9}$")) {
            fail(req, resp, "手机号格式不正确", username, phone, email);
            return;
        }
        if (email != null && !email.isEmpty() && !email.matches("^[\\w.+-]+@[\\w-]+\\.[a-zA-Z]{2,}$")) {
            fail(req, resp, "邮箱格式不正确", username, phone, email);
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);

            // 查重
            if (mapper.findByUsername(username) != null) {
                fail(req, resp, "用户名已被占用", username, phone, email);
                return;
            }
            if (phone != null && !phone.isEmpty() && mapper.findByPhone(phone) != null) {
                fail(req, resp, "手机号已被注册", username, phone, email);
                return;
            }

            // 构造 User 插入
            User user = new User();
            user.setUsername(username);
            user.setPassword(PasswordUtil.encrypt(password));
            user.setPhone(phone);
            user.setEmail(email);
            user.setCreditScore(100);
            user.setBalance(new BigDecimal("0.00"));
            user.setStatus(0);
            user.setRegisterTime(LocalDateTime.now());

            int rows = mapper.insert(user);
            session.commit();

            if (rows > 0) {
                // 注册成功，直接登录跳首页
                req.getSession().setAttribute("currentUser", user);
                resp.sendRedirect(req.getContextPath() + "/index.jsp");
            } else {
                fail(req, resp, "注册失败，请稍后再试", username, phone, email);
            }
        } catch (Exception e) {
            e.printStackTrace();
            fail(req, resp, "注册出错：" + e.getMessage(), username, phone, email);
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

    // ============ AJAX 查重（返回 JSON） ============

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