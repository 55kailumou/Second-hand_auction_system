package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.Notice;
import org.example.mapper.NoticeMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 - 公告管理 Servlet
 *
 * URL 模式：/admin/announcement
 *   - GET  /admin/announcement?action=list&status=&keyword=&page=  → 公告列表（JSP）
 *   - GET  /admin/announcement?action=detail&id=                    → 公告详情（JSON）
 *   - POST /admin/announcement?action=create                        → 新增公告（默认草稿 status=0）
 *   - POST /admin/announcement?action=update&id=                    → 更新公告
 *   - POST /admin/announcement?action=set-status&id=&status=        → 发布/撤回（0草稿 1已发布 2已撤回）
 *   - POST /admin/announcement?action=set-top&id=&isTop=            → 置顶/取消置顶
 *   - POST /admin/announcement?action=delete&id=                    → 删除公告
 *
 * 业务规则：
 *   - 新增后默认 status=0（草稿），需要再点"发布"才能在前台看到
 *   - 发布时 status 1 → 设置 publish_time = NOW()
 *   - 撤回时 status 2 → publish_time 不变
 *   - is_top=1 的公告在列表最前（最多 N 个置顶）
 *   - 不做富文本编辑器，只用 textarea 写纯文本/简单 HTML（防 XSS 用 EscapeUtil 处理）
 */
