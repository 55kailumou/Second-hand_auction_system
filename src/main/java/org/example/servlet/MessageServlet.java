package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Message;
import org.example.entity.User;
import org.example.mapper.MessageMapper;
import org.example.util.MyBatisUtil;
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
 * 消息通知 Servlet
 *
 * URL 模式：/message?action=xxx
 *   - GET  /message?action=list&isRead=&page=     → 消息中心（JSP）
 *   - GET  /message?action=unread-count           → 未读数（JSON，顶 nav 轮询用）
 *   - POST /message?action=mark-read&id=xx        → 标记单条已读（JSON）
 *   - POST /message?action=mark-all-read          → 全部已读（JSON）
 *   - POST /message?action=remove&id=xx           → 删除单条（避开 HttpServlet.doDelete）
 */
@WebServlet("/message")
public class MessageServlet extends HttpServlet {

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
            case "unread-count":
                getUnreadCount(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/message?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "mark-read":
                doMarkRead(req, resp);
                break;
            case "mark-all-read":
                doMarkAllRead(req, resp);
                break;
            case "remove":
                doRemove(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 消息列表 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/message?action=list", "UTF-8"));
            return;
        }

        // isRead: 0=未读 1=已读 null=全部
        Integer isReadFilter = parseIntOrNull(req.getParameter("isRead"));
        int pageNo = 1;
        try { pageNo = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (pageNo < 1) pageNo = 1;
        int pageSize = 15;
        int offset = (pageNo - 1) * pageSize;

        List<Message> messages;
        int total, unreadCount;
        try (SqlSession session = MyBatisUtil.openSession()) {
            MessageMapper mapper = session.getMapper(MessageMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("userId", user.getId());
            params.put("isRead", isReadFilter);
            params.put("offset", offset);
            params.put("limit", pageSize);
            messages = mapper.findByCondition(params);
            total = mapper.countByCondition(params);
            unreadCount = mapper.countUnreadByUserId(user.getId());
        } catch (Exception e) {
            ResponseUtil.handleException(e, "消息列表");
            messages = new java.util.ArrayList<>();
            total = 0;
            unreadCount = 0;
            req.setAttribute("error", "加载消息失败，请稍后重试");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("messagesJson", safeToJson(messages));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("isReadFilter", isReadFilter);
        req.setAttribute("unreadCount", unreadCount);
        req.getRequestDispatcher("/WEB-INF/jsp/message/list.jsp").forward(req, resp);
    }

    // ============ 未读数（顶 nav 轮询用） ============

    private void getUnreadCount(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }
        try (SqlSession session = MyBatisUtil.openSession()) {
            int count = session.getMapper(MessageMapper.class).countUnreadByUserId(user.getId());
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("count", count);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "未读数查询"));
        }
    }

    // ============ 标记单条已读 ============

    private void doMarkRead(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }
        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            int rows = session.getMapper(MessageMapper.class).markRead(id, user.getId());
            session.commit();
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "已标记为已读");
            data.put("updated", rows);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "标记已读"));
        }
    }

    // ============ 全部已读 ============

    private void doMarkAllRead(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            int rows = session.getMapper(MessageMapper.class).markAllRead(user.getId());
            session.commit();
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "已将 " + rows + " 条消息标记为已读");
            data.put("updated", rows);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "全部已读"));
        }
    }

    // ============ 删除单条 ============

    private void doRemove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }
        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            int rows = session.getMapper(MessageMapper.class).deleteById(id, user.getId());
            session.commit();
            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "已删除");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("删除失败或消息不存在"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "删除消息"));
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
