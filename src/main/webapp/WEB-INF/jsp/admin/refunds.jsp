<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
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
    <title>退款审批 · 管理后台</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        .admin-main { max-width: 1400px; margin: 24px auto 0; padding: 0 24px 60px; position: relative; z-index: 3; }

        .nav-badge {
            display: inline-block; padding: 1px 6px; margin-left: 4px;
            background: var(--cp-red); color: #fff; font-size: 9px;
            font-family: var(--font-mono); font-weight: 700;
            clip-path: polygon(3px 0, 100% 0, calc(100% - 3px) 100%, 0 100%);
        }
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
            width: 240px;
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

        .alert { padding: 10px 16px; font-family: var(--font-mono); font-size: 11px; margin-bottom: 12px; text-transform: uppercase; letter-spacing: 0.05em; }
        .alert-warning { background: rgba(255,238,0,0.1); color: var(--cp-yellow); border: 1px solid var(--cp-yellow-dim); }

        .cp-table td, .cp-table th { white-space: nowrap; }
        .cp-table td { vertical-align: top; }

        .col-cover {
            width: 50px; height: 50px;
            background: rgba(255,238,0,0.05);
            display: grid; place-items: center;
            color: var(--cp-text-dim); overflow: hidden;
            border: 1px solid var(--cp-yellow-dim);
            clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%);
        }
        .col-cover img { width: 100%; height: 100%; object-fit: cover; }

        .reason-block {
            background: rgba(255,238,0,0.05);
            border-left: 3px solid var(--cp-yellow);
            padding: 8px 12px;
            font-size: 11px;
            font-family: var(--font-mono);
            color: var(--cp-text-dim);
            line-height: 1.5;
            margin-top: 6px;
        }
        .reason-block i { color: var(--cp-yellow); margin-right: 4px; }
        .result-block {
            background: rgba(255,238,0,0.05);
            padding: 6px 10px;
            font-size: 11px;
            font-family: var(--font-mono);
            color: var(--cp-text-dim);
            margin-top: 6px;
        }
        .result-block i { color: var(--cp-yellow); }

        .action-btn {
            padding: 6px 14px;
            font-family: var(--font-mono);
            font-size: 10px;
            text-transform: uppercase;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.15s;
            border: none;
        }
        .btn-approve { background: var(--cp-yellow); color: #000; clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%); }
        .btn-approve:hover { background: #fff; }
        .btn-reject { background: var(--cp-red); color: #fff; clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%); }
        .btn-reject:hover { background: #ff3366; }
        .btn-done { padding: 6px 12px; background: rgba(255,238,0,0.1); color: var(--cp-text-dim); font-family: var(--font-mono); font-size: 10px; }

        .empty-state { text-align: center; padding: 60px 20px; font-family: var(--font-mono); font-size: 12px; color: var(--cp-text-dim); }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; color: var(--cp-yellow-dim); }

        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-family: var(--font-mono); font-size: 10px; color: var(--cp-yellow-dim); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 6px; }
        .form-textarea {
            width: 100%; padding: 9px 12px;
            font-size: 13px; color: var(--cp-yellow);
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
            outline: none; font-family: var(--font-mono); box-sizing: border-box;
            resize: vertical; min-height: 80px;
        }
        .form-textarea:focus { box-shadow: 0 0 8px rgba(255,238,0,0.3); }

        .cp-modal-actions { display: flex; gap: 8px; margin-top: 20px; padding-top: 16px; border-top: 1px solid rgba(255,238,0,0.15); }
        .cp-modal-actions button { flex: 1; padding: 10px; font-size: 12px; font-weight: 700; }
        .btn-modal-cancel { background: rgba(255,238,0,0.1); color: var(--cp-yellow-dim); border: 1px solid var(--cp-yellow-dim); font-family: var(--font-mono); text-transform: uppercase; }
        .btn-modal-approve { background: var(--cp-yellow); color: #000; font-family: var(--font-mono); text-transform: uppercase; }
        .btn-modal-reject { background: var(--cp-red); color: #fff; font-family: var(--font-mono); text-transform: uppercase; }
    </style>
</head>
<body>

<!-- ========== 顶部 admin 导航 ========== -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/admin" class="cp-logo">管理后台</a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/admin"><i class="fa fa-dashboard"></i> 概览</a>
            <a href="<%=ctx%>/admin/refund?action=list" class="active">
                <i class="fa fa-undo"></i> 退款审批
                <% if (pendingCount != null && pendingCount > 0) { %>
                    <span class="nav-badge"><%= pendingCount %></span>
                <% } %>
            </a>
            <a href="<%=ctx%>/admin/item?action=list"><i class="fa fa-gavel"></i> 拍品</a>
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

    <!-- 标题栏 -->
    <div class="cp-page-head">
        <div>
            <div class="cp-page-title">退款审批</div>
            <div class="cp-page-sub">买家申请退款的订单，审核通过后状态变为"已退款"，驳回后回到"已付款"</div>
        </div>
        <% if (pendingCount != null && pendingCount > 0) { %>
            <div class="cp-badge cp-badge-yellow" style="font-size: 12px; padding: 6px 14px;">
                <i class="fa fa-bell"></i>
                待审核 <%= pendingCount %> 单
            </div>
        <% } %>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- 筛选 + 搜索 -->
    <div class="filter-bar">
        <a href="<%=ctx%>/admin/refund?action=list&status=4" class="filter-tab <%= status != null && status == 4 ? "active" : "" %>">
            待审核 <span class="count">(<%= pendingCount %>)</span>
        </a>
        <a href="<%=ctx%>/admin/refund?action=list&status=5" class="filter-tab <%= status != null && status == 5 ? "active" : "" %>">
            已完成
        </a>
        <a href="<%=ctx%>/admin/refund?action=list" class="filter-tab <%= status == null ? "active" : "" %>">
            全部
        </a>
        <form class="filter-search" method="get" action="<%=ctx%>/admin/refund">
            <input type="hidden" name="action" value="list">
            <% if (status != null) { %>
                <input type="hidden" name="status" value="<%= status %>">
            <% } %>
            <input type="text" name="keyword" value="<%= EscapeUtil.html(keyword) %>"
                   placeholder="搜索订单号 / 拍品标题 / 退款理由">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
    </div>

    <!-- 列表 -->
    <div v-if="rows.length > 0" class="cp-table-wrap">
        <table class="cp-table">
            <thead>
                <tr>
                    <th style="width: 60px;">封面</th>
                    <th>拍品 / 订单</th>
                    <th>买家</th>
                    <th>金额</th>
                    <th style="text-align: right;">操作</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="r in rows" :key="r.orderId">
                    <td>
                        <div class="col-cover" :style="r.coverImage ? 'background-image:url(' + r.coverImage + '); background-size:cover; background-position:center;' : ''">
                            <i v-if="!r.coverImage" class="fa fa-image"></i>
                        </div>
                    </td>
                    <td style="min-width: 180px;">
                        <div style="font-weight: 700;">{{ r.itemTitle }}</div>
                        <div style="font-family: var(--font-mono); font-size: 10px; color: var(--cp-text-dim);">{{ r.orderNo }}</div>
                        <div v-if="r.status === 4" class="reason-block">
                            <i class="fa fa-commenting-o"></i> 退款理由：{{ r.refundReason }}
                        </div>
                        <div v-else class="result-block">
                            <i class="fa fa-check-circle"></i> 审核结果：{{ r.refundAuditResult }}
                        </div>
                    </td>
                    <td style="font-family: var(--font-mono); font-size: 11px;">
                        <div style="font-weight: 700; color: var(--cp-yellow);">{{ r.buyerUsername }}</div>
                        <div style="color: var(--cp-text-dim);">ID: {{ r.buyerId }}</div>
                    </td>
                    <td style="font-family: var(--font-mono);">
                        <div style="font-size: 14px; font-weight: 700; color: var(--cp-yellow);">
                            <small style="color: var(--cp-text-dim);">¥</small>{{ formatPrice(r.finalPrice) }}
                        </div>
                        <div style="margin-top: 4px;">
                            <span v-if="r.status === 4" class="cp-badge cp-badge-yellow" style="font-size: 9px;">待审核</span>
                            <span v-else-if="r.status === 5" class="cp-badge" style="background: var(--cp-yellow); color: #000; font-size: 9px;">已退款</span>
                        </div>
                    </td>
                    <td style="text-align: right;">
                        <button v-if="r.status === 4" class="action-btn btn-approve" @click="openApprove(r)">
                            <i class="fa fa-check"></i> 同意
                        </button>
                        <button v-if="r.status === 4" class="action-btn btn-reject" @click="openReject(r)">
                            <i class="fa fa-times"></i> 驳回
                        </button>
                        <span v-else class="btn-done"><i class="fa fa-check-circle"></i> 已处理</span>
                    </td>
                </tr>
            </tbody>
        </table>
    </div>

    <!-- 空状态 -->
    <div v-else class="cp-table-wrap">
        <div class="empty-state">
            <i class="fa fa-inbox"></i>
            <p>暂无退款申请</p>
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

    <!-- 弹窗（同意/驳回） -->
    <div v-if="modalOpen" class="cp-modal-overlay" @click.self="closeModal">
        <div class="cp-modal">
            <div class="cp-modal-title">
                <span><i :class="['fa', modalMode === 'approve' ? 'fa-check-circle' : 'fa-times-circle']"></i> {{ modalMode === 'approve' ? '同意退款' : '驳回退款' }}</span>
                <span class="cp-modal-close" @click="closeModal">&times;</span>
            </div>
            <div class="cp-page-sub" style="margin-bottom: 18px; line-height: 1.5;">
                订单号 <span style="color: var(--cp-yellow); font-family: var(--font-mono);">{{ currentOrder ? currentOrder.orderNo : '' }}</span>
                · 金额 <span style="color: var(--cp-yellow); font-weight: 700;">¥{{ currentOrder ? formatPrice(currentOrder.finalPrice) : '0.00' }}</span>
            </div>
            <form @submit.prevent="submitForm">
                <div class="form-group">
                    <label class="form-label">审核说明（买家可见）</label>
                    <textarea v-model="form.result" class="form-textarea" maxlength="500"
                              :placeholder="modalMode === 'approve' ? '例如：已确认卖家同意退款，退款将在 1-3 个工作日内原路返回' : '例如：经核实商品与描述一致，不符合退款条件，请与卖家沟通'"></textarea>
                </div>
                <div class="cp-modal-actions">
                    <button type="button" class="btn-modal-cancel" @click="closeModal">取消</button>
                    <button type="submit" :disabled="submitting"
                            :class="modalMode === 'approve' ? 'btn-modal-approve' : 'btn-modal-reject'">
                        {{ submitting ? '处理中...' : (modalMode === 'approve' ? '确认同意' : '确认驳回') }}
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
                const currentOrder = ref(null);
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
                    return ctxPath + '/admin/refund?' + params.toString();
                }
                function formatPrice(p) {
                    return Number(p).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
                function openApprove(r) {
                    currentOrder.value = r;
                    modalMode.value = 'approve';
                    form.result = '已确认情况属实，同意退款';
                    modalOpen.value = true;
                }
                function openReject(r) {
                    currentOrder.value = r;
                    modalMode.value = 'reject';
                    form.result = '经核实不符合退款条件，已驳回';
                    modalOpen.value = true;
                }
                function closeModal() {
                    modalOpen.value = false;
                    form.result = '';
                    currentOrder.value = null;
                }
                function submitForm() {
                    if (submitting.value || !currentOrder.value) return;
                    submitting.value = true;
                    const params = new URLSearchParams();
                    params.append('id', currentOrder.value.orderId);
                    params.append('result', form.result || '');
                    const action = modalMode.value === 'approve' ? 'approve' : 'reject';
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/admin/refund?action=' + action, params)
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
                         pagesToShow, modalOpen, modalMode, currentOrder, form, submitting,
                         pageHref, formatPrice, openApprove, openReject, closeModal, submitForm };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
