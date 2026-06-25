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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* 复用 admin 模块的暗色顶栏样式 */
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
                          background: #fef3c7; color: #b45309;
                          display: grid; place-items: center; font-size: 22px; }
        .page-head-info { flex: 1; }
        .page-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); }
        .page-head-stat { display: flex; gap: 6px; align-items: center; padding: 8px 16px;
                          background: #fef3c7; color: #b45309; border-radius: 6px;
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
        .filter-divider { width: 1px; height: 20px; background: #e5e7eb; margin: 0 4px; }
        .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .filter-search input, .filter-search select { padding: 6px 12px; border: 1px solid var(--color-border);
                                                       border-radius: 4px; font-size: 13px; outline: none; }
        .filter-search input { width: 200px; }
        .filter-search input:focus, .filter-search select:focus { border-color: var(--color-primary); }
        .filter-search button { padding: 6px 14px; background: var(--color-primary); color: #fff;
                                border: none; border-radius: 4px; font-size: 13px; cursor: pointer; }

        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        .item-table { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 12px; overflow: hidden; }
        .item-row { display: grid; grid-template-columns: 70px 1fr 200px 130px 130px 200px;
                     gap: 14px; padding: 14px 20px; align-items: center;
                     border-bottom: 1px solid var(--color-border-soft); }
        .item-row:last-child { border-bottom: none; }
        .item-row.head { background: #f9fafb; font-size: 12px; color: var(--color-muted);
                          font-weight: 600; padding: 10px 20px; }
        .col-cover { width: 60px; height: 60px; border-radius: 4px; background: #f3f4f6;
                     display: grid; place-items: center; color: #9ca3af; overflow: hidden;
                     flex-shrink: 0; }
        .col-cover img { width: 100%; height: 100%; object-fit: cover; }
        .col-info { min-width: 0; }
        .col-info-title { font-size: 13px; font-weight: 600; color: var(--color-text);
                          margin-bottom: 2px;
                          overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .col-info-sub { font-size: 11px; color: var(--color-muted); }
        .col-info-sub .views { color: var(--color-primary); }
        .col-user { font-size: 12px; }
        .col-user .username { font-weight: 500; }
        .col-user .uid { color: var(--color-muted); font-size: 11px; }
        .col-cat { font-size: 12px; }
        .col-cat .badge { padding: 2px 8px; border-radius: 3px; font-size: 11px;
                          background: #e0e7ff; color: #4338ca; }
        .col-price { font-size: 15px; font-weight: 700; color: var(--color-primary); }
        .col-price small { font-size: 10px; margin-right: 1px; }
        .col-status .badge { padding: 3px 10px; border-radius: 12px; font-weight: 500;
                             font-size: 11px; }
        .col-actions { display: flex; gap: 4px; justify-content: flex-end; flex-wrap: wrap; }
        .col-actions button { padding: 5px 10px; border: 1px solid var(--color-border);
                              border-radius: 3px; font-size: 12px; cursor: pointer;
                              background: #fff; color: var(--color-text-sub);
                              transition: all 0.15s; }
        .col-actions button:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .col-actions .danger:hover { border-color: var(--color-danger); color: var(--color-danger); }

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
        .modal-sub { font-size: 12px; color: var(--color-muted); margin-bottom: 18px;
                    line-height: 1.5; }
        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-size: 13px; color: var(--color-text-sub);
                      margin-bottom: 6px; font-weight: 500; }
        .form-select { width: 100%; padding: 9px 12px; border: 1px solid var(--color-border);
                       border-radius: 6px; font-size: 14px; outline: none;
                       background: #fff; font-family: inherit; }
        .form-select:focus { border-color: var(--color-primary); }
        .modal-actions { display: flex; gap: 8px; margin-top: 20px;
                         padding-top: 16px; border-top: 1px solid var(--color-border-soft); }
        .modal-actions button { flex: 1; padding: 10px; border: none; border-radius: 6px;
                                font-size: 14px; font-weight: 600; cursor: pointer; }
        .btn-modal-cancel { background: #f3f4f6; color: var(--color-text); }
        .btn-modal-confirm { background: var(--color-primary); color: #fff; }
        .btn-modal-confirm:hover { background: var(--color-primary-hover); }
        .btn-modal-danger { background: #ef4444; color: #fff; }
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
            <a href="<%=ctx%>/admin/item?action=list" class="active">
                <i class="fa fa-gavel"></i> 拍品管理
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
        <div class="page-head-icon"><i class="fa fa-gavel"></i></div>
        <div class="page-head-info">
            <div class="page-head-title">拍品管理</div>
            <div class="page-head-sub">查看所有拍品、改状态、改分类、强制下架。仅 status=1 拍卖中可被用户出价。</div>
        </div>
        <div class="page-head-stat">
            <i class="fa fa-bolt"></i>
            拍卖中 <span class="num"><%= activeCount %></span> / 共 <span class="num"><%= totalCount %></span>
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

        <select name="category" class="form-select" style="width: auto; padding: 5px 10px; font-size: 13px;" onchange="this.form.submit()">
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
    <div v-if="rows.length > 0" class="item-table">
        <div class="item-row head">
            <div>封面</div>
            <div>拍品 / 浏览</div>
            <div>卖家</div>
            <div>分类</div>
            <div>当前价</div>
            <div style="text-align: right;">操作</div>
        </div>
        <div v-for="r in rows" :key="r.id" class="item-row">
            <div class="col-cover" :style="r.coverImage ? 'background-image:url(' + r.coverImage + '); background-size:cover; background-position:center;' : ''">
                <i v-if="!r.coverImage" class="fa fa-image"></i>
            </div>
            <div class="col-info">
                <a :href="ctxPath + '/item?action=detail&id=' + r.id" target="_blank" class="col-info-title" style="text-decoration: none; color: inherit;">
                    {{ r.title }}
                </a>
                <div class="col-info-sub">
                    ID: {{ r.id }}
                    <span class="views"><i class="fa fa-eye"></i> {{ r.viewCount }}</span>
                </div>
            </div>
            <div class="col-user">
                <div class="username">{{ r.sellerUsername }}</div>
                <div class="uid">ID: {{ r.sellerId }}</div>
            </div>
            <div class="col-cat">
                <span class="badge">{{ r.categoryName }}</span>
            </div>
            <div class="col-price">
                <small>¥</small>{{ formatPrice(r.currentPrice) }}
            </div>
            <div class="col-status" style="text-align: right;">
                <span :class="['badge', 'badge-' + badge(r.status)]">{{ statusText(r.status) }}</span>
            </div>
            <div class="col-actions" style="text-align: right;">
                <button @click="openStatusModal(r)"><i class="fa fa-pencil"></i> 改状态</button>
                <button @click="openCategoryModal(r)"><i class="fa fa-tag"></i> 改分类</button>
                <button v-if="r.status !== 4" class="danger" @click="removeItem(r)">
                    <i class="fa fa-trash-o"></i> 下架
                </button>
            </div>
        </div>
    </div>

    <div v-else class="item-table">
        <div class="empty-state">
            <i class="fa fa-inbox"></i>
            <p>暂无符合条件的拍品</p>
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

    <!-- 改状态弹窗 -->
    <div :class="['modal', { show: statusModalOpen }]" @click.self="closeStatusModal">
        <div class="modal-content">
            <div class="modal-title"><i class="fa fa-pencil"></i> 改状态</div>
            <div class="modal-sub">
                当前拍品：<strong>{{ currentRow ? currentRow.title : '' }}</strong>
                · 当前状态：<span :class="['badge', 'badge-' + badge(currentRow ? currentRow.status : 0)]">
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
                <div class="modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeStatusModal">取消</button>
                    <button type="submit" class="btn-modal-confirm" :disabled="statusSubmitting">
                        {{ statusSubmitting ? '处理中...' : '确认修改' }}
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- 改分类弹窗 -->
    <div :class="['modal', { show: categoryModalOpen }]" @click.self="closeCategoryModal">
        <div class="modal-content">
            <div class="modal-title"><i class="fa fa-tag"></i> 改分类</div>
            <div class="modal-sub">
                当前拍品：<strong>{{ currentRow ? currentRow.title : '' }}</strong>
                · 当前分类：<span class="badge" style="background: #e0e7ff; color: #4338ca;">
                    {{ currentRow ? currentRow.categoryName : '' }}
                </span>
            </div>
            <form @submit.prevent="submitCategory">
                <div class="form-group">
                    <label class="form-label">新分类</label>
                    <select v-model="newCategoryId" class="form-select" required>
                        <option value="">请选择分类</option>
                        <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.categoryName }}</option>
                    </select>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeCategoryModal">取消</button>
                    <button type="submit" class="btn-modal-confirm" :disabled="categorySubmitting">
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
