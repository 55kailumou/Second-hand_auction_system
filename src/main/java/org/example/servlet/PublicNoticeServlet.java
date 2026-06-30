package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.fasterxml.jackson.databind.SerializationFeature;
import org.apache.ibatis.session.SqlSession;
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
import java.util.HashMap;
import java.util.Map;

/**
 * 前台公开访问公告的 Servlet（不需要管理员登录）
 *
 * URL 模式：/notice?action=xxx
 *   - GET /notice?action=detail&id=                          → 公告详情（仅返回 status=1 已发布的）
 *
 * 注意：
 *   - 不依赖 AdminAuthFilter（路径不在 /admin/* 下）
 *   - 不接收 adminId、未读、管理员字段等内部信息
 */
@WebServlet("/notice")
public class PublicNoticeServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
            .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "detail";

        switch (action) {
            case "detail":
                showPublicDetail(req, resp);
                break;
            default:
                writeJson(resp, errorOf("未知操作"));
        }
    }

    /** 公开详情接口：仅返回已发布（status=1）的公告，不暴露内部字段 */
    private void showPublicDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            writeJson(resp, errorOf("参数错误：缺少 id"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            Notice notice = session.getMapper(NoticeMapper.class).findById(id);
            if (notice == null) {
                writeJson(resp, errorOf("公告不存在"));
                return;
            }
            if (notice.getStatus() == null || notice.getStatus() != 1) {
                // 仅已发布公告对前台可见（草稿/已撤回对用户隐藏）
                writeJson(resp, errorOf("公告不可见"));
                return;
            }

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            Map<String, Object> n = new HashMap<>();
            n.put("id", notice.getId());
            n.put("title", notice.getTitle());
            n.put("content", notice.getContent());
            n.put("isTop", notice.getIsTop());
            n.put("publishTime", notice.getPublishTime());
            data.put("notice", n);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "公告详情"));
        }
    }

    // ============ 工具方法（与 AdminAnnouncementServlet 共享写法） ============

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        JSON.writeValue(resp.getWriter(), obj);
    }

    private Map<String, Object> errorOf(String msg) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", false);
        r.put("message", msg);
        return r;
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s); } catch (Exception e) { return null; }
    }
}
