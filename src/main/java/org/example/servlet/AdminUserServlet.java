package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.User;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;
import org.example.util.PasswordUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 - 用户管理 Servlet
 *
 * URL 模式：/admin/user
 *   - GET  /admin/user?action=list&status=&keyword=&page=  → 用户列表（JSP，受 AdminAuthFilter 保护）
 *   - GET  /admin/user?action=detail&id=xx                  → 用户详情（JSON）
 *   - POST /admin/user?action=set-status&id=&status=        → 封禁/解封（JSON，0=正常 1=封禁）
 *   - POST /admin/user?action=adjust-credit&id=&delta=     → 调整信用分（JSON，增量 -100 ~ +100）
 *   - POST /admin/user?action=reset-password&id=           → 重置密码为 123456（JSON）
 *
 * 状态说明：
 *   0 正常 1 封禁
 *
 * 安全规则：
 *   - 改 status / 重置密码：拒绝操作 ID=1 的 admin 账号（防误锁自己）
 *   - 调信用分：单次 -100 ~ +100，超出范围报错
 *   - 重置密码：写入 SHA-256(123456)
 */
@WebServlet("/admin/user")
public class AdminUserServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    /** 初始账号的 user.id = 1（ddl 里 INSERT 的 admin 行），禁止通过本 servlet 改其状态 */
    private static final int PROTECTED_USER_ID = 1;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":
                showList(req, resp);
                break;
            case "detail":
                getDetail(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/admin/user?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "set-status":
                doSetStatus(req, resp);
                break;
            case "adjust-credit":
                doAdjustCredit(req, resp);
                break;
            case "reset-password":
                doResetPassword(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 用户列表 ============

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
        int pageSize = 15;
        int offset = (pageNo - 1) * pageSize;

        List<User> users = null;
        int total = 0;
        int normalCount = 0;
        int bannedCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("status", status);
            params.put("keyword", keyword == null ? null : keyword.trim());
            params.put("offset", offset);
            params.put("limit", pageSize);

            users = mapper.findByCondition(params);
            total = mapper.countByCondition(params);

            // 统计：正常用户数 / 封禁用户数（admin 概览用）
            Map<String, Object> normalParams = new HashMap<>();
            normalParams.put("status", 0);
            normalCount = mapper.countByCondition(normalParams);

            Map<String, Object> bannedParams = new HashMap<>();
            bannedParams.put("status", 1);
            bannedCount = mapper.countByCondition(bannedParams);

            // 重要：清空 password（防止泄露到 JSP）
            if (users != null) {
                for (User u : users) {
                    u.setPassword(null);
                }
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "用户列表");
            req.setAttribute("error", "加载用户列表失败，请稍后重试");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("admin", admin);
        req.setAttribute("usersJson", safeToJson(users == null ? new java.util.ArrayList<>() : users));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("status", status);
        req.setAttribute("keyword", keyword == null ? "" : keyword);
        req.setAttribute("normalCount", normalCount);
        req.setAttribute("bannedCount", bannedCount);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/users.jsp").forward(req, resp);
    }

    // ============ 用户详情（JSON） ============

    private void getDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            User user = session.getMapper(UserMapper.class).findById(id);
            if (user == null) { writeJson(resp, errorOf("用户不存在")); return; }
            user.setPassword(null);  // 永远不返回密码
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("user", user);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "用户详情"));
        }
    }

    // ============ 封禁 / 解封 ============

    private void doSetStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer newStatus = parseIntOrNull(req.getParameter("status"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (newStatus == null || (newStatus != 0 && newStatus != 1)) {
            writeJson(resp, errorOf("status 必须为 0（正常）或 1（封禁）"));
            return;
        }

        // 安全保护：禁止封禁初始账号
        if (id == PROTECTED_USER_ID) {
            writeJson(resp, errorOf("初始账号受保护，无法修改状态"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);
            User user = mapper.findById(id);
            if (user == null) { writeJson(resp, errorOf("用户不存在")); return; }

            int oldStatus = user.getStatus() == null ? 0 : user.getStatus();
            if (oldStatus == newStatus) {
                writeJson(resp, errorOf("状态未变化"));
                return;
            }

            int rows = mapper.updateStatusByAdmin(id, newStatus);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "用户已" + statusText(newStatus) + "（" + user.getUsername() + "）");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "改状态"));
        }
    }

    // ============ 调整信用分 ============

    private void doAdjustCredit(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer delta = parseIntOrNull(req.getParameter("delta"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (delta == null) { writeJson(resp, errorOf("参数错误：缺少 delta")); return; }
        if (delta < -100 || delta > 100) {
            writeJson(resp, errorOf("单次调整范围 -100 ~ +100"));
            return;
        }
        if (delta == 0) { writeJson(resp, errorOf("调整值不能为 0")); return; }

        // 安全保护：禁止改初始账号的信用分
        if (id == PROTECTED_USER_ID) {
            writeJson(resp, errorOf("初始账号受保护，无法调整信用分"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);
            User user = mapper.findById(id);
            if (user == null) { writeJson(resp, errorOf("用户不存在")); return; }

            int oldScore = user.getCreditScore() == null ? 100 : user.getCreditScore();
            int rows = mapper.updateCreditScore(id, delta);  // SQL 用 GREATEST/LEAST 约束 0-150
            session.commit();

            if (rows > 0) {
                // 重新读最新值
                User fresh = mapper.findById(id);
                int newScore = fresh.getCreditScore() == null ? oldScore : fresh.getCreditScore();

                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "信用分已" + (delta > 0 ? "上调" : "下调") + " " + Math.abs(delta) +
                        "（" + user.getUsername() + "： " + oldScore + " → " + newScore + "）");
                data.put("oldScore", oldScore);
                data.put("newScore", newScore);
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "调信用分"));
        }
    }

    // ============ 重置密码 ============

    private void doResetPassword(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        // 安全保护：禁止重置初始账号密码（防误锁）
        if (id == PROTECTED_USER_ID) {
            writeJson(resp, errorOf("初始账号受保护，无法重置密码"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);
            User user = mapper.findById(id);
            if (user == null) { writeJson(resp, errorOf("用户不存在")); return; }

            String newPwd = PasswordUtil.encrypt("123456");  // 重置为初始密码
            int rows = mapper.resetPasswordByAdmin(id, newPwd);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "密码已重置为 123456（" + user.getUsername() + "）");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "重置密码"));
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

    private String statusText(int s) {
        return s == 0 ? "解封" : "封禁";
    }
}