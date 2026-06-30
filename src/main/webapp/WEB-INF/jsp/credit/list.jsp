<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect(ctx + "/user?action=login");
        return;
    }

    String rowsJson = (String) request.getAttribute("rowsJson");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("pageNo");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    String type = (String) request.getAttribute("type");
    java.util.Map<String, Object> stat =
            (java.util.Map<String, Object>) request.getAttribute("stat");
    String error = (String) request.getAttribute("error");
    if (rowsJson == null) rowsJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (type == null) type = "received";
    if (stat == null) stat = new java.util.HashMap<>();
    // MyBatis 的 COUNT/AVG 聚合返回 Long/Long/Double，JSP 不能直接强转 Integer/Double
    Number countNum = (Number) stat.get("count");
    Number avgNum = (Number) stat.get("avgScore");
    int statCount = countNum == null ? 0 : countNum.intValue();
    double statAvg = avgNum == null ? 0.0 : avgNum.doubleValue();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我的评价 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * Cyberpunk 2077 — 我的评价
         * 黑色背景 / #FFEE00 霓虹黄 / 单色字体 / clip-path 多边形
         * ============================================================ */
        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background: #000;
            color: #FFEE00;
            font-family: 'Sarasa Mono SC', 'Source Code Pro', monospace;
            line-height: 1.6;
        }

        a { color: #FFEE00; text-decoration: none; transition: all 0.15s; }
        a:hover { color: #fff; text-shadow: 0 0 10px #FFEE00, 0 0 20px #FFEE00; }

        /* ---- Nav ---- */

        .cp-logo:hover { text-shadow: 0 0 10px #FFEE00; }
        .logo-icon {
            width: 30px; height: 30px; background: #FFEE00; color: #000;
            display: grid; place-items: center; font-size: 14px;
            clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
        }

        .cp-nav-search button:hover { background: #fff; }

        .user-name-link { color: #FFEE00; font-weight: 500; }
        .user-name-link:hover { text-shadow: 0 0 8px #FFEE00; }

        /* ---- Page head ---- */
        .credit-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        .cp-page-head {
            background: #0a0a0a;
            border: 1px solid #FFEE00;
            clip-path: polygon(12px 0, 100% 0, 100% 100%, 0 100%, 0 12px);
            padding: 20px 24px;
            display: flex; align-items: center; gap: 16px;
        }
        .credit-head-icon {
            width: 48px; height: 48px;
            border: 2px solid #FFEE00; color: #FFEE00; background: #000;
            display: grid; place-items: center; font-size: 22px;
            clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
        }
        .credit-head-info { flex: 1; min-width: 0; }
        .cp-page-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 1px; }
        .cp-page-sub { font-size: 12px; color: #888; font-family: 'Sarasa Mono SC', monospace; }
        .credit-head-actions { }

        /* ---- Alert ---- */
        .alert {
            padding: 10px 16px; margin-top: 12px; font-size: 13px;
            border: 1px solid #FFEE00; background: #111; color: #FFEE00;
            clip-path: polygon(6px 0, 100% 0, 100% 100%, 0 100%, 0 6px);
        }

        /* ---- Stat card ---- */
        .stat-card {
            background: #0a0a0a;
            border: 1px solid #FFEE00;
            clip-path: polygon(14px 0, 100% 0, 100% 100%, 0 100%, 0 14px);
            margin-top: 12px; padding: 20px 24px;
            display: flex; align-items: center; gap: 24px;
        }
        .stat-card-icon {
            width: 64px; height: 64px;
            border: 2px solid #FFEE00; color: #FFEE00; background: #000;
            display: grid; place-items: center; font-size: 30px;
            clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
        }
        .stat-card-body { flex: 1; }
        .stat-card-title { font-size: 13px; color: #FFEE00; margin-bottom: 4px; font-weight: 500; text-transform: uppercase; letter-spacing: 1px; }
        .stat-card-value { font-size: 36px; font-weight: 800; color: #FFEE00; line-height: 1.1;
                           display: flex; align-items: baseline; gap: 8px;
                           text-shadow: 0 0 12px rgba(255,238,0,0.5); }
        .stat-card-value small { font-size: 18px; font-weight: 600; color: #888; }
        .stat-card-sub { font-size: 12px; color: #888; margin-top: 4px; }

        /* ---- Tabs ---- */
        .cp-tabs {
            background: #0a0a0a;
            border: 1px solid #333;
            margin-top: 12px; padding: 4px 20px;
            display: flex; align-items: center;
        }
        .cp-tab {
            padding: 12px 16px; font-size: 14px; color: #888;
            cursor: pointer; position: relative; font-weight: 500;
            text-decoration: none; font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-tab:hover { color: #FFEE00; }
        .cp-tab.active { color: #FFEE00; font-weight: 700; }
        .cp-tab.active::after {
            content: ''; position: absolute;
            bottom: 0; left: 50%; transform: translateX(-50%);
            width: 24px; height: 2px; background: #FFEE00;
            box-shadow: 0 0 8px #FFEE00;
        }

        /* ---- Card list ---- */
        .credit-list { display: flex; flex-direction: column; gap: 10px; margin-top: 12px; }
        .credit-card {
            background: #0a0a0a;
            border: 1px solid #FFEE00;
            clip-path: polygon(10px 0, 100% 0, 100% 100%, 0 100%, 0 10px);
            padding: 16px 20px; display: grid;
            grid-template-columns: 60px 1fr auto; gap: 14px;
            align-items: start;
        }
        .credit-cover {
            width: 60px; height: 60px;
            clip-path: polygon(6px 0, 100% 0, 100% 100%, 0 100%, 0 6px);
            background: #111; display: grid; place-items: center;
            color: #555; overflow: hidden; flex-shrink: 0;
        }
        .credit-cover img { width: 100%; height: 100%; object-fit: cover; }
        .credit-body { min-width: 0; }
        .credit-line-1 {
            display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
            font-size: 13px; color: #888; margin-bottom: 6px;
        }
        .credit-line-1 .username { font-weight: 600; color: #FFEE00; }
        .credit-line-1 .sep { color: #444; }
        .credit-line-1 .role-tag {
            padding: 1px 6px; font-size: 11px;
            background: #222; color: #FFEE00; border: 1px solid #FFEE00;
        }
        .credit-line-2 {
            display: flex; align-items: center; gap: 6px;
            font-size: 13px; color: #aaa; margin-bottom: 6px;
        }
        .credit-line-2 .item-link { color: #aaa; text-decoration: none; }
        .credit-line-2 .item-link:hover { color: #FFEE00; text-shadow: 0 0 6px #FFEE00; }
        .credit-stars { display: flex; gap: 1px; }
        .credit-stars i { font-size: 14px; color: #333; }
        .credit-stars i.on { color: #FFEE00; text-shadow: 0 0 6px rgba(255,238,0,0.6); }
        .credit-content {
            font-size: 13px; line-height: 1.6; color: #ccc;
            background: #111; padding: 10px 12px;
            border-left: 3px solid #FFEE00;
            margin-top: 6px; word-break: break-all; white-space: pre-wrap;
        }
        .credit-time {
            font-size: 12px; color: #555; text-align: right; white-space: nowrap;
        }
        .credit-time .ago { display: block; margin-top: 2px; color: #444; }

        /* ---- Empty state ---- */
        .empty-state {
            background: #0a0a0a; border: 1px solid #333;
            clip-path: polygon(10px 0, 100% 0, 100% 100%, 0 100%, 0 10px);
            margin-top: 12px; text-align: center; padding: 80px 20px;
            color: #555; font-size: 13px;
        }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }
        .empty-state a { color: #FFEE00; font-weight: 600; }

        /* ---- Pager ---- */
        .pager { margin-top: 16px; display: flex; justify-content: center; gap: 6px; }
        .pager a, .pager span {
            padding: 6px 12px; border: 1px solid #333;
            font-size: 13px; color: #888; text-decoration: none;
            min-width: 32px; text-align: center; background: #0a0a0a;
            font-family: 'Sarasa Mono SC', monospace;
        }
        .pager a:hover { border-color: #FFEE00; color: #FFEE00; }
        .pager .active { background: #FFEE00; color: #000; border-color: #FFEE00; font-weight: 700; }
        .pager .disabled { color: #444; cursor: not-allowed; background: #050505; }

        /* ---- Footer ---- */
        .credit-footer {
            background: #050505; border-top: 1px solid #FFEE00;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .credit-footer-inner { max-width: 1200px; margin: 0 auto; color: #555; }

        [v-cloak] { display: none; }

        /* ---- Scrollbar ---- */
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: #0a0a0a; }
        ::-webkit-scrollbar-thumb { background: #333; border-radius: 4px; }
        ::-webkit-scrollbar-thumb:hover { background: #FFEE00; }
    </style>
</head>
<body>

<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
            <a href="<%=ctx%>/user?action=center">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="cp-nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="cp-nav-user">
            <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= currentUser.getUsername() %></a>
            <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: #555;">退出</a>
            <a href="<%=ctx%>/user?action=center" class="avatar">
                <%= currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()
                    ? currentUser.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </a>
        </div>
    </div>
</header>

<div class="credit-wrap" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="cp-page-head">
        <div class="credit-head-icon"><i class="fa fa-star"></i></div>
        <div class="credit-head-info">
            <div class="cp-page-title">我的评价</div>
            <div class="cp-page-sub">
                信用分 <span style="color: #FFEE00; font-weight: 700;"><%= currentUser.getCreditScore() == null ? 100 : currentUser.getCreditScore() %></span>
                &middot; 共 {{ total }} 条评价
            </div>
        </div>
        <div class="credit-head-actions">
            <a href="<%=ctx%>/user?action=center" class="cp-btn-outline">
                <i class="fa fa-arrow-left"></i> 返回个人中心
            </a>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- 收到的评价统计（仅 received tab 显示） -->
    <div v-if="type === 'received'" class="stat-card">
        <div class="stat-card-icon"><i class="fa fa-star"></i></div>
        <div class="stat-card-body">
            <div class="stat-card-title">我的平均评分</div>
            <div class="stat-card-value">
                <%= String.format("%.1f", statAvg) %>
                <small>/ 5.0</small>
            </div>
            <div class="stat-card-sub">基于 <%= statCount %> 条收到的评价</div>
        </div>
        <div class="stat-card-icon" style="background: #000; color: #00f0ff; border-color: #00f0ff;">
            <i class="fa fa-thumbs-up"></i>
        </div>
    </div>

    <!-- tab 切换 -->
    <div class="cp-tabs">
        <a href="<%=ctx%>/credit?action=list&type=received" class="cp-tab <%= "received".equals(type) ? "active" : "" %>">
            <i class="fa fa-inbox"></i> 收到的评价
        </a>
        <a href="<%=ctx%>/credit?action=list&type=sent" class="cp-tab <%= "sent".equals(type) ? "active" : "" %>">
            <i class="fa fa-paper-plane"></i> 我发出的
        </a>
        <a href="<%=ctx%>/credit?action=list&type=all" class="cp-tab <%= "all".equals(type) ? "active" : "" %>">
            <i class="fa fa-list"></i> 全部
        </a>
    </div>

    <!-- 评价列表 -->
    <div v-if="rows.length > 0" class="credit-list">
        <div v-for="r in rows" :key="r.id" class="credit-card">
            <div class="credit-cover" :style="r.coverImage ? 'background-image:url(' + r.coverImage + '); background-size:cover; background-position:center;' : ''">
                <i v-if="!r.coverImage" class="fa fa-image"></i>
            </div>
            <div class="credit-body">
                <div class="credit-line-1">
                    <span class="username">{{ type === 'sent' ? r.targetUsername : r.evaluatorUsername }}</span>
                    <span class="role-tag">{{ r.roleText }}</span>
                    <span class="sep">&middot;</span>
                    <span>订单号 {{ r.orderNo }}</span>
                </div>
                <div class="credit-line-2">
                    <span class="credit-stars">
                        <i v-for="i in 5" :key="i" :class="['fa', 'fa-star', i <= r.score ? 'on' : '']"></i>
                    </span>
                    <a :href="ctxPath + '/item?action=detail&id=' + r.itemId" class="item-link">
                        &laquo;{{ r.itemTitle || '(已删除)' }}&raquo;
                    </a>
                </div>
                <div v-if="r.content" class="credit-content">{{ r.content }}</div>
                <div v-else class="credit-content" style="color: #555; font-style: italic;">
                    （评价人没有填写内容）
                </div>
            </div>
            <div class="credit-time">
                {{ formatTime(r.createTime) }}
                <span class="ago">{{ formatAgo(r.createTime) }}</span>
            </div>
        </div>
    </div>

    <!-- 空状态 -->
    <div v-else class="empty-state">
        <i class="fa fa-star-o"></i>
        <p v-if="type === 'received'">还没有收到评价</p>
        <p v-else-if="type === 'sent'">还没有发出过评价</p>
        <p v-else>暂无评价记录</p>
        <p style="margin-top: 12px;">
            <a href="<%=ctx%>/order?action=list">去查看我的订单 →</a>
        </p>
    </div>

    <!-- 分页 -->
    <div v-if="totalPages > 1" class="pager">
        <a v-if="pageNo > 1" :href="pageHref(pageNo - 1)">‹ 上一页</a>
        <span v-else class="disabled">‹ 上一页</span>

        <span v-for="p in pagesToShow" :key="p" :class="p === pageNo ? 'active' : ''">
            <a v-if="p !== pageNo" :href="pageHref(p)">{{ p }}</a>
            <span v-else>{{ p }}</span>
        </span>

        <a v-if="pageNo < totalPages" :href="pageHref(pageNo + 1)">下一页 ›</a>
        <span v-else class="disabled">下一页 ›</span>
    </div>

</div>

<footer class="credit-footer">
    <div class="credit-footer-inner">
        &copy; 2025 二手物品拍卖系统 &middot; Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath  = '<%=ctx%>';
    const rowsInit = <%= rowsJson %>;
    const total    = <%= total %>;
    const pageNoInit = <%= pageNo %>;
    const totalPages = <%= totalPages %>;
    const typeInit = '<%= type %>';

    loadVue().then(() => {
        const { createApp, ref, computed } = Vue;
        createApp({
            setup() {
                const rows = ref(rowsInit);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);
                const type = ref(typeInit);

                const pagesToShow = computed(() => {
                    const total = totalPagesRef.value;
                    const cur = pageNoRef.value;
                    const arr = [];
                    const start = Math.max(1, cur - 2);
                    const end = Math.min(total, cur + 2);
                    for (let i = start; i <= end; i++) arr.push(i);
                    return arr;
                });

                function pageHref(p) {
                    return ctxPath + '/credit?action=list&type=' + type.value + '&page=' + p;
                }
                function formatTime(dt) {
                    if (!dt) return '-';
                    const d = new Date(dt);
                    if (isNaN(d)) return dt;
                    const pad = n => String(n).padStart(2, '0');
                    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
                }
                function formatAgo(dt) {
                    if (!dt) return '';
                    const d = new Date(dt);
                    if (isNaN(d)) return '';
                    const diff = Date.now() - d.getTime();
                    const min = Math.floor(diff / 60000);
                    if (min < 1) return '刚刚';
                    if (min < 60) return min + ' 分钟前';
                    const hr = Math.floor(min / 60);
                    if (hr < 24) return hr + ' 小时前';
                    const day = Math.floor(hr / 24);
                    if (day < 30) return day + ' 天前';
                    const mon = Math.floor(day / 30);
                    if (mon < 12) return mon + ' 月前';
                    return Math.floor(mon / 12) + ' 年前';
                }
                return { rows, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef,
                         type, pagesToShow, pageHref, formatTime, formatAgo };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
