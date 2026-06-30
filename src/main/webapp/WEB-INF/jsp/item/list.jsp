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
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * CYBERPUNK 2077 — 拍品列表页
         * 暗黑霓虹主题 / 黄 / 青 / 红 三色
         * ============================================================ */

        /* ---------- 全局 ---------- */
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #000;
            color: #FFEE00;
            font-family: 'Sarasa Mono SC', 'Source Code Pro', monospace;
            line-height: 1.5;
            min-height: 100vh;
        }
        a { color: #00F0FF; text-decoration: none; transition: color 0.15s; }
        a:hover { color: #FFEE00; text-shadow: 0 0 6px #FFEE00; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: #0a0a0a; }
        ::-webkit-scrollbar-thumb { background: #00F0FF; border-radius: 3px; }

        /* ---------- 扫描线 ---------- */
        .scanline {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none; z-index: 9999;
            background: repeating-linear-gradient(
                0deg,
                transparent, transparent 2px,
                rgba(0, 240, 255, 0.03) 2px, rgba(0, 240, 255, 0.03) 4px
            );
        }

        /* ---------- Nav ---------- */

        .cp-logo:hover { color: #FFEE00; text-shadow: 0 0 10px #FFEE00; }

        .cp-nav-search button:hover { background: #FFEE00; color: #000; }

        .nav-tags-label { flex-shrink: 0; }
        
        .cp-nav-tag:hover { color: #00F0FF; text-shadow: 0 0 6px #00F0FF; }
        .cp-nav-tag-hot { color: #FF003C; font-weight: 700; }
        .cp-nav-tag-hot:hover { color: #FF003C; text-shadow: 0 0 8px #FF003C; }

        .cp-nav-user .icon-btn:hover { background: rgba(0, 240, 255, 0.1); color: #FFEE00; }
        
        .cp-nav-user .user-name-link { color: #00F0FF; font-weight: 500; }
        .cp-nav-user .user-name-link:hover { color: #FFEE00; }

        /* ---------- 主体 ---------- */
        .cp-container {
            max-width: 1200px; margin: 12px auto 0;
            padding: 0 16px;
            display: grid;
            grid-template-columns: 1fr 40px;
            gap: 12px;
            align-items: start;
        }

        /* ---------- 顶筛选条 ---------- */
        .cp-topbar {
            background: #0d0d0d; border-radius: 2px;
            border: 1px solid rgba(0, 240, 255, 0.15);
            display: flex; align-items: center; padding: 10px 16px;
            margin-bottom: 10px; gap: 8px;
        }
        .topbar-label {
            color: rgba(255, 238, 0, 0.5); font-size: 12px;
            margin-right: 4px; flex-shrink: 0;
        }
        .topbar-sort { display: flex; gap: 4px; flex: 1; min-width: 0; }
        .cp-sort-btn {
            padding: 6px 14px; font-size: 13px; color: rgba(255, 238, 0, 0.6);
            border: 1px solid transparent; border-radius: 2px;
            cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; gap: 3px;
        }
        .cp-sort-btn:hover { color: #00F0FF; border-color: rgba(0, 240, 255, 0.3); }
        .cp-sort-btn.active { background: rgba(0, 240, 255, 0.1); color: #00F0FF; font-weight: 700; border-color: #00F0FF; }
        .cp-sort-btn .arrow { font-size: 10px; }
        .topbar-right {
            display: flex; align-items: center; gap: 10px; flex-shrink: 0;
            font-size: 12px; color: rgba(255, 238, 0, 0.5);
        }
        .topbar-right .page-info {
            background: #0a0a0a; padding: 4px 10px; border-radius: 2px;
            border: 1px solid rgba(0, 240, 255, 0.15);
            display: flex; align-items: center; gap: 8px;
        }
        .topbar-right .page-info .arrow-btn {
            width: 18px; height: 18px; display: grid; place-items: center;
            border-radius: 2px; cursor: pointer; color: rgba(255, 238, 0, 0.5);
            transition: all 0.15s;
        }
        .topbar-right .page-info .arrow-btn:hover:not(.disabled) { background: rgba(0, 240, 255, 0.1); color: #00F0FF; }
        .topbar-right .page-info .arrow-btn.disabled { opacity: 0.3; cursor: not-allowed; }

        /* ---------- 属性筛选条 ---------- */
        .filterbar {
            background: #0d0d0d; border-radius: 2px;
            border: 1px solid rgba(0, 240, 255, 0.15);
            padding: 12px 16px; margin-bottom: 10px;
            display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
        }
        .filterbar-section { display: flex; align-items: center; gap: 6px; }
        .filterbar-label {
            color: rgba(255, 238, 0, 0.5); font-size: 12px;
            display: flex; align-items: center; gap: 4px; flex-shrink: 0;
        }
        .filterbar-label::after { content: '：'; }
        .filter-chip {
            display: flex; align-items: center; gap: 4px;
            padding: 4px 10px; font-size: 12px; color: rgba(255, 238, 0, 0.6);
            border: 1px solid transparent; border-radius: 2px;
            cursor: pointer; transition: all 0.15s; user-select: none;
        }
        .filter-chip:hover { color: #00F0FF; border-color: rgba(0, 240, 255, 0.3); }
        .filter-chip.active { background: rgba(0, 240, 255, 0.1); color: #00F0FF; font-weight: 700; border-color: #00F0FF; }
        .filter-chip i { font-size: 11px; }

        /* 一级 / 二级层级区分 */
        .filter-chip-top {
            font-weight: 600;
            color: rgba(255, 238, 0, 0.85);
        }
        .filter-chip-sub {
            margin-left: 12px;
            padding-left: 8px;
            font-size: 11px;
            color: rgba(255, 238, 0, 0.5);
            border-left: 1px solid rgba(0, 240, 255, 0.18);
        }
        .filter-chip-sub:hover {
            color: #00F0FF;
            border-color: rgba(0, 240, 255, 0.3);
            border-left-color: rgba(0, 240, 255, 0.3);
        }
        .filter-chip-sub.active { border-left-color: #00F0FF; }

        /* ---------- 商品网格 ---------- */
        .cp-goods-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
        }
        @media (max-width: 1200px) { .cp-goods-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .cp-goods-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .cp-goods-grid { grid-template-columns: repeat(3, 1fr); } }

        .cp-goods-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.12);
            border-radius: 2px; overflow: hidden; cursor: pointer; transition: all 0.2s;
            display: flex; flex-direction: column;
        }
        .cp-goods-card:hover {
            border-color: #00F0FF;
            transform: translateY(-2px);
            box-shadow: 0 0 16px rgba(0, 240, 255, 0.15);
        }

        .cp-goods-cover {
            width: 100%; aspect-ratio: 1; background: #0a0a0a;
            position: relative; overflow: hidden; display: grid; place-items: center;
        }
        .cp-goods-cover img {
            width: 100%; height: 100%; object-fit: cover; display: block;
        }
        .cp-goods-cover .placeholder-icon {
            font-size: 36px; color: rgba(0, 240, 255, 0.25);
        }
        .cp-goods-cover .badge {
            position: absolute; top: 6px; left: 6px;
            display: flex; gap: 3px; flex-wrap: wrap;
        }

        /* Cyberpunk badge variants */
        .cp-badge {
            padding: 2px 7px; font-size: 10px; font-weight: 700;
            border-radius: 2px; line-height: 1.5; letter-spacing: 0.5px;
            border: 1px solid;
        }
        .cp-badge-accent { background: rgba(0, 240, 255, 0.12); color: #00F0FF; border-color: rgba(0, 240, 255, 0.35); }
        .cp-badge-danger { background: rgba(255, 0, 60, 0.12); color: #FF003C; border-color: rgba(255, 0, 60, 0.35); }
        .cp-badge-info   { background: rgba(0, 240, 255, 0.08); color: #00F0FF; border-color: rgba(0, 240, 255, 0.2); }
        .cp-badge-purple { background: rgba(191, 64, 191, 0.12); color: #CF6FEF; border-color: rgba(191, 64, 191, 0.35); }
        .cp-badge-success{ background: rgba(0, 255, 65, 0.1); color: #00FF41; border-color: rgba(0, 255, 65, 0.3); }

        .cp-goods-cover .countdown-tag {
            position: absolute; bottom: 0; left: 0; right: 0;
            background: linear-gradient(transparent, rgba(0, 0, 0, 0.85));
            color: #FFEE00; font-size: 11px; padding: 14px 8px 6px;
            display: flex; align-items: center; gap: 4px;
        }
        .cp-goods-cover .countdown-tag.urgent { background: linear-gradient(transparent, rgba(255, 0, 60, 0.85)); }
        .cp-goods-cover .countdown-tag.ended { background: rgba(40, 40, 40, 0.9); color: rgba(255, 238, 0, 0.4); }
        .cp-goods-cover .countdown-tag i { font-size: 10px; }

        .cp-goods-body { padding: 8px 8px 10px; flex: 1; display: flex; flex-direction: column; }
        .cp-goods-title {
            font-size: 12px; color: #FFEE00; line-height: 1.4;
            margin-bottom: 6px; min-height: 34px;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        }
        .item-meta-row {
            display: flex; align-items: center; gap: 6px;
            font-size: 11px; color: rgba(255, 238, 0, 0.45); margin-bottom: 6px;
        }
        .item-meta-row i { font-size: 10px; }
        .cp-goods-price-row {
            display: flex; align-items: baseline; justify-content: space-between; margin-top: auto;
        }
        .cp-goods-price {
            font-size: 16px; font-weight: 700; color: #00F0FF; line-height: 1;
        }
        .cp-goods-price small { font-size: 11px; margin-right: 1px; }
        .cp-goods-bidders {
            font-size: 11px; color: rgba(255, 238, 0, 0.45);
            display: flex; align-items: center; gap: 3px;
        }
        .cp-goods-foot {
            margin-top: 6px; display: flex; align-items: center; gap: 5px;
            font-size: 11px; color: rgba(255, 238, 0, 0.45);
        }
        .item-location { margin-left: auto; }

        /* ---------- 空状态 ---------- */
        .cp-empty {
            text-align: center; padding: 80px 24px; color: rgba(255, 238, 0, 0.4);
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.12);
            border-radius: 2px;
        }
        .cp-empty i { font-size: 48px; margin-bottom: 12px; opacity: 0.3; }

        /* ---------- 分页 ---------- */
        .cp-pagination {
            display: flex; justify-content: center; gap: 6px;
            margin: 24px 0 12px;
        }
        .cp-page-btn {
            min-width: 36px; height: 36px; padding: 0 10px;
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.15);
            border-radius: 2px; cursor: pointer; font-size: 13px;
            display: inline-flex; align-items: center; justify-content: center;
            transition: all 0.15s; color: #FFEE00; font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-page-btn:hover:not(:disabled) { border-color: #00F0FF; color: #00F0FF; box-shadow: 0 0 8px rgba(0, 240, 255, 0.15); }
        .cp-page-btn.active { background: #00F0FF; color: #000; border-color: #00F0FF; font-weight: 700; }
        .cp-page-btn:disabled { opacity: 0.3; cursor: not-allowed; }

        /* ---------- 右侧浮动操作栏 ---------- */
        .cp-floats {
            position: sticky; top: 72px;
            display: flex; flex-direction: column; gap: 6px;
        }
        .cp-float-btn {
            width: 40px; height: 40px; background: #0d0d0d;
            border: 1px solid rgba(0, 240, 255, 0.15); border-radius: 2px;
            display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            color: #00F0FF; box-shadow: 0 0 6px rgba(0, 240, 255, 0.05);
            transition: all 0.15s; cursor: pointer; font-size: 10px; gap: 1px;
        }
        .cp-float-btn i { font-size: 14px; }
        .cp-float-btn:hover { background: #00F0FF; color: #000; transform: translateY(-1px); box-shadow: 0 0 12px #00F0FF; }
        .cp-float-btn.primary { background: #00F0FF; color: #000; border-color: #00F0FF; }

        /* ---------- 错误条 ---------- */
        .error-bar {
            background: rgba(255, 0, 60, 0.1); color: #FF003C;
            border: 1px solid rgba(255, 0, 60, 0.3);
            padding: 10px 16px; border-radius: 2px;
            margin-bottom: 12px; font-size: 13px;
        }

        /* ---------- 响应式 ---------- */
        @media (max-width: 1024px) {

            .cp-container { grid-template-columns: 1fr; }
            .cp-floats { display: none; }
        }
        @media (max-width: 768px) {

            .filterbar { gap: 10px; }
        }

        /* ---------- 页脚 ---------- */
        .list-footer {
            background: #050505; color: rgba(255, 238, 0, 0.4);
            border-top: 1px solid rgba(0, 240, 255, 0.1);
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .list-footer-inner {
            max-width: 1200px; margin: 0 auto;
            color: rgba(255, 238, 0, 0.3);
        }

        /* 下拉容器（搜索建议等） */
        .search-dropdown {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.2);
            border-top: none; border-radius: 0 0 2px 2px;
        }
    </style>
</head>
<body>

<div class="scanline" aria-hidden="true"></div>

<!-- ========== 顶 nav ========== -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="cp-logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list" class="active">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="javascript:void(0)" onclick="go('<%=ctx%>/item?action=hot-ranks')">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=center')">个人中心</a>
            <% } %>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="cp-nav-search" id="searchForm">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ..."
                   value="<%= keyword %>">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="cp-nav-user">
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=center')" class="user-name-link"><%= currentUser.getUsername() %></a>
                <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=logout')" style="font-size: 12px; color: rgba(255,238,0,0.5);">退出</a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" class="icon-btn" title="登录"><i class="fa fa-user-o"></i></a>
                <a href="<%=ctx%>/user?action=login" style="font-size: 13px; padding: 6px 12px; color: #00F0FF; border: 1px solid #00F0FF; border-radius: 2px;">登录</a>
                <a href="<%=ctx%>/user?action=register" style="font-size: 13px; padding: 6px 12px; color: #000; background: #00F0FF; border-radius: 2px;">注册</a>
            <% } %>
        </div>
    </div>
</header>

<!-- ========== 主体两栏 ========== -->
<div class="cp-container">
<div id="app">

    <% if (error != null) { %>
    <div class="error-bar"><%= error %></div>
    <% } %>

    <!-- 顶筛选条（综合 / 排序） -->
    <div class="cp-topbar">
        <span class="topbar-label">排序</span>
        <div class="topbar-sort">
            <div :class="['cp-sort-btn', { active: sort==='newest' }]" @click="changeSort('newest')">综合</div>
            <div :class="['cp-sort-btn', { active: sort==='ending' }]" @click="changeSort('ending')">
                即将结束 <i class="fa fa-angle-down arrow"></i>
            </div>
            <div :class="['cp-sort-btn', { active: sort==='hot' }]" @click="changeSort('hot')">
                新发布 <i class="fa fa-angle-down arrow"></i>
            </div>
            <div :class="['cp-sort-btn', { active: sort==='priceAsc' }]" @click="changeSort('priceAsc')">
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

    <!-- 分类筛选条（一级 + 缩进二级） -->
    <div class="filterbar">
        <div class="filterbar-section">
            <span class="filterbar-label">分类</span>
            <div :class="['filter-chip', { active: !currentCategoryId }]" @click="changeCategory(null)">全部</div>
            <template v-for="top in topCategories" :key="top.id">
                <div :class="['filter-chip', 'filter-chip-top', { active: currentCategoryId === top.id }]"
                     @click="changeCategory(top.id)">
                    {{ top.categoryName }}
                </div>
                <div v-for="sub in subCategoriesOf(top.id)" :key="sub.id"
                     :class="['filter-chip', 'filter-chip-sub', { active: currentCategoryId === sub.id }]"
                     @click="changeCategory(sub.id)">
                    {{ sub.categoryName }}
                </div>
            </template>
            <!-- 没有 parent 的"游离"分类（孤儿兜底） -->
            <div v-for="o in orphanCategories" :key="o.id"
                 :class="['filter-chip', 'filter-chip-sub', { active: currentCategoryId === o.id }]"
                 @click="changeCategory(o.id)">
                {{ o.categoryName }}
            </div>
        </div>
        <div style="margin-left: auto; font-size: 12px; color: rgba(255,238,0,0.5);">
            共 <strong style="color: #00F0FF;">{{ total }}</strong> 件拍品
        </div>
    </div>

    <!-- 商品网格 -->
    <div v-if="items.length === 0" class="cp-empty">
        <i class="fa fa-inbox"></i>
        <p>暂无符合条件的拍品</p>
    </div>
    <div v-else class="cp-goods-grid">
        <div v-for="item in items" :key="item.id" class="cp-goods-card" @click="goDetail(item.id)">
            <div class="cp-goods-cover"
                 :style="item.coverImage ? 'background-image:url(' + item.coverImage + ');background-size:cover;background-position:center;' : ''">
                <i v-if="!item.coverImage" class="fa fa-image placeholder-icon"></i>
                <div class="badge">
                    <span class="cp-badge cp-badge-accent" v-if="item.freeShipping">包邮</span>
                    <span class="cp-badge cp-badge-danger" v-if="isEnding(item)">即将结束</span>
                    <span class="cp-badge cp-badge-info" v-if="item.conditionLevel === '全新'">全新</span>
                    <span class="cp-badge cp-badge-purple" v-else-if="item.conditionLevel === '严选'">严选</span>
                </div>
                <div :class="['countdown-tag', { urgent: isUrgent(item), ended: isEnded(item) }]">
                    <i class="fa fa-clock-o"></i>
                    <span v-if="isEnded(item)">已结束</span>
                    <span v-else>剩余 {{ countdownOf(item) }}</span>
                </div>
            </div>
            <div class="cp-goods-body">
                <div class="cp-goods-title">{{ item.title }}</div>
                <div class="item-meta-row">
                    <i class="fa fa-clock-o"></i>
                    <span>{{ relativeTime(item) }}</span>
                </div>
                <div class="cp-goods-price-row">
                    <div class="cp-goods-price">
                        <small>¥</small>{{ formatPrice(item.currentPrice) }}
                    </div>
                    <div class="cp-goods-bidders">
                        <i class="fa fa-user-o"></i> {{ item.viewCount || 0 }}
                    </div>
                </div>
                <div class="cp-goods-foot">
                    <span class="cp-badge">{{ creditLabel(item) }}</span>
                    <span class="item-location" v-if="item.location">{{ item.location }}</span>
                    <span class="item-location" v-else>—</span>
                </div>
            </div>
        </div>
    </div>

    <!-- 分页 -->
    <div v-if="totalPages > 1" class="cp-pagination">
        <button class="cp-page-btn" :disabled="page === 1" @click="goPage(1)">
            <i class="fa fa-angle-double-left"></i>
        </button>
        <button class="cp-page-btn" :disabled="page === 1" @click="goPage(page - 1)">
            <i class="fa fa-angle-left"></i>
        </button>
        <button v-for="p in pageNumbers" :key="p"
                :class="['cp-page-btn', { active: p === page }]" @click="goPage(p)">
            {{ p }}
        </button>
        <button class="cp-page-btn" :disabled="page === totalPages" @click="goPage(page + 1)">
            <i class="fa fa-angle-right"></i>
        </button>
        <button class="cp-page-btn" :disabled="page === totalPages" @click="goPage(totalPages)">
            <i class="fa fa-angle-double-right"></i>
        </button>
    </div>

</div>

    <!-- 右侧浮动操作栏 -->
    <aside class="cp-floats">
        <div class="cp-float-btn primary" title="发拍品" onclick="go('<%=ctx%>/item?action=publish-page')">
            <i class="fa fa-plus"></i><span>发布</span>
        </div>
        <div class="cp-float-btn" title="消息" onclick="go('<%= currentUser != null ? ctx + "/user?action=center" : ctx + "/user?action=login" %>')">
            <i class="fa fa-envelope-o"></i><span>消息</span>
        </div>
        <div class="cp-float-btn" title="APP" onclick="toast('APP 下载敬请期待', 'info')">
            <i class="fa fa-mobile"></i><span>APP</span>
        </div>
        <div class="cp-float-btn" title="反馈" onclick="toast('反馈功能开发中', 'info')">
            <i class="fa fa-commenting-o"></i><span>反馈</span>
        </div>
        <div class="cp-float-btn" title="客服" onclick="toast('客服：400-888-8888', 'info')">
            <i class="fa fa-headphones"></i><span>客服</span>
        </div>
        <div class="cp-float-btn" title="回顶部" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" style="margin-top: auto;">
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

                // 分类层级：一级 + parentId 关系
                const topCategories = computed(() =>
                    categoriesRef.value.filter(c => c.parentId === 0)
                );
                const orphanCategories = computed(() => {
                    // 二级分类里 parentId 找不到对应一级的，单独列兜底
                    const topIds = new Set(topCategories.value.map(c => c.id));
                    return categoriesRef.value.filter(c =>
                        c.parentId !== 0 && c.parentId != null && !topIds.has(c.parentId)
                    );
                });
                function subCategoriesOf(parentId) {
                    return categoriesRef.value
                        .filter(c => c.parentId === parentId)
                        .sort((a, b) => (a.sortOrder || 0) - (b.sortOrder || 0));
                }

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
                    topCategories, subCategoriesOf, orphanCategories,
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
