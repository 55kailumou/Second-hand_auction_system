<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    java.util.List<org.example.entity.Deposit> deposits =
            (java.util.List<org.example.entity.Deposit>) request.getAttribute("deposits");
    java.math.BigDecimal balance =
            (java.math.BigDecimal) request.getAttribute("balance");
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) { response.sendRedirect(ctx + "/user?action=login"); return; }
    if (deposits == null) deposits = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>我的押金 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #000; color: #FFEE00; font-family: 'Sarasa Mono SC', Consolas, monospace; min-height: 100vh; }
        .wrap { max-width: 960px; margin: 32px auto; padding: 0 16px; }
        .page-title {
            font-size: 20px; font-weight: 700; color: #FFEE00;
            padding-bottom: 12px; margin-bottom: 18px;
            border-bottom: 1px dashed rgba(0, 240, 255, 0.2);
            display: flex; align-items: center; gap: 8px;
        }
        .page-title::before { content: '// '; color: rgba(0, 240, 255, 0.5); font-weight: 400; }

        .balance-card {
            background: linear-gradient(135deg, rgba(0, 240, 255, 0.08), rgba(255, 238, 0, 0.05));
            border: 1px solid rgba(0, 240, 255, 0.2);
            border-radius: 2px; padding: 20px 24px; margin-bottom: 16px;
            display: flex; align-items: center; gap: 16px;
        }
        .balance-icon {
            width: 48px; height: 48px; border-radius: 2px;
            background: rgba(0, 240, 255, 0.1); color: #00F0FF;
            display: grid; place-items: center; font-size: 22px;
            border: 1px solid rgba(0, 240, 255, 0.3); flex-shrink: 0;
        }
        .balance-info .label { font-size: 12px; color: rgba(255, 238, 0, 0.5); margin-bottom: 4px; }
        .balance-info .value { font-size: 24px; font-weight: 800; color: #00F0FF; }

        .deposit-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.12);
            border-radius: 2px; padding: 16px 20px; margin-bottom: 10px;
            display: grid; grid-template-columns: 1fr auto; gap: 12px; align-items: center;
        }
        .deposit-card.returned { opacity: 0.5; }
        .deposit-card.transferred { border-color: rgba(255, 238, 0, 0.2); }
        .deposit-card .row1 { font-size: 14px; color: #FFEE00; font-weight: 600; margin-bottom: 4px; }
        .deposit-card .row2 { font-size: 12px; color: rgba(255, 238, 0, 0.5); }
        .deposit-card .row2 span { margin-right: 12px; }
        .deposit-card .amount { font-size: 18px; font-weight: 700; color: #00F0FF; text-align: right; }
        .badge {
            padding: 2px 8px; border-radius: 2px; font-size: 11px; font-weight: 600;
            display: inline-block; border: 1px solid;
        }
        .badge-warning { background: rgba(255, 238, 0, 0.1); color: #FFEE00; border-color: rgba(255, 238, 0, 0.3); }
        .badge-success { background: rgba(0, 255, 65, 0.1); color: #00FF41; border-color: rgba(0, 255, 65, 0.3); }
        .badge-info    { background: rgba(0, 240, 255, 0.1); color: #00F0FF; border-color: rgba(0, 240, 255, 0.3); }
        .badge-gray    { background: rgba(255, 255, 255, 0.05); color: rgba(255, 238, 0, 0.4); border-color: rgba(255, 238, 0, 0.1); }

        .empty {
            text-align: center; padding: 60px 20px; color: rgba(255, 238, 0, 0.35);
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.1);
            border-radius: 2px;
        }
        .empty i { font-size: 48px; opacity: 0.2; display: block; margin-bottom: 12px; }
    </style>
</head>
<body>

<div class="wrap">
    <div class="page-title">我的押金</div>

    <div class="balance-card">
        <div class="balance-icon"><i class="fa fa-database"></i></div>
        <div class="balance-info">
            <div class="label">当前账户余额</div>
            <div class="value">¥<%= balance == null ? "0.00" : balance.toPlainString() %></div>
        </div>
        <a href="<%=ctx%>/user?action=center" style="margin-left: auto; color: #00F0FF; font-size: 13px; text-decoration: none;">
            <i class="fa fa-user"></i> 个人中心
        </a>
    </div>

    <% if (deposits.isEmpty()) { %>
    <div class="empty">
        <i class="fa fa-shield"></i>
        <p>暂无押金记录</p>
        <p style="font-size: 12px; margin-top: 8px;">参与竞拍需要先缴纳押金</p>
    </div>
    <% } else { %>
        <% for (org.example.entity.Deposit d : deposits) { %>
            <div class="deposit-card <%= d.getStatus() != null && d.getStatus() == 2 ? "returned" : "" %> <%= d.getStatus() != null && d.getStatus() == 1 ? "transferred" : "" %>">
                <div>
                    <div class="row1">
                        拍品 #<%= d.getItemId() %>
                        <% int s = d.getStatus() == null ? 0 : d.getStatus();
                           String cls = "badge-gray", txt = "未知";
                           if (s == 0) { cls = "badge-warning"; txt = "已缴纳（锁定中）"; }
                           else if (s == 1) { cls = "badge-success"; txt = "已转货款"; }
                           else if (s == 2) { cls = "badge-info"; txt = "已退还"; }
                           else if (s == 3) { cls = "badge-gray"; txt = "已没收"; }
                        %>
                        <span class="badge <%= cls %>"><%= txt %></span>
                    </div>
                    <div class="row2">
                        <span><i class="fa fa-calendar"></i> <%= d.getPayTime() == null ? "-" : d.getPayTime().toString().substring(0, Math.min(16, d.getPayTime().toString().length())) %></span>
                        <span><i class="fa fa-credit-card"></i> <%= d.getPayMethod() == null ? "-" :
                            ("balance".equals(d.getPayMethod()) ? "余额" :
                             ("alipay".equals(d.getPayMethod()) ? "支付宝" :
                              ("wechat".equals(d.getPayMethod()) ? "微信" : d.getPayMethod()))) %></span>
                        <% if (d.getRefundTime() != null) { %>
                        <span><i class="fa fa-undo"></i> <%= d.getRefundTime().toString().substring(0, Math.min(16, d.getRefundTime().toString().length())) %></span>
                        <% } %>
                    </div>
                </div>
                <div>
                    <div class="amount">¥<%= d.getAmount() == null ? "0.00" : d.getAmount().toPlainString() %></div>
                    <a href="<%=ctx%>/item?action=detail&id=<%= d.getItemId() %>"
                       style="font-size: 12px; color: #00F0FF; text-decoration: none; display: block; text-align: right; margin-top: 4px;">
                        查看拍品 <i class="fa fa-angle-right"></i>
                    </a>
                </div>
            </div>
        <% } %>
    <% } %>
</div>

</body>
</html>
