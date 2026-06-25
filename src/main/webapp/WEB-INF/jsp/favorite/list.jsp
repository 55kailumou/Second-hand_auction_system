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

    java.util.List<java.util.Map<String, Object>> favoriteItems =
            (java.util.List<java.util.Map<String, Object>>) request.getAttribute("favoriteItems");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("page");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer pageSize = (Integer) request.getAttribute("pageSize");
    String error = (String) request.getAttribute("error");
    if (favoriteItems == null) favoriteItems = new java.util.ArrayList<>();
    if (total == null) total = 0;
    if (pageNo == null) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (pageSize == null) pageSize = 12;

    // 转成 JSON 给 Vue
    com.fasterxml.jackson.databind.ObjectMapper json =
            new com.fasterxml.jackson.databind.ObjectMapper()
                    .registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule())
                    .disable(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    String itemsJson = json.writeValueAsString(favoriteItems);
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我的收藏 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 我的收藏 v1 · 仿闲鱼
         * - 顶 nav 统一
         * - 标题栏 + 统计
         * - 6 列卡片网格
         * - 分页
         * ============================================================ */
        body { background: #f5f5f5; }

        /* ---------- 顶 nav（与 center.jsp 保持一致） ---------- */
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
        .fav-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px 60px; }

        /* 标题栏 */
        .fav-head {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 20px 24px;
            display: flex; align-items: center; gap: 16px;
        }
        .fav-head-icon {
            width: 48px; height: 48px; border-radius: 8px;
            background: var(--color-primary-light); color: var(--color-primary);
            display: grid; place-items: center; font-size: 22px;
        }
        .fav-head-info { flex: 1; min-width: 0; }
        .fav-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .fav-head-sub { font-size: 12px; color: var(--color-muted); }
        .fav-head-actions { display: flex; gap: 8px; }
        .fav-head-actions a {
            padding: 8px 16px; border-radius: 6px;
            font-size: 13px; text-decoration: none;
            display: flex; align-items: center; gap: 5px;
            transition: all 0.15s;
        }
        .btn-ghost {
            background: #fff; color: var(--color-text);
            border: 1px solid var(--color-border);
        }
        .btn-ghost:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .btn-primary {
            background: var(--color-primary); color: #fff; border: 1px solid var(--color-primary);
        }
        .btn-primary:hover { background: var(--color-primary-hover); border-color: var(--color-primary-hover); }

        /* 错误条 */
        .alert { padding: 10px 16px; border-radius: 8px; margin-top: 12px; font-size: 13px; }
        .alert-warning { background: #fef3c7; color: #b45309; }

        /* 卡片网格 */
        .fav-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
            margin-top: 12px;
        }
        @media (max-width: 1200px) { .fav-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .fav-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .fav-grid { grid-template-columns: repeat(3, 1fr); } }

        .fav-card {
            background: #fff; border: 1px solid transparent;
            border-radius: 4px; overflow: hidden;
            position: relative; cursor: pointer;
            transition: all 0.15s; text-decoration: none; color: inherit;
        }
        .fav-card:hover {
            border-color: var(--color-primary);
            transform: translateY(-2px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .fav-card-cover {
            width: 100%; aspect-ratio: 1; background: #fff7ed;
            position: relative; display: grid; place-items: center; overflow: hidden;
        }
        .fav-card-cover img { width: 100%; height: 100%; object-fit: cover; }
        .fav-card-cover i { font-size: 32px; color: rgba(255,107,53,0.4); }

        /* 状态徽章 */
        .fav-card-cover .status-tag {
            position: absolute; inset: 0;
            background: rgba(0,0,0,0.4);
            display: grid; place-items: center;
            color: #fff; font-size: 14px; font-weight: 700;
            letter-spacing: 0.1em;
        }
        .fav-card-cover .status-tag.gray { background: rgba(107,114,128,0.7); }

        /* 取消收藏小按钮 */
        .fav-remove {
            position: absolute; top: 6px; right: 6px;
            width: 28px; height: 28px; border-radius: 50%;
            background: rgba(0,0,0,0.55); color: #fff;
            display: grid; place-items: center;
            font-size: 12px; cursor: pointer; opacity: 0;
            transition: opacity 0.15s, background 0.15s;
            border: none; z-index: 2;
        }
        .fav-card:hover .fav-remove { opacity: 1; }
        .fav-remove:hover { background: var(--color-danger); }

        .fav-card-body { padding: 8px 10px 10px; }
        .fav-card-title {
            font-size: 12px; line-height: 1.4; min-height: 32px;
            color: var(--color-text);
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .fav-card-price {
            margin-top: 4px;
            font-size: 14px; font-weight: 700; color: var(--color-primary);
        }
        .fav-card-price small { font-size: 10px; margin-right: 1px; }
        .fav-card-time {
            font-size: 11px; color: var(--color-muted);
            margin-top: 2px;
        }

        /* 空状态 */
        .empty-state {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            margin-top: 12px;
            text-align: center; padding: 80px 20px;
            color: var(--color-muted); font-size: 13px;
        }
        .empty-state i { font-size: 48px; opacity: 0.3; margin-bottom: 12px; display: block; }
        .empty-state a { color: var(--color-primary); text-decoration: none; font-weight: 600; }
        .empty-state a:hover { text-decoration: underline; }

        /* 分页 */
        .pager {
            margin-top: 20px; display: flex; justify-content: center; gap: 6px;
        }
        .pager a, .pager span {
            padding: 6px 12px; border: 1px solid var(--color-border);
            border-radius: 4px; font-size: 13px; color: var(--color-text-sub);
            text-decoration: none; min-width: 32px; text-align: center;
            background: #fff;
        }
        .pager a:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .pager .active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .pager .disabled { color: var(--color-placeholder); cursor: not-allowed; background: var(--color-bg); }

        /* 页脚 */
        .fav-footer {
            background: #1f2937; color: #d1d5db;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .fav-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }
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

<div class="fav-wrap" id="app" v-cloak>

    <!-- 标题栏 -->
    <div class="fav-head">
        <div class="fav-head-icon"><i class="fa fa-heart"></i></div>
        <div class="fav-head-info">
            <div class="fav-head-title">我的收藏</div>
            <div class="fav-head-sub">共 {{ total }} 件拍品 · 按收藏时间倒序</div>
        </div>
        <div class="fav-head-actions">
            <a href="<%=ctx%>/item?action=list" class="btn-ghost">
                <i class="fa fa-search"></i> 去逛逛
            </a>
        </div>
    </div>

    <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <!-- 列表 -->
    <div v-if="items.length > 0" class="fav-grid">
        <div v-for="item in items" :key="item.favoriteId" class="fav-card"
             @click="goDetail(item)">
            <button class="fav-remove" @click.stop="removeFav(item)" title="取消收藏">
                <i class="fa fa-times"></i>
            </button>
            <div class="fav-card-cover" :style="item.coverImage ? 'background-image:url(' + item.coverImage + '); background-size:cover; background-position:center;' : ''">
                <i v-if="!item.coverImage" class="fa fa-image"></i>
                <div v-if="item.status === 2" class="status-tag">已成交</div>
                <div v-else-if="item.status === 3" class="status-tag gray">已流拍</div>
                <div v-else-if="item.status === 4" class="status-tag gray">已下架</div>
            </div>
            <div class="fav-card-body">
                <div class="fav-card-title">{{ item.title || '（已删除）' }}</div>
                <div class="fav-card-price">
                    <small>¥</small>{{ formatPrice(item.currentPrice) }}
                </div>
                <div class="fav-card-time">
                    <i class="fa fa-clock-o"></i> 收藏于 {{ formatTime(item.addTime) }}
                </div>
            </div>
        </div>
    </div>

    <!-- 空状态 -->
    <div v-if="items.length === 0" class="empty-state">
        <i class="fa fa-heart-o"></i>
        <p>还没有收藏的拍品</p>
        <p style="margin-top: 8px;">
            <a href="<%=ctx%>/item?action=list">去浏览拍品 →</a>
        </p>
    </div>

    <!-- 分页 -->
    <div v-if="totalPages > 1" class="pager">
        <a v-if="page > 1" :href="pageHref(page - 1)">‹ 上一页</a>
        <span v-else class="disabled">‹ 上一页</span>

        <span v-for="p in pagesToShow" :key="p"
              :class="p === page ? 'active' : ''">
            <a v-if="p !== page" :href="pageHref(p)">{{ p }}</a>
            <span v-else>{{ p }}</span>
        </span>

        <a v-if="page < totalPages" :href="pageHref(page + 1)">下一页 ›</a>
        <span v-else class="disabled">下一页 ›</span>
    </div>

</div>

<!-- 页脚 -->
<footer class="fav-footer">
    <div class="fav-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath   = '<%=ctx%>';
    const itemsInit = <%= itemsJson %>;
    const total     = <%= total %>;
    const page      = <%= pageNo %>;
    const totalPages= <%= totalPages %>;

    loadVue().then(() => {
        const { createApp, ref, computed } = Vue;
        createApp({
            setup() {
                const items = ref(itemsInit);
                const totalRef = ref(total);
                const pageRef = ref(page);
                const totalPagesRef = ref(totalPages);

                const pagesToShow = computed(() => {
                    const total = totalPagesRef.value;
                    const cur = pageRef.value;
                    const arr = [];
                    const start = Math.max(1, cur - 2);
                    const end = Math.min(total, cur + 2);
                    for (let i = start; i <= end; i++) arr.push(i);
                    return arr;
                });

                function goDetail(item) {
                    if (!item || !item.itemId) return;
                    window.location.href = ctxPath + '/item?action=detail&id=' + item.itemId;
                }
                function pageHref(p) {
                    return ctxPath + '/favorite?action=list&page=' + p;
                }
                function formatPrice(p) {
                    return Number(p).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
                function formatTime(dt) {
                    if (!dt) return '-';
                    const d = new Date(dt);
                    if (isNaN(d)) return dt;
                    const pad = n => String(n).padStart(2, '0');
                    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
                        ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
                }
                function removeFav(item) {
                    if (!confirm('确定取消收藏《' + (item.title || '') + '》？')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/favorite?action=delete', null, {
                            params: { id: item.favoriteId }
                        }).then(r => {
                            if (r.data.success) {
                                toast('已取消收藏', 'success');
                                // 从列表移除
                                items.value = items.value.filter(x => x.favoriteId !== item.favoriteId);
                                totalRef.value = Math.max(0, totalRef.value - 1);
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                        }).catch(() => toast('网络错误', 'error'));
                    });
                }

                return { items, total: totalRef, page: pageRef, totalPages: totalPagesRef,
                         pagesToShow, goDetail, pageHref, formatPrice, formatTime, removeFav };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
