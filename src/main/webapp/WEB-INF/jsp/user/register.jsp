<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    String error = (String) request.getAttribute("error");
    String preUsername = (String) request.getAttribute("preUsername");
    String prePhone = (String) request.getAttribute("prePhone");
    String preEmail = (String) request.getAttribute("preEmail");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>注册 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 注册页 v2 · 跟首页/列表/详情/登录保持同一套设计语言
         * - body 浅灰 #f5f5f5（与其他页一致）
         * - 白底卡 8px 圆角 + 弱阴影（与其他页一致）
         * - 顶部品牌区：橙红 gavel icon + "二手拍卖"
         * - 输入框、按钮、错误条全部走 common.css 风格
         * ============================================================ */
        body {
            background: #f5f5f5;
            min-height: 100vh; padding: 24px 16px;
            display: flex; align-items: center; justify-content: center;
        }
        .auth-wrap {
            width: 100%; max-width: 880px;
            display: grid; grid-template-columns: 1fr 480px;
            background: #fff; border-radius: 8px; overflow: hidden;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        }
        @media (max-width: 768px) {
            .auth-wrap { grid-template-columns: 1fr; max-width: 480px; }
            .auth-side { display: none; }
        }
        /* 左侧品牌区（与登录页同款） */
        .auth-side {
            background:
                linear-gradient(135deg, rgba(255,107,53,0.10) 0%, rgba(255,107,53,0.02) 100%),
                linear-gradient(45deg, #fef3c7 0%, #fed7aa 60%, #fdba74 100%);
            padding: 40px 36px; display: flex; flex-direction: column;
            justify-content: space-between; min-height: 640px;
        }
        .auth-brand {
            display: flex; align-items: center; gap: 8px;
            font-size: 20px; font-weight: 800; color: var(--color-primary);
        }
        .auth-brand .logo-icon {
            width: 30px; height: 30px; background: var(--color-primary);
            color: #fff; border-radius: 4px; display: grid; place-items: center;
            font-size: 14px;
        }
        .auth-slogan { margin-top: 28px; }
        .auth-slogan h2 {
            font-size: 24px; font-weight: 700; color: var(--color-text);
            line-height: 1.4; margin-bottom: 12px;
        }
        .auth-slogan p { font-size: 13px; color: #6b7280; line-height: 1.7; }
        .auth-features { display: flex; flex-direction: column; gap: 12px; }
        .auth-feat { display: flex; align-items: center; gap: 10px; font-size: 13px; color: var(--color-text); }
        .auth-feat i {
            width: 28px; height: 28px; border-radius: 50%;
            background: #fff; color: var(--color-primary);
            display: grid; place-items: center; font-size: 13px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04); flex-shrink: 0;
        }
        .auth-side-foot { font-size: 12px; color: #92400e; }

        /* 右侧表单区 */
        .auth-main { padding: 36px 40px; }
        .auth-title { font-size: 22px; font-weight: 700; color: var(--color-text); margin-bottom: 6px; }
        .auth-subtitle { font-size: 13px; color: var(--color-muted); margin-bottom: 22px; }
        .auth-error {
            padding: 10px 14px; background: #fee2e2; color: var(--color-danger);
            border-radius: 6px; font-size: 13px; margin-bottom: 18px;
            display: flex; align-items: center; gap: 8px;
        }
        .auth-link { text-align: center; margin-top: 16px; font-size: 13px; color: var(--color-muted); }
        .check-status { font-size: 12px; margin-top: 4px; display: block; min-height: 16px; }
        .check-status.checking { color: var(--color-info); }
        .check-status.success { color: var(--color-success); }
        .check-status.error { color: var(--color-danger); }
    </style>
</head>
<body>
<div id="app" class="auth-wrap">
    <!-- 左侧品牌区 -->
    <div class="auth-side">
        <div>
            <div class="auth-brand">
                <span class="logo-icon"><i class="fa fa-gavel"></i></span>
                <span>二手拍卖</span>
            </div>
            <div class="auth-slogan">
                <h2>加入二手拍卖<br>开启闲置好生活</h2>
                <p>1 分钟注册，立即参与竞拍 / 发布好物<br>千万用户在线交易，安全有保障</p>
            </div>
        </div>
        <div class="auth-features">
            <div class="auth-feat"><i class="fa fa-shield"></i> 担保交易 · 出价有保障</div>
            <div class="auth-feat"><i class="fa fa-check-circle"></i> 实名认证 · 信用可查</div>
            <div class="auth-feat"><i class="fa fa-truck"></i> 包邮到家 · 7 天可退</div>
        </div>
        <div class="auth-side-foot">© 2025 二手物品拍卖系统</div>
    </div>

    <!-- 右侧表单 -->
    <div class="auth-main">
    <h1 class="auth-title">创建账号</h1>
    <p class="auth-subtitle">加入我们，开始买卖二手好物</p>

    <!-- 错误提示（来自 Servlet） -->
    <div v-if="serverError" class="auth-error">
        <i class="fa fa-exclamation-circle"></i>
        <span>{{ serverError }}</span>
    </div>

    <form action="<%=ctx%>/user?action=register" method="post" @submit.prevent="handleSubmit($event)">
        <!-- 用户名（必填，可重复，仅展示用） -->
        <div class="form-group">
            <label class="form-label">用户名<span class="required">*</span></label>
            <input type="text" name="username"
                   class="form-input"
                   :class="{ 'error': touched.username && errors.username, 'success': touched.username && !errors.username && form.username }"
                   placeholder="2-20 个字符，字母/数字/下划线/中文（用户名可重复）"
                   v-model="form.username"
                   @blur="touched.username = true; validateField('username')"
                   required>
            <span class="form-error" v-if="touched.username && errors.username">{{ errors.username }}</span>
        </div>

        <!-- 密码 -->
        <div class="form-group">
            <label class="form-label">密码<span class="required">*</span></label>
            <input type="password" name="password"
                   class="form-input"
                   :class="{ 'error': touched.password && errors.password, 'success': touched.password && !errors.password }"
                   placeholder="6-20 个字符"
                   v-model="form.password"
                   @blur="touched.password = true; validateField('password')"
                   required>
            <span class="form-error" v-if="touched.password && errors.password">{{ errors.password }}</span>
        </div>

        <!-- 确认密码 -->
        <div class="form-group">
            <label class="form-label">确认密码<span class="required">*</span></label>
            <input type="password" name="confirmPassword"
                   class="form-input"
                   :class="{ 'error': touched.confirmPassword && errors.confirmPassword, 'success': touched.confirmPassword && !errors.confirmPassword && form.confirmPassword }"
                   placeholder="请再次输入密码"
                   v-model="form.confirmPassword"
                   @blur="touched.confirmPassword = true; validateField('confirmPassword')"
                   required>
            <span class="form-error" v-if="touched.confirmPassword && errors.confirmPassword">{{ errors.confirmPassword }}</span>
        </div>

        <!-- 手机号（必填，唯一） -->
        <div class="form-group">
            <label class="form-label">手机号<span class="required">*</span></label>
            <input type="text" name="phone"
                   class="form-input"
                   :class="{ 'error': touched.phone && errors.phone, 'success': touched.phone && !errors.phone && form.phone }"
                   placeholder="11 位手机号，用于登录"
                   v-model="form.phone"
                   @blur="touched.phone = true; validateField('phone')"
                   @input="onPhoneInput"
                   required>
            <span class="check-status" :class="phoneCheck.class" v-if="form.phone && !errors.phone && phoneCheck.class !== 'idle'">
                <i v-if="phoneCheck.class === 'checking'" class="fa fa-spinner fa-spin"></i>
                <i v-else-if="phoneCheck.class === 'success'" class="fa fa-check-circle"></i>
                <i v-else-if="phoneCheck.class === 'error'" class="fa fa-times-circle"></i>
                {{ phoneCheck.msg }}
            </span>
            <span class="form-error" v-else-if="touched.phone && errors.phone">{{ errors.phone }}</span>
        </div>

        <!-- 邮箱（选填，唯一） -->
        <div class="form-group">
            <label class="form-label">邮箱<span style="color: var(--color-muted); font-weight: 400; font-size: 12px;">（选填，可用于登录）</span></label>
            <input type="email" name="email"
                   class="form-input"
                   :class="{ 'error': touched.email && errors.email, 'success': touched.email && !errors.email && form.email }"
                   placeholder="example@domain.com"
                   v-model="form.email"
                   @blur="touched.email = true; validateField('email')">
            <span class="form-error" v-if="touched.email && errors.email">{{ errors.email }}</span>
        </div>

        <!-- 用户协议 -->
        <div class="form-group">
            <label style="display: flex; align-items: center; gap: 8px; cursor: pointer; user-select: none;">
                <input type="checkbox" v-model="agreed" required>
                <span style="font-size: 14px; color: var(--color-muted);">
                    我已阅读并同意 <a href="javascript:void(0)" @click.stop="showAgreement = true">《用户协议》</a>
                </span>
            </label>
        </div>

        <button type="submit" class="btn btn-primary btn-lg btn-block" :disabled="loading || !agreed">
            {{ loading ? '注册中...' : '注 册' }}
        </button>

        <div class="auth-link">
            已有账号？<a href="<%=ctx%>/user?action=login">立即登录</a>
        </div>
    </form>
    </div><!-- /auth-main -->
</div><!-- /auth-wrap -->

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    loadVue().then(() => {
        loadAxios().then(() => {
            const { createApp, ref, reactive } = Vue;
            createApp({
                setup() {
                    const form = reactive({
                        username: '<%= preUsername == null ? "" : preUsername %>',
                        password: '',
                        confirmPassword: '',
                        phone: '<%= prePhone == null ? "" : prePhone %>',
                        email: '<%= preEmail == null ? "" : preEmail %>'
                    });
                    const errors = reactive({});
                    const touched = reactive({});
                    const loading = ref(false);
                    const agreed = ref(false);
                    const serverError = ref('<%= error == null ? "" : error.replace("'", "\\'") %>');
                    const showAgreement = ref(false);
                    const phoneCheck = reactive({ class: 'idle', msg: '' });

                    // 字段校验规则
                    function validateField(field) {
                        const v = form[field];
                        let err = '';
                        switch (field) {
                            case 'username':
                                // 用户名必填，可重复
                                if (!v) err = '请输入用户名';
                                else if (v.length < 2 || v.length > 20) err = '用户名长度必须 2-20';
                                else if (!/^[a-zA-Z0-9_\u4e00-\u9fa5]+$/.test(v)) err = '只能含字母、数字、下划线、中文';
                                break;
                            case 'password':
                                if (!v) err = '请输入密码';
                                else if (v.length < 6 || v.length > 20) err = '密码长度 6-20';
                                break;
                            case 'confirmPassword':
                                if (!v) err = '请再次输入密码';
                                else if (v !== form.password) err = '两次密码不一致';
                                break;
                            case 'phone':
                                if (!v) err = '请输入手机号';
                                else if (!/^1[3-9]\d{9}$/.test(v)) err = '手机号格式不正确';
                                break;
                            case 'email':
                                if (v && !/^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$/.test(v)) err = '邮箱格式不正确';
                                break;
                        }
                        if (err) errors[field] = err; else delete errors[field];
                        return !err;
                    }

                    // 手机号输入：先校验格式，再异步查重
                    const onPhoneInput = debounce(() => {
                        if (form.phone && !validateField('phone')) { phoneCheck.class = 'idle'; return; }
                        if (!form.phone) { phoneCheck.class = 'idle'; return; }
                        if (!/^1[3-9]\d{9}$/.test(form.phone)) return; // 格式不对不查
                        phoneCheck.class = 'checking';
                        phoneCheck.msg = '检查中...';
                        axios.get('<%=ctx%>/user?action=check-phone', { params: { phone: form.phone } })
                            .then(r => {
                                phoneCheck.class = r.data.available ? 'success' : 'error';
                                phoneCheck.msg = r.data.message;
                            })
                            .catch(() => { phoneCheck.class = 'idle'; phoneCheck.msg = ''; });
                    }, 400);

                    function handleSubmit(e) {
                        // 全字段校验
                        const fields = ['username', 'password', 'confirmPassword', 'phone', 'email'];
                        let ok = true;
                        fields.forEach(f => { touched[f] = true; if (!validateField(f)) ok = false; });
                        if (!ok) { toast('请检查表单填写', 'error'); return; }
                        if (!agreed.value) { toast('请同意用户协议', 'error'); return; }

                        loading.value = true;
                        e.target.submit();
                    }

                    return {
                        form, errors, touched, loading, agreed, serverError, showAgreement,
                        phoneCheck,
                        onPhoneInput, handleSubmit
                    };
                }
            }).mount('#app');
        });
    });
</script>
</body>
</html>