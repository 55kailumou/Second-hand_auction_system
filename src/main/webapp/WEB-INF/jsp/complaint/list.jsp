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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 我的投诉 v1 · 仿闲鱼 v2
         * - 顶 nav 统一
         * - 标题栏 + tab（我发起的 / 我收到的 / 全部）+ 搜索
         * - 投诉列表（每条：状态徽章 + 订单 + 对方 + 原因 + 审核结果）
         * ============================================================ */
        body { background: #f5f5f5; }

        /* 顶 nav（与 credit/favorite/address/message 一致） */
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

        /* 主体 */
        .cpl-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        /* 标题栏 */
        .cpl-head { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                    padding: 20px 24px; display: flex; align-items: center; gap: 16px; }
        .cpl-head-icon { width: 48px; height: 48px; border-radius: 8px;
                         background: #fee2e2; color: #b91c1c;
                         display: grid; place-items: center; font-size: 22px; }
        .cpl-head-info { flex: 1; min-width: 0; }
        .cpl-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .cpl-head-sub { font-size: 12px; color: var(--color-muted); }
        .cpl-head-actions a { padding: 8px 16px; background: #fff; color: var(--color-text);
                              border: 1px solid var(--color-border); border-radius: 6px;
                              font-size: 13px; text-decoration: none;
                              display: flex; align-items: center; gap: 5px; transition: all 0.15s; }
        .cpl-head-actions a:hover { border-color: var(--color-primary); color: var(--color-primary); }

        /* 错误条 */
        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        /* tab + 搜索 */
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
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input { padding: 6px 12px; border: 1px solid var(--color-border);
                               border-radius: 4px; font-size: 13px; outline: none; width: 220px; }
        .filter-search input:focus { border-color: var(--color-primary); }
        .filter-search button { padding: 6px 14px; background: var(--color-primary); color: #fff;
                                border: none; border-radius: 4px; font-size: 13px; cursor: pointer; }
        .filter-search button:hover { background: var(--color-primary-hover); }

        /* 列表 */
        .cpl-list { display: flex; flex-direction: column; gap: 10px; margin-top: 12px; }
        .cpl-card { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                    padding: 16px 20px; display: grid;
                    grid-template-columns: 60px 1fr auto; gap: 14px;
                    align-items: start; border-left: 3px solid transparent; }
        .cpl-card.status-0 { border-left-color: #f59e0b; }   /* 待处理 */
        .cpl-card.status-2 { border-left-color: #10b981; }   /* 已处理 */
        .cpl-card.status-3 { border-left-color: #9ca3af; }   /* 已驳回 */
        .cpl-cover { width: 60px; height: 60px; border-radius: 4px;
                     background: #f3f4f6; display: grid; place-items: center;
                     color: #9ca3af; overflow: hidden; flex-shrink: 0; }
        .cpl-cover img { width: 100%; height: 100%; object-fit: cover; }
        .cpl-body { min-width: 0; }
        .cpl-line-1 { display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
                      margin-bottom: 4px; font-size: 13px; color: var(--color-text-sub); }
        .cpl-line-1 .role-tag { padding: 1px 8px; font-size: 11px;
                                background: #fef3c7; color: #b45309; border-radius: 2px; }
        .cpl-line-1 .username { font-weight: 600; color: var(--color-text); }
        .cpl-line-1 .sep { color: #e5e7eb; }
        .cpl-line-2 { font-size: 13px; color: var(--color-text); margin-bottom: 6px; }
        .cpl-reason { font-size: 13px; line-height: 1.6; color: var(--color-text);
                      background: var(--color-bg); padding: 10px 12px;
                      border-radius: 4px; margin-top: 6px; word-break: break-all;
                      white-space: pre-wrap; }
        .cpl-reason i { color: var(--color-danger); margin-right: 4px; }
        .cpl-result { background: #f0f9ff; border-left: 3px solid #3b82f6;
                      padding: 8px 12px; border-radius: 4px; font-size: 12px;
                      color: #1e40af; margin-top: 8px; line-height: 1.5; }
        .cpl-result i { color: #3b82f6; margin-right: 4px; }
        .cpl-side { text-align: right; font-size: 12px; color: var(--color-placeholder);
                    white-space: nowrap; }
        .cpl-side .badge { padding: 3px 10px; border-radius: 12px; font-weight: 500; margin-bottom: 6px;
                           display: inline-block; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-info    { background: #dbeafe; color: #1e40af; }
        .badge-success { background: #d1fae5; color: #047857; }
        .badge-gray    { background: #f3f4f6; color: #6b7280; }
        .cpl-side .time { display: block; margin-top: 4px; }

        /* 空状态 */
        .empty-state { background: #fff; border-radius: 8px;
                       box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 12px;
                       text-align: center; padding: 80px 20px;
                       color: var(--color-muted); font-size: 13px; }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }
        .empty-state a { color: var(--color-primary); text-decoration: none; font-weight: 600; }

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
        .cpl-footer { background: #1f2937; color: #d1d5db;
                      margin-top: 32px; padding: 32px 16px 16px;
                      text-align: center; font-size: 12px; }
        .cpl-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }

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
            <a href="<%=ctx%>/message?action=list">消息中心</a>
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

<div class="cpl-wrap" id="app" v-cloak>

    <div class="cpl-head">
        <div class="cpl-head-icon"><i class="fa fa-flag"></i></div>
        <div class="cpl-head-info">
            <div class="cpl-head-title">我的投诉</div>
            <div class="cpl-head-sub">共 {{ total }} 条 · 投诉提交后由管理员在 1-3 个工作日内处理</div>
        </div>
        <div class="cpl-head-actions">
            <a href="<%=ctx%>/order?action=list">
                <i class="fa fa-list-alt"></i> 前往订单发起投诉
            </a>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <div class="filter-bar">
        <a href="<%=ctx%>/complaint?action=list&role=complainant" class="filter-tab <%= "complainant".equals(role) ? "active" : "" %>">
            <i class="fa fa-paper-plane"></i> 我发起的
        </a>
        <a href="<%=ctx%>/complaint?action=list&role=respondent" class="filter-tab <%= "respondent".equals(role) ? "active" : "" %>">
            <i class="fa fa-inbox"></i> 收到的（被投诉）
        </a>
        <a href="<%=ctx%>/complaint?action=list&role=all" class="filter-tab <%= "all".equals(role) ? "active" : "" %>">
            <i class="fa fa-list"></i> 全部
        </a>
        <form class="filter-search" method="get" action="<%=ctx%>/complaint">
            <input type="hidden" name="action" value="list">
            <input type="hidden" name="role" value="<%= role %>">
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索投诉原因">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
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
                        <span class="role-tag" style="background: #fee2e2; color: #b91c1c;">被投诉</span>
                        <span class="username">用户&#35;{{ c.complainantId }}</span>
                    </span>
                    <span v-else>
                        <span class="role-tag" style="background: #f3f4f6; color: #6b7280;">双向</span>
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
                <span :class="['badge', 'badge-' + statusBadgeClass(c.status)]">{{ c.statusText }}</span>
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
                        case 0: return 'warning';
                        case 1: return 'info';
                        case 2: return 'success';
                        case 3: return 'gray';
                        default: return 'gray';
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
