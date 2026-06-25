package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.mapper.AdminMapper;
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
import java.util.HashMap;
import java.util.Map;

/**
 * 管理员登录 Servlet
 *
 * URL 模式：/admin/login
 *   - GET  /admin/login        → 显示登录页（JSP）
 *   - POST /admin/login        → 处理登录（JSON）
 *   - GET  /admin/logout       → 退出登录
 *
 * session 键：currentAdmin（注意：与用户侧的 currentUser 区分）
 *
 * 初始账号：ddl 里有 INSERT ('admin', '8d969...', '超级管理员', 'super')
 * 默认密码：123456（首次登录后建议改）
 */
@WebServlet("/admin/login")
public class AdminLoginServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");

        if ("logout".equals(action)) {
            logout(req, resp);
            return;
        }

        // 已经在管理后台登录 → 直接跳到管理首页
        HttpSession session = req.getSession();
        if (session.getAttribute("currentAdmin") != null) {
            resp.sendRedirect(req.getContextPath() + "/admin");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/jsp/admin/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String account = req.getParameter("account");
        String password = req.getParameter("password");

        if (account == null || account.isEmpty() || password == null || password.isEmpty()) {
            writeJson(resp, errorOf("账号和密码不能为空"));
            return;
        }

        String encPwd = PasswordUtil.encrypt(password);

        try (SqlSession session = MyBatisUtil.openSession()) {
            AdminMapper mapper = session.getMapper(AdminMapper.class);
            Admin admin = mapper.findByAccount(account.trim());

            if (admin == null) {
                writeJson(resp, errorOf("账号不存在"));
                return;
            }
            // 安全保护：初始超级管理员账号（admin）永不禁用——即使数据库被误改也能登
            // 其它账号才检查 status 字段
            boolean isSuperAdmin = "admin".equalsIgnoreCase(admin.getAdminAccount());
            if (!isSuperAdmin && admin.getStatus() != null && admin.getStatus() == 0) {
                writeJson(resp, errorOf("账号已被禁用"));
                return;
            }
            if (!admin.getAdminPassword().equalsIgnoreCase(encPwd)) {
                writeJson(resp, errorOf("账号或密码错误"));
                return;
            }

            // 登录成功：更新最后登录时间 + 写 session（不存 password）
            mapper.updateLastLoginTime(admin.getId());
            session.commit();

            admin.setAdminPassword(null);  // 不放 password 进 session
            req.getSession().setAttribute("currentAdmin", admin);

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "登录成功");
            data.put("adminName", admin.getAdminName());
            data.put("role", admin.getRole());
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "管理员登录"));
        }
    }

    private void logout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.removeAttribute("currentAdmin");
        resp.sendRedirect(req.getContextPath() + "/admin/login");
    }

    // ============ 工具 ============

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
