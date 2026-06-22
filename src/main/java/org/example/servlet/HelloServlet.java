package org.example.servlet;

import org.apache.ibatis.session.SqlSession;
import org.example.entity.User;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * 骨架验证 Servlet：访问 /hello 能查到 user 表的所有用户
 * 用来验证「MyBatis 配置 → SqlSession → Mapper → DB」整条链路是否通
 *
 * 跑通后会跳转到 /WEB-INF/jsp/hello.jsp，把用户列表渲染出来
 */
@WebServlet(name = "HelloServlet", urlPatterns = "/hello")
public class HelloServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        List<User> users;
        int total;

        // try-with-resources 确保 SqlSession 一定关闭
        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper mapper = session.getMapper(UserMapper.class);
            users = mapper.findAll();
            total = mapper.countAll();
            System.out.println("[HelloServlet] 查询到 " + total + " 个用户");
        } catch (Exception e) {
            e.printStackTrace();
            resp.setContentType("text/html;charset=UTF-8");
            resp.getWriter().println("<h2 style='color:red'>MyBatis 报错：</h2><pre>" + e.getMessage() + "</pre>");
            return;
        }

        // 把数据传给 JSP 渲染
        req.setAttribute("users", users);
        req.setAttribute("total", total);
        req.getRequestDispatcher("/WEB-INF/jsp/hello.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        doGet(req, resp);
    }
}