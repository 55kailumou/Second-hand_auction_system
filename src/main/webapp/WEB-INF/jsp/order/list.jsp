<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect(ctx + "/user?action=login&returnUrl=" +
                java.net.URLEncoder.encode("/order?action=list", "UTF-8"));
        return;
    }

    String error = (String) request.getAttribute("error");
    java.util.List<org.example.entity.OrderInfo> orders =
            (java.util.List<org.example.entity.OrderInfo>) request.getAttribute("orders");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNum = (Integer) request.getAttribute("page");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    String role = (String) request.getAttribute("role");
    Integer statusFilter = (Integer) request.getAttribute("status");
    String keyword = (String) request.getAttribute("keyword");
    Integer pageSize = (Integer) request.getAttribute("pageSize");
    if (orders == null) orders = new java.util.ArrayList<>();
    if (total == null) total = 0;
    if (pageNum == null) pageNum = 1;
    if (totalPages == null) totalPages = 1;
    if (pageSize == null) pageSize = 10;
    if (role == null) role = "buyer";
    if (keyword == null) keyword = "";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我的订单 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        :root {
            --cp-yellow: #FFEE00;
            --cp-yellow-dim: #AA9900;
            --cp-bg: #000;
            --cp-card-bg: #0a0a0a;
            --cp-border: #FFEE00;
            --cp-text: #FFEE00;
            --cp-text-dim: #AA9900;
            --cp-text-muted: #555;
            --cp-font: 'Sarasa Mono SC', monospace;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--cp-bg);
            color: var(--cp-text);
            font-family: var(--cp-font);
            line-height: 1.6;
            min-height: 100vh;
        }
        a { color: var(--cp-yellow); text-decoration: none; transition: opacity 0.15s; }
        a:hover { opacity: 0.7; }
        i.fa { margin-right: 4px; }

        /* ===== NAV ===== */

        /* ===== CONTAINER ===== */
        .cp-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px 60px;
        }

        /* ===== PAGE HEADER ===== */
        .cp-page-header {
            background: var(--cp-card-bg);
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
            padding: 20px 24px;
            margin-top: 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }
        .cp-page-title {
            font-size: 22px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        .cp-page-title small {
            font-size: 13px;
            color: var(--cp-text-dim);
            margin-left: 8px;
            font-weight: 400;
        }

        /* ===== TABS ===== */
        .cp-tabs {
            display: flex;
            gap: 4px;
            background: #111;
            border: 1px solid var(--cp-border);
            padding: 4px;
            clip-path: polygon(6px 0, 100% 0, 100% 100%, 0 100%, 0 6px);
        }
        .cp-tab {
            padding: 8px 18px;
            cursor: pointer;
            font-size: 13px;
            color: var(--cp-text-dim);
            transition: all 0.2s;
            text-decoration: none;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            font-family: var(--cp-font);
        }
        .cp-tab.active {
            background: var(--cp-yellow);
            color: #000;
            font-weight: 600;
        }
        .cp-tab:hover:not(.active) {
            background: rgba(255, 238, 0, 0.1);
            color: var(--cp-yellow);
        }

        /* ===== FILTER BAR ===== */
        .cp-filter-bar {
            background: var(--cp-card-bg);
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 8px 100%, 0 calc(100% - 8px));
            padding: 14px 20px;
            margin-top: 16px;
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        .cp-filter-chip {
            padding: 5px 14px;
            cursor: pointer;
            font-size: 12px;
            color: var(--cp-text-dim);
            background: #111;
            border: 1px solid #333;
            text-decoration: none;
            text-transform: uppercase;
            font-family: var(--cp-font);
            transition: all 0.2s;
        }
        .cp-filter-chip:hover {
            border-color: var(--cp-yellow);
            color: var(--cp-yellow);
        }
        .cp-filter-chip.active {
            background: var(--cp-yellow);
            color: #000;
            border-color: var(--cp-yellow);
            font-weight: 600;
        }
        .cp-search-input {
            padding: 6px 12px;
            background: #111;
            border: 1px solid #333;
            color: var(--cp-yellow);
            font-size: 13px;
            min-width: 200px;
            font-family: var(--cp-font);
            outline: none;
        }
        .cp-search-input:focus {
            border-color: var(--cp-yellow);
        }
        .cp-search-input::placeholder {
            color: #555;
        }

        /* ===== ORDER LIST ===== */
        .cp-order-list {
            margin-top: 16px;
            display: flex;
            flex-direction: column;
            gap: 12px;
        }

        /* ===== ORDER CARD ===== */
        .cp-order-card {
            background: var(--cp-card-bg);
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 10px 100%, 0 calc(100% - 10px));
            transition: all 0.2s;
        }
        .cp-order-card:hover {
            border-color: #fff;
            box-shadow: 0 0 12px rgba(255, 238, 0, 0.3);
        }
        .cp-order-head {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 10px 20px;
            border-bottom: 1px solid #222;
            font-size: 13px;
            color: var(--cp-text-dim);
        }
        .cp-order-no {
            font-family: var(--cp-font);
            color: var(--cp-yellow);
        }
        .cp-order-body {
            display: flex;
            gap: 16px;
            padding: 16px 20px;
        }
        .cp-order-cover {
            width: 100px;
            height: 100px;
            border: 1px solid #333;
            background: #0d0d0d center/cover no-repeat;
            flex-shrink: 0;
            display: grid;
            place-items: center;
            color: #555;
            font-size: 30px;
        }
        .cp-order-info {
            flex: 1;
            min-width: 0;
        }
        .cp-order-title {
            font-size: 15px;
            font-weight: 600;
            color: var(--cp-yellow);
            margin-bottom: 8px;
            line-height: 1.4;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .cp-order-meta {
            display: flex;
            gap: 16px;
            font-size: 12px;
            color: var(--cp-text-dim);
            margin-bottom: 8px;
        }
        .cp-order-price {
            font-size: 18px;
            font-weight: 700;
            color: #fff;
            text-shadow: 0 0 6px var(--cp-yellow);
        }
        .cp-order-actions {
            display: flex;
            flex-direction: column;
            gap: 8px;
            align-items: flex-end;
            justify-content: space-between;
            min-width: 130px;
        }

        /* ===== BADGES ===== */
        .cp-badge {
            display: inline-block;
            padding: 3px 10px;
            font-size: 11px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: 1px solid transparent;
            font-family: var(--cp-font);
        }
        .cp-badge-warning {
            background: #332800;
            color: #FFEE00;
            border-color: #FFEE00;
        }
        .cp-badge-info {
            background: #001a33;
            color: #66bbff;
            border-color: #66bbff;
        }
        .cp-badge-primary {
            background: #331a00;
            color: #ff8800;
            border-color: #ff8800;
        }
        .cp-badge-success {
            background: #00331a;
            color: #00ff88;
            border-color: #00ff88;
        }
        .cp-badge-gray {
            background: #1a1a1a;
            color: #888;
            border-color: #555;
        }

        /* ===== EMPTY STATE ===== */
        .cp-empty {
            text-align: center;
            padding: 80px 20px;
            background: var(--cp-card-bg);
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
        }
        .cp-empty i {
            font-size: 64px;
            color: #333;
            margin-bottom: 16px;
        }
        .cp-empty h3 {
            color: var(--cp-yellow);
            margin-bottom: 8px;
        }
        .cp-empty p {
            color: var(--cp-text-dim);
            margin-bottom: 24px;
        }

        /* ===== PAGINATION ===== */
        .cp-pagination {
            display: flex;
            justify-content: center;
            gap: 4px;
            margin-top: 24px;
        }
        .cp-page-btn {
            min-width: 36px;
            height: 36px;
            padding: 0 10px;
            border: 1px solid #333;
            background: #0d0d0d;
            cursor: pointer;
            color: var(--cp-yellow);
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 13px;
            transition: all 0.2s;
            font-family: var(--cp-font);
        }
        .cp-page-btn:hover {
            border-color: var(--cp-yellow);
            background: rgba(255, 238, 0, 0.1);
        }
        .cp-page-btn.active {
            background: var(--cp-yellow);
            color: #000;
            border-color: var(--cp-yellow);
            font-weight: 600;
        }
        .cp-page-btn.disabled {
            opacity: 0.3;
            cursor: not-allowed;
            pointer-events: none;
        }

        /* ===== ALERT ===== */
        .cp-alert {
            margin-top: 16px;
            padding: 12px 16px;
            background: #220000;
            color: #ff4444;
            border: 1px solid #ff4444;
            font-family: var(--cp-font);
        }

        /* ===== BUTTONS ===== */
        .cp-btn {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 8px 16px;
            border: 1.5px solid var(--cp-border);
            background: transparent;
            color: var(--cp-yellow);
            font-family: var(--cp-font);
            font-size: 13px;
            cursor: pointer;
            text-decoration: none;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            transition: all 0.2s;
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
        }
        .cp-btn:hover {
            background: var(--cp-yellow);
            color: #000;
        }
        .cp-btn-sm {
            padding: 5px 12px;
            font-size: 11px;
        }

        /* ===== INLINE OVERRIDES ===== */
        .btn { font-family: var(--cp-font); }
    </style>
</head>
<body>

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
            <a href="<%=ctx%>/order?action=list" class="active">我的订单</a>
        </nav>
        <div class="cp-nav-user">
            <span>欢迎，</span>
            <span style="color: #fff; font-weight: 500;"><%= currentUser.getUsername() %></span>
            <a href="<%=ctx%>/user?action=logout" style="color: var(--cp-yellow);">退出</a>
        </div>
    </div>
</header>

<div class="cp-container">

    <!-- 页头 -->
    <div class="cp-page-header">
        <div class="cp-page-title">
            我的订单
            <small>共 <%= total %> 笔</small>
        </div>
        <div class="cp-tabs">
            <a href="<%=ctx%>/order?action=list&role=buyer" class="cp-tab <%= "buyer".equals(role) ? "active" : "" %>">我购买的</a>
            <a href="<%=ctx%>/order?action=list&role=seller" class="cp-tab <%= "seller".equals(role) ? "active" : "" %>">我卖出的</a>
            <a href="<%=ctx%>/order?action=list&role=all" class="cp-tab <%= "all".equals(role) ? "active" : "" %>">全部</a>
        </div>
    </div>

    <!-- 状态筛选 + 搜索 -->
    <div class="cp-filter-bar">
        <a href="<%=ctx%>/order?action=list&role=<%= role %>" class="cp-filter-chip <%= statusFilter == null ? "active" : "" %>">全部状态</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=0" class="cp-filter-chip <%= statusFilter != null && statusFilter == 0 ? "active" : "" %>">待付款</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=1" class="cp-filter-chip <%= statusFilter != null && statusFilter == 1 ? "active" : "" %>">已付款</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=2" class="cp-filter-chip <%= statusFilter != null && statusFilter == 2 ? "active" : "" %>">已发货</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=3" class="cp-filter-chip <%= statusFilter != null && statusFilter == 3 ? "active" : "" %>">已收货</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=6" class="cp-filter-chip <%= statusFilter != null && statusFilter == 6 ? "active" : "" %>">已取消</a>

        <form style="margin-left: auto; display: flex; gap: 8px;" action="<%=ctx%>/order" method="get">
            <input type="hidden" name="action" value="list">
            <input type="hidden" name="role" value="<%= role %>">
            <% if (statusFilter != null) { %>
                <input type="hidden" name="status" value="<%= statusFilter %>">
            <% } %>
            <input type="text" name="keyword" value="<%= keyword %>" placeholder="搜索订单号/拍品标题" class="cp-search-input">
            <button type="submit" class="cp-btn cp-btn-sm">搜索</button>
        </form>
    </div>

    <% if (error != null) { %>
        <div class="cp-alert">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- 订单列表 -->
    <div class="cp-order-list">
        <% if (orders.isEmpty()) { %>
            <div class="cp-empty">
                <i class="fa fa-inbox"></i>
                <h3>暂无订单</h3>
                <p><% if ("seller".equals(role)) { %>你还没有卖出任何拍品<% } else { %>去逛逛拍品，发现心仪好物吧<% } %></p>
                <a href="<%=ctx%>/item?action=list" class="cp-btn">浏览拍品</a>
            </div>
        <% } else { %>
            <% for (org.example.entity.OrderInfo order : orders) { %>
                <div class="cp-order-card">
                    <div class="cp-order-head">
                        <div>
                            <span>订单号：</span>
                            <span class="cp-order-no"><%= order.getOrderNo() %></span>
                            <span style="margin-left: 12px;"><%= order.getCreateTime() == null ? "" : order.getCreateTime().toString().substring(0, 16).replace('T', ' ') %></span>
                        </div>
                        <span class="cp-badge <%= order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("warning") ? "cp-badge-warning" : order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("info") ? "cp-badge-info" : order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("primary") ? "cp-badge-primary" : order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("success") ? "cp-badge-success" : "cp-badge-gray" %>"><%= order.getStatusText() %></span>
                    </div>
                    <div class="cp-order-body">
                        <div class="cp-order-cover" style="<%= order.getCoverImage() != null && !order.getCoverImage().isEmpty() ? "background-image: url('" + order.getCoverImage() + "');" : "" %>">
                            <% if (order.getCoverImage() == null || order.getCoverImage().isEmpty()) { %>
                                <i class="fa fa-image"></i>
                            <% } %>
                        </div>
                        <div class="cp-order-info">
                            <div class="cp-order-title"><%= EscapeUtil.html(order.getItemTitle()) %></div>
                            <div class="cp-order-meta">
                                <span>订单编号 <%= order.getId() %></span>
                                <span><%= "buyer".equals(role) ? "卖家" : "买家" %> ID <%= "buyer".equals(role) ? order.getSellerId() : order.getBuyerId() %></span>
                            </div>
                            <div class="cp-order-price">¥<%= order.getFinalPrice() == null ? "0.00" : order.getFinalPrice().toPlainString() %></div>
                        </div>
                        <div class="cp-order-actions">
                            <a href="<%=ctx%>/order?action=detail&id=<%= order.getId() %>" class="cp-btn cp-btn-sm">查看详情</a>
                            <% if ("buyer".equals(role) && order.getStatus() != null && order.getStatus() == 0) { %>
                                <a href="<%=ctx%>/order?action=detail&id=<%= order.getId() %>" class="cp-btn cp-btn-sm">去付款</a>
                            <% } %>
                        </div>
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>

    <!-- 分页 -->
    <% if (totalPages > 1) { %>
        <div class="cp-pagination">
            <a href="<%=ctx%>/order?action=list&role=<%= role %>&page=<%= Math.max(1, pageNum - 1) %><%= statusFilter != null ? "&status=" + statusFilter : "" %><%= keyword != null && !keyword.isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
               class="cp-page-btn <%= pageNum <= 1 ? "disabled" : "" %>">上一页</a>
            <% for (int p = 1; p <= totalPages; p++) { %>
                <a href="<%=ctx%>/order?action=list&role=<%= role %>&page=<%= p %><%= statusFilter != null ? "&status=" + statusFilter : "" %><%= keyword != null && !keyword.isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
                   class="cp-page-btn <%= p == pageNum ? "active" : "" %>"><%= p %></a>
            <% } %>
            <a href="<%=ctx%>/order?action=list&role=<%= role %>&page=<%= Math.min(totalPages, pageNum + 1) %><%= statusFilter != null ? "&status=" + statusFilter : "" %><%= keyword != null && !keyword.isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
               class="cp-page-btn <%= pageNum >= totalPages ? "disabled" : "" %>">下一页</a>
        </div>
    <% } %>
</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
</body>
</html>