<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User user =
            (org.example.entity.User) request.getAttribute("user");
    java.util.Map<String, Integer> sellerStats =
            (java.util.Map<String, Integer>) request.getAttribute("sellerStats");
    Integer ordersPending = (Integer) request.getAttribute("ordersPending");
    Integer ordersPaid = (Integer) request.getAttribute("ordersPaid");
    Integer ordersShipped = (Integer) request.getAttribute("ordersShipped");
    Integer ordersDone = (Integer) request.getAttribute("ordersDone");
    Integer myBidsCount = (Integer) request.getAttribute("myBidsCount");
    Integer favoritesCount = (Integer) request.getAttribute("favoritesCount");
    Integer addressCount = (Integer) request.getAttribute("addressCount");
    Integer unreadMessageCount = (Integer) request.getAttribute("unreadMessageCount");
    Integer myComplaintCount = (Integer) request.getAttribute("myComplaintCount");
    Integer sellerOrdersToShip = (Integer) request.getAttribute("sellerOrdersToShip");
    java.util.List<org.example.entity.AuctionItem> recentItems =
            (java.util.List<org.example.entity.AuctionItem>) request.getAttribute("recentItems");
    String error = (String) request.getAttribute("error");
    if (sellerStats == null) sellerStats = new java.util.HashMap<>();
    if (ordersPending == null) ordersPending = 0;
    if (ordersPaid == null) ordersPaid = 0;
    if (ordersShipped == null) ordersShipped = 0;
    if (ordersDone == null) ordersDone = 0;
    if (myBidsCount == null) myBidsCount = 0;
    if (favoritesCount == null) favoritesCount = 0;
    if (addressCount == null) addressCount = 0;
    if (unreadMessageCount == null) unreadMessageCount = 0;
    if (myComplaintCount == null) myComplaintCount = 0;
    if (sellerOrdersToShip == null) sellerOrdersToShip = 0;
    if (recentItems == null) recentItems = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>个人中心 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 个人中心 v2 · 仿闲鱼
         * - 顶 nav 统一
         * - 左侧固定侧栏（我的交易/我的收藏/账户设置）
         * - 主区：用户信息卡 + 4 核心统计 + 4 订单状态 + tab + 拍品网格
         * - 右侧浮动操作栏
         * ============================================================ */
        body { background: #f5f5f5; }

        /* ---------- 顶 nav ---------- */
        .header { background: #fff; height: 60px; position: sticky; top: 0; z-index: 100;
                  box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
        .header-inner { max-width: 1200px; margin: 0 auto; padding: 0 16px; height: 100%;
                        display: flex; align-items: center; gap: 20px; }
        .logo { font-size: 20px; font-weight: 800; color: var(--color-primary);
                display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
        .logo-icon { width: 30px; height: 30px; background: var(--color-primary);
                     color: #fff; border-radius: 4px; display: grid; place-items: center;
                     font-size: 14px; }
        .nav { display: flex; gap: 24px; }
        .nav a { color: var(--color-text); font-size: 14px; font-weight: 500;
                 padding: 0 4px; height: 60px; display: flex; align-items: center;
                 position: relative; transition: color 0.2s; }
        .nav a:hover, .nav a.active { color: var(--color-primary); }
        .nav a.active::after {
            content: ''; position: absolute;
            bottom: 8px; left: 4px; right: 4px;
            height: 2px; background: var(--color-primary); border-radius: 2px;
        }
        .nav-search {
            flex: 0 1 380px;
            display: flex; background: #fff7ed;
            border: 2px solid var(--color-primary);
            border-radius: 20px; overflow: hidden; height: 36px;
        }
        .nav-search input {
            flex: 1; padding: 0 14px; border: none; outline: none;
            background: transparent; font-size: 13px; color: var(--color-text);
        }
        .nav-search input::placeholder { color: #9ca3af; }
        .nav-search button {
            background: var(--color-primary); color: #fff;
            font-size: 13px; font-weight: 600; padding: 0 18px;
            display: flex; align-items: center; gap: 5px;
        }
        .nav-search button:hover { background: var(--color-primary-hover); }
        .nav-tags { display: flex; gap: 12px; font-size: 12px; color: var(--color-muted);
                    flex: 1; min-width: 0; overflow: hidden; }
        .nav-tags-label { flex-shrink: 0; }
        .nav-tag { white-space: nowrap; transition: color 0.15s; }
        .nav-tag:hover { color: var(--color-primary); }
        .nav-tag.hot { color: var(--color-danger); font-weight: 600; }
        .user-info { display: flex; align-items: center; gap: 8px; font-size: 14px; flex-shrink: 0; margin-left: auto; }
        .user-info .avatar {
            width: 32px; height: 32px; border-radius: 50%;
            background: linear-gradient(135deg, var(--color-primary), #ffaa80);
            color: #fff; display: grid; place-items: center;
            font-size: 13px; font-weight: 600;
        }
        .user-name-link { color: var(--color-text); font-weight: 500; }

        /* ---------- 主体三栏 ---------- */
        .center-main {
            max-width: 1200px; margin: 12px auto 0;
            padding: 0 16px;
            display: grid;
            grid-template-columns: 200px 1fr 40px;
            gap: 12px;
            align-items: start;
        }

        /* ---------- 左侧侧栏 ---------- */
        .sidebar {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            position: sticky; top: 72px;
            padding: 8px 0;
        }
        .side-group { margin-bottom: 4px; }
        .side-group-title {
            display: flex; align-items: center; gap: 8px;
            padding: 10px 16px; font-size: 13px; color: var(--color-text);
            cursor: pointer; transition: color 0.15s;
            font-weight: 600;
        }
        .side-group-title:hover { color: var(--color-primary); }
        .side-group-title i:first-child { width: 16px; color: var(--color-muted); }
        .side-group-title .arrow {
            margin-left: auto; font-size: 10px; color: var(--color-placeholder);
            transition: transform 0.2s;
        }
        .side-group.collapsed .arrow { transform: rotate(-90deg); }
        .side-list { list-style: none; padding: 0 0 6px; }
        .side-group.collapsed .side-list { display: none; }
        .side-link {
            display: flex; align-items: center; gap: 8px;
            padding: 7px 16px 7px 40px; font-size: 13px;
            color: var(--color-text-sub); transition: all 0.15s;
            cursor: pointer; position: relative;
        }
        .side-link::before {
            content: ''; position: absolute; left: 28px; top: 50%;
            width: 4px; height: 4px; border-radius: 50%;
            background: var(--color-placeholder); transform: translateY(-50%);
        }
        .side-link:hover { color: var(--color-primary); background: var(--color-primary-light); }
        .side-link.active { color: var(--color-primary); background: var(--color-primary-light); font-weight: 600; }
        .side-link .count {
            margin-left: auto; font-size: 11px;
            background: var(--color-danger); color: #fff;
            padding: 1px 6px; border-radius: 8px; min-width: 18px; text-align: center;
        }
        .side-link .count.gray { background: #e5e7eb; color: var(--color-muted); }

        /* ---------- 主区 ---------- */
        .content { min-width: 0; }

        /* 用户信息卡 */
        .profile-card {
            background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%);
            border-radius: 8px; padding: 24px 28px;
            color: #fff; box-shadow: 0 2px 12px rgba(0,0,0,0.05);
            display: grid; grid-template-columns: 80px 1fr auto; gap: 20px;
            align-items: center; position: relative; overflow: hidden;
        }
        .profile-card::before {
            content: ''; position: absolute; right: -40px; top: -40px;
            width: 200px; height: 200px; border-radius: 50%;
            background: rgba(255,255,255,0.08);
        }
        .profile-card::after {
            content: ''; position: absolute; right: 60px; bottom: -60px;
            width: 140px; height: 140px; border-radius: 50%;
            background: rgba(255,255,255,0.06);
        }
        .profile-avatar {
            width: 80px; height: 80px; border-radius: 50%;
            background: rgba(255,255,255,0.25);
            display: grid; place-items: center;
            font-size: 32px; font-weight: 700;
            border: 3px solid rgba(255,255,255,0.4);
            position: relative; z-index: 1;
        }
        .profile-info { position: relative; z-index: 1; }
        .profile-name { font-size: 22px; font-weight: 700; margin-bottom: 6px;
                        display: flex; align-items: center; gap: 8px; }
        .profile-name .hello { font-size: 14px; font-weight: 400; opacity: 0.9; }
        .profile-tags { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 6px; }
        .profile-tag {
            padding: 3px 10px; background: rgba(255,255,255,0.22);
            border-radius: 14px; font-size: 12px;
            display: flex; align-items: center; gap: 4px;
        }
        .profile-meta { font-size: 12px; opacity: 0.85;
                        display: flex; gap: 14px; flex-wrap: wrap; }
        .profile-meta span { display: flex; align-items: center; gap: 4px; }
        .profile-actions { display: flex; flex-direction: column; gap: 8px;
                            position: relative; z-index: 1; }
        .profile-action {
            padding: 8px 18px; background: rgba(255,255,255,0.95);
            color: var(--color-primary); border-radius: 6px;
            font-size: 13px; font-weight: 600; text-align: center;
            border: none; cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; justify-content: center; gap: 5px;
        }
        .profile-action:hover { background: #fff; transform: translateY(-1px);
                                 box-shadow: 0 4px 10px rgba(0,0,0,0.15); }
        .profile-action.outline {
            background: transparent; color: #fff;
            border: 1px solid rgba(255,255,255,0.5);
        }
        .profile-action.outline:hover {
            background: rgba(255,255,255,0.15); color: #fff;
        }

        /* 4 核心统计 */
        .core-stats {
            display: grid; grid-template-columns: repeat(4, 1fr);
            gap: 10px; margin-top: 12px;
        }
        .core-stat {
            background: #fff; border-radius: 8px;
            padding: 18px 16px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            display: flex; align-items: center; gap: 12px;
            cursor: pointer; transition: all 0.15s;
            text-decoration: none; color: inherit;
        }
        .core-stat:hover {
            transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        }
        .core-stat-icon {
            width: 44px; height: 44px; border-radius: 8px;
            display: grid; place-items: center;
            font-size: 20px; flex-shrink: 0;
        }
        .core-stat-icon.orange { background: var(--color-primary-light); color: var(--color-primary); }
        .core-stat-icon.blue   { background: #dbeafe; color: #3b82f6; }
        .core-stat-icon.green  { background: #d1fae5; color: #10b981; }
        .core-stat-icon.purple { background: #ede9fe; color: #8b5cf6; }
        .core-stat-body { min-width: 0; }
        .core-stat-value { font-size: 22px; font-weight: 700; color: var(--color-text); line-height: 1.1; }
        .core-stat-label { font-size: 12px; color: var(--color-muted); margin-top: 2px; }

        /* 4 订单状态（横向小卡） */
        .order-stats {
            background: #fff; border-radius: 8px;
            margin-top: 12px; padding: 16px 20px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        }
        .order-stats-head {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 12px;
        }
        .order-stats-title { font-size: 14px; font-weight: 600; }
        .order-stats-title::before {
            content: ''; display: inline-block; width: 3px; height: 14px;
            background: var(--color-primary); border-radius: 2px; margin-right: 6px;
            vertical-align: middle;
        }
        .order-stats-link { font-size: 12px; color: var(--color-muted); }
        .order-stats-link:hover { color: var(--color-primary); }
        .order-stats-grid {
            display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px;
        }
        .order-stat {
            padding: 14px; border-radius: 6px;
            background: var(--color-bg); text-align: center;
            cursor: pointer; transition: all 0.15s;
            text-decoration: none; color: inherit;
        }
        .order-stat:hover { background: var(--color-primary-light); transform: translateY(-1px); }
        .order-stat-num { font-size: 22px; font-weight: 700; color: var(--color-text); }
        .order-stat-num.has { color: var(--color-primary); }
        .order-stat-label { font-size: 12px; color: var(--color-muted); margin-top: 2px; }
        .order-stat .badge-dot {
            display: inline-block; width: 6px; height: 6px;
            background: var(--color-danger); border-radius: 50%;
            margin-left: 4px; vertical-align: top;
        }

        /* 待办横幅 */
        .todo-bar {
            background: #fff7ed; border: 1px solid #fed7aa;
            border-radius: 8px; padding: 10px 16px; margin-top: 12px;
            display: flex; align-items: center; gap: 8px;
            font-size: 13px; color: #b45309;
        }
        .todo-bar .todo-link {
            margin-left: auto; color: var(--color-primary); font-weight: 600;
        }
        .todo-bar .todo-link:hover { text-decoration: underline; }

        /* 拍品区块 */
        .item-block {
            background: #fff; border-radius: 8px;
            margin-top: 12px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            overflow: hidden;
        }
        .item-tabs {
            display: flex; align-items: center;
            padding: 12px 20px 0;
            border-bottom: 1px solid var(--color-border-soft);
        }
        .item-tab {
            padding: 10px 18px; font-size: 14px; color: var(--color-text-sub);
            cursor: pointer; transition: color 0.15s;
            position: relative; font-weight: 500;
        }
        .item-tab:hover { color: var(--color-primary); }
        .item-tab.active { color: var(--color-primary); font-weight: 600; }
        .item-tab.active::after {
            content: ''; position: absolute;
            bottom: 0; left: 50%; transform: translateX(-50%);
            width: 24px; height: 2px; background: var(--color-primary);
            border-radius: 2px;
        }
        .item-tab .tab-num {
            margin-left: 4px; font-size: 12px; color: var(--color-muted);
        }
        .item-tab.active .tab-num { color: var(--color-primary); }
        .item-block-head-right {
            margin-left: auto; padding: 10px 0;
            font-size: 12px; color: var(--color-muted);
        }
        .item-block-head-right a { color: var(--color-muted); }
        .item-block-head-right a:hover { color: var(--color-primary); }
        .item-block-body { padding: 16px 20px; min-height: 100px; }

        /* 拍品网格（6 列） */
        .item-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
        }
        @media (max-width: 1200px) { .item-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .item-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .item-grid { grid-template-columns: repeat(3, 1fr); } }

        .item-card {
            background: #fff; border: 1px solid transparent;
            border-radius: 4px; overflow: hidden; cursor: pointer;
            transition: all 0.15s; text-decoration: none; color: inherit;
        }
        .item-card:hover {
            border-color: var(--color-primary);
            transform: translateY(-2px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .item-card-cover {
            width: 100%; aspect-ratio: 1; background: #fff7ed;
            position: relative; display: grid; place-items: center;
            overflow: hidden;
        }
        .item-card-cover img { width: 100%; height: 100%; object-fit: cover; }
        .item-card-cover i { font-size: 32px; color: rgba(255,107,53,0.4); }
        .item-card-cover .sold-tag {
            position: absolute; inset: 0;
            background: rgba(0,0,0,0.4);
            display: grid; place-items: center;
            color: #fff; font-size: 16px; font-weight: 700;
            letter-spacing: 0.1em;
        }
        .item-card-body { padding: 8px; }
        .item-card-title {
            font-size: 12px; line-height: 1.4; margin-bottom: 4px;
            min-height: 32px; color: var(--color-text);
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        }
        .item-card-price {
            font-size: 14px; font-weight: 700; color: var(--color-primary);
        }
        .item-card-price small { font-size: 10px; margin-right: 1px; }

        /* 卖家统计 4 数字 */
        .seller-stats {
            display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px;
        }
        .seller-stat {
            background: var(--color-bg); padding: 14px; border-radius: 6px;
            text-align: center;
        }
        .seller-stat-num { font-size: 22px; font-weight: 700; color: var(--color-text); }
        .seller-stat-num.primary { color: var(--color-primary); }
        .seller-stat-num.success { color: var(--color-success); }
        .seller-stat-num.muted   { color: var(--color-muted); }
        .seller-stat-label { font-size: 12px; color: var(--color-muted); margin-top: 2px; }

        /* 空状态 */
        .empty-state {
            text-align: center; padding: 40px 20px;
            color: var(--color-muted); font-size: 13px;
        }
        .empty-state i { font-size: 36px; opacity: 0.3; margin-bottom: 8px; display: block; }

        /* ---------- 错误条 ---------- */
        .alert { padding: 10px 16px; border-radius: 8px; margin-bottom: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        /* ---------- 右侧浮动操作栏 ---------- */
        .floats {
            position: sticky; top: 72px;
            display: flex; flex-direction: column; gap: 6px;
        }
        .float-btn {
            width: 40px; height: 40px; background: #fff;
            border-radius: 8px; display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            color: var(--color-text-sub); box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            transition: all 0.15s; cursor: pointer; font-size: 10px; gap: 1px;
            text-decoration: none;
        }
        .float-btn i { font-size: 14px; }
        .float-btn:hover { background: var(--color-primary); color: #fff; transform: translateY(-1px); }
        .float-btn.primary { background: var(--color-primary); color: #fff; }

        /* ---------- 页脚 ---------- */
        .center-footer {
            background: #1f2937; color: #d1d5db;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .center-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }

        /* ---------- 响应式 ---------- */
        @media (max-width: 1024px) {
            .center-main { grid-template-columns: 180px 1fr; }
            .floats { display: none; }
            .nav-tags { display: none; }
            .nav-search { flex: 0 1 280px; }
        }
        @media (max-width: 768px) {
            .center-main { grid-template-columns: 1fr; padding: 0 8px; }
            .sidebar { position: static; }
            .header-inner { gap: 8px; padding: 0 12px; }
            .nav { display: none; }
            .nav-search { flex: 1; }
            .profile-card { grid-template-columns: 64px 1fr; padding: 16px; }
            .profile-actions { grid-column: 1 / -1; flex-direction: row; }
            .profile-action { flex: 1; }
            .core-stats, .order-stats-grid, .seller-stats { grid-template-columns: repeat(2, 1fr); }
        }
    </style>
</head>
<body>

<!-- ========== 顶 nav ========== -->
<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <span class="logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
            <a href="<%=ctx%>/user?action=center" class="active">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="nav-tags">
            <span class="nav-tags-label">热搜：</span>
            <a href="<%=ctx%>/item/list?keyword=iPhone" class="nav-tag hot">iPhone 15</a>
            <a href="<%=ctx%>/item/list?keyword=相机" class="nav-tag">佳能相机</a>
            <a href="<%=ctx%>/item/list?keyword=球鞋" class="nav-tag">球鞋</a>
            <a href="<%=ctx%>/item/list?keyword=茅台" class="nav-tag hot">茅台</a>
        </div>
        <div class="user-info">
            <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= user.getUsername() %></a>
            <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: var(--color-muted);">退出</a>
            <a href="<%=ctx%>/user?action=center" class="avatar">
                <%= user.getUsername() != null && !user.getUsername().isEmpty()
                    ? user.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </a>
        </div>
    </div>
</header>

<!-- ========== 主体三栏 ========== -->
<div class="center-main">

    <!-- 左侧侧栏 -->
    <aside class="sidebar">
        <!-- 我的中心 -->
        <div class="side-group">
            <div class="side-group-title">
                <i class="fa fa-user-circle"></i>
                <span>我的中心</span>
            </div>
            <ul class="side-list">
                <li><a href="<%=ctx%>/message?action=list" class="side-link">
                    <i class="fa fa-envelope-o"></i> 消息中心
                    <% if (unreadMessageCount != null && unreadMessageCount > 0) { %>
                        <span class="count"><%= unreadMessageCount %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/complaint?action=list" class="side-link">
                    <i class="fa fa-flag-o"></i> 我的投诉
                    <% if (myComplaintCount != null && myComplaintCount > 0) { %>
                        <span class="count"><%= myComplaintCount %></span>
                    <% } else { %>
                        <span class="count gray">0</span>
                    <% } %>
                </a></li>
            </ul>
        </div>

        <!-- 我的交易（展开） -->
        <div class="side-group">
            <div class="side-group-title" onclick="toggleGroup(this)">
                <i class="fa fa-handshake-o"></i>
                <span>我的交易</span>
                <i class="fa fa-angle-down arrow"></i>
            </div>
            <ul class="side-list">
                <li><a href="<%=ctx%>/item?action=my-items" class="side-link">
                    我发布的
                    <% if (sellerStats.get("total") != null && sellerStats.get("total") > 0) { %>
                        <span class="count"><%= sellerStats.get("total") %></span>
                    <% } %>
                </a></li>
                <li><a href="javascript:void(0)" onclick="toast('我的出价功能开发中', 'info')" class="side-link">
                    我的出价
                    <% if (myBidsCount > 0) { %>
                        <span class="count"><%= myBidsCount %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/order?action=list&role=buyer" class="side-link">
                    我的订单（买家）
                    <% if (ordersPending + ordersPaid + ordersShipped + ordersDone > 0) { %>
                        <span class="count"><%= ordersPending + ordersPaid + ordersShipped + ordersDone %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/order?action=list&role=seller" class="side-link">
                    卖出订单（卖家）
                    <% if (sellerOrdersToShip > 0) { %>
                        <span class="count"><%= sellerOrdersToShip %></span>
                    <% } else { %>
                        <span class="count gray">0</span>
                    <% } %>
                </a></li>
            </ul>
        </div>

        <!-- 我的收藏 -->
        <div class="side-group">
            <div class="side-group-title" onclick="toggleGroup(this)">
                <i class="fa fa-heart-o"></i>
                <span>我的收藏</span>
                <i class="fa fa-angle-down arrow"></i>
            </div>
            <ul class="side-list">
                <li><a href="<%=ctx%>/favorite?action=list" class="side-link">
                    收藏的拍品
                    <% if (favoritesCount != null && favoritesCount > 0) { %>
                        <span class="count"><%= favoritesCount %></span>
                    <% } else { %>
                        <span class="count gray">0</span>
                    <% } %>
                </a></li>
                <li><a href="javascript:void(0)" onclick="toast('关注的卖家开发中', 'info')" class="side-link">
                    关注的卖家
                    <span class="count gray">0</span>
                </a></li>
            </ul>
        </div>

        <!-- 账户设置 -->
        <div class="side-group">
            <div class="side-group-title" onclick="toggleGroup(this)">
                <i class="fa fa-cog"></i>
                <span>账户设置</span>
                <i class="fa fa-angle-down arrow"></i>
            </div>
            <ul class="side-list">
                <li><a href="javascript:void(0)" onclick="toast('个人资料编辑开发中', 'info')" class="side-link">个人资料</a></li>
                <li><a href="javascript:void(0)" onclick="toast('账号安全开发中', 'info')" class="side-link">账号安全</a></li>
                <li><a href="<%=ctx%>/address?action=list" class="side-link">
                    收货地址
                    <% if (addressCount != null && addressCount > 0) { %>
                        <span class="count"><%= addressCount %></span>
                    <% } else { %>
                        <span class="count gray">0</span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/credit?action=list" class="side-link">
                    <i class="fa fa-star-o"></i> 我的评价
                </a></li>
            </ul>
        </div>
    </aside>

    <!-- 中央内容 -->
    <main class="content">
        <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
        <% } %>

        <!-- 用户信息卡 -->
        <div class="profile-card">
            <div class="profile-avatar">
                <%= user.getUsername() != null && !user.getUsername().isEmpty()
                    ? user.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </div>
            <div class="profile-info">
                <div class="profile-name">
                    <%= user.getUsername() %>
                    <span class="hello">· 你好</span>
                </div>
                <div class="profile-tags">
                    <span class="profile-tag"><i class="fa fa-star"></i> 信用分 <%= user.getCreditScore() %></span>
                    <span class="profile-tag"><i class="fa fa-trophy"></i> 信用优秀</span>
                    <% if (user.getPhone() != null && !user.getPhone().isEmpty()) { %>
                        <span class="profile-tag"><i class="fa fa-phone"></i> 已认证手机</span>
                    <% } %>
                </div>
                <div class="profile-meta">
                    <span><i class="fa fa-calendar"></i> 注册于
                        <%= user.getRegisterTime() == null ? "-" : user.getRegisterTime().toString().substring(0, 10) %>
                    </span>
                    <span><i class="fa fa-users"></i> 0 粉丝</span>
                    <span><i class="fa fa-eye"></i> 0 关注</span>
                </div>
            </div>
            <div class="profile-actions">
                <a href="<%=ctx%>/item?action=publish-page" class="profile-action">
                    <i class="fa fa-plus"></i> 发布拍品
                </a>
                <a href="javascript:void(0)" onclick="toast('编辑资料开发中', 'info')" class="profile-action outline">
                    <i class="fa fa-pencil"></i> 编辑资料
                </a>
            </div>
        </div>

        <!-- 待办横幅 -->
        <% if (ordersPending > 0) { %>
        <div class="todo-bar">
            <i class="fa fa-bell"></i>
            您有 <strong><%= ordersPending %></strong> 笔订单待付款
            <a href="<%=ctx%>/order?action=list&role=buyer&status=0" class="todo-link">立即处理 →</a>
        </div>
        <% } %>
        <% if (sellerOrdersToShip > 0) { %>
        <div class="todo-bar">
            <i class="fa fa-truck"></i>
            您有 <strong><%= sellerOrdersToShip %></strong> 笔订单待发货（作为卖家）
            <a href="<%=ctx%>/order?action=list&role=seller&status=1" class="todo-link">立即发货 →</a>
        </div>
        <% } %>

        <!-- 4 核心统计 -->
        <div class="core-stats">
            <a href="<%=ctx%>/item?action=list&seller=<%= user.getId() %>" class="core-stat">
                <div class="core-stat-icon orange"><i class="fa fa-gavel"></i></div>
                <div class="core-stat-body">
                    <div class="core-stat-value"><%= sellerStats.get("total") == null ? 0 : sellerStats.get("total") %></div>
                    <div class="core-stat-label">我发布的拍品</div>
                </div>
            </a>
            <a href="javascript:void(0)" onclick="toast('我的出价开发中', 'info')" class="core-stat">
                <div class="core-stat-icon blue"><i class="fa fa-hand-paper-o"></i></div>
                <div class="core-stat-body">
                    <div class="core-stat-value"><%= myBidsCount %></div>
                    <div class="core-stat-label">我的出价</div>
                </div>
            </a>
            <a href="<%=ctx%>/order?action=list&role=buyer" class="core-stat">
                <div class="core-stat-icon green"><i class="fa fa-list-alt"></i></div>
                <div class="core-stat-body">
                    <div class="core-stat-value"><%= ordersPending + ordersPaid + ordersShipped + ordersDone %></div>
                    <div class="core-stat-label">我的订单</div>
                </div>
            </a>
            <a href="<%=ctx%>/favorite?action=list" class="core-stat">
                <div class="core-stat-icon purple"><i class="fa fa-heart"></i></div>
                <div class="core-stat-body">
                    <div class="core-stat-value"><%= favoritesCount %></div>
                    <div class="core-stat-label">我的收藏</div>
                </div>
            </a>
        </div>

        <!-- 4 订单状态 -->
        <div class="order-stats">
            <div class="order-stats-head">
                <div class="order-stats-title">我的订单（买家）</div>
                <a href="<%=ctx%>/order?action=list&role=buyer" class="order-stats-link">查看全部 →</a>
            </div>
            <div class="order-stats-grid">
                <a href="<%=ctx%>/order?action=list&role=buyer&status=0" class="order-stat">
                    <div class="order-stat-num <%= ordersPending > 0 ? "has" : "" %>">
                        <%= ordersPending %><% if (ordersPending > 0) { %><span class="badge-dot"></span><% } %>
                    </div>
                    <div class="order-stat-label">待付款</div>
                </a>
                <a href="<%=ctx%>/order?action=list&role=buyer&status=1" class="order-stat">
                    <div class="order-stat-num <%= ordersPaid > 0 ? "has" : "" %>">
                        <%= ordersPaid %>
                    </div>
                    <div class="order-stat-label">已付款</div>
                </a>
                <a href="<%=ctx%>/order?action=list&role=buyer&status=2" class="order-stat">
                    <div class="order-stat-num <%= ordersShipped > 0 ? "has" : "" %>">
                        <%= ordersShipped %>
                    </div>
                    <div class="order-stat-label">已发货</div>
                </a>
                <a href="<%=ctx%>/order?action=list&role=buyer&status=3" class="order-stat">
                    <div class="order-stat-num <%= ordersDone > 0 ? "has" : "" %>">
                        <%= ordersDone %>
                    </div>
                    <div class="order-stat-label">已收货</div>
                </a>
            </div>
        </div>

        <!-- 卖家统计 + 拍品 -->
        <div class="item-block">
            <div class="item-tabs">
                <a href="javascript:void(0)" class="item-tab active" data-tab="active">
                    拍卖中 <span class="tab-num">(<%= sellerStats.get("active") == null ? 0 : sellerStats.get("active") %>)</span>
                </a>
                <a href="javascript:void(0)" class="item-tab" data-tab="sold">
                    已成交 <span class="tab-num">(<%= sellerStats.get("sold") == null ? 0 : sellerStats.get("sold") %>)</span>
                </a>
                <a href="javascript:void(0)" class="item-tab" data-tab="failed">
                    已流拍 <span class="tab-num">(<%= sellerStats.get("failed") == null ? 0 : sellerStats.get("failed") %>)</span>
                </a>
                <div class="item-block-head-right">
                    <a href="<%=ctx%>/item?action=publish-page">+ 发布新拍品</a>
                </div>
            </div>
            <div class="item-block-body">
                <!-- 4 数字统计 -->
                <div class="seller-stats" style="margin-bottom: 16px;">
                    <div class="seller-stat">
                        <div class="seller-stat-num"><%= sellerStats.get("total") == null ? 0 : sellerStats.get("total") %></div>
                        <div class="seller-stat-label">全部</div>
                    </div>
                    <div class="seller-stat">
                        <div class="seller-stat-num primary"><%= sellerStats.get("active") == null ? 0 : sellerStats.get("active") %></div>
                        <div class="seller-stat-label">拍卖中</div>
                    </div>
                    <div class="seller-stat">
                        <div class="seller-stat-num success"><%= sellerStats.get("sold") == null ? 0 : sellerStats.get("sold") %></div>
                        <div class="seller-stat-label">已成交</div>
                    </div>
                    <div class="seller-stat">
                        <div class="seller-stat-num muted"><%= sellerStats.get("failed") == null ? 0 : sellerStats.get("failed") %></div>
                        <div class="seller-stat-label">已流拍</div>
                    </div>
                </div>

                <!-- 拍品网格 -->
                <% if (recentItems.isEmpty()) { %>
                    <div class="empty-state">
                        <i class="fa fa-inbox"></i>
                        还没有发布过拍品，<a href="<%=ctx%>/item?action=publish-page" style="color: var(--color-primary);">立即发布</a>
                    </div>
                <% } else { %>
                    <div class="item-grid">
                        <% for (org.example.entity.AuctionItem item : recentItems) { %>
                            <a href="<%=ctx%>/item?action=detail&id=<%= item.getId() %>" class="item-card">
                                <div class="item-card-cover" style="<%= item.getCoverImage() != null && !item.getCoverImage().isEmpty() ? "background-image: url('" + item.getCoverImage() + "'); background-size: cover; background-position: center;" : "" %>">
                                    <% if (item.getCoverImage() == null || item.getCoverImage().isEmpty()) { %>
                                        <i class="fa fa-image"></i>
                                    <% } %>
                                    <%-- 已成交 / 已流拍时盖个半透明水印 --%>
                                    <% if (item.getStatus() != null && item.getStatus() == 2) { %>
                                        <div class="sold-tag">已成交</div>
                                    <% } else if (item.getStatus() != null && item.getStatus() == 3) { %>
                                        <div class="sold-tag" style="background: rgba(107,114,128,0.7);">已流拍</div>
                                    <% } %>
                                </div>
                                <div class="item-card-body">
                                    <div class="item-card-title"><%= EscapeUtil.html(item.getTitle()) %></div>
                                    <div class="item-card-price">
                                        <small>¥</small><%= item.getCurrentPrice() == null ? "0.00" : item.getCurrentPrice().toPlainString() %>
                                    </div>
                                </div>
                            </a>
                        <% } %>
                    </div>
                <% } %>
            </div>
        </div>

    </main>

    <!-- 右侧浮动操作栏 -->
    <aside class="floats">
        <a href="<%=ctx%>/item?action=publish-page" class="float-btn primary" title="发拍品">
            <i class="fa fa-plus"></i><span>发布</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('消息中心开发中', 'info')" class="float-btn" title="消息">
            <i class="fa fa-envelope-o"></i><span>消息</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('APP 下载敬请期待', 'info')" class="float-btn" title="APP">
            <i class="fa fa-mobile"></i><span>APP</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('反馈功能开发中', 'info')" class="float-btn" title="反馈">
            <i class="fa fa-commenting-o"></i><span>反馈</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('客服：400-888-8888', 'info')" class="float-btn" title="客服">
            <i class="fa fa-headphones"></i><span>客服</span>
        </a>
        <a href="javascript:void(0)" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" class="float-btn" title="回顶部" style="margin-top: auto;">
            <i class="fa fa-arrow-up"></i><span>顶部</span>
        </a>
    </aside>
</div>

<!-- 页脚 -->
<footer class="center-footer">
    <div class="center-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // 左侧侧栏分组折叠/展开
    function toggleGroup(titleEl) {
        const group = titleEl.parentElement;
        group.classList.toggle('collapsed');
    }

    // 拍品 tab 切换（前端占位：只切换高亮，真实数据由后端给时再接）
    document.querySelectorAll('.item-tab').forEach(tab => {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.item-tab').forEach(t => t.classList.remove('active'));
            this.classList.add('active');
            const tabName = this.dataset.tab;
            // 前端占位：toast 提示，实际应请求后端切换数据
            toast('切换到「' + (tabName === 'active' ? '拍卖中' : tabName === 'sold' ? '已成交' : '已流拍') + '」', 'info');
        });
    });
</script>
</body>
</html>
