package org.example.filter;

import javax.servlet.*;
import java.io.IOException;

/**
 * 字符编码过滤器：统一所有请求/响应为 UTF-8
 * 解决 JSP 中文乱码问题
 *
 * 顺序：在 web.xml 中显式注册，确保在 AuthFilter 之前执行
 */
public class EncodingFilter implements Filter {

    private String encoding = "UTF-8";

    @Override
    public void init(FilterConfig filterConfig) {
        String configEncoding = filterConfig.getInitParameter("encoding");
        if (configEncoding != null && !configEncoding.isEmpty()) {
            this.encoding = configEncoding;
        }
        System.out.println("[EncodingFilter] 初始化完成，编码：" + encoding);
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        // 请求编码（表单 POST 中文）
        request.setCharacterEncoding(encoding);
        // 响应字符编码（仅设置 charset，不动 Content-Type）
        // ⚠️ 不要在这里 setContentType("text/html...") —— 会把 CSS/JS/图片
        //    等所有静态资源的 MIME 类型强制改成 text/html，导致浏览器拒绝解析 CSS。
        //    MIME 类型由 JSP page directive / Servlet setContentType / Tomcat
        //    default servlet 根据扩展名各自管理。
        response.setCharacterEncoding(encoding);

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
        System.out.println("[EncodingFilter] 销毁");
    }
}