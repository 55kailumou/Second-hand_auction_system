<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect(ctx + "/user?action=login");
        return;
    }

    String addressesJson = (String) request.getAttribute("addressesJson");
    Integer addressCount = (Integer) request.getAttribute("addressCount");
    Integer maxAddresses = (Integer) request.getAttribute("maxAddresses");
    String error = (String) request.getAttribute("error");
    if (addressesJson == null) addressesJson = "[]";
    if (addressCount == null) addressCount = 0;
    if (maxAddresses == null) maxAddresses = 10;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>收货地址 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 收货地址管理 v1 · 仿闲鱼
         * - 顶 nav 统一
         * - 标题栏 + 统计
         * - 地址卡片列表（默认徽章 / 编辑 / 删除 / 设为默认）
         * - 新增/编辑弹窗（同一弹窗，按 mode 区分）
         * ============================================================ */
        body { background: #f5f5f5; }

        /* ---------- 顶 nav（与 favorite/list.jsp / center.jsp 保持一致） ---------- */
        .header { background: #fff; height: 60px; position: sticky; top: 0; z-index: 100;
                  box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
        .header-inner { max-width: 1200px; margin: 0 auto; padding: 0 16px; height: 100%;
                        display: flex; align-items: center; gap: 20px; }
        .logo { font-size: 20px; font-weight: 800; color: var(--color-primary);
                display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
        .logo-icon { width: 30px; height: 30px; background: var(--color-primary);
                     color: #fff; border-radius: 4px; display: grid; place-items: center;
                     font-size: 14px; }
        .nav { display: flex; gap: 24px; }
        .nav a { color: var(--color-text); font-size: 14px; font-weight: 500;
                 padding: 0 4px; height: 60px; display: flex; align-items: center;
                 position: relative; transition: color 0.2s; }
        .nav a:hover, .nav a.active { color: var(--color-primary); }
        .nav a.active::after {
            content: ''; position: absolute;
            bottom: 8px; left: 4px; right: 4px;
            height: 2px; background: var(--color-primary); border-radius: 2px;
        }
        .nav-search {
            flex: 0 1 380px;
            display: flex; background: #fff7ed;
            border: 2px solid var(--color-primary);
            border-radius: 20px; overflow: hidden; height: 36px;
        }
        .nav-search input {
            flex: 1; padding: 0 14px; border: none; outline: none;
            background: transparent; font-size: 13px; color: var(--color-text);
        }
        .nav-search input::placeholder { color: #9ca3af; }
        .nav-search button {
            background: var(--color-primary); color: #fff;
            font-size: 13px; font-weight: 600; padding: 0 18px;
            display: flex; align-items: center; gap: 5px;
        }
        .nav-search button:hover { background: var(--color-primary-hover); }
        .user-info { display: flex; align-items: center; gap: 8px; font-size: 14px; flex-shrink: 0; margin-left: auto; }
        .user-info .avatar {
            width: 32px; height: 32px; border-radius: 50%;
            background: linear-gradient(135deg, var(--color-primary), #ffaa80);
            color: #fff; display: grid; place-items: center;
            font-size: 13px; font-weight: 600;
        }
        .user-name-link { color: var(--color-text); font-weight: 500; }

        /* ---------- 主体 ---------- */
        .addr-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        /* 标题栏 */
        .addr-head {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 20px 24px;
            display: flex; align-items: center; gap: 16px;
        }
        .addr-head-icon {
            width: 48px; height: 48px; border-radius: 8px;
            background: var(--color-primary-light); color: var(--color-primary);
            display: grid; place-items: center; font-size: 22px;
        }
        .addr-head-info { flex: 1; min-width: 0; }
        .addr-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .addr-head-sub { font-size: 12px; color: var(--color-muted); }
        .addr-head-actions { display: flex; gap: 8px; }
        .btn-ghost {
            padding: 8px 16px; background: #fff; color: var(--color-text);
            border: 1px solid var(--color-border); border-radius: 6px;
            font-size: 13px; text-decoration: none;
            display: flex; align-items: center; gap: 5px;
            transition: all 0.15s; cursor: pointer;
        }
        .btn-ghost:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .btn-primary {
            padding: 8px 16px; background: var(--color-primary); color: #fff;
            border: 1px solid var(--color-primary); border-radius: 6px;
            font-size: 13px; font-weight: 600; text-decoration: none;
            display: flex; align-items: center; gap: 5px;
            transition: all 0.15s; cursor: pointer;
        }
        .btn-primary:hover { background: var(--color-primary-hover); border-color: var(--color-primary-hover); }
        .btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }

        /* 错误条 */
        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        /* 地址卡片列表 */
        .addr-list { display: flex; flex-direction: column; gap: 10px; margin-top: 12px; }
        .addr-card {
            background: #fff; border: 1.5px solid transparent;
            border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 16px 20px; display: grid;
            grid-template-columns: 1fr auto; gap: 12px 16px;
            transition: all 0.15s;
        }
        .addr-card.default { border-color: var(--color-primary); background: #fff7ed; }
        .addr-card:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
        .addr-line-1 {
            display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
            grid-column: 1 / -1;
        }
        .addr-name { font-size: 16px; font-weight: 600; color: var(--color-text); }
        .addr-phone { font-size: 14px; color: var(--color-text); font-weight: 500; }
        .addr-tag {
            display: inline-block; padding: 2px 8px; font-size: 11px; font-weight: 600;
            background: var(--color-primary); color: #fff; border-radius: 3px;
        }
        .addr-line-2 {
            grid-column: 1 / -1;
            font-size: 13px; color: var(--color-text); line-height: 1.6;
        }
        .addr-line-3 {
            grid-column: 1 / -1;
            display: flex; align-items: center; gap: 8px;
            font-size: 12px; color: var(--color-muted);
        }
        .addr-line-3 .sep { color: #e5e7eb; }
        .addr-actions {
            display: flex; align-items: center; gap: 6px;
            grid-row: 1 / 3; align-self: start;
        }
        .addr-action-btn {
            padding: 6px 12px; background: #fff; color: var(--color-text-sub);
            border: 1px solid var(--color-border); border-radius: 4px;
            font-size: 12px; cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; gap: 3px;
        }
        .addr-action-btn:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .addr-action-btn.danger:hover { border-color: var(--color-danger); color: var(--color-danger); }

        /* 空状态 */
        .empty-state {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            margin-top: 12px;
            text-align: center; padding: 80px 20px;
            color: var(--color-muted); font-size: 13px;
        }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }
        .empty-state button {
            margin-top: 12px; padding: 8px 20px;
            background: var(--color-primary); color: #fff;
            border: none; border-radius: 6px; font-size: 13px;
            font-weight: 600; cursor: pointer;
        }
        .empty-state button:hover { background: var(--color-primary-hover); }

        /* 弹窗 */
        .modal { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000;
                 display: none; align-items: center; justify-content: center; }
        .modal.show { display: flex; }
        .modal-content {
            background: #fff; border-radius: 10px;
            padding: 28px; width: 90%; max-width: 540px;
            max-height: 90vh; overflow-y: auto;
        }
        .modal-title { font-size: 18px; font-weight: 700; margin-bottom: 20px;
                       display: flex; align-items: center; gap: 8px; }
        .modal-title::before {
            content: ''; display: inline-block; width: 4px; height: 18px;
            background: var(--color-primary); border-radius: 2px;
        }
        .form-group { margin-bottom: 14px; }
        .form-label { display: block; font-size: 13px; color: var(--color-text-sub);
                      margin-bottom: 6px; font-weight: 500; }
        .form-label .req { color: var(--color-danger); margin-right: 2px; }
        .form-input {
            width: 100%; padding: 9px 12px; border: 1px solid var(--color-border);
            border-radius: 6px; font-size: 14px; outline: none;
            transition: border-color 0.15s; box-sizing: border-box;
            font-family: inherit;
        }
        .form-input:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(255,107,53,0.1); }
        .form-row { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }
        .form-checkbox {
            display: flex; align-items: center; gap: 6px;
            font-size: 13px; color: var(--color-text-sub); cursor: pointer;
        }
        .form-checkbox input { width: 16px; height: 16px; cursor: pointer; accent-color: var(--color-primary); }
        .modal-actions {
            display: flex; gap: 8px; margin-top: 20px;
            padding-top: 16px; border-top: 1px solid var(--color-border-soft);
        }
        .modal-actions .btn-ghost { flex: 1; justify-content: center; }
        .modal-actions .btn-primary { flex: 1; justify-content: center; }

        /* 页脚 */
        .addr-footer {
            background: #1f2937; color: #d1d5db;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .addr-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }

        [v-cloak] { display: none; }
    </style>
</head>
<body>

<!-- ========== 顶 nav ========== -->
<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <span class="logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
            <a href="<%=ctx%>/user?action=center">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="user-info">
            <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= currentUser.getUsername() %></a>
            <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: var(--color-muted);">退出</a>
            <a href="<%=ctx%>/user?action=center" class="avatar">
                <%= currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()
                    ? currentUser.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </a>
        </div>
    </div>
</header>

<div class="addr-wrap" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="addr-head">
        <div class="addr-head-icon"><i class="fa fa-map-marker"></i></div>
        <div class="addr-head-info">
            <div class="addr-head-title">收货地址</div>
            <div class="addr-head-sub">已添加 {{ addresses.length }} / {{ maxAddresses }} 个地址 · 用于订单收件</div>
        </div>
        <div class="addr-head-actions">
            <a href="<%=ctx%>/user?action=center" class="btn-ghost">
                <i class="fa fa-arrow-left"></i> 返回个人中心
            </a>
            <button class="btn-primary" @click="openAddModal" :disabled="addresses.length >= maxAddresses">
                <i class="fa fa-plus"></i> 新增收货地址
            </button>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- 列表 -->
    <div v-if="addresses.length > 0" class="addr-list">
        <div v-for="a in addresses" :key="a.id"
             :class="['addr-card', { default: a.isDefault === 1 }]">
            <div class="addr-line-1">
                <span class="addr-name">{{ a.receiverName }}</span>
                <span class="addr-phone">{{ a.receiverPhone }}</span>
                <span v-if="a.isDefault === 1" class="addr-tag">默认</span>
            </div>
            <div class="addr-line-2">{{ a.province }} {{ a.city }} {{ a.district }} {{ a.detailAddress }}</div>
            <div class="addr-line-3">
                <span><i class="fa fa-clock-o"></i> 添加于 {{ formatTime(a.createTime) }}</span>
            </div>
            <div class="addr-actions">
                <button v-if="a.isDefault !== 1" class="addr-action-btn" @click="setDefault(a)">
                    <i class="fa fa-check-circle"></i> 设为默认
                </button>
                <button class="addr-action-btn" @click="openEditModal(a)">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="addr-action-btn danger" @click="removeAddr(a)">
                    <i class="fa fa-trash-o"></i> 删除
                </button>
            </div>
        </div>
    </div>

    <!-- 空状态 -->
    <div v-else class="empty-state">
        <i class="fa fa-map-marker"></i>
        <p>还没有添加收货地址</p>
        <button @click="openAddModal">
            <i class="fa fa-plus"></i> 立即添加
        </button>
    </div>

    <!-- 弹窗（新增 / 编辑 共用） -->
    <div :class="['modal', { show: modalOpen }]" @click.self="closeModal">
        <div class="modal-content">
            <div class="modal-title">{{ mode === 'add' ? '新增收货地址' : '编辑收货地址' }}</div>
            <form @submit.prevent="submitForm">
                <div class="form-group">
                    <label class="form-label"><span class="req">*</span>收货人</label>
                    <input v-model="form.receiverName" class="form-input" maxlength="20"
                           placeholder="请填写收货人姓名" required>
                </div>
                <div class="form-group">
                    <label class="form-label"><span class="req">*</span>手机号</label>
                    <input v-model="form.receiverPhone" class="form-input" maxlength="11"
                           placeholder="11 位手机号" required>
                </div>
                <div class="form-group">
                    <label class="form-label"><span class="req">*</span>所在地区</label>
                    <div class="form-row">
                        <input v-model="form.province" class="form-input" maxlength="20"
                               placeholder="省（如 北京）" required>
                        <input v-model="form.city" class="form-input" maxlength="20"
                               placeholder="市（如 北京市）" required>
                        <input v-model="form.district" class="form-input" maxlength="20"
                               placeholder="区/县（如 海淀区）" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label"><span class="req">*</span>详细地址</label>
                    <input v-model="form.detailAddress" class="form-input" maxlength="100"
                           placeholder="街道、楼栋、门牌号等" required>
                </div>
                <div class="form-group">
                    <label class="form-checkbox">
                        <input type="checkbox" v-model="form.isDefault" :true-value="1" :false-value="0">
                        设为默认地址
                    </label>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn-ghost" @click="closeModal">取消</button>
                    <button type="submit" class="btn-primary" :disabled="submitting">
                        {{ submitting ? '保存中...' : (mode === 'add' ? '保存地址' : '更新地址') }}
                    </button>
                </div>
            </form>
        </div>
    </div>

</div>

<!-- 页脚 -->
<footer class="addr-footer">
    <div class="addr-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath        = '<%=ctx%>';
    const addressesInit  = <%= addressesJson %>;
    const maxAddresses   = <%= maxAddresses %>;

    loadVue().then(() => {
        const { createApp, ref, reactive } = Vue;
        createApp({
            setup() {
                const addresses = ref(addressesInit);
                const maxAddr = ref(maxAddresses);
                const modalOpen = ref(false);
                const mode = ref('add');     // 'add' | 'update'
                const editingId = ref(null);
                const submitting = ref(false);
                const form = reactive({
                    receiverName: '',
                    receiverPhone: '',
                    province: '',
                    city: '',
                    district: '',
                    detailAddress: '',
                    isDefault: 0
                });

                function resetForm() {
                    form.receiverName = '';
                    form.receiverPhone = '';
                    form.province = '';
                    form.city = '';
                    form.district = '';
                    form.detailAddress = '';
                    form.isDefault = 0;
                    editingId.value = null;
                }
                function fillForm(a) {
                    form.receiverName = a.receiverName || '';
                    form.receiverPhone = a.receiverPhone || '';
                    form.province = a.province || '';
                    form.city = a.city || '';
                    form.district = a.district || '';
                    form.detailAddress = a.detailAddress || '';
                    form.isDefault = a.isDefault == null ? 0 : a.isDefault;
                    editingId.value = a.id;
                }
                function openAddModal() {
                    if (addresses.value.length >= maxAddr.value) {
                        toast('最多只能添加 ' + maxAddr.value + ' 个地址', 'error');
                        return;
                    }
                    resetForm();
                    // 第一个地址自动默认
                    if (addresses.value.length === 0) form.isDefault = 1;
                    mode.value = 'add';
                    modalOpen.value = true;
                }
                function openEditModal(a) {
                    fillForm(a);
                    mode.value = 'update';
                    modalOpen.value = true;
                }
                function closeModal() {
                    modalOpen.value = false;
                }

                function submitForm() {
                    if (submitting.value) return;
                    // 前端二次校验（与服务端一致）
                    if (!form.receiverName) { toast('请填写收货人', 'error'); return; }
                    if (!/^1[3-9]\d{9}$/.test(form.receiverPhone)) {
                        toast('手机号格式不正确', 'error'); return;
                    }
                    if (!form.province || !form.city || !form.district) {
                        toast('请填完整的省/市/区', 'error'); return;
                    }
                    if (!form.detailAddress) { toast('请填写详细地址', 'error'); return; }

                    submitting.value = true;
                    const params = new URLSearchParams();
                    Object.keys(form).forEach(k => params.append(k, form[k]));
                    if (mode.value === 'update') params.append('id', editingId.value);

                    const action = mode.value === 'add' ? 'add' : 'update';
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/address?action=' + action, params)
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '保存成功', 'success');
                                    closeModal();
                                    setTimeout(() => location.reload(), 500);
                                } else {
                                    toast(r.data.message || '保存失败', 'error');
                                }
                                submitting.value = false;
                            })
                            .catch(() => {
                                toast('网络错误', 'error');
                                submitting.value = false;
                            });
                    });
                }

                function setDefault(a) {
                    if (a.isDefault === 1) return;
                    if (!confirm('将"' + a.receiverName + '"设为默认地址？')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/address?action=set-default', null, {
                            params: { id: a.id }
                        }).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已设为默认', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                function removeAddr(a) {
                    if (a.isDefault === 1 && addresses.value.length > 1) {
                        if (!confirm('这是你的默认地址，删除后会自动把其它最近添加的地址设为默认。\n确定删除？')) return;
                    } else if (!confirm('确定删除地址"' + a.receiverName + '"？')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/address?action=remove', null, {
                            params: { id: a.id }
                        }).then(r => {
                            if (r.data.success) {
                                toast(r.data.message || '已删除', 'success');
                                setTimeout(() => location.reload(), 500);
                            } else {
                                toast(r.data.message || '删除失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                function formatTime(dt) {
                    if (!dt) return '-';
                    const d = new Date(dt);
                    if (isNaN(d)) return dt;
                    const pad = n => String(n).padStart(2, '0');
                    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate());
                }

                return { addresses, maxAddresses: maxAddr,
                         modalOpen, mode, form, submitting,
                         openAddModal, openEditModal, closeModal, submitForm,
                         setDefault, removeAddr, formatTime };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
