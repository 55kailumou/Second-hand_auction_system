<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>404 · 页面不存在</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/cyberpunk.css">
</head>
<body class="error-body">
    <div class="scanline"></div>
    <div class="error-box">
        <h1 class="error-404">404</h1>
        <p class="error-sub">// PAGE NOT FOUND</p>
        <a class="cp-btn error-btn" href="${pageContext.request.contextPath}/index.jsp">[ 返回首页 ]</a>
    </div>
</body>
</html>
