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
    Integer categoryId = (Integer) request.getAttribute("categoryId");
    String keyword = (String) request.getAttribute("keyword");
    Integer totalCount = (Integer) request.getAttribute("totalCount");
    Integer activeCount = (Integer) request.getAttribute("activeCount");
    java.util.List<org.example.entity.Category> categories =
            (java.util.List<org.example.entity.Category>) request.getAttribute("categories");
    String error = (String) request.getAttribute("error");
    if (rowsJson == null) rowsJson = "[]";
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (keyword == null) keyword = "";
    if (totalCount == null) totalCount = 0;
    if (activeCount == null) activeCount = 0;
    if (categories == null) categories = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>拍品管理 · 管理后台</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        .admin-main { max-width: 1400px; margin: 24px auto 0; padding: 0 24px 60px; position: relative; z-index: 3; }

        .admin-main .cp-page-head { margin: 0 0 16px; }

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
        .filter-divider { width: 1px; height: 20px; background: var(--cp-yellow-dim); margin: 0 4px; }
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input, .filter-search select {
            padding: 6px 12px;
            font-size: 12px;
            color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none;
            font-family: var(--font-mono);
        }
        .filter-search input { width: 200px; }
        .filter-search input:focus, .filter-search select:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }
        .filter-search input::placeholder { color: var(--cp-text-dim); }
        .filter-search select option { background: #000; color: var(--cp-yellow); }
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

        .alert { padding: 10px 16px; font-family: var(--font-mono); font-size: 11px; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.05em; }
        .alert-warning { background: rgba(255,238,0,0.1); color: var(--cp-yellow); border: 1px solid var(--cp-yellow-dim); }

        .cp-table td, .cp-table th { white-space: nowrap; }
        .cp-table td { vertical-align: middle; }

        .col-cover {
            width: 50px; height: 50px;
            background: rgba(255,238,0,0.05);
            display: grid; place-items: center;
            color: var(--cp-text-dim); overflow: hidden;
            border: 1px solid var(--cp-yellow-dim);
            clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%);
        }
        .col-cover img { width: 100%; height: 100%; object-fit: cover; }

        .col-info-title { font-size: 12px; font-weight: 700; color: var(--cp-yellow); text-decoration: none; }
        .col-info-sub { font-size: 10px; color: var(--cp-text-dim); font-family: var(--font-mono); }
        .col-info-sub .views { color: var(--cp-cyan); }

        .empty-state { text-align: center; padding: 60px 20px; font-family: var(--font-mono); font-size: 12px; color: var(--cp-text-dim); }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; color: var(--cp-yellow-dim); }

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

        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-family: var(--font-mono); font-size: 10px; color: var(--cp-yellow-dim); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 6px; }
        .form-select {
            width: 100%; padding: 9px 12px;
            font-size: 13px; color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none; font-family: var(--font-mono);
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath fill='%23FFEE00' d='M6 8L0 0h12z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 12px center;
            padding-right: 32px;
        }
        .form-select option { background: #000; color: var(--cp-yellow); }
        .form-select:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }

        .cp-modal-actions { display: flex; gap: 8px; margin-top: 20px; padding-top: 16px; border-top: 1px solid rgba(255,238,0,0.15); }
        .cp-modal-actions button { flex: 1; padding: 10px; font-size: 12px; font-weight: 700; }
        .btn-modal-cancel { background: rgba(255,238,0,0.1); color: var(--cp-yellow-dim); border: 1px solid var(--cp-yellow-dim); font-family: var(--font-mono); text-transform: uppercase; }
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
            <a href="<%=ctx%>/admin/item?action=list" class="active"><i class="fa fa-gavel"></i> 拍品管理</a>
            <a href="<%=ctx%>/admin/user?action=list"><i class="fa fa-users"></i> 用户</a>
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
            <div class="cp-page-title">拍品管理</div>
            <div class="cp-page-sub">查看所有拍品、改状态、改分类、强制下架。仅 status=1 拍卖中可被用户出价。</div>
        </div>
        <div class="cp-badge cp-badge-yellow" style="font-size: 12px; padding: 6px 14px;">
            <i class="fa fa-bolt"></i>
            拍卖中 <%= activeCount %> / 共 <%= totalCount %>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- tab 筛选 + 搜索 -->
    <form class="filter-bar" method="get" action="<%=ctx%>/admin/item">
        <input type="hidden" name="action" value="list">

        <a href="<%=ctx%>/admin/item?action=list" class="filter-tab <%= status == null ? "active" : "" %>">
            全部 <span class="count">(<%= totalCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/item?action=list&status=1" class="filter-tab <%= status != null && status == 1 ? "active" : "" %>">
            拍卖中
        </a>
        <a href="<%=ctx%>/admin/item?action=list&status=0" class="filter-tab <%= status != null && status == 0 ? "active" : "" %>">
            待审核
        </a>
        <a href="<%=ctx%>/admin/item?action=list&status=2" class="filter-tab <%= status != null && status == 2 ? "active" : "" %>">
            已成交
        </a>
        <a href="<%=ctx%>/admin/item?action=list&status=3" class="filter-tab <%= status != null && status == 3 ? "active" : "" %>">
            已流拍
        </a>
        <a href="<%=ctx%>/admin/item?action=list&status=4" class="filter-tab <%= status != null && status == 4 ? "active" : "" %>">
            已下架
        </a>
        <a href="<%=ctx%>/admin/item?action=list&status=5" class="filter-tab <%= status != null && status == 5 ? "active" : "" %>">
            审核未通过
        </a>

        <div class="filter-divider"></div>

        <select name="category" class="form-select" style="width: auto; padding: 5px 10px; font-size: 11px;" onchange="this.form.submit()">
            <option value="">全部分类</option>
            <% for (org.example.entity.Category c : categories) { %>
                <option value="<%= c.getId() %>" <%= (categoryId != null && categoryId.equals(c.getId())) ? "selected" : "" %>>
                    <%= c.getCategoryName() %>
                </option>
            <% } %>
        </select>

        <div class="filter-search">
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索拍品标题">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </div>
    </form>

    <!-- 列表 -->
    <div v-if="rows.length > 0" class="cp-table-wrap">
        <table class="cp-table">
            <thead>
                <tr>
                    <th style="width: 60px;">封面</th>
                    <th>拍品 / 浏览</th>
                    <th>卖家</th>
                    <th>分类</th>
                    <th>当前价</th>
                    <th style="text-align: right;">操作</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="r in rows" :key="r.id">
                    <td>
                        <div class="col-cover" :style="r.coverImage ? 'background-image:url(' + r.coverImage + '); background-size:cover; background-position:center;' : ''">
                            <i v-if="!r.coverImage" class="fa fa-image"></i>
                        </div>
                    </td>
                    <td>
                        <a :href="ctxPath + '/item?action=detail&id=' + r.id" target="_blank" class="col-info-title">
                            {{ r.title }}
                        </a>
                        <div class="col-info-sub">
                            ID: {{ r.id }}
                            <span class="views"><i class="fa fa-eye"></i> {{ r.viewCount }}</span>
                        </div>
                    </td>
                    <td style="font-family: var(--font-mono); font-size: 11px;">
                        <div style="font-weight: 700; color: var(--cp-yellow);">{{ r.sellerUsername }}</div>
                        <div style="color: var(--cp-text-dim);">ID: {{ r.sellerId }}</div>
                    </td>
                    <td>
                        <span class="cp-badge cp-badge-cyan" style="font-size: 10px;">{{ r.categoryName }}</span>
                    </td>
                    <td style="font-family: var(--font-mono); font-size: 14px; font-weight: 700; color: var(--cp-yellow);">
                        <small style="color: var(--cp-text-dim);">¥</small>{{ formatPrice(r.currentPrice) }}
                    </td>
                    <td style="text-align: right;">
                        <span :class="['cp-badge', badge(r.status) === 'warning' ? 'cp-badge-yellow' : badge(r.status) === 'primary' ? 'cp-badge-cyan' : badge(r.status) === 'success' ? 'cp-badge-yellow' : badge(r.status) === 'danger' ? 'cp-badge-red' : 'cp-badge-dim']" style="margin-right: 4px;">
                            {{ statusText(r.status) }}
                        </span>
                        <button class="action-btn" @click="openStatusModal(r)"><i class="fa fa-pencil"></i> 改状态</button>
                        <button class="action-btn" @click="openCategoryModal(r)"><i class="fa fa-tag"></i> 改分类</button>
                        <button v-if="r.status !== 4" class="action-btn danger" @click="removeItem(r)">
                            <i class="fa fa-trash-o"></i> 下架
                        </button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <div v-else class="cp-table-wrap">
        <div class="empty-state">
            <i class="fa fa-inbox"></i>
            <p>暂无符合条件的拍品</p>
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

    <!-- 改状态弹窗 -->
    <div v-if="statusModalOpen" class="cp-modal-overlay" @click.self="closeStatusModal">
        <div class="cp-modal">
            <div class="cp-modal-title">
                <span><i class="fa fa-pencil"></i> 改状态</span>
                <span class="cp-modal-close" @click="closeStatusModal">&times;</span>
            </div>
            <div class="cp-page-sub" style="margin-bottom: 18px; line-height: 1.5;">
                当前拍品：<strong style="color: var(--cp-yellow);">{{ currentRow ? currentRow.title : '' }}</strong>
                · 当前状态：<span :class="['cp-badge', 'cp-badge-' + (badge(currentRow ? currentRow.status : 0) === 'warning' ? 'yellow' : badge(currentRow ? currentRow.status : 0) === 'primary' ? 'cyan' : badge(currentRow ? currentRow.status : 0) === 'success' ? 'yellow' : badge(currentRow ? currentRow.status : 0) === 'danger' ? 'red' : 'dim')]">
                    {{ statusText(currentRow ? currentRow.status : 0) }}
                </span>
            </div>
            <form @submit.prevent="submitStatus">
                <div class="form-group">
                    <label class="form-label">新状态</label>
                    <select v-model="newStatus" class="form-select">
                        <option value="0">待审核</option>
                        <option value="1">拍卖中</option>
                        <option value="2">已成交</option>
                        <option value="3">已流拍</option>
                        <option value="4">已下架</option>
                        <option value="5">审核未通过</option>
                    </select>
                </div>
                <div class="cp-modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeStatusModal">取消</button>
                    <button type="submit" class="cp-btn cp-btn-sm" :disabled="statusSubmitting">
                        {{ statusSubmitting ? '处理中...' : '确认修改' }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- 改分类弹窗 -->
    <div v-if="categoryModalOpen" class="cp-modal-overlay" @click.self="closeCategoryModal">
        <div class="cp-modal">
            <div class="cp-modal-title">
                <span><i class="fa fa-tag"></i> 改分类</span>
                <span class="cp-modal-close" @click="closeCategoryModal">&times;</span>
            </div>
            <div class="cp-page-sub" style="margin-bottom: 18px; line-height: 1.5;">
                当前拍品：<strong style="color: var(--cp-yellow);">{{ currentRow ? currentRow.title : '' }}</strong>
                · 当前分类：<span class="cp-badge cp-badge-cyan">{{ currentRow ? currentRow.categoryName : '' }}</span>
            </div>
            <form @submit.prevent="submitCategory">
                <div class="form-group">
                    <label class="form-label">新分类</label>
                    <select v-model="newCategoryId" class="form-select" required>
                        <option value="">请选择分类</option>
                        <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.categoryName }}</option>
                    </select>
                </div>
                <div class="cp-modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeCategoryModal">取消</button>
                    <button type="submit" class="cp-btn cp-btn-sm" :disabled="categorySubmitting">
                        {{ categorySubmitting ? '处理中...' : '确认修改' }}
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
    const ctxPath    = '<%=ctx%>';
    const rowsInit   = <%= rowsJson %>;
    const total      = <%= total %>;
    const pageNoInit = <%= pageNo %>;
    const totalPages = <%= totalPages %>;
    const categoriesJson = [
        <% for (int i = 0; i < categories.size(); i++) {
            org.example.entity.Category c = categories.get(i);
            if (i > 0) out.print(",");
        %>
        { id: <%= c.getId() %>, name: '<%= EscapeUtil.js(c.getCategoryName()) %>' }
        <% } %>
    ];

    loadVue().then(() => {
        const { createApp, ref, computed, reactive } = Vue;
        createApp({
            setup() {
                const rows = ref(rowsInit);
                const totalRef = ref(total);
                const pageNoRef = ref(pageNoInit);
                const totalPagesRef = ref(totalPages);
                const categories = ref(categoriesJson);

                const statusModalOpen = ref(false);
                const categoryModalOpen = ref(false);
                const currentRow = ref(null);
                const newStatus = ref(1);
                const newCategoryId = ref('');
                const statusSubmitting = ref(false);
                const categorySubmitting = ref(false);

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
                    const statusEl = document.querySelector('select[name="status"]') || document.querySelector('a.filter-tab.active');
                    // status from tab link
                    const activeTab = document.querySelector('a.filter-tab.active');
                    if (activeTab && activeTab.href) {
                        const u = new URL(activeTab.href);
                        if (u.searchParams.get('status')) {
                            params.set('status', u.searchParams.get('status'));
                        }
                    }
                    const catEl = document.querySelector('select[name="category"]');
                    if (catEl && catEl.value) params.set('category', catEl.value);
                    const kw = document.querySelector('input[name="keyword"]');
                    if (kw && kw.value) params.set('keyword', kw.value);
                    return ctxPath + '/admin/item?' + params.toString();
                }

                function badge(s) {
                    switch (s) {
                        case 0: return 'warning';
                        case 1: return 'primary';
                        case 2: return 'success';
                        case 3: return 'gray';
                        case 4: return 'danger';
                        case 5: return 'danger';
                        default: return 'gray';
                    }
                }
                function statusText(s) {
                    switch (s) {
                        case 0: return '待审核';
                        case 1: return '拍卖中';
                        case 2: return '已成交';
                        case 3: return '已流拍';
                        case 4: return '已下架';
                        case 5: return '审核未通过';
                        default: return '未知';
                    }
                }
                function formatPrice(p) {
                    return Number(p).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }

                function openStatusModal(r) {
                    currentRow.value = r;
                    newStatus.value = r.status;
                    statusModalOpen.value = true;
                }
                function closeStatusModal() { statusModalOpen.value = false; }
                function submitStatus() {
                    if (statusSubmitting.value || !currentRow.value) return;
                    if (parseInt(newStatus.value) === currentRow.value.status) {
                        toast('状态未变化', 'info');
                        return;
                    }
                    statusSubmitting.value = true;
                    const params = new URLSearchParams();
                    params.append('id', currentRow.value.id);
                    params.append('status', newStatus.value);
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/item?action=set-status', params)
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '修改成功', 'success');
                                    setTimeout(() => location.reload(), 500);
                                } else {
                                    toast(r.data.message || '操作失败', 'error');
                                }
                                statusSubmitting.value = false;
                            })
                            .catch(() => { toast('网络错误', 'error'); statusSubmitting.value = false; });
                    });
                }
                function openCategoryModal(r) {
                    currentRow.value = r;
                    newCategoryId.value = r.categoryId || '';
                    categoryModalOpen.value = true;
                }
                function closeCategoryModal() { categoryModalOpen.value = false; }
                function submitCategory() {
                    if (categorySubmitting.value || !currentRow.value) return;
                    if (!newCategoryId.value) { toast('请选择分类', 'error'); return; }
                    if (parseInt(newCategoryId.value) === currentRow.value.categoryId) {
                        toast('分类未变化', 'info');
                        return;
                    }
                    categorySubmitting.value = true;
                    const params = new URLSearchParams();
                    params.append('id', currentRow.value.id);
                    params.append('categoryId', newCategoryId.value);
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/item?action=set-category', params)
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '修改成功', 'success');
                                    setTimeout(() => location.reload(), 500);
                                } else {
                                    toast(r.data.message || '操作失败', 'error');
                                }
                                categorySubmitting.value = false;
                            })
                            .catch(() => { toast('网络错误', 'error'); categorySubmitting.value = false; });
                    });
                }
                function removeItem(r) {
                    if (!confirm('确定要强制下架《' + r.title + '》？\n下架后该拍品对用户不可见，且不能再被出价。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/item?action=remove', null, {
                            params: { id: r.id }
                        }).then(rr => {
                            if (rr.data.success) {
                                toast(rr.data.message || '已下架', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(rr.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                return { rows, total: totalRef, pageNo: pageNoRef, totalPages: totalPagesRef, categories,
                         pagesToShow, statusModalOpen, categoryModalOpen, currentRow,
                         newStatus, newCategoryId, statusSubmitting, categorySubmitting,
                         pageHref, badge, statusText, formatPrice,
                         openStatusModal, closeStatusModal, submitStatus,
                         openCategoryModal, closeCategoryModal, submitCategory,
                         removeItem };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
