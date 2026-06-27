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
    <title>// 登录 · 二手拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 登录页 Cyberpunk 风格
         * ============================================================ */
        body {
            min-height: 100vh;
            display: flex; align-items: center; justify-content: center;
            padding: 24px 16px;
        }
        .auth-wrap {
            width: 100%; max-width: 880px;
            display: grid; grid-template-columns: 1fr 420px;
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(0 0, calc(100% - 20px) 0, 100% 20px, 100% 100%, 20px 100%, 0 calc(100% - 20px));
            box-shadow: 0 0 48px rgba(255,238,0,0.15);
            position: relative; z-index: 10;
        }
        @media (max-width: 768px) {
            .auth-wrap { grid-template-columns: 1fr; max-width: 420px; }
            .auth-side { display: none; }
        }
        .auth-side {
            padding: 40px 36px;
            display: flex; flex-direction: column;
            justify-content: space-between; min-height: 520px;
            background:
                radial-gradient(ellipse at 30% 30%, rgba(255,238,0,0.08) 0%, transparent 50%),
                radial-gradient(ellipse at 70% 80%, rgba(0,240,255,0.05) 0%, transparent 40%),
                #000;
            border-right: 1px solid var(--cp-yellow);
        }
        .auth-brand {
            display: flex; align-items: center; gap: 10px;
            font-size: 20px; font-weight: 900; font-style: italic;
            color: var(--cp-yellow);
            text-transform: uppercase;
            text-shadow: 0 0 12px rgba(255,238,0,0.4);
        }
        .auth-brand .logo-icon {
            width: 30px; height: 30px;
            background: var(--cp-yellow); color: #000;
            clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
            display: grid; place-items: center;
            font-size: 14px;
        }
        .auth-slogan { margin-top: 28px; }
        .auth-slogan h2 {
            font-size: 24px; font-weight: 900; font-style: italic;
            color: var(--cp-yellow);
            line-height: 1.4; margin-bottom: 12px;
            text-shadow: 0 0 8px rgba(255,238,0,0.3);
        }
        .auth-slogan p {
            font-size: 13px; color: var(--cp-text-dim);
            line-height: 1.7;
            font-family: var(--font-mono);
            border-left: 2px solid var(--cp-yellow);
            padding-left: 12px;
        }
        .auth-features { display: flex; flex-direction: column; gap: 12px; }
        .auth-feat {
            display: flex; align-items: center; gap: 10px;
            font-size: 12px; color: var(--cp-text);
            font-family: var(--font-mono);
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .auth-feat i {
            width: 28px; height: 28px;
            background: rgba(255,238,0,0.1);
            color: var(--cp-yellow);
            border: 1px solid var(--cp-yellow);
            clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
            display: grid; place-items: center; font-size: 12px;
            flex-shrink: 0;
        }
        .auth-side-foot {
            font-size: 10px; color: var(--cp-text-dim);
            font-family: var(--font-mono);
            text-transform: uppercase;
            letter-spacing: 0.1em;
        }

        .auth-main { padding: 40px 40px 36px; }
        .auth-title {
            font-size: 22px; font-weight: 900; font-style: italic;
            color: var(--cp-yellow);
            text-transform: uppercase;
            margin-bottom: 6px;
            text-shadow: 0 0 8px rgba(255,238,0,0.3);
        }
        .auth-subtitle {
            font-size: 12px; color: var(--cp-text-dim);
            margin-bottom: 26px;
            font-family: var(--font-mono);
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .auth-error {
            padding: 10px 14px;
            background: rgba(255,0,60,0.1);
            color: var(--cp-red);
            border: 1px solid var(--cp-red);
            clip-path: polygon(6px 0, 100% 0, 100% calc(100% - 6px), calc(100% - 6px) 100%, 0 100%, 0 6px);
            font-size: 12px;
            margin-bottom: 18px;
            display: flex; align-items: center; gap: 8px;
            font-family: var(--font-mono);
        }
        .auth-link {
            text-align: center;
            margin-top: 18px;
            font-size: 12px;
            color: var(--cp-text-dim);
            font-family: var(--font-mono);
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }
        .auth-link a { color: var(--cp-yellow); }
        .auth-link a:hover { text-shadow: 0 0 8px var(--cp-yellow); }
    </style>
</head>
<body>
<div id="app" class="auth-wrap">
    <div class="scanline" style="z-index:1;"></div>

    <!-- 左侧品牌区 -->
    <div class="auth-side">
        <div>
            <div class="auth-brand">
                <span class="logo-icon"><i class="fa fa-gavel"></i></span>
                <span>赛博拍卖</span>
            </div>
            <div style="margin-top:8px;font-family:var(--font-mono);font-size:10px;color:var(--cp-yellow-dim);text-transform:uppercase;letter-spacing:0.15em;">// 在线拍卖网络</div>
            <div class="auth-slogan">
                <h2>&gt; 登录<br>&gt; 进入赛博空间</h2>
                <p>// 闲置流转 // 价值新生<br>// 透明 // 安全 // 高效</p>
            </div>
        </div>
        <div class="auth-features">
            <div class="auth-feat"><i class="fa fa-shield"></i> 担保交易 · 出价有保障</div>
            <div class="auth-feat"><i class="fa fa-check-circle"></i> 实名认证 · 信用可查</div>
            <div class="auth-feat"><i class="fa fa-truck"></i> 包邮到家 · 7 天可退</div>
        </div>
        <div class="auth-side-foot">// 2025 赛博拍卖系统</div>
    </div>

    <!-- 右侧表单 -->
    <div class="auth-main">
    <div class="module-tag">// 身份验证</div>
    <h1 class="auth-title">欢迎回来</h1>
    <p class="auth-subtitle">&gt;&gt; 登录后开启您的赛博拍卖之旅</p>

    <!-- 错误提示 -->
    <div v-if="serverError" class="auth-error">
        <i class="fa fa-exclamation-circle"></i>
        <span>{{ serverError }}</span>
    </div>

    <form action="<%=ctx%>/user?action=login<%= returnUrl.isEmpty() ? "" : "&returnUrl=" + java.net.URLEncoder.encode(returnUrl, "UTF-8") %>"
          method="post" @submit.prevent="handleSubmit($event)">

        <div class="cp-form-group">
            <label class="cp-form-label">手机号 / 邮箱<span class="required">*</span></label>
            <input type="text" name="account"
                   class="cp-form-input"
                   placeholder="> 请输入手机号或邮箱"
                   v-model="form.account"
                   autocomplete="username"
                   required>
        </div>

        <div class="cp-form-group">
            <label class="cp-form-label">密码<span class="required">*</span></label>
            <input type="password" name="password"
                   class="cp-form-input"
                   placeholder="> 请输入密码"
                   v-model="form.password"
                   autocomplete="current-password"
                   required>
        </div>

        <button type="submit" class="cp-btn cp-btn-lg cp-btn-block" :disabled="loading" style="margin-top:8px;">
            {{ loading ? '// 验证中...' : '登 录' }}
        </button>

        <div class="auth-link">
            &gt; 还没有账号？<a href="<%=ctx%>/user?action=register">立即注册</a>
        </div>
    </form>
    </div>
</div>

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
                    const account = form.value.account.trim();
                    if (!account) {
                        toast('请输入手机号或邮箱', 'error');
                        return;
                    }
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