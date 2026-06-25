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
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        .admin-main { max-width: 1400px; margin: 24px auto 0; padding: 0 24px 60px; position: relative; z-index: 3; }

        .welcome {
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(0 0, calc(100% - 16px) 0, 100% 16px, 100% 100%, 16px 100%, 0 calc(100% - 16px));
            box-shadow: 0 0 24px rgba(255,238,0,0.1);
            color: var(--cp-text); padding: 28px 32px;
            display: flex; align-items: center; gap: 20px;
        }
        .welcome-icon {
            width: 64px; height: 64px;
            background: var(--cp-yellow); color: #000;
            clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
            display: grid; place-items: center; font-size: 28px; flex-shrink: 0;
        }
        .welcome-info { flex: 1; }
        .welcome-title { font-size: 20px; font-weight: 900; font-style: italic; color: var(--cp-yellow); margin-bottom: 4px; }
        .welcome-sub { font-size: 12px; font-family: var(--font-mono); color: var(--cp-text-dim); }

        .quick-block {
            background: #000;
            border: 1.5px solid var(--cp-yellow);
            clip-path: polygon(0 0, calc(100% - 16px) 0, 100% 16px, 100% 100%, 16px 100%, 0 calc(100% - 16px));
            box-shadow: 0 0 24px rgba(255,238,0,0.1);
            margin-top: 16px; padding: 20px 24px;
        }
        .quick-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
        .quick-card {
            padding: 16px;
            border: 1.5px solid var(--cp-yellow-dim);
            clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 8px 100%, 0 calc(100% - 8px));
            text-decoration: none; color: inherit;
            transition: all 0.2s; display: block;
        }
        .quick-card:hover {
            border-color: var(--cp-yellow);
            box-shadow: 0 0 16px rgba(255,238,0,0.4);
            transform: translateY(-2px);
        }
        .quick-card-icon { font-size: 22px; color: var(--cp-yellow); margin-bottom: 8px; }
        .quick-card-title { font-size: 14px; font-weight: 700; color: var(--cp-text); text-transform: uppercase; margin-bottom: 4px; }
        .quick-card-sub { font-size: 11px; font-family: var(--font-mono); color: var(--cp-text-dim); }

        .nav-badge {
            display: inline-block; padding: 1px 6px; margin-left: 4px;
            background: var(--cp-red); color: #fff; font-size: 9px;
            font-family: var(--font-mono); font-weight: 700;
            clip-path: polygon(3px 0, 100% 0, calc(100% - 3px) 100%, 0 100%);
        }

        @media (max-width: 980px) {
            .quick-grid { grid-template-columns: repeat(2, 1fr); }
        }
        @media (max-width: 640px) {
            .quick-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/admin" class="cp-logo">管理后台</a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/admin" class="active"><i class="fa fa-dashboard"></i> 概览</a>
            <a href="<%=ctx%>/admin/refund?action=list">
                <i class="fa fa-undo"></i> 退款审批
                <% if (pendingRefund > 0) { %>
                    <span class="nav-badge"><%= pendingRefund %></span>
                <% } %>
            </a>
            <a href="<%=ctx%>/admin/complaint?action=list">
                <i class="fa fa-flag"></i> 投诉审批
                <% if (pendingComplaint > 0) { %>
                    <span class="nav-badge"><%= pendingComplaint %></span>
                <% } %>
            </a>
            <a href="<%=ctx%>/admin/item?action=list"><i class="fa fa-gavel"></i> 拍品</a>
            <a href="<%=ctx%>/admin/user?action=list"><i class="fa fa-users"></i> 用户</a>
            <a href="<%=ctx%>/admin/category?action=list"><i class="fa fa-sitemap"></i> 分类</a>
            <a href="<%=ctx%>/admin/announcement?action=list"><i class="fa fa-bullhorn"></i> 公告</a>
            <a href="<%=ctx%>/admin/stats"><i class="fa fa-bar-chart"></i> 数据统计</a>
        </nav>
        <div class="cp-nav-user">
            <i class="fa fa-user-circle-o" style="color: var(--cp-yellow-dim);"></i>
            <span style="font-size: 12px; color: var(--cp-text-dim); font-family: var(--font-mono);"><%= EscapeUtil.html(admin.getAdminName()) %></span>
            <span style="padding: 2px 6px; background: rgba(255,238,0,0.1); color: var(--cp-yellow-dim); font-size: 9px; font-family: var(--font-mono); text-transform: uppercase; border: 1px solid var(--cp-yellow-dim);"><%= admin.getRole() == null ? "admin" : admin.getRole() %></span>
            <a href="<%=ctx%>/admin/login?action=logout" class="icon-btn"><i class="fa fa-sign-out"></i></a>
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

    <div class="cp-kpi-grid" style="margin-top: 16px;">
        <div class="cp-kpi-card">
            <div class="cp-kpi-icon k1"><i class="fa fa-bell"></i></div>
            <div class="cp-kpi-info">
                <div class="cp-kpi-label">待审核退款</div>
                <div class="cp-kpi-value" style="<%= pendingRefund > 0 ? "color: var(--cp-red); text-shadow: 0 0 8px var(--cp-red);" : "" %>"><%= pendingRefund %></div>
                <a href="<%=ctx%>/admin/refund?action=list&status=4" style="font-size: 10px; font-family: var(--font-mono); color: var(--cp-yellow-dim);">去处理 &rarr;</a>
            </div>
        </div>
        <div class="cp-kpi-card">
            <div class="cp-kpi-icon k2"><i class="fa fa-list-alt"></i></div>
            <div class="cp-kpi-info">
                <div class="cp-kpi-label">总订单数</div>
                <div class="cp-kpi-value">-</div>
                <span style="font-size: 10px; font-family: var(--font-mono); color: var(--cp-text-dim);">阶段 3 上线</span>
            </div>
        </div>
        <div class="cp-kpi-card">
            <div class="cp-kpi-icon k3"><i class="fa fa-users"></i></div>
            <div class="cp-kpi-info">
                <div class="cp-kpi-label">总用户数</div>
                <div class="cp-kpi-value">-</div>
                <span style="font-size: 10px; font-family: var(--font-mono); color: var(--cp-text-dim);">阶段 3 上线</span>
            </div>
        </div>
        <div class="cp-kpi-card">
            <div class="cp-kpi-icon k4"><i class="fa fa-gavel"></i></div>
            <div class="cp-kpi-info">
                <div class="cp-kpi-label">总拍品数</div>
                <div class="cp-kpi-value">-</div>
                <span style="font-size: 10px; font-family: var(--font-mono); color: var(--cp-text-dim);">阶段 3 上线</span>
            </div>
        </div>
    </div>

    <div class="quick-block">
        <div class="cp-section-title">快捷入口</div>
        <div class="quick-grid">
            <a href="<%=ctx%>/admin/refund?action=list" class="quick-card">
                <div class="quick-card-icon"><i class="fa fa-undo"></i></div>
                <div class="quick-card-title">退款审批</div>
                <div class="quick-card-sub">处理买家退款申请</div>
            </a>
            <a href="<%=ctx%>/admin/complaint?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-red);"><i class="fa fa-flag"></i></div>
                <div class="quick-card-title">投诉审批</div>
                <div class="quick-card-sub">处理用户投诉纠纷</div>
            </a>
            <a href="<%=ctx%>/admin/item?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-cyan);"><i class="fa fa-gavel"></i></div>
                <div class="quick-card-title">拍品管理</div>
                <div class="quick-card-sub">下架 / 审核拍品</div>
            </a>
            <a href="<%=ctx%>/admin/user?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-yellow);"><i class="fa fa-users"></i></div>
                <div class="quick-card-title">用户管理</div>
                <div class="quick-card-sub">封禁 / 信用调整</div>
            </a>
            <a href="<%=ctx%>/admin/category?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-cyan);"><i class="fa fa-sitemap"></i></div>
                <div class="quick-card-title">分类管理</div>
                <div class="quick-card-sub">拍品分类 / 启用禁用</div>
            </a>
            <a href="<%=ctx%>/admin/announcement?action=list" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-red);"><i class="fa fa-bullhorn"></i></div>
                <div class="quick-card-title">公告管理</div>
                <div class="quick-card-sub">发布 / 撤回 / 置顶</div>
            </a>
            <a href="<%=ctx%>/admin/stats" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-cyan);"><i class="fa fa-bar-chart"></i></div>
                <div class="quick-card-title">数据统计</div>
                <div class="quick-card-sub">图表 / KPI 总览</div>
            </a>
            <a href="<%=ctx%>/index.jsp" target="_blank" class="quick-card">
                <div class="quick-card-icon" style="color: var(--cp-yellow-dim);"><i class="fa fa-external-link"></i></div>
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
