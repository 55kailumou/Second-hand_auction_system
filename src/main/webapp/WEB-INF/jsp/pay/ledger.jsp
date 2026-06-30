<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    java.util.List<org.example.entity.PaymentRecord> records =
            (java.util.List<org.example.entity.PaymentRecord>) request.getAttribute("records");
    Integer total = (Integer) request.getAttribute("total");
    Integer pageNo = (Integer) request.getAttribute("page");
    Integer totalPages = (Integer) request.getAttribute("totalPages");
    Integer type = (Integer) request.getAttribute("type");
    java.math.BigDecimal balance = (java.math.BigDecimal) request.getAttribute("balance");
    java.math.BigDecimal platformBalance = (java.math.BigDecimal) request.getAttribute("platformBalance");
    if (records == null) records = new java.util.ArrayList<>();
    if (total == null) total = 0;
    if (pageNo == null || pageNo < 1) pageNo = 1;
    if (totalPages == null) totalPages = 1;
    if (balance == null) balance = java.math.BigDecimal.ZERO;
    if (platformBalance == null) platformBalance = java.math.BigDecimal.ZERO;

    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) { response.sendRedirect(ctx + "/user?action=login"); return; }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>账户流水 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #000; color: #FFEE00; font-family: 'Sarasa Mono SC', Consolas, monospace; min-height: 100vh; }
        .wrap { max-width: 1000px; margin: 32px auto; padding: 0 16px; }
        .page-title {
            font-size: 20px; font-weight: 700; color: #FFEE00;
            padding-bottom: 12px; margin-bottom: 18px;
            border-bottom: 1px dashed rgba(0, 240, 255, 0.2);
            display: flex; align-items: center; gap: 8px;
        }
        .page-title::before { content: '// '; color: rgba(0, 240, 255, 0.5); font-weight: 400; }

        .balance-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 18px; }
        .balance-card {
            background: linear-gradient(135deg, rgba(0, 240, 255, 0.08), rgba(255, 238, 0, 0.05));
            border: 1px solid rgba(0, 240, 255, 0.2);
            border-radius: 2px; padding: 18px 22px;
            display: flex; align-items: center; gap: 14px;
        }
        .balance-icon {
            width: 44px; height: 44px; border-radius: 2px;
            background: rgba(0, 240, 255, 0.1); color: #00F0FF;
            display: grid; place-items: center; font-size: 20px;
            border: 1px solid rgba(0, 240, 255, 0.3); flex-shrink: 0;
        }
        .balance-info .label { font-size: 12px; color: rgba(255, 238, 0, 0.5); margin-bottom: 4px; }
        .balance-info .value { font-size: 22px; font-weight: 800; color: #00F0FF; }

        .filters {
            display: flex; gap: 6px; flex-wrap: wrap;
            margin-bottom: 14px; padding: 10px 12px;
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.1);
            border-radius: 2px;
        }
        .filter-link {
            padding: 4px 12px; font-size: 12px; border-radius: 2px;
            color: #00F0FF; text-decoration: none; border: 1px solid transparent;
            transition: all 0.15s;
        }
        .filter-link:hover { background: rgba(0, 240, 255, 0.08); border-color: rgba(0, 240, 255, 0.3); }
        .filter-link.active { background: rgba(0, 240, 255, 0.15); border-color: #00F0FF; color: #FFEE00; }

        .record-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.1);
            border-radius: 2px; padding: 12px 16px; margin-bottom: 8px;
            display: grid; grid-template-columns: auto 1fr auto; gap: 14px; align-items: center;
        }
        .type-tag {
            padding: 4px 10px; border-radius: 2px; font-size: 11px; font-weight: 600;
            border: 1px solid; min-width: 80px; text-align: center;
        }
        .type-1 { background: rgba(255, 0, 60, 0.1); color: #FF003C; border-color: rgba(255, 0, 60, 0.3); }   /* 押金缴 */
        .type-2 { background: rgba(0, 255, 65, 0.1); color: #00FF41; border-color: rgba(0, 255, 65, 0.3); }   /* 押金退 */
        .type-3 { background: rgba(255, 238, 0, 0.1); color: #FFEE00; border-color: rgba(255, 238, 0, 0.3); } /* 押金转 */
        .type-4 { background: rgba(0, 240, 255, 0.1); color: #00F0FF; border-color: rgba(0, 240, 255, 0.3); } /* 尾款 */
        .type-5 { background: rgba(255, 0, 60, 0.1); color: #FF003C; border-color: rgba(255, 0, 60, 0.3); }   /* 打款 */
        .type-6 { background: rgba(0, 255, 65, 0.1); color: #00FF41; border-color: rgba(0, 255, 65, 0.3); }   /* 退款 */

        .record-info .title { font-size: 14px; color: #FFEE00; font-weight: 500; margin-bottom: 4px; }
        .record-info .meta { font-size: 11px; color: rgba(255, 238, 0, 0.5); }
        .record-info .meta span { margin-right: 10px; }

        .record-amount { font-size: 18px; font-weight: 700; text-align: right; }
        .amount-pos { color: #00FF41; }
        .amount-neg { color: #FF003C; }

        .empty {
            text-align: center; padding: 60px 20px; color: rgba(255, 238, 0, 0.35);
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.1);
            border-radius: 2px;
        }
        .empty i { font-size: 48px; opacity: 0.2; display: block; margin-bottom: 12px; }

        .pagination { display: flex; justify-content: center; gap: 6px; margin-top: 20px; }
        .pagination a, .pagination span {
            padding: 6px 12px; font-size: 13px; border: 1px solid rgba(0, 240, 255, 0.2);
            border-radius: 2px; color: #00F0FF; text-decoration: none;
        }
        .pagination a:hover { background: rgba(0, 240, 255, 0.1); }
        .pagination .current { background: #00F0FF; color: #000; }
        .pagination .disabled { opacity: 0.4; cursor: not-allowed; }
    </style>
</head>
<body>

<div class="wrap">
    <div class="page-title">账户流水</div>

    <div class="balance-row">
        <div class="balance-card">
            <div class="balance-icon"><i class="fa fa-database"></i></div>
            <div class="balance-info">
                <div class="label">我的余额</div>
                <div class="value">¥<%= balance.toPlainString() %></div>
            </div>
        </div>
        <div class="balance-card">
            <div class="balance-icon" style="background: rgba(255, 238, 0, 0.1); color: #FFEE00; border-color: rgba(255, 238, 0, 0.3);">
                <i class="fa fa-bank"></i>
            </div>
            <div class="balance-info">
                <div class="label">平台暂管金额（参考）</div>
                <div class="value" style="color: #FFEE00;">¥<%= platformBalance.toPlainString() %></div>
            </div>
        </div>
    </div>

    <div class="filters">
        <a href="<%=ctx%>/payment?action=ledger" class="filter-link <%= type == null ? "active" : "" %>">全部</a>
        <a href="<%=ctx%>/payment?action=ledger&type=1" class="filter-link <%= type != null && type == 1 ? "active" : "" %>">押金缴纳</a>
        <a href="<%=ctx%>/payment?action=ledger&type=2" class="filter-link <%= type != null && type == 2 ? "active" : "" %>">押金退还</a>
        <a href="<%=ctx%>/payment?action=ledger&type=3" class="filter-link <%= type != null && type == 3 ? "active" : "" %>">押金转货款</a>
        <a href="<%=ctx%>/payment?action=ledger&type=4" class="filter-link <%= type != null && type == 4 ? "active" : "" %>">尾款支付</a>
        <a href="<%=ctx%>/payment?action=ledger&type=5" class="filter-link <%= type != null && type == 5 ? "active" : "" %>">平台打款</a>
        <a href="<%=ctx%>/payment?action=ledger&type=6" class="filter-link <%= type != null && type == 6 ? "active" : "" %>">平台退款</a>
    </div>

    <% if (records.isEmpty()) { %>
    <div class="empty">
        <i class="fa fa-list-alt"></i>
        <p>暂无流水记录</p>
    </div>
    <% } else { %>
        <% for (org.example.entity.PaymentRecord r : records) {
            int t = r.getType() == null ? 0 : r.getType();
            boolean isPos = r.getAmount() != null && r.getAmount().compareTo(java.math.BigDecimal.ZERO) > 0;
        %>
        <div class="record-card">
            <span class="type-tag type-<%= t %>"><%= r.getTypeText() %></span>
            <div class="record-info">
                <div class="title"><%= r.getRemark() == null ? "" : r.getRemark() %></div>
                <div class="meta">
                    <span><i class="fa fa-calendar"></i> <%= r.getCreateTime() == null ? "-" : r.getCreateTime().toString().substring(0, Math.min(16, r.getCreateTime().toString().length())) %></span>
                    <span><i class="fa fa-credit-card"></i> <%= r.getMethodText() %></span>
                    <% if (r.getOrderNo() != null && !r.getOrderNo().isEmpty()) { %>
                    <span><i class="fa fa-file-text-o"></i> <%= r.getOrderNo().substring(0, Math.min(8, r.getOrderNo().length())) %>...</span>
                    <% } %>
                    <% if (r.getBalanceAfter() != null) { %>
                    <span><i class="fa fa-database"></i> 余额后 ¥<%= r.getBalanceAfter().toPlainString() %></span>
                    <% } %>
                </div>
            </div>
            <div class="record-amount <%= isPos ? "amount-pos" : "amount-neg" %>">
                <%= isPos ? "+" : "" %>¥<%= r.getAmount() == null ? "0.00" : r.getAmount().toPlainString() %>
            </div>
        </div>
        <% } %>

        <% if (totalPages > 1) { %>
        <div class="pagination">
            <% if (pageNo > 1) { %>
                <a href="<%=ctx%>/payment?action=ledger<%= type == null ? "" : "&type=" + type %>&page=<%= pageNo - 1 %>">上一页</a>
            <% } else { %>
                <span class="disabled">上一页</span>
            <% } %>
            <span class="current"><%= pageNo %> / <%= totalPages %></span>
            <% if (pageNo < totalPages) { %>
                <a href="<%=ctx%>/payment?action=ledger<%= type == null ? "" : "&type=" + type %>&page=<%= pageNo + 1 %>">下一页</a>
            <% } else { %>
                <span class="disabled">下一页</span>
            <% } %>
        </div>
        <% } %>
    <% } %>
</div>

</body>
</html>
