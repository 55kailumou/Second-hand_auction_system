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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 消息中心 v1 · 仿闲鱼 v2
         * - 顶 nav 统一
         * - 标题栏 + 未读数角标 + 全部已读
         * - tab 切换（全部 / 未读 / 已读）
         * - 消息卡（类型图标 + 标题 + 内容 + 时间 + 已读态）
         * - 弹窗详情（点击未读消息自动标已读 + 跳关联业务）
         * ============================================================ */
        body { background: #f5f5f5; }

        /* 顶 nav（与 credit/favorite/address 一致） */
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
        .msg-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        /* 标题栏 */
        .msg-head { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                    padding: 20px 24px; display: flex; align-items: center; gap: 16px; }
        .msg-head-icon { width: 48px; height: 48px; border-radius: 8px;
                         background: #dbeafe; color: #1e40af;
                         display: grid; place-items: center; font-size: 22px; position: relative; }
        .msg-head-icon .badge { position: absolute; top: -4px; right: -4px;
                                min-width: 20px; height: 20px; padding: 0 6px;
                                background: #ef4444; color: #fff; border-radius: 10px;
                                font-size: 11px; font-weight: 700;
                                display: grid; place-items: center; }
        .msg-head-info { flex: 1; min-width: 0; }
        .msg-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .msg-head-sub { font-size: 12px; color: var(--color-muted); }
        .msg-head-actions { display: flex; gap: 8px; }
        .btn-ghost { padding: 8px 16px; background: #fff; color: var(--color-text);
                     border: 1px solid var(--color-border); border-radius: 6px;
                     font-size: 13px; text-decoration: none;
                     display: flex; align-items: center; gap: 5px;
                     transition: all 0.15s; cursor: pointer; }
        .btn-ghost:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .btn-primary { padding: 8px 16px; background: var(--color-primary); color: #fff;
                       border: 1px solid var(--color-primary); border-radius: 6px;
                       font-size: 13px; font-weight: 600;
                       display: flex; align-items: center; gap: 5px;
                       transition: all 0.15s; cursor: pointer; }
        .btn-primary:hover { background: var(--color-primary-hover); border-color: var(--color-primary-hover); }
        .btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }

        /* 错误条 */
        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

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
        .filter-tab.active .count { color: var(--color-primary); }

        /* 消息列表 */
        .msg-list { display: flex; flex-direction: column; gap: 8px; margin-top: 12px; }
        .msg-card { background: #fff; border-radius: 8px;
                    box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                    padding: 16px 20px; display: grid;
                    grid-template-columns: 48px 1fr auto; gap: 14px;
                    align-items: start; cursor: pointer; transition: all 0.15s;
                    position: relative; }
        .msg-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.06); transform: translateY(-1px); }
        .msg-card.unread { background: #fffbeb; }
        .msg-card.unread::before { content: ''; position: absolute;
                                    left: 0; top: 0; bottom: 0; width: 3px;
                                    background: var(--color-danger); border-radius: 4px 0 0 4px; }
        .msg-icon { width: 48px; height: 48px; border-radius: 8px;
                    display: grid; place-items: center; font-size: 22px; color: #fff; }
        .msg-body { min-width: 0; }
        .msg-line-1 { display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
                       margin-bottom: 4px; }
        .msg-type-tag { font-size: 11px; padding: 1px 8px;
                        background: #f3f4f6; color: var(--color-muted);
                        border-radius: 3px; font-weight: 500; }
        .msg-card.unread .msg-type-tag { background: #fef3c7; color: #b45309; }
        .msg-title { font-size: 14px; font-weight: 600; color: var(--color-text); }
        .msg-card.unread .msg-title { font-weight: 700; }
        .msg-content { font-size: 13px; color: var(--color-text-sub);
                       line-height: 1.5; word-break: break-all;
                       display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
                       overflow: hidden; }
        .msg-time { font-size: 12px; color: var(--color-placeholder); text-align: right;
                    white-space: nowrap; }
        .msg-time .ago { display: block; margin-top: 2px; }
        .msg-actions { display: flex; gap: 6px; margin-top: 8px; }
        .msg-action-btn { padding: 4px 10px; background: #fff;
                          color: var(--color-text-sub); border: 1px solid var(--color-border);
                          border-radius: 3px; font-size: 12px; cursor: pointer;
                          transition: all 0.15s; }
        .msg-action-btn:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .msg-action-btn.danger:hover { border-color: var(--color-danger); color: var(--color-danger); }

        /* 空状态 */
        .empty-state { background: #fff; border-radius: 8px;
                       box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 12px;
                       text-align: center; padding: 80px 20px;
                       color: var(--color-muted); font-size: 13px; }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }

        /* 分页 */
        .pager { margin-top: 16px; display: flex; justify-content: center; gap: 6px; }
        .pager a, .pager span { padding: 6px 12px; border: 1px solid var(--color-border);
                                border-radius: 4px; font-size: 13px; color: var(--color-text-sub);
                                text-decoration: none; min-width: 32px; text-align: center;
                                background: #fff; }
        .pager a:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .pager .active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .pager .disabled { color: var(--color-placeholder); cursor: not-allowed; background: var(--color-bg); }

        /* 弹窗（消息详情） */
        .modal { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000;
                 display: none; align-items: center; justify-content: center; }
        .modal.show { display: flex; }
        .modal-content { background: #fff; border-radius: 10px; padding: 28px;
                         width: 90%; max-width: 480px; max-height: 80vh; overflow-y: auto; }
        .modal-header { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
        .modal-icon { width: 48px; height: 48px; border-radius: 8px;
                      display: grid; place-items: center; font-size: 22px; color: #fff; }
        .modal-title-body { flex: 1; min-width: 0; }
        .modal-title-text { font-size: 16px; font-weight: 700; margin-bottom: 4px; }
        .modal-time { font-size: 12px; color: var(--color-muted); }
        .modal-content-body { font-size: 14px; line-height: 1.7; color: var(--color-text);
                              white-space: pre-wrap; word-break: break-all;
                              background: var(--color-bg); padding: 14px 16px;
                              border-radius: 6px; margin-bottom: 16px; }
        .modal-actions { display: flex; gap: 8px; }
        .modal-actions a, .modal-actions button { flex: 1; padding: 10px;
                                                   border-radius: 6px; font-size: 13px;
                                                   font-weight: 600; text-align: center;
                                                   text-decoration: none; cursor: pointer; }
        .modal-actions .btn-primary { background: var(--color-primary); color: #fff;
                                      border: 1px solid var(--color-primary); }
        .modal-actions .btn-ghost { background: #f3f4f6; color: var(--color-text);
                                    border: 1px solid transparent; }

        /* 页脚 */
        .msg-footer { background: #1f2937; color: #d1d5db;
                      margin-top: 32px; padding: 32px 16px 16px;
                      text-align: center; font-size: 12px; }
        .msg-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }

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
            <a href="<%=ctx%>/message?action=list" class="active">消息中心</a>
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

<div class="msg-wrap" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="msg-head">
        <div class="msg-head-icon">
            <i class="fa fa-envelope"></i>
            <% if (unreadCount > 0) { %>
                <span class="badge"><%= unreadCount > 99 ? "99+" : unreadCount %></span>
            <% } %>
        </div>
        <div class="msg-head-info">
            <div class="msg-head-title">消息中心</div>
            <div class="msg-head-sub">共 {{ total }} 条 · 未读 <span style="color: var(--color-danger); font-weight: 600;">{{ unreadCount }}</span> 条</div>
        </div>
        <div class="msg-head-actions">
            <button class="btn-primary" @click="markAllRead" :disabled="unreadCount === 0">
                <i class="fa fa-check-circle"></i> 全部标为已读
            </button>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- tab 切换 -->
    <div class="filter-bar">
        <a href="<%=ctx%>/message?action=list" class="filter-tab <%= isReadFilter == null ? "active" : "" %>">
            全部 <span class="count">(<%= total %>)</span>
        </a>
        <a href="<%=ctx%>/message?action=list&isRead=0" class="filter-tab <%= isReadFilter != null && isReadFilter == 0 ? "active" : "" %>">
            未读 <span class="count">(<%= unreadCount %>)</span>
        </a>
        <a href="<%=ctx%>/message?action=list&isRead=1" class="filter-tab <%= isReadFilter != null && isReadFilter == 1 ? "active" : "" %>">
            已读
        </a>
    </div>

    <!-- 消息列表 -->
    <div v-if="messages.length > 0" class="msg-list">
        <div v-for="m in messages" :key="m.id"
             :class="['msg-card', { unread: m.isRead === 0 }]"
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
    <div v-else class="empty-state">
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
    <div :class="['modal', { show: modalOpen }]" @click.self="closeModal">
        <div class="modal-content" v-if="currentMsg">
            <div class="modal-header">
                <div class="modal-icon" :style="'background:' + currentMsg.typeColor">
                    <i :class="['fa', currentMsg.typeIcon]"></i>
                </div>
                <div class="modal-title-body">
                    <div class="modal-title-text">{{ currentMsg.title }}</div>
                    <div class="modal-time">{{ currentMsg.typeText }} · {{ formatTime(currentMsg.createTime) }}</div>
                </div>
            </div>
            <div class="modal-content-body">{{ currentMsg.content }}</div>
            <div class="modal-actions">
                <button class="btn-ghost" @click="removeMsg(currentMsg)">
                    <i class="fa fa-trash-o"></i> 删除
                </button>
                <a v-if="relatedUrl(currentMsg)" :href="relatedUrl(currentMsg)" class="btn-primary">
                    <i class="fa fa-external-link"></i> 查看详情
                </a>
                <button v-else class="btn-primary" @click="closeModal">关闭</button>
            </div>
        </div>
    </div>

</div>

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
