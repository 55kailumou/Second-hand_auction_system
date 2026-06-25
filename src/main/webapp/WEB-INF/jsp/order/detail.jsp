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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: var(--color-bg); }
        .header { background: #fff; padding: 14px 0;
                  box-shadow: var(--shadow-sm); position: sticky; top: 0; z-index: 100; }
        .header-inner { max-width: 1200px; margin: 0 auto; padding: 0 24px;
                        display: flex; align-items: center; justify-content: space-between; }
        .logo { font-size: 20px; font-weight: 700; color: var(--color-primary);
                display: flex; align-items: center; gap: 8px; }
        .nav { display: flex; gap: 24px; }
        .nav a { color: var(--color-text); font-size: 14px; }
        .nav a:hover, .nav a.active { color: var(--color-primary); }
        .user-info { display: flex; align-items: center; gap: 12px; font-size: 13px; }

        .detail-layout { display: grid; grid-template-columns: 1fr 360px; gap: 20px; margin-top: 20px; }
        @media (max-width: 900px) { .detail-layout { grid-template-columns: 1fr; } }

        .card { background: #fff; border-radius: var(--radius-lg); box-shadow: var(--shadow-sm);
                padding: 24px; margin-bottom: 16px; }

        .status-bar { display: flex; align-items: center; justify-content: space-between;
                      padding: 20px 24px; background: linear-gradient(135deg, #fff3eb 0%, #ffe5d0 100%);
                      border-radius: var(--radius-lg); margin-bottom: 16px; }
        .status-text { font-size: 20px; font-weight: 700; color: var(--color-primary); }
        .status-tip { font-size: 13px; color: var(--color-text); margin-top: 4px; }
        .status-icon { font-size: 56px; color: var(--color-primary); }

        .timeline { display: flex; gap: 0; margin-top: 16px; }
        .timeline-step { flex: 1; text-align: center; position: relative; }
        .timeline-step .dot { width: 28px; height: 28px; border-radius: 50%;
                              background: #e5e7eb; color: #9ca3af; margin: 0 auto 8px;
                              display: grid; place-items: center; font-size: 14px; }
        .timeline-step.done .dot { background: var(--color-primary); color: #fff; }
        .timeline-step .label { font-size: 12px; color: var(--color-muted); }
        .timeline-step.done .label { color: var(--color-primary); font-weight: 500; }
        .timeline-step:not(:last-child)::after { content: ''; position: absolute;
                      top: 14px; left: calc(50% + 14px); right: calc(-50% + 14px);
                      height: 2px; background: #e5e7eb; }
        .timeline-step.done:not(:last-child)::after { background: var(--color-primary); }

        .section-title { font-size: 15px; font-weight: 600; margin-bottom: 12px;
                         display: flex; align-items: center; gap: 8px; }
        .section-title::before { content: ''; display: inline-block; width: 4px; height: 16px;
                                  background: var(--color-primary); border-radius: 2px; }

        .info-row { display: flex; padding: 8px 0; font-size: 14px; }
        .info-label { color: var(--color-muted); min-width: 100px; }
        .info-value { color: var(--color-text); flex: 1; word-break: break-all; }
        .info-value.mono { font-family: 'Courier New', monospace; }

        .item-mini { display: flex; gap: 16px; padding: 12px; background: var(--color-bg);
                      border-radius: var(--radius); }
        .item-mini-cover { width: 80px; height: 80px; border-radius: var(--radius);
                           background: #e5e7eb center/cover no-repeat; flex-shrink: 0;
                           display: grid; place-items: center; color: #9ca3af; font-size: 24px; }
        .item-mini-info { flex: 1; min-width: 0; }
        .item-mini-title { font-size: 14px; font-weight: 600; color: var(--color-text);
                           margin-bottom: 4px; line-height: 1.4;
                           overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .item-mini-price { font-size: 16px; font-weight: 700; color: var(--color-primary); }

        .address-card { background: var(--color-bg); padding: 16px; border-radius: var(--radius);
                        border-left: 3px solid var(--color-primary); }
        .address-name { font-size: 16px; font-weight: 600; margin-bottom: 4px; }
        .address-phone { color: var(--color-muted); font-size: 13px; margin-bottom: 6px; }
        .address-detail { color: var(--color-text); font-size: 14px; line-height: 1.5; }

        .action-panel { position: sticky; top: 80px; }
        .action-card { background: #fff; border-radius: var(--radius-lg); box-shadow: var(--shadow-sm);
                       padding: 24px; margin-bottom: 16px; }
        .price-big { font-size: 32px; font-weight: 700; color: var(--color-primary);
                     text-align: center; margin: 16px 0; }
        .price-big small { font-size: 14px; font-weight: 400; margin-right: 4px; }
        .action-btn { width: 100%; margin-bottom: 8px; }

        .form-group { margin-bottom: 12px; }
        .form-label { display: block; font-size: 13px; color: var(--color-muted);
                      margin-bottom: 4px; }
        .form-input { width: 100%; padding: 8px 12px; border: 1px solid var(--color-border);
                      border-radius: 6px; font-size: 14px; }

        .modal { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000;
                 display: none; align-items: center; justify-content: center; }
        .modal.show { display: flex; }
        .modal-content { background: #fff; border-radius: var(--radius-lg);
                         padding: 32px; width: 90%; max-width: 480px; }
        .modal-title { font-size: 18px; font-weight: 600; margin-bottom: 20px; }

        .badge { display: inline-block; padding: 3px 10px; border-radius: 12px;
                 font-size: 12px; font-weight: 500; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-info    { background: #dbeafe; color: #1e40af; }
        .badge-primary { background: #fff3eb; color: var(--color-primary); }
        .badge-success { background: #d1fae5; color: #047857; }
        .badge-gray    { background: #f3f4f6; color: #6b7280; }
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
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list" class="active">我的订单</a>
        </nav>
        <div class="user-info">
            <span>欢迎，</span>
            <span style="color: var(--color-text); font-weight: 500;"><%= currentUser.getUsername() %></span>
            <a href="<%=ctx%>/user?action=logout" style="color: var(--color-primary);">退出</a>
        </div>
    </div>
</header>

<div class="container" style="max-width: 1200px; margin: 0 auto; padding: 0 24px 60px;">

    <% if (error != null) { %>
        <div class="card" style="background: #fee2e2; color: #b91c1c;">
            <i class="fa fa-exclamation-circle"></i> <%= error %>
        </div>
    <% } %>

    <% if (order == null) { %>
        <div class="card" style="text-align: center; padding: 60px;">
            <i class="fa fa-exclamation-triangle" style="font-size: 48px; color: var(--color-muted);"></i>
            <h3 style="margin: 16px 0 8px;">订单不存在或已被删除</h3>
            <a href="<%=ctx%>/order?action=list" class="btn btn-primary">返回订单列表</a>
        </div>
    <% } else { %>

    <!-- 状态栏 -->
    <div class="status-bar">
        <div>
            <div class="status-text">
                <i class="fa <%= order.getStatus() != null && order.getStatus() == 0 ? "fa-clock-o" :
                                  order.getStatus() != null && order.getStatus() == 1 ? "fa-credit-card" :
                                  order.getStatus() != null && order.getStatus() == 2 ? "fa-truck" :
                                  order.getStatus() != null && order.getStatus() == 3 ? "fa-check-circle" :
                                  "fa-times-circle" %>"></i>
                <%= order.getStatusText() %>
            </div>
            <div class="status-tip">
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
        <i class="fa <%= order.getStatus() != null && order.getStatus() == 3 ? "fa-check-circle" : "fa-clock-o" %> status-icon"></i>
    </div>

    <div class="detail-layout">

        <!-- 左侧：订单详情 -->
        <div>
            <!-- 订单基本信息 -->
            <div class="card">
                <div class="section-title">订单信息</div>
                <div class="info-row"><span class="info-label">订单号</span><span class="info-value mono"><%= EscapeUtil.html(order.getOrderNo()) %></span></div>
                <div class="info-row"><span class="info-label">下单时间</span><span class="info-value"><%= order.getCreateTime() == null ? "-" : order.getCreateTime().toString().replace('T', ' ') %></span></div>
                <% if (order.getPayTime() != null) { %>
                    <div class="info-row"><span class="info-label">付款时间</span><span class="info-value"><%= order.getPayTime().toString().replace('T', ' ') %></span></div>
                <% } %>
                <% if (order.getDeliverTime() != null) { %>
                    <div class="info-row"><span class="info-label">发货时间</span><span class="info-value"><%= order.getDeliverTime().toString().replace('T', ' ') %></span></div>
                <% } %>
                <% if (order.getReceiveTime() != null) { %>
                    <div class="info-row"><span class="info-label">收货时间</span><span class="info-value"><%= order.getReceiveTime().toString().replace('T', ' ') %></span></div>
                <% } %>
                <% if (order.getLogisticsCompany() != null && !order.getLogisticsCompany().isEmpty()) { %>
                    <div class="info-row"><span class="info-label">物流公司</span><span class="info-value"><%= order.getLogisticsCompany() == null ? "-" : EscapeUtil.html(order.getLogisticsCompany()) %></span></div>
                <% } %>
                <% if (order.getTrackingNumber() != null && !order.getTrackingNumber().isEmpty()) { %>
                    <div class="info-row"><span class="info-label">物流单号</span><span class="info-value mono"><%= order.getTrackingNumber() == null ? "-" : EscapeUtil.html(order.getTrackingNumber()) %></span></div>
                <% } %>
                <div class="info-row"><span class="info-label">买家 ID</span><span class="info-value"><%= order.getBuyerId() %></span></div>
                <div class="info-row"><span class="info-label">卖家 ID</span><span class="info-value"><%= order.getSellerId() %></span></div>
            </div>

            <!-- 拍品信息 -->
            <div class="card">
                <div class="section-title">拍品信息</div>
                <div class="item-mini">
                    <div class="item-mini-cover" style="<%= order.getCoverImage() != null && !order.getCoverImage().isEmpty() ? "background-image: url('" + order.getCoverImage() + "');" : "" %>">
                        <% if (order.getCoverImage() == null || order.getCoverImage().isEmpty()) { %>
                            <i class="fa fa-image"></i>
                        <% } %>
                    </div>
                    <div class="item-mini-info">
                        <div class="item-mini-title"><%= EscapeUtil.html(order.getItemTitle()) %></div>
                        <div style="font-size: 12px; color: var(--color-muted); margin-bottom: 6px;">拍品 ID：<%= order.getItemId() %></div>
                        <div class="item-mini-price">成交价 ¥<%= order.getFinalPrice() == null ? "0.00" : order.getFinalPrice().toPlainString() %></div>
                    </div>
                </div>
                <% if (item != null) { %>
                    <div style="margin-top: 12px; text-align: right;">
                        <a href="<%=ctx%>/item?action=detail&id=<%= item.getId() %>" class="btn btn-ghost btn-sm">查看拍品 →</a>
                    </div>
                <% } %>
            </div>

            <!-- 收货地址 -->
            <div class="card">
                <div class="section-title">收货地址</div>
                <% if (address != null) { %>
                    <div class="address-card">
                        <div class="address-name">
                            <%= address.getReceiverName() %>
                            <span class="address-phone" style="font-weight: 400; margin-left: 12px;"><%= address.getReceiverPhone() %></span>
                        </div>
                        <div class="address-detail">
                            <%= address.getFullAddress() %>
                        </div>
                    </div>
                <% } else { %>
                    <div style="color: var(--color-muted); padding: 16px;">地址信息已被删除</div>
                <% } %>
            </div>

            <!-- 状态时间线 -->
            <div class="card">
                <div class="section-title">订单进度</div>
                <div class="timeline">
                    <div class="timeline-step done">
                        <div class="dot"><i class="fa fa-check"></i></div>
                        <div class="label">下单</div>
                    </div>
                    <div class="timeline-step <%= order.getStatus() != null && order.getStatus() >= 1 ? "done" : "" %>">
                        <div class="dot"><i class="fa fa-credit-card"></i></div>
                        <div class="label">付款</div>
                    </div>
                    <div class="timeline-step <%= order.getStatus() != null && order.getStatus() >= 2 ? "done" : "" %>">
                        <div class="dot"><i class="fa fa-truck"></i></div>
                        <div class="label">发货</div>
                    </div>
                    <div class="timeline-step <%= order.getStatus() != null && order.getStatus() >= 3 ? "done" : "" %>">
                        <div class="dot"><i class="fa fa-check-circle"></i></div>
                        <div class="label">收货</div>
                    </div>
                </div>
            </div>

            <!-- 退款信息（仅 status 4 / 5 时显示） -->
            <% if (order.getStatus() != null && (order.getStatus() == 4 || order.getStatus() == 5)) { %>
                <div class="card" style="border-left: 4px solid #f59e0b;">
                    <div class="section-title" style="color: #b45309;">
                        <i class="fa fa-undo"></i> 退款信息
                    </div>
                    <div class="info-row">
                        <span class="info-label">退款理由</span>
                        <span class="info-value"><%= order.getRefundReason() == null ? "-" : EscapeUtil.html(order.getRefundReason()) %></span>
                    </div>
                    <% if (order.getRefundAuditTime() != null) { %>
                        <div class="info-row">
                            <span class="info-label">审核时间</span>
                            <span class="info-value"><%= order.getRefundAuditTime().toString().replace('T', ' ') %></span>
                        </div>
                    <% } %>
                    <% if (order.getRefundAuditResult() != null && !order.getRefundAuditResult().isEmpty()) { %>
                        <div class="info-row">
                            <span class="info-label">审核结果</span>
                            <span class="info-value"><%= EscapeUtil.html(order.getRefundAuditResult()) %></span>
                        </div>
                    <% } %>
                    <div class="info-row">
                        <span class="info-label">当前状态</span>
                        <span class="info-value">
                            <% if (order.getStatus() == 4) { %>
                                <span class="badge badge-warning">待管理员审核</span>
                            <% } else { %>
                                <span class="badge" style="background: #d1fae5; color: #047857;">已退款</span>
                            <% } %>
                        </span>
                    </div>
                </div>
            <% } %>
        </div>

        <!-- 右侧：金额 + 操作 -->
        <div class="action-panel">
            <div class="action-card">
                <div style="text-align: center; color: var(--color-muted); font-size: 13px;">订单金额</div>
                <div class="price-big"><small>¥</small><%= order.getFinalPrice() == null ? "0.00" : order.getFinalPrice().toPlainString() %></div>
                <span class="badge <%= order.getStatusBadgeClass() %>" style="display: block; text-align: center; margin-bottom: 16px;"><%= order.getStatusText() %></span>

                <% if (isBuyer) { %>
                    <% if (order.getStatus() != null && order.getStatus() == 0) { %>
                        <button class="btn btn-primary action-btn" onclick="payOrder()">
                            <i class="fa fa-credit-card"></i> 立即付款
                        </button>
                        <button class="btn btn-ghost action-btn" onclick="cancelOrder()">
                            <i class="fa fa-times"></i> 取消订单
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 1) { %>
                        <button class="btn btn-secondary action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 等待卖家发货
                        </button>
                        <button class="btn btn-ghost action-btn" onclick="openRefundModal()">
                            <i class="fa fa-undo"></i> 申请退款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 2) { %>
                        <button class="btn btn-primary action-btn" onclick="confirmReceive()">
                            <i class="fa fa-check"></i> 确认收货
                        </button>
                        <button class="btn btn-ghost action-btn" onclick="openRefundModal()">
                            <i class="fa fa-undo"></i> 申请退款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 4) { %>
                        <button class="btn btn-secondary action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 退款审核中
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 5) { %>
                        <button class="btn btn-secondary action-btn" disabled>
                            <i class="fa fa-check-circle"></i> 已退款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 3) { %>
                        <button class="btn btn-primary action-btn" onclick="openCreditModal()">
                            <i class="fa fa-star"></i> 评价卖家
                        </button>
                    <% } %>
                <% } else { %>
                    <% if (order.getStatus() != null && order.getStatus() == 1) { %>
                        <button class="btn btn-primary action-btn" onclick="openDeliverModal()">
                            <i class="fa fa-truck"></i> 我要发货
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 2) { %>
                        <button class="btn btn-secondary action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 等待买家确认收货
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 0) { %>
                        <button class="btn btn-secondary action-btn" disabled>
                            <i class="fa fa-clock-o"></i> 等待买家付款
                        </button>
                    <% } else if (order.getStatus() != null && order.getStatus() == 3) { %>
                        <button class="btn btn-primary action-btn" onclick="openCreditModal()">
                            <i class="fa fa-star"></i> 评价买家
                        </button>
                    <% } %>
                <% } %>

                <%-- 投诉按钮：status 3/4/5/6 可见（不再有其他途径解决时） --%>
                <% int st = order.getStatus() == null ? 0 : order.getStatus(); %>
                <% if (st == 3 || st == 4 || st == 5 || st == 6) { %>
                    <button class="btn btn-ghost action-btn" onclick="openComplaintModal()" style="color: #b91c1c;">
                        <i class="fa fa-flag"></i> 投诉
                    </button>
                <% } %>
                    <% } %>
                <% } %>

                <a href="<%=ctx%>/order?action=list" class="btn btn-ghost action-btn">返回列表</a>
            </div>
        </div>

    </div>

    <!-- 发货弹窗（卖家） -->
    <div id="deliverModal" class="modal">
        <div class="modal-content">
            <div class="modal-title">填写发货信息</div>
            <form id="deliverForm">
                <div class="form-group">
                    <label class="form-label">物流公司 *</label>
                    <input type="text" name="logisticsCompany" class="form-input" placeholder="如：顺丰速运" required>
                </div>
                <div class="form-group">
                    <label class="form-label">物流单号 *</label>
                    <input type="text" name="trackingNumber" class="form-input" placeholder="请输入运单号" required>
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="btn btn-ghost" style="flex: 1;" onclick="closeDeliverModal()">取消</button>
                    <button type="submit" class="btn btn-primary" style="flex: 1;">确认发货</button>
                </div>
            </form>
        </div>
    </div>

    <!-- 申请退款弹窗（买家） -->
    <div id="refundModal" class="modal">
        <div class="modal-content">
            <div class="modal-title" style="color: #b45309;">
                <i class="fa fa-undo"></i> 申请退款
            </div>
            <p style="font-size: 13px; color: var(--color-muted); margin-bottom: 16px; line-height: 1.6;">
                提交后，管理员将在 1-3 个工作日内审核。审核通过后资金将原路返回，请耐心等待。
            </p>
            <form id="refundForm">
                <div class="form-group">
                    <label class="form-label">退款理由 *</label>
                    <textarea name="refundReason" class="form-input" style="min-height: 100px; resize: vertical; font-family: inherit;"
                              maxlength="500" placeholder="请详细说明退款原因（不超过 500 字）" required></textarea>
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="btn btn-ghost" style="flex: 1;" onclick="closeRefundModal()">取消</button>
                    <button type="submit" class="btn btn-primary" style="flex: 1; background: #b45309; border-color: #b45309;">提交申请</button>
                </div>
            </form>
        </div>
    </div>

    <!-- 评价弹窗（双向：买家评卖家 / 卖家评买家） -->
    <div id="creditModal" class="modal" style="z-index: 1001;">
        <div class="modal-content" style="max-width: 480px;">
            <div class="modal-title" style="color: #f59e0b;">
                <i class="fa fa-star"></i> 评价
            </div>
            <p style="font-size: 13px; color: var(--color-muted); margin-bottom: 20px; line-height: 1.6;">
                请为本次交易打分。评价提交后不可修改，会影响对方信用分。
            </p>
            <form id="creditForm">
                <div class="form-group" style="text-align: center; padding: 10px 0;">
                    <label class="form-label" style="text-align: center; margin-bottom: 12px;">评分（1-5 星）*</label>
                    <div id="starPicker" style="display: inline-flex; gap: 8px; font-size: 32px; cursor: pointer;">
                        <i class="fa fa-star-o" data-score="1" style="color: #e5e7eb; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="2" style="color: #e5e7eb; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="3" style="color: #e5e7eb; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="4" style="color: #e5e7eb; transition: color 0.15s;"></i>
                        <i class="fa fa-star-o" data-score="5" style="color: #e5e7eb; transition: color 0.15s;"></i>
                    </div>
                    <input type="hidden" name="score" id="scoreInput" required>
                    <div id="scoreText" style="margin-top: 8px; font-size: 12px; color: var(--color-placeholder); height: 16px;">
                        点击星星选择评分
                    </div>
                </div>
                <div class="form-group">
                    <label class="form-label">评价内容（选填）</label>
                    <textarea name="content" class="form-input" style="min-height: 80px; resize: vertical; font-family: inherit;"
                              maxlength="500" placeholder="说点什么吧，比如商品描述是否准确、卖家服务态度等"></textarea>
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="btn btn-ghost" style="flex: 1;" onclick="closeCreditModal()">取消</button>
                    <button type="submit" class="btn btn-primary" style="flex: 1; background: #f59e0b; border-color: #f59e0b;" id="creditSubmitBtn">
                        <i class="fa fa-paper-plane"></i> 提交评价
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- 投诉弹窗 -->
    <div id="complaintModal" class="modal" style="z-index: 1001;">
        <div class="modal-content" style="max-width: 480px;">
            <div class="modal-title" style="color: #b91c1c;">
                <i class="fa fa-flag"></i> 投诉
            </div>
            <p style="font-size: 13px; color: var(--color-muted); margin-bottom: 16px; line-height: 1.6;">
                投诉将由管理员在 1-3 个工作日内审核处理。请详细说明情况，避免情绪化表达。
            </p>
            <form id="complaintForm">
                <div class="form-group">
                    <label class="form-label"><span style="color: var(--color-danger);">*</span> 投诉原因</label>
                    <textarea name="reason" class="form-input" style="min-height: 100px; resize: vertical; font-family: inherit;"
                              maxlength="500" placeholder="请详细说明投诉原因（不超过 500 字）" required></textarea>
                </div>
                <div class="form-group">
                    <label class="form-label">证据图片 URL（选填）</label>
                    <input type="text" name="evidence" class="form-input" maxlength="500"
                           placeholder="如：聊天截图、商品问题照片等的 URL">
                </div>
                <div style="display: flex; gap: 8px; margin-top: 20px;">
                    <button type="button" class="btn btn-ghost" style="flex: 1;" onclick="closeComplaintModal()">取消</button>
                    <button type="submit" class="btn btn-primary" style="flex: 1; background: #b91c1c; border-color: #b91c1c;" id="complaintSubmitBtn">
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
    if (!confirm('确认付款 ¥<%= order != null ? order.getFinalPrice() : "0.00" %>？\n(演示项目，跳过实际支付)')) return;
    axios.post(ctx + '/order?action=pay', new URLSearchParams({ orderNo: orderNo }))
        .then(r => {
            if (r.data.success) {
                toast('付款成功', 'success');
                setTimeout(() => location.reload(), 800);
            } else {
                toast(r.data.message, 'error');
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
            star.style.color = '#f59e0b';
        } else {
            star.className = 'fa fa-star-o';
            star.style.color = '#e5e7eb';
        }
    });
    document.getElementById('scoreText').textContent = n > 0 ? scoreLabels[n] : '点击星星选择评分';
    document.getElementById('scoreText').style.color = n > 0 ? '#f59e0b' : 'var(--color-placeholder)';
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
            s.style.color = sn <= n ? '#fbbf24' : '#e5e7eb';
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