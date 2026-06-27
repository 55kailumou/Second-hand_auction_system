<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>MyBatis 连通测试</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/cyberpunk.css">
</head>
<body>
    <div class="cp-container">
        <h1 class="cp-glitch" data-text="> MyBatis_CONNECT_OK">> MyBatis_CONNECT_OK</h1>
        <p class="cp-subtitle">// 从 user 表查询到的数据</p>
        <div class="cp-badge">RECORDS :: ${total}</div>

        <table class="cp-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>用户名</th>
                    <th>电话</th>
                    <th>邮箱</th>
                    <th>信用分</th>
                    <th>状态</th>
                    <th>注册时间</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="u" items="${users}">
                    <tr>
                        <td>${u.id}</td>
                        <td>${u.username}</td>
                        <td>${u.phone}</td>
                        <td>${u.email}</td>
                        <td>${u.creditScore}</td>
                        <td class="${u.status == 0 ? 'status-on' : 'status-off'}">
                            ${u.status == 0 ? '[ 正常 ]' : '[ 封禁 ]'}
                        </td>
                        <td>${u.registerTime}</td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>

        <a class="cp-btn" href="${pageContext.request.contextPath}/index.jsp">&lt; 返回首页</a>
    </div>
</body>
</html>
