<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>二手物品拍卖系统 · 首页</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: var(--color-bg); }
        .header {
            background: #fff; padding: 16px 0;
            box-shadow: var(--shadow-sm); position: sticky; top: 0; z-index: 100;
        }
        .header-inner {
            max-width: 1200px; margin: 0 auto; padding: 0 24px;
            display: flex; align-items: center; justify-content: space-between;
        }
        .logo {
            font-size: 22px; font-weight: 700; color: var(--color-primary);
            display: flex; align-items: center; gap: 8px;
        }
        .nav { display: flex; gap: 28px; }
        .nav a { color: var(--color-text); font-size: 15px; transition: color 0.2s; }
        .nav a:hover { color: var(--color-primary); }

        .user-info { display: flex; align-items: center; gap: 16px; font-size: 14px; }
        .user-name { color: var(--color-text); font-weight: 500; }
        .user-balance { color: var(--color-primary); font-weight: 600; }

        .hero {
            background: linear-gradient(135deg, #ff6b35 0%, #f7931e 100%);
            color: #fff; padding: 60px 24px; text-align: center;
        }
        .hero h1 { font-size: 36px; margin-bottom: 12px; }
        .hero p { font-size: 16px; opacity: 0.9; margin-bottom: 28px; }
        .hero-search {
            max-width: 600px; margin: 0 auto; display: flex; gap: 0;
            background: #fff; border-radius: 12px; overflow: hidden;
            box-shadow: 0 10px 30px rgba(0,0,0,0.15);
        }
        .hero-search input {
            flex: 1; padding: 16px 20px; border: none; outline: none; font-size: 15px; color: var(--color-text);
        }
        .hero-search button {
            padding: 0 32px; background: var(--color-primary); color: #fff;
            font-size: 15px; font-weight: 500; border: none; cursor: pointer;
            transition: background 0.2s;
        }
        .hero-search button:hover { background: var(--color-primary-hover); }

        .section-title {
            font-size: 22px; font-weight: 700; margin: 40px 0 20px;
            display: flex; align-items: center; gap: 8px;
        }
        .section-title::before {
            content: ''; display: inline-block; width: 4px; height: 22px;
            background: var(--color-primary); border-radius: 2px;
        }

        .features {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px; margin-bottom: 40px;
        }
        .feature-card {
            background: #fff; padding: 24px; border-radius: var(--radius);
            box-shadow: var(--shadow-sm); transition: all 0.2s;
            display: flex; align-items: center; gap: 16px; cursor: pointer;
        }
        .feature-card:hover { box-shadow: var(--shadow); transform: translateY(-2px); }
        .feature-icon {
            width: 48px; height: 48px; border-radius: 12px;
            background: var(--color-primary-light); color: var(--color-primary);
            display: flex; align-items: center; justify-content: center;
            font-size: 22px;
        }
        .feature-title { font-size: 16px; font-weight: 600; margin-bottom: 4px; }
        .feature-desc { font-size: 13px; color: var(--color-muted); }
    </style>
</head>
<body>

<!-- 顶部导航 -->
<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <i class="fa fa-gavel"></i> 二手拍卖
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="javascript:void(0)" onclick="go('/item/list')">浏览拍品</a>
            <a href="javascript:void(0)" onclick="go('/item/publish')">发布拍品</a>
            <a href="javascript:void(0)" onclick="go('/user/center')">个人中心</a>
        </nav>
        <div class="user-info">
            <% if (currentUser != null) { %>
                <span>欢迎，</span>
                <span class="user-name"><%= currentUser.getUsername() %></span>
                <span class="user-balance"><%= String.format("￥%.2f", currentUser.getBalance()) %></span>
                <a href="<%=ctx%>/user?action=logout" class="btn btn-secondary btn-sm">退出</a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" class="btn btn-ghost btn-sm">登录</a>
                <a href="<%=ctx%>/user?action=register" class="btn btn-primary btn-sm">免费注册</a>
            <% } %>
        </div>
    </div>
</header>

<!-- Hero Banner -->
<section class="hero">
    <h1>🎉 闲置流转 · 价值新生</h1>
    <p>在这里，每一件二手物品都能找到新主人，每一次出价都是一次惊喜</p>
    <div id="vue-root">
        <div class="hero-search">
            <input type="text" placeholder="搜索你想要的好物 · 数码 / 服饰 / 书籍 ..." v-model="keyword">
            <button @click="search"><i class="fa fa-search"></i> 搜索</button>
        </div>
    </div>
</section>

<div class="container">

    <!-- 功能入口（已登录 vs 未登录 不同展示） -->
    <h2 class="section-title">快速入口</h2>
    <div class="features">
        <div class="feature-card" onclick="go('/item/list')">
            <div class="feature-icon"><i class="fa fa-search"></i></div>
            <div>
                <div class="feature-title">浏览拍品</div>
                <div class="feature-desc">发现心仪的二手好物</div>
            </div>
        </div>
        <div class="feature-card" onclick="go('/item/publish')">
            <div class="feature-icon"><i class="fa fa-plus-circle"></i></div>
            <div>
                <div class="feature-title">发布拍品</div>
                <div class="feature-desc">让你的闲置流转起来</div>
            </div>
        </div>
        <div class="feature-card" onclick="go('/user/center')">
            <div class="feature-icon"><i class="fa fa-user-circle"></i></div>
            <div>
                <div class="feature-title">个人中心</div>
                <div class="feature-desc">管理你的订单和出价</div>
            </div>
        </div>
        <div class="feature-card" @click="go('/item/list?sort=hot')">
            <div class="feature-icon"><i class="fa fa-fire"></i></div>
            <div>
                <div class="feature-title">热门拍品</div>
                <div class="feature-desc">看看大家在抢什么</div>
            </div>
        </div>
    </div>

    <% if (currentUser == null) { %>
    <!-- 未登录：引导注册 -->
    <div class="card text-center" style="background: linear-gradient(135deg, #fff3eb 0%, #ffe5d0 100%);">
        <h2 style="color: var(--color-primary); margin-bottom: 8px;">立即加入，开启你的拍卖之旅</h2>
        <p style="color: var(--color-muted); margin-bottom: 20px;">注册即送 100 信用分，专属客服 7×24 在线</p>
        <a href="<%=ctx%>/user?action=register" class="btn btn-primary btn-lg">免费注册</a>
        <a href="<%=ctx%>/user?action=login" class="btn btn-ghost btn-lg">已有账号？登录</a>
    </div>
    <% } else { %>
    <!-- 已登录：用户面板 -->
    <div class="card">
        <div class="flex-between">
            <div>
                <h2 style="font-size: 20px; margin-bottom: 8px;">
                    你好，<%= currentUser.getUsername() %> 👋
                </h2>
                <p class="text-muted">
                    信用分 <span class="text-success font-bold"><%= currentUser.getCreditScore() %></span> ·
                    余额 <span class="text-primary font-bold"><%= String.format("￥%.2f", currentUser.getBalance()) %></span> ·
                    注册于 <%= currentUser.getRegisterTime() == null ? "-" : currentUser.getRegisterTime().toString().substring(0, 10) %>
                </p>
            </div>
            <div class="flex gap">
                <a href="<%=ctx%>/item/publish" class="btn btn-primary">
                    <i class="fa fa-plus"></i> 立即发布拍品
                </a>
                <a href="<%=ctx%>/user/center" class="btn btn-secondary">
                    <i class="fa fa-user"></i> 进入个人中心
                </a>
            </div>
        </div>
    </div>
    <% } %>
</div>

<div style="text-align: center; padding: 40px 0; color: var(--color-muted); font-size: 13px;">
    © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
</div>

<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // 全局跳转函数（供非 Vue 区域调用）
    function go(path) {
        window.location.href = '<%=ctx%>' + path;
    }

    // Vue 只接管 hero 搜索框（局部增强）
    loadVue().then(() => {
        const { createApp, ref } = Vue;
        createApp({
            setup() {
                const keyword = ref('');
                function search() {
                    if (!keyword.value.trim()) { toast('请输入搜索关键词', 'info'); return; }
                    window.location.href = '<%=ctx%>/item/list?keyword=' + encodeURIComponent(keyword.value);
                }
                return { keyword, search };
            }
        }).mount('#vue-root');
    });
</script>
</body>
</html>