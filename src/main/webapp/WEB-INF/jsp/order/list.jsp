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

        .page-header { background: #fff; padding: 24px; border-radius: var(--radius-lg);
                       box-shadow: var(--shadow-sm); margin-top: 20px;
                       display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; }
        .page-title { font-size: 22px; font-weight: 700; }
        .page-title small { font-size: 13px; color: var(--color-muted); margin-left: 8px; font-weight: 400; }

        .role-tabs { display: flex; gap: 8px; background: #f3f4f6; padding: 4px; border-radius: 10px; }
        .role-tab { padding: 8px 18px; border-radius: 8px; cursor: pointer;
                    font-size: 14px; color: var(--color-muted); transition: all 0.2s; text-decoration: none; }
        .role-tab.active { background: #fff; color: var(--color-primary); font-weight: 500;
                           box-shadow: 0 1px 4px rgba(0,0,0,0.06); }

        .filter-bar { background: #fff; padding: 16px 24px; border-radius: var(--radius-lg);
                      box-shadow: var(--shadow-sm); margin-top: 16px;
                      display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
        .filter-chip { padding: 6px 14px; border-radius: 20px; cursor: pointer; font-size: 13px;
                       color: var(--color-text); background: #f3f4f6; text-decoration: none;
                       border: 1px solid transparent; transition: all 0.2s; }
        .filter-chip:hover { background: #e5e7eb; }
        .filter-chip.active { background: var(--color-primary-light); color: var(--color-primary);
                              border-color: var(--color-primary); font-weight: 500; }
        .search-input { padding: 6px 12px; border: 1px solid var(--color-border); border-radius: 6px;
                        font-size: 13px; min-width: 200px; }

        .order-list { margin-top: 16px; display: flex; flex-direction: column; gap: 12px; }

        .order-card { background: #fff; border-radius: var(--radius-lg);
                      box-shadow: var(--shadow-sm); overflow: hidden;
                      transition: all 0.2s; }
        .order-card:hover { box-shadow: var(--shadow); }
        .order-head { display: flex; align-items: center; justify-content: space-between;
                      padding: 12px 20px; border-bottom: 1px solid #f3f4f6;
                      font-size: 13px; color: var(--color-muted); }
        .order-no { font-family: 'Courier New', monospace; color: var(--color-text); }
        .order-body { display: flex; gap: 16px; padding: 16px 20px; }
        .order-cover { width: 100px; height: 100px; border-radius: var(--radius);
                       background: #f3f4f6 center/cover no-repeat; flex-shrink: 0;
                       display: grid; place-items: center; color: var(--color-muted); font-size: 30px; }
        .order-info { flex: 1; min-width: 0; }
        .order-title { font-size: 15px; font-weight: 600; color: var(--color-text);
                       margin-bottom: 8px; line-height: 1.4;
                       overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .order-meta { display: flex; gap: 16px; font-size: 12px; color: var(--color-muted);
                      margin-bottom: 8px; }
        .order-price { font-size: 18px; font-weight: 700; color: var(--color-primary); }
        .order-actions { display: flex; flex-direction: column; gap: 8px; align-items: flex-end;
                         justify-content: space-between; min-width: 130px; }

        .badge { display: inline-block; padding: 3px 10px; border-radius: 12px;
                 font-size: 12px; font-weight: 500; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-info    { background: #dbeafe; color: #1e40af; }
        .badge-primary { background: #fff3eb; color: var(--color-primary); }
        .badge-success { background: #d1fae5; color: #047857; }
        .badge-gray    { background: #f3f4f6; color: #6b7280; }

        .empty-state { text-align: center; padding: 80px 20px; background: #fff;
                       border-radius: var(--radius-lg); box-shadow: var(--shadow-sm); }
        .empty-state i { font-size: 64px; color: var(--color-muted); margin-bottom: 16px; }
        .empty-state h3 { color: var(--color-text); margin-bottom: 8px; }
        .empty-state p { color: var(--color-muted); margin-bottom: 24px; }

        .pagination { display: flex; justify-content: center; gap: 4px; margin-top: 24px; }
        .page-btn { min-width: 36px; height: 36px; padding: 0 10px; border: 1px solid var(--color-border);
                    background: #fff; border-radius: 6px; cursor: pointer;
                    color: var(--color-text); text-decoration: none; display: inline-flex;
                    align-items: center; justify-content: center; font-size: 13px; transition: all 0.2s; }
        .page-btn:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .page-btn.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .page-btn.disabled { opacity: 0.5; cursor: not-allowed; pointer-events: none; }
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
            <a href="<%=ctx%>/order?action=list" class="active">我的订单</a>
        </nav>
        <div class="user-info">
            <span>欢迎，</span>
            <span style="color: var(--color-text); font-weight: 500;"><%= currentUser.getUsername() %></span>
            <a href="<%=ctx%>/user?action=logout" style="color: var(--color-primary);">退出</a>
        </div>
    </div>
</header>

<div class="container" style="max-width: 1200px; margin: 0 auto; padding: 0 24px 60px;">

    <!-- 页头 -->
    <div class="page-header">
        <div class="page-title">
            我的订单
            <small>共 <%= total %> 笔</small>
        </div>
        <div class="role-tabs">
            <a href="<%=ctx%>/order?action=list&role=buyer" class="role-tab <%= "buyer".equals(role) ? "active" : "" %>">我购买的</a>
            <a href="<%=ctx%>/order?action=list&role=seller" class="role-tab <%= "seller".equals(role) ? "active" : "" %>">我卖出的</a>
            <a href="<%=ctx%>/order?action=list&role=all" class="role-tab <%= "all".equals(role) ? "active" : "" %>">全部</a>
        </div>
    </div>

    <!-- 状态筛选 + 搜索 -->
    <div class="filter-bar">
        <a href="<%=ctx%>/order?action=list&role=<%= role %>" class="filter-chip <%= statusFilter == null ? "active" : "" %>">全部状态</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=0" class="filter-chip <%= statusFilter != null && statusFilter == 0 ? "active" : "" %>">待付款</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=1" class="filter-chip <%= statusFilter != null && statusFilter == 1 ? "active" : "" %>">已付款</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=2" class="filter-chip <%= statusFilter != null && statusFilter == 2 ? "active" : "" %>">已发货</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=3" class="filter-chip <%= statusFilter != null && statusFilter == 3 ? "active" : "" %>">已收货</a>
        <a href="<%=ctx%>/order?action=list&role=<%= role %>&status=6" class="filter-chip <%= statusFilter != null && statusFilter == 6 ? "active" : "" %>">已取消</a>

        <form style="margin-left: auto; display: flex; gap: 8px;" action="<%=ctx%>/order" method="get">
            <input type="hidden" name="action" value="list">
            <input type="hidden" name="role" value="<%= role %>">
            <% if (statusFilter != null) { %>
                <input type="hidden" name="status" value="<%= statusFilter %>">
            <% } %>
            <input type="text" name="keyword" value="<%= keyword %>" placeholder="搜索订单号/拍品标题" class="search-input">
            <button type="submit" class="btn btn-secondary btn-sm">搜索</button>
        </form>
    </div>

    <% if (error != null) { %>
        <div class="alert" style="margin-top: 16px; padding: 12px 16px; background: #fee2e2; color: #b91c1c; border-radius: 8px;">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- 订单列表 -->
    <div class="order-list">
        <% if (orders.isEmpty()) { %>
            <div class="empty-state">
                <i class="fa fa-inbox"></i>
                <h3>暂无订单</h3>
                <p><% if ("seller".equals(role)) { %>你还没有卖出任何拍品<% } else { %>去逛逛拍品，发现心仪好物吧<% } %></p>
                <a href="<%=ctx%>/item?action=list" class="btn btn-primary">浏览拍品</a>
            </div>
        <% } else { %>
            <% for (org.example.entity.OrderInfo order : orders) { %>
                <div class="order-card">
                    <div class="order-head">
                        <div>
                            <span>订单号：</span>
                            <span class="order-no"><%= order.getOrderNo() %></span>
                            <span style="margin-left: 12px;"><%= order.getCreateTime() == null ? "" : order.getCreateTime().toString().substring(0, 16).replace('T', ' ') %></span>
                        </div>
                        <span class="badge <%= order.getStatusBadgeClass() %>"><%= order.getStatusText() %></span>
                    </div>
                    <div class="order-body">
                        <div class="order-cover" style="<%= order.getCoverImage() != null && !order.getCoverImage().isEmpty() ? "background-image: url('" + order.getCoverImage() + "');" : "" %>">
                            <% if (order.getCoverImage() == null || order.getCoverImage().isEmpty()) { %>
                                <i class="fa fa-image"></i>
                            <% } %>
                        </div>
                        <div class="order-info">
                            <div class="order-title"><%= EscapeUtil.html(order.getItemTitle()) %></div>
                            <div class="order-meta">
                                <span>订单编号 <%= order.getId() %></span>
                                <span><%= "buyer".equals(role) ? "卖家" : "买家" %> ID <%= "buyer".equals(role) ? order.getSellerId() : order.getBuyerId() %></span>
                            </div>
                            <div class="order-price">¥<%= order.getFinalPrice() == null ? "0.00" : order.getFinalPrice().toPlainString() %></div>
                        </div>
                        <div class="order-actions">
                            <a href="<%=ctx%>/order?action=detail&id=<%= order.getId() %>" class="btn btn-secondary btn-sm">查看详情</a>
                            <% if ("buyer".equals(role) && order.getStatus() != null && order.getStatus() == 0) { %>
                                <a href="<%=ctx%>/order?action=detail&id=<%= order.getId() %>" class="btn btn-primary btn-sm">去付款</a>
                            <% } %>
                        </div>
                    </div>
                </div>
            <% } %>
        <% } %>
    </div>

    <!-- 分页 -->
    <% if (totalPages > 1) { %>
        <div class="pagination">
            <a href="<%=ctx%>/order?action=list&role=<%= role %>&page=<%= Math.max(1, pageNum - 1) %><%= statusFilter != null ? "&status=" + statusFilter : "" %><%= keyword != null && !keyword.isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
               class="page-btn <%= pageNum <= 1 ? "disabled" : "" %>">上一页</a>
            <% for (int p = 1; p <= totalPages; p++) { %>
                <a href="<%=ctx%>/order?action=list&role=<%= role %>&page=<%= p %><%= statusFilter != null ? "&status=" + statusFilter : "" %><%= keyword != null && !keyword.isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
                   class="page-btn <%= p == pageNum ? "active" : "" %>"><%= p %></a>
            <% } %>
            <a href="<%=ctx%>/order?action=list&role=<%= role %>&page=<%= Math.min(totalPages, pageNum + 1) %><%= statusFilter != null ? "&status=" + statusFilter : "" %><%= keyword != null && !keyword.isEmpty() ? "&keyword=" + java.net.URLEncoder.encode(keyword, "UTF-8") : "" %>"
               class="page-btn <%= pageNum >= totalPages ? "disabled" : "" %>">下一页</a>
        </div>
    <% } %>
</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
</body>
</html>