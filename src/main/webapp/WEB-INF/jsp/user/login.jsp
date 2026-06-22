<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    String error = (String) request.getAttribute("error");
    String returnUrl = request.getParameter("returnUrl");
    if (returnUrl == null) returnUrl = "";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>登录 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <style>
        body {
            background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%);
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
        }
        .login-container {
            background: #fff; border-radius: 16px; padding: 48px 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.2);
            width: 100%; max-width: 420px;
        }
        .login-title { font-size: 26px; font-weight: 700; text-align: center; margin-bottom: 8px; color: var(--color-text); }
        .login-subtitle { text-align: center; color: var(--color-muted); margin-bottom: 32px; font-size: 14px; }
        .login-tabs { display: flex; gap: 8px; margin-bottom: 24px; background: #f3f4f6; padding: 4px; border-radius: 10px; }
        .login-tab {
            flex: 1; padding: 10px; text-align: center; cursor: pointer;
            border-radius: 8px; font-size: 14px; color: var(--color-muted); transition: all 0.2s;
        }
        .login-tab.active { background: #fff; color: var(--color-primary); font-weight: 500; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
        .login-link { text-align: center; margin-top: 16px; font-size: 14px; color: var(--color-muted); }
    </style>
</head>
<body>
<div id="app" class="login-container">
    <h1 class="login-title">欢迎回来</h1>
    <p class="login-subtitle">登录后开启您的二手拍卖之旅</p>

    <!-- 错误提示（来自 Servlet） -->
    <div v-if="serverError" class="form-error text-center mb"
         style="padding: 10px; background: #fee2e2; border-radius: 8px;">
        {{ serverError }}
    </div>

    <!-- 登录方式 Tab -->
    <div class="login-tabs">
        <div :class="['login-tab', { active: loginType === 'account' }]"
             @click="loginType = 'account'">用户名登录</div>
        <div :class="['login-tab', { active: loginType === 'phone' }]"
             @click="loginType = 'phone'">手机号登录</div>
    </div>

    <form action="<%=ctx%>/user?action=login<%= returnUrl.isEmpty() ? "" : "&returnUrl=" + java.net.URLEncoder.encode(returnUrl, "UTF-8") %>"
          method="post" @submit.prevent="handleSubmit">

        <!-- 用户名/手机号 输入 -->
        <div class="form-group">
            <label class="form-label">
                {{ loginType === 'phone' ? '手机号' : '用户名' }}<span class="required">*</span>
            </label>
            <input type="text" name="username"
                   class="form-input"
                   :placeholder="loginType === 'phone' ? '请输入手机号' : '请输入用户名'"
                   v-model="form.username"
                   autocomplete="username"
                   required>
        </div>

        <!-- 密码 -->
        <div class="form-group">
            <label class="form-label">密码<span class="required">*</span></label>
            <input type="password" name="password"
                   class="form-input"
                   placeholder="请输入密码"
                   v-model="form.password"
                   autocomplete="current-password"
                   required>
        </div>

        <!-- 提交 -->
        <button type="submit" class="btn btn-primary btn-lg btn-block" :disabled="loading">
            {{ loading ? '登录中...' : '登 录' }}
        </button>

        <div class="login-link">
            还没有账号？<a href="<%=ctx%>/user?action=register">立即注册</a>
        </div>
    </form>
</div>

<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    loadVue().then(() => {
        const { createApp, ref } = Vue;
        createApp({
            setup() {
                const loginType = ref('account');
                const form = ref({ username: '', password: '' });
                const loading = ref(false);
                const serverError = ref('<%= error == null ? "" : error.replace("'", "\\'") %>');

                function handleSubmit() {
                    // 前端基础校验
                    if (!form.value.username.trim()) {
                        toast('请输入用户名/手机号', 'error');
                        return;
                    }
                    if (!form.value.password) {
                        toast('请输入密码', 'error');
                        return;
                    }
                    // 校验通过 → 提交表单
                    loading.value = true;
                    event.target.submit();
                }

                return { loginType, form, loading, serverError, handleSubmit };
            }
        }).mount('#app');
    });
</script>
</body>
</html>