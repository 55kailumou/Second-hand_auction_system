package org.example.servlet;

import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.mapper.ComplaintMapper;
import org.example.mapper.OrderMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

/**
 * 管理后台首页 Servlet
 *
 * URL：/admin → 装载后台首页（JSP）
 * 受 AdminAuthFilter 保护
 */
@WebServlet("/admin")
public class AdminIndexServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        int pendingRefund = 0;
        int pendingComplaint = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            ComplaintMapper complaintMapper = session.getMapper(ComplaintMapper.class);
            pendingRefund = orderMapper.countPendingRefund();
            pendingComplaint = complaintMapper.countPending();
        } catch (Exception e) {
            ResponseUtil.handleException(e, "管理后台首页");
        }

        req.setAttribute("admin", admin);
        req.setAttribute("pendingRefund", pendingRefund);
        req.setAttribute("pendingComplaint", pendingComplaint);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/index.jsp").forward(req, resp);
    }
}
