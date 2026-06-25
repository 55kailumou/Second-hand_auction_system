<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.Admin admin =
            (org.example.entity.Admin) session.getAttribute("currentAdmin");
    if (admin == null) {
        response.sendRedirect(ctx + "/admin/login");
        return;
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>数据统计 · 管理后台</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.js"></script>
    <style>
        body { background: #f5f5f5; margin: 0; }
        .admin-header { background: #1f2937; color: #d1d5db; height: 56px;
                        position: sticky; top: 0; z-index: 100; }
        .admin-header-inner { max-width: 1400px; margin: 0 auto; padding: 0 20px; height: 100%;
                              display: flex; align-items: center; gap: 20px; }
        .admin-logo { display: flex; align-items: center; gap: 8px;
                      font-size: 16px; font-weight: 700; color: #fff;
                      text-decoration: none; }
        .admin-logo-icon { width: 28px; height: 28px; background: #f59e0b; color: #1f2937;
                           border-radius: 4px; display: grid; place-items: center;
                           font-size: 14px; font-weight: 700; }
        .admin-nav { display: flex; gap: 4px; margin-left: 20px; }
        .admin-nav a { padding: 8px 14px; color: #d1d5db; font-size: 13px;
                       border-radius: 4px; text-decoration: none; transition: all 0.15s; }
        .admin-nav a:hover { background: rgba(255,255,255,0.1); color: #fff; }
        .admin-nav a.active { background: rgba(245,158,11,0.2); color: #fbbf24; }
        .admin-user { margin-left: auto; display: flex; align-items: center; gap: 12px; font-size: 13px; }
        .admin-user .role-tag { padding: 2px 8px; background: #374151; color: #fbbf24;
                                border-radius: 3px; font-size: 11px; font-weight: 600; }
        .admin-user a { color: #9ca3af; text-decoration: none; font-size: 12px; }
        .admin-user a:hover { color: #fff; }

        .admin-main { max-width: 1400px; margin: 16px auto 0; padding: 0 20px 60px; }

        .page-head { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     padding: 20px 24px; display: flex; align-items: center; gap: 16px; }
        .page-head-icon { width: 48px; height: 48px; border-radius: 8px;
                          background: linear-gradient(135deg, #6366f1, #8b5cf6);
                          color: #fff;
                          display: grid; place-items: center; font-size: 22px; }
        .page-head-info { flex: 1; }
        .page-head-title { font-size: 18px; font-weight: 700; margin-bottom: 4px; }
        .page-head-sub { font-size: 12px; color: var(--color-muted); }
        .page-head-toolbar { display: flex; gap: 8px; }
        .page-head-toolbar button { padding: 6px 14px; border: 1px solid var(--color-border);
                                    border-radius: 4px; font-size: 12px; cursor: pointer;
                                    background: #fff; color: var(--color-text-sub); }
        .page-head-toolbar button:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .page-head-toolbar button.active { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }

        /* KPI 卡片 */
        .kpi-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-top: 12px; }
        .kpi-card { background: #fff; border-radius: 8px; padding: 20px;
                    box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                    display: flex; align-items: center; gap: 16px; }
        .kpi-icon { width: 56px; height: 56px; border-radius: 12px;
                    display: grid; place-items: center; font-size: 24px; color: #fff; flex-shrink: 0; }
        .kpi-icon.k1 { background: linear-gradient(135deg, #3b82f6, #1d4ed8); }
        .kpi-icon.k2 { background: linear-gradient(135deg, #10b981, #047857); }
        .kpi-icon.k3 { background: linear-gradient(135deg, #f59e0b, #d97706); }
        .kpi-icon.k4 { background: linear-gradient(135deg, #ef4444, #b91c1c); }
        .kpi-info { flex: 1; min-width: 0; }
        .kpi-label { font-size: 12px; color: var(--color-muted); margin-bottom: 4px; }
        .kpi-value { font-size: 26px; font-weight: 700; color: var(--color-text); line-height: 1.2; }
        .kpi-value .unit { font-size: 13px; color: var(--color-muted); font-weight: 500; margin-left: 4px; }
        .kpi-sub { font-size: 11px; color: var(--color-muted); margin-top: 4px; }

        /* 图表网格 */
        .chart-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; margin-top: 12px; }
        .chart-card { background: #fff; border-radius: 8px; padding: 18px 20px;
                      box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
        .chart-card.span2 { grid-column: span 2; }
        .chart-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
        .chart-title { font-size: 14px; font-weight: 600; color: var(--color-text);
                       display: flex; align-items: center; gap: 8px; }
        .chart-title i { color: var(--color-primary); font-size: 13px; }
        .chart-meta { font-size: 11px; color: var(--color-muted); }
        .chart-canvas-wrap { position: relative; height: 280px; }
        .chart-canvas-wrap.tall { height: 320px; }

        /* loading / empty */
        .loading-mask { text-align: center; padding: 60px 20px; color: var(--color-muted); font-size: 14px; }
        .loading-mask i { font-size: 32px; margin-bottom: 12px; display: block; }
        .empty-mini { text-align: center; padding: 40px 20px; color: var(--color-muted); font-size: 12px; }

        @media (max-width: 980px) {
            .kpi-grid { grid-template-columns: repeat(2, 1fr); }
            .chart-grid { grid-template-columns: 1fr; }
            .chart-card.span2 { grid-column: span 1; }
        }
    </style>
</head>
<body>

<header class="admin-header">
    <div class="admin-header-inner">
        <a href="<%=ctx%>/admin" class="admin-logo">
            <span class="admin-logo-icon">A</span>
            <span>管理后台</span>
        </a>
        <nav class="admin-nav">
            <a href="<%=ctx%>/admin"><i class="fa fa-dashboard"></i> 概览</a>
            <a href="<%=ctx%>/admin/refund?action=list"><i class="fa fa-undo"></i> 退款审批</a>
            <a href="<%=ctx%>/admin/complaint?action=list"><i class="fa fa-flag"></i> 投诉审批</a>
            <a href="<%=ctx%>/admin/item?action=list"><i class="fa fa-gavel"></i> 拍品管理</a>
            <a href="<%=ctx%>/admin/user?action=list"><i class="fa fa-users"></i> 用户管理</a>
            <a href="<%=ctx%>/admin/category?action=list"><i class="fa fa-sitemap"></i> 分类管理</a>
            <a href="<%=ctx%>/admin/announcement?action=list"><i class="fa fa-bullhorn"></i> 公告</a>
            <a href="<%=ctx%>/admin/stats" class="active"><i class="fa fa-bar-chart"></i> 数据统计</a>
        </nav>
        <div class="admin-user">
            <i class="fa fa-user-circle-o"></i>
            <span><%= EscapeUtil.html(admin.getAdminName()) %></span>
            <span class="role-tag"><%= admin.getRole() == null ? "admin" : admin.getRole() %></span>
            <a href="<%=ctx%>/admin/login?action=logout"><i class="fa fa-sign-out"></i> 退出</a>
        </div>
    </div>
</header>

<div class="admin-main" id="app" v-cloak>

    <div class="page-head">
        <div class="page-head-icon"><i class="fa fa-bar-chart"></i></div>
        <div class="page-head-info">
            <div class="page-head-title">数据统计</div>
            <div class="page-head-sub">系统核心指标可视化。点击上方时间范围切换趋势统计天数。</div>
        </div>
        <div class="page-head-toolbar">
            <button @click="changeDays(7)" :class="{ active: trendDays === 7 }">7 天</button>
            <button @click="changeDays(30)" :class="{ active: trendDays === 30 }">30 天</button>
            <button @click="changeDays(90)" :class="{ active: trendDays === 90 }">90 天</button>
            <button @click="refresh()" title="刷新数据"><i class="fa fa-refresh"></i></button>
        </div>
    </div>

    <!-- KPI 卡片 -->
    <div v-if="stats" class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-icon k1"><i class="fa fa-users"></i></div>
            <div class="kpi-info">
                <div class="kpi-label">注册用户</div>
                <div class="kpi-value">{{ formatNumber(stats.overview.userCount) }}<span class="unit">人</span></div>
                <div class="kpi-sub">总用户数</div>
            </div>
        </div>
        <div class="kpi-card">
            <div class="kpi-icon k2"><i class="fa fa-gavel"></i></div>
            <div class="kpi-info">
                <div class="kpi-label">拍品总数</div>
                <div class="kpi-value">{{ formatNumber(stats.overview.itemCount) }}<span class="unit">件</span></div>
                <div class="kpi-sub">拍卖中 {{ stats.overview.activeItemCount }} 件</div>
            </div>
        </div>
        <div class="kpi-card">
            <div class="kpi-icon k3"><i class="fa fa-shopping-cart"></i></div>
            <div class="kpi-info">
                <div class="kpi-label">已成交订单</div>
                <div class="kpi-value">{{ formatNumber(stats.overview.completedOrderCount) }}<span class="unit">单</span></div>
                <div class="kpi-sub">总订单 {{ stats.overview.totalOrderCount }} 单</div>
            </div>
        </div>
        <div class="kpi-card">
            <div class="kpi-icon k4"><i class="fa fa-cny"></i></div>
            <div class="kpi-info">
                <div class="kpi-label">总成交额 (GMV)</div>
                <div class="kpi-value">¥{{ formatMoney(stats.overview.gmv) }}</div>
                <div class="kpi-sub">退款中 {{ stats.overview.pendingRefundCount }} 单</div>
            </div>
        </div>
    </div>

    <!-- 加载中 -->
    <div v-if="loading" class="loading-mask" style="background: #fff; border-radius: 8px; margin-top: 12px;">
        <i class="fa fa-spinner fa-spin"></i>
        正在加载统计数据...
    </div>

    <!-- 图表区 -->
    <div v-if="stats" class="chart-grid">

        <!-- 用户增长趋势（跨 2 列） -->
        <div class="chart-card span2">
            <div class="chart-head">
                <div class="chart-title"><i class="fa fa-line-chart"></i> 用户增长趋势</div>
                <div class="chart-meta">最近 {{ stats.trendDays }} 天</div>
            </div>
            <div class="chart-canvas-wrap tall">
                <canvas ref="userTrendCanvas"></canvas>
            </div>
        </div>

        <!-- 拍品状态分布 -->
        <div class="chart-card">
            <div class="chart-head">
                <div class="chart-title"><i class="fa fa-pie-chart"></i> 拍品状态分布</div>
                <div class="chart-meta">共 {{ stats.overview.itemCount }} 件</div>
            </div>
            <div class="chart-canvas-wrap">
                <canvas ref="itemStatusCanvas"></canvas>
            </div>
        </div>

        <!-- 拍品分类分布 Top 10 -->
        <div class="chart-card">
            <div class="chart-head">
                <div class="chart-title"><i class="fa fa-sitemap"></i> 拍品分类分布 Top 10</div>
                <div class="chart-meta">按拍品数</div>
            </div>
            <div class="chart-canvas-wrap">
                <canvas ref="categoryCanvas"></canvas>
            </div>
        </div>

        <!-- 订单趋势（跨 2 列） -->
        <div class="chart-card span2">
            <div class="chart-head">
                <div class="chart-title"><i class="fa fa-area-chart"></i> 订单趋势</div>
                <div class="chart-meta">最近 {{ stats.trendDays }} 天</div>
            </div>
            <div class="chart-canvas-wrap tall">
                <canvas ref="orderTrendCanvas"></canvas>
            </div>
        </div>

        <!-- 订单状态分布 -->
        <div class="chart-card">
            <div class="chart-head">
                <div class="chart-title"><i class="fa fa-pie-chart"></i> 订单状态分布</div>
                <div class="chart-meta">共 {{ stats.overview.totalOrderCount }} 单</div>
            </div>
            <div class="chart-canvas-wrap">
                <canvas ref="orderStatusCanvas"></canvas>
            </div>
        </div>

        <!-- 热门拍品 Top 10 -->
        <div class="chart-card">
            <div class="chart-head">
                <div class="chart-title"><i class="fa fa-fire"></i> 热门拍品 Top 10</div>
                <div class="chart-meta">按浏览量</div>
            </div>
            <div class="chart-canvas-wrap">
                <canvas ref="topItemsCanvas"></canvas>
            </div>
        </div>

    </div>
</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    const ctxPath = '<%=ctx%>';

    loadVue().then(() => {
        const { createApp, ref, reactive, onMounted, nextTick } = Vue;
        createApp({
            setup() {
                const loading = ref(true);
                const stats = ref(null);
                const trendDays = ref(30);
                const charts = {};  // 存放 chart 实例

                const userTrendCanvas = ref(null);
                const itemStatusCanvas = ref(null);
                const categoryCanvas = ref(null);
                const orderTrendCanvas = ref(null);
                const orderStatusCanvas = ref(null);
                const topItemsCanvas = ref(null);

                function formatNumber(n) {
                    if (n == null) return '0';
                    return Number(n).toLocaleString('zh-CN');
                }
                function formatMoney(n) {
                    if (n == null) return '0.00';
                    return Number(n).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }

                async function fetchOverview() {
                    loading.value = true;
                    return new Promise((resolve, reject) => {
                        loadAxios().then(() => {
                            axios.get(ctxPath + '/admin/stats?action=overview&days=' + trendDays.value)
                                .then(r => {
                                    if (r.data.success) {
                                        stats.value = r.data.data;
                                        loading.value = false;
                                        resolve(r.data.data);
                                    } else {
                                        toast(r.data.message || '加载失败', 'error');
                                        loading.value = false;
                                        reject(r.data);
                                    }
                                })
                                .catch(() => {
                                    toast('网络错误', 'error');
                                    loading.value = false;
                                    reject();
                                });
                        });
                    });
                }

                function destroyChart(name) {
                    if (charts[name]) {
                        try { charts[name].destroy(); } catch (e) {}
                        charts[name] = null;
                    }
                }

                function renderAllCharts() {
                    if (typeof Chart === 'undefined') {
                        toast('Chart.js 加载失败，请检查网络', 'error');
                        return;
                    }
                    renderUserTrend();
                    renderItemStatus();
                    renderCategory();
                    renderOrderTrend();
                    renderOrderStatus();
                    renderTopItems();
                }

                // ============ 用户增长趋势（折线图） ============
                function renderUserTrend() {
                    destroyChart('userTrend');
                    const data = stats.value.userTrend;
                    charts.userTrend = new Chart(userTrendCanvas.value, {
                        type: 'line',
                        data: {
                            labels: data.map(d => d.date),
                            datasets: [{
                                label: '新增用户',
                                data: data.map(d => d.cnt),
                                borderColor: '#3b82f6',
                                backgroundColor: 'rgba(59,130,246,0.1)',
                                borderWidth: 2,
                                fill: true,
                                tension: 0.35,
                                pointRadius: 3,
                                pointHoverRadius: 6,
                                pointBackgroundColor: '#3b82f6',
                                pointBorderColor: '#fff',
                                pointBorderWidth: 2
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: { display: false },
                                tooltip: { mode: 'index', intersect: false }
                            },
                            scales: {
                                y: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#f3f4f6' } },
                                x: { grid: { display: false } }
                            }
                        }
                    });
                }

                // ============ 拍品状态分布（环形图） ============
                function renderItemStatus() {
                    destroyChart('itemStatus');
                    const data = stats.value.itemStatus;
                    charts.itemStatus = new Chart(itemStatusCanvas.value, {
                        type: 'doughnut',
                        data: {
                            labels: data.map(d => d.name),
                            datasets: [{
                                data: data.map(d => d.cnt),
                                backgroundColor: data.map(d => d.color),
                                borderWidth: 2,
                                borderColor: '#fff'
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            cutout: '60%',
                            plugins: {
                                legend: { position: 'right', labels: { boxWidth: 12, font: { size: 11 } } },
                                tooltip: {
                                    callbacks: {
                                        label: function(ctx) {
                                            const total = ctx.dataset.data.reduce((a,b) => a+b, 0);
                                            const pct = total > 0 ? (ctx.parsed / total * 100).toFixed(1) : 0;
                                            return ctx.label + ': ' + ctx.parsed + ' 件 (' + pct + '%)';
                                        }
                                    }
                                }
                            }
                        }
                    });
                }

                // ============ 拍品分类分布（横向柱状图） ============
                function renderCategory() {
                    destroyChart('category');
                    const data = stats.value.categoryDistribution;
                    if (data.length === 0) {
                        const ctx = categoryCanvas.value.getContext('2d');
                        ctx.fillStyle = '#9ca3af';
                        ctx.font = '13px sans-serif';
                        ctx.textAlign = 'center';
                        ctx.fillText('暂无分类数据', categoryCanvas.value.width / 2, 140);
                        return;
                    }
                    charts.category = new Chart(categoryCanvas.value, {
                        type: 'bar',
                        data: {
                            labels: data.map(d => d.category),
                            datasets: [{
                                label: '拍品数',
                                data: data.map(d => d.cnt),
                                backgroundColor: 'rgba(99,102,241,0.7)',
                                borderColor: '#6366f1',
                                borderWidth: 1,
                                borderRadius: 4
                            }]
                        },
                        options: {
                            indexAxis: 'y',
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: { legend: { display: false } },
                            scales: {
                                x: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#f3f4f6' } },
                                y: { grid: { display: false }, ticks: { font: { size: 11 } } }
                            }
                        }
                    });
                }

                // ============ 订单趋势（双轴折线图） ============
                function renderOrderTrend() {
                    destroyChart('orderTrend');
                    const data = stats.value.orderTrend;
                    charts.orderTrend = new Chart(orderTrendCanvas.value, {
                        type: 'line',
                        data: {
                            labels: data.map(d => d.date),
                            datasets: [
                                {
                                    label: '订单数',
                                    data: data.map(d => d.cnt),
                                    borderColor: '#10b981',
                                    backgroundColor: 'rgba(16,185,129,0.1)',
                                    borderWidth: 2,
                                    fill: true,
                                    tension: 0.35,
                                    yAxisID: 'y',
                                    pointRadius: 3,
                                    pointHoverRadius: 6,
                                    pointBackgroundColor: '#10b981',
                                    pointBorderColor: '#fff',
                                    pointBorderWidth: 2
                                },
                                {
                                    label: '成交额 (元)',
                                    data: data.map(d => d.amount),
                                    borderColor: '#f59e0b',
                                    backgroundColor: 'rgba(245,158,11,0.1)',
                                    borderWidth: 2,
                                    fill: false,
                                    tension: 0.35,
                                    yAxisID: 'y1',
                                    pointRadius: 3,
                                    pointHoverRadius: 6,
                                    pointBackgroundColor: '#f59e0b',
                                    pointBorderColor: '#fff',
                                    pointBorderWidth: 2
                                }
                            ]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            interaction: { mode: 'index', intersect: false },
                            plugins: {
                                legend: { position: 'top', align: 'end', labels: { boxWidth: 12, font: { size: 11 } } },
                                tooltip: { mode: 'index', intersect: false }
                            },
                            scales: {
                                y: {
                                    type: 'linear',
                                    position: 'left',
                                    beginAtZero: true,
                                    ticks: { precision: 0 },
                                    grid: { color: '#f3f4f6' },
                                    title: { display: true, text: '订单数', font: { size: 11 } }
                                },
                                y1: {
                                    type: 'linear',
                                    position: 'right',
                                    beginAtZero: true,
                                    grid: { display: false },
                                    title: { display: true, text: '成交额', font: { size: 11 } }
                                },
                                x: { grid: { display: false } }
                            }
                        }
                    });
                }

                // ============ 订单状态分布（环形图） ============
                function renderOrderStatus() {
                    destroyChart('orderStatus');
                    const data = stats.value.orderStatus;
                    charts.orderStatus = new Chart(orderStatusCanvas.value, {
                        type: 'doughnut',
                        data: {
                            labels: data.map(d => d.name),
                            datasets: [{
                                data: data.map(d => d.cnt),
                                backgroundColor: data.map(d => d.color),
                                borderWidth: 2,
                                borderColor: '#fff'
                            }]
                        },
                        options: {
                            responsive: true,
                            maintainAspectRatio: false,
                            cutout: '60%',
                            plugins: {
                                legend: { position: 'right', labels: { boxWidth: 12, font: { size: 11 } } },
                                tooltip: {
                                    callbacks: {
                                        label: function(ctx) {
                                            const total = ctx.dataset.data.reduce((a,b) => a+b, 0);
                                            const pct = total > 0 ? (ctx.parsed / total * 100).toFixed(1) : 0;
                                            return ctx.label + ': ' + ctx.parsed + ' 单 (' + pct + '%)';
                                        }
                                    }
                                }
                            }
                        }
                    });
                }

                // ============ 热门拍品 Top 10（横向柱状图） ============
                function renderTopItems() {
                    destroyChart('topItems');
                    const data = stats.value.topItems;
                    if (data.length === 0) {
                        const ctx = topItemsCanvas.value.getContext('2d');
                        ctx.fillStyle = '#9ca3af';
                        ctx.font = '13px sans-serif';
                        ctx.textAlign = 'center';
                        ctx.fillText('暂无拍品数据', topItemsCanvas.value.width / 2, 140);
                        return;
                    }
                    // 截断标题到 16 字符
                    const labels = data.map(d => {
                        const t = String(d.title || '');
                        return t.length > 16 ? t.substring(0, 16) + '…' : t;
                    });
                    charts.topItems = new Chart(topItemsCanvas.value, {
                        type: 'bar',
                        data: {
                            labels: labels,
                            datasets: [{
                                label: '浏览量',
                                data: data.map(d => d.view_count),
                                backgroundColor: 'rgba(239,68,68,0.7)',
                                borderColor: '#ef4444',
                                borderWidth: 1,
                                borderRadius: 4
                            }]
                        },
                        options: {
                            indexAxis: 'y',
                            responsive: true,
                            maintainAspectRatio: false,
                            plugins: {
                                legend: { display: false },
                                tooltip: {
                                    callbacks: {
                                        title: function(items) { return data[items[0].dataIndex].title; },
                                        label: function(ctx) {
                                            const item = data[ctx.dataIndex];
                                            return [
                                                '浏览量: ' + ctx.parsed.x,
                                                '分类: ' + (item.category || '-')
                                            ];
                                        }
                                    }
                                }
                            },
                            scales: {
                                x: { beginAtZero: true, ticks: { precision: 0 }, grid: { color: '#f3f4f6' } },
                                y: { grid: { display: false }, ticks: { font: { size: 11 } } }
                            }
                        }
                    });
                }

                async function changeDays(days) {
                    if (trendDays.value === days) return;
                    trendDays.value = days;
                    await fetchOverview();
                    await nextTick();
                    renderAllCharts();
                }

                async function refresh() {
                    await fetchOverview();
                    await nextTick();
                    renderAllCharts();
                    toast('已刷新', 'success');
                }

                onMounted(async () => {
                    await fetchOverview();
                    await nextTick();
                    renderAllCharts();
                });

                return {
                    loading, stats, trendDays,
                    userTrendCanvas, itemStatusCanvas, categoryCanvas,
                    orderTrendCanvas, orderStatusCanvas, topItemsCanvas,
                    formatNumber, formatMoney,
                    changeDays, refresh
                };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
