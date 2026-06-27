<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    String error = (String) request.getAttribute("error");
    // 已登录 → 直接跳后台首页
    if (session.getAttribute("currentAdmin") != null) {
        response.sendRedirect(ctx + "/admin");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理后台登录 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body {
            margin: 0; min-height: 100vh;
            background: #000;
            display: flex; align-items: center; justify-content: center;
            font-family: var(--font-display);
            position: relative;
        }
        .login-card {
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(0 0, calc(100% - 20px) 0, 100% 20px, 100% 100%, 20px 100%, 0 calc(100% - 20px));
            box-shadow: 0 0 48px rgba(255,238,0,0.2);
            width: 100%; max-width: 420px; padding: 40px 36px;
            position: relative; z-index: 3;
        }
        .login-logo {
            display: flex; align-items: center; justify-content: center;
            gap: 10px; margin-bottom: 8px;
        }
        .login-logo-icon {
            width: 48px; height: 48px;
            background: var(--cp-yellow); color: #000;
            clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
            display: grid; place-items: center;
            font-size: 22px; font-weight: 900;
        }
        .login-title {
            font-size: 22px; font-weight: 900; font-style: italic;
            color: var(--cp-yellow); text-shadow: 0 0 12px rgba(255,238,0,0.4);
            text-transform: uppercase;
        }
        .login-sub {
            text-align: center;
            font-family: var(--font-mono);
            color: var(--cp-yellow-dim); font-size: 11px;
            text-transform: uppercase; letter-spacing: 0.1em;
            margin-bottom: 28px;
        }
        .alert {
            padding: 10px 14px; font-family: var(--font-mono); font-size: 11px;
            margin-bottom: 16px; text-transform: uppercase; letter-spacing: 0.05em;
        }
        .alert-error {
            background: rgba(255,0,60,0.15); color: var(--cp-red);
            border: 1px solid var(--cp-red);
        }
        .alert-info {
            background: rgba(0,240,255,0.15); color: var(--cp-cyan);
            border: 1px solid var(--cp-cyan);
        }
        .login-tip {
            text-align: center;
            font-family: var(--font-mono); font-size: 10px;
            color: var(--cp-text-dim);
            margin-top: 20px; padding-top: 16px;
            border-top: 1px solid rgba(255,238,0,0.15);
            line-height: 1.7;
            text-transform: uppercase; letter-spacing: 0.05em;
        }
        .login-tip code {
            background: rgba(255,238,0,0.1); color: var(--cp-yellow);
            padding: 2px 6px; font-size: 10px; font-family: var(--font-mono);
        }
        .login-footer {
            position: fixed; bottom: 16px; left: 0; right: 0;
            text-align: center;
            font-family: var(--font-mono); font-size: 10px;
            color: var(--cp-text-dim); z-index: 3;
        }
    </style>
</head>
<body>

<div class="scanline" style="z-index: 2;"></div>

<div class="login-card">
    <div class="module-tag" style="justify-content: center;">管理后台 · 身份验证</div>
    <div class="login-logo">
        <div class="login-logo-icon"><i class="fa fa-gavel"></i></div>
        <div class="login-title">管理后台</div>
    </div>
    <div class="login-sub">二手物品拍卖系统 · Admin</div>

    <div id="alertBox"></div>

    <form id="loginForm">
        <div class="cp-form-group">
            <label class="cp-form-label">登录账号</label>
            <div class="cp-form-input-wrap">
                <input type="text" name="account" class="cp-form-input" placeholder="admin" required>
            </div>
        </div>
        <div class="cp-form-group">
            <label class="cp-form-label">登录密码</label>
            <div class="cp-form-input-wrap">
                <input type="password" name="password" class="cp-form-input" placeholder="••••••" required>
            </div>
        </div>
        <button type="submit" class="cp-btn cp-btn-block" id="submitBtn">
            <i class="fa fa-sign-in"></i> 登录
        </button>
    </form>

    <div class="login-tip">
        默认账号 <code>admin</code> / 密码 <code>123456</code><br>
        首次登录后建议修改密码
    </div>
</div>

<div class="login-footer">
    &copy; 2025 二手物品拍卖系统 · JSP + Servlet + MyBatis
</div>

<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath = '<%=ctx%>';

    function showAlert(msg, type) {
        const box = document.getElementById('alertBox');
        box.innerHTML = '<div class="alert alert-' + (type || 'error') + '"><i class="fa fa-exclamation-circle"></i> ' + msg + '</div>';
    }

    document.getElementById('loginForm').addEventListener('submit', function(e) {
        e.preventDefault();
        const form = new FormData(e.target);
        const submitBtn = document.getElementById('submitBtn');
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> 登录中...';

        loadAxios().then(() => {
            axios.post(ctxPath + '/admin/login', new URLSearchParams({
                account: form.get('account'),
                password: form.get('password')
            })).then(r => {
                if (r.data.success) {
                    showAlert('登录成功，正在跳转...', 'info');
                    setTimeout(() => {
                        const returnUrl = new URLSearchParams(window.location.search).get('returnUrl') || '/admin';
                        window.location.href = ctxPath + returnUrl;
                    }, 600);
                } else {
                    showAlert(r.data.message || '登录失败', 'error');
                    submitBtn.disabled = false;
                    submitBtn.innerHTML = '<i class="fa fa-sign-in"></i> 登录';
                }
            }).catch(() => {
                showAlert('网络错误', 'error');
                submitBtn.disabled = false;
                submitBtn.innerHTML = '<i class="fa fa-sign-in"></i> 登录';
            });
        });
    });
</script>
</body>
</html>
