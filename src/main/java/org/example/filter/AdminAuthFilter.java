package org.example.filter;

import org.example.entity.Admin;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URLEncoder;

/**
 * 管理员鉴权 Filter：拦截 /admin 和 /admin/* 除 /admin/login 外的所有路径
 *
 * 已登录管理员（session.currentAdmin 存在）放行
 * 未登录跳到 /admin/login?returnUrl=<原URL>
 *
 * 注意：
 *   1. /admin（不带尾斜杠）和 /admin/*（带尾斜杠）是两个不同的路径，要分别匹配
 *      否则访问 /admin 时不会被本 Filter 拦截，全靠 AdminIndexServlet 内部校验，
 *      导致拦截逻辑分散、不一致
 *   2. /admin/login.jsp 仅作为文件路径存在（实际请求走 AdminLoginServlet），不会
 *      被 WebFilter 匹配到，加 urlPatterns 兜底也无副作用
 */
@WebFilter(urlPatterns = {"/admin", "/admin/*"})
public class AdminAuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String uri = req.getRequestURI();
        String ctx = req.getContextPath();
        // 登录页 + 登录 action 放行
        if (uri.endsWith("/admin/login") || uri.endsWith("/admin/login.jsp")) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = req.getSession(false);
        Admin admin = (session == null) ? null : (Admin) session.getAttribute("currentAdmin");
        if (admin == null) {
            String back = URLEncoder.encode(uri.substring(ctx.length()), "UTF-8");
            resp.sendRedirect(ctx + "/admin/login?returnUrl=" + back);
            return;
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}
