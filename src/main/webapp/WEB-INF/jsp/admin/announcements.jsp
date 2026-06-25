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
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        .admin-main { max-width: 1400px; margin: 24px auto 0; padding: 0 24px 60px; position: relative; z-index: 3; }

        .admin-main .cp-page-head { margin: 0 0 16px; }

        .toolbar {
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
        .toolbar .filter-search { margin-left: auto; display: flex; gap: 6px; }
        .toolbar input {
            padding: 6px 12px;
            font-size: 12px;
            color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none;
            font-family: var(--font-mono);
            width: 220px;
        }
        .toolbar input:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }
        .toolbar input::placeholder { color: var(--cp-text-dim); }
        .toolbar button.search {
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

        .col-title { font-weight: 700; }
        .col-title .top-tag {
            padding: 1px 6px; background: var(--cp-red); color: #fff;
            font-size: 9px; font-family: var(--font-mono); font-weight: 700;
            clip-path: polygon(3px 0, 100% 0, calc(100% - 3px) 100%, 0 100%);
            margin-right: 6px;
        }

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
        .form-hint { font-size: 10px; font-family: var(--font-mono); color: var(--cp-text-dim); margin-top: 4px; }
        .form-input, .form-select, .form-textarea {
            width: 100%; padding: 9px 12px;
            font-size: 13px; color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none; font-family: var(--font-mono); box-sizing: border-box;
        }
        .form-input:focus, .form-select:focus, .form-textarea:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }
        .form-textarea { resize: vertical; min-height: 160px; line-height: 1.6; }
        .form-select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath fill='%23FFEE00' d='M6 8L0 0h12z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 12px center;
            padding-right: 32px;
        }
        .form-select option { background: #000; color: var(--cp-yellow); }
        .form-checkbox { display: flex; align-items: center; gap: 6px; font-size: 12px; font-family: var(--font-mono); color: var(--cp-text-dim); }
        .form-checkbox input { width: auto; accent-color: var(--cp-yellow); }

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
            <a href="<%=ctx%>/admin/item?action=list"><i class="fa fa-gavel"></i> 拍品管理</a>
            <a href="<%=ctx%>/admin/user?action=list"><i class="fa fa-users"></i> 用户管理</a>
            <a href="<%=ctx%>/admin/category?action=list"><i class="fa fa-sitemap"></i> 分类管理</a>
            <a href="<%=ctx%>/admin/announcement?action=list" class="active"><i class="fa fa-bullhorn"></i> 公告</a>
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
            <div class="cp-page-title">公告管理</div>
            <div class="cp-page-sub">发布/撤回/置顶系统公告。新增默认草稿，需手动点"发布"才能在前台显示。</div>
        </div>
        <div class="cp-badge cp-badge-yellow" style="font-size: 12px; padding: 6px 14px;">
            <i class="fa fa-check-circle"></i>
            已发布 <%= publishedCount %> · 置顶 <%= topCount %>
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

        <button type="button" class="cp-btn cp-btn-sm" @click="openCreateModal" style="margin-left: 12px;">
            <i class="fa fa-plus"></i> 新增公告
        </button>

        <div class="filter-search">
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>" placeholder="搜索标题 / 内容">
            <button type="submit" class="search"><i class="fa fa-search"></i> 搜索</button>
        </div>
    </form>

    <div v-if="notices.length > 0" class="cp-table-wrap">
        <table class="cp-table">
            <thead>
                <tr>
                    <th style="width: 50px;">ID</th>
                    <th>标题</th>
                    <th>发布时间</th>
                    <th style="text-align: center;">置顶</th>
                    <th style="text-align: center;">状态</th>
                    <th style="text-align: right;">操作</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="n in notices" :key="n.id">
                    <td style="font-family: var(--font-mono); font-size: 11px; color: var(--cp-text-dim);">&#35;{{ n.id }}</td>
                    <td>
                        <span v-if="n.isTop === 1" class="top-tag">置顶</span>
                        <span class="col-title">{{ n.title }}</span>
                    </td>
                    <td style="font-family: var(--font-mono); font-size: 11px; color: var(--cp-text-dim);">{{ n.publishTime || '-' }}</td>
                    <td style="text-align: center;">
                        <span v-if="n.isTop === 1" style="color: var(--cp-red); font-family: var(--font-mono); font-size: 11px;"><i class="fa fa-thumb-tack"></i> 置顶</span>
                        <span v-else style="color: var(--cp-text-dim);">-</span>
                    </td>
                    <td style="text-align: center;">
                        <span :class="['cp-badge', badge(n.status) === 'gray' ? 'cp-badge-dim' : badge(n.status) === 'success' ? 'cp-badge-yellow' : 'cp-badge-red']">{{ statusText(n.status) }}</span>
                    </td>
                    <td style="text-align: right;">
                        <button class="action-btn" @click="openEditModal(n)"><i class="fa fa-pencil"></i> 编辑</button>
                        <button v-if="n.status !== 1" class="action-btn" @click="publishNotice(n)"><i class="fa fa-check"></i> 发布</button>
                        <button v-else class="action-btn danger" @click="retractNotice(n)"><i class="fa fa-undo"></i> 撤回</button>
                        <button v-if="n.isTop !== 1" class="action-btn" @click="setTop(n)"><i class="fa fa-thumb-tack"></i> 置顶</button>
                        <button v-else class="action-btn" @click="unsetTop(n)"><i class="fa fa-thumb-tack" style="color: var(--cp-red);"></i> 取消置顶</button>
                        <button class="action-btn danger" @click="deleteNotice(n)"><i class="fa fa-trash-o"></i> 删除</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <div v-else class="cp-table-wrap">
        <div class="empty-state">
            <i class="fa fa-bullhorn"></i>
            <p>暂无公告</p>
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

    <!-- 新增/编辑弹窗 -->
    <div v-if="modalOpen" class="cp-modal-overlay" @click.self="closeModal">
        <div class="cp-modal">
            <div class="cp-modal-title">
                <span><i :class="form.id ? 'fa fa-pencil' : 'fa fa-plus'"></i> {{ form.id ? '编辑公告' : '新增公告' }}</span>
                <span class="cp-modal-close" @click="closeModal">&times;</span>
            </div>
            <div class="cp-page-sub" style="margin-bottom: 18px; line-height: 1.5;">标题不超过 100 字，内容不超过 5000 字。新增后默认为草稿状态。</div>
            <form @submit.prevent="submit">
                <div class="form-group">
                    <label class="form-label">标题 <span style="color: var(--cp-red);">*</span></label>
                    <input type="text" v-model="form.title" class="form-input"
                           maxlength="100" placeholder="公告标题" required>
                </div>
                <div class="form-group">
                    <label class="form-label">内容 <span style="color: var(--cp-red);">*</span></label>
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
                <div class="cp-modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeModal">取消</button>
                    <button type="submit" class="cp-btn cp-btn-sm" :disabled="submitting">
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
