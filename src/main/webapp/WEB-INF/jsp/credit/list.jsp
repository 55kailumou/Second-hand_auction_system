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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 我的评价 v1 · 仿闲鱼 v2
         * - 顶 nav 统一
         * - 标题栏 + 统计卡
         * - tab 切换（收到的 / 发出的 / 全部）
         * - 评价列表（每条含对方 + 拍品 + 星级 + 内容 + 时间）
         * ============================================================ */
        body { background: #f5f5f5; }

        /* ---------- 顶 nav（与 favorite/address/center 一致） ---------- */
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
        .nav a.active::after { content: ''; position: absolute;
            bottom: 8px; left: 4px; right: 4px;
            height: 2px; background: var(--color-primary); border-radius: 2px; }
        .nav-search { flex: 0 1 380px; display: flex; background: #fff7ed;
                      border: 2px solid var(--color-primary);
                      border-radius: 20px; overflow: hidden; height: 36px; }
        .nav-search input { flex: 1; padding: 0 14px; border: none; outline: none;
                            background: transparent; font-size: 13px; color: var(--color-text); }
        .nav-search input::placeholder { color: #9ca3af; }
        .nav-search button { background: var(--color-primary); color: #fff;
                            font-size: 13px; font-weight: 600; padding: 0 18px;
                            display: flex; align-items: center; gap: 5px; }
        .nav-search button:hover { background: var(--color-primary-hover); }
        .user-info { display: flex; align-items: center; gap: 8px; font-size: 14px; flex-shrink: 0; margin-left: auto; }
        .user-info .avatar { width: 32px; height: 32px; border-radius: 50%;
            background: linear-gradient(135deg, var(--color-primary), #ffaa80);
            color: #fff; display: grid; place-items: center;
            font-size: 13px; font-weight: 600; }
        .user-name-link { color: var(--color-text); font-weight: 500; }

        /* ---------- 主体 ---------- */
        .credit-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        /* 标题栏 */
        .credit-head { background: #fff; border-radius: 8px;
                       box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       padding: 20px 24px;
                       display: flex; align-items: center; gap: 16px; }
        .credit-head-icon { width: 48px; height: 48px; border-radius: 8px;
                           background: #fef3c7; color: #b45309;
                           display: grid; place-items: center; font-size: 22px; }
        .credit-head-info { flex: 1; min-width: 0; }
        .credit-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .credit-head-sub { font-size: 12px; color: var(--color-muted); }
        .credit-head-actions a { padding: 8px 16px; background: #fff; color: var(--color-text);
                                 border: 1px solid var(--color-border); border-radius: 6px;
                                 font-size: 13px; text-decoration: none;
                                 display: flex; align-items: center; gap: 5px; transition: all 0.15s; }
        .credit-head-actions a:hover { border-color: var(--color-primary); color: var(--color-primary); }

        /* 错误条 */
        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        /* 统计卡（仅 received 时显示） */
        .stat-card { background: linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%);
                     border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     margin-top: 12px; padding: 20px 24px;
                     display: flex; align-items: center; gap: 24px; }
        .stat-card-icon { width: 64px; height: 64px; border-radius: 50%;
                          background: #fff; color: #f59e0b;
                          display: grid; place-items: center; font-size: 30px;
                          box-shadow: 0 2px 8px rgba(245,158,11,0.2); }
        .stat-card-body { flex: 1; }
        .stat-card-title { font-size: 13px; color: #92400e; margin-bottom: 4px; font-weight: 500; }
        .stat-card-value { font-size: 36px; font-weight: 800; color: #b45309; line-height: 1.1;
                           display: flex; align-items: baseline; gap: 8px; }
        .stat-card-value small { font-size: 18px; font-weight: 600; color: #d97706; }
        .stat-card-sub { font-size: 12px; color: #92400e; margin-top: 4px; }

        /* tab */
        .filter-bar { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                      margin-top: 12px; padding: 4px 20px;
                      display: flex; align-items: center; }
        .filter-tab { padding: 12px 16px; font-size: 14px; color: var(--color-text-sub);
                      cursor: pointer; position: relative; font-weight: 500;
                      text-decoration: none; }
        .filter-tab:hover { color: var(--color-primary); }
        .filter-tab.active { color: var(--color-primary); font-weight: 600; }
        .filter-tab.active::after { content: ''; position: absolute;
                                    bottom: 0; left: 50%; transform: translateX(-50%);
                                    width: 24px; height: 2px; background: var(--color-primary);
                                    border-radius: 2px; }
        .filter-tab .count { margin-left: 4px; font-size: 12px; color: var(--color-muted); }

        /* 评价列表 */
        .credit-list { display: flex; flex-direction: column; gap: 10px; margin-top: 12px; }
        .credit-card { background: #fff; border-radius: 8px;
                       box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       padding: 16px 20px; display: grid;
                       grid-template-columns: 60px 1fr auto; gap: 14px;
                       align-items: start; }
        .credit-cover { width: 60px; height: 60px; border-radius: 4px;
                        background: #f3f4f6; display: grid; place-items: center;
                        color: #9ca3af; overflow: hidden; flex-shrink: 0; }
        .credit-cover img { width: 100%; height: 100%; object-fit: cover; }
        .credit-body { min-width: 0; }
        .credit-line-1 { display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
                         font-size: 13px; color: var(--color-text-sub); margin-bottom: 6px; }
        .credit-line-1 .username { font-weight: 600; color: var(--color-text); }
        .credit-line-1 .sep { color: #e5e7eb; }
        .credit-line-1 .role-tag { padding: 1px 6px; font-size: 11px;
                                   background: var(--color-primary-light); color: var(--color-primary);
                                   border-radius: 2px; }
        .credit-line-2 { display: flex; align-items: center; gap: 6px;
                         font-size: 13px; color: var(--color-text); margin-bottom: 6px; }
        .credit-line-2 .item-link { color: var(--color-text); text-decoration: none; }
        .credit-line-2 .item-link:hover { color: var(--color-primary); }
        .credit-stars { display: flex; gap: 1px; }
        .credit-stars i { font-size: 14px; color: #e5e7eb; }
        .credit-stars i.on { color: #f59e0b; }
        .credit-content { font-size: 13px; line-height: 1.6; color: var(--color-text);
                          background: var(--color-bg); padding: 10px 12px;
                          border-radius: 4px; border-left: 3px solid #fed7aa;
                          margin-top: 6px; word-break: break-all; white-space: pre-wrap; }
        .credit-time { font-size: 12px; color: var(--color-placeholder); text-align: right;
                       white-space: nowrap; }
        .credit-time .ago { display: block; margin-top: 2px; }

        /* 空状态 */
        .empty-state { background: #fff; border-radius: 8px;
                       box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 12px;
                       text-align: center; padding: 80px 20px;
                       color: var(--color-muted); font-size: 13px; }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }
        .empty-state a { color: var(--color-primary); text-decoration: none; font-weight: 600; }
        .empty-state a:hover { text-decoration: underline; }

        /* 分页 */
        .pager { margin-top: 16px; display: flex; justify-content: center; gap: 6px; }
        .pager a, .pager span { padding: 6px 12px; border: 1px solid var(--color-border);
                                border-radius: 4px; font-size: 13px; color: var(--color-text-sub);
                                text-decoration: none; min-width: 32px; text-align: center;
                                background: #fff; }
        .pager a:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .pager .active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .pager .disabled { color: var(--color-placeholder); cursor: not-allowed; background: var(--color-bg); }

        /* 页脚 */
        .credit-footer { background: #1f2937; color: #d1d5db;
                         margin-top: 32px; padding: 32px 16px 16px;
                         text-align: center; font-size: 12px; }
        .credit-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }

        [v-cloak] { display: none; }
    </style>
</head>
<body>

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
            <a href="<%=ctx%>/user?action=center">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="user-info">
            <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= currentUser.getUsername() %></a>
            <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: var(--color-muted);">退出</a>
            <a href="<%=ctx%>/user?action=center" class="avatar">
                <%= currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()
                    ? currentUser.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </a>
        </div>
    </div>
</header>

<div class="credit-wrap" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="credit-head">
        <div class="credit-head-icon"><i class="fa fa-star"></i></div>
        <div class="credit-head-info">
            <div class="credit-head-title">我的评价</div>
            <div class="credit-head-sub">
                信用分 <span style="color: var(--color-primary); font-weight: 600;"><%= currentUser.getCreditScore() == null ? 100 : currentUser.getCreditScore() %></span>
                · 共 {{ total }} 条评价
            </div>
        </div>
        <div class="credit-head-actions">
            <a href="<%=ctx%>/user?action=center">
                <i class="fa fa-arrow-left"></i> 返回个人中心
            </a>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
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
        <div class="stat-card-icon" style="background: #fff; color: #10b981;">
            <i class="fa fa-thumbs-up"></i>
        </div>
    </div>

    <!-- tab 切换 -->
    <div class="filter-bar">
        <a href="<%=ctx%>/credit?action=list&type=received" class="filter-tab <%= "received".equals(type) ? "active" : "" %>">
            <i class="fa fa-inbox"></i> 收到的评价
        </a>
        <a href="<%=ctx%>/credit?action=list&type=sent" class="filter-tab <%= "sent".equals(type) ? "active" : "" %>">
            <i class="fa fa-paper-plane"></i> 我发出的
        </a>
        <a href="<%=ctx%>/credit?action=list&type=all" class="filter-tab <%= "all".equals(type) ? "active" : "" %>">
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
                    <span class="sep">·</span>
                    <span>订单号 {{ r.orderNo }}</span>
                </div>
                <div class="credit-line-2">
                    <span class="credit-stars">
                        <i v-for="i in 5" :key="i" :class="['fa', 'fa-star', i <= r.score ? 'on' : '']"></i>
                    </span>
                    <a :href="ctxPath + '/item?action=detail&id=' + r.itemId" class="item-link">
                        《{{ r.itemTitle || '(已删除)' }}》
                    </a>
                </div>
                <div v-if="r.content" class="credit-content">{{ r.content }}</div>
                <div v-else class="credit-content" style="color: var(--color-placeholder); font-style: italic;">
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
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
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
