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

    String rowsJson = (String) request.getAttribute("rowsJson");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("pageNo");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer status = (Integer) request.getAttribute("status");
    String keyword = (String) request.getAttribute("keyword");
    Integer pendingCount = (Integer) request.getAttribute("pendingCount");
    String error = (String) request.getAttribute("error");
    if (rowsJson == null) rowsJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (keyword == null) keyword = "";
    if (pendingCount == null) pendingCount = 0;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>投诉审批 · 管理后台</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* 复用 admin/refunds.jsp 的暗色顶栏 + 浅色内容样式 */
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
        .admin-nav a .badge { display: inline-block; padding: 1px 6px; margin-left: 4px;
                              background: #ef4444; color: #fff; font-size: 10px;
                              border-radius: 8px; font-weight: 600; }
        .admin-user { margin-left: auto; display: flex; align-items: center; gap: 12px; font-size: 13px; }
        .admin-user .role-tag { padding: 2px 8px; background: #374151; color: #fbbf24;
                                border-radius: 3px; font-size: 11px; font-weight: 600; }
        .admin-user a { color: #9ca3af; text-decoration: none; font-size: 12px; }
        .admin-user a:hover { color: #fff; }

        .admin-main { max-width: 1400px; margin: 16px auto 0; padding: 0 20px 60px; }

        .page-head { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     padding: 20px 24px; display: flex; align-items: center; gap: 16px; }
        .page-head-icon { width: 48px; height: 48px; border-radius: 8px;
                          background: #fee2e2; color: #b91c1c;
                          display: grid; place-items: center; font-size: 22px; }
        .page-head-info { flex: 1; }
        .page-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); }
        .page-head-stat { display: flex; gap: 6px; align-items: center; padding: 8px 16px;
                          background: #fee2e2; color: #b91c1c; border-radius: 6px;
                          font-size: 13px; font-weight: 600; }
        .page-head-stat .num { font-size: 18px; }

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
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input { padding: 6px 12px; border: 1px solid var(--color-border);
                               border-radius: 4px; font-size: 13px; outline: none; width: 240px; }
        .filter-search input:focus { border-color: var(--color-primary); }
        .filter-search button { padding: 6px 14px; background: var(--color-primary); color: #fff;
                                border: none; border-radius: 4px; font-size: 13px; cursor: pointer; }

        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        .order-table { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 12px; overflow: hidden; }
        .order-row { display: grid; grid-template-columns: 100px 1fr 200px 120px 200px;
                     gap: 16px; padding: 14px 20px; align-items: center;
                     border-bottom: 1px solid var(--color-border-soft); }
        .order-row:last-child { border-bottom: none; }
        .order-row.head { background: #f9fafb; font-size: 12px; color: var(--color-muted);
                          font-weight: 600; padding: 10px 20px; }
        .col-cover { width: 60px; height: 60px; border-radius: 4px; background: #f3f4f6;
                     display: grid; place-items: center; color: #9ca3af; overflow: hidden;
                     flex-shrink: 0; }
        .col-cover img { width: 100%; height: 100%; object-fit: cover; }
        .col-info { display: flex; align-items: center; gap: 10px; min-width: 0; }
        .col-info-body { min-width: 0; }
        .col-info-title { font-size: 13px; font-weight: 600; color: var(--color-text);
                          margin-bottom: 2px;
                          overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .col-info-sub { font-size: 11px; color: var(--color-muted);
                        font-family: 'Courier New', monospace; }
        .col-users { font-size: 12px; }
        .col-users .arrow { color: var(--color-muted); margin: 0 4px; }
        .col-users .user-tag { display: inline-block; padding: 1px 6px;
                               border-radius: 2px; font-weight: 500; }
        .col-users .complainant { background: #fee2e2; color: #b91c1c; }
        .col-users .respondent  { background: #dbeafe; color: #1e40af; }
        .col-status { font-size: 12px; }
        .col-status .badge { padding: 3px 10px; border-radius: 12px; font-weight: 500; }
        .col-actions { display: flex; gap: 6px; justify-content: flex-end; }
        .col-actions button { padding: 6px 14px; border: none; border-radius: 4px;
                              font-size: 12px; cursor: pointer; font-weight: 500;
                              transition: all 0.15s; }
        .btn-approve { background: #d1fae5; color: #047857; }
        .btn-approve:hover { background: #10b981; color: #fff; }
        .btn-reject { background: #fee2e2; color: #b91c1c; }
        .btn-reject:hover { background: #ef4444; color: #fff; }
        .btn-done { padding: 6px 12px; background: #f3f4f6; color: #6b7280; border-radius: 4px;
                    font-size: 12px; }

        .reason-block { background: #fef3c7; border-left: 3px solid #f59e0b;
                        padding: 8px 12px; border-radius: 4px; font-size: 12px;
                        color: #92400e; line-height: 1.5; }
        .reason-block i { color: #f59e0b; margin-right: 4px; }
        .result-block { background: #f3f4f6; padding: 6px 10px; border-radius: 4px;
                        font-size: 12px; color: var(--color-text-sub); }
        .evidence-block { background: #f0f9ff; padding: 4px 8px; border-radius: 4px;
                          font-size: 11px; color: #1e40af; margin-top: 4px; word-break: break-all; }
        .evidence-block a { color: #1e40af; }

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

        .modal { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000;
                 display: none; align-items: center; justify-content: center; }
        .modal.show { display: flex; }
        .modal-content { background: #fff; border-radius: 10px; padding: 28px;
                         width: 90%; max-width: 480px; }
        .modal-title { font-size: 17px; font-weight: 700; margin-bottom: 8px;
                       display: flex; align-items: center; gap: 8px; }
        .modal-title.approve { color: #047857; }
        .modal-title.reject { color: #b91c1c; }
        .modal-sub { font-size: 12px; color: var(--color-muted); margin-bottom: 18px; }
        .modal-sub .mono { font-family: 'Courier New', monospace; color: var(--color-text); }
        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-size: 13px; color: var(--color-text-sub);
                      margin-bottom: 6px; font-weight: 500; }
        .form-textarea { width: 100%; padding: 9px 12px; border: 1px solid var(--color-border);
                         border-radius: 6px; font-size: 14px; outline: none;
                         transition: border-color 0.15s; font-family: inherit;
                         min-height: 100px; resize: vertical; box-sizing: border-box; }
        .form-textarea:focus { border-color: var(--color-primary); }
        .modal-actions { display: flex; gap: 8px; margin-top: 20px;
                         padding-top: 16px; border-top: 1px solid var(--color-border-soft); }
        .modal-actions button { flex: 1; padding: 10px; border: none; border-radius: 6px;
                                font-size: 14px; font-weight: 600; cursor: pointer; }
        .btn-modal-cancel { background: #f3f4f6; color: var(--color-text); }
        .btn-modal-cancel:hover { background: #e5e7eb; }
        .btn-modal-approve { background: #10b981; color: #fff; }
        .btn-modal-approve:hover { background: #059669; }
        .btn-modal-reject { background: #ef4444; color: #fff; }
        .btn-modal-reject:hover { background: #dc2626; }
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
            <a href="<%=ctx%>/admin/refund?action=list">
                <i class="fa fa-undo"></i> 退款审批
            </a>
            <a href="<%=ctx%>/admin/complaint?action=list" class="active">
                <i class="fa fa-flag"></i> 投诉审批
                <% if (pendingCount != null && pendingCount > 0) { %>
                    <span class="badge"><%= pendingCount %></span>
                <% } %>
            </a>
            <a href="<%=ctx%>/admin/item?action=list">
                <i class="fa fa-gavel"></i> 拍品
            </a>
            <a href="<%=ctx%>/admin/user?action=list">
                <i class="fa fa-users"></i> 用户
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
        <div class="page-head-icon"><i class="fa fa-flag"></i></div>
        <div class="page-head-info">
            <div class="page-head-title">投诉审批</div>
            <div class="page-head-sub">处理用户的投诉申请，1-3 个工作日内审核，处理结果会通过站内信通知投诉人</div>
        </div>
        <% if (pendingCount != null && pendingCount > 0) { %>
            <div class="page-head-stat">
                <i class="fa fa-bell"></i>
                待处理 <span class="num"><%= pendingCount %></span> 单
            </div>
        <% } %>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <div class="filter-bar">
        <a href="<%=ctx%>/admin/complaint?action=list&status=0" class="filter-tab <%= status != null && status == 0 ? "active" : "" %>">
            待处理 <span class="count">(<%= pendingCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/complaint?action=list&status=2" class="filter-tab <%= status != null && status == 2 ? "active" : "" %>">
            已处理
        </a>
        <a href="<%=ctx%>/admin/complaint?action=list&status=3" class="filter-tab <%= status != null && status == 3 ? "active" : "" %>">
            已驳回
        </a>
        <a href="<%=ctx%>/admin/complaint?action=list" class="filter-tab <%= status == null ? "active" : "" %>">
            全部
        </a>
        <form class="filter-search" method="get" action="<%=ctx%>/admin/complaint">
            <input type="hidden" name="action" value="list">
            <% if (status != null) { %>
                <input type="hidden" name="status" value="<%= status %>">
            <% } %>
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索投诉原因">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
    </div>

    <div v-if="rows.length > 0" class="order-table">
        <div class="order-row head">
            <div>封面</div>
            <div>投诉 / 拍品</div>
            <div>投诉人 → 被投诉人</div>
            <div>状态</div>
            <div style="text-align: right;">操作</div>
        </div>
        <div v-for="c in rows" :key="c.id" class="order-row">
            <div class="col-cover" :style="c.coverImage ? 'background-image:url(' + c.coverImage + '); background-size:cover; background-position:center;' : ''">
                <i v-if="!c.coverImage" class="fa fa-image"></i>
            </div>
            <div class="col-info">
                <div class="col-info-body">
                    <div class="col-info-title">{{ c.itemTitle }}</div>
                    <div class="col-info-sub">{{ c.orderNo }}</div>
                    <div v-if="c.status === 0 || c.status === 1" class="reason-block" style="margin-top: 6px;">
                        <i class="fa fa-commenting-o"></i> 投诉原因：{{ c.reason }}
                        <div v-if="c.evidence" class="evidence-block">
                            <i class="fa fa-paperclip"></i> 证据：<a :href="c.evidence" target="_blank">{{ c.evidence }}</a>
                        </div>
                    </div>
                    <div v-else class="result-block" style="margin-top: 6px;">
                        <i class="fa fa-check-circle"></i> 处理结果：{{ c.handleResult }}
                    </div>
                </div>
            </div>
            <div class="col-users">
                <span class="user-tag complainant">{{ c.complainantUsername }}</span>
                <span class="arrow">→</span>
                <span class="user-tag respondent">{{ c.respondentUsername }}</span>
            </div>
            <div class="col-status">
                <span :class="['badge', 'badge-' + badge(c.status)]">{{ c.statusText }}</span>
                <div style="font-size: 11px; color: var(--color-muted); margin-top: 4px;">
                    {{ formatTime(c.createTime) }}
                </div>
            </div>
            <div class="col-actions">
                <button v-if="c.status === 0 || c.status === 1" class="btn-approve" @click="openApprove(c)">
                    <i class="fa fa-check"></i> 处理
                </button>
                <button v-if="c.status === 0 || c.status === 1" class="btn-reject" @click="openReject(c)">
                    <i class="fa fa-times"></i> 驳回
                </button>
                <span v-else class="btn-done"><i class="fa fa-check-circle"></i> 已处理</span>
            </div>
        </div>
    </div>

    <div v-else class="order-table">
        <div class="empty-state">
            <i class="fa fa-inbox"></i>
            <p>暂无投诉记录</p>
        </div>
    </div>

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

    <div :class="['modal', { show: modalOpen }]" @click.self="closeModal">
        <div class="modal-content">
            <div :class="['modal-title', modalMode]">
                <i :class="['fa', modalMode === 'approve' ? 'fa-check-circle' : 'fa-times-circle']"></i>
                {{ modalMode === 'approve' ? '处理投诉' : '驳回投诉' }}
            </div>
            <div class="modal-sub">
                投诉人 <span class="mono">{{ currentCpl ? currentCpl.complainantUsername : '' }}</span>
                → 被投诉人 <span class="mono">{{ currentCpl ? currentCpl.respondentUsername : '' }}</span>
                <br>订单 <span class="mono">{{ currentCpl ? currentCpl.orderNo : '' }}</span>
            </div>
            <form @submit.prevent="submitForm">
                <div class="form-group">
                    <label class="form-label">处理说明（投诉人可见）</label>
                    <textarea v-model="form.result" class="form-textarea" maxlength="500"
                              :placeholder="modalMode === 'approve' ? '例如：已核实情况属实，对被投诉人发出警告' : '例如：经核实无法证明被投诉人违规，投诉不成立'"></textarea>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeModal">取消</button>
                    <button type="submit" :disabled="submitting"
                            :class="modalMode === 'approve' ? 'btn-modal-approve' : 'btn-modal-reject'">
                        {{ submitting ? '处理中...' : (modalMode === 'approve' ? '确认处理' : '确认驳回') }}
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
    const ctxPath  = '<%=ctx%>';
    const rowsInit = <%= rowsJson %>;
    const total    = <%= total %>;
    const pageNoInit = <%= pageNo %>;
    const totalPages = <%= totalPages %>;

    loadVue().then(() => {
        const { createApp, ref, reactive, computed } = Vue;
        createApp({
            setup() {
                const rows = ref(rowsInit);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);

                const modalOpen = ref(false);
                const modalMode = ref('approve');
                const currentCpl = ref(null);
                const submitting = ref(false);
                const form = reactive({ result: '' });

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
                    const statusEl = document.querySelector('input[name="status"]');
                    if (statusEl) params.set('status', statusEl.value);
                    const kw = document.querySelector('input[name="keyword"]');
                    if (kw && kw.value) params.set('keyword', kw.value);
                    return ctxPath + '/admin/complaint?' + params.toString();
                }
                function badge(s) {
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
                function openApprove(c) {
                    currentCpl.value = c;
                    modalMode.value = 'approve';
                    form.result = '已核实情况属实，投诉成立';
                    modalOpen.value = true;
                }
                function openReject(c) {
                    currentCpl.value = c;
                    modalMode.value = 'reject';
                    form.result = '经核实无法证明被投诉人违规，投诉不成立';
                    modalOpen.value = true;
                }
                function closeModal() {
                    modalOpen.value = false;
                    form.result = '';
                    currentCpl.value = null;
                }
                function submitForm() {
                    if (submitting.value || !currentCpl.value) return;
                    submitting.value = true;
                    const params = new URLSearchParams();
                    params.append('id', currentCpl.value.id);
                    params.append('status', modalMode.value === 'approve' ? 2 : 3);
                    params.append('result', form.result || '');
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/complaint?action=process', params)
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '操作成功', 'success');
                                    closeModal();
                                    setTimeout(() => location.reload(), 600);
                                } else {
                                    toast(r.data.message || '操作失败', 'error');
                                }
                                submitting.value = false;
                            })
                            .catch(() => {
                                toast('网络错误', 'error');
                                submitting.value = false;
                            });
                    });
                }
                return { rows, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef,
                         pagesToShow, modalOpen, modalMode, currentCpl, form, submitting,
                         pageHref, badge, formatTime, openApprove, openReject, closeModal, submitForm };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
