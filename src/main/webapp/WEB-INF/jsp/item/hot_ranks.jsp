<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%!
    /** 渲染一张拍品卡片（带排名圈 + 状态角标）。ranked=true 时显示编号（金/银/铜/灰）。 */
    private String renderHotCard(org.example.entity.AuctionItem item, int rank, String ctx, boolean ranked) {
        if (item == null) return "";
        String rankCls = "rank-gray";
        if (rank == 1)      rankCls = "rank-gold";
        else if (rank == 2) rankCls = "rank-silver";
        else if (rank == 3) rankCls = "rank-bronze";

        String cover = item.getCoverImage() != null && !item.getCoverImage().isEmpty()
                ? "background-image: url('" + item.getCoverImage() + "'); background-size: cover; background-position: center;"
                : "";

        // 状态角标（所有状态都上榜，所以要标识出来）
        Integer st = item.getStatus();
        String badge = "";
        if (st != null && st == 0)        badge = "<div class=\"hot-badge badge-pending\">待审核</div>";
        else if (st != null && st == 2)   badge = "<div class=\"hot-badge badge-sold\">已成交</div>";
        else if (st != null && st == 3)   badge = "<div class=\"hot-badge badge-failed\">已流拍</div>";
        else if (st != null && st == 4)   badge = "<div class=\"hot-badge badge-offline\">已下架</div>";
        else if (st != null && st == 5)   badge = "<div class=\"hot-badge badge-rejected\">未通过</div>";

        StringBuilder sb = new StringBuilder();
        sb.append("<a href=\"").append(ctx).append("/item?action=detail&id=").append(item.getId())
          .append("\" class=\"hot-card\">");
        if (ranked) {
            sb.append("<div class=\"hot-rank ").append(rankCls).append("\">").append(rank).append("</div>");
        }
        sb.append("<div class=\"hot-cover\" style=\"").append(cover).append("\">");
        if (item.getCoverImage() == null || item.getCoverImage().isEmpty()) {
            sb.append("<i class=\"fa fa-image\"></i>");
        }
        sb.append(badge);
        sb.append("</div>");
        sb.append("<div class=\"hot-body\">");
        sb.append("<div class=\"hot-title\">").append(EscapeUtil.html(item.getTitle())).append("</div>");
        sb.append("<div class=\"hot-meta\">");
        sb.append("<span class=\"hot-price\"><small>¥</small>")
          .append(item.getCurrentPrice() == null ? "0.00" : item.getCurrentPrice().toPlainString())
          .append("</span>");
        sb.append("<span class=\"hot-views\"><i class=\"fa fa-fire\"></i> ")
          .append(item.getViewCount() == null ? 0 : item.getViewCount())
          .append("</span>");
        sb.append("</div></div></a>");
        return sb.toString();
    }
