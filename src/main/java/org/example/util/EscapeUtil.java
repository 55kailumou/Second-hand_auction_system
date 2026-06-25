package org.example.util;

/**
 * HTML/JS 转义工具：防止存储型 XSS
 *
 * 使用场景：
 *   1. JSP 里输出用户输入的字段（标题/地址/物流单号等）
 *      <%= EscapeUtil.html(order.getItemTitle()) %>
 *
 *   2. JSP 里把字符串拼到 JS 代码块
 *      const title = '<%= EscapeUtil.js(item.title) %>';
 *
 *   3. JSP 里把字符串拼到 HTML 属性
 *      <div title="<%= EscapeUtil.attr(item.title) %>">
 *
 * 常见 XSS 攻击 payload（演示项目用户字段应该全部过滤）：
 *   - <script>alert(1)</script>
 *   - <img src=x onerror=alert(1)>
 *   - javascript:alert(1)
 *   - " onmouseover="alert(1)
 */
public class EscapeUtil {

    private EscapeUtil() {}

    /**
     * HTML 文本转义：用于 <%= %> 输出到 HTML 文本节点
     * 转义：& < > " '
     */
    public static String html(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '&':  sb.append("&amp;");  break;
                case '<':  sb.append("&lt;");   break;
                case '>':  sb.append("&gt;");   break;
                case '"':  sb.append("&quot;"); break;
                case '\'': sb.append("&#x27;"); break;
                default:   sb.append(c);
            }
        }
        return sb.toString();
    }

    /**
     * HTML 属性转义：用于把字符串放到 HTML 属性值里（value="..." title="..."）
     * 比 html() 多转义一个空格（防止 "abc" onmouseover=...）
     */
    public static String attr(String s) {
        if (s == null) return "";
        return html(s).replace(" ", "&#32;");
    }

    /**
     * JS 字符串转义：用于把字符串拼到 inline JS（const x = '...'）
     * 转义：' " \ 反斜杠 换行 回车 制表符 < > &
     * 同时防止 </script> 提前结束 script 块
     */
    public static String js(String s) {
        if (s == null) return "";
        StringBuilder sb = new StringBuilder(s.length() + 16);
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\\': sb.append("\\\\"); break;
                case '\'': sb.append("\\'");  break;
                case '"':  sb.append("\\\""); break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                case '<':
                    // 防止 </script> 闭合
                    if (i + 1 < s.length() && s.charAt(i + 1) == '/') {
                        sb.append("<\\/");
                        i++;
                    } else {
                        sb.append("<");
                    }
                    break;
                case '/':
                    // 防止 </script> 闭合
                    if (i + 1 < s.length() && s.charAt(i + 1) == '>') {
                        sb.append("\\x2F>");
                        i++;
                    } else {
                        sb.append("/");
                    }
                    break;
                default:
                    sb.append(c);
            }
        }
        return sb.toString();
    }
}