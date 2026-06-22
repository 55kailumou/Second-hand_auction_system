<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>404 · 页面不存在</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f9fafb; height: 100vh; display: flex; align-items: center; justify-content: center; }
        .box { text-align: center; }
        h1 { font-size: 80px; color: #667eea; margin: 0; }
        p { color: #6b7280; margin: 16px 0; }
        a { color: #667eea; text-decoration: none; }
    </style>
</head>
<body>
    <div class="box">
        <h1>404</h1>
        <p>页面走丢了 ...</p>
        <a href="${pageContext.request.contextPath}/index.jsp">回首页</a>
    </div>
</body>
</html>