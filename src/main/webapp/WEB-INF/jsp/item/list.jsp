<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    String itemsJson        = (String) request.getAttribute("itemsJson");
    String categoriesJson   = (String) request.getAttribute("categoriesJson");
    Integer categoryId      = (Integer) request.getAttribute("categoryId");
    String keyword          = (String) request.getAttribute("keyword");
    String sort             = (String) request.getAttribute("sort");
    Integer pageNo          = (Integer) request.getAttribute("page");
    Integer size            = (Integer) request.getAttribute("size");
    Integer total           = (Integer) request.getAttribute("total");
    Integer totalPages      = (Integer) request.getAttribute("totalPages");
    String error            = (String) request.getAttribute("error");

    if (itemsJson == null) itemsJson = "[]";
    if (categoriesJson == null) categoriesJson = "[]";
    if (keyword == null) keyword = "";
    if (sort == null || sort.isEmpty()) sort = "newest";
    if (pageNo == null || pageNo < 1) pageNo = 1;
    if (size == null || size < 1) size = 12;
    if (total == null) total = 0;
    if (totalPages == null || totalPages < 1) totalPages = 1;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>浏览拍品 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 拍品列表页 v2 · 仿闲鱼搜索结果
         * - 顶 nav：白底 + 大搜索框 + 热搜词
         * - 主区：顶筛选条 + 属性筛选 + 6 列商品网格 + 右侧浮动操作栏
         * - 保留所有 Vue 接管与后端数据流
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
        .nav-tags {
            display: flex; gap: 12px; font-size: 12px; color: var(--color-muted);
            flex: 1; min-width: 0; overflow: hidden;
        }
        .nav-tags-label { flex-shrink: 0; }
        .nav-tag { white-space: nowrap; transition: color 0.15s; }
        .nav-tag:hover { color: var(--color-primary); }
        .nav-tag.hot { color: var(--color-danger); font-weight: 600; }
        .user-info { display: flex; align-items: center; gap: 8px; font-size: 14px; flex-shrink: 0; margin-left: auto; }
        .user-info .icon-btn {
            width: 36px; height: 36px; display: grid; place-items: center;
            color: var(--color-text-sub); border-radius: 50%;
            transition: background 0.15s; font-size: 15px;
        }
        .user-info .icon-btn:hover { background: var(--color-primary-light); color: var(--color-primary); }
        .user-info .avatar {
            width: 32px; height: 32px; border-radius: 50%;
            background: linear-gradient(135deg, var(--color-primary), #ffaa80);
            color: #fff; display: grid; place-items: center;
            font-size: 13px; font-weight: 600; cursor: pointer;
        }
        .user-name-link { color: var(--color-text); font-weight: 500; }

        /* ---------- 主体三栏 ---------- */
        .list-main {
            max-width: 1200px; margin: 12px auto 0;
            padding: 0 16px;
            display: grid;
            grid-template-columns: 1fr 40px;
            gap: 12px;
            align-items: start;
        }

        /* ---------- 顶筛选条（综合 / 排序 + 右侧分页） ---------- */
        .topbar {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            display: flex; align-items: center; padding: 10px 16px;
            margin-bottom: 10px; gap: 8px;
        }
        .topbar-label {
            color: var(--color-muted); font-size: 12px;
            margin-right: 4px; flex-shrink: 0;
        }
        .topbar-sort {
            display: flex; gap: 4px; flex: 1; min-width: 0;
        }
        .sort-btn {
            padding: 6px 14px; font-size: 13px; color: var(--color-text-sub);
            border-radius: 4px; cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; gap: 3px;
        }
        .sort-btn:hover { color: var(--color-primary); }
        .sort-btn.active { background: var(--color-primary-light); color: var(--color-primary); font-weight: 600; }
        .sort-btn .arrow { font-size: 10px; }
        .topbar-right {
            display: flex; align-items: center; gap: 10px; flex-shrink: 0;
            font-size: 12px; color: var(--color-muted);
        }
        .topbar-right .page-info {
            background: #f3f4f6; padding: 4px 10px; border-radius: 4px;
            display: flex; align-items: center; gap: 8px;
        }
        .topbar-right .page-info .arrow-btn {
            width: 18px; height: 18px; display: grid; place-items: center;
            border-radius: 3px; cursor: pointer; color: var(--color-muted);
            transition: all 0.15s;
        }
        .topbar-right .page-info .arrow-btn:hover:not(.disabled) { background: #fff; color: var(--color-primary); }
        .topbar-right .page-info .arrow-btn.disabled { opacity: 0.4; cursor: not-allowed; }

        /* ---------- 属性筛选条（checkbox 风格） ---------- */
        .filterbar {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 12px 16px; margin-bottom: 10px;
            display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
        }
        .filterbar-section {
            display: flex; align-items: center; gap: 6px;
        }
        .filterbar-label {
            color: var(--color-muted); font-size: 12px;
            display: flex; align-items: center; gap: 4px;
            flex-shrink: 0;
        }
        .filterbar-label::after { content: '：'; }
        .filter-chip {
            display: flex; align-items: center; gap: 4px;
            padding: 4px 10px; font-size: 12px; color: var(--color-text-sub);
            border-radius: 4px; cursor: pointer; transition: all 0.15s;
            user-select: none;
        }
        .filter-chip:hover { color: var(--color-primary); }
        .filter-chip.active { background: var(--color-primary-light); color: var(--color-primary); font-weight: 600; }
        .filter-chip i { font-size: 11px; }

        /* ---------- 商品网格 ---------- */
        .item-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
        }
        @media (max-width: 1200px) { .item-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .item-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .item-grid { grid-template-columns: repeat(3, 1fr); } }

        .item-card {
            background: #fff; border: 1px solid transparent; border-radius: 4px;
            overflow: hidden; cursor: pointer; transition: all 0.2s;
            display: flex; flex-direction: column;
        }
        .item-card:hover {
            border-color: var(--color-primary);
            transform: translateY(-2px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .item-cover {
            width: 100%; aspect-ratio: 1; background: #fff7ed;
            position: relative; overflow: hidden; display: grid; place-items: center;
        }
        .item-cover img {
            width: 100%; height: 100%; object-fit: cover; display: block;
        }
        .item-cover .placeholder-icon {
            font-size: 36px; color: rgba(255,107,53,0.5);
        }
        .item-cover .badge {
            position: absolute; top: 6px; left: 6px;
            display: flex; gap: 3px; flex-wrap: wrap;
        }
        .badge-tag {
            padding: 1px 6px; font-size: 10px; font-weight: 600;
            border-radius: 2px; line-height: 1.5;
        }
        .badge-orange { background: #fff7ed; color: var(--color-primary); border: 1px solid #fed7aa; }
        .badge-red    { background: #fee2e2; color: var(--color-danger); border: 1px solid #fecaca; }
        .badge-blue   { background: #dbeafe; color: #3b82f6; border: 1px solid #bfdbfe; }
        .badge-purple { background: #ede9fe; color: #8b5cf6; border: 1px solid #ddd6fe; }
        .badge-green  { background: #d1fae5; color: #10b981; border: 1px solid #a7f3d0; }

        .item-cover .countdown-tag {
            position: absolute; bottom: 0; left: 0; right: 0;
            background: linear-gradient(transparent, rgba(0,0,0,0.65));
            color: #fff; font-size: 11px; padding: 14px 8px 6px;
            display: flex; align-items: center; gap: 4px;
        }
        .item-cover .countdown-tag.urgent { background: linear-gradient(transparent, rgba(239,68,68,0.85)); }
        .item-cover .countdown-tag.ended { background: rgba(107,114,128,0.85); }
        .item-cover .countdown-tag i { font-size: 10px; }

        .item-body { padding: 8px 8px 10px; flex: 1; display: flex; flex-direction: column; }
        .item-title {
            font-size: 12px; color: var(--color-text); line-height: 1.4;
            margin-bottom: 6px; min-height: 34px;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        }
        .item-meta-row {
            display: flex; align-items: center; gap: 6px;
            font-size: 11px; color: var(--color-muted); margin-bottom: 6px;
        }
        .item-meta-row i { font-size: 10px; }
        .item-price-row {
            display: flex; align-items: baseline; justify-content: space-between; margin-top: auto;
        }
        .item-current-price {
            font-size: 16px; font-weight: 700; color: var(--color-primary); line-height: 1;
        }
        .item-current-price small { font-size: 11px; margin-right: 1px; }
        .item-bid-count {
            font-size: 11px; color: var(--color-muted);
            display: flex; align-items: center; gap: 3px;
        }
        .item-foot {
            margin-top: 6px; display: flex; align-items: center; gap: 5px;
            font-size: 11px; color: var(--color-muted);
        }
        .item-credit {
            background: #fff7ed; color: var(--color-primary);
            font-size: 10px; padding: 1px 4px; border-radius: 2px; flex-shrink: 0;
        }
        .item-location { margin-left: auto; }

        /* ---------- 空状态 ---------- */
        .empty-state {
            text-align: center; padding: 80px 24px; color: var(--color-muted);
            background: #fff; border-radius: 8px;
        }
        .empty-state i { font-size: 48px; margin-bottom: 12px; opacity: 0.4; }

        /* ---------- 分页（底部） ---------- */
        .pagination {
            display: flex; justify-content: center; gap: 6px;
            margin: 24px 0 12px;
        }
        .page-btn {
            min-width: 36px; height: 36px; padding: 0 10px;
            background: #fff; border: 1px solid var(--color-border);
            border-radius: 4px; cursor: pointer; font-size: 13px;
            display: inline-flex; align-items: center; justify-content: center;
            transition: all 0.15s; color: var(--color-text);
        }
        .page-btn:hover:not(:disabled) { border-color: var(--color-primary); color: var(--color-primary); }
        .page-btn.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .page-btn:disabled { opacity: 0.4; cursor: not-allowed; }

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
        }
        .float-btn i { font-size: 14px; }
        .float-btn:hover { background: var(--color-primary); color: #fff; transform: translateY(-1px); }
        .float-btn.primary { background: var(--color-primary); color: #fff; }

        /* ---------- 错误条 ---------- */
        .error-bar {
            background: #fee2e2; color: var(--color-danger);
            padding: 10px 16px; border-radius: 8px;
            margin-bottom: 12px; font-size: 13px;
        }

        /* ---------- 响应式 ---------- */
        @media (max-width: 1024px) {
            .nav-tags { display: none; }
            .nav-search { flex: 0 1 280px; }
            .list-main { grid-template-columns: 1fr; }
            .floats { display: none; }
        }
        @media (max-width: 768px) {
            .header-inner { gap: 8px; padding: 0 12px; }
            .nav { display: none; }
            .nav-search { flex: 1; }
            .filterbar { gap: 10px; }
        }

        /* ---------- 页脚 ---------- */
        .list-footer {
            background: #1f2937; color: #d1d5db;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .list-footer-inner {
            max-width: 1200px; margin: 0 auto;
            color: #6b7280;
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
            <a href="<%=ctx%>/item?action=list" class="active">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="javascript:void(0)" onclick="go('<%=ctx%>/item?action=list&sort=hot')">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=center')">个人中心</a>
            <% } %>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="nav-search" id="searchForm">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ..."
                   value="<%= keyword %>">
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
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=center')" class="user-name-link"><%= currentUser.getUsername() %></a>
                <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=logout')" style="font-size: 12px; color: var(--color-muted);">退出</a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" class="icon-btn" title="登录"><i class="fa fa-user-o"></i></a>
                <a href="<%=ctx%>/user?action=login" style="font-size: 13px; padding: 6px 12px; color: var(--color-primary); border: 1px solid var(--color-primary); border-radius: 4px;">登录</a>
                <a href="<%=ctx%>/user?action=register" style="font-size: 13px; padding: 6px 12px; color: #fff; background: var(--color-primary); border-radius: 4px;">注册</a>
            <% } %>
        </div>
    </div>
</header>

<!-- ========== 主体两栏 ========== -->
<div class="list-main">
<div id="app">

    <% if (error != null) { %>
    <div class="error-bar"><%= error %></div>
    <% } %>

    <!-- 顶筛选条（综合 / 排序） -->
    <div class="topbar">
        <span class="topbar-label">排序</span>
        <div class="topbar-sort">
            <div :class="['sort-btn', { active: sort==='newest' }]" @click="changeSort('newest')">综合</div>
            <div :class="['sort-btn', { active: sort==='ending' }]" @click="changeSort('ending')">
                即将结束 <i class="fa fa-angle-down arrow"></i>
            </div>
            <div :class="['sort-btn', { active: sort==='hot' }]" @click="changeSort('hot')">
                新发布 <i class="fa fa-angle-down arrow"></i>
            </div>
            <div :class="['sort-btn', { active: sort==='priceAsc' }]" @click="changeSort('priceAsc')">
                价格 <i class="fa fa-angle-down arrow"></i>
            </div>
        </div>
        <div class="topbar-right">
            <div class="page-info">
                <span>{{ page }} / {{ totalPages }}</span>
                <span :class="['arrow-btn', { disabled: page === 1 }]" @click="goPage(page - 1)">
                    <i class="fa fa-angle-left"></i>
                </span>
                <span :class="['arrow-btn', { disabled: page === totalPages }]" @click="goPage(page + 1)">
                    <i class="fa fa-angle-right"></i>
                </span>
            </div>
        </div>
    </div>

    <!-- 属性筛选条（checkbox 风格） -->
    <div class="filterbar">
        <div class="filterbar-section">
            <span class="filterbar-label">分类</span>
            <div :class="['filter-chip', { active: !currentCategoryId }]" @click="changeCategory(null)">全部</div>
            <div v-for="c in categories" :key="c.id"
                 :class="['filter-chip', { active: currentCategoryId === c.id }]"
                 @click="changeCategory(c.id)">
                {{ c.categoryName }}
            </div>
        </div>
    </div>

    <div class="filterbar" style="padding-top: 6px; padding-bottom: 6px;">
        <div class="filterbar-section">
            <span class="filterbar-label">属性</span>
            <div class="filter-chip" @click="toast('个人拍品筛选（前端占位）', 'info')">
                <i class="fa fa-square-o"></i> 个人拍品
            </div>
            <div class="filter-chip" @click="toast('包邮筛选（前端占位）', 'info')">
                <i class="fa fa-square-o"></i> 包邮
            </div>
            <div class="filter-chip" @click="toast('严选筛选（前端占位）', 'info')">
                <i class="fa fa-square-o"></i> 严选
            </div>
            <div class="filter-chip" @click="toast('全新筛选（前端占位）', 'info')">
                <i class="fa fa-square-o"></i> 全新
            </div>
            <div class="filter-chip" @click="toast('即将结束筛选（前端占位）', 'info')">
                <i class="fa fa-square-o"></i> 即将结束
            </div>
        </div>
        <div style="margin-left: auto; font-size: 12px; color: var(--color-muted);">
            共 <strong style="color: var(--color-text);">{{ total }}</strong> 件拍品
        </div>
    </div>

    <!-- 商品网格 -->
    <div v-if="items.length === 0" class="empty-state">
        <i class="fa fa-inbox"></i>
        <p>暂无符合条件的拍品</p>
    </div>
    <div v-else class="item-grid">
        <div v-for="item in items" :key="item.id" class="item-card" @click="goDetail(item.id)">
            <div class="item-cover"
                 :style="item.coverImage ? 'background-image:url(' + item.coverImage + ');background-size:cover;background-position:center;' : ''">
                <i v-if="!item.coverImage" class="fa fa-image placeholder-icon"></i>
                <div class="badge">
                    <span class="badge-tag badge-orange" v-if="item.freeShipping">包邮</span>
                    <span class="badge-tag badge-red" v-if="isEnding(item)">即将结束</span>
                    <span class="badge-tag badge-blue" v-if="item.conditionLevel === '全新'">全新</span>
                    <span class="badge-tag badge-purple" v-else-if="item.conditionLevel === '严选'">严选</span>
                </div>
                <div :class="['countdown-tag', { urgent: isUrgent(item), ended: isEnded(item) }]">
                    <i class="fa fa-clock-o"></i>
                    <span v-if="isEnded(item)">已结束</span>
                    <span v-else>剩余 {{ countdownOf(item) }}</span>
                </div>
            </div>
            <div class="item-body">
                <div class="item-title">{{ item.title }}</div>
                <div class="item-meta-row">
                    <i class="fa fa-clock-o"></i>
                    <span>{{ relativeTime(item) }}</span>
                </div>
                <div class="item-price-row">
                    <div class="item-current-price">
                        <small>¥</small>{{ formatPrice(item.currentPrice) }}
                    </div>
                    <div class="item-bid-count">
                        <i class="fa fa-user-o"></i> {{ item.viewCount || 0 }}
                    </div>
                </div>
                <div class="item-foot">
                    <span class="item-credit">{{ creditLabel(item) }}</span>
                    <span class="item-location" v-if="item.location">{{ item.location }}</span>
                    <span class="item-location" v-else>—</span>
                </div>
            </div>
        </div>
    </div>

    <!-- 分页 -->
    <div v-if="totalPages > 1" class="pagination">
        <button class="page-btn" :disabled="page === 1" @click="goPage(1)">
            <i class="fa fa-angle-double-left"></i>
        </button>
        <button class="page-btn" :disabled="page === 1" @click="goPage(page - 1)">
            <i class="fa fa-angle-left"></i>
        </button>
        <button v-for="p in pageNumbers" :key="p"
                :class="['page-btn', { active: p === page }]" @click="goPage(p)">
            {{ p }}
        </button>
        <button class="page-btn" :disabled="page === totalPages" @click="goPage(page + 1)">
            <i class="fa fa-angle-right"></i>
        </button>
        <button class="page-btn" :disabled="page === totalPages" @click="goPage(totalPages)">
            <i class="fa fa-angle-double-right"></i>
        </button>
    </div>

</div>

    <!-- 右侧浮动操作栏 -->
    <aside class="floats">
        <div class="float-btn primary" title="发拍品" onclick="go('<%=ctx%>/item?action=publish-page')">
            <i class="fa fa-plus"></i><span>发布</span>
        </div>
        <div class="float-btn" title="消息" onclick="go('<%= currentUser != null ? ctx + "/user?action=center" : ctx + "/user?action=login" %>')">
            <i class="fa fa-envelope-o"></i><span>消息</span>
        </div>
        <div class="float-btn" title="APP" onclick="toast('APP 下载敬请期待', 'info')">
            <i class="fa fa-mobile"></i><span>APP</span>
        </div>
        <div class="float-btn" title="反馈" onclick="toast('反馈功能开发中', 'info')">
            <i class="fa fa-commenting-o"></i><span>反馈</span>
        </div>
        <div class="float-btn" title="客服" onclick="toast('客服：400-888-8888', 'info')">
            <i class="fa fa-headphones"></i><span>客服</span>
        </div>
        <div class="float-btn" title="回顶部" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" style="margin-top: auto;">
            <i class="fa fa-arrow-up"></i><span>顶部</span>
        </div>
    </aside>
</div>

<!-- 页脚 -->
<footer class="list-footer">
    <div class="list-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // 全局跳转
    function go(path) { window.location.href = path; }

    // Servlet 端已塞好的 JSON
    const items      = <%= itemsJson %>;
    const categories = <%= categoriesJson %>;
    const initCategoryId = <%= categoryId == null ? "null" : categoryId.toString() %>;
    const initKeyword    = '<%= keyword.replace("'", "\\'") %>';
    const initSort       = '<%= sort %>';
    const initPage       = <%= pageNo %>;
    const initTotal      = <%= total %>;
    const initTotalPages = <%= totalPages %>;

    loadVue().then(() => {
        const { createApp, ref, computed, onMounted, onUnmounted } = Vue;
        createApp({
            setup() {
                const itemsRef      = ref(items);
                const categoriesRef = ref(categories);
                const currentCategoryId = ref(initCategoryId);
                const keywordRef    = ref(initKeyword);
                const sortRef       = ref(initSort);
                const page          = ref(initPage);
                const total         = ref(initTotal);
                const totalPages    = ref(initTotalPages);
                const now           = ref(Date.now());
                let timer = null;

                onMounted(() => { timer = setInterval(() => { now.value = Date.now(); }, 1000); });
                onUnmounted(() => { if (timer) clearInterval(timer); });

                const pageNumbers = computed(() => {
                    const arr = [];
                    const start = Math.max(1, page.value - 2);
                    const end   = Math.min(totalPages.value, start + 4);
                    for (let i = start; i <= end; i++) arr.push(i);
                    return arr;
                });

                function formatPrice(p) {
                    return Number(p).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
                function conditionLabel(c) { return c || '9成新'; }

                function countdownOf(item) {
                    if (!item.endTime) return '';
                    const left = new Date(item.endTime).getTime() - now.value;
                    if (left <= 0) return '已结束';
                    const sec = Math.floor(left / 1000);
                    const days = Math.floor(sec / 86400);
                    const hours = Math.floor((sec % 86400) / 3600);
                    const mins = Math.floor((sec % 3600) / 60);
                    const secs = sec % 60;
                    if (days > 0)  return days + '天' + hours + '时';
                    if (hours > 0) return hours + '时' + mins + '分';
                    return mins + '分' + secs + '秒';
                }
                function isEnding(item) {
                    if (!item.endTime) return false;
                    const left = new Date(item.endTime).getTime() - now.value;
                    return left > 0 && left < 60 * 60 * 1000; // 1 小时内算"即将结束"
                }
                function isUrgent(item) {
                    if (!item.endTime) return false;
                    const left = new Date(item.endTime).getTime() - now.value;
                    return left > 0 && left < 30 * 60 * 1000; // 30 分钟内红色
                }
                function isEnded(item) {
                    if (!item.endTime) return false;
                    return new Date(item.endTime).getTime() - now.value <= 0;
                }
                function creditLabel(item) {
                    return item.creditLabel || '信用极好';
                }
                function relativeTime(item) {
                    if (!item.publishTime) return '';
                    const t = new Date(item.publishTime).getTime();
                    const diff = Math.max(0, now.value - t);
                    const sec = Math.floor(diff / 1000);
                    if (sec < 60) return '刚刚发布';
                    if (sec < 3600) return Math.floor(sec / 60) + '分钟前发布';
                    if (sec < 86400) return Math.floor(sec / 3600) + '小时前发布';
                    return Math.floor(sec / 86400) + '天前发布';
                }

                function buildQuery(extra) {
                    const qs = new URLSearchParams();
                    qs.set('action', 'list');
                    if (currentCategoryId.value) qs.set('category', currentCategoryId.value);
                    if (keywordRef.value) qs.set('keyword', keywordRef.value);
                    if (sortRef.value && sortRef.value !== 'newest') qs.set('sort', sortRef.value);
                    for (const k in extra) if (extra[k] != null) qs.set(k, extra[k]);
                    return '<%=ctx%>/item?' + qs.toString();
                }

                function changeCategory(id) { currentCategoryId.value = id; window.location.href = buildQuery({ page: 1 }); }
                function changeSort(s)      { sortRef.value = s;       window.location.href = buildQuery({ page: 1 }); }
                function goPage(p) {
                    if (p < 1 || p > totalPages.value) return;
                    window.location.href = buildQuery({ page: p });
                }
                function goDetail(id) { window.location.href = '<%=ctx%>/item?action=detail&id=' + id; }

                return {
                    items: itemsRef, categories: categoriesRef,
                    currentCategoryId, sort: sortRef, page, total, totalPages,
                    pageNumbers,
                    formatPrice, conditionLabel, countdownOf,
                    isEnding, isUrgent, isEnded, creditLabel, relativeTime,
                    changeCategory, changeSort, goPage, goDetail
                };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
