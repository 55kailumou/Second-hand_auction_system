<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.Admin admin =
            (org.example.entity.Admin) session.getAttribute("currentAdmin");
    if (admin == null) {
        response.sendRedirect(ctx + "/admin/login");
        return;
    }

    String usersJson = (String) request.getAttribute("usersJson");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("pageNo");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer status = (Integer) request.getAttribute("status");
    String keyword = (String) request.getAttribute("keyword");
    Integer normalCount = (Integer) request.getAttribute("normalCount");
    Integer bannedCount = (Integer) request.getAttribute("bannedCount");
    String error = (String) request.getAttribute("error");
    if (usersJson == null) usersJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (keyword == null) keyword = "";
    if (normalCount == null) normalCount = 0;
    if (bannedCount == null) bannedCount = 0;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户管理 · 管理后台</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #f5f5f5; margin: 0; }
        .admin-header { background: #1f2937; color: #d1d5db; height: 56px;
                        position: sticky; top: 0; z-index: 100; }
        .admin-header-inner { max-width: 1400px; margin: 0 auto; padding: 0 20px; height: 100%;
                              display: flex; align-items: center; gap: 20px; }
        .admin-logo { display: flex; align-items: center; gap: 8px;
                      font-size: 16px; font-weight: 700; color: #fff;
                      text-decoration: none; }
        .admin-logo-icon { width: 28px; height: 28px; background: #f59e0b; color: #1f2937;
                           border-radius: 4px; display: grid; place-items: center;
                           font-size: 14px; font-weight: 700; }
        .admin-nav { display: flex; gap: 4px; margin-left: 20px; }
        .admin-nav a { padding: 8px 14px; color: #d1d5db; font-size: 13px;
                       border-radius: 4px; text-decoration: none; transition: all 0.15s; }
        .admin-nav a:hover { background: rgba(255,255,255,0.1); color: #fff; }
        .admin-nav a.active { background: rgba(245,158,11,0.2); color: #fbbf24; }
        .admin-user { margin-left: auto; display: flex; align-items: center; gap: 12px; font-size: 13px; }
        .admin-user .role-tag { padding: 2px 8px; background: #374151; color: #fbbf24;
                                border-radius: 3px; font-size: 11px; font-weight: 600; }
        .admin-user a { color: #9ca3af; text-decoration: none; font-size: 12px; }
        .admin-user a:hover { color: #fff; }

        .admin-main { max-width: 1400px; margin: 16px auto 0; padding: 0 20px 60px; }

        .page-head { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     padding: 20px 24px; display: flex; align-items: center; gap: 16px; }
        .page-head-icon { width: 48px; height: 48px; border-radius: 8px;
                          background: #d1fae5; color: #047857;
                          display: grid; place-items: center; font-size: 22px; }
        .page-head-info { flex: 1; }
        .page-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); }
        .page-head-stat { display: flex; gap: 6px; align-items: center; padding: 8px 16px;
                          background: #d1fae5; color: #047857; border-radius: 6px;
                          font-size: 13px; font-weight: 600; }
        .page-head-stat .num { font-size: 18px; }

        .filter-bar { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                      margin-top: 12px; padding: 12px 20px;
                      display: flex; align-items: center; flex-wrap: wrap; gap: 8px; }
        .filter-tab { padding: 8px 14px; font-size: 13px; color: var(--color-text-sub);
                      cursor: pointer; position: relative; font-weight: 500;
                      text-decoration: none; border-radius: 4px; transition: all 0.15s; }
        .filter-tab:hover { color: var(--color-primary); background: #f9fafb; }
        .filter-tab.active { color: #fff; background: var(--color-primary); font-weight: 600; }
        .filter-tab .count { margin-left: 4px; font-size: 12px; opacity: 0.85; }
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input { padding: 6px 12px; border: 1px solid var(--color-border);
                                border-radius: 4px; font-size: 13px; outline: none; width: 260px; }
        .filter-search input:focus { border-color: var(--color-primary); }
        .filter-search button { padding: 6px 14px; background: var(--color-primary); color: #fff;
                                border: none; border-radius: 4px; font-size: 13px; cursor: pointer; }

        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        .user-table { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 12px; overflow: hidden; }
        .user-row { display: grid;
                     grid-template-columns: 60px 1fr 220px 100px 100px 110px 280px;
                     gap: 14px; padding: 14px 20px; align-items: center;
                     border-bottom: 1px solid var(--color-border-soft); }
        .user-row:last-child { border-bottom: none; }
        .user-row.head { background: #f9fafb; font-size: 12px; color: var(--color-muted);
                          font-weight: 600; padding: 10px 20px; }
        .col-avatar { width: 44px; height: 44px; border-radius: 50%;
                       background: linear-gradient(135deg, #d1fae5, #6ee7b7); color: #047857;
                       display: grid; place-items: center; font-size: 18px; font-weight: 700; }
        .col-avatar.banned { background: linear-gradient(135deg, #fee2e2, #fca5a5); color: #b91c1c; opacity: 0.7; }
        .col-user { min-width: 0; }
        .col-user .username { font-size: 13px; font-weight: 600; color: var(--color-text);
                              margin-bottom: 2px;
                              overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .col-user .uid { font-size: 11px; color: var(--color-muted); }
        .col-contact { font-size: 12px; }
        .col-contact .row { margin-bottom: 2px;
                             overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .col-contact .row i { color: var(--color-muted); margin-right: 4px; }
        .col-credit { font-size: 14px; font-weight: 700; text-align: center; }
        .col-credit .score { font-size: 18px; }
        .col-credit.high { color: #047857; }
        .col-credit.mid  { color: #b45309; }
        .col-credit.low  { color: #b91c1c; }
        .col-balance { font-size: 13px; text-align: center; color: var(--color-text-sub); }
        .col-balance .num { font-size: 15px; font-weight: 700; color: var(--color-primary); }
        .col-status .badge { padding: 3px 10px; border-radius: 12px; font-weight: 500;
                              font-size: 11px; }
        .col-actions { display: flex; gap: 4px; justify-content: flex-end; flex-wrap: wrap; }
        .col-actions button { padding: 5px 10px; border: 1px solid var(--color-border);
                              border-radius: 3px; font-size: 12px; cursor: pointer;
                              background: #fff; color: var(--color-text-sub);
                              transition: all 0.15s; }
        .col-actions button:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .col-actions button.danger:hover { border-color: var(--color-danger); color: var(--color-danger); }

        .empty-state { text-align: center; padding: 60px 20px; color: var(--color-muted); font-size: 13px; }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }

        .pager { margin-top: 16px; display: flex; justify-content: center; gap: 6px; }
        .pager a, .pager span { padding: 6px 12px; border: 1px solid var(--color-border);
                                border-radius: 4px; font-size: 13px; color: var(--color-text-sub);
                                text-decoration: none; min-width: 32px; text-align: center;
                                background: #fff; }
        .pager a:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .pager .active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .pager .disabled { color: var(--color-placeholder); cursor: not-allowed; background: var(--color-bg); }

        /* 弹窗 */
        .modal { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000;
                 display: none; align-items: center; justify-content: center; }
        .modal.show { display: flex; }
        .modal-content { background: #fff; border-radius: 10px; padding: 28px;
                         width: 90%; max-width: 460px; }
        .modal-title { font-size: 17px; font-weight: 700; margin-bottom: 8px;
                       display: flex; align-items: center; gap: 8px; color: #b45309; }
        .modal-title.danger { color: #b91c1c; }
        .modal-title.success { color: #047857; }
        .modal-sub { font-size: 12px; color: var(--color-muted); margin-bottom: 18px;
                     line-height: 1.5; }
        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-size: 13px; color: var(--color-text-sub);
                      margin-bottom: 6px; font-weight: 500; }
        .form-input { width: 100%; padding: 9px 12px; border: 1px solid var(--color-border);
                      border-radius: 6px; font-size: 14px; outline: none;
                      font-family: inherit; box-sizing: border-box; }
        .form-input:focus { border-color: var(--color-primary); }
        .form-hint { font-size: 11px; color: var(--color-muted); margin-top: 4px; }
        .modal-actions { display: flex; gap: 8px; margin-top: 20px;
                         padding-top: 16px; border-top: 1px solid var(--color-border-soft); }
        .modal-actions button { flex: 1; padding: 10px; border: none; border-radius: 6px;
                                font-size: 14px; font-weight: 600; cursor: pointer; }
        .btn-modal-cancel { background: #f3f4f6; color: var(--color-text); }
        .btn-modal-confirm { background: var(--color-primary); color: #fff; }
        .btn-modal-danger { background: #ef4444; color: #fff; }

        /* 徽章颜色 */
        .badge-success { background: #d1fae5; color: #047857; }
        .badge-danger  { background: #fee2e2; color: #b91c1c; }
        .badge-gray    { background: #e5e7eb; color: #6b7280; }
    </style>
</head>
<body>

<header class="admin-header">
    <div class="admin-header-inner">
        <a href="<%=ctx%>/admin" class="admin-logo">
            <span class="admin-logo-icon">A</span>
            <span>管理后台</span>
        </a>
        <nav class="admin-nav">
            <a href="<%=ctx%>/admin"><i class="fa fa-dashboard"></i> 概览</a>
            <a href="<%=ctx%>/admin/refund?action=list"><i class="fa fa-undo"></i> 退款审批</a>
            <a href="<%=ctx%>/admin/complaint?action=list"><i class="fa fa-flag"></i> 投诉审批</a>
            <a href="<%=ctx%>/admin/item?action=list"><i class="fa fa-gavel"></i> 拍品管理</a>
            <a href="<%=ctx%>/admin/user?action=list" class="active">
                <i class="fa fa-users"></i> 用户管理
            </a>
        </nav>
        <div class="admin-user">
            <i class="fa fa-user-circle-o"></i>
            <span><%= EscapeUtil.html(admin.getAdminName()) %></span>
            <span class="role-tag"><%= admin.getRole() == null ? "admin" : admin.getRole() %></span>
            <a href="<%=ctx%>/admin/login?action=logout"><i class="fa fa-sign-out"></i> 退出</a>
        </div>
    </div>
</header>

<div class="admin-main" id="app">

    <div class="page-head">
        <div class="page-head-icon"><i class="fa fa-users"></i></div>
        <div class="page-head-info">
            <div class="page-head-title">用户管理</div>
            <div class="page-head-sub">封禁 / 解封用户、调整信用分（0-150）、重置密码。初始账号 ID=1 受保护。</div>
        </div>
        <div class="page-head-stat">
            <i class="fa fa-check-circle"></i>
            正常 <span class="num"><%= normalCount %></span> / 封禁 <span class="num" style="color: #b91c1c;"><%= bannedCount %></span>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- tab 筛选 + 搜索 -->
    <form class="filter-bar" method="get" action="<%=ctx%>/admin/user">
        <input type="hidden" name="action" value="list">

        <a href="<%=ctx%>/admin/user?action=list" class="filter-tab <%= status == null ? "active" : "" %>">
            全部 <span class="count">(<%= normalCount + bannedCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/user?action=list&status=0" class="filter-tab <%= status != null && status == 0 ? "active" : "" %>">
            正常 <span class="count">(<%= normalCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/user?action=list&status=1" class="filter-tab <%= status != null && status == 1 ? "active" : "" %>">
            封禁 <span class="count">(<%= bannedCount %>)</span>
        </a>

        <div class="filter-search">
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索用户名 / 手机 / 邮箱">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </div>
    </form>

    <!-- 列表 -->
    <div v-if="users.length > 0" class="user-table">
        <div class="user-row head">
            <div>头像</div>
            <div>用户</div>
            <div>联系方式</div>
            <div style="text-align: center;">信用分</div>
            <div style="text-align: center;">余额</div>
            <div style="text-align: center;">状态</div>
            <div style="text-align: right;">操作</div>
        </div>
        <div v-for="u in users" :key="u.id" class="user-row">
            <div :class="['col-avatar', u.status === 1 ? 'banned' : '']">
                {{ u.username ? u.username.charAt(0).toUpperCase() : '?' }}
            </div>
            <div class="col-user">
                <div class="username">{{ u.username || '(未设置)' }}</div>
                <div class="uid">ID: {{ u.id }} · 注册 {{ formatTime(u.registerTime) }}</div>
            </div>
            <div class="col-contact">
                <div class="row" v-if="u.phone">
                    <i class="fa fa-mobile"></i> {{ u.phone }}
                </div>
                <div class="row" v-if="u.email">
                    <i class="fa fa-envelope-o"></i> {{ u.email }}
                </div>
                <div class="row" v-if="!u.phone && !u.email" style="color: var(--color-muted);">
                    未填写
                </div>
            </div>
            <div :class="['col-credit', creditLevel(u.creditScore)]">
                <div class="score">{{ u.creditScore == null ? '-' : u.creditScore }}</div>
            </div>
            <div class="col-balance">
                <small>¥</small><span class="num">{{ formatBalance(u.balance) }}</span>
            </div>
            <div class="col-status" style="text-align: center;">
                <span :class="['badge', u.status === 1 ? 'badge-danger' : 'badge-success']">
                    {{ u.status === 1 ? '封禁' : '正常' }}
                </span>
            </div>
            <div class="col-actions">
                <button v-if="u.status !== 1" class="danger" @click="banUser(u)">
                    <i class="fa fa-ban"></i> 封禁
                </button>
                <button v-else @click="unbanUser(u)">
                    <i class="fa fa-check"></i> 解封
                </button>
                <button @click="openCreditModal(u)">
                    <i class="fa fa-sliders"></i> 信用分
                </button>
                <button class="danger" @click="resetPassword(u)">
                    <i class="fa fa-key"></i> 重置密码
                </button>
            </div>
        </div>
    </div>

    <div v-else class="user-table">
        <div class="empty-state">
            <i class="fa fa-user-o"></i>
            <p>暂无符合条件的用户</p>
        </div>
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

    <!-- 调信用分弹窗 -->
    <div :class="['modal', { show: creditModalOpen }]" @click.self="closeCreditModal">
        <div class="modal-content">
            <div class="modal-title"><i class="fa fa-sliders"></i> 调整信用分</div>
            <div class="modal-sub">
                当前用户：<strong>{{ currentUser ? currentUser.username : '' }}</strong>
                · 当前信用分：<strong style="color: var(--color-primary);">{{ currentUser ? currentUser.creditScore : '-' }}</strong>
                <br>范围 0-150，自动约束。输入正值上调，负值下调。
            </div>
            <form @submit.prevent="submitCredit">
                <div class="form-group">
                    <label class="form-label">调整量（-100 ~ +100）</label>
                    <input type="number" v-model.number="creditDelta" class="form-input"
                           min="-100" max="100" placeholder="例如：+10 / -20" required>
                    <div class="form-hint">
                        新信用分（预览）：{{ creditPreview }}
                    </div>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeCreditModal">取消</button>
                    <button type="submit" class="btn-modal-confirm" :disabled="creditSubmitting">
                        {{ creditSubmitting ? '处理中...' : '确认调整' }}
                    </button>
                </div>
            </form>
        </div>
    </div>

</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath      = '<%=ctx%>';
    const usersInit    = <%= usersJson %>;
    const total        = <%= total %>;
    const pageNoInit   = <%= pageNo %>;
    const totalPages   = <%= totalPages %>;

    loadVue().then(() => {
        const { createApp, ref, computed } = Vue;
        createApp({
            setup() {
                const users = ref(usersInit);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);

                // 调信用分弹窗
                const creditModalOpen = ref(false);
                const currentUser = ref(null);
                const creditDelta = ref(0);
                const creditSubmitting = ref(false);

                const pagesToShow = computed(() => {
                    const t = totalPagesRef.value;
                    const c = pageNoRef.value;
                    const arr = [];
                    const start = Math.max(1, c - 2);
                    const end = Math.min(t, c + 2);
                    for (let i = start; i <= end; i++) arr.push(i);
                    return arr;
                });

                const creditPreview = computed(() => {
                    if (!currentUser.value || !creditDelta.value) return currentUser.value ? currentUser.value.creditScore : '-';
                    const newScore = (currentUser.value.creditScore || 100) + creditDelta.value;
                    return Math.max(0, Math.min(150, newScore));
                });

                function pageHref(p) {
                    const params = new URLSearchParams();
                    params.set('action', 'list');
                    params.set('page', p);
                    const activeTab = document.querySelector('a.filter-tab.active');
                    if (activeTab && activeTab.href) {
                        const u = new URL(activeTab.href);
                        const s = u.searchParams.get('status');
                        if (s !== null) params.set('status', s);
                    }
                    const kw = document.querySelector('input[name="keyword"]');
                    if (kw && kw.value) params.set('keyword', kw.value);
                    return ctxPath + '/admin/user?' + params.toString();
                }

                function creditLevel(s) {
                    if (s == null) return '';
                    if (s >= 120) return 'high';
                    if (s >= 90) return 'mid';
                    return 'low';
                }
                function formatBalance(b) {
                    if (b == null) return '0.00';
                    return Number(b).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
                function formatTime(t) {
                    if (!t) return '-';
                    // ISO 字符串转 yyyy-MM-dd
                    return t.substring(0, 10);
                }

                function banUser(u) {
                    if (!confirm('确定封禁用户「' + (u.username || ('#' + u.id)) + '」？\n封禁后该用户无法登录，且无法在出价/下单/发布拍品。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/user?action=set-status', new URLSearchParams({
                            id: u.id, status: '1'
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已封禁', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }
                function unbanUser(u) {
                    if (!confirm('确定解封用户「' + (u.username || ('#' + u.id)) + '」？')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/user?action=set-status', new URLSearchParams({
                            id: u.id, status: '0'
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已解封', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                function openCreditModal(u) {
                    currentUser.value = u;
                    creditDelta.value = 0;
                    creditModalOpen.value = true;
                }
                function closeCreditModal() { creditModalOpen.value = false; }
                function submitCredit() {
                    if (creditSubmitting.value || !currentUser.value) return;
                    if (!creditDelta.value) { toast('调整值不能为 0', 'error'); return; }
                    if (creditDelta.value < -100 || creditDelta.value > 100) {
                        toast('单次调整范围 -100 ~ +100', 'error');
                        return;
                    }
                    creditSubmitting.value = true;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/user?action=adjust-credit', new URLSearchParams({
                            id: currentUser.value.id, delta: creditDelta.value
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '调整成功', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                            creditSubmitting.value = false;
                        }).catch(() => { toast('网络错误', 'error'); creditSubmitting.value = false; });
                    });
                }

                function resetPassword(u) {
                    if (!confirm('确定重置用户「' + (u.username || ('#' + u.id)) + '」的密码为 123456？\n用户下次登录将使用新密码。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/user?action=reset-password', new URLSearchParams({
                            id: u.id
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '密码已重置', 'success');
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                return { users, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef,
                         pagesToShow, creditModalOpen, currentUser, creditDelta, creditSubmitting,
                         creditPreview, pageHref, creditLevel, formatBalance, formatTime,
                         banUser, unbanUser, openCreditModal, closeCreditModal, submitCredit,
                         resetPassword };
            }
        }).mount('#app');
    });
</script>
</body>
</html>