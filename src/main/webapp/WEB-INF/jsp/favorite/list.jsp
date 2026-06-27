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
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * Cyberpunk 2077 · 我的收藏
         * - Dark neon theme #000 / #FFEE00 / #00FFFF / #FF00FF
         * - Clip-path polygons, monospace fonts
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
        .fav-head {
            background: #0d0d0d;
            border: 1px solid #FFEE00;
            clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
            padding: 20px 24px;
            display: flex;
            align-items: center;
            gap: 16px;
        }
        .fav-head-icon {
            width: 48px;
            height: 48px;
            background: #111;
            border: 1px solid #FF00FF;
            color: #FF00FF;
            display: grid;
            place-items: center;
            font-size: 22px;
            clip-path: polygon(10% 0, 90% 0, 100% 10%, 100% 90%, 90% 100%, 10% 100%, 0 90%, 0 10%);
        }
        .fav-head-info { flex: 1; min-width: 0; }
        .fav-head-title {
            font-size: 18px;
            font-weight: 700;
            color: #FF00FF;
            text-shadow: 0 0 6px #FF00FF;
            margin-bottom: 4px;
        }
        .fav-head-sub { font-size: 12px; color: #666; }
        .fav-head-actions { display: flex; gap: 8px; }

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

        /* ---------- Goods Grid ---------- */
        .cp-goods-grid {
            display: grid;
            grid-template-columns: repeat(6, 1fr);
            gap: 10px;
            margin-top: 12px;
        }
        @media (max-width: 1200px) { .cp-goods-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .cp-goods-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .cp-goods-grid { grid-template-columns: repeat(3, 1fr); } }

        .cp-goods-card {
            background: #0d0d0d;
            border: 1px solid #222;
            clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
            overflow: hidden;
            position: relative;
            cursor: pointer;
            transition: all 0.2s;
            text-decoration: none;
            color: inherit;
        }
        .cp-goods-card:hover {
            border-color: #00FFFF;
            transform: translateY(-2px);
            box-shadow: 0 0 14px rgba(0,255,255,0.15);
        }
        .cp-goods-cover {
            width: 100%;
            aspect-ratio: 1;
            background: #111;
            position: relative;
            display: grid;
            place-items: center;
            overflow: hidden;
        }
        .cp-goods-cover img { width: 100%; height: 100%; object-fit: cover; }
        .cp-goods-cover i { font-size: 32px; color: rgba(255,238,0,0.2); }

        /* 状态徽章 */
        .cp-goods-cover .status-tag {
            position: absolute;
            inset: 0;
            background: rgba(0,0,0,0.7);
            display: grid;
            place-items: center;
            color: #FFEE00;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.15em;
            text-transform: uppercase;
        }
        .cp-goods-cover .status-tag.gray { background: rgba(50,50,50,0.8); color: #888; }

        /* 取消收藏按钮 */
        .fav-remove {
            position: absolute;
            top: 6px;
            right: 6px;
            width: 28px;
            height: 28px;
            background: rgba(0,0,0,0.7);
            border: 1px solid #FF00FF;
            color: #FF00FF;
            display: grid;
            place-items: center;
            font-size: 12px;
            cursor: pointer;
            opacity: 0;
            transition: opacity 0.2s, background 0.2s;
            z-index: 2;
            font-family: inherit;
        }
        .cp-goods-card:hover .fav-remove { opacity: 1; }
        .fav-remove:hover {
            background: #FF00FF;
            color: #000;
        }

        .cp-goods-body { padding: 8px 10px 10px; }
        .cp-goods-title {
            font-size: 12px;
            line-height: 1.4;
            min-height: 32px;
            color: #ccc;
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .cp-goods-price {
            margin-top: 4px;
            font-size: 14px;
            font-weight: 700;
            color: #FFEE00;
        }
        .cp-goods-price small { font-size: 10px; margin-right: 1px; }
        .cp-goods-time {
            font-size: 11px;
            color: #555;
            margin-top: 2px;
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
        .cp-empty a {
            color: #00FFFF;
            font-weight: 600;
        }
        .cp-empty a:hover {
            color: #FF00FF;
            text-shadow: 0 0 8px #FF00FF;
        }

        /* ---------- Pagination ---------- */
        .pager {
            margin-top: 20px;
            display: flex;
            justify-content: center;
            gap: 6px;
        }
        .pager a, .pager span {
            padding: 6px 12px;
            border: 1px solid #333;
            font-size: 13px;
            color: #888;
            text-decoration: none;
            min-width: 32px;
            text-align: center;
            background: #0d0d0d;
            transition: all 0.15s;
            font-family: inherit;
        }
        .pager a:hover {
            border-color: #00FFFF;
            color: #00FFFF;
        }
        .pager .active {
            background: #FFEE00;
            color: #000;
            border-color: #FFEE00;
            font-weight: 700;
        }
        .pager .disabled {
            color: #333;
            cursor: not-allowed;
            background: #050505;
        }

        /* ---------- Footer ---------- */
        .fav-footer {
            background: #050505;
            border-top: 1px solid #FFEE00;
            margin-top: 32px;
            padding: 32px 16px 16px;
            text-align: center;
            font-size: 12px;
        }
        .fav-footer-inner {
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
    <div class="fav-head">
        <div class="fav-head-icon"><i class="fa fa-heart"></i></div>
        <div class="fav-head-info">
            <div class="fav-head-title">> 我的收藏</div>
            <div class="fav-head-sub">共 {{ total }} 件拍品 · 按收藏时间倒序</div>
        </div>
        <div class="fav-head-actions">
            <a href="<%=ctx%>/item?action=list" class="cp-btn cp-btn-outline cp-btn-sm">
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
    <div v-if="items.length > 0" class="cp-goods-grid">
        <div v-for="item in items" :key="item.favoriteId" class="cp-goods-card"
             @click="goDetail(item)">
            <button class="fav-remove" @click.stop="removeFav(item)" title="取消收藏">
                <i class="fa fa-times"></i>
            </button>
            <div class="cp-goods-cover" :style="item.coverImage ? 'background-image:url(' + item.coverImage + '); background-size:cover; background-position:center;' : ''">
                <i v-if="!item.coverImage" class="fa fa-image"></i>
                <div v-if="item.status === 2" class="status-tag">已成交</div>
                <div v-else-if="item.status === 3" class="status-tag gray">已流拍</div>
                <div v-else-if="item.status === 4" class="status-tag gray">已下架</div>
            </div>
            <div class="cp-goods-body">
                <div class="cp-goods-title">{{ item.title || '（已删除）' }}</div>
                <div class="cp-goods-price">
                    <small>¥</small>{{ formatPrice(item.currentPrice) }}
                </div>
                <div class="cp-goods-time">
                    <i class="fa fa-clock-o"></i> 收藏于 {{ formatTime(item.addTime) }}
                </div>
            </div>
        </div>
    </div>

    <!-- 空状态 -->
    <div v-if="items.length === 0" class="cp-empty">
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
