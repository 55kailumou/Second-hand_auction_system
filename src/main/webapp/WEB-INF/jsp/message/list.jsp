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

    String messagesJson = (String) request.getAttribute("messagesJson");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("pageNo");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer isReadFilter = (Integer) request.getAttribute("isReadFilter");
    Integer unreadCount = (Integer) request.getAttribute("unreadCount");
    String error = (String) request.getAttribute("error");
    if (messagesJson == null) messagesJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (unreadCount == null) unreadCount = 0;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>消息中心 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * Cyberpunk 2077 · 消息中心
         * - Dark neon theme #000 / #FFEE00 / #00FFFF / #FF00FF
         * - Clip-path polygons, monospace fonts, scanline overlay
         * ============================================================ */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { height: 100%; }
        body {
            background: #000;
            color: #FFEE00;
            font-family: 'Courier New', 'Consolas', 'Share Tech Mono', monospace;
            font-size: 14px;
            line-height: 1.6;
            position: relative;
            overflow-x: hidden;
        }
        body::before {
            content: '';
            position: fixed;
            inset: 0;
            background: repeating-linear-gradient(
                0deg,
                rgba(0,255,255,0.03) 0px,
                rgba(0,255,255,0.03) 1px,
                transparent 1px,
                transparent 3px
            );
            pointer-events: none;
            z-index: 9999;
        }
        a { color: #00FFFF; text-decoration: none; transition: color 0.2s; }
        a:hover { color: #FF00FF; text-shadow: 0 0 8px #FF00FF; }
        ::-webkit-scrollbar { width: 8px; background: #0a0a0a; }
        ::-webkit-scrollbar-thumb { background: #FFEE00; border-radius: 0; }

        /* ---------- Navigation ---------- */

        .cp-logo .logo-icon {
            width: 30px;
            height: 30px;
            background: #FFEE00;
            color: #000;
            display: grid;
            place-items: center;
            font-size: 14px;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
        }

        .cp-nav-search button:hover {
            background: #00FFFF;
            color: #000;
        }

        .cp-nav-user .user-name-link {
            color: #FFEE00;
            font-weight: 600;
        }
        .cp-nav-user .user-name-link:hover {
            color: #00FFFF;
            text-shadow: 0 0 8px #00FFFF;
        }

        /* ---------- Container ---------- */
        .cp-container {
            max-width: 1200px;
            margin: 12px auto 0;
            padding: 0 16px 60px;
        }

        /* ---------- Head ---------- */
        .msg-head {
            background: #0d0d0d;
            border: 1px solid #FFEE00;
            clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
            padding: 20px 24px;
            display: flex;
            align-items: center;
            gap: 16px;
        }
        .msg-head-icon {
            width: 48px;
            height: 48px;
            background: #111;
            border: 1px solid #00FFFF;
            color: #00FFFF;
            display: grid;
            place-items: center;
            font-size: 22px;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
            position: relative;
        }
        .cp-badge-red {
            position: absolute;
            top: -6px;
            right: -6px;
            min-width: 20px;
            height: 20px;
            padding: 0 6px;
            background: #FF00FF;
            color: #000;
            border: 1px solid #FF00FF;
            font-size: 10px;
            font-weight: 700;
            display: grid;
            place-items: center;
            clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%);
        }
        .msg-head-info { flex: 1; min-width: 0; }
        .msg-head-title {
            font-size: 18px;
            font-weight: 700;
            color: #00FFFF;
            text-shadow: 0 0 6px #00FFFF;
            margin-bottom: 4px;
        }
        .msg-head-sub { font-size: 12px; color: #666; }
        .msg-head-actions { display: flex; gap: 8px; }

        /* ---------- Buttons ---------- */
        .cp-btn {
            padding: 8px 16px;
            background: transparent;
            color: #FFEE00;
            border: 1px solid #FFEE00;
            clip-path: polygon(6px 0, 100% 0, calc(100% - 6px) 100%, 0 100%);
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: all 0.15s;
            cursor: pointer;
            font-family: inherit;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .cp-btn:hover {
            background: #FFEE00;
            color: #000;
            box-shadow: 0 0 12px #FFEE00;
        }
        .cp-btn:disabled {
            opacity: 0.4;
            cursor: not-allowed;
        }
        .cp-btn-sm {
            padding: 5px 10px;
            font-size: 11px;
        }
        .cp-btn-outline {
            background: transparent;
            border: 1px solid #00FFFF;
            color: #00FFFF;
        }
        .cp-btn-outline:hover {
            background: #00FFFF;
            color: #000;
            box-shadow: 0 0 12px #00FFFF;
        }

        /* ---------- Alert ---------- */
        .alert {
            padding: 10px 16px;
            margin-top: 12px;
            font-size: 13px;
            border: 1px solid;
        }
        .alert-warning {
            background: #1a0a00;
            color: #FF8800;
            border-color: #FF8800;
        }

        /* ---------- Tabs ---------- */
        .cp-tabs {
            background: #0d0d0d;
            border: 1px solid #222;
            clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
            margin-top: 12px;
            padding: 4px 20px;
            display: flex;
            align-items: center;
        }
        .cp-tab {
            padding: 12px 16px;
            font-size: 13px;
            color: #666;
            cursor: pointer;
            position: relative;
            font-weight: 600;
            text-decoration: none;
            text-transform: uppercase;
            letter-spacing: 1px;
            transition: color 0.2s;
        }
        .cp-tab:hover { color: #00FFFF; }
        .cp-tab.active {
            color: #FFEE00;
        }
        .cp-tab.active::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 50%;
            transform: translateX(-50%);
            width: 24px;
            height: 2px;
            background: #FFEE00;
            box-shadow: 0 0 8px #FFEE00;
        }
        .cp-tab .count {
            margin-left: 4px;
            font-size: 11px;
            color: #555;
        }
        .cp-tab.active .count { color: #FFEE00; }

        /* ---------- Message List ---------- */
        .msg-list {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-top: 12px;
        }
        .cp-list-item {
            background: #0d0d0d;
            border: 1px solid #222;
            clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%);
            padding: 16px 20px;
            display: grid;
            grid-template-columns: 48px 1fr auto;
            gap: 14px;
            align-items: start;
            cursor: pointer;
            transition: all 0.2s;
            position: relative;
        }
        .cp-list-item:hover {
            border-color: #00FFFF;
            box-shadow: 0 0 10px rgba(0,255,255,0.1);
        }
        .cp-list-item.unread {
            border-color: #FFEE00;
            background: #111;
        }
        .cp-list-item.unread::before {
            content: '';
            position: absolute;
            left: 0;
            top: 0;
            bottom: 0;
            width: 3px;
            background: #FFEE00;
            box-shadow: 0 0 8px #FFEE00;
        }
        .msg-icon {
            width: 48px;
            height: 48px;
            display: grid;
            place-items: center;
            font-size: 22px;
            color: #fff;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
        }
        .msg-body { min-width: 0; }
        .msg-line-1 {
            display: flex;
            align-items: center;
            gap: 8px;
            flex-wrap: wrap;
            margin-bottom: 4px;
        }
        .msg-type-tag {
            font-size: 10px;
            padding: 1px 8px;
            background: #1a1a1a;
            color: #666;
            border: 1px solid #333;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .cp-list-item.unread .msg-type-tag {
            background: #1a1a00;
            border-color: #FFEE00;
            color: #FFEE00;
        }
        .msg-title {
            font-size: 14px;
            font-weight: 600;
            color: #ccc;
        }
        .cp-list-item.unread .msg-title {
            color: #FFEE00;
            font-weight: 700;
        }
        .msg-content {
            font-size: 13px;
            color: #777;
            line-height: 1.5;
            word-break: break-all;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .msg-time {
            font-size: 12px;
            color: #444;
            text-align: right;
            white-space: nowrap;
        }
        .msg-time .ago { display: block; margin-top: 2px; }
        .msg-actions { display: flex; gap: 6px; margin-top: 8px; }

        /* ---------- Empty State ---------- */
        .cp-empty {
            background: #0d0d0d;
            border: 1px solid #333;
            clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
            margin-top: 12px;
            text-align: center;
            padding: 80px 20px;
            color: #555;
            font-size: 13px;
        }
        .cp-empty i {
            font-size: 48px;
            color: #333;
            margin-bottom: 12px;
            display: block;
        }

        /* ---------- Pagination ---------- */
        .pager {
            margin-top: 16px;
            display: flex;
            justify-content: center;
            gap: 6px;
        }
        .pager a, .pager span {
            padding: 6px 12px;
            border: 1px solid #333;
            font-size: 13px;
            color: #888;
            text-decoration: none;
            min-width: 32px;
            text-align: center;
            background: #0d0d0d;
            transition: all 0.15s;
            font-family: inherit;
        }
        .pager a:hover {
            border-color: #00FFFF;
            color: #00FFFF;
        }
        .pager .active {
            background: #FFEE00;
            color: #000;
            border-color: #FFEE00;
            font-weight: 700;
        }
        .pager .disabled {
            color: #333;
            cursor: not-allowed;
            background: #050505;
        }

        /* ---------- Modal ---------- */
        .cp-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.85);
            z-index: 1000;
            display: none;
            align-items: center;
            justify-content: center;
            backdrop-filter: blur(4px);
        }
        .cp-modal-overlay.show { display: flex; }
        .cp-modal {
            background: #0d0d0d;
            border: 2px solid #FFEE00;
            clip-path: polygon(14px 0, 100% 0, calc(100% - 14px) 100%, 0 100%);
            padding: 28px;
            width: 90%;
            max-width: 480px;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow: 0 0 30px rgba(255,238,0,0.15);
        }
        .cp-modal-header {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 16px;
        }
        .modal-icon {
            width: 48px;
            height: 48px;
            display: grid;
            place-items: center;
            font-size: 22px;
            color: #fff;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
        }
        .cp-modal-title-body { flex: 1; min-width: 0; }
        .cp-modal-title {
            font-size: 16px;
            font-weight: 700;
            color: #00FFFF;
            text-shadow: 0 0 6px #00FFFF;
            margin-bottom: 4px;
        }
        .modal-time { font-size: 12px; color: #555; }
        .modal-content-body {
            font-size: 14px;
            line-height: 1.7;
            color: #ccc;
            white-space: pre-wrap;
            word-break: break-all;
            background: #0a0a0a;
            border: 1px solid #222;
            padding: 14px 16px;
            margin-bottom: 16px;
        }
        .modal-actions {
            display: flex;
            gap: 8px;
        }
        .modal-actions a, .modal-actions button {
            flex: 1;
            padding: 10px;
            font-size: 12px;
            font-weight: 600;
            text-align: center;
            text-decoration: none;
            cursor: pointer;
            font-family: inherit;
        }
        .modal-actions .cp-btn {
            justify-content: center;
        }

        /* ---------- Footer ---------- */
        .msg-footer {
            background: #050505;
            border-top: 1px solid #FFEE00;
            margin-top: 32px;
            padding: 32px 16px 16px;
            text-align: center;
            font-size: 12px;
        }
        .msg-footer-inner {
            max-width: 1200px;
            margin: 0 auto;
            color: #444;
        }

        [v-cloak] { display: none; }
    </style>
</head>
<body>

<!-- Scanline overlay -->
<div class="scanline" style="position:fixed;inset:0;pointer-events:none;z-index:9999;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,255,0.02) 2px,rgba(0,255,255,0.02) 4px);"></div>

<!-- ========== Navigation ========== -->
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
            <a href="<%=ctx%>/message?action=list" class="active">消息中心</a>
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

<div class="cp-container" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="msg-head">
        <div class="msg-head-icon">
            <i class="fa fa-envelope"></i>
            <% if (unreadCount > 0) { %>
                <span class="cp-badge-red"><%= unreadCount > 99 ? "99+" : unreadCount %></span>
            <% } %>
        </div>
        <div class="msg-head-info">
            <div class="msg-head-title">> 消息中心</div>
            <div class="msg-head-sub">共 {{ total }} 条 · 未读 <span style="color: #FF00FF; font-weight: 600;">{{ unreadCount }}</span> 条</div>
        </div>
        <div class="msg-head-actions">
            <button class="cp-btn cp-btn-sm" @click="markAllRead" :disabled="unreadCount === 0">
                <i class="fa fa-check-circle"></i> 全部已读
            </button>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- Tabs -->
    <div class="cp-tabs">
        <a href="<%=ctx%>/message?action=list" class="cp-tab <%= isReadFilter == null ? "active" : "" %>">
            全部 <span class="count">(<%= total %>)</span>
        </a>
        <a href="<%=ctx%>/message?action=list&isRead=0" class="cp-tab <%= isReadFilter != null && isReadFilter == 0 ? "active" : "" %>">
            未读 <span class="count">(<%= unreadCount %>)</span>
        </a>
        <a href="<%=ctx%>/message?action=list&isRead=1" class="cp-tab <%= isReadFilter != null && isReadFilter == 1 ? "active" : "" %>">
            已读
        </a>
    </div>

    <!-- 消息列表 -->
    <div v-if="messages.length > 0" class="msg-list">
        <div v-for="m in messages" :key="m.id"
             :class="['cp-list-item', { unread: m.isRead === 0 }]"
             @click="openMsg(m)">
            <div class="msg-icon" :style="'background:' + m.typeColor">
                <i :class="['fa', m.typeIcon]"></i>
            </div>
            <div class="msg-body">
                <div class="msg-line-1">
                    <span class="msg-type-tag">{{ m.typeText }}</span>
                    <span class="msg-title">{{ m.title }}</span>
                </div>
                <div class="msg-content">{{ m.content }}</div>
            </div>
            <div class="msg-time">
                {{ formatTime(m.createTime) }}
                <span class="ago">{{ formatAgo(m.createTime) }}</span>
            </div>
        </div>
    </div>

    <!-- 空状态 -->
    <div v-else class="cp-empty">
        <i class="fa fa-inbox"></i>
        <p v-if="isReadFilter === 0">没有未读消息</p>
        <p v-else-if="isReadFilter === 1">没有已读消息</p>
        <p v-else>暂无消息，去拍个喜欢的商品试试？</p>
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

    <!-- 弹窗（消息详情） -->
    <div :class="['cp-modal-overlay', { show: modalOpen }]" @click.self="closeModal">
        <div class="cp-modal" v-if="currentMsg">
            <div class="cp-modal-header">
                <div class="modal-icon" :style="'background:' + currentMsg.typeColor">
                    <i :class="['fa', currentMsg.typeIcon]"></i>
                </div>
                <div class="cp-modal-title-body">
                    <div class="cp-modal-title">{{ currentMsg.title }}</div>
                    <div class="modal-time">{{ currentMsg.typeText }} · {{ formatTime(currentMsg.createTime) }}</div>
                </div>
                <button class="cp-modal-close" @click="closeModal" style="margin-left:auto;background:none;border:1px solid #555;color:#555;font-size:18px;cursor:pointer;width:30px;height:30px;display:grid;place-items:center;font-family:inherit;">&times;</button>
            </div>
            <div class="modal-content-body">{{ currentMsg.content }}</div>
            <div class="modal-actions">
                <button class="cp-btn cp-btn-outline cp-btn-sm" @click="removeMsg(currentMsg)">
                    <i class="fa fa-trash-o"></i> 删除
                </button>
                <a v-if="relatedUrl(currentMsg)" :href="relatedUrl(currentMsg)" class="cp-btn cp-btn-sm">
                    <i class="fa fa-external-link"></i> 查看详情
                </a>
                <button v-else class="cp-btn cp-btn-sm" @click="closeModal">关闭</button>
            </div>
        </div>
    </div>

</div>

<!-- 页脚 -->
<footer class="msg-footer">
    <div class="msg-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath       = '<%=ctx%>';
    const messagesInit  = <%= messagesJson %>;
    const total         = <%= total %>;
    const pageNoInit    = <%= pageNo %>;
    const totalPages    = <%= totalPages %>;
    const isReadFilter  = <%= isReadFilter == null ? "null" : isReadFilter %>;
    const unreadCountInit = <%= unreadCount %>;

    loadVue().then(() => {
        const { createApp, ref, computed } = Vue;
        createApp({
            setup() {
                const messages = ref(messagesInit);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);
                const isReadFilterRef = ref(isReadFilter);
                const unreadCount = ref(unreadCountInit);

                const modalOpen = ref(false);
                const currentMsg = ref(null);

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
                    params.set('page', p);
                    if (isReadFilterRef.value !== null) params.set('isRead', isReadFilterRef.value);
                    return ctxPath + '/message?' + params.toString();
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

                // 根据 type + relatedId 计算跳转链接
                function relatedUrl(m) {
                    if (!m.relatedId) return null;
                    switch (m.type) {
                        case 1: case 5:   // 中标 / 订单状态 → 订单详情（这里 relatedId 是 orderId，需要 orderNo）
                            // 实际中 relatedId 存的是 order.id，前端暂时用订单列表兜底
                            return ctxPath + '/order?action=list';
                        case 2:           // 出价被超 → 拍品详情（这里 relatedId 实际是 itemId）
                            return ctxPath + '/item?action=detail&id=' + m.relatedId;
                        case 6:           // 审核结果 → 我的退款列表（用订单列表兜底）
                            return ctxPath + '/order?action=list';
                        default:
                            return null;
                    }
                }

                function openMsg(m) {
                    currentMsg.value = m;
                    modalOpen.value = true;
                    // 未读消息点击后自动标记为已读
                    if (m.isRead === 0) {
                        loadAxios().then(() => {
                            axios.post(ctxPath + '/message?action=mark-read', null, {
                                params: { id: m.id }
                            }).then(r => {
                                if (r.data.success && r.data.updated > 0) {
                                    m.isRead = 1;
                                    unreadCount.value = Math.max(0, unreadCount.value - 1);
                                }
                            });
                        });
                    }
                }
                function closeModal() {
                    modalOpen.value = false;
                }
                function markAllRead() {
                    if (unreadCount.value === 0) return;
                    if (!confirm('将所有未读消息标记为已读？')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/message?action=mark-all-read', null, {})
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '已全部标记为已读', 'success');
                                    setTimeout(() => location.reload(), 500);
                                } else {
                                    toast(r.data.message || '操作失败', 'error');
                                }
                            })
                            .catch(() => toast('网络错误', 'error'));
                    });
                }
                function removeMsg(m) {
                    if (!confirm('确定删除这条消息？')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/message?action=remove', null, {
                            params: { id: m.id }
                        }).then(r => {
                            if (r.data.success) {
                                toast('已删除', 'success');
                                closeModal();
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '删除失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                return { messages, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef,
                         isReadFilter: isReadFilterRef, unreadCount,
                         modalOpen, currentMsg, pagesToShow, pageHref, formatTime, formatAgo,
                         relatedUrl, openMsg, closeModal, markAllRead, removeMsg };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
