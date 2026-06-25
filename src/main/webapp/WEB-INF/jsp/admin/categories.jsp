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

    String categoriesJson = (String) request.getAttribute("categoriesJson");
    Integer total = (Integer) request.getAttribute("total");
    Integer enabledCount = (Integer) request.getAttribute("enabledCount");
    Integer disabledCount = (Integer) request.getAttribute("disabledCount");
    String error = (String) request.getAttribute("error");
    if (categoriesJson == null) categoriesJson = "[]";
    if (total == null) total = 0;
    if (enabledCount == null) enabledCount = 0;
    if (disabledCount == null) disabledCount = 0;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>分类管理 · 管理后台</title>
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
                          background: #e0e7ff; color: #4338ca;
                          display: grid; place-items: center; font-size: 22px; }
        .page-head-info { flex: 1; }
        .page-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); }
        .page-head-stat { display: flex; gap: 6px; align-items: center; padding: 8px 16px;
                          background: #e0e7ff; color: #4338ca; border-radius: 6px;
                          font-size: 13px; font-weight: 600; }
        .page-head-stat .num { font-size: 18px; }

        .toolbar { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                   margin-top: 12px; padding: 12px 20px;
                   display: flex; align-items: center; gap: 8px; }
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

        .cat-table { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     margin-top: 12px; overflow: hidden; }
        .cat-row { display: grid;
                    grid-template-columns: 60px 1fr 120px 80px 120px 80px 240px;
                    gap: 14px; padding: 14px 20px; align-items: center;
                    border-bottom: 1px solid var(--color-border-soft); }
        .cat-row.sub { background: #fafbfc; padding-left: 60px; }
        .cat-row.sub .col-id { color: var(--color-muted); }
        .cat-row:last-child { border-bottom: none; }
        .cat-row.head { background: #f9fafb; font-size: 12px; color: var(--color-muted);
                         font-weight: 600; padding: 10px 20px; }
        .col-id { font-size: 12px; color: var(--color-muted); }
        .col-name { font-size: 13px; font-weight: 600; }
        .col-name .parent-tag { font-size: 10px; padding: 1px 6px;
                                  background: #f3f4f6; color: var(--color-muted);
                                  border-radius: 3px; margin-left: 6px; font-weight: 500; }
        .col-sort, .col-count { font-size: 13px; text-align: center; color: var(--color-text-sub); }
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

        /* 弹窗 */
        .modal { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000;
                 display: none; align-items: center; justify-content: center; }
        .modal.show { display: flex; }
        .modal-content { background: #fff; border-radius: 10px; padding: 28px;
                         width: 90%; max-width: 480px; }
        .modal-title { font-size: 17px; font-weight: 700; margin-bottom: 8px;
                       display: flex; align-items: center; gap: 8px; color: #4338ca; }
        .modal-sub { font-size: 12px; color: var(--color-muted); margin-bottom: 18px; line-height: 1.5; }
        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-size: 13px; color: var(--color-text-sub);
                      margin-bottom: 6px; font-weight: 500; }
        .form-input, .form-select { width: 100%; padding: 9px 12px; border: 1px solid var(--color-border);
                                     border-radius: 6px; font-size: 14px; outline: none;
                                     font-family: inherit; box-sizing: border-box; background: #fff; }
        .form-input:focus, .form-select:focus { border-color: var(--color-primary); }
        .form-hint { font-size: 11px; color: var(--color-muted); margin-top: 4px; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .modal-actions { display: flex; gap: 8px; margin-top: 20px;
                         padding-top: 16px; border-top: 1px solid var(--color-border-soft); }
        .modal-actions button { flex: 1; padding: 10px; border: none; border-radius: 6px;
                                font-size: 14px; font-weight: 600; cursor: pointer; }
        .btn-modal-cancel { background: #f3f4f6; color: var(--color-text); }
        .btn-modal-confirm { background: var(--color-primary); color: #fff; }

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
            <a href="<%=ctx%>/admin/user?action=list"><i class="fa fa-users"></i> 用户管理</a>
            <a href="<%=ctx%>/admin/category?action=list" class="active">
                <i class="fa fa-sitemap"></i> 分类管理
            </a>
            <a href="<%=ctx%>/admin/announcement?action=list">
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
        <div class="page-head-icon"><i class="fa fa-sitemap"></i></div>
        <div class="page-head-info">
            <div class="page-head-title">分类管理</div>
            <div class="page-head-sub">管理拍品分类（一级 + 二级）、启用/禁用。删除前需先清空该分类下的拍品。</div>
        </div>
        <div class="page-head-stat">
            <i class="fa fa-check-circle"></i>
            启用 <span class="num"><%= enabledCount %></span> / 禁用 <span class="num" style="color: #b91c1c;"><%= disabledCount %></span>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <div class="toolbar">
        <button class="add" @click="openCreateModal"><i class="fa fa-plus"></i> 新增分类</button>
    </div>

    <div v-if="categories.length > 0" class="cat-table">
        <div class="cat-row head">
            <div>ID</div>
            <div>分类名</div>
            <div style="text-align: center;">父分类</div>
            <div style="text-align: center;">排序</div>
            <div style="text-align: center;">拍品数</div>
            <div style="text-align: center;">状态</div>
            <div style="text-align: right;">操作</div>
        </div>
        <div v-for="c in categories" :key="c.id" :class="['cat-row', c.parentId && c.parentId !== 0 ? 'sub' : '']">
            <div class="col-id">&#35;{{ c.id }}</div>
            <div class="col-name">
                {{ c.categoryName }}
                <span v-if="c.parentId && c.parentId !== 0" class="parent-tag">子分类</span>
            </div>
            <div class="col-sort">
                <span v-if="c.parentId && c.parentId !== 0" style="color: var(--color-muted); font-size: 11px;">
                    {{ parentName(c.parentId) }}
                </span>
                <span v-else style="color: #4338ca; font-weight: 600;">一级</span>
            </div>
            <div class="col-sort">{{ c.sortOrder == null ? 0 : c.sortOrder }}</div>
            <div class="col-count">-</div>
            <div class="col-status" style="text-align: center;">
                <span :class="['badge', c.status === 0 ? 'badge-danger' : 'badge-success']">
                    {{ c.status === 0 ? '禁用' : '启用' }}
                </span>
            </div>
            <div class="col-actions">
                <button @click="openEditModal(c)"><i class="fa fa-pencil"></i> 编辑</button>
                <button v-if="c.status !== 0" class="danger" @click="disableCat(c)">
                    <i class="fa fa-ban"></i> 禁用
                </button>
                <button v-else @click="enableCat(c)">
                    <i class="fa fa-check"></i> 启用
                </button>
                <button class="danger" @click="deleteCat(c)">
                    <i class="fa fa-trash-o"></i> 删除
                </button>
            </div>
        </div>
    </div>

    <div v-else class="cat-table">
        <div class="empty-state">
            <i class="fa fa-sitemap"></i>
            <p>暂无分类</p>
        </div>
    </div>

    <!-- 新增 / 编辑弹窗 -->
    <div :class="['modal', { show: modalOpen }]" @click.self="closeModal">
        <div class="modal-content">
            <div class="modal-title">
                <i :class="form.id ? 'fa fa-pencil' : 'fa fa-plus'"></i>
                {{ form.id ? '编辑分类' : '新增分类' }}
            </div>
            <div class="modal-sub">分类名不超过 20 字，父分类留空表示顶级分类。</div>
            <form @submit.prevent="submit">
                <div class="form-group">
                    <label class="form-label">分类名 <span style="color: var(--color-danger);">*</span></label>
                    <input type="text" v-model="form.categoryName" class="form-input"
                           maxlength="20" placeholder="例如：手机数码" required>
                </div>
                <div class="form-group">
                    <label class="form-label">父分类</label>
                    <select v-model="form.parentId" class="form-select">
                        <option v-for="p in parentOptions" :key="p.id" :value="p.id">{{ p.name }}</option>
                    </select>
                    <div class="form-hint">选择"（一级分类）"表示这是一个顶级分类。</div>
                </div>
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">排序号</label>
                        <input type="number" v-model.number="form.sortOrder" class="form-input"
                               min="0" placeholder="数字小靠前">
                    </div>
                    <div class="form-group">
                        <label class="form-label">状态</label>
                        <select v-model="form.status" class="form-select">
                            <option :value="1">启用</option>
                            <option :value="0">禁用</option>
                        </select>
                    </div>
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
    const catsInit = <%= categoriesJson %>;

    loadVue().then(() => {
        const { createApp, ref, reactive } = Vue;
        createApp({
            setup() {
                const categories = ref(catsInit);

                const modalOpen = ref(false);
                const submitting = ref(false);
                const form = reactive({
                    id: null,
                    categoryName: '',
                    parentId: 0,
                    sortOrder: 0,
                    status: 1
                });

                const parentOptions = ref([{ id: 0, name: '（一级分类）' }]);

                function parentName(pid) {
                    const p = categories.value.find(c => c.id === pid);
                    return p ? p.categoryName : '?';
                }

                async function openCreateModal() {
                    form.id = null;
                    form.categoryName = '';
                    form.parentId = 0;
                    form.sortOrder = 0;
                    form.status = 1;
                    await loadParents();
                    modalOpen.value = true;
                }

                async function openEditModal(c) {
                    form.id = c.id;
                    form.categoryName = c.categoryName;
                    form.parentId = c.parentId || 0;
                    form.sortOrder = c.sortOrder || 0;
                    form.status = c.status == null ? 1 : c.status;
                    await loadParents();
                    modalOpen.value = true;
                }

                function closeModal() { modalOpen.value = false; }

                async function loadParents() {
                    return new Promise(resolve => {
                        loadAxios().then(() => {
                            axios.get(ctxPath + '/admin/category?action=parents').then(r => {
                                if (r.data.success) parentOptions.value = r.data.options;
                                resolve();
                            }).catch(() => resolve());
                        });
                    });
                }

                function submit() {
                    if (submitting.value) return;
                    if (!form.categoryName || !form.categoryName.trim()) {
                        toast('请填写分类名', 'error');
                        return;
                    }
                    submitting.value = true;
                    const params = new URLSearchParams();
                    params.append('categoryName', form.categoryName.trim());
                    params.append('parentId', form.parentId);
                    params.append('sortOrder', form.sortOrder || 0);
                    params.append('status', form.status);
                    const url = form.id
                        ? ctxPath + '/admin/category?action=update&id=' + form.id
                        : ctxPath + '/admin/category?action=create';
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

                function disableCat(c) {
                    if (!confirm('确定禁用分类「' + c.categoryName + '」？\n禁用后前台不可见，但已有数据不丢失。')) return;
                    setStatus(c, 0);
                }
                function enableCat(c) {
                    setStatus(c, 1);
                }
                function setStatus(c, status) {
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/category?action=set-status', new URLSearchParams({
                            id: c.id, status: status
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

                function deleteCat(c) {
                    if (!confirm('确定删除分类「' + c.categoryName + '」？\n注意：分类下有拍品或子分类时无法删除。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/category?action=delete', new URLSearchParams({
                            id: c.id
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

                return { categories, modalOpen, submitting, form, parentOptions,
                         parentName, openCreateModal, openEditModal, closeModal, submit,
                         disableCat, enableCat, deleteCat };
            }
        }).mount('#app');
    });
</script>
</body>
</html>