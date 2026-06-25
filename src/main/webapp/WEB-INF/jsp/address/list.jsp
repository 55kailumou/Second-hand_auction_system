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
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * Cyberpunk 2077 · 收货地址管理
         * - Dark neon theme #000 / #FFEE00 / #00FFFF / #FF00FF
         * - Clip-path polygons, monospace fonts, scanline overlay
         * ============================================================ */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { height: 100%; }
        body {
            background: #000;
            color: #FFEE00;
            font-family: 'Courier New', 'Consolas', 'Share Tech Mono', monospace;
            font-size: 14px;
            line-height: 1.6;
            position: relative;
            overflow-x: hidden;
        }
        body::before {
            content: '';
            position: fixed;
            inset: 0;
            background: repeating-linear-gradient(
                0deg,
                rgba(0,255,255,0.03) 0px,
                rgba(0,255,255,0.03) 1px,
                transparent 1px,
                transparent 3px
            );
            pointer-events: none;
            z-index: 9999;
        }
        a { color: #00FFFF; text-decoration: none; transition: color 0.2s; }
        a:hover { color: #FF00FF; text-shadow: 0 0 8px #FF00FF; }
        ::-webkit-scrollbar { width: 8px; background: #0a0a0a; }
        ::-webkit-scrollbar-thumb { background: #FFEE00; border-radius: 0; }

        /* ---------- Navigation ---------- */

        .cp-logo .logo-icon {
            width: 30px;
            height: 30px;
            background: #FFEE00;
            color: #000;
            border-radius: 0;
            display: grid;
            place-items: center;
            font-size: 14px;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
        }

        .cp-nav-search button:hover {
            background: #00FFFF;
            color: #000;
        }

        .cp-nav-user .user-name-link {
            color: #FFEE00;
            font-weight: 600;
        }
        .cp-nav-user .user-name-link:hover {
            color: #00FFFF;
            text-shadow: 0 0 8px #00FFFF;
        }

        /* ---------- Container ---------- */
        .cp-container {
            max-width: 1200px;
            margin: 12px auto 0;
            padding: 0 16px 60px;
        }

        /* ---------- Head ---------- */
        .addr-head {
            background: #0d0d0d;
            border: 1px solid #FFEE00;
            clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
            padding: 20px 24px;
            display: flex;
            align-items: center;
            gap: 16px;
        }
        .addr-head-icon {
            width: 48px;
            height: 48px;
            background: #111;
            border: 1px solid #FFEE00;
            color: #FFEE00;
            display: grid;
            place-items: center;
            font-size: 22px;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
        }
        .addr-head-info { flex: 1; min-width: 0; }
        .addr-head-title {
            font-size: 18px;
            font-weight: 700;
            color: #00FFFF;
            text-shadow: 0 0 6px #00FFFF;
            margin-bottom: 4px;
        }
        .addr-head-sub { font-size: 12px; color: #666; }
        .addr-head-actions { display: flex; gap: 8px; }

        /* ---------- Buttons ---------- */
        .cp-btn {
            padding: 8px 16px;
            background: transparent;
            color: #FFEE00;
            border: 1px solid #FFEE00;
            clip-path: polygon(6px 0, 100% 0, calc(100% - 6px) 100%, 0 100%);
            font-size: 12px;
            font-weight: 600;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            transition: all 0.15s;
            cursor: pointer;
            font-family: inherit;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .cp-btn:hover {
            background: #FFEE00;
            color: #000;
            box-shadow: 0 0 12px #FFEE00;
        }
        .cp-btn:disabled {
            opacity: 0.4;
            cursor: not-allowed;
        }
        .cp-btn-sm {
            padding: 5px 10px;
            font-size: 11px;
        }
        .cp-btn-outline {
            background: transparent;
            border: 1px solid #00FFFF;
            color: #00FFFF;
        }
        .cp-btn-outline:hover {
            background: #00FFFF;
            color: #000;
            box-shadow: 0 0 12px #00FFFF;
        }

        /* ---------- Alert ---------- */
        .alert {
            padding: 10px 16px;
            margin-top: 12px;
            font-size: 13px;
            border: 1px solid;
        }
        .alert-warning {
            background: #1a0a00;
            color: #FF8800;
            border-color: #FF8800;
        }

        /* ---------- Address Cards ---------- */
        .addr-list {
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-top: 12px;
        }
        .addr-card {
            background: #0d0d0d;
            border: 1.5px solid #333;
            clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%);
            padding: 16px 20px;
            display: grid;
            grid-template-columns: 1fr auto;
            gap: 12px 16px;
            transition: all 0.2s;
        }
        .addr-card.default {
            border-color: #FFEE00;
            box-shadow: 0 0 10px rgba(255,238,0,0.2);
        }
        .addr-card:hover {
            border-color: #00FFFF;
            box-shadow: 0 0 14px rgba(0,255,255,0.15);
        }
        .addr-line-1 {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
            grid-column: 1 / -1;
        }
        .addr-name { font-size: 16px; font-weight: 700; color: #FFEE00; }
        .addr-phone { font-size: 14px; color: #aaa; font-weight: 500; }
        .cp-badge {
            display: inline-block;
            padding: 2px 10px;
            font-size: 10px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 2px;
        }
        .cp-badge-yellow {
            background: #FFEE00;
            color: #000;
        }
        .cp-badge-cyan {
            background: #00FFFF;
            color: #000;
        }
        .cp-badge-magenta {
            background: #FF00FF;
            color: #000;
        }
        .cp-badge-outline {
            background: transparent;
            border: 1px solid #FFEE00;
            color: #FFEE00;
        }
        .addr-line-2 {
            grid-column: 1 / -1;
            font-size: 13px;
            color: #ccc;
            line-height: 1.6;
        }
        .addr-line-3 {
            grid-column: 1 / -1;
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 12px;
            color: #555;
        }
        .addr-line-3 .sep { color: #333; }
        .addr-actions {
            display: flex;
            align-items: center;
            gap: 6px;
            grid-row: 1 / 3;
            align-self: start;
        }

        /* ---------- Empty State ---------- */
        .cp-empty {
            background: #0d0d0d;
            border: 1px solid #333;
            clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
            margin-top: 12px;
            text-align: center;
            padding: 80px 20px;
            color: #555;
            font-size: 13px;
        }
        .cp-empty i {
            font-size: 48px;
            color: #333;
            margin-bottom: 12px;
            display: block;
        }
        .cp-empty .cp-btn {
            margin-top: 12px;
        }

        /* ---------- Modal ---------- */
        .cp-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.85);
            z-index: 1000;
            display: none;
            align-items: center;
            justify-content: center;
            backdrop-filter: blur(4px);
        }
        .cp-modal-overlay.show { display: flex; }
        .cp-modal {
            background: #0d0d0d;
            border: 2px solid #FFEE00;
            clip-path: polygon(14px 0, 100% 0, calc(100% - 14px) 100%, 0 100%);
            padding: 28px;
            width: 90%;
            max-width: 540px;
            max-height: 90vh;
            overflow-y: auto;
            box-shadow: 0 0 30px rgba(255,238,0,0.15);
        }
        .cp-modal-title {
            font-size: 18px;
            font-weight: 700;
            color: #00FFFF;
            text-shadow: 0 0 6px #00FFFF;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .cp-modal-title::before {
            content: '>';
            display: inline-block;
            color: #FFEE00;
            font-weight: 700;
        }
        .cp-modal-close {
            margin-left: auto;
            background: none;
            border: 1px solid #555;
            color: #555;
            font-size: 18px;
            cursor: pointer;
            width: 30px;
            height: 30px;
            display: grid;
            place-items: center;
            font-family: inherit;
        }
        .cp-modal-close:hover {
            border-color: #FF00FF;
            color: #FF00FF;
        }

        /* ---------- Form ---------- */
        .cp-form-group { margin-bottom: 14px; }
        .cp-form-label {
            display: block;
            font-size: 12px;
            color: #888;
            margin-bottom: 6px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .cp-form-label .req { color: #FF00FF; margin-right: 2px; }
        .cp-form-input {
            width: 100%;
            padding: 9px 12px;
            background: #111;
            border: 1px solid #333;
            color: #FFEE00;
            font-size: 14px;
            outline: none;
            transition: border-color 0.2s, box-shadow 0.2s;
            box-sizing: border-box;
            font-family: inherit;
        }
        .cp-form-input:focus {
            border-color: #00FFFF;
            box-shadow: 0 0 8px rgba(0,255,255,0.2);
        }
        .cp-form-input::placeholder { color: #444; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; }
        .form-checkbox {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
            color: #888;
            cursor: pointer;
        }
        .form-checkbox input {
            width: 16px;
            height: 16px;
            cursor: pointer;
            accent-color: #FFEE00;
        }
        .modal-actions {
            display: flex;
            gap: 8px;
            margin-top: 20px;
            padding-top: 16px;
            border-top: 1px solid #222;
        }
        .modal-actions .cp-btn { flex: 1; justify-content: center; }

        /* ---------- Footer ---------- */
        .addr-footer {
            background: #050505;
            border-top: 1px solid #FFEE00;
            margin-top: 32px;
            padding: 32px 16px 16px;
            text-align: center;
            font-size: 12px;
        }
        .addr-footer-inner {
            max-width: 1200px;
            margin: 0 auto;
            color: #444;
        }

        [v-cloak] { display: none; }
    </style>
</head>
<body>

<!-- Scanline overlay -->
<div class="scanline" style="position:fixed;inset:0;pointer-events:none;z-index:9999;background:repeating-linear-gradient(0deg,transparent,transparent 2px,rgba(0,255,255,0.02) 2px,rgba(0,255,255,0.02) 4px);"></div>

<!-- ========== Navigation ========== -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
            <a href="<%=ctx%>/user?action=center">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="cp-nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="cp-nav-user">
            <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= currentUser.getUsername() %></a>
            <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: #555;">退出</a>
            <a href="<%=ctx%>/user?action=center" class="avatar">
                <%= currentUser.getUsername() != null && !currentUser.getUsername().isEmpty()
                    ? currentUser.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </a>
        </div>
    </div>
</header>

<div class="cp-container" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="addr-head">
        <div class="addr-head-icon"><i class="fa fa-map-marker"></i></div>
        <div class="addr-head-info">
            <div class="addr-head-title">> 收货地址</div>
            <div class="addr-head-sub">已添加 {{ addresses.length }} / {{ maxAddresses }} 个地址 · 用于订单收件</div>
        </div>
        <div class="addr-head-actions">
            <a href="<%=ctx%>/user?action=center" class="cp-btn cp-btn-outline cp-btn-sm">
                <i class="fa fa-arrow-left"></i> 返回
            </a>
            <button class="cp-btn cp-btn-sm" @click="openAddModal" :disabled="addresses.length >= maxAddresses">
                <i class="fa fa-plus"></i> 新增地址
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
                <span v-if="a.isDefault === 1" class="cp-badge cp-badge-yellow">默认</span>
            </div>
            <div class="addr-line-2">{{ a.province }} {{ a.city }} {{ a.district }} {{ a.detailAddress }}</div>
            <div class="addr-line-3">
                <span><i class="fa fa-clock-o"></i> 添加于 {{ formatTime(a.createTime) }}</span>
            </div>
            <div class="addr-actions">
                <button v-if="a.isDefault !== 1" class="cp-btn cp-btn-outline cp-btn-sm" @click="setDefault(a)">
                    <i class="fa fa-check-circle"></i> 默认
                </button>
                <button class="cp-btn cp-btn-outline cp-btn-sm" @click="openEditModal(a)">
                    <i class="fa fa-pencil"></i> 编辑
                </button>
                <button class="cp-btn cp-btn-outline cp-btn-sm" style="border-color:#FF00FF;color:#FF00FF;" @click="removeAddr(a)">
                    <i class="fa fa-trash-o"></i> 删除
                </button>
            </div>
        </div>
    </div>

    <!-- 空状态 -->
    <div v-else class="cp-empty">
        <i class="fa fa-map-marker"></i>
        <p>还没有添加收货地址</p>
        <button class="cp-btn cp-btn-sm" @click="openAddModal">
            <i class="fa fa-plus"></i> 立即添加
        </button>
    </div>

    <!-- 弹窗（新增 / 编辑 共用） -->
    <div :class="['cp-modal-overlay', { show: modalOpen }]" @click.self="closeModal">
        <div class="cp-modal">
            <div style="display:flex;align-items:center;">
                <div class="cp-modal-title">{{ mode === 'add' ? '新增收货地址' : '编辑收货地址' }}</div>
                <button class="cp-modal-close" @click="closeModal">&times;</button>
            </div>
            <form @submit.prevent="submitForm">
                <div class="cp-form-group">
                    <label class="cp-form-label"><span class="req">*</span>收货人</label>
                    <input v-model="form.receiverName" class="cp-form-input" maxlength="20"
                           placeholder="请填写收货人姓名" required>
                </div>
                <div class="cp-form-group">
                    <label class="cp-form-label"><span class="req">*</span>手机号</label>
                    <input v-model="form.receiverPhone" class="cp-form-input" maxlength="11"
                           placeholder="11 位手机号" required>
                </div>
                <div class="cp-form-group">
                    <label class="cp-form-label"><span class="req">*</span>所在地区</label>
                    <div class="form-row">
                        <input v-model="form.province" class="cp-form-input" maxlength="20"
                               placeholder="省" required>
                        <input v-model="form.city" class="cp-form-input" maxlength="20"
                               placeholder="市" required>
                        <input v-model="form.district" class="cp-form-input" maxlength="20"
                               placeholder="区/县" required>
                    </div>
                </div>
                <div class="cp-form-group">
                    <label class="cp-form-label"><span class="req">*</span>详细地址</label>
                    <input v-model="form.detailAddress" class="cp-form-input" maxlength="100"
                           placeholder="街道、楼栋、门牌号等" required>
                </div>
                <div class="cp-form-group">
                    <label class="form-checkbox">
                        <input type="checkbox" v-model="form.isDefault" :true-value="1" :false-value="0">
                        设为默认地址
                    </label>
                </div>
                <div class="modal-actions">
                    <button type="button" class="cp-btn cp-btn-outline" @click="closeModal">取消</button>
                    <button type="submit" class="cp-btn" :disabled="submitting">
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
