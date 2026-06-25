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
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        .admin-main { max-width: 1400px; margin: 24px auto 0; padding: 0 24px 60px; position: relative; z-index: 3; }

        .admin-main .cp-page-head { margin: 0 0 16px; }
        .admin-main .cp-page-head .cp-page-sub { font-size: 11px; }

        .filter-bar {
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
            padding: 12px 16px;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            flex-wrap: wrap;
            gap: 8px;
        }
        .filter-tab {
            padding: 6px 14px;
            font-size: 11px;
            color: var(--cp-text-dim);
            font-family: var(--font-mono);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            cursor: pointer;
            transition: all 0.15s;
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            text-decoration: none;
            font-weight: 700;
        }
        .filter-tab:hover { color: var(--cp-yellow); background: rgba(255,238,0,0.1); }
        .filter-tab.active { background: var(--cp-yellow); color: #000; }
        .filter-tab .count { margin-left: 4px; font-size: 10px; opacity: 0.7; }
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input {
            padding: 6px 12px;
            font-size: 12px;
            color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none;
            font-family: var(--font-mono);
            width: 260px;
        }
        .filter-search input:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }
        .filter-search input::placeholder { color: var(--cp-text-dim); }
        .filter-search button {
            padding: 6px 14px;
            background: var(--cp-yellow); color: #000;
            border: none;
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
            cursor: pointer;
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            font-family: var(--font-mono);
        }

        .alert {
            padding: 10px 16px;
            font-family: var(--font-mono); font-size: 11px;
            margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.05em;
        }
        .alert-warning {
            background: rgba(255,238,0,0.1);
            color: var(--cp-yellow);
            border: 1px solid var(--cp-yellow-dim);
        }

        .cp-table td, .cp-table th { white-space: nowrap; }

        .empty-state {
            text-align: center; padding: 60px 20px;
            font-family: var(--font-mono); font-size: 12px;
            color: var(--cp-text-dim);
        }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; color: var(--cp-yellow-dim); }

        .user-avatar {
            width: 36px; height: 36px;
            background: var(--cp-yellow); color: #000;
            display: grid; place-items: center;
            font-size: 14px; font-weight: 900;
            clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
            flex-shrink: 0;
        }
        .user-avatar.banned { background: var(--cp-red); color: #fff; opacity: 0.7; }

        .action-btn {
            padding: 4px 10px;
            background: #000;
            border: 1px solid var(--cp-yellow-dim);
            color: var(--cp-text-dim);
            font-family: var(--font-mono);
            font-size: 10px;
            text-transform: uppercase;
            cursor: pointer;
            transition: all 0.15s;
            clip-path: polygon(3px 0, 100% 0, 100% calc(100% - 3px), calc(100% - 3px) 100%, 0 100%, 0 3px);
        }
        .action-btn:hover { border-color: var(--cp-yellow); color: var(--cp-yellow); }
        .action-btn.danger:hover { border-color: var(--cp-red); color: var(--cp-red); }

        .form-input {
            width: 100%;
            padding: 9px 12px;
            font-size: 13px;
            color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none;
            font-family: var(--font-mono);
            box-sizing: border-box;
        }
        .form-input:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }
        .form-hint { font-size: 10px; font-family: var(--font-mono); color: var(--cp-text-dim); margin-top: 4px; }

        .form-group { margin-bottom: 14px; }
        .form-label {
            display: block;
            font-family: var(--font-mono);
            font-size: 10px;
            color: var(--cp-yellow-dim);
            text-transform: uppercase;
            letter-spacing: 0.1em;
            margin-bottom: 6px;
        }

        .cp-modal-actions {
            display: flex; gap: 8px; margin-top: 20px;
            padding-top: 16px; border-top: 1px solid rgba(255,238,0,0.15);
        }
        .cp-modal-actions button { flex: 1; padding: 10px; font-size: 12px; font-weight: 700; }
        .btn-modal-cancel {
            background: rgba(255,238,0,0.1); color: var(--cp-yellow-dim);
            border: 1px solid var(--cp-yellow-dim);
            font-family: var(--font-mono);
            text-transform: uppercase;
        }
        .btn-modal-danger {
            background: var(--cp-red); color: #fff;
            font-family: var(--font-mono);
            text-transform: uppercase;
        }
    </style>
</head>
<body>

<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/admin" class="cp-logo">管理后台</a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/admin"><i class="fa fa-dashboard"></i> 概览</a>
            <a href="<%=ctx%>/admin/refund?action=list"><i class="fa fa-undo"></i> 退款审批</a>
            <a href="<%=ctx%>/admin/complaint?action=list"><i class="fa fa-flag"></i> 投诉审批</a>
            <a href="<%=ctx%>/admin/item?action=list"><i class="fa fa-gavel"></i> 拍品管理</a>
            <a href="<%=ctx%>/admin/user?action=list" class="active"><i class="fa fa-users"></i> 用户管理</a>
        </nav>
        <div class="cp-nav-user">
            <i class="fa fa-user-circle-o" style="color: var(--cp-yellow-dim);"></i>
            <span style="font-size: 12px; color: var(--cp-text-dim); font-family: var(--font-mono);"><%= EscapeUtil.html(admin.getAdminName()) %></span>
            <span style="padding: 2px 6px; background: rgba(255,238,0,0.1); color: var(--cp-yellow-dim); font-size: 9px; font-family: var(--font-mono); text-transform: uppercase; border: 1px solid var(--cp-yellow-dim);"><%= admin.getRole() == null ? "admin" : admin.getRole() %></span>
            <a href="<%=ctx%>/admin/login?action=logout" class="icon-btn"><i class="fa fa-sign-out"></i></a>
        </div>
    </div>
