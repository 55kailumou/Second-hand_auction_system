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

    String noticesJson = (String) request.getAttribute("noticesJson");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("pageNo");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer status = (Integer) request.getAttribute("status");
    String keyword = (String) request.getAttribute("keyword");
    Integer draftCount = (Integer) request.getAttribute("draftCount");
    Integer publishedCount = (Integer) request.getAttribute("publishedCount");
    Integer retractedCount = (Integer) request.getAttribute("retractedCount");
    Integer topCount = (Integer) request.getAttribute("topCount");
    String error = (String) request.getAttribute("error");
    if (noticesJson == null) noticesJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (keyword == null) keyword = "";
    if (draftCount == null) draftCount = 0;
    if (publishedCount == null) publishedCount = 0;
    if (retractedCount == null) retractedCount = 0;
    if (topCount == null) topCount = 0;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>公告管理 · 管理后台</title>
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
                          background: #fee2e2; color: #b91c1c;
                          display: grid; place-items: center; font-size: 22px; }
        .page-head-info { flex: 1; }
        .page-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); }
        .page-head-stat { display: flex; gap: 6px; align-items: center; padding: 8px 16px;
                          background: #fee2e2; color: #b91c1c; border-radius: 6px;
                          font-size: 13px; font-weight: 600; }
        .page-head-stat .num { font-size: 18px; }

        .toolbar { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                   margin-top: 12px; padding: 12px 20px;
                   display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
        .filter-tab { padding: 6px 12px; font-size: 13px; color: var(--color-text-sub);
                      text-decoration: none; border-radius: 4px; transition: all 0.15s; font-weight: 500; }
        .filter-tab:hover { color: var(--color-primary); background: #f9fafb; }
        .filter-tab.active { color: #fff; background: var(--color-primary); font-weight: 600; }
        .filter-tab .count { margin-left: 4px; font-size: 12px; opacity: 0.85; }
        .toolbar .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .toolbar input { padding: 6px 12px; border: 1px solid var(--color-border);
                         border-radius: 4px; font-size: 13px; outline: none; width: 220px; }
        .toolbar input:focus { border-color: var(--color-primary); }
        .toolbar button { padding: 6px 14px; border: none; border-radius: 4px;
                          font-size: 13px; cursor: pointer; }
        .toolbar button.search { background: var(--color-primary); color: #fff; }
        .toolbar button.add { background: var(--color-primary); color: #fff; }

        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        .notice-table { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                        margin-top: 12px; overflow: hidden; }
        .notice-row { display: grid;
                       grid-template-columns: 60px 1fr 180px 100px 140px 240px;
                       gap: 14px; padding: 14px 20px; align-items: center;
                       border-bottom: 1px solid var(--color-border-soft); }
        .notice-row:last-child { border-bottom: none; }
        .notice-row.head { background: #f9fafb; font-size: 12px; color: var(--color-muted);
                            font-weight: 600; padding: 10px 20px; }
        .col-id { font-size: 12px; color: var(--color-muted); }
        .col-title { font-size: 13px; font-weight: 600; color: var(--color-text);
                      display: flex; align-items: center; gap: 6px; min-width: 0; }
        .col-title .title-text { overflow: hidden; text-overflow: ellipsis;
                                  white-space: nowrap; flex: 1; min-width: 0; }
        .col-title .top-tag { padding: 1px 6px; background: #ef4444; color: #fff;
                                font-size: 10px; border-radius: 3px; font-weight: 600; flex-shrink: 0; }
        .col-content { font-size: 12px; color: var(--color-muted);
                       overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
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
                         width: 90%; max-width: 600px; }
        .modal-title { font-size: 17px; font-weight: 700; margin-bottom: 8px;
                       display: flex; align-items: center; gap: 8px; color: #b91c1c; }
        .modal-sub { font-size: 12px; color: var(--color-muted); margin-bottom: 18px; line-height: 1.5; }
        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-size: 13px; color: var(--color-text-sub);
                      margin-bottom: 6px; font-weight: 500; }
        .form-input, .form-select, .form-textarea { width: 100%; padding: 9px 12px;
                                                     border: 1px solid var(--color-border);
                                                     border-radius: 6px; font-size: 14px;
                                                     outline: none; font-family: inherit;
                                                     box-sizing: border-box; background: #fff; }
        .form-input:focus, .form-select:focus, .form-textarea:focus { border-color: var(--color-primary); }
        .form-textarea { resize: vertical; min-height: 160px; line-height: 1.6; }
        .form-hint { font-size: 11px; color: var(--color-muted); margin-top: 4px; }
        .form-checkbox { display: flex; align-items: center; gap: 6px; font-size: 13px; }
        .form-checkbox input { width: auto; }
        .modal-actions { display: flex; gap: 8px; margin-top: 20px;
                         padding-top: 16px; border-top: 1px solid var(--color-border-soft); }
        .modal-actions button { flex: 1; padding: 10px; border: none; border-radius: 6px;
                                font-size: 14px; font-weight: 600; cursor: pointer; }
        .btn-modal-cancel { background: #f3f4f6; color: var(--color-text); }
        .btn-modal-confirm { background: var(--color-primary); color: #fff; }

        .badge-success { background: #d1fae5; color: #047857; }
        .badge-warning { background: #fef3c7; color: #b45309; }
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
            <a href="<%=ctx%>/admin/user?action=list"><i class="fa fa-users"></i> 用户管理</a>
            <a href="<%=ctx%>/admin/category?action=list"><i class="fa fa-sitemap"></i> 分类管理</a>
            <a href="<%=ctx%>/admin/announcement?action=list" class="active">
                <i class="fa fa-bullhorn"></i> 公告
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
        <div class="page-head-icon"><i class="fa fa-bullhorn"></i></div>
        <div class="page-head-info">
            <div class="page-head-title">公告管理</div>
            <div class="page-head-sub">发布/撤回/置顶系统公告。新增默认草稿，需手动点"发布"才能在前台显示。</div>
        </div>
        <div class="page-head-stat">
            <i class="fa fa-check-circle"></i>
            已发布 <span class="num"><%= publishedCount %></span> · 置顶 <span class="num" style="color: #ef4444;"><%= topCount %></span>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <form class="toolbar" method="get" action="<%=ctx%>/admin/announcement">
        <input type="hidden" name="action" value="list">

        <a href="<%=ctx%>/admin/announcement?action=list" class="filter-tab <%= status == null ? "active" : "" %>">
            全部 <span class="count">(<%= draftCount + publishedCount + retractedCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/announcement?action=list&status=1" class="filter-tab <%= status != null && status == 1 ? "active" : "" %>">
            已发布 <span class="count">(<%= publishedCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/announcement?action=list&status=0" class="filter-tab <%= status != null && status == 0 ? "active" : "" %>">
            草稿 <span class="count">(<%= draftCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/announcement?action=list&status=2" class="filter-tab <%= status != null && status == 2 ? "active" : "" %>">
            已撤回 <span class="count">(<%= retractedCount %>)</span>
        </a>

        <button type="button" class="add" @click="openCreateModal" style="margin-left: 12px;">
            <i class="fa fa-plus"></i> 新增公告
        </button>

        <div class="filter-search">
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索标题 / 内容">
            <button type="submit" class="search"><i class="fa fa-search"></i> 搜索</button>
        </div>
    </form>

    <div v-if="notices.length > 0" class="notice-table">
        <div class="notice-row head">
            <div>ID</div>
            <div>标题</div>
            <div>发布时间</div>
            <div style="text-align: center;">置顶</div>
            <div style="text-align: center;">状态</div>
            <div style="text-align: right;">操作</div>
        </div>
        <div v-for="n in notices" :key="n.id" class="notice-row">
            <div class="col-id">&#35;{{ n.id }}</div>
            <div class="col-title">
                <span v-if="n.isTop === 1" class="top-tag">置顶</span>
                <span class="title-text">{{ n.title }}</span>
            </div>
            <div class="col-content">{{ n.publishTime || '-' }}</div>
            <div class="col-status" style="text-align: center;">
                <span v-if="n.isTop === 1" style="color: #ef4444;"><i class="fa fa-thumb-tack"></i> 置顶</span>
                <span v-else style="color: var(--color-muted);">-</span>
            </div>
            <div class="col-status" style="text-align: center;">
                <span :class="['badge', badge(n.status)]">{{ statusText(n.status) }}</span>
            </div>
            <div class="col-actions">
                <button @click="openEditModal(n)"><i class="fa fa-pencil"></i> 编辑</button>
                <button v-if="n.status !== 1" class="danger" @click="publishNotice(n)">
                    <i class="fa fa-check"></i> 发布
                </button>
                <button v-else @click="retractNotice(n)">
                    <i class="fa fa-undo"></i> 撤回
                </button>
                <button v-if="n.isTop !== 1" @click="setTop(n)">
                    <i class="fa fa-thumb-tack"></i> 置顶
                </button>
                <button v-else @click="unsetTop(n)">
                    <i class="fa fa-thumb-tack" style="color: #ef4444;"></i> 取消置顶
                </button>
                <button class="danger" @click="deleteNotice(n)">
                    <i class="fa fa-trash-o"></i> 删除
                </button>
            </div>
        </div>
    </div>

    <div v-else class="notice-table">
        <div class="empty-state">
            <i class="fa fa-bullhorn"></i>
            <p>暂无公告</p>
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

    <!-- 新增/编辑弹窗 -->
    <div :class="['modal', { show: modalOpen }]" @click.self="closeModal">
        <div class="modal-content">
            <div class="modal-title">
                <i :class="form.id ? 'fa fa-pencil' : 'fa fa-plus'"></i>
                {{ form.id ? '编辑公告' : '新增公告' }}
            </div>
            <div class="modal-sub">标题不超过 100 字，内容不超过 5000 字。新增后默认为草稿状态。</div>
            <form @submit.prevent="submit">
                <div class="form-group">
                    <label class="form-label">标题 <span style="color: var(--color-danger);">*</span></label>
                    <input type="text" v-model="form.title" class="form-input"
                           maxlength="100" placeholder="公告标题" required>
                </div>
                <div class="form-group">
                    <label class="form-label">内容 <span style="color: var(--color-danger);">*</span></label>
                    <textarea v-model="form.content" class="form-textarea"
                              maxlength="5000" placeholder="公告内容（支持换行）" required></textarea>
                    <div class="form-hint">纯文本 + 换行。前台会保留换行展示（&lt;br&gt;）。</div>
                </div>
                <div class="form-group">
                    <label class="form-checkbox">
                        <input type="checkbox" v-model="form.isTopBool" :true-value="true" :false-value="false">
                        置顶（仅对已发布公告生效）
                    </label>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeModal">取消</button>
                    <button type="submit" class="btn-modal-confirm" :disabled="submitting">
                        {{ submitting ? '提交中...' : '确认保存' }}
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
    const initJson = <%= noticesJson %>;
    const total    = <%= total %>;
    const pageNoInit = <%= pageNo %>;
    const totalPages = <%= totalPages %>;

    loadVue().then(() => {
        const { createApp, ref, reactive, computed } = Vue;
        createApp({
            setup() {
                const notices = ref(initJson);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);

                const modalOpen = ref(false);
                const submitting = ref(false);
                const form = reactive({
                    id: null,
                    title: '',
                    content: '',
                    isTopBool: false
                });

                const pagesToShow = computed(() => {
                    const t = totalPagesRef.value;
                    const c = pageNoRef.value;
                    const arr = [];
                    const start = Math.max(1, c - 2);
                    const end = Math.min(t, c + 2);
                    for (let i = start; i <= end; i++) arr.push(i);
                    return arr;
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
                    return ctxPath + '/admin/announcement?' + params.toString();
                }

                function badge(s) {
                    switch (s) {
                        case 0: return 'gray';
                        case 1: return 'success';
                        case 2: return 'danger';
                        default: return 'gray';
                    }
                }
                function statusText(s) {
                    switch (s) {
                        case 0: return '草稿';
                        case 1: return '已发布';
                        case 2: return '已撤回';
                        default: return '未知';
                    }
                }

                function openCreateModal() {
                    form.id = null;
                    form.title = '';
                    form.content = '';
                    form.isTopBool = false;
                    modalOpen.value = true;
                }
                function openEditModal(n) {
                    form.id = n.id;
                    form.title = n.title;
                    form.content = n.content;
                    form.isTopBool = n.isTop === 1;
                    modalOpen.value = true;
                }
                function closeModal() { modalOpen.value = false; }

                function submit() {
                    if (submitting.value) return;
                    if (!form.title || !form.title.trim()) { toast('请填写标题', 'error'); return; }
                    if (!form.content || !form.content.trim()) { toast('请填写内容', 'error'); return; }
                    submitting.value = true;
                    const params = new URLSearchParams();
                    params.append('title', form.title.trim());
                    params.append('content', form.content.trim());
                    params.append('isTop', form.isTopBool ? 1 : 0);
                    const url = form.id
                        ? ctxPath + '/admin/announcement?action=update&id=' + form.id
                        : ctxPath + '/admin/announcement?action=create';
                    loadAxios().then(() => {
                        axios.post(url, params).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '保存成功', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                            submitting.value = false;
                        }).catch(() => { toast('网络错误', 'error'); submitting.value = false; });
                    });
                }

                function publishNotice(n) {
                    if (!confirm('确定发布公告「' + n.title + '」？\n发布后会在前台显示。')) return;
                    setStatus(n, 1);
                }
                function retractNotice(n) {
                    if (!confirm('确定撤回公告「' + n.title + '」？\n撤回后前台不再显示。')) return;
                    setStatus(n, 2);
                }
                function setStatus(n, status) {
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/announcement?action=set-status', new URLSearchParams({
                            id: n.id, status: status
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '操作成功', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                function setTop(n) {
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/announcement?action=set-top', new URLSearchParams({
                            id: n.id, isTop: 1
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已置顶', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }
                function unsetTop(n) {
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/announcement?action=set-top', new URLSearchParams({
                            id: n.id, isTop: 0
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已取消置顶', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                function deleteNotice(n) {
                    if (!confirm('确定删除公告「' + n.title + '」？\n此操作不可撤销。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/announcement?action=delete', new URLSearchParams({
                            id: n.id
                        })).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已删除', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '删除失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                return { notices, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef,
                         pagesToShow, modalOpen, submitting, form,
                         pageHref, badge, statusText,
                         openCreateModal, openEditModal, closeModal, submit,
                         publishNotice, retractNotice, setTop, unsetTop, deleteNotice };
            }
        }).mount('#app');
    });
</script>
</body>
</html>