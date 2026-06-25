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
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 管理后台登录 v1 · 暗色系
         * - 居中卡片
         * - 渐变背景
         * - 简洁表单
         * ============================================================ */
        * { box-sizing: border-box; }
        body {
            margin: 0; min-height: 100vh;
            background: linear-gradient(135deg, #1f2937 0%, #111827 100%);
            display: flex; align-items: center; justify-content: center;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", sans-serif;
        }
        .login-card {
            background: #fff; border-radius: 12px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            width: 100%; max-width: 400px; padding: 40px 36px;
        }
        .login-logo {
            display: flex; align-items: center; justify-content: center;
            gap: 10px; margin-bottom: 8px;
        }
        .login-logo-icon {
            width: 48px; height: 48px; background: linear-gradient(135deg, #1f2937, #374151);
            color: #fff; border-radius: 8px; display: grid; place-items: center;
            font-size: 22px;
        }
        .login-title {
            font-size: 22px; font-weight: 800; color: #1f2937;
        }
        .login-sub {
            text-align: center; color: #6b7280; font-size: 13px;
            margin-bottom: 28px;
        }
        .form-group { margin-bottom: 16px; }
        .form-label {
            display: block; font-size: 13px; color: #374151;
            margin-bottom: 6px; font-weight: 500;
        }
        .form-input-wrap {
            position: relative;
        }
        .form-input-wrap i {
            position: absolute; left: 12px; top: 50%;
            transform: translateY(-50%); color: #9ca3af;
        }
        .form-input {
            width: 100%; padding: 11px 14px 11px 38px;
            border: 1.5px solid #e5e7eb; border-radius: 6px;
            font-size: 14px; outline: none; transition: all 0.15s;
        }
        .form-input:focus {
            border-color: #1f2937;
            box-shadow: 0 0 0 3px rgba(31,41,55,0.1);
        }
        .btn-submit {
            width: 100%; padding: 12px; background: #1f2937; color: #fff;
            border: none; border-radius: 6px; font-size: 15px;
            font-weight: 600; cursor: pointer; transition: all 0.15s;
            margin-top: 8px;
        }
        .btn-submit:hover:not(:disabled) { background: #111827; }
        .btn-submit:disabled { opacity: 0.6; cursor: not-allowed; }

        .alert {
            padding: 10px 14px; border-radius: 6px;
            font-size: 13px; margin-bottom: 16px;
        }
        .alert-error { background: #fee2e2; color: #b91c1c; }
        .alert-info  { background: #dbeafe; color: #1e40af; }

        .login-tip {
            text-align: center; font-size: 12px; color: #9ca3af;
            margin-top: 20px; padding-top: 16px;
            border-top: 1px solid #f3f4f6;
            line-height: 1.7;
        }
        .login-tip code {
            background: #f3f4f6; color: #1f2937;
            padding: 2px 6px; border-radius: 3px; font-size: 12px;
        }
        .login-footer {
            position: fixed; bottom: 16px; left: 0; right: 0;
            text-align: center; color: #6b7280; font-size: 12px;
        }
    </style>
</head>
<body>

<div class="login-card">
    <div class="login-logo">
        <div class="login-logo-icon"><i class="fa fa-gavel"></i></div>
        <div class="login-title">管理后台</div>
    </div>
    <div class="login-sub">二手物品拍卖系统 · Admin</div>

    <div id="alertBox"></div>

    <form id="loginForm">
        <div class="form-group">
            <label class="form-label">登录账号</label>
            <div class="form-input-wrap">
                <i class="fa fa-user-o"></i>
                <input type="text" name="account" class="form-input" placeholder="admin" required>
            </div>
        </div>
        <div class="form-group">
            <label class="form-label">登录密码</label>
            <div class="form-input-wrap">
                <i class="fa fa-lock"></i>
                <input type="password" name="password" class="form-input" placeholder="••••••" required>
            </div>
        </div>
        <button type="submit" class="btn-submit" id="submitBtn">
            <i class="fa fa-sign-in"></i> 登录
        </button>
    </form>

    <div class="login-tip">
        默认账号 <code>admin</code> / 密码 <code>123456</code><br>
        首次登录后建议修改密码
    </div>
</div>

<div class="login-footer">
    © 2025 二手物品拍卖系统 · JSP + Servlet + MyBatis
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
