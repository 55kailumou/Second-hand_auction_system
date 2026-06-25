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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #f5f5f5; }
        .header { background: #fff; height: 60px; position: sticky; top: 0; z-index: 100;
                  box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
        .header-inner { max-width: 1200px; margin: 0 auto; padding: 0 16px; height: 100%;
                        display: flex; align-items: center; gap: 20px; }
        .logo { font-size: 20px; font-weight: 800; color: var(--color-primary);
                display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
        .logo-icon { width: 30px; height: 30px; background: var(--color-primary);
                     color: #fff; border-radius: 4px; display: grid; place-items: center;
                     font-size: 14px; }
        .nav { display: flex; gap: 24px; margin-left: auto; }
        .nav a { color: var(--color-text); font-size: 14px; font-weight: 500;
                 padding: 0 4px; height: 60px; display: flex; align-items: center;
                 position: relative; transition: color 0.2s; }
        .nav a:hover, .nav a.active { color: var(--color-primary); }
        .nav a.active::after {
            content: ''; position: absolute;
            bottom: 8px; left: 4px; right: 4px;
            height: 2px; background: var(--color-primary); border-radius: 2px;
        }

        .container { max-width: 1200px; margin: 16px auto; padding: 0 16px; }
        .page-head { background: #fff; border-radius: 8px; padding: 20px 24px;
                     box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     display: flex; align-items: center; gap: 16px; margin-bottom: 12px; }
        .page-head-title { font-size: 18px; font-weight: 700; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); margin-top: 4px; }
        .page-head-info { flex: 1; }

        .item-card { background: #fff; border-radius: 8px; padding: 18px 20px;
                     box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     display: flex; gap: 16px; align-items: center; margin-bottom: 10px; }
        .item-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.06); }
        .item-cover { width: 100px; height: 100px; border-radius: 6px;
                      background: var(--color-primary-soft); flex-shrink: 0;
                      display: grid; place-items: center; overflow: hidden; }
        .item-cover img { width: 100%; height: 100%; object-fit: cover; }
        .item-cover i { font-size: 28px; color: rgba(255,107,53,0.4); }
        .item-info { flex: 1; min-width: 0; }
        .item-title { font-size: 14px; font-weight: 600;
                      white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .item-meta { font-size: 12px; color: var(--color-muted); margin-top: 4px;
                     display: flex; gap: 12px; flex-wrap: wrap; }
        .item-price { color: var(--color-primary); font-weight: 700; font-size: 16px;
                      margin-top: 6px; }

        .status-pill { display: inline-block; padding: 3px 10px;
                       border-radius: 12px; font-size: 11px; font-weight: 600; }
        .status-0 { background: #fef3c7; color: #b45309; }
        .status-1 { background: #dbeafe; color: #1d4ed8; }
        .status-2 { background: #d1fae5; color: #047857; }
        .status-3 { background: #f3f4f6; color: #6b7280; }
        .status-4 { background: #fee2e2; color: #b91c1c; }
        .status-5 { background: #fde68a; color: #92400e; }

        .item-actions { display: flex; gap: 6px; flex-shrink: 0; }
        .item-actions a, .item-actions button {
            padding: 6px 12px; border-radius: 4px; font-size: 12px;
            text-decoration: none; cursor: pointer; border: 1px solid transparent;
            transition: all 0.15s;
        }
        .btn-edit { background: #fff; color: var(--color-primary); border-color: var(--color-primary); }
        .btn-edit:hover { background: var(--color-primary); color: #fff; }
        .btn-offline-card { background: #fff; color: var(--color-danger); border-color: var(--color-danger); }
        .btn-offline-card:hover { background: var(--color-danger); color: #fff; }
        .btn-view { background: #f9fafb; color: var(--color-text-sub); border-color: var(--color-border); }
        .btn-view:hover { background: #f3f4f6; }
        .btn-disabled { background: #f9fafb; color: #9ca3af; border-color: var(--color-border); cursor: not-allowed; }

        .empty-state { background: #fff; border-radius: 8px; padding: 60px 20px;
                       text-align: center; box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
        .empty-state i { font-size: 56px; color: rgba(255,107,53,0.3); margin-bottom: 16px; }
        .empty-state p { color: var(--color-muted); margin-bottom: 20px; }

        .alert-error { background: #fee2e2; color: var(--color-danger); padding: 12px 16px;
                       border-radius: 8px; font-size: 13px; margin-bottom: 12px; }
    </style>
</head>
<body>

<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <span class="logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/user?action=center">个人中心</a>
        </nav>
    </div>
</header>

<div class="container" id="app" v-cloak>
    <div class="page-head">
        <div style="width: 48px; height: 48px; border-radius: 8px; background: var(--color-primary-light);
                    display: grid; place-items: center; color: var(--color-primary); font-size: 22px;">
            <i class="fa fa-handshake-o"></i>
        </div>
        <div class="page-head-info">
            <div class="page-head-title">我发布的拍品</div>
            <div class="page-head-sub">
                共 <strong>{{ items.length }}</strong> 件 ·
                拍卖中 <strong style="color: #1d4ed8;">{{ countByStatus(1) }}</strong> ·
                待审核 <strong style="color: #b45309;">{{ countByStatus(0) }}</strong> ·
                已成交 <strong style="color: #047857;">{{ countByStatus(2) }}</strong> ·
                已下架 <strong style="color: #b91c1c;">{{ countByStatus(4) }}</strong>
            </div>
        </div>
        <a href="<%=ctx%>/item?action=publish-page" class="btn-edit"
           style="padding: 9px 20px; background: var(--color-primary); color: #fff; border: none; font-weight: 600;">
            <i class="fa fa-plus"></i> 发布新拍品
        </a>
    </div>

    <div v-if="items.length === 0" class="empty-state">
        <i class="fa fa-inbox"></i>
        <p>您还没有发布过拍品</p>
        <a href="<%=ctx%>/item?action=publish-page"
           style="display: inline-block; padding: 10px 28px; background: var(--color-primary);
                  color: #fff; border-radius: 6px; text-decoration: none; font-weight: 600;">
            <i class="fa fa-plus"></i> 立即发布
        </a>
    </div>

    <div v-for="it in items" :key="it.id" class="item-card">
        <a :href="'<%=ctx%>/item?action=detail&id=' + it.id" class="item-cover">
            <img v-if="it.coverImage" :src="it.coverImage" :alt="it.title">
            <i v-else class="fa fa-image"></i>
        </a>
        <div class="item-info">
            <div class="item-title">
                <a :href="'<%=ctx%>/item?action=detail&id=' + it.id"
                   style="color: var(--color-text); text-decoration: none;">{{ it.title }}</a>
            </div>
            <div class="item-meta">
                <span>浏览 {{ it.viewCount || 0 }} 次</span>
                <span>当前价 ¥{{ formatPrice(it.currentPrice) }}</span>
                <span v-if="it.endTime">结束：{{ formatDateTime(it.endTime) }}</span>
            </div>
            <div class="item-price">¥{{ formatPrice(it.currentPrice || it.startPrice) }}</div>
        </div>
        <span :class="['status-pill', 'status-' + it.status]">{{ statusText(it.status) }}</span>
        <div class="item-actions">
            <a :href="'<%=ctx%>/item?action=detail&id=' + it.id" class="btn-view">查看</a>
            <a :href="'<%=ctx%>/item?action=edit-page&id=' + it.id"
               :class="canEdit(it) ? 'btn-edit' : 'btn-disabled'">
                编辑
            </a>
            <button v-if="canOffline(it)" type="button" class="btn-offline-card"
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
