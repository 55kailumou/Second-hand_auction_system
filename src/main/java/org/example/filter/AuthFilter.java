package org.example.filter;

import org.example.entity.User;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/**
 * 登录拦截过滤器
 *
 * 放行规则（无需登录即可访问）：
 *   1. 静态资源：/static/*
 *   2. 公共页面：/index.jsp、/hello
 *   3. 用户登录注册：/user?action=login|register|check-*|logout
 *
 * 其他所有 URL 必须登录后才能访问。
 * 未登录访问 → 重定向到登录页（AJAX 请求则返回 401）。
 *
 * 顺序：在 web.xml 中显式注册，确保在 EncodingFilter 之后执行
 */
public class AuthFilter implements Filter {

    /** 完全放行的 URL 前缀 */
    private static final List<String> PUBLIC_PREFIXES = Arrays.asList(
            "/static/",
            "/index.jsp",
            "/hello"
    );

    /** Servlet action 放行（针对 /user?action=xxx 这种形式） */
    private static final List<String> PUBLIC_USER_ACTIONS = Arrays.asList(
            "login", "register", "check-username", "check-phone", "logout"
    );

    @Override
    public void init(FilterConfig filterConfig) {
        System.out.println("[AuthFilter] 初始化完成");
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) resp;

        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();
        String path = uri.substring(contextPath.length());

        // 1. 完全放行
        for (String prefix : PUBLIC_PREFIXES) {
            if (path.startsWith(prefix)) {
                chain.doFilter(req, resp);
                return;
            }
        }

        // 2. /user?action=login/register/check-* 放行（但 logout 不放行）
        if (path.equals("/user")) {
            String action = request.getParameter("action");
            if (action != null && PUBLIC_USER_ACTIONS.contains(action)) {
                chain.doFilter(req, resp);
                return;
            }
        }

        // 3. 检查 session
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            // 判断是否是 AJAX 请求（根据 X-Requested-With 头）
            String xhr = request.getHeader("X-Requested-With");
            if ("XMLHttpRequest".equals(xhr)) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"code\":401,\"message\":\"请先登录\"}");
                return;
            }
            // 普通请求 → 重定向到登录页（带 returnUrl 登录后跳回）
            String returnUrl = request.getQueryString() == null
                    ? path
                    : path + "?" + request.getQueryString();
            response.sendRedirect(contextPath + "/user?action=login&returnUrl="
                    + java.net.URLEncoder.encode(returnUrl, "UTF-8"));
            return;
        }

        // 4. 已登录，放行
        chain.doFilter(req, resp);
    }

    @Override
    public void destroy() {
        System.out.println("[AuthFilter] 销毁");
    }
}