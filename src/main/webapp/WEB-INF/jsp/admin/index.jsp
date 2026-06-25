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
    Integer pendingRefund = (Integer) request.getAttribute("pendingRefund");
    Integer pendingComplaint = (Integer) request.getAttribute("pendingComplaint");
    if (pendingRefund == null) pendingRefund = 0;
    if (pendingComplaint == null) pendingComplaint = 0;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>管理后台 · 概览</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
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
        .admin-nav a .badge { display: inline-block; padding: 1px 6px; margin-left: 4px;
                              background: #ef4444; color: #fff; font-size: 10px;
                              border-radius: 8px; font-weight: 600; }
        .admin-user { margin-left: auto; display: flex; align-items: center; gap: 12px; font-size: 13px; }
        .admin-user .role-tag { padding: 2px 8px; background: #374151; color: #fbbf24;
                                border-radius: 3px; font-size: 11px; font-weight: 600; }
        .admin-user a { color: #9ca3af; text-decoration: none; font-size: 12px; }
        .admin-user a:hover { color: #fff; }

        .admin-main { max-width: 1400px; margin: 16px auto 0; padding: 0 20px 60px; }

        /* 欢迎卡 */
        .welcome { background: linear-gradient(135deg, #1f2937 0%, #374151 100%);
                   color: #fff; border-radius: 8px; padding: 28px 32px;
                   display: flex; align-items: center; gap: 20px; }
        .welcome-icon { width: 64px; height: 64px; border-radius: 8px;
                        background: rgba(245,158,11,0.2); color: #fbbf24;
                        display: grid; place-items: center; font-size: 28px; }
        .welcome-info { flex: 1; }
        .welcome-title { font-size: 20px; font-weight: 700; margin-bottom: 4px; }
        .welcome-sub { font-size: 13px; opacity: 0.8; }

        /* 4 数字卡 */
        .stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-top: 16px; }
        .stat-card { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                     padding: 20px; display: flex; align-items: center; gap: 14px; }
        .stat-icon { width: 48px; height: 48px; border-radius: 8px;
                     display: grid; place-items: center; font-size: 20px; flex-shrink: 0; }
        .stat-icon.orange  { background: #fef3c7; color: #b45309; }
        .stat-icon.blue    { background: #dbeafe; color: #1e40af; }
        .stat-icon.green   { background: #d1fae5; color: #047857; }
        .stat-icon.purple  { background: #ede9fe; color: #6d28d9; }
        .stat-value { font-size: 24px; font-weight: 800; color: var(--color-text); line-height: 1.1; }
        .stat-label { font-size: 12px; color: var(--color-muted); margin-top: 4px; }
        .stat-link { font-size: 12px; color: var(--color-primary); margin-top: 4px;
                     text-decoration: none; }
        .stat-link:hover { text-decoration: underline; }

        /* 快捷入口 */
        .quick-block { background: #fff; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.04);
                       margin-top: 16px; padding: 20px 24px; }
        .block-title { font-size: 15px; font-weight: 600; margin-bottom: 14px;
                       display: flex; align-items: center; gap: 8px; }
        .block-title::before { content: ''; display: inline-block; width: 3px; height: 16px;
                               background: var(--color-primary); border-radius: 2px; }
        .quick-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
        .quick-card { padding: 16px; border: 1.5px solid var(--color-border-soft);
                      border-radius: 6px; text-decoration: none; color: inherit;
                      transition: all 0.15s; }
        .quick-card:hover { border-color: var(--color-primary); transform: translateY(-1px);
                            box-shadow: 0 4px 8px rgba(0,0,0,0.05); }
        .quick-card-icon { font-size: 22px; color: var(--color-primary); margin-bottom: 8px; }
        .quick-card-title { font-size: 14px; font-weight: 600; margin-bottom: 4px; }
        .quick-card-sub { font-size: 12px; color: var(--color-muted); }
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
            <a href="<%=ctx%>/admin" class="active"><i class="fa fa-dashboard"></i> 概览</a>
            <a href="<%=ctx%>/admin/refund?action=list">
                <i class="fa fa-undo"></i> 退款审批
                <% if (pendingRefund > 0) { %>
                    <span class="badge"><%= pendingRefund %></span>
                <% } %>
            </a>
            <a href="<%=ctx%>/admin/complaint?action=list">
                <i class="fa fa-flag"></i> 投诉审批
                <% if (pendingComplaint > 0) { %>
                    <span class="badge"><%= pendingComplaint %></span>
                <% } %>
            </a>
            <a href="<%=ctx%>/admin/item?action=list">
                <i class="fa fa-gavel"></i> 拍品
            </a>
            <a href="<%=ctx%>/admin/user?action=list">
                <i class="fa fa-users"></i> 用户
            </a>
            <a href="<%=ctx%>/admin/category?action=list">
                <i class="fa fa-sitemap"></i> 分类
            </a>
            <a href="<%=ctx%>/admin/announcement?action=list">
                <i class="fa fa-bullhorn"></i> 公告
            </a>
            <a href="<%=ctx%>/admin/stats">
                <i class="fa fa-bar-chart"></i> 数据统计
            </a>
        </nav>
        <div class="admin-user">
            <i class="fa fa-user-circle-o"></i>
            <span><%= EscapeUtil.html(admin.getAdminName()) %></span>
            <span class="role-tag"><%= admin.getRole() == null ? "admin" : admin.getRole() %></span>
            <a href="<%=ctx%>/admin/login?action=logout"><i class="fa fa-sign-out"></i> 退出</a>
        </div>
    </div>
</header>

<div class="admin-main">

    <div class="welcome">
        <div class="welcome-icon"><i class="fa fa-shield"></i></div>
        <div class="welcome-info">
            <div class="welcome-title">欢迎回来，<%= EscapeUtil.html(admin.getAdminName()) %>！</div>
            <div class="welcome-sub">这是管理后台概览页。你可以处理用户退款申请、查看平台数据等。</div>
        </div>
    </div>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon orange"><i class="fa fa-bell"></i></div>
            <div>
                <div class="stat-value" style="color: <%= pendingRefund > 0 ? "#b45309" : "var(--color-text)" %>;">
                    <%= pendingRefund %>
                </div>
                <div class="stat-label">待审核退款</div>
                <a href="<%=ctx%>/admin/refund?action=list&status=4" class="stat-link">去处理 →</a>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon blue"><i class="fa fa-list-alt"></i></div>
            <div>
                <div class="stat-value">-</div>
                <div class="stat-label">总订单数</div>
                <span class="stat-link" style="color: var(--color-muted);">阶段 3 上线</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon green"><i class="fa fa-users"></i></div>
            <div>
                <div class="stat-value">-</div>
                <div class="stat-label">总用户数</div>
                <span class="stat-link" style="color: var(--color-muted);">阶段 3 上线</span>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon purple"><i class="fa fa-gavel"></i></div>
            <div>
                <div class="stat-value">-</div>
                <div class="stat-label">总拍品数</div>
                <span class="stat-link" style="color: var(--color-muted);">阶段 3 上线</span>
            </div>
        </div>
    </div>

    <div class="quick-block">
        <div class="block-title">快捷入口</div>
        <div class="quick-grid">
            <a href="<%=ctx%>/admin/refund?action=list" class="quick-card">
                <div class="quick-card-icon"><i class="fa fa-undo"></i></div>
                <div class="quick-card-title">退款审批</div>
                <div class="quick-card-sub">处理买家退款申请</div>
            </a>
            <a href="<%=ctx%>/admin/complaint?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: #b91c1c;"><i class="fa fa-flag"></i></div>
                <div class="quick-card-title">投诉审批</div>
                <div class="quick-card-sub">处理用户投诉纠纷</div>
            </a>
            <a href="<%=ctx%>/admin/item?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: #6d28d9;"><i class="fa fa-gavel"></i></div>
                <div class="quick-card-title">拍品管理</div>
                <div class="quick-card-sub">下架 / 审核拍品</div>
            </a>
            <a href="<%=ctx%>/admin/user?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: #047857;"><i class="fa fa-users"></i></div>
                <div class="quick-card-title">用户管理</div>
                <div class="quick-card-sub">封禁 / 信用调整</div>
            </a>
            <a href="<%=ctx%>/admin/category?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: #4338ca;"><i class="fa fa-sitemap"></i></div>
                <div class="quick-card-title">分类管理</div>
                <div class="quick-card-sub">拍品分类 / 启用禁用</div>
            </a>
            <a href="<%=ctx%>/admin/announcement?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: #b91c1c;"><i class="fa fa-bullhorn"></i></div>
                <div class="quick-card-title">公告管理</div>
                <div class="quick-card-sub">发布 / 撤回 / 置顶</div>
            </a>
            <a href="<%=ctx%>/admin/stats" class="quick-card">
                <div class="quick-card-icon" style="color: #6366f1;"><i class="fa fa-bar-chart"></i></div>
                <div class="quick-card-title">数据统计</div>
                <div class="quick-card-sub">图表 / KPI 总览</div>
            </a>
            <a href="<%=ctx%>/index.jsp" target="_blank" class="quick-card">
                <div class="quick-card-icon" style="color: #1e40af;"><i class="fa fa-external-link"></i></div>
                <div class="quick-card-title">前台首页</div>
                <div class="quick-card-sub">新窗口打开</div>
            </a>
        </div>
    </div>

</div>

<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
</body>
</html>
