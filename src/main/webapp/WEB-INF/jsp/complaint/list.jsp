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
    String role = (String) request.getAttribute("role");
    Integer statusFilter = (Integer) request.getAttribute("statusFilter");
    String keyword = (String) request.getAttribute("keyword");
    String error = (String) request.getAttribute("error");
    if (rowsJson == null) rowsJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (role == null) role = "complainant";
    if (keyword == null) keyword = "";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我的投诉 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * Cyberpunk 2077 — 我的投诉
         * 黑色背景 / #FFEE00 霓虹黄 / 单色字体 / clip-path 多边形
         * ============================================================ */
        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            background: #000;
            color: #FFEE00;
            font-family: 'Courier New', Consolas, 'Source Code Pro', monospace;
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
        .cpl-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        .cp-page-head {
            background: #0a0a0a;
            border: 1px solid #FFEE00;
            clip-path: polygon(12px 0, 100% 0, 100% 100%, 0 100%, 0 12px);
            padding: 20px 24px;
            display: flex; align-items: center; gap: 16px;
        }
        .cpl-head-icon {
            width: 48px; height: 48px;
            border: 2px solid #FFEE00; color: #FFEE00; background: #000;
            display: grid; place-items: center; font-size: 22px;
            clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
        }
        .cpl-head-info { flex: 1; min-width: 0; }
        .cp-page-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 1px; }
        .cp-page-sub { font-size: 12px; color: #888; font-family: 'Courier New', monospace; }
        .cpl-head-actions { }

        /* ---- Alert ---- */
        .alert {
            padding: 10px 16px; margin-top: 12px; font-size: 13px;
            border: 1px solid #FFEE00; background: #111; color: #FFEE00;
            clip-path: polygon(6px 0, 100% 0, 100% 100%, 0 100%, 0 6px);
        }

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
            text-decoration: none; font-family: 'Courier New', monospace;
        }
        .cp-tab:hover { color: #FFEE00; }
        .cp-tab.active { color: #FFEE00; font-weight: 700; }
        .cp-tab.active::after {
            content: ''; position: absolute;
            bottom: 0; left: 50%; transform: translateX(-50%);
            width: 24px; height: 2px; background: #FFEE00;
            box-shadow: 0 0 8px #FFEE00;
        }
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input {
            padding: 6px 12px; border: 1px solid #333;
            background: #111; color: #FFEE00;
            font-size: 13px; outline: none; width: 220px;
            font-family: 'Courier New', monospace;
        }
        .filter-search input:focus { border-color: #FFEE00; }
        .filter-search input::placeholder { color: #555; }

        /* ---- Card list ---- */
        .cpl-list { display: flex; flex-direction: column; gap: 10px; margin-top: 12px; }
        .cpl-card {
            background: #0a0a0a;
            border: 1px solid #FFEE00;
            clip-path: polygon(10px 0, 100% 0, 100% 100%, 0 100%, 0 10px);
            padding: 16px 20px; display: grid;
            grid-template-columns: 60px 1fr auto; gap: 14px;
            align-items: start;
        }
        .cpl-card.status-0 { border-color: #FFEE00; box-shadow: 0 0 4px rgba(255,238,0,0.3); }
        .cpl-card.status-2 { border-color: #00f0ff; box-shadow: 0 0 4px rgba(0,240,255,0.3); }
        .cpl-card.status-3 { border-color: #555; }
        .cpl-cover {
            width: 60px; height: 60px;
            clip-path: polygon(6px 0, 100% 0, 100% 100%, 0 100%, 0 6px);
            background: #111; display: grid; place-items: center;
            color: #555; overflow: hidden; flex-shrink: 0;
        }
        .cpl-cover img { width: 100%; height: 100%; object-fit: cover; }
        .cpl-body { min-width: 0; }
        .cpl-line-1 {
            display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
            margin-bottom: 4px; font-size: 13px; color: #888;
        }
        .cpl-line-1 .role-tag {
            padding: 1px 8px; font-size: 11px;
            background: #222; color: #FFEE00; border: 1px solid #FFEE00;
        }
        .cpl-line-1 .username { font-weight: 600; color: #FFEE00; }
        .cpl-line-1 .sep { color: #444; }
        .cpl-line-2 { font-size: 13px; color: #aaa; margin-bottom: 6px; }
        .cpl-reason {
            font-size: 13px; line-height: 1.6; color: #ccc;
            background: #111; padding: 10px 12px;
            border-left: 3px solid #FFEE00;
            margin-top: 6px; word-break: break-all; white-space: pre-wrap;
        }
        .cpl-reason i { color: #FFEE00; margin-right: 4px; }
        .cpl-result {
            background: #0a0a2a; border-left: 3px solid #00f0ff;
            padding: 8px 12px; font-size: 12px;
            color: #00f0ff; margin-top: 8px; line-height: 1.5;
        }
        .cpl-result i { color: #00f0ff; margin-right: 4px; }
        .cpl-side { text-align: right; font-size: 12px; color: #555; white-space: nowrap; }
        .cpl-side .time { display: block; margin-top: 4px; }

        /* ---- Badges ---- */
        .cp-badge {
            padding: 3px 10px; font-weight: 600; margin-bottom: 6px;
            display: inline-block; font-size: 11px;
            font-family: 'Courier New', monospace;
            text-transform: uppercase; letter-spacing: 1px;
        }
        .cp-badge-yellow { background: #FFEE00; color: #000; }
        .cp-badge-red { background: #ff0044; color: #fff; }
        .cp-badge-cyan { background: #00f0ff; color: #000; }
        .cp-badge-dim { background: #222; color: #888; border: 1px solid #444; }

        /* ---- Buttons ---- */
        .cp-btn-sm {
            padding: 6px 14px; background: #FFEE00; color: #000;
            border: none; font-size: 13px; cursor: pointer;
            font-family: 'Courier New', monospace; font-weight: 700;
            text-transform: uppercase;
            clip-path: polygon(4px 0, 100% 0, 100% 100%, 0 100%, 0 4px);
        }
        .cp-btn-sm:hover { background: #fff; }

        .cp-btn-outline {
            padding: 8px 16px; background: transparent; color: #FFEE00;
            border: 1px solid #FFEE00; font-size: 13px; text-decoration: none;
            display: flex; align-items: center; gap: 5px;
            font-family: 'Courier New', monospace;
            clip-path: polygon(6px 0, 100% 0, 100% 100%, 0 100%, 0 6px);
            transition: all 0.15s;
        }
        .cp-btn-outline:hover { background: #FFEE00; color: #000; }

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
            font-family: 'Courier New', monospace;
        }
        .pager a:hover { border-color: #FFEE00; color: #FFEE00; }
        .pager .active { background: #FFEE00; color: #000; border-color: #FFEE00; font-weight: 700; }
        .pager .disabled { color: #444; cursor: not-allowed; background: #050505; }

        /* ---- Footer ---- */
        .cpl-footer {
            background: #050505; border-top: 1px solid #FFEE00;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .cpl-footer-inner { max-width: 1200px; margin: 0 auto; color: #555; }

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
            <a href="<%=ctx%>/message?action=list">消息中心</a>
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

<div class="cpl-wrap" id="app" v-cloak>

    <div class="cp-page-head">
        <div class="cpl-head-icon"><i class="fa fa-flag"></i></div>
        <div class="cpl-head-info">
            <div class="cp-page-title">我的投诉</div>
            <div class="cp-page-sub">共 {{ total }} 条 · 投诉提交后由管理员在 1-3 个工作日内处理</div>
        </div>
        <div class="cpl-head-actions">
            <a href="<%=ctx%>/order?action=list" class="cp-btn-outline">
                <i class="fa fa-list-alt"></i> 前往订单发起投诉
            </a>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <div class="cp-tabs">
        <a href="<%=ctx%>/complaint?action=list&role=complainant" class="cp-tab <%= "complainant".equals(role) ? "active" : "" %>">
            <i class="fa fa-paper-plane"></i> 我发起的
        </a>
        <a href="<%=ctx%>/complaint?action=list&role=respondent" class="cp-tab <%= "respondent".equals(role) ? "active" : "" %>">
            <i class="fa fa-inbox"></i> 收到的（被投诉）
        </a>
        <a href="<%=ctx%>/complaint?action=list&role=all" class="cp-tab <%= "all".equals(role) ? "active" : "" %>">
            <i class="fa fa-list"></i> 全部
        </a>
        <form class="filter-search" method="get" action="<%=ctx%>/complaint">
            <input type="hidden" name="action" value="list">
            <input type="hidden" name="role" value="<%= role %>">
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索投诉原因">
            <button type="submit" class="cp-btn-sm"><i class="fa fa-search"></i> 搜索</button>
        </form>
    </div>

    <!-- 列表 -->
    <div v-if="rows.length > 0" class="cpl-list">
        <div v-for="c in rows" :key="c.id" :class="['cpl-card', 'status-' + c.status]">
            <div class="cpl-cover" :style="c.coverImage ? 'background-image:url(' + c.coverImage + '); background-size:cover; background-position:center;' : ''">
                <i v-if="!c.coverImage" class="fa fa-image"></i>
            </div>
            <div class="cpl-body">
                <div class="cpl-line-1">
                    <span v-if="role === 'complainant'">
                        <span class="role-tag">投诉</span>
                        <span class="username">{{ c.respondentUsername }}</span>
                    </span>
                    <span v-else-if="role === 'respondent'">
                        <span class="role-tag" style="background: #330000; color: #ff0044; border-color: #ff0044;">被投诉</span>
                        <span class="username">用户&#35;{{ c.complainantId }}</span>
                    </span>
                    <span v-else>
                        <span class="role-tag" style="background: #222; color: #888; border-color: #555;">双向</span>
                    </span>
                    <span class="sep">·</span>
                    <span>订单号 <code style="font-family: 'Courier New', monospace;">{{ c.orderNo }}</code></span>
                    <span class="sep">·</span>
                    <span>{{ c.itemTitle }}</span>
                </div>
                <div class="cpl-line-2">
                    <i class="fa fa-clock-o"></i> 投诉于 {{ formatTime(c.createTime) }}
                    <span v-if="c.handleTime" style="margin-left: 12px;">
                        <i class="fa fa-check-circle"></i> 处理于 {{ formatTime(c.handleTime) }}
                    </span>
                </div>
                <div class="cpl-reason">
                    <i class="fa fa-commenting-o"></i> {{ c.reason }}
                </div>
                <div v-if="c.handleResult" class="cpl-result">
                    <i class="fa fa-info-circle"></i> 管理员处理结果：{{ c.handleResult }}
                </div>
            </div>
            <div class="cpl-side">
                <span :class="['cp-badge', 'cp-badge-' + statusBadgeClass(c.status)]">{{ c.statusText }}</span>
                <span class="time">{{ formatAgo(c.createTime) }}</span>
            </div>
        </div>
    </div>

    <div v-else class="empty-state">
        <i class="fa fa-flag-o"></i>
        <p v-if="role === 'complainant'">还没有发起过投诉</p>
        <p v-else-if="role === 'respondent'">没有被投诉过</p>
        <p v-else>暂无投诉记录</p>
        <p style="margin-top: 12px;">
            <a href="<%=ctx%>/order?action=list">前往订单管理 →</a>
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

<footer class="cpl-footer">
    <div class="cpl-footer-inner">
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
    const roleInit = '<%= role %>';

    loadVue().then(() => {
        const { createApp, ref, computed } = Vue;
        createApp({
            setup() {
                const rows = ref(rowsInit);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);
                const role = ref(roleInit);

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
                    const params = new URLSearchParams();
                    params.set('action', 'list');
                    params.set('role', role.value);
                    params.set('page', p);
                    const kw = document.querySelector('input[name="keyword"]');
                    if (kw && kw.value) params.set('keyword', kw.value);
                    return ctxPath + '/complaint?' + params.toString();
                }
                function statusBadgeClass(s) {
                    switch (s) {
                        case 0: return 'yellow';
                        case 1: return 'cyan';
                        case 2: return 'cyan';
                        case 3: return 'dim';
                        default: return 'dim';
                    }
                }
                function formatTime(dt) {
                    if (!dt) return '-';
                    const d = new Date(dt);
                    if (isNaN(d)) return dt;
                    const pad = n => String(n).padStart(2, '0');
                    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
                        ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
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
                    return Math.floor(day / 30) + ' 月前';
                }
                return { rows, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef,
                         role, pagesToShow, pageHref, statusBadgeClass, formatTime, formatAgo };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