</header>

<div class="admin-main" id="app">

    <div class="cp-page-head">
        <div>
            <div class="cp-page-title">用户管理</div>
            <div class="cp-page-sub">封禁 / 解封用户、调整信用分（0-150）、重置密码。初始账号 ID=1 受保护。</div>
        </div>
        <div class="cp-badge cp-badge-yellow" style="font-size: 12px; padding: 6px 14px;">
            <i class="fa fa-check-circle"></i>
            正常 <%= normalCount %> / 封禁 <%= bannedCount %>
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
    <div v-if="users.length > 0" class="cp-table-wrap">
        <table class="cp-table">
            <thead>
                <tr>
                    <th style="width: 50px;">头像</th>
                    <th>用户</th>
                    <th>联系方式</th>
                    <th style="text-align: center;">信用分</th>
                    <th style="text-align: center;">余额</th>
                    <th style="text-align: center;">状态</th>
                    <th style="text-align: right;">操作</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="u in users" :key="u.id">
                    <td>
                        <div :class="['user-avatar', u.status === 1 ? 'banned' : '']">
                            {{ u.username ? u.username.charAt(0).toUpperCase() : '?' }}
                        </div>
                    </td>
                    <td>
                        <div style="font-weight: 700; color: var(--cp-yellow);">{{ u.username || '(未设置)' }}</div>
                        <div style="font-size: 10px; color: var(--cp-text-dim); font-family: var(--font-mono);">ID: {{ u.id }} · 注册 {{ formatTime(u.registerTime) }}</div>
                    </td>
                    <td style="font-size: 11px; font-family: var(--font-mono);">
                        <div v-if="u.phone" style="margin-bottom: 2px;"><i class="fa fa-mobile" style="color: var(--cp-text-dim);"></i> {{ u.phone }}</div>
                        <div v-if="u.email"><i class="fa fa-envelope-o" style="color: var(--cp-text-dim);"></i> {{ u.email }}</div>
                        <div v-if="!u.phone && !u.email" style="color: var(--cp-text-dim);">未填写</div>
                    </td>
                    <td style="text-align: center;">
                        <div style="font-size: 16px; font-weight: 700;" :style="{ color: u.creditScore >= 120 ? 'var(--cp-yellow)' : u.creditScore >= 90 ? '#FFAA00' : 'var(--cp-red)' }">
                            {{ u.creditScore == null ? '-' : u.creditScore }}
                        </div>
                    </td>
                    <td style="text-align: center; font-family: var(--font-mono);">
                        <small style="color: var(--cp-text-dim);">¥</small><span style="font-size: 14px; font-weight: 700; color: var(--cp-yellow);">{{ formatBalance(u.balance) }}</span>
                    </td>
                    <td style="text-align: center;">
                        <span :class="['cp-badge', u.status === 1 ? 'cp-badge-red' : 'cp-badge-yellow']">
                            {{ u.status === 1 ? '封禁' : '正常' }}
                        </span>
                    </td>
                    <td style="text-align: right;">
                        <button v-if="u.status !== 1" class="action-btn danger" @click="banUser(u)">
                            <i class="fa fa-ban"></i> 封禁
                        </button>
                        <button v-else class="action-btn" @click="unbanUser(u)">
                            <i class="fa fa-check"></i> 解封
                        </button>
                        <button class="action-btn" @click="openCreditModal(u)">
                            <i class="fa fa-sliders"></i> 信用分
                        </button>
                        <button class="action-btn danger" @click="resetPassword(u)">
                            <i class="fa fa-key"></i> 重置密码
                        </button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <div v-else class="cp-table-wrap">
        <div class="empty-state">
            <i class="fa fa-user-o"></i>
            <p>暂无符合条件的用户</p>
        </div>
    </div>

    <!-- 分页 -->
    <div v-if="totalPages > 1" class="cp-pagination">
        <button v-if="pageNo > 1" class="cp-page-btn" @click="window.location.href = pageHref(pageNo - 1)">&lsaquo; 上一页</button>
        <button v-else class="cp-page-btn" disabled>&lsaquo; 上一页</button>
        <button v-for="p in pagesToShow" :key="p" :class="['cp-page-btn', p === pageNo ? 'active' : '']"
                @click="window.location.href = pageHref(p)">{{ p }}</button>
        <button v-if="pageNo < totalPages" class="cp-page-btn" @click="window.location.href = pageHref(pageNo + 1)">下一页 &rsaquo;</button>
        <button v-else class="cp-page-btn" disabled>下一页 &rsaquo;</button>
    </div>

    <!-- 调信用分弹窗 -->
    <div v-if="creditModalOpen" class="cp-modal-overlay" @click.self="closeCreditModal">
        <div class="cp-modal">
            <div class="cp-modal-title">
                <span><i class="fa fa-sliders"></i> 调整信用分</span>
                <span class="cp-modal-close" @click="closeCreditModal">&times;</span>
            </div>
            <div class="cp-page-sub" style="margin-bottom: 18px; line-height: 1.5;">
                当前用户：<strong style="color: var(--cp-yellow);">{{ currentUser ? currentUser.username : '' }}</strong>
                · 当前信用分：<strong style="color: var(--cp-yellow);">{{ currentUser ? currentUser.creditScore : '-' }}</strong>
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
                <div class="cp-modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeCreditModal">取消</button>
                    <button type="submit" class="cp-btn cp-btn-sm" :disabled="creditSubmitting">
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
