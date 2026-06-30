<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
    String type    = (String) request.getAttribute("type");
    String status  = (String) request.getAttribute("status");
    String message = (String) request.getAttribute("message");
    String itemId  = (String) request.getAttribute("itemId");
    String orderNo = (String) request.getAttribute("orderNo");
    if (type == null) type = "deposit";
    if (status == null) status = "fail";
    if (message == null) message = "";
    boolean isSuccess = "success".equals(status);
    boolean isCancel  = "cancel".equals(status);

    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) { response.sendRedirect(ctx + "/user?action=login"); return; }

    java.math.BigDecimal balance = null;
    java.math.BigDecimal platformAfter = null;
    try (org.apache.ibatis.session.SqlSession sqlSession = org.example.util.MyBatisUtil.openSession()) {
        org.example.mapper.UserMapper userMapper = sqlSession.getMapper(org.example.mapper.UserMapper.class);
        org.example.entity.User u = userMapper.findById(currentUser.getId());
        if (u != null) balance = u.getBalance();
        org.example.entity.SystemAccount sa =
                sqlSession.getMapper(org.example.mapper.SystemAccountMapper.class).get();
        if (sa != null) platformAfter = sa.getBalance();
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>支付结果 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #000; color: #FFEE00; font-family: 'Sarasa Mono SC', Consolas, monospace; min-height: 100vh; }
        .scanline {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none; z-index: 9999;
            background: repeating-linear-gradient(0deg, transparent, transparent 2px,
                rgba(0, 240, 255, 0.03) 2px, rgba(0, 240, 255, 0.03) 4px);
        }
        .result-wrap { max-width: 560px; margin: 60px auto; padding: 0 16px; }
        .result-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.2);
            border-radius: 2px; padding: 40px 32px; text-align: center;
        }
        .result-icon { font-size: 64px; margin-bottom: 16px; }
        .result-icon.success { color: #00FF41; text-shadow: 0 0 12px #00FF41; }
        .result-icon.fail    { color: #FF003C; text-shadow: 0 0 12px #FF003C; }
        .result-icon.cancel  { color: #FFEE00; opacity: 0.6; }
        .result-title { font-size: 22px; font-weight: 700; margin-bottom: 12px; }
        .result-title.success { color: #00FF41; }
        .result-title.fail    { color: #FF003C; }
        .result-title.cancel  { color: #FFEE00; }
        .result-msg {
            font-size: 14px; color: rgba(255, 238, 0, 0.7);
            background: rgba(0, 240, 255, 0.04);
            border: 1px solid rgba(0, 240, 255, 0.15);
            border-radius: 2px; padding: 12px; margin: 16px 0;
        }
        .result-balances {
            display: grid; grid-template-columns: 1fr 1fr; gap: 8px;
            margin: 16px 0;
        }
        .balance-box {
            background: #0a0a0a; border: 1px solid rgba(0, 240, 255, 0.1);
            border-radius: 2px; padding: 12px;
        }
        .balance-box .label { font-size: 11px; color: rgba(255, 238, 0, 0.5); margin-bottom: 4px; }
        .balance-box .value { font-size: 18px; font-weight: 700; color: #00F0FF; }
        .result-actions { display: flex; gap: 8px; margin-top: 20px; }
        .btn-primary, .btn-secondary {
            flex: 1; padding: 12px; font-size: 14px; font-weight: 600;
            border-radius: 2px; cursor: pointer; text-align: center;
            text-decoration: none; display: inline-flex; align-items: center; justify-content: center; gap: 4px;
            font-family: inherit; transition: all 0.15s;
        }
        .btn-primary { background: #00F0FF; color: #000; border: 1px solid #00F0FF; }
        .btn-primary:hover { background: #FFEE00; border-color: #FFEE00; }
        .btn-secondary { background: transparent; color: #00F0FF; border: 1px solid #00F0FF; }
        .btn-secondary:hover { background: rgba(0, 240, 255, 0.1); }
    </style>
</head>
<body>

<div class="scanline"></div>

<div class="result-wrap">
    <div class="result-card">
        <% if (isSuccess) { %>
            <div class="result-icon success"><i class="fa fa-check-circle"></i></div>
            <div class="result-title success">支付成功</div>
        <% } else if (isCancel) { %>
            <div class="result-icon cancel"><i class="fa fa-times-circle"></i></div>
            <div class="result-title cancel">已取消</div>
        <% } else { %>
            <div class="result-icon fail"><i class="fa fa-exclamation-circle"></i></div>
            <div class="result-title fail">支付失败</div>
        <% } %>

        <div class="result-msg"><%= message %></div>

        <% if (isSuccess) { %>
        <div class="result-balances">
            <div class="balance-box">
                <div class="label">您的余额</div>
                <div class="value">¥<%= balance == null ? "0.00" : balance.toPlainString() %></div>
            </div>
            <div class="balance-box">
                <div class="label">平台账户</div>
                <div class="value">¥<%= platformAfter == null ? "0.00" : platformAfter.toPlainString() %></div>
            </div>
        </div>
        <% } %>

        <div class="result-actions">
            <% if (isSuccess) { %>
                <% if ("deposit".equals(type)) { %>
                    <a href="<%=ctx%>/item?action=detail&id=<%= itemId %>" class="btn-primary">
                        <i class="fa fa-gavel"></i> 立即出价
                    </a>
                    <a href="<%=ctx%>/deposit?action=my" class="btn-secondary">
                        <i class="fa fa-list"></i> 我的押金
                    </a>
                <% } else { %>
                    <a href="<%=ctx%>/order?action=detail&id=<%= orderNo == null ? "" : "" %>" class="btn-primary"
                       onclick="<%= orderNo == null ? "" : "goToOrder(this, '" + orderNo + "'); return false;" %>">
                        <i class="fa fa-file-text-o"></i> 查看订单
                    </a>
                    <a href="<%=ctx%>/user?action=center" class="btn-secondary">
                        <i class="fa fa-user"></i> 个人中心
                    </a>
                <% } %>
            <% } else { %>
                <% if ("deposit".equals(type) && itemId != null) { %>
                    <a href="<%=ctx%>/deposit?action=checkout&itemId=<%= itemId %>" class="btn-primary">
                        <i class="fa fa-refresh"></i> 重试
                    </a>
                <% } else if ("final".equals(type) && orderNo != null) { %>
                    <a href="<%=ctx%>/order?action=detail&id=<%= orderNo %>" class="btn-primary">
                        <i class="fa fa-refresh"></i> 返回订单
                    </a>
                <% } %>
                <a href="<%=ctx%>/index.jsp" class="btn-secondary">
                    <i class="fa fa-home"></i> 回首页
                </a>
            <% } %>
        </div>
    </div>
</div>

<script>
    // 跳到订单详情（orderNo → id）
    function goToOrder(btn, orderNo) {
        const xhr = new XMLHttpRequest();
        xhr.open('GET', '<%=ctx%>/order?action=lookup&orderNo=' + encodeURIComponent(orderNo), true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return;
            try {
                const r = JSON.parse(xhr.responseText);
                if (r.id) {
                    window.location.href = '<%=ctx%>/order?action=detail&id=' + r.id;
                } else {
                    alert('订单查询失败');
                }
            } catch (e) {
                alert('请求失败：' + e.message);
            }
        };
        xhr.send();
    }
</script>

</body>
</html>