%>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    @SuppressWarnings("unchecked")
    java.util.List<org.example.entity.AuctionItem> globalHot =
            (java.util.List<org.example.entity.AuctionItem>) request.getAttribute("globalHot");

    @SuppressWarnings("unchecked")
    java.util.List<java.util.Map<String, Object>> sections =
            (java.util.List<java.util.Map<String, Object>>) request.getAttribute("sections");

    String error = (String) request.getAttribute("error");
    if (globalHot == null) globalHot = new java.util.ArrayList<>();
    if (sections == null) sections = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>热门拍品 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * HOT RANKS PAGE — 全站热度榜 + 各分类热度榜
         * 配色沿用 cyberpunk：黄 + 青 + 红
         * ============================================================ */

        body {
            background: #050505;
            color: #FFEE00;
            font-family: 'Sarasa Mono SC', monospace;
            min-height: 100vh;
        }

        .scanline {
            position: fixed; inset: 0; z-index: 9999; pointer-events: none;
            background: repeating-linear-gradient(0deg, transparent, transparent 2px,
                       rgba(0,240,255,0.025) 2px, rgba(0,240,255,0.025) 4px);
        }

        /* ---- MAIN ---- */
        .hr-container {
            max-width: 1200px;
            margin: 16px auto 40px;
            padding: 0 16px;
        }

        /* ---- HERO BANNER ---- */
        .hr-hero {
            position: relative;
            padding: 28px 32px;
            background: linear-gradient(135deg, rgba(255,0,60,0.12) 0%, rgba(0,240,255,0.10) 50%, rgba(255,238,0,0.10) 100%);
            border: 1px solid rgba(0,240,255,0.35);
            clip-path: polygon(1% 0, 99% 0, 100% 3%, 100% 97%, 99% 100%, 1% 100%, 0 97%, 0 3%);
            margin-bottom: 20px;
            overflow: hidden;
        }
        .hr-hero::before {
            content: ''; position: absolute; top: -50%; right: -10%;
            width: 400px; height: 400px;
            background: radial-gradient(circle, rgba(255,0,60,0.15) 0%, transparent 70%);
            pointer-events: none;
        }
        .hr-hero-title {
            font-size: 28px; font-weight: 700;
            font-family: 'Sarasa Mono SC', monospace;
            color: #FF003C;
            text-shadow: 0 0 16px rgba(255,0,60,0.5);
            letter-spacing: 0.08em;
            margin-bottom: 8px;
        }
        .hr-hero-title .prefix { color: rgba(255,238,0,0.5); margin-right: 8px; }
        .hr-hero-sub {
            color: rgba(255,238,0,0.65); font-size: 13px;
            display: flex; align-items: center; gap: 18px; flex-wrap: wrap;
        }
        .hr-hero-sub i { color: #00F0FF; margin-right: 4px; }

        /* ---- SECTION HEADER ---- */
        .hr-section {
            margin-top: 28px;
        }
        .hr-section-head {
            display: flex; align-items: center; gap: 12px;
            margin-bottom: 14px;
            padding-bottom: 10px;
            border-bottom: 1px solid rgba(0,240,255,0.18);
        }
        .hr-section-icon {
            width: 32px; height: 32px;
            background: rgba(0,240,255,0.10);
            border: 1px solid rgba(0,240,255,0.45);
            display: grid; place-items: center;
            color: #00F0FF; font-size: 14px;
            clip-path: polygon(15% 0, 85% 0, 100% 15%, 100% 85%, 85% 100%, 15% 100%, 0 85%, 0 15%);
        }
        .hr-section-title {
            font-size: 16px; font-weight: 700; color: #FFEE00;
            font-family: 'Sarasa Mono SC', monospace;
            letter-spacing: 0.06em;
        }
        .hr-section-title .num {
            margin-left: 6px; font-size: 12px;
            color: rgba(0,240,255,0.7);
            font-family: inherit;
        }
        .hr-section-more {
            margin-left: auto; font-size: 12px;
            color: rgba(255,238,0,0.6);
            text-decoration: none;
            padding: 5px 12px;
            border: 1px solid rgba(0,240,255,0.25);
            transition: all 0.15s;
        }
        .hr-section-more:hover {
            color: #00F0FF;
            border-color: #00F0FF;
            box-shadow: 0 0 8px rgba(0,240,255,0.3);
        }

        /* ---- GLOBAL GRID: 6 列 ---- */
        .hr-global-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 12px;
        }
        @media (max-width: 1024px) { .hr-global-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .hr-global-grid { grid-template-columns: repeat(3, 1fr); } }

        /* ---- PER-CATEGORY GRID: 4 列 ---- */
        .hr-cat-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 10px;
        }
        @media (max-width: 1024px) { .hr-cat-grid { grid-template-columns: repeat(3, 1fr); } }
        @media (max-width: 768px)  { .hr-cat-grid { grid-template-columns: repeat(2, 1fr); } }

        /* ---- CARD ---- */
        .hot-card {
            position: relative;
            background: #0d0d0d;
            border: 1px solid rgba(255,238,0,0.12);
            color: inherit;
            text-decoration: none;
            overflow: hidden;
            clip-path: polygon(2% 0, 98% 0, 100% 3%, 100% 97%, 98% 100%, 2% 100%, 0 97%, 0 3%);
            transition: all 0.18s;
            display: block;
        }
        .hot-card:hover {
            border-color: #00F0FF;
            box-shadow: 0 0 16px rgba(0,240,255,0.25);
            transform: translateY(-2px);
        }

        .hot-rank {
            position: absolute; top: 6px; left: 6px;
            width: 26px; height: 26px;
            display: grid; place-items: center;
            font-size: 13px; font-weight: 700;
            font-family: 'Sarasa Mono SC', monospace;
            z-index: 2;
            color: #0a0a0a;
            clip-path: polygon(20% 0, 80% 0, 100% 20%, 100% 80%, 80% 100%, 20% 100%, 0 80%, 0 20%);
        }
        .rank-gold   { background: linear-gradient(135deg, #FFD700, #FFA500); box-shadow: 0 0 12px rgba(255,215,0,0.6); }
        .rank-silver { background: linear-gradient(135deg, #E0E0E0, #A0A0A0); box-shadow: 0 0 8px rgba(200,200,200,0.5); }
        .rank-bronze { background: linear-gradient(135deg, #CD7F32, #8B4513); color: #fff; box-shadow: 0 0 6px rgba(205,127,50,0.5); }
        .rank-gray   { background: rgba(80,80,80,0.85); color: #ccc; }

        .hot-cover {
            width: 100%; aspect-ratio: 1;
            background: #111;
            display: grid; place-items: center;
            color: rgba(255,238,0,0.18);
            font-size: 28px;
            border-bottom: 1px solid rgba(255,238,0,0.10);
        }

        .hot-body { padding: 8px 10px; }
        .hot-title {
            font-size: 12px; line-height: 1.4;
            color: #ddd;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
            margin-bottom: 6px;
            min-height: 34px;
        }
        .hot-card:hover .hot-title { color: #FFEE00; }
        .hot-meta {
            display: flex; align-items: center; justify-content: space-between;
            font-size: 12px;
        }
        .hot-price {
            color: #FFEE00;
            font-family: 'Sarasa Mono SC', monospace;
            font-weight: 700;
        }
        .hot-price small { font-size: 10px; margin-right: 1px; opacity: 0.7; }
        .hot-views {
            color: #FF003C; font-size: 11px;
            display: flex; align-items: center; gap: 3px;
        }
        .hot-views i { font-size: 11px; }

        /* ---- 状态角标（所有 status 都上榜，靠角标区分） ---- */
        .hot-badge {
            position: absolute; top: 6px; right: 6px;
            padding: 2px 8px;
            font-size: 10px; font-weight: 700;
            font-family: 'Sarasa Mono SC', monospace;
            letter-spacing: 0.05em;
            color: #fff;
            z-index: 2;
            clip-path: polygon(10% 0, 90% 0, 100% 50%, 90% 100%, 10% 100%, 0% 50%);
        }
        .badge-pending  { background: #FFEE00; color: #0a0a0a; }    /* 待审核 - 黄 */
        .badge-sold     { background: #FF003C; }                      /* 已成交 - 红 */
        .badge-failed   { background: #555; color: #ddd; }            /* 已流拍 - 灰 */
        .badge-offline  { background: #2a2a2a; color: #888; }         /* 已下架 - 暗灰 */
        .badge-rejected { background: #ff8800; color: #0a0a0a; }      /* 未通过 - 橙 */

        /* ---- ERROR ---- */
        .hr-error {
            background: rgba(255,0,60,0.10);
            border: 1px solid #FF003C;
            color: #FF6B8A;
            padding: 12px 18px;
            clip-path: polygon(1% 0, 99% 0, 100% 3%, 100% 97%, 99% 100%, 1% 100%, 0 97%, 0 3%);
            margin-bottom: 14px;
        }

        /* ---- EMPTY ---- */
        .hr-empty {
            text-align: center;
            padding: 60px 20px;
            color: rgba(255,238,0,0.4);
            font-size: 13px;
        }
        .hr-empty i { display: block; font-size: 40px; margin-bottom: 10px; opacity: 0.4; }

        /* ---- FOOTER (与 list.jsp 一致) ---- */
        .list-footer {
            background: #050505; color: rgba(255,238,0,0.4);
            border-top: 1px solid rgba(0,240,255,0.1);
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .list-footer-inner {
            max-width: 1200px; margin: 0 auto;
            color: rgba(255,238,0,0.3);
        }

        /* ---- 修正 cp-nav 按钮在 hot_ranks 上的细节 ---- */
        .cp-nav-menu a.active {
            color: #FFEE00;
            text-shadow: 0 0 10px rgba(255,238,0,0.4);
        }
    </style>
</head>
<body>

<div class="scanline"></div>

<%-- ========== NAV ========== --%>
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="cp-logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/item?action=hot-ranks" class="active">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="<%=ctx%>/user?action=center">个人中心</a>
            <% } %>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="cp-nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="cp-nav-tags">
            <span class="nav-tags-label">热搜：</span>
            <a href="<%=ctx%>/item/list?keyword=iPhone" class="cp-nav-tag cp-nav-tag-hot">iPhone 15</a>
            <a href="<%=ctx%>/item/list?keyword=相机" class="cp-nav-tag">相机</a>
            <a href="<%=ctx%>/item/list?keyword=球鞋" class="cp-nav-tag">球鞋</a>
            <a href="<%=ctx%>/item/list?keyword=茅台" class="cp-nav-tag cp-nav-tag-hot">茅台</a>
        </div>
        <div class="cp-nav-user">
            <% if (currentUser != null) { %>
                <a href="<%=ctx%>/user?action=center" class="user-name-link">
                    <%= currentUser.getUsername() %>
                </a>
                <a href="<%=ctx%>/user?action=logout"
                   style="font-size: 11px; color: #555; text-decoration: none;">[退出]</a>
                <a href="<%=ctx%>/user?action=center" class="cp-avatar">
                    <%= currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()
                        ? currentUser.getUsername().substring(0, 1).toUpperCase() : "?" %>
                </a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" class="user-name-link">登录</a>
                <a href="<%=ctx%>/user?action=register" class="cp-avatar">?</a>
            <% } %>
        </div>
    </div>
</header>

<main class="hr-container">

    <% if (error != null) { %>
        <div class="hr-error">
            <i class="fa fa-exclamation-triangle"></i> // <%= error %>
        </div>
    <% } %>

    <%-- ========== HERO ========== --%>
    <section class="hr-hero">
        <div class="hr-hero-title">
            <span class="prefix">//</span>HOT&nbsp;RANKS&nbsp;<span style="color:#FFEE00;">·</span>&nbsp;热门拍品
        </div>
        <div class="hr-hero-sub">
            <span><i class="fa fa-fire"></i>全站热度 TOP <%= globalHot.size() %> · 浏览量排序</span>
            <span><i class="fa fa-th-large"></i>各分类热度榜</span>
            <span style="margin-left:auto;color:rgba(0,240,255,0.5);font-size:11px;">
                <i class="fa fa-list"></i>所有状态拍品（含已成交/已流拍）
            </span>
        </div>
    </section>

    <%-- ========== 全站热度榜 ========== --%>
    <section class="hr-section">
        <div class="hr-section-head">
            <div class="hr-section-icon"><i class="fa fa-trophy"></i></div>
            <div class="hr-section-title">
                全站热度榜
                <span class="num">/TOP <%= globalHot.size() %></span>
            </div>
            <a href="<%=ctx%>/item?action=list&sort=hot" class="hr-section-more">
                查看全部 →
            </a>
        </div>
        <% if (globalHot.isEmpty()) { %>
            <div class="hr-empty">
                <i class="fa fa-fire-extinguisher"></i>
                暂时还没有热门拍品，欢迎
                <a href="<%=ctx%>/item?action=publish-page" style="color:#00F0FF;">发布拍品</a>
            </div>
        <% } else { %>
            <div class="hr-global-grid">
                <%
                    int rank = 0;
                    for (org.example.entity.AuctionItem item : globalHot) {
                        rank++;
                        out.write(renderHotCard(item, rank, ctx, true));
                    }
                %>
            </div>
        <% } %>
    </section>

    <%-- ========== 各分类热度榜 ========== --%>
    <% if (sections.isEmpty()) { %>
        <section class="hr-section">
            <div class="hr-empty">
                <i class="fa fa-folder-open-o"></i>
                暂无任何分类数据
            </div>
        </section>
    <% } else { %>
        <% for (java.util.Map<String, Object> section : sections) {
               org.example.entity.Category cat = (org.example.entity.Category) section.get("category");
               @SuppressWarnings("unchecked")
               java.util.List<org.example.entity.AuctionItem> items = (java.util.List<org.example.entity.AuctionItem>) section.get("hotItems");
               if (items == null) items = new java.util.ArrayList<>();
        %>
            <section class="hr-section">
                <div class="hr-section-head">
                    <div class="hr-section-icon">
                        <i class="fa fa-<%= cat.getIcon() == null || cat.getIcon().isEmpty() ? "tag" : cat.getIcon() %>"></i>
                    </div>
                    <div class="hr-section-title">
                        <%= cat.getCategoryName() %>
                        <span class="num">/热度 TOP <%= items.size() %></span>
                    </div>
                    <a href="<%=ctx%>/item?action=list&category=<%= cat.getId() %>&sort=hot"
                       class="hr-section-more">
                        <%= cat.getCategoryName() %>完整榜单 →
                    </a>
                </div>
                <div class="hr-cat-grid">
                    <%
                        int subRank = 0;
                        for (org.example.entity.AuctionItem item : items) {
                            subRank++;
                            // 分类榜里也带排名（1-3 金银铜，超过 3 灰）
                            out.write(renderHotCard(item, subRank, ctx, true));
                        }
                    %>
                </div>
            </section>
        <% } %>
    <% } %>

</main>

<%-- ========== FOOTER ========== --%>
<footer class="list-footer">
    <div class="list-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script>
    // 把 hover 卡片时的 view_count 通过 prefetch 提升（不阻塞、不强求）
    document.querySelectorAll('.hot-card').forEach(card => {
        card.addEventListener('mouseenter', () => {
            const m = card.getAttribute('href').match(/id=(\d+)/);
            if (m && m[1]) {
                // 后端在 detail 页会自增 view_count，无需前端重复触发
            }
        });
    });
</script>
</body>
</html>