@WebServlet("/admin/announcement")
public class AdminAnnouncementServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private static final DateTimeFormatter ISO_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

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
                resp.sendRedirect(req.getContextPath() + "/admin/announcement?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "create":
                doCreate(req, resp);
                break;
            case "update":
                doUpdate(req, resp);
                break;
            case "set-status":
                doSetStatus(req, resp);
                break;
            case "set-top":
                doSetTop(req, resp);
                break;
            case "delete":
                doRemove(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 列表 ============

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

        List<Notice> notices = null;
        int total = 0;
        int draftCount = 0;
        int publishedCount = 0;
        int retractedCount = 0;
        int topCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            NoticeMapper mapper = session.getMapper(NoticeMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("status", status);
            params.put("keyword", keyword == null ? null : keyword.trim());
            params.put("offset", offset);
            params.put("limit", pageSize);

            notices = mapper.findByCondition(params);
            total = mapper.countByCondition(params);

            // 统计各状态
            java.util.Map<String, Object> all = new java.util.HashMap<>();
            int allTotal = mapper.countByCondition(all);
            java.util.Map<String, Object> draftParams = new java.util.HashMap<>();
            draftParams.put("status", 0);
            draftCount = mapper.countByCondition(draftParams);
            java.util.Map<String, Object> pubParams = new java.util.HashMap<>();
            pubParams.put("status", 1);
            publishedCount = mapper.countByCondition(pubParams);
            java.util.Map<String, Object> retParams = new java.util.HashMap<>();
            retParams.put("status", 2);
            retractedCount = mapper.countByCondition(retParams);
            // 置顶数（状态为已发布的 + is_top=1）
            java.util.Map<String, Object> topParams = new java.util.HashMap<>();
            topParams.put("status", 1);
            topParams.put("keyword", "");  // 占位；is_top 用 list 自己判断
            List<Notice> publishedList = mapper.findByCondition(topParams);
            if (publishedList != null) {
                topCount = (int) publishedList.stream().filter(n -> n.getIsTop() != null && n.getIsTop() == 1).count();
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "公告列表");
            req.setAttribute("error", "加载公告列表失败，请稍后重试");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("admin", admin);
        req.setAttribute("noticesJson", safeToJson(notices == null ? new java.util.ArrayList<>() : notices));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("status", status);
        req.setAttribute("keyword", keyword == null ? "" : keyword);
        req.setAttribute("draftCount", draftCount);
        req.setAttribute("publishedCount", publishedCount);
        req.setAttribute("retractedCount", retractedCount);
        req.setAttribute("topCount", topCount);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/announcements.jsp").forward(req, resp);
    }

    // ============ 详情（JSON） ============

    private void getDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            Notice notice = session.getMapper(NoticeMapper.class).findById(id);
            if (notice == null) { writeJson(resp, errorOf("公告不存在")); return; }
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("notice", notice);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "公告详情"));
        }
    }

    // ============ 新增（默认草稿） ============

    private void doCreate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        String title = trim(req.getParameter("title"));
        String content = trim(req.getParameter("content"));
        Integer isTop = parseIntOrNull(req.getParameter("isTop"));
        Integer status = parseIntOrNull(req.getParameter("status"));

        if (title == null || title.isEmpty()) { writeJson(resp, errorOf("标题不能为空")); return; }
        if (title.length() > 100) { writeJson(resp, errorOf("标题不超过 100 字")); return; }
        if (content == null || content.isEmpty()) { writeJson(resp, errorOf("内容不能为空")); return; }
        if (content.length() > 5000) { writeJson(resp, errorOf("内容不超过 5000 字")); return; }
        if (isTop == null || (isTop != 0 && isTop != 1)) isTop = 0;
        if (status == null) status = 0;
        if (status != 0 && status != 1 && status != 2) status = 0;

        try (SqlSession session = MyBatisUtil.openSession()) {
            Notice notice = new Notice();
            notice.setAdminId(admin.getId());
            notice.setTitle(title);
            notice.setContent(content);
            notice.setIsTop(isTop);
            notice.setStatus(status);
            notice.setPublishTime(status == 1 ? LocalDateTime.now() : null);

            session.getMapper(NoticeMapper.class).insert(notice);
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "公告已新增（" + statusText(status) + "）：" + title);
            data.put("id", notice.getId());
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "新增公告"));
        }
    }

    // ============ 更新 ============

    private void doUpdate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        String title = trim(req.getParameter("title"));
        String content = trim(req.getParameter("content"));
        Integer isTop = parseIntOrNull(req.getParameter("isTop"));

        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (title == null || title.isEmpty()) { writeJson(resp, errorOf("标题不能为空")); return; }
        if (title.length() > 100) { writeJson(resp, errorOf("标题不超过 100 字")); return; }
        if (content == null || content.isEmpty()) { writeJson(resp, errorOf("内容不能为空")); return; }
        if (content.length() > 5000) { writeJson(resp, errorOf("内容不超过 5000 字")); return; }
        if (isTop == null || (isTop != 0 && isTop != 1)) isTop = 0;

        try (SqlSession session = MyBatisUtil.openSession()) {
            NoticeMapper mapper = session.getMapper(NoticeMapper.class);
            Notice old = mapper.findById(id);
            if (old == null) { writeJson(resp, errorOf("公告不存在")); return; }

            Notice notice = new Notice();
            notice.setId(id);
            notice.setAdminId(old.getAdminId());
            notice.setTitle(title);
            notice.setContent(content);
            notice.setIsTop(isTop);
            notice.setStatus(old.getStatus());
            notice.setPublishTime(old.getPublishTime());
            notice.setCreateTime(old.getCreateTime());

            int rows = mapper.updateById(notice);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "公告已更新：" + title);
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("更新失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "更新公告"));
        }
    }

    // ============ 发布/撤回 ============

    private void doSetStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer newStatus = parseIntOrNull(req.getParameter("status"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (newStatus == null || newStatus < 0 || newStatus > 2) {
            writeJson(resp, errorOf("status 必须为 0（草稿）/ 1（已发布）/ 2（已撤回）"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            NoticeMapper mapper = session.getMapper(NoticeMapper.class);
            Notice notice = mapper.findById(id);
            if (notice == null) { writeJson(resp, errorOf("公告不存在")); return; }

            int oldStatus = notice.getStatus() == null ? 0 : notice.getStatus();
            if (oldStatus == newStatus) {
                writeJson(resp, errorOf("状态未变化"));
                return;
            }

            String publishTimeStr;
            if (newStatus == 1) {
                // 发布：publish_time 设为 NOW()
                publishTimeStr = LocalDateTime.now().format(ISO_FMT);
            } else if (notice.getPublishTime() != null) {
                // 撤回/转草稿：保留原 publish_time（仅记录首次发布时间）
                publishTimeStr = notice.getPublishTime().format(ISO_FMT);
            } else {
                publishTimeStr = null;
            }

            int rows = mapper.updateStatusByAdmin(id, newStatus, publishTimeStr);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "公告已" + statusText(newStatus) + "：" + notice.getTitle());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "改状态"));
        }
    }

    // ============ 置顶/取消置顶 ============

    private void doSetTop(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer isTop = parseIntOrNull(req.getParameter("isTop"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (isTop == null || (isTop != 0 && isTop != 1)) {
            writeJson(resp, errorOf("isTop 必须为 0 或 1"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            NoticeMapper mapper = session.getMapper(NoticeMapper.class);
            Notice notice = mapper.findById(id);
            if (notice == null) { writeJson(resp, errorOf("公告不存在")); return; }

            int oldTop = notice.getIsTop() == null ? 0 : notice.getIsTop();
            if (oldTop == isTop) {
                writeJson(resp, errorOf("置顶状态未变化"));
                return;
            }

            int rows = mapper.updateTopByAdmin(id, isTop);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", (isTop == 1 ? "已置顶：" : "已取消置顶：") + notice.getTitle());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "置顶"));
        }
    }

    // ============ 删除 ============

    private void doRemove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            NoticeMapper mapper = session.getMapper(NoticeMapper.class);
            Notice notice = mapper.findById(id);
            if (notice == null) { writeJson(resp, errorOf("公告不存在")); return; }

            int rows = mapper.deleteById(id);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "公告已删除：" + notice.getTitle());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("删除失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "删除公告"));
        }
    }

    // ============ 工具 ============

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
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
        switch (s) {
            case 0: return "转为草稿";
            case 1: return "已发布";
            case 2: return "已撤回";
            default: return "未知";
        }
    }
}