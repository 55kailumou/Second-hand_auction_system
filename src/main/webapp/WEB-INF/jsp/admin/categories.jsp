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
            gap: 8px;
        }

        .alert { padding: 10px 16px; font-family: var(--font-mono); font-size: 11px; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.05em; }
        .alert-warning { background: rgba(255,238,0,0.1); color: var(--cp-yellow); border: 1px solid var(--cp-yellow-dim); }

        .cp-table td, .cp-table th { white-space: nowrap; }

        .cat-row.sub td:first-child { padding-left: 40px; }
        .cat-row.sub .col-id { color: var(--cp-text-dim); }

        .parent-tag { font-size: 9px; padding: 1px 6px; background: rgba(255,238,0,0.1); color: var(--cp-yellow-dim); border-radius: 2px; margin-left: 6px; font-family: var(--font-mono); }

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
        .form-input, .form-select {
            width: 100%; padding: 9px 12px;
            font-size: 13px; color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none; font-family: var(--font-mono); box-sizing: border-box;
        }
        .form-input:focus, .form-select:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }
        .form-select {
            appearance: none;
            background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath fill='%23FFEE00' d='M6 8L0 0h12z'/%3E%3C/svg%3E");
            background-repeat: no-repeat;
            background-position: right 12px center;
            padding-right: 32px;
        }
        .form-select option { background: #000; color: var(--cp-yellow); }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

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
            <a href="<%=ctx%>/admin/category?action=list" class="active"><i class="fa fa-sitemap"></i> 分类管理</a>
            <a href="<%=ctx%>/admin/announcement?action=list"><i class="fa fa-bullhorn"></i> 公告</a>
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
            <div class="cp-page-title">分类管理</div>
            <div class="cp-page-sub">管理拍品分类（一级 + 二级）、启用/禁用。删除前需先清空该分类下的拍品。</div>
        </div>
        <div class="cp-badge cp-badge-yellow" style="font-size: 12px; padding: 6px 14px;">
            <i class="fa fa-check-circle"></i>
            启用 <%= enabledCount %> / 禁用 <%= disabledCount %>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <div class="toolbar">
        <button class="cp-btn cp-btn-sm" @click="openCreateModal"><i class="fa fa-plus"></i> 新增分类</button>
    </div>

    <div v-if="categories.length > 0" class="cp-table-wrap">
        <table class="cp-table">
            <thead>
                <tr>
                    <th style="width: 50px;">ID</th>
                    <th>分类名</th>
                    <th style="text-align: center;">父分类</th>
                    <th style="text-align: center;">排序</th>
                    <th style="text-align: center;">拍品数</th>
                    <th style="text-align: center;">状态</th>
                    <th style="text-align: right;">操作</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="c in categories" :key="c.id" :class="['cat-row', c.parentId && c.parentId !== 0 ? 'sub' : '']">
                    <td style="font-family: var(--font-mono); font-size: 11px; color: var(--cp-text-dim);">&#35;{{ c.id }}</td>
                    <td>
                        <span style="font-weight: 700;">{{ c.categoryName }}</span>
                        <span v-if="c.parentId && c.parentId !== 0" class="parent-tag">子分类</span>
                    </td>
                    <td style="text-align: center; font-family: var(--font-mono); font-size: 11px;">
                        <span v-if="c.parentId && c.parentId !== 0" style="color: var(--cp-text-dim);">{{ parentName(c.parentId) }}</span>
                        <span v-else style="color: var(--cp-cyan); font-weight: 700;">一级</span>
                    </td>
                    <td style="text-align: center; font-family: var(--font-mono); font-size: 12px; color: var(--cp-text-dim);">{{ c.sortOrder == null ? 0 : c.sortOrder }}</td>
                    <td style="text-align: center; color: var(--cp-text-dim);">-</td>
                    <td style="text-align: center;">
                        <span :class="['cp-badge', c.status === 0 ? 'cp-badge-red' : 'cp-badge-yellow']">
                            {{ c.status === 0 ? '禁用' : '启用' }}
                        </span>
                    </td>
                    <td style="text-align: right;">
                        <button class="action-btn" @click="openEditModal(c)"><i class="fa fa-pencil"></i> 编辑</button>
                        <button v-if="c.status !== 0" class="action-btn danger" @click="disableCat(c)"><i class="fa fa-ban"></i> 禁用</button>
                        <button v-else class="action-btn" @click="enableCat(c)"><i class="fa fa-check"></i> 启用</button>
                        <button class="action-btn danger" @click="deleteCat(c)"><i class="fa fa-trash-o"></i> 删除</button>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <div v-else class="cp-table-wrap">
        <div class="empty-state">
            <i class="fa fa-sitemap"></i>
            <p>暂无分类</p>
        </div>
    </div>

    <!-- 新增 / 编辑弹窗 -->
    <div v-if="modalOpen" class="cp-modal-overlay" @click.self="closeModal">
        <div class="cp-modal">
            <div class="cp-modal-title">
                <span><i :class="form.id ? 'fa fa-pencil' : 'fa fa-plus'"></i> {{ form.id ? '编辑分类' : '新增分类' }}</span>
                <span class="cp-modal-close" @click="closeModal">&times;</span>
            </div>
            <div class="cp-page-sub" style="margin-bottom: 18px;">分类名不超过 20 字，父分类留空表示顶级分类。</div>
            <form @submit.prevent="submit">
                <div class="form-group">
                    <label class="form-label">分类名 <span style="color: var(--cp-red);">*</span></label>
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
