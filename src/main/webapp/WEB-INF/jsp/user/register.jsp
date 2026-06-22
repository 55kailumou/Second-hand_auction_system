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
        body {
            background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%);
            min-height: 100vh; padding: 40px 16px;
            display: flex; align-items: center; justify-content: center;
        }
        .register-container {
            background: #fff; border-radius: 16px; padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.2);
            width: 100%; max-width: 480px;
        }
        .register-title { font-size: 26px; font-weight: 700; text-align: center; margin-bottom: 8px; }
        .register-subtitle { text-align: center; color: var(--color-muted); margin-bottom: 28px; font-size: 14px; }
        .check-status { font-size: 12px; margin-top: 4px; display: block; min-height: 16px; }
        .check-status.checking { color: var(--color-info); }
        .check-status.success { color: var(--color-success); }
        .check-status.error { color: var(--color-danger); }
    </style>
</head>
<body>
<div id="app" class="register-container">
    <h1 class="register-title">创建账号</h1>
    <p class="register-subtitle">加入我们，开始买卖二手好物</p>

    <!-- 错误提示（来自 Servlet） -->
    <div v-if="serverError" class="form-error text-center mb"
         style="padding: 10px; background: #fee2e2; border-radius: 8px;">
        {{ serverError }}
    </div>

    <form action="<%=ctx%>/user?action=register" method="post" @submit.prevent="handleSubmit">
        <!-- 用户名 -->
        <div class="form-group">
            <label class="form-label">用户名<span class="required">*</span></label>
            <input type="text" name="username"
                   class="form-input"
                   :class="{ 'error': touched.username && errors.username, 'success': touched.username && !errors.username && form.username }"
                   placeholder="3-20 个字符，字母/数字/下划线/中文"
                   v-model="form.username"
                   @blur="touched.username = true; validateField('username')"
                   @input="onUsernameInput"
                   required>
            <span class="check-status" :class="usernameCheck.class" v-if="form.username">
                <i v-if="usernameCheck.class === 'checking'" class="fa fa-spinner fa-spin"></i>
                <i v-else-if="usernameCheck.class === 'success'" class="fa fa-check-circle"></i>
                <i v-else-if="usernameCheck.class === 'error'" class="fa fa-times-circle"></i>
                {{ usernameCheck.msg }}
            </span>
            <span class="form-error" v-else-if="touched.username && errors.username">{{ errors.username }}</span>
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

        <!-- 手机号 -->
        <div class="form-group">
            <label class="form-label">手机号</label>
            <input type="text" name="phone"
                   class="form-input"
                   :class="{ 'error': touched.phone && errors.phone, 'success': touched.phone && !errors.phone && form.phone }"
                   placeholder="选填，但建议填写"
                   v-model="form.phone"
                   @blur="touched.phone = true; validateField('phone')"
                   @input="onPhoneInput">
            <span class="check-status" :class="phoneCheck.class" v-if="form.phone && !errors.phone && phoneCheck.class !== 'idle'">
                <i v-if="phoneCheck.class === 'checking'" class="fa fa-spinner fa-spin"></i>
                <i v-else-if="phoneCheck.class === 'success'" class="fa fa-check-circle"></i>
                <i v-else-if="phoneCheck.class === 'error'" class="fa fa-times-circle"></i>
                {{ phoneCheck.msg }}
            </span>
            <span class="form-error" v-else-if="touched.phone && errors.phone">{{ errors.phone }}</span>
        </div>

        <!-- 邮箱 -->
        <div class="form-group">
            <label class="form-label">邮箱</label>
            <input type="email" name="email"
                   class="form-input"
                   :class="{ 'error': touched.email && errors.email, 'success': touched.email && !errors.email && form.email }"
                   placeholder="选填"
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

        <div class="login-link" style="text-align: center; margin-top: 16px; font-size: 14px; color: var(--color-muted);">
            已有账号？<a href="<%=ctx%>/user?action=login">立即登录</a>
        </div>
    </form>
</div>

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
                    const usernameCheck = reactive({ class: 'idle', msg: '' });
                    const phoneCheck = reactive({ class: 'idle', msg: '' });

                    // 字段校验规则
                    function validateField(field) {
                        const v = form[field];
                        let err = '';
                        switch (field) {
                            case 'username':
                                if (!v) err = '请输入用户名';
                                else if (v.length < 3 || v.length > 20) err = '用户名长度必须 3-20';
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
                                if (v && !/^1[3-9]\d{9}$/.test(v)) err = '手机号格式不正确';
                                break;
                            case 'email':
                                if (v && !/^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$/.test(v)) err = '邮箱格式不正确';
                                break;
                        }
                        if (err) errors[field] = err; else delete errors[field];
                        return !err;
                    }

                    // 用户名输入：先校验格式，再异步查重
                    const onUsernameInput = debounce(() => {
                        if (!validateField('username')) { usernameCheck.class = 'idle'; return; }
                        usernameCheck.class = 'checking';
                        usernameCheck.msg = '检查中...';
                        axios.get('<%=ctx%>/user?action=check-username', { params: { username: form.username } })
                            .then(r => {
                                usernameCheck.class = r.data.available ? 'success' : 'error';
                                usernameCheck.msg = r.data.message;
                            })
                            .catch(() => { usernameCheck.class = 'idle'; usernameCheck.msg = ''; });
                    }, 400);

                    // 手机号输入：先校验格式，再异步查重
                    const onPhoneInput = debounce(() => {
                        if (form.phone && !validateField('phone')) { phoneCheck.class = 'idle'; return; }
                        if (!form.phone) { phoneCheck.class = 'idle'; return; }
                        phoneCheck.class = 'checking';
                        phoneCheck.msg = '检查中...';
                        axios.get('<%=ctx%>/user?action=check-phone', { params: { phone: form.phone } })
                            .then(r => {
                                phoneCheck.class = r.data.available ? 'success' : 'error';
                                phoneCheck.msg = r.data.message;
                            })
                            .catch(() => { phoneCheck.class = 'idle'; phoneCheck.msg = ''; });
                    }, 400);

                    function handleSubmit() {
                        // 全字段校验
                        const fields = ['username', 'password', 'confirmPassword', 'phone', 'email'];
                        let ok = true;
                        fields.forEach(f => { touched[f] = true; if (!validateField(f)) ok = false; });
                        if (!ok) { toast('请检查表单填写', 'error'); return; }
                        if (!agreed.value) { toast('请同意用户协议', 'error'); return; }

                        loading.value = true;
                        event.target.submit();
                    }

                    return {
                        form, errors, touched, loading, agreed, serverError, showAgreement,
                        usernameCheck, phoneCheck,
                        onUsernameInput, onPhoneInput, handleSubmit
                    };
                }
            }).mount('#app');
        });
    });
</script>
</body>
</html>