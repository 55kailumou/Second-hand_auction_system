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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: var(--color-bg); }
        .header { background: #fff; padding: 14px 0;
                  box-shadow: var(--shadow-sm); position: sticky; top: 0; z-index: 100; }
        .header-inner { max-width: 1200px; margin: 0 auto; padding: 0 24px;
                        display: flex; align-items: center; justify-content: space-between; }
        .logo { font-size: 20px; font-weight: 700; color: var(--color-primary);
                display: flex; align-items: center; gap: 8px; }
        .nav { display: flex; gap: 24px; }
        .nav a { color: var(--color-text); font-size: 14px; }
        .nav a:hover, .nav a.active { color: var(--color-primary); }
        .user-info { display: flex; align-items: center; gap: 12px; font-size: 13px; }

        .result-hero { padding: 60px 24px; text-align: center;
                       background: linear-gradient(135deg, #fff3eb 0%, #ffe5d0 100%);
                       border-radius: var(--radius-lg); margin-top: 20px;
                       position: relative; overflow: hidden; }
        .result-hero.sold { background: linear-gradient(135deg, #fff3eb 0%, #ffd4a8 100%); }
        .result-hero.failed { background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%); }

        .result-icon { font-size: 96px; margin-bottom: 16px; display: block;
                       color: var(--color-primary); }
        .result-hero.failed .result-icon { color: #9ca3af; }
        .result-title { font-size: 32px; font-weight: 700; margin-bottom: 8px;
                        color: var(--color-text); }
        .result-title .accent { color: var(--color-primary); }
        .result-subtitle { font-size: 16px; color: var(--color-muted); margin-bottom: 24px; }

        .result-meta { display: inline-flex; gap: 32px; padding: 16px 32px;
                       background: rgba(255,255,255,0.7); border-radius: var(--radius);
                       backdrop-filter: blur(4px); }
        .result-meta-item { text-align: center; }
        .result-meta-label { font-size: 12px; color: var(--color-muted); margin-bottom: 4px; }
        .result-meta-value { font-size: 22px; font-weight: 700; color: var(--color-primary); }

        .content-card { background: #fff; border-radius: var(--radius-lg);
                        box-shadow: var(--shadow-sm); padding: 24px;
                        margin-top: 20px; }
        .section-title { font-size: 16px; font-weight: 600; margin-bottom: 16px;
                         display: flex; align-items: center; gap: 8px; }
        .section-title::before { content: ''; display: inline-block; width: 4px; height: 18px;
                                  background: var(--color-primary); border-radius: 2px; }

        .winner-card { display: flex; align-items: center; gap: 16px; padding: 16px;
                       background: linear-gradient(135deg, #fff3eb 0%, #ffe5d0 100%);
                       border-radius: var(--radius); }
        .winner-avatar { width: 56px; height: 56px; border-radius: 50%;
                         background: var(--color-primary); color: #fff;
                         display: grid; place-items: center; font-size: 22px;
                         font-weight: 700; }
        .winner-info { flex: 1; }
        .winner-name { font-size: 18px; font-weight: 600; color: var(--color-text); }
        .winner-price { font-size: 16px; color: var(--color-primary); margin-top: 4px; }

        .item-mini { display: flex; gap: 16px; padding: 16px;
                      border: 1px solid var(--color-border); border-radius: var(--radius); }
        .item-mini-cover { width: 120px; height: 120px; border-radius: var(--radius);
                           background: #f3f4f6 center/cover no-repeat; flex-shrink: 0;
                           display: grid; place-items: center; color: var(--color-muted); font-size: 36px; }
        .item-mini-info { flex: 1; min-width: 0; }
        .item-mini-title { font-size: 16px; font-weight: 600; margin-bottom: 8px; }
        .item-mini-desc { font-size: 13px; color: var(--color-muted); line-height: 1.6; }

        .action-bar { display: flex; gap: 12px; justify-content: center;
                      margin-top: 24px; flex-wrap: wrap; }
    </style>
</head>
<body>

<!-- 顶部导航 -->
<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <i class="fa fa-gavel"></i> 二手拍卖
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
        </nav>
        <div class="user-info">
            <% if (currentUser != null) { %>
                <span>欢迎，</span>
                <span style="color: var(--color-text); font-weight: 500;"><%= currentUser.getUsername() %></span>
                <a href="<%=ctx%>/user?action=logout" style="color: var(--color-primary);">退出</a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" class="btn btn-ghost btn-sm">登录</a>
                <a href="<%=ctx%>/user?action=register" class="btn btn-primary btn-sm">免费注册</a>
            <% } %>
        </div>
    </div>
</header>

<div class="container" style="max-width: 900px; margin: 0 auto; padding: 0 24px 60px;">

    <% if (item == null) { %>
        <div class="content-card" style="text-align: center; padding: 60px;">
            <i class="fa fa-exclamation-triangle" style="font-size: 48px; color: var(--color-muted);"></i>
            <h3 style="margin: 16px 0 8px;">拍品不存在</h3>
            <a href="<%=ctx%>/item?action=list" class="btn btn-primary">返回拍品列表</a>
        </div>
    <% } else if ("sold".equals(resultType)) { %>
        <!-- 已成交 -->
        <div class="result-hero sold">
            <i class="fa fa-trophy result-icon"></i>
            <div class="result-title">拍卖 <span class="accent">成交</span>！</div>
            <div class="result-subtitle">恭喜中拍，请尽快完成付款</div>
            <div class="result-meta">
                <div class="result-meta-item">
                    <div class="result-meta-label">成交价</div>
                    <div class="result-meta-value">¥<%= winner != null && winner.getBidAmount() != null ? winner.getBidAmount().toPlainString() : "0.00" %></div>
                </div>
                <div class="result-meta-item">
                    <div class="result-meta-label">出价次数</div>
                    <div class="result-meta-value"><%= bidCount %></div>
                </div>
                <div class="result-meta-item">
                    <div class="result-meta-label">出价人数</div>
                    <div class="result-meta-value">--</div>
                </div>
            </div>
        </div>

        <div class="content-card">
            <div class="section-title">中拍信息</div>
            <div class="winner-card">
                <div class="winner-avatar">
                    <%= winnerUser != null && winnerUser.getUsername() != null ? EscapeUtil.html(winnerUser.getUsername().substring(0, 1).toUpperCase()) : "?" %>
                </div>
                <div class="winner-info">
                    <div class="winner-name"><%= winnerUser != null ? EscapeUtil.html(winnerUser.getUsername()) : "(用户已注销)" %></div>
                    <div class="winner-price">
                        <i class="fa fa-gavel"></i> 出价 ¥<%= winner != null && winner.getBidAmount() != null ? winner.getBidAmount().toPlainString() : "0.00" %>
                        <% if (winner != null && winner.getBidTime() != null) { %>
                            <span style="color: var(--color-muted); font-size: 13px; margin-left: 12px;">
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

        <div class="content-card">
            <div class="section-title">拍品信息</div>
            <div class="item-mini">
                <div class="item-mini-cover" style="<%= item.getCoverImage() != null && !item.getCoverImage().isEmpty() ? "background-image: url('" + item.getCoverImage() + "');" : "" %>">
                    <% if (item.getCoverImage() == null || item.getCoverImage().isEmpty()) { %>
                        <i class="fa fa-image"></i>
                    <% } %>
                </div>
                <div class="item-mini-info">
                    <div class="item-mini-title"><%= EscapeUtil.html(item.getTitle()) %></div>
                    <div class="item-mini-desc">
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
        <div class="result-hero failed">
            <i class="fa fa-frown-o result-icon"></i>
            <div class="result-title">拍卖 <span style="color: #6b7280;">流拍</span></div>
            <div class="result-subtitle">很遗憾，本次拍卖无人出价</div>
        </div>

        <div class="content-card">
            <div class="section-title">拍品信息</div>
            <div class="item-mini">
                <div class="item-mini-cover" style="<%= item.getCoverImage() != null && !item.getCoverImage().isEmpty() ? "background-image: url('" + item.getCoverImage() + "');" : "" %>">
                    <% if (item.getCoverImage() == null || item.getCoverImage().isEmpty()) { %>
                        <i class="fa fa-image"></i>
                    <% } %>
                </div>
                <div class="item-mini-info">
                    <div class="item-mini-title"><%= EscapeUtil.html(item.getTitle()) %></div>
                    <div class="item-mini-desc">
                        起拍价 ¥<%= item.getStartPrice() == null ? "0.00" : item.getStartPrice().toPlainString() %>
                        · 结束于 <%= item.getEndTime() == null ? "-" : item.getEndTime().toString().substring(0, 16).replace('T', ' ') %>
                    </div>
                </div>
            </div>
            <div class="action-bar">
                <a href="<%=ctx%>/item?action=list" class="btn btn-primary">看看其他拍品</a>
                <% if (currentUser != null && item.getSellerId() != null && item.getSellerId().equals(currentUser.getId())) { %>
                    <a href="<%=ctx%>/item?action=publish-page" class="btn btn-ghost">重新发布</a>
                <% } %>
            </div>
        </div>

    <% } else { %>
        <!-- 未知状态 -->
        <div class="content-card">
            <div class="section-title">拍卖状态</div>
            <p style="color: var(--color-muted);">该拍品当前状态：<%= item.getStatus() == null ? "未知" : item.getStatus() %></p>
            <p style="color: var(--color-muted);">结束时间：<%= item.getEndTime() == null ? "-" : item.getEndTime().toString().replace('T', ' ') %></p>
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