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
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 登录页 v2 · 跟首页/列表/详情保持同一套设计语言
         * - body 浅灰 #f5f5f5（与其他页一致）
         * - 白底卡 8px 圆角 + 弱阴影（与其他页一致）
         * - 顶部品牌区：橙红 gavel icon + "二手拍卖"
         * - 输入框、按钮、错误条全部走 common.css 风格
         * ============================================================ */
        body {
            background: #f5f5f5;
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            padding: 24px 16px;
        }
        .auth-wrap {
            width: 100%; max-width: 880px;
            display: grid; grid-template-columns: 1fr 420px;
            background: #fff; border-radius: 8px; overflow: hidden;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        }
        @media (max-width: 768px) {
            .auth-wrap { grid-template-columns: 1fr; max-width: 420px; }
            .auth-side { display: none; }
        }
        /* 左侧品牌区（仿首页 banner 风格） */
        .auth-side {
            background:
                linear-gradient(135deg, rgba(255,107,53,0.10) 0%, rgba(255,107,53,0.02) 100%),
                linear-gradient(45deg, #fef3c7 0%, #fed7aa 60%, #fdba74 100%);
            padding: 40px 36px; display: flex; flex-direction: column;
            justify-content: space-between; min-height: 520px;
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
        .auth-main { padding: 40px 40px 36px; }
        .auth-title { font-size: 22px; font-weight: 700; color: var(--color-text); margin-bottom: 6px; }
        .auth-subtitle { font-size: 13px; color: var(--color-muted); margin-bottom: 26px; }
        .auth-error {
            padding: 10px 14px; background: #fee2e2; color: var(--color-danger);
            border-radius: 6px; font-size: 13px; margin-bottom: 18px;
            display: flex; align-items: center; gap: 8px;
        }
        .auth-link { text-align: center; margin-top: 18px; font-size: 13px; color: var(--color-muted); }
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
                <h2>让闲置流转<br>让价值新生</h2>
                <p>透明、安全、高效的二手物品竞拍平台<br>登录即可参与拍品竞价、发布个人好物</p>
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
    <h1 class="auth-title">欢迎回来</h1>
    <p class="auth-subtitle">登录后开启您的二手拍卖之旅</p>

    <!-- 错误提示（来自 Servlet） -->
    <div v-if="serverError" class="auth-error">
        <i class="fa fa-exclamation-circle"></i>
        <span>{{ serverError }}</span>
    </div>

    <form action="<%=ctx%>/user?action=login<%= returnUrl.isEmpty() ? "" : "&returnUrl=" + java.net.URLEncoder.encode(returnUrl, "UTF-8") %>"
          method="post" @submit.prevent="handleSubmit($event)">

        <!-- 手机号 / 邮箱 输入 -->
        <div class="form-group">
            <label class="form-label">手机号 / 邮箱<span class="required">*</span></label>
            <input type="text" name="account"
                   class="form-input"
                   placeholder="请输入注册时使用的手机号或邮箱"
                   v-model="form.account"
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

        <div class="auth-link">
            还没有账号？<a href="<%=ctx%>/user?action=register">立即注册</a>
        </div>
    </form>
    </div><!-- /auth-main -->
</div><!-- /auth-wrap -->

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    loadVue().then(() => {
        const { createApp, ref } = Vue;
        createApp({
            setup() {
                const form = ref({ account: '', password: '' });
                const loading = ref(false);
                const serverError = ref('<%= error == null ? "" : error.replace("'", "\\'") %>');

                function handleSubmit(e) {
                    // 前端基础校验
                    const account = form.value.account.trim();
                    if (!account) {
                        toast('请输入手机号或邮箱', 'error');
                        return;
                    }
                    // 简单格式校验
                    const isPhone = /^1[3-9]\d{9}$/.test(account);
                    const isEmail = /^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$/.test(account);
                    if (!isPhone && !isEmail) {
                        toast('请输入正确的手机号或邮箱', 'error');
                        return;
                    }
                    if (!form.value.password) {
                        toast('请输入密码', 'error');
                        return;
                    }
                    // 校验通过 → 提交表单（接收 Vue 传来的 $event）
                    loading.value = true;
                    e.target.submit();
                }

                return { form, loading, serverError, handleSubmit };
            }
        }).mount('#app');
    });
</script>
</body>
</html>