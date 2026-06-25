<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>MyBatis 连通测试</title>
    <style>
        body { font-family: "Microsoft YaHei", sans-serif; background: #f9fafb; padding: 40px; }
        .container { max-width: 900px; margin: 0 auto; background: white; padding: 32px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.06); }
        h1 { color: #1f2937; margin-bottom: 8px; }
        .subtitle { color: #6b7280; margin-bottom: 24px; }
        .ok-badge { display: inline-block; background: #d1fae5; color: #065f46; padding: 6px 14px; border-radius: 6px; font-size: 13px; margin-bottom: 24px; }
        table { width: 100%; border-collapse: collapse; margin-top: 16px; }
        th { background: #f3f4f6; padding: 12px; text-align: left; color: #374151; border-bottom: 2px solid #e5e7eb; }
        td { padding: 12px; border-bottom: 1px solid #f3f4f6; color: #4b5563; }
        tr:hover td { background: #f9fafb; }
        .status-0 { color: #059669; font-weight: 600; }
        .status-1 { color: #dc2626; font-weight: 600; }
        .back { display: inline-block; margin-top: 24px; color: #667eea; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <h1>✓ MyBatis 连通测试</h1>
        <p class="subtitle">从 user 表查询到的数据</p>
        <div class="ok-badge">共 ${total} 条记录</div>

        <table>
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
                        <td class="${u.status == 0 ? 'status-0' : 'status-1'}">
                            ${u.status == 0 ? '正常' : '封禁'}
                        </td>
                        <td>${u.registerTime}</td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>

        <a class="back" href="${pageContext.request.contextPath}/index.jsp">← 返回首页</a>
    </div>
</body>
</html>