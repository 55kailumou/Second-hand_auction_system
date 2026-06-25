<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) {
        response.sendRedirect(ctx + "/user?action=login&returnUrl=" +
                java.net.URLEncoder.encode("/item?action=my-items", "UTF-8"));
        return;
    }
    String itemsJson = (String) request.getAttribute("itemsJson");
    if (itemsJson == null) itemsJson = "[]";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我发布的拍品 · 个人中心</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #0a0a0a; color: #FFEE00; font-family: 'Courier New', Consolas, 'Source Code Pro', monospace; }

        .cp-page-head { background: #111; border: 1px solid #FFEE00; padding: 20px 24px; display: flex; align-items: center; gap: 16px; margin-bottom: 12px; }
        .cp-page-title { font-size: 18px; font-weight: 700; color: #FFEE00; }
        .cp-page-sub { font-size: 12px; color: #FFEE00; opacity: 0.7; margin-top: 4px; }

        .cp-card { background: #111; border: 1px solid #FFEE00; padding: 18px 20px; display: flex; gap: 16px; align-items: center; margin-bottom: 10px; }
        .cp-card:hover { box-shadow: 0 0 15px rgba(255,238,0,0.15); }
        .cp-card-cover { width: 100px; height: 100px; border: 1px solid #FFEE00; background: #0a0a0a; flex-shrink: 0; display: grid; place-items: center; overflow: hidden; }
        .cp-card-cover img { width: 100%; height: 100%; object-fit: cover; }
        .cp-card-cover i { font-size: 28px; color: #FFEE00; opacity: 0.4; }
        .cp-card-info { flex: 1; min-width: 0; }
        .cp-card-title { font-size: 14px; font-weight: 600; color: #FFEE00; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .cp-card-title a { color: #FFEE00; text-decoration: none; }
        .cp-card-title a:hover { color: #00f0ff; }
        .cp-card-meta { font-size: 12px; color: #FFEE00; opacity: 0.7; margin-top: 4px; display: flex; gap: 12px; flex-wrap: wrap; }
        .cp-card-price { color: #00f0ff; font-weight: 700; font-size: 16px; margin-top: 6px; text-shadow: 0 0 5px #00f0ff; }

        .cp-status-pill { display: inline-block; padding: 3px 10px; border: 1px solid #FFEE00; font-size: 11px; font-weight: 600; color: #FFEE00; }
        .status-0 { border-color: #FFEE00; color: #FFEE00; }
        .status-1 { border-color: #00f0ff; color: #00f0ff; text-shadow: 0 0 5px #00f0ff; }
        .status-2 { border-color: #00ff88; color: #00ff88; }
        .status-3 { border-color: #666; color: #666; }
        .status-4 { border-color: #ff00ff; color: #ff00ff; }
        .status-5 { border-color: #ff4444; color: #ff4444; }

        .cp-card-actions { display: flex; gap: 6px; flex-shrink: 0; }
        .cp-card-actions a, .cp-card-actions button { padding: 6px 12px; font-size: 12px; text-decoration: none; cursor: pointer; font-family: inherit; transition: all 0.15s; border: 1px solid transparent; }
        .cp-btn-sm { background: #FFEE00; color: #0a0a0a; border: none; font-weight: 600; }
        .cp-btn-sm:hover { background: #fff; box-shadow: 0 0 10px rgba(255,238,0,0.5); }
        .cp-btn-danger-sm { background: transparent; border: 1px solid #ff00ff; color: #ff00ff; }
        .cp-btn-danger-sm:hover { background: #ff00ff; color: #0a0a0a; }
        .cp-btn-outline-sm { background: transparent; border: 1px solid #FFEE00; color: #FFEE00; }
        .cp-btn-outline-sm:hover { background: #FFEE00; color: #0a0a0a; }
        .cp-btn-disabled { background: #1a1a1a; border: 1px solid #333; color: #666; cursor: not-allowed; }

        .cp-empty-state { background: #111; border: 1px solid #FFEE00; padding: 60px 20px; text-align: center; }
        .cp-empty-state i { font-size: 56px; color: #FFEE00; opacity: 0.3; }
        .cp-empty-state p { color: #FFEE00; opacity: 0.7; margin-bottom: 20px; }

        .cp-alert-error { background: rgba(255,0,255,0.1); border: 1px solid #ff00ff; color: #ff00ff; padding: 12px 16px; font-size: 13px; margin-bottom: 12px; }

        .cp-scanline { position: fixed; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 9999; background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,0.03) 2px, rgba(0,0,0,0.03) 4px); }
    </style>
</head>
<body>

<div class="cp-scanline"></div>

<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="cp-logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/user?action=center">个人中心</a>
        </nav>
    </div>
</header>

<div class="cp-container" id="app" v-cloak>
    <div class="cp-page-head">
        <div style="width: 48px; height: 48px; border: 1px solid #FFEE00;
                    display: grid; place-items: center; color: #FFEE00; font-size: 22px;">
            <i class="fa fa-handshake-o"></i>
        </div>
        <div class="cp-page-head-info">
            <div class="cp-page-title">我发布的拍品</div>
            <div class="cp-page-sub">
                共 <strong>{{ items.length }}</strong> 件 ·
                拍卖中 <strong style="color: #00f0ff;">{{ countByStatus(1) }}</strong> ·
                待审核 <strong style="color: #FFEE00;">{{ countByStatus(0) }}</strong> ·
                已成交 <strong style="color: #00ff88;">{{ countByStatus(2) }}</strong> ·
                已下架 <strong style="color: #ff00ff;">{{ countByStatus(4) }}</strong>
            </div>
        </div>
        <a href="<%=ctx%>/item?action=publish-page" class="cp-btn-sm"
           style="padding: 9px 20px; background: #FFEE00; color: #0a0a0a; border: none; font-weight: 600;">
            <i class="fa fa-plus"></i> 发布新拍品
        </a>
    </div>

    <div v-if="items.length === 0" class="cp-empty-state">
        <i class="fa fa-inbox"></i>
        <p>您还没有发布过拍品</p>
        <a href="<%=ctx%>/item?action=publish-page"
           style="display: inline-block; padding: 10px 28px; background: #FFEE00;
                  color: #0a0a0a; text-decoration: none; font-weight: 600;">
            <i class="fa fa-plus"></i> 立即发布
        </a>
    </div>

    <div v-for="it in items" :key="it.id" class="cp-card">
        <a :href="'<%=ctx%>/item?action=detail&id=' + it.id" class="cp-card-cover">
            <img v-if="it.coverImage" :src="it.coverImage" :alt="it.title">
            <i v-else class="fa fa-image"></i>
        </a>
        <div class="cp-card-info">
            <div class="cp-card-title">
                <a :href="'<%=ctx%>/item?action=detail&id=' + it.id"
                   style="color: #FFEE00; text-decoration: none;">{{ it.title }}</a>
            </div>
            <div class="cp-card-meta">
                <span>浏览 {{ it.viewCount || 0 }} 次</span>
                <span>当前价 ¥{{ formatPrice(it.currentPrice) }}</span>
                <span v-if="it.endTime">结束：{{ formatDateTime(it.endTime) }}</span>
            </div>
            <div class="cp-card-price">¥{{ formatPrice(it.currentPrice || it.startPrice) }}</div>
        </div>
        <span :class="['cp-status-pill', 'status-' + it.status]">{{ statusText(it.status) }}</span>
        <div class="cp-card-actions">
            <a :href="'<%=ctx%>/item?action=detail&id=' + it.id" class="cp-btn-outline-sm">查看</a>
            <a :href="'<%=ctx%>/item?action=edit-page&id=' + it.id"
               :class="canEdit(it) ? 'cp-btn-sm' : 'cp-btn-disabled'">
                编辑
            </a>
            <button v-if="canOffline(it)" type="button" class="cp-btn-danger-sm"
                    @click="offlineItem(it)">撤拍</button>
        </div>
    </div>
</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath = '<%=ctx%>';
    const initItems = <%= itemsJson %>;

    loadVue().then(() => {
        const { createApp, ref } = Vue;
        createApp({
            setup() {
                const items = ref(initItems || []);

                function statusText(s) {
                    switch (s) {
                        case 0: return '待审核';
                        case 1: return '拍卖中';
                        case 2: return '已成交';
                        case 3: return '已流拍';
                        case 4: return '已下架';
                        case 5: return '审核未通过';
                        default: return '未知';
                    }
                }
                function countByStatus(s) {
                    return items.value.filter(it => it.status === s).length;
                }
                function formatPrice(p) {
                    if (p == null) return '0.00';
                    return Number(p).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
                function formatDateTime(s) {
                    if (!s) return '';
                    return s.substring(0, 16).replace('T', ' ');
                }
                // 是否可编辑（不能成交/流拍/下架）
                function canEdit(it) {
                    return it.status !== 2 && it.status !== 3;
                }
                // 是否可撤拍（已开始拍卖、已成交、已流拍、已下架 → 都不可撤）
                function canOffline(it) {
                    if (it.status === 0 || it.status === 5) return true;
                    if (it.status === 1 && it.startTime && new Date(it.startTime) > new Date()) return true;
                    return false;
                }
                function offlineItem(it) {
                    if (!confirm('确定要撤拍「' + it.title + '」吗？\\n撤拍后前台不再展示。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/item?action=offline&id=' + it.id)
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '撤拍成功', 'success');
                                    setTimeout(() => location.reload(), 800);
                                } else {
                                    toast(r.data.message || '撤拍失败', 'error');
                                }
                            })
                            .catch(() => toast('网络错误', 'error'));
                    });
                }

                return { items, statusText, countByStatus, formatPrice, formatDateTime,
                         canEdit, canOffline, offlineItem };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
