<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    org.example.entity.AuctionItem item =
            (org.example.entity.AuctionItem) request.getAttribute("item");
    org.example.entity.BidRecord winner =
            (org.example.entity.BidRecord) request.getAttribute("winner");
    org.example.entity.User winnerUser =
            (org.example.entity.User) request.getAttribute("winnerUser");
    Integer bidCount = (Integer) request.getAttribute("bidCount");
    String resultType = (String) request.getAttribute("resultType");
    if (bidCount == null) bidCount = 0;
    if (resultType == null) resultType = "unknown";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>拍卖结果 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #0a0a0a; color: #FFEE00; font-family: 'Sarasa Mono SC', 'Source Code Pro', monospace; }

        .cp-nav-user a { color: #00f0ff; }
        .cp-container { max-width: 900px; margin: 0 auto; padding: 0 24px 60px; }

        .cp-result-hero { padding: 60px 24px; text-align: center; border: 1px solid #FFEE00; margin-top: 20px; position: relative; overflow: hidden; background: #0a0a0a; }
        .cp-result-hero.cp-sold { border-color: #FFEE00; box-shadow: 0 0 30px rgba(255,238,0,0.15); }
        .cp-result-hero.cp-failed { border-color: #ff00ff; box-shadow: 0 0 30px rgba(255,0,255,0.1); }
        .cp-result-icon { font-size: 96px; margin-bottom: 16px; display: block; color: #FFEE00; text-shadow: 0 0 20px #FFEE00; }
        .cp-result-hero.cp-failed .cp-result-icon { color: #ff00ff; text-shadow: 0 0 20px #ff00ff; }
        .cp-result-title { font-size: 32px; font-weight: 700; margin-bottom: 8px; color: #FFEE00; text-shadow: 0 0 10px #FFEE00; }
        .cp-result-title .accent { color: #FFEE00; }
        .cp-result-subtitle { font-size: 16px; color: #FFEE00; opacity: 0.7; margin-bottom: 24px; }
        .cp-result-meta { display: inline-flex; gap: 32px; padding: 16px 32px; background: rgba(17,17,17,0.9); border: 1px solid #FFEE00; }
        .cp-result-meta-item { text-align: center; }
        .cp-result-meta-label { font-size: 12px; color: #FFEE00; opacity: 0.7; margin-bottom: 4px; }
        .cp-result-meta-value { font-size: 22px; font-weight: 700; color: #00f0ff; text-shadow: 0 0 10px #00f0ff; }

        .cp-card { background: #111; border: 1px solid #FFEE00; padding: 24px; margin-top: 20px; }
        .cp-section-title { font-size: 16px; font-weight: 600; margin-bottom: 16px; display: flex; align-items: center; gap: 8px; color: #FFEE00; }
        .cp-section-title::before { content: ''; display: inline-block; width: 4px; height: 18px; background: #FFEE00; box-shadow: 0 0 8px #FFEE00; }

        .cp-winner-card { display: flex; align-items: center; gap: 16px; padding: 16px; border: 1px solid #FFEE00; background: #0a0a0a; }
        .cp-winner-avatar { width: 56px; height: 56px; background: #FFEE00; color: #0a0a0a; display: grid; place-items: center; font-size: 22px; font-weight: 700; }
        .cp-winner-info { flex: 1; }
        .cp-winner-name { font-size: 18px; font-weight: 600; color: #FFEE00; }
        .cp-winner-price { font-size: 16px; color: #00f0ff; margin-top: 4px; }

        .cp-item-mini { display: flex; gap: 16px; padding: 16px; border: 1px solid #FFEE00; }
        .cp-item-mini-cover { width: 120px; height: 120px; background: #0a0a0a center/cover no-repeat; border: 1px solid #FFEE00; flex-shrink: 0; display: grid; place-items: center; color: #FFEE00; font-size: 36px; }
        .cp-item-mini-info { flex: 1; min-width: 0; }
        .cp-item-mini-title { font-size: 16px; font-weight: 600; color: #FFEE00; margin-bottom: 8px; }
        .cp-item-mini-desc { font-size: 13px; color: #FFEE00; opacity: 0.7; line-height: 1.6; }

        .cp-action-bar { display: flex; gap: 12px; justify-content: center; margin-top: 24px; flex-wrap: wrap; }
        .cp-action-bar a { text-decoration: none; }

        .cp-scanline { position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 9999; background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.03) 2px, rgba(0,0,0,0.03) 4px); }
    </style>
</head>
<body>

<div class="cp-scanline"></div>

<!-- 顶部导航 -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <i class="fa fa-gavel"></i> 二手拍卖
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
        </nav>
        <div class="cp-nav-user">
            <% if (currentUser != null) { %>
                <span>欢迎，</span>
                <span style="font-weight: 500;"><%= currentUser.getUsername() %></span>
                <a href="<%=ctx%>/user?action=logout" style="color: #00f0ff;">退出</a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" class="btn btn-ghost btn-sm">登录</a>
                <a href="<%=ctx%>/user?action=register" class="btn btn-primary btn-sm">免费注册</a>
            <% } %>
        </div>
    </div>
</header>

<div class="cp-container">

    <% if (item == null) { %>
        <div class="cp-card" style="text-align: center; padding: 60px;">
            <i class="fa fa-exclamation-triangle" style="font-size: 48px; color: #FFEE00; opacity: 0.7;"></i>
            <h3 style="margin: 16px 0 8px; color: #FFEE00;">拍品不存在</h3>
            <a href="<%=ctx%>/item?action=list" class="btn btn-primary">返回拍品列表</a>
        </div>
    <% } else if ("sold".equals(resultType)) { %>
        <!-- 已成交 -->
        <div class="cp-result-hero cp-sold">
            <i class="fa fa-trophy cp-result-icon"></i>
            <div class="cp-result-title">拍卖 <span class="accent">成交</span>！</div>
            <div class="cp-result-subtitle">恭喜中拍，请尽快完成付款</div>
            <div class="cp-result-meta">
                <div class="cp-result-meta-item">
                    <div class="cp-result-meta-label">成交价</div>
                    <div class="cp-result-meta-value">¥<%= winner != null && winner.getBidAmount() != null ? winner.getBidAmount().toPlainString() : "0.00" %></div>
                </div>
                <div class="cp-result-meta-item">
                    <div class="cp-result-meta-label">出价次数</div>
                    <div class="cp-result-meta-value"><%= bidCount %></div>
                </div>
                <div class="cp-result-meta-item">
                    <div class="cp-result-meta-label">出价人数</div>
                    <div class="cp-result-meta-value">--</div>
                </div>
            </div>
        </div>

        <div class="cp-card">
            <div class="cp-section-title">中拍信息</div>
            <div class="cp-winner-card">
                <div class="cp-winner-avatar">
                    <%= winnerUser != null && winnerUser.getUsername() != null ? EscapeUtil.html(winnerUser.getUsername().substring(0, 1).toUpperCase()) : "?" %>
                </div>
                <div class="cp-winner-info">
                    <div class="cp-winner-name"><%= winnerUser != null ? EscapeUtil.html(winnerUser.getUsername()) : "(用户已注销)" %></div>
                    <div class="cp-winner-price">
                        <i class="fa fa-gavel"></i> 出价 ¥<%= winner != null && winner.getBidAmount() != null ? winner.getBidAmount().toPlainString() : "0.00" %>
                        <% if (winner != null && winner.getBidTime() != null) { %>
                            <span style="color: #FFEE00; opacity: 0.7; font-size: 13px; margin-left: 12px;">
                                <%= winner.getBidTime().toString().substring(0, 16).replace('T', ' ') %>
                            </span>
                        <% } %>
                    </div>
                </div>
                <% if (currentUser != null && winner != null && winner.getBidderId() != null && winner.getBidderId().equals(currentUser.getId())) { %>
                    <a href="<%=ctx%>/order?action=list&role=buyer" class="btn btn-primary" id="goPayBtn" data-item-id="<%= item.getId() %>">
                        <i class="fa fa-credit-card"></i> 立即下单付款
                    </a>
                <% } %>
            </div>
        </div>

        <div class="cp-card">
            <div class="cp-section-title">拍品信息</div>
            <div class="cp-item-mini">
                <div class="cp-item-mini-cover" style="<%= item.getCoverImage() != null && !item.getCoverImage().isEmpty() ? "background-image: url('" + item.getCoverImage() + "');" : "" %>">
                    <% if (item.getCoverImage() == null || item.getCoverImage().isEmpty()) { %>
                        <i class="fa fa-image"></i>
                    <% } %>
                </div>
                <div class="cp-item-mini-info">
                    <div class="cp-item-mini-title"><%= EscapeUtil.html(item.getTitle()) %></div>
                    <div class="cp-item-mini-desc">
                        <%= item.getDescription() != null ? EscapeUtil.html(item.getDescription().length() > 100 ? item.getDescription().substring(0, 100) + "..." : item.getDescription()) : "" %>
                    </div>
                    <div style="margin-top: 12px;">
                        <a href="<%=ctx%>/item?action=detail&id=<%= item.getId() %>" class="btn btn-ghost btn-sm">查看完整详情 →</a>
                    </div>
                </div>
            </div>
        </div>

    <% } else if ("failed".equals(resultType)) { %>
        <!-- 已流拍 -->
        <div class="cp-result-hero cp-failed">
            <i class="fa fa-frown-o cp-result-icon"></i>
            <div class="cp-result-title">拍卖 <span style="color: #ff00ff; text-shadow: 0 0 10px #ff00ff;">流拍</span></div>
            <div class="cp-result-subtitle">很遗憾，本次拍卖无人出价</div>
        </div>

        <div class="cp-card">
            <div class="cp-section-title">拍品信息</div>
            <div class="cp-item-mini">
                <div class="cp-item-mini-cover" style="<%= item.getCoverImage() != null && !item.getCoverImage().isEmpty() ? "background-image: url('" + item.getCoverImage() + "');" : "" %>">
                    <% if (item.getCoverImage() == null || item.getCoverImage().isEmpty()) { %>
                        <i class="fa fa-image"></i>
                    <% } %>
                </div>
                <div class="cp-item-mini-info">
                    <div class="cp-item-mini-title"><%= EscapeUtil.html(item.getTitle()) %></div>
                    <div class="cp-item-mini-desc">
                        起拍价 ¥<%= item.getStartPrice() == null ? "0.00" : item.getStartPrice().toPlainString() %>
                        · 结束于 <%= item.getEndTime() == null ? "-" : item.getEndTime().toString().substring(0, 16).replace('T', ' ') %>
                    </div>
                </div>
            </div>
            <div class="cp-action-bar">
                <a href="<%=ctx%>/item?action=list" class="btn btn-primary">看看其他拍品</a>
                <% if (currentUser != null && item.getSellerId() != null && item.getSellerId().equals(currentUser.getId())) { %>
                    <a href="<%=ctx%>/item?action=publish-page" class="btn btn-ghost">重新发布</a>
                <% } %>
            </div>
        </div>

    <% } else { %>
        <!-- 未知状态 -->
        <div class="cp-card">
            <div class="cp-section-title">拍卖状态</div>
            <p style="color: #FFEE00; opacity: 0.7;">该拍品当前状态：<%= item.getStatus() == null ? "未知" : item.getStatus() %></p>
            <p style="color: #FFEE00; opacity: 0.7;">结束时间：<%= item.getEndTime() == null ? "-" : item.getEndTime().toString().replace('T', ' ') %></p>
        </div>
    <% } %>

</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
// 中拍人点"立即下单付款"——查默认地址，调用 create 接口
const goPayBtn = document.getElementById('goPayBtn');
if (goPayBtn) {
    goPayBtn.addEventListener('click', async function(e) {
        e.preventDefault();
        const itemId = this.getAttribute('data-item-id');
        const ctx = '<%= ctx %>';

        try {
            // 调用通用接口查默认地址（前端简化：弹窗让用户输入地址 ID）
            // 实际项目里应该在个人中心有地址管理，这里先用 prompt 简化
            const addrInput = prompt('请输入收货地址 ID（演示项目，请到数据库 address 表查看）');
            if (!addrInput) return;
            const addressId = parseInt(addrInput);
            if (isNaN(addressId)) { toast('地址 ID 无效', 'error'); return; }

            const params = new URLSearchParams();
            params.append('itemId', itemId);
            params.append('addressId', addressId);
            const r = await axios.post(ctx + '/order?action=create', params);

            if (r.data.success) {
                toast('订单创建成功', 'success');
                setTimeout(() => {
                    location.href = ctx + '/order?action=detail&id=' + r.data.orderId;
                }, 800);
            } else {
                toast(r.data.message, 'error');
            }
        } catch (err) {
            toast('网络错误', 'error');
        }
    });
}
</script>
</body>
</html>
