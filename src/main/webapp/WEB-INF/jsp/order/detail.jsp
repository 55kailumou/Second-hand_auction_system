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

    org.example.entity.OrderInfo order =
            (org.example.entity.OrderInfo) request.getAttribute("order");
    org.example.entity.Address address =
            (org.example.entity.Address) request.getAttribute("address");
    org.example.entity.AuctionItem item =
            (org.example.entity.AuctionItem) request.getAttribute("item");
    Boolean isBuyer = (Boolean) request.getAttribute("isBuyer");
    String error = (String) request.getAttribute("error");
    if (isBuyer == null) isBuyer = false;
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>订单详情 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        :root {
            --cp-yellow: #FFEE00;
            --cp-yellow-dim: #AA9900;
            --cp-bg: #000;
            --cp-card-bg: #0a0a0a;
            --cp-border: #FFEE00;
            --cp-text: #FFEE00;
            --cp-text-dim: #AA9900;
            --cp-text-muted: #555;
            --cp-danger: #ff3355;
            --cp-font: 'Sarasa Mono SC', monospace;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: var(--cp-bg);
            color: var(--cp-text);
            font-family: var(--cp-font);
            line-height: 1.6;
            min-height: 100vh;
        }
        a { color: var(--cp-yellow); text-decoration: none; transition: opacity 0.15s; }
        a:hover { opacity: 0.7; }
        i.fa { margin-right: 4px; }

        /* ===== NAV ===== */

        /* ===== CONTAINER ===== */
        .cp-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px 60px;
        }

        /* ===== DETAIL LAYOUT ===== */
        .cp-detail-layout {
            display: grid;
            grid-template-columns: 1fr 360px;
            gap: 20px;
            margin-top: 20px;
        }
        @media (max-width: 900px) { .cp-detail-layout { grid-template-columns: 1fr; } }

        /* ===== CYBERPUNK CARD ===== */
        .cp-card {
            background: var(--cp-card-bg);
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 10px 100%, 0 calc(100% - 10px));
            padding: 24px;
            margin-bottom: 16px;
        }

        /* ===== STATUS BAR ===== */
        .cp-status-bar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 20px 24px;
            background: #0d0d0d;
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 12px) 0, 100% 12px, 100% 100%, 12px 100%, 0 calc(100% - 12px));
            margin-bottom: 16px;
        }
        .cp-status-text {
            font-size: 20px;
            font-weight: 700;
            color: var(--cp-yellow);
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .cp-status-tip {
            font-size: 13px;
            color: var(--cp-text-dim);
            margin-top: 4px;
        }
        .cp-status-icon {
            font-size: 56px;
            color: var(--cp-yellow);
            text-shadow: 0 0 10px var(--cp-yellow);
        }

        /* ===== TIMELINE ===== */
        .cp-timeline {
            display: flex;
            gap: 0;
            margin-top: 16px;
        }
        .cp-timeline-step {
            flex: 1;
            text-align: center;
            position: relative;
        }
        .cp-timeline-step .dot {
            width: 28px;
            height: 28px;
            border: 1.5px solid #333;
            background: #0d0d0d;
            color: #555;
            margin: 0 auto 8px;
            display: grid;
            place-items: center;
            font-size: 14px;
            clip-path: polygon(3px 0, 100% 0, 100% calc(100% - 3px), calc(100% - 3px) 100%, 0 100%, 0 3px);
        }
        .cp-timeline-step.done .dot {
            background: var(--cp-yellow);
            color: #000;
            border-color: var(--cp-yellow);
        }
        .cp-timeline-step .label {
            font-size: 12px;
            color: var(--cp-text-muted);
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .cp-timeline-step.done .label {
            color: var(--cp-yellow);
            font-weight: 500;
        }
        .cp-timeline-step:not(:last-child)::after {
            content: '';
            position: absolute;
            top: 14px;
            left: calc(50% + 14px);
            right: calc(-50% + 14px);
            height: 2px;
            background: #222;
        }
        .cp-timeline-step.done:not(:last-child)::after {
            background: var(--cp-yellow);
        }

        /* ===== SECTION TITLE ===== */
        .cp-section-title {
            font-size: 15px;
            font-weight: 600;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .cp-section-title::before {
            content: '';
            display: inline-block;
            width: 4px;
            height: 16px;
            background: var(--cp-yellow);
        }

        /* ===== INFO ROW ===== */
        .cp-info-row {
            display: flex;
            padding: 8px 0;
            font-size: 14px;
            border-bottom: 1px solid #111;
        }
        .cp-info-label {
            color: var(--cp-text-dim);
            min-width: 100px;
        }
        .cp-info-value {
            color: var(--cp-yellow);
            flex: 1;
            word-break: break-all;
        }
        .cp-info-value.mono {
            font-family: var(--cp-font);
        }

        /* ===== ITEM MINI ===== */
        .cp-item-mini {
            display: flex;
            gap: 16px;
            padding: 12px;
            border: 1px solid #222;
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
        }
        .cp-item-mini-cover {
            width: 80px;
            height: 80px;
            border: 1px solid #333;
            background: #0d0d0d center/cover no-repeat;
            flex-shrink: 0;
            display: grid;
            place-items: center;
            color: #555;
            font-size: 24px;
        }
        .cp-item-mini-info {
            flex: 1;
            min-width: 0;
        }
        .cp-item-mini-title {
            font-size: 14px;
            font-weight: 600;
            color: var(--cp-yellow);
            margin-bottom: 4px;
            line-height: 1.4;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .cp-item-mini-price {
            font-size: 16px;
            font-weight: 700;
            color: #fff;
            text-shadow: 0 0 6px var(--cp-yellow);
        }

        /* ===== ADDRESS CARD ===== */
        .cp-address-card {
            border: 1px solid #222;
            padding: 16px;
            border-left: 3px solid var(--cp-yellow);
            clip-path: polygon(0 0, calc(100% - 6px) 0, 100% 6px, 100% 100%, 6px 100%, 0 calc(100% - 6px));
        }
        .cp-address-name {
            font-size: 16px;
            font-weight: 600;
            color: var(--cp-yellow);
            margin-bottom: 4px;
        }
        .cp-address-phone {
            color: var(--cp-text-dim);
            font-size: 13px;
            margin-bottom: 6px;
        }
        .cp-address-detail {
            color: var(--cp-text);
            font-size: 14px;
            line-height: 1.5;
        }

        /* ===== ACTION PANEL ===== */
        .cp-action-panel {
            position: sticky;
            top: 80px;
        }
        .cp-action-card {
            background: var(--cp-card-bg);
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 10px 100%, 0 calc(100% - 10px));
            padding: 24px;
            margin-bottom: 16px;
        }
        .cp-price-big {
            font-size: 32px;
            font-weight: 700;
            color: #fff;
            text-shadow: 0 0 10px var(--cp-yellow);
            text-align: center;
            margin: 16px 0;
        }
        .cp-price-big small {
            font-size: 14px;
            font-weight: 400;
            margin-right: 4px;
        }
        .cp-action-btn {
            width: 100%;
            margin-bottom: 8px;
        }

        /* ===== BUTTONS ===== */
        .cp-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 4px;
            padding: 8px 16px;
            border: 1.5px solid var(--cp-border);
            background: transparent;
            color: var(--cp-yellow);
            font-family: var(--cp-font);
            font-size: 13px;
            cursor: pointer;
            text-decoration: none;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            transition: all 0.2s;
            clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
        }
        .cp-btn:hover {
            background: var(--cp-yellow);
            color: #000;
        }
        .cp-btn:disabled {
            opacity: 0.4;
            cursor: not-allowed;
            pointer-events: none;
        }
        .cp-btn-sm {
            padding: 5px 12px;
            font-size: 11px;
        }
        .cp-btn-outline {
            border-color: #555;
            color: #888;
        }
        .cp-btn-outline:hover {
            border-color: var(--cp-yellow);
            color: var(--cp-yellow);
            background: transparent;
        }
        .cp-btn-danger {
            border-color: var(--cp-danger);
            color: var(--cp-danger);
        }
        .cp-btn-danger:hover {
            background: var(--cp-danger);
            color: #fff;
        }

        /* ===== BADGES ===== */
        .cp-badge {
            display: inline-block;
            padding: 3px 10px;
            font-size: 11px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border: 1px solid transparent;
            font-family: var(--cp-font);
        }
        .cp-badge-warning {
            background: #332800;
            color: #FFEE00;
            border-color: #FFEE00;
        }
        .cp-badge-info {
            background: #001a33;
            color: #66bbff;
            border-color: #66bbff;
        }
        .cp-badge-primary {
            background: #331a00;
            color: #ff8800;
            border-color: #ff8800;
        }
        .cp-badge-success {
            background: #00331a;
            color: #00ff88;
            border-color: #00ff88;
        }
        .cp-badge-gray {
            background: #1a1a1a;
            color: #888;
            border-color: #555;
        }

        /* ===== FORM ===== */
        .cp-form-group {
            margin-bottom: 12px;
        }
        .cp-form-label {
            display: block;
            font-size: 13px;
            color: var(--cp-text-dim);
            margin-bottom: 4px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .cp-form-input {
            width: 100%;
            padding: 8px 12px;
            background: #111;
            border: 1px solid #333;
            color: var(--cp-yellow);
            font-size: 14px;
            font-family: var(--cp-font);
            outline: none;
        }
        .cp-form-input:focus {
            border-color: var(--cp-yellow);
        }
        .cp-form-input::placeholder {
            color: #444;
        }
        textarea.cp-form-input {
            resize: vertical;
            font-family: var(--cp-font);
        }

        /* ===== MODAL ===== */
        .cp-modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.85);
            z-index: 1000;
            display: none;
            align-items: center;
            justify-content: center;
        }
        .cp-modal-overlay.show {
            display: flex;
        }
        .cp-modal {
            background: #0d0d0d;
            border: 1.5px solid var(--cp-border);
            clip-path: polygon(0 0, calc(100% - 14px) 0, 100% 14px, 100% 100%, 14px 100%, 0 calc(100% - 14px));
            padding: 32px;
            width: 90%;
            max-width: 480px;
        }
        .cp-modal-title {
            font-size: 18px;
            font-weight: 600;
            margin-bottom: 20px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: var(--cp-yellow);
        }
        .cp-modal-close {
            float: right;
            cursor: pointer;
            color: var(--cp-text-dim);
            font-size: 20px;
            border: none;
            background: none;
            font-family: var(--cp-font);
        }
        .cp-modal-close:hover {
            color: var(--cp-yellow);
        }

        /* ===== INLINE OVERRIDES ===== */
        .btn { font-family: var(--cp-font); }
    </style>
</head>
<body>

<!-- 顶部导航 -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <i class="fa fa-gavel"></i> 二手拍卖
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list" class="active">我的订单</a>
        </nav>
        <div class="cp-nav-user">
            <span>欢迎，</span>
            <span style="color: #fff; font-weight: 500;"><%= currentUser.getUsername() %></span>
            <a href="<%=ctx%>/user?action=logout" style="color: var(--cp-yellow);">退出</a>
        </div>
    </div>
</header>

<div class="cp-container">

    <% if (error != null) { %>
        <div class="cp-card" style="background: #220000; color: #ff4444; border-color: #ff4444;">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <% if (order == null) { %>
        <div class="cp-card" style="text-align: center; padding: 60px;">
            <i class="fa fa-exclamation-triangle" style="font-size: 48px; color: #555;"></i>
            <h3 style="margin: 16px 0 8px; color: var(--cp-yellow);">订单不存在或已被删除</h3>
            <a href="<%=ctx%>/order?action=list" class="cp-btn">返回订单列表</a>
        </div>
    <% } else { %>

    <!-- 状态栏 -->
    <div class="cp-status-bar">
        <div>
            <div class="cp-status-text">
                <i class="fa <%= order.getStatus() != null && order.getStatus() == 0 ? "fa-clock-o" :
                                  order.getStatus() != null && order.getStatus() == 1 ? "fa-credit-card" :
                                  order.getStatus() != null && order.getStatus() == 2 ? "fa-truck" :
                                  order.getStatus() != null && order.getStatus() == 3 ? "fa-check-circle" :
                                  "fa-times-circle" %>"></i>
                <%= order.getStatusText() %>
            </div>
            <div class="cp-status-tip">
                <% if (order.getStatus() != null && order.getStatus() == 0 && isBuyer) { %>
                    请在 24 小时内完成付款，超时订单将自动取消
                <% } else if (order.getStatus() != null && order.getStatus() == 1 && !isBuyer) { %>
                    买家已付款，请尽快发货
                <% } else if (order.getStatus() != null && order.getStatus() == 2 && isBuyer) { %>
                    卖家已发货，等待你确认收货
                <% } else if (order.getStatus() != null && order.getStatus() == 3) { %>
                    交易已完成，感谢使用
                <% } else if (order.getStatus() != null && order.getStatus() == 4 && isBuyer) { %>
                    退款申请已提交，等待管理员审核（通常 1-3 个工作日）
                <% } else if (order.getStatus() != null && order.getStatus() == 4 && !isBuyer) { %>
                    买家申请退款，请等待管理员审核结果
                <% } else if (order.getStatus() != null && order.getStatus() == 5) { %>
                    退款已审核完成，资金将原路返回
                <% } else if (order.getStatus() != null && order.getStatus() == 6) { %>
                    订单已取消
                <% } %>
            </div>
        </div>
        <i class="fa <%= order.getStatus() != null && order.getStatus() == 3 ? "fa-check-circle" : "fa-clock-o" %> cp-status-icon"></i>
    </div>

    <div class="cp-detail-layout">

        <!-- 左侧：订单详情 -->
        <div>
            <!-- 订单基本信息 -->
            <div class="cp-card">
                <div class="cp-section-title">订单信息</div>
                <div class="cp-info-row"><span class="cp-info-label">订单号</span><span class="cp-info-value mono"><%= EscapeUtil.html(order.getOrderNo()) %></span></div>
                <div class="cp-info-row"><span class="cp-info-label">下单时间</span><span class="cp-info-value"><%= order.getCreateTime() == null ? "-" : order.getCreateTime().toString().replace('T', ' ') %></span></div>
                <% if (order.getPayTime() != null) { %>
                    <div class="cp-info-row"><span class="cp-info-label">付款时间</span><span class="cp-info-value"><%= order.getPayTime().toString().replace('T', ' ') %></span></div>
                <% } %>
                <% if (order.getDeliverTime() != null) { %>
                    <div class="cp-info-row"><span class="cp-info-label">发货时间</span><span class="cp-info-value"><%= order.getDeliverTime().toString().replace('T', ' ') %></span></div>
                <% } %>
                <% if (order.getReceiveTime() != null) { %>
                    <div class="cp-info-row"><span class="cp-info-label">收货时间</span><span class="cp-info-value"><%= order.getReceiveTime().toString().replace('T', ' ') %></span></div>
                <% } %>
                <% if (order.getSettledTime() != null) { %>
                    <div class="cp-info-row" style="background: rgba(0, 255, 65, 0.05);">
                        <span class="cp-info-label" style="color: #00FF41;">平台打款时间</span>
                        <span class="cp-info-value" style="color: #00FF41;"><%= order.getSettledTime().toString().replace('T', ' ') %></span>
                    </div>
                <% } %>
                <% if (order.getFinalPayMethod() != null && !order.getFinalPayMethod().isEmpty()) { %>
                    <div class="cp-info-row">
                        <span class="cp-info-label">尾款支付方式</span>
                        <span class="cp-info-value">
                            <%= "balance".equals(order.getFinalPayMethod()) ? "<i class='fa fa-database'></i> 账户余额" :
                                ("alipay".equals(order.getFinalPayMethod()) ? "<i class='fa fa-mobile' style='color:#1677ff;'></i> 支付宝" :
                                 ("wechat".equals(order.getFinalPayMethod()) ? "<i class='fa fa-weixin' style='color:#07c160;'></i> 微信支付" :
                                  order.getFinalPayMethod())) %>
                        </span>
                    </div>
                <% } %>
                <% if (order.getLogisticsCompany() != null && !order.getLogisticsCompany().isEmpty()) { %>
                    <div class="cp-info-row"><span class="cp-info-label">物流公司</span><span class="cp-info-value"><%= order.getLogisticsCompany() == null ? "-" : EscapeUtil.html(order.getLogisticsCompany()) %></span></div>
                <% } %>
                <% if (order.getTrackingNumber() != null && !order.getTrackingNumber().isEmpty()) { %>
                    <div class="cp-info-row"><span class="cp-info-label">物流单号</span><span class="cp-info-value mono"><%= order.getTrackingNumber() == null ? "-" : EscapeUtil.html(order.getTrackingNumber()) %></span></div>
                <% } %>
                <div class="cp-info-row"><span class="cp-info-label">买家 ID</span><span class="cp-info-value"><%= order.getBuyerId() %></span></div>
                <div class="cp-info-row"><span class="cp-info-label">卖家 ID</span><span class="cp-info-value"><%= order.getSellerId() %></span></div>
            </div>

            <!-- 拍品信息 -->
            <div class="cp-card">
                <div class="cp-section-title">拍品信息</div>
                <div class="cp-item-mini">
                    <div class="cp-item-mini-cover" style="<%= order.getCoverImage() != null && !order.getCoverImage().isEmpty() ? "background-image: url('" + order.getCoverImage() + "');" : "" %>">
                        <% if (order.getCoverImage() == null || order.getCoverImage().isEmpty()) { %>
                            <i class="fa fa-image"></i>
                        <% } %>
                    </div>
                    <div class="cp-item-mini-info">
                        <div class="cp-item-mini-title"><%= EscapeUtil.html(order.getItemTitle()) %></div>
                        <div style="font-size: 12px; color: var(--cp-text-dim); margin-bottom: 6px;">拍品 ID：<%= order.getItemId() %></div>
                        <div class="cp-item-mini-price">成交价 ¥<%= order.getFinalPrice() == null ? "0.00" : order.getFinalPrice().toPlainString() %></div>
                    </div>
                </div>
                <% if (item != null) { %>
                    <div style="margin-top: 12px; text-align: right;">
                        <a href="<%=ctx%>/item?action=detail&id=<%= item.getId() %>" class="cp-btn cp-btn-sm">查看拍品 →</a>
                    </div>
                <% } %>
            </div>

            <!-- 收货地址 -->
            <div class="cp-card">
                <div class="cp-section-title">收货地址</div>
                <% if (address != null) { %>
                    <div class="cp-address-card">
                        <div class="cp-address-name">
                            <%= address.getReceiverName() %>
                            <span class="cp-address-phone" style="font-weight: 400; margin-left: 12px;"><%= address.getReceiverPhone() %></span>
                        </div>
                        <div class="cp-address-detail">
                            <%= address.getFullAddress() %>
                        </div>
                    </div>
                <% } else { %>
                    <div style="color: var(--cp-text-dim); padding: 16px;">地址信息已被删除</div>
                <% } %>
            </div>

            <!-- 状态时间线 -->
            <div class="cp-card">
                <div class="cp-section-title">订单进度</div>
                <div class="cp-timeline">
                    <div class="cp-timeline-step done">
                        <div class="dot"><i class="fa fa-check"></i></div>
                        <div class="label">下单</div>
                    </div>
                    <div class="cp-timeline-step <%= order.getStatus() != null && order.getStatus() >= 1 ? "done" : "" %>">
                        <div class="dot"><i class="fa fa-credit-card"></i></div>
                        <div class="label">付款</div>
                    </div>
                    <div class="cp-timeline-step <%= order.getStatus() != null && order.getStatus() >= 2 ? "done" : "" %>">
                        <div class="dot"><i class="fa fa-truck"></i></div>
                        <div class="label">发货</div>
                    </div>
                    <div class="cp-timeline-step <%= order.getStatus() != null && order.getStatus() >= 3 ? "done" : "" %>">
                        <div class="dot"><i class="fa fa-check-circle"></i></div>
                        <div class="label">收货</div>
                    </div>
                </div>
            </div>

            <!-- 退款信息（仅 status 4 / 5 时显示） -->
            <% if (order.getStatus() != null && (order.getStatus() == 4 || order.getStatus() == 5)) { %>
                <div class="cp-card" style="border-color: #ff8800;">
                    <div class="cp-section-title" style="color: #ff8800;">
                        <i class="fa fa-undo"></i> 退款信息
                    </div>
                    <div class="cp-info-row">
                        <span class="cp-info-label">退款理由</span>
                        <span class="cp-info-value"><%= order.getRefundReason() == null ? "-" : EscapeUtil.html(order.getRefundReason()) %></span>
                    </div>
                    <% if (order.getRefundAuditTime() != null) { %>
                        <div class="cp-info-row">
                            <span class="cp-info-label">审核时间</span>
                            <span class="cp-info-value"><%= order.getRefundAuditTime().toString().replace('T', ' ') %></span>
                        </div>
                    <% } %>
                    <% if (order.getRefundAuditResult() != null && !order.getRefundAuditResult().isEmpty()) { %>
                        <div class="cp-info-row">
                            <span class="cp-info-label">审核结果</span>
                            <span class="cp-info-value"><%= EscapeUtil.html(order.getRefundAuditResult()) %></span>
                        </div>
                    <% } %>
                    <div class="cp-info-row">
                        <span class="cp-info-label">当前状态</span>
                        <span class="cp-info-value">
                            <% if (order.getStatus() == 4) { %>
                                <span class="cp-badge cp-badge-warning">待管理员审核</span>
                            <% } else { %>
                                <span class="cp-badge cp-badge-success">已退款</span>
                            <% } %>
                        </span>
                    </div>
                </div>
            <% } %>
        </div>

        <!-- 右侧：金额 + 操作 -->
        <div class="cp-action-panel">
            <div class="cp-action-card">
                <div style="text-align: center; color: var(--cp-text-dim); font-size: 13px; text-transform: uppercase; letter-spacing: 1px;">订单金额</div>
                <div class="cp-price-big"><small>¥</small><%= order.getFinalPrice() == null ? "0.00" : order.getFinalPrice().toPlainString() %></div>

                <%-- 押金/尾款明细 --%>
                <% if (order.getDepositAmount() != null && order.getDepositAmount().compareTo(java.math.BigDecimal.ZERO) > 0) { %>
                <div style="background: rgba(0, 240, 255, 0.05); border: 1px dashed rgba(0, 240, 255, 0.2); border-radius: 2px; padding: 8px 10px; margin: 10px 0; font-size: 12px; color: rgba(255, 238, 0, 0.7); line-height: 1.7;">
                    <div style="display: flex; justify-content: space-between;">
                        <span>已抵用押金</span>
                        <span style="color: #00F0FF;">-¥<%= order.getDepositAmount().toPlainString() %></span>
                    </div>
                    <div style="display: flex; justify-content: space-between; margin-top: 2px;">
                        <span>待付尾款</span>
                        <span style="color: #FFEE00; font-weight: 600;">¥<%= order.getFinalPayAmount() == null ? "0.00" : order.getFinalPayAmount().toPlainString() %></span>
                    </div>
                    <% if (order.getFinalPayMethod() != null && !order.getFinalPayMethod().isEmpty()) { %>
                    <div style="display: flex; justify-content: space-between; margin-top: 4px; padding-top: 4px; border-top: 1px solid rgba(0, 240, 255, 0.1);">
                        <span>已付方式</span>
                        <span><%= "balance".equals(order.getFinalPayMethod()) ? "余额" : ("alipay".equals(order.getFinalPayMethod()) ? "支付宝" : ("wechat".equals(order.getFinalPayMethod()) ? "微信" : order.getFinalPayMethod())) %></span>
                    </div>
                    <% } %>
                </div>
                <% } %>

                <span class="cp-badge <%= order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("warning") ? "cp-badge-warning" : order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("info") ? "cp-badge-info" : order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("primary") ? "cp-badge-primary" : order.getStatusBadgeClass() != null && order.getStatusBadgeClass().contains("success") ? "cp-badge-success" : "cp-badge-gray" %>" style="display: block; text-align: center; margin-bottom: 16px;"><%= order.getStatusText() %></span>

                <% if (isBuyer) { %>
                    <% if (order.getStatus() != null && order.getStatus() == 0) { %>
                        <button class="cp-btn cp-action-btn" onclick="payOrder()">
                            <i class="fa fa-credit-card"></i> 立即付款
                        </button>
                        <button class="cp-btn cp-btn-outline cp-action-btn" onclick="cancelOrder()">
                            <i class="fa fa-times"></i> 取消订单
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 1) { %>
                        <button class="cp-btn cp-action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 等待卖家发货
                        </button>
                        <button class="cp-btn cp-btn-outline cp-action-btn" onclick="openRefundModal()">
                            <i class="fa fa-undo"></i> 申请退款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 2) { %>
                        <button class="cp-btn cp-action-btn" onclick="confirmReceive()">
                            <i class="fa fa-check"></i> 确认收货
                        </button>
                        <button class="cp-btn cp-btn-outline cp-action-btn" onclick="openRefundModal()">
                            <i class="fa fa-undo"></i> 申请退款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 4) { %>
                        <button class="cp-btn cp-action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 退款审核中
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 5) { %>
                        <button class="cp-btn cp-action-btn" disabled>
                            <i class="fa fa-check-circle"></i> 已退款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 3) { %>
                        <button class="cp-btn cp-action-btn" onclick="openCreditModal()">
                            <i class="fa fa-star"></i> 评价卖家
                        </button>
                    <% } %>
                <% } else { %>
                    <% if (order.getStatus() != null && order.getStatus() == 1) { %>
                        <button class="cp-btn cp-action-btn" onclick="openDeliverModal()">
                            <i class="fa fa-truck"></i> 我要发货
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 2) { %>
                        <button class="cp-btn cp-action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 等待买家确认收货
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 0) { %>
                        <button class="cp-btn cp-action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 等待买家付款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 3) { %>
                        <button class="cp-btn cp-action-btn" onclick="openCreditModal()">
                            <i class="fa fa-star"></i> 评价买家
                        </button>
                    <% } %>
                <% } %>

                <%-- 投诉按钮：status 3/4/5/6 可见（不再有其他途径解决时） --%>
                <% int st = order.getStatus() == null ? 0 : order.getStatus(); %>
                <% if (st == 3 || st == 4 || st == 5 || st == 6) { %>
                    <button class="cp-btn cp-btn-danger cp-action-btn" onclick="openComplaintModal()">
                        <i class="fa fa-flag"></i> 投诉
                    </button>
                <% } %>

                <a href="<%=ctx%>/order?action=list" class="cp-btn cp-btn-outline cp-action-btn">返回列表</a>
            </div>
        </div>

    </div>

    <!-- 发货弹窗（卖家） -->
    <div id="deliverModal" class="cp-modal-overlay">
        <div class="cp-modal">
            <div class="cp-modal-title">填写发货信息</div>
            <form id="deliverForm">
                <div class="cp-form-group">
                    <label class="cp-form-label">物流公司 *</label>
                    <input type="text" name="logisticsCompany" class="cp-form-input" placeholder="如：顺丰速运" required>
                </div>
                <div class="cp-form-group">
                    <label class="cp-form-label">物流单号 *</label>
                    <input type="text" name="trackingNumber" class="cp-form-input" placeholder="请输入运单号" required>
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="cp-btn cp-btn-outline" style="flex: 1;" onclick="closeDeliverModal()">取消</button>
                    <button type="submit" class="cp-btn" style="flex: 1;">确认发货</button>
                </div>
            </form>
        </div>
    </div>

    <!-- 申请退款弹窗（买家） -->
    <div id="refundModal" class="cp-modal-overlay">
        <div class="cp-modal">
            <div class="cp-modal-title" style="color: #ff8800;">
                <i class="fa fa-undo"></i> 申请退款
            </div>
            <p style="font-size: 13px; color: var(--cp-text-dim); margin-bottom: 16px; line-height: 1.6;">
                提交后，管理员将在 1-3 个工作日内审核。审核通过后资金将原路返回，请耐心等待。
            </p>
            <form id="refundForm">
                <div class="cp-form-group">
                    <label class="cp-form-label">退款理由 *</label>
                    <textarea name="refundReason" class="cp-form-input" style="min-height: 100px;"
                              maxlength="500" placeholder="请详细说明退款原因（不超过 500 字）" required></textarea>
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="cp-btn cp-btn-outline" style="flex: 1;" onclick="closeRefundModal()">取消</button>
                    <button type="submit" class="cp-btn" style="flex: 1; border-color: #ff8800; color: #ff8800;">提交申请</button>
                </div>
            </form>
        </div>
    </div>

    <!-- 评价弹窗（双向：买家评卖家 / 卖家评买家） -->
    <div id="creditModal" class="cp-modal-overlay" style="z-index: 1001;">
        <div class="cp-modal" style="max-width: 480px;">
            <div class="cp-modal-title" style="color: var(--cp-yellow);">
                <i class="fa fa-star"></i> 评价
            </div>
            <p style="font-size: 13px; color: var(--cp-text-dim); margin-bottom: 20px; line-height: 1.6;">
                请为本次交易打分。评价提交后不可修改，会影响对方信用分。
            </p>
            <form id="creditForm">
                <div class="cp-form-group" style="text-align: center; padding: 10px 0;">
                    <label class="cp-form-label" style="text-align: center; margin-bottom: 12px;">评分（1-5 星）*</label>
                    <div id="starPicker" style="display: inline-flex; gap: 8px; font-size: 32px; cursor: pointer;">
                        <i class="fa fa-star-o" data-score="1" style="color: #333; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="2" style="color: #333; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="3" style="color: #333; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="4" style="color: #333; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="5" style="color: #333; transition: color 0.15s;"></i>
                    </div>
                    <input type="hidden" name="score" id="scoreInput" required>
                    <div id="scoreText" style="margin-top: 8px; font-size: 12px; color: #444; height: 16px;">
                        点击星星选择评分
                    </div>
                </div>
                <div class="cp-form-group">
                    <label class="cp-form-label">评价内容（选填）</label>
                    <textarea name="content" id="content" class="cp-form-input" style="min-height: 80px;"
                              maxlength="500" placeholder="说点什么吧，比如商品描述是否准确、卖家服务态度等"></textarea>
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="cp-btn cp-btn-outline" style="flex: 1;" onclick="closeCreditModal()">取消</button>
                    <button type="submit" class="cp-btn" style="flex: 1; border-color: var(--cp-yellow); color: var(--cp-yellow);" id="creditSubmitBtn">
                        <i class="fa fa-paper-plane"></i> 提交评价
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- 投诉弹窗 -->
    <div id="complaintModal" class="cp-modal-overlay" style="z-index: 1001;">
        <div class="cp-modal" style="max-width: 480px;">
            <div class="cp-modal-title" style="color: var(--cp-danger);">
                <i class="fa fa-flag"></i> 投诉
            </div>
            <p style="font-size: 13px; color: var(--cp-text-dim); margin-bottom: 16px; line-height: 1.6;">
                投诉将由管理员在 1-3 个工作日内审核处理。请详细说明情况，避免情绪化表达。
            </p>
            <form id="complaintForm">
                <div class="cp-form-group">
                    <label class="cp-form-label"><span style="color: var(--cp-danger);">*</span> 投诉原因</label>
                    <textarea name="reason" class="cp-form-input" style="min-height: 100px;"
                              maxlength="500" placeholder="请详细说明投诉原因（不超过 500 字）" required></textarea>
                </div>
                <div class="cp-form-group">
                    <label class="cp-form-label">证据图片 URL（选填）</label>
                    <input type="text" name="evidence" class="cp-form-input" maxlength="500"
                           placeholder="如：聊天截图、商品问题照片等的 URL">
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="cp-btn cp-btn-outline" style="flex: 1;" onclick="closeComplaintModal()">取消</button>
                    <button type="submit" class="cp-btn cp-btn-danger" style="flex: 1;" id="complaintSubmitBtn">
                        <i class="fa fa-paper-plane"></i> 提交投诉
                    </button>
                </div>
            </form>
        </div>
    </div>

    <% } %>
</div>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
const orderNo = '<%= order != null ? order.getOrderNo() : "" %>';
const ctx = '<%= ctx %>';

function payOrder() {
    const finalPay = '<%= order != null && order.getFinalPayAmount() != null ? order.getFinalPayAmount().toPlainString() : "0.00" %>';
    const deposit = '<%= order != null && order.getDepositAmount() != null ? order.getDepositAmount().toPlainString() : "0.00" %>';
    const total = '<%= order != null && order.getFinalPrice() != null ? order.getFinalPrice().toPlainString() : "0.00" %>';

    let info = '订单总价 ¥' + total;
    if (parseFloat(deposit) > 0) {
        info += '（已抵用押金 ¥' + deposit + '，待付尾款 ¥' + finalPay + '）';
    }
    info += '\n请选择支付方式：';

    // 弹出支付方式选择
    const choice = prompt(
        info + '\n\n' +
        '1 - 账户余额（即时到账）\n' +
        '2 - 支付宝（模拟）\n' +
        '3 - 微信支付（模拟）\n\n' +
        '请输入 1 / 2 / 3：',
        '1'
    );
    if (choice == null) return;

    let method = 'balance';
    if (choice === '2') method = 'alipay';
    else if (choice === '3') method = 'wechat';
    else if (choice !== '1') {
        toast('无效选择', 'error');
        return;
    }

    axios.post(ctx + '/order?action=pay', new URLSearchParams({ orderNo: orderNo, method: method }))
        .then(r => {
            const data = r.data;
            if (data.success) {
                if (data.redirect) {
                    // 模拟支付：跳到模拟收银台
                    window.location.href = data.redirect;
                } else {
                    // 余额支付：直接成功
                    toast(data.message || '付款成功', 'success');
                    setTimeout(() => location.reload(), 800);
                }
            } else {
                toast(data.message, 'error');
            }
        })
        .catch(() => toast('网络错误', 'error'));
}

function cancelOrder() {
    if (!confirm('确认取消此订单？')) return;
    axios.post(ctx + '/order?action=cancel', new URLSearchParams({ orderNo: orderNo }))
        .then(r => {
            if (r.data.success) {
                toast('订单已取消', 'success');
                setTimeout(() => location.reload(), 800);
            } else {
                toast(r.data.message, 'error');
            }
        })
        .catch(() => toast('网络错误', 'error'));
}

function confirmReceive() {
    if (!confirm('确认已收到货？')) return;
    axios.post(ctx + '/order?action=confirm-receive', new URLSearchParams({ orderNo: orderNo }))
        .then(r => {
            if (r.data.success) {
                toast('已确认收货', 'success');
                setTimeout(() => location.reload(), 800);
            } else {
                toast(r.data.message, 'error');
            }
        })
        .catch(() => toast('网络错误', 'error'));
}

function openDeliverModal() {
    document.getElementById('deliverModal').classList.add('show');
}
function closeDeliverModal() {
    document.getElementById('deliverModal').classList.remove('show');
}

// 申请退款
function openRefundModal() {
    if (!confirm('确定要申请退款吗？\n请确认已与卖家沟通无果。\n提交后请耐心等待管理员审核。')) return;
    document.getElementById('refundModal').classList.add('show');
}
function closeRefundModal() {
    document.getElementById('refundModal').classList.remove('show');
}

// 评价
let creditScore = 0;
function openCreditModal() {
    // 检查是否已经评过
    axios.get(ctx + '/credit', {
        params: { action: 'for-order', orderNo: orderNo }
    }).then(r => {
        if (r.data.success) {
            if (r.data.evaluated) {
                toast('此订单你已经评价过（' + r.data.score + ' 星）', 'info');
                return;
            }
            if (!r.data.canEvaluate) {
                toast('此订单还未到可评价状态', 'error');
                return;
            }
            // 打开弹窗 + 重置
            creditScore = 0;
            document.getElementById('scoreInput').value = '';
            document.getElementById('content').value = '';
            updateStars(0);
            document.getElementById('creditModal').classList.add('show');
        } else {
            toast(r.data.message || '检查失败', 'error');
        }
    }).catch(() => toast('网络错误', 'error'));
}
function closeCreditModal() {
    document.getElementById('creditModal').classList.remove('show');
}
const scoreLabels = { 1: '1 星 · 极差', 2: '2 星 · 差评', 3: '3 星 · 中评', 4: '4 星 · 好评', 5: '5 星 · 非常满意' };
function updateStars(n) {
    document.querySelectorAll('#starPicker i').forEach(star => {
        const s = parseInt(star.dataset.score);
        if (s <= n) {
            star.className = 'fa fa-star';
            star.style.color = '#FFEE00';
        } else {
            star.className = 'fa fa-star-o';
            star.style.color = '#333';
        }
    });
    document.getElementById('scoreText').textContent = n > 0 ? scoreLabels[n] : '点击星星选择评分';
    document.getElementById('scoreText').style.color = n > 0 ? '#FFEE00' : '#444';
    document.getElementById('scoreInput').value = n;
}
document.querySelectorAll('#starPicker i').forEach(star => {
    star.addEventListener('click', function() {
        creditScore = parseInt(this.dataset.score);
        updateStars(creditScore);
    });
    star.addEventListener('mouseenter', function() {
        const n = parseInt(this.dataset.score);
        document.querySelectorAll('#starPicker i').forEach(s => {
            const sn = parseInt(s.dataset.score);
            s.style.color = sn <= n ? '#FFEE00' : '#333';
        });
    });
    star.addEventListener('mouseleave', function() {
        updateStars(creditScore);
    });
});

document.getElementById('deliverForm')?.addEventListener('submit', function(e) {
    e.preventDefault();
    const form = new FormData(e.target);
    const params = new URLSearchParams();
    params.append('orderNo', orderNo);
    params.append('logisticsCompany', form.get('logisticsCompany'));
    params.append('trackingNumber', form.get('trackingNumber'));

    axios.post(ctx + '/order?action=deliver', params)
        .then(r => {
            if (r.data.success) {
                toast('发货成功', 'success');
                closeDeliverModal();
                setTimeout(() => location.reload(), 800);
            } else {
                toast(r.data.message, 'error');
            }
        })
        .catch(() => toast('网络错误', 'error'));
});

document.getElementById('refundForm')?.addEventListener('submit', function(e) {
    e.preventDefault();
    const form = new FormData(e.target);
    const reason = (form.get('refundReason') || '').trim();
    if (!reason) { toast('请填写退款理由', 'error'); return; }
    if (reason.length > 500) { toast('退款理由不超过 500 字', 'error'); return; }

    axios.post(ctx + '/order?action=apply-refund', null, {
        params: { orderNo: orderNo, refundReason: reason }
    }).then(r => {
        if (r.data.success) {
            toast(r.data.message || '申请已提交', 'success');
            closeRefundModal();
            setTimeout(() => location.reload(), 800);
        } else {
            toast(r.data.message, 'error');
        }
    }).catch(() => toast('网络错误', 'error'));
});

document.getElementById('creditForm')?.addEventListener('submit', function(e) {
    e.preventDefault();
    const form = new FormData(e.target);
    const score = parseInt(form.get('score') || '0');
    const content = (form.get('content') || '').trim();
    if (!score || score < 1 || score > 5) {
        toast('请选择 1-5 星评分', 'error');
        return;
    }
    if (content.length > 500) {
        toast('评价内容不超过 500 字', 'error');
        return;
    }
    const submitBtn = document.getElementById('creditSubmitBtn');
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> 提交中...';

    axios.post(ctx + '/credit?action=submit', null, {
        params: { orderNo: orderNo, score: score, content: content }
    }).then(r => {
        if (r.data.success) {
            toast(r.data.message || '评价成功', 'success');
            closeCreditModal();
            setTimeout(() => location.reload(), 800);
        } else {
            toast(r.data.message, 'error');
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fa fa-paper-plane"></i> 提交评价';
        }
    }).catch(() => {
        toast('网络错误', 'error');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<i class="fa fa-paper-plane"></i> 提交评价';
    });
});

// 投诉
function openComplaintModal() {
    if (!confirm('确定要发起投诉吗？\n请确认已与对方沟通无果。\n提交后管理员将介入处理。')) return;
    // 检查是否已投诉
    axios.get(ctx + '/complaint', {
        params: { action: 'for-order', orderNo: orderNo }
    }).then(r => {
        if (r.data.success) {
            if (r.data.complained) {
                toast('此订单你已经投诉过，请去「我的投诉」查看', 'info');
                return;
            }
            // 打开弹窗
            document.getElementById('complaintForm').reset();
            document.getElementById('complaintModal').classList.add('show');
        } else {
            toast(r.data.message || '检查失败', 'error');
        }
    }).catch(() => toast('网络错误', 'error'));
}
function closeComplaintModal() {
    document.getElementById('complaintModal').classList.remove('show');
}
document.getElementById('complaintForm')?.addEventListener('submit', function(e) {
    e.preventDefault();
    const form = new FormData(e.target);
    const reason = (form.get('reason') || '').trim();
    const evidence = (form.get('evidence') || '').trim();
    if (!reason) { toast('请填写投诉原因', 'error'); return; }
    if (reason.length > 500) { toast('投诉原因不超过 500 字', 'error'); return; }
    if (evidence.length > 500) { toast('证据 URL 不超过 500 字', 'error'); return; }

    const submitBtn = document.getElementById('complaintSubmitBtn');
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> 提交中...';

    axios.post(ctx + '/complaint?action=submit', null, {
        params: { orderNo: orderNo, reason: reason, evidence: evidence }
    }).then(r => {
        if (r.data.success) {
            toast(r.data.message || '投诉已提交', 'success');
            closeComplaintModal();
            setTimeout(() => location.reload(), 800);
        } else {
            toast(r.data.message, 'error');
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fa fa-paper-plane"></i> 提交投诉';
        }
    }).catch(() => {
        toast('网络错误', 'error');
        submitBtn.disabled = false;
        submitBtn.innerHTML = '<i class="fa fa-paper-plane"></i> 提交投诉';
    });
});
</script>
</body>
</html>