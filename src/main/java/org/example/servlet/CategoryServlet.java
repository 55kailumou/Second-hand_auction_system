package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Category;
import org.example.mapper.CategoryMapper;
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
 * 分类 Servlet：提供 AJAX 接口给前端 Vue 用
 *
 * URL 模式：/category?action=xxx
 *   - GET  /category?action=list       → 返回所有分类 JSON
 *   - GET  /category?action=top        → 返回一级分类 JSON
 */
@WebServlet("/category")
public class CategoryServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "top":
                sendTopLevel(req, resp);
                break;
            case "list":
            default:
                sendAll(req, resp);
                break;
        }
    }

    private void sendAll(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper mapper = session.getMapper(CategoryMapper.class);
            List<Category> list = mapper.findAll();
            writeJson(resp, list);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "分类查询"));
        }
    }

    private void sendTopLevel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper mapper = session.getMapper(CategoryMapper.class);
            List<Category> list = mapper.findTopLevel();
            writeJson(resp, list);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "分类查询"));
        }
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
