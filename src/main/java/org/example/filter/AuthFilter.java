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
 * 设计原则：
 *   1. 打开网站默认就是首页（访客状态），登录/注册入口在右上角
 *   2. 访客可浏览拍品（list/detail/result），但发拍品/出价/下单/看个人中心必须登录
 *
 * 放行规则（无需登录）：
 *   - 静态资源：/static/*
 *   - 首页/测试：/index.jsp、/hello
 *   - /item 浏览类：action ∈ {list, detail, result}
 *   - /user 认证类：action ∈ {login, register, check-username, check-phone, logout}
 *   - /bid 查询类：action ∈ {history, settle}
 *
 * 其余 URL 必须登录后才能访问（包括 /item 的 publish-page、/order/*、/user?action=center、/bid?action=place）
 *
 * 未登录访问受保护资源：
 *   - 普通请求 → 重定向到登录页（带 returnUrl 登录后跳回）
 *   - AJAX 请求 → 返回 401 JSON
 */
public class AuthFilter implements Filter {

    /** 用户 Servlet 的公共 action（认证相关） */
    private static final List<String> PUBLIC_USER_ACTIONS = Arrays.asList(
            "login", "register", "check-username", "check-phone", "logout"
    );

    /** 拍品 Servlet 的公共 action（浏览类，访客可访问） */
    private static final List<String> PUBLIC_ITEM_ACTIONS = Arrays.asList(
            "list", "detail", "result"
    );

    /** 出价 Servlet 的公共 action（仅查询类；settle 必须登录，详见 #P0-1 安全修复） */
    private static final List<String> PUBLIC_BID_ACTIONS = Arrays.asList(
            "history"
    );

    /** 路径前缀直接放行（首页、静态资源、admin 路径） */
    private boolean isPublicPath(String path) {
        // 空路径 "/" 也放行：让 Tomcat 内部按 welcome-file 自动跳转到 index.jsp
        if (path.equals("/")
                || path.startsWith("/static/")
                || path.equals("/index.jsp")
                || path.equals("/hello")) {
            return true;
        }
        // /admin 和 /admin/* 都放行：admin 鉴权交给 AdminAuthFilter（它会放行 /admin/login）
        // 这里必须先放行，否则 AuthFilter 会把未登录的 admin 访问重定向到用户登录页
        // 注意：/admin（不带尾斜杠）和 /admin/* 是两个不同的路径，要分别匹配
        if (path.equals("/admin") || path.startsWith("/admin/")) {
            return true;
        }
        return false;
    }

    /** Servlet 路径 + action 是否在公共白名单 */
    private boolean isPublicAction(String path, String action) {
        if ("/user".equals(path) && action != null && PUBLIC_USER_ACTIONS.contains(action)) {
            return true;
        }
        if ("/item".equals(path)) {
            // item 没传 action 时默认为 list，也放行
            if (action == null || PUBLIC_ITEM_ACTIONS.contains(action)) {
                return true;
            }
        }
        if ("/bid".equals(path)) {
            // bid 没传 action 时默认为 history，也放行
            if (action == null || PUBLIC_BID_ACTIONS.contains(action)) {
                return true;
            }
        }
        // 前台公告：所有人可查看详情
        if ("/notice".equals(path) && "detail".equals(action)) {
            return true;
        }
        return false;
    }

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
        String action = request.getParameter("action");

        // 1. 公共路径 / 公共 action → 直接放行
        if (isPublicPath(path) || isPublicAction(path, action)) {
            chain.doFilter(req, resp);
            return;
        }

        // 2. 其余路径检查登录状态
        HttpSession session = request.getSession(false);
        User currentUser = session == null ? null : (User) session.getAttribute("currentUser");

        if (currentUser == null) {
            // AJAX 请求 → 返回 401 JSON
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

        // 3. 已登录，放行
        chain.doFilter(req, resp);
    }

    @Override
    public void destroy() {
        System.out.println("[AuthFilter] 销毁");
    }
}