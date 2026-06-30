<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.Admin admin = (org.example.entity.Admin) request.getAttribute("admin");
    java.util.List<java.util.Map<String, Object>> items = (java.util.List<java.util.Map<String, Object>>) request.getAttribute("items");
    Integer activeCount = (Integer) request.getAttribute("activeCount");
    Integer soldCount = (Integer) request.getAttribute("soldCount");
    Integer flowCount = (Integer) request.getAttribute("flowCount");
    org.example.entity.SystemAccount sa = (org.example.entity.SystemAccount) request.getAttribute("sa");
    java.util.List<org.example.entity.PaymentRecord> recentRecords = (java.util.List<org.example.entity.PaymentRecord>) request.getAttribute("recentRecords");
    java.util.List<java.util.Map<String, Object>> users = (java.util.List<java.util.Map<String, Object>>) request.getAttribute("users");
    if (items == null) items = new java.util.ArrayList<>();
    if (activeCount == null) activeCount = 0;
    if (soldCount == null) soldCount = 0;
    if (flowCount == null) flowCount = 0;
    if (recentRecords == null) recentRecords = new java.util.ArrayList<>();
    if (users == null) users = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>演示控制台 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #000; color: #FFEE00; font-family: 'Sarasa Mono SC', Consolas, monospace; min-height: 100vh; padding: 0 0 40px; }
        .scanline { position: fixed; inset: 0; z-index: 9999; pointer-events: none;
            background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 240, 255, 0.03) 2px, rgba(0, 240, 255, 0.03) 4px); }
        .header { background: #0d0d0d; border-bottom: 1px solid rgba(0, 240, 255, 0.2); padding: 12px 24px; display: flex; align-items: center; justify-content: space-between; }
        .header h1 { font-size: 18px; color: #FFEE00; }
        .header h1::before { content: '// '; color: #00F0FF; }
        .header a { color: #00F0FF; text-decoration: none; font-size: 13px; }
        .wrap { max-width: 1280px; margin: 0 auto; padding: 0 16px; }
        .section { margin: 18px 0; }
        .section-title { font-size: 15px; font-weight: 700; color: #FFEE00; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px dashed rgba(0, 240, 255, 0.2); }
        .section-title::before { content: '> '; color: #00F0FF; }

        .stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }
        .stat-card { background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.2); border-radius: 2px; padding: 14px 18px; }
        .stat-card .label { font-size: 11px; color: rgba(255, 238, 0, 0.5); margin-bottom: 4px; }
        .stat-card .value { font-size: 22px; font-weight: 800; color: #00F0FF; }
        .stat-card.sold .value { color: #00FF41; }
        .stat-card.flow .value { color: rgba(255, 238, 0, 0.5); }
        .stat-card.platform .value { color: #FFEE00; }

        .action-bar { display: flex; gap: 10px; align-items: center; flex-wrap: wrap; padding: 10px 14px; background: rgba(0, 240, 255, 0.05); border: 1px dashed rgba(0, 240, 255, 0.3); border-radius: 2px; }
        .action-bar .info { font-size: 12px; color: rgba(255, 238, 0, 0.7); flex: 1; }
        .btn-action {
            padding: 8px 18px; background: #00F0FF; color: #000; border: none; border-radius: 2px;
            font-size: 13px; font-weight: 700; cursor: pointer; text-decoration: none; display: inline-flex; align-items: center; gap: 6px;
            font-family: inherit; transition: all 0.15s;
        }
        .btn-action:hover { background: #FFEE00; box-shadow: 0 0 12px rgba(255, 238, 0, 0.4); }
        .btn-action.secondary { background: transparent; color: #00F0FF; border: 1px solid #00F0FF; }
        .btn-action.secondary:hover { background: rgba(0, 240, 255, 0.1); }

        .item-table { width: 100%; border-collapse: collapse; background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.1); font-size: 12px; }
        .item-table th, .item-table td { padding: 8px 10px; text-align: left; border-bottom: 1px solid rgba(0, 240, 255, 0.05); }
        .item-table th { background: #050505; color: #00F0FF; font-weight: 600; font-size: 11px; text-transform: uppercase; }
        .item-table tr:hover { background: rgba(0, 240, 255, 0.03); }
        .item-table td.amount { text-align: right; font-family: 'Courier New', monospace; color: #00F0FF; }
        .badge { padding: 2px 8px; border-radius: 2px; font-size: 10px; font-weight: 600; border: 1px solid; display: inline-block; }
        .badge-1 { background: rgba(0, 240, 255, 0.1); color: #00F0FF; border-color: rgba(0, 240, 255, 0.3); }
        .badge-2 { background: rgba(0, 255, 65, 0.1); color: #00FF41; border-color: rgba(0, 255, 65, 0.3); }
        .badge-3 { background: rgba(255, 238, 0, 0.1); color: rgba(255, 238, 0, 0.6); border-color: rgba(255, 238, 0, 0.2); }

        .user-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
        .user-card { background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.15); border-radius: 2px; padding: 12px; }
        .user-card .name { font-size: 14px; color: #FFEE00; font-weight: 600; }
        .user-card .phone { font-size: 11px; color: rgba(255, 238, 0, 0.4); margin: 2px 0 6px; }
        .user-card .bal { font-size: 16px; font-weight: 700; color: #00F0FF; }

        .record-row { display: grid; grid-template-columns: auto 1fr auto; gap: 10px; padding: 8px 12px; background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.08); border-radius: 2px; margin-bottom: 4px; font-size: 12px; }
        .record-row .amt { font-family: 'Courier New', monospace; font-weight: 700; text-align: right; }
        .record-row .pos { color: #00FF41; }
        .record-row .neg { color: #FF003C; }

        .empty { text-align: center; padding: 40px 20px; color: rgba(255, 238, 0, 0.35); font-size: 13px; }
    </style>
</head>
<body>
<div class="scanline"></div>

<div class="header">
    <h1>演示控制台 · 5-Phase 拍卖流程</h1>
    <div>
        <a href="<%=ctx%>/admin"><i class="fa fa-tachometer"></i> 后台首页</a>
        &nbsp;|&nbsp;
        <a href="<%=ctx%>/index.jsp"><i class="fa fa-home"></i> 站点首页</a>
    </div>
</div>

<div class="wrap">

    <!-- 概览 -->
    <div class="section">
        <div class="stat-grid">
            <div class="stat-card">
                <div class="label">拍卖中</div>
                <div class="value"><%= activeCount %></div>
            </div>
            <div class="stat-card sold">
                <div class="label">已成交</div>
                <div class="value"><%= soldCount %></div>
            </div>
            <div class="stat-card flow">
                <div class="label">已流拍</div>
                <div class="value"><%= flowCount %></div>
            </div>
            <div class="stat-card platform">
                <div class="label">平台账户余额</div>
                <div class="value">¥<%= sa == null ? "0.00" : sa.getBalance().toPlainString() %></div>
            </div>
        </div>
    </div>

    <!-- 一键触发结算 -->
    <div class="section">
        <div class="section-title">一键触发拍卖结算（手动模拟 end_time 到期）</div>
        <div class="action-bar">
            <div class="info">
                <i class="fa fa-info-circle" style="color: #00F0FF;"></i>
                扫描所有 <code style="color: #FFEE00;">end_time &lt; now AND status=1</code> 的拍品，逐个结算
                <br>
                · 有人出价 → <b style="color: #00FF41;">已成交</b> + 中标者押金<b>转货款</b> + 其他押金<b>退还</b>
                <br>
                · 没人出价 → <b style="color: rgba(255, 238, 0, 0.6);">已流拍</b> + 所有押金<b>退还</b>
            </div>
            <button class="btn-action" onclick="triggerSettle()">
                <i class="fa fa-gavel"></i> 立即触发结算
            </button>
        </div>
        <div id="settleResult" style="margin-top: 10px;"></div>
    </div>

    <!-- 拍品列表 -->
    <div class="section">
        <div class="section-title">拍品列表（最近 20 个）</div>
        <% if (items.isEmpty()) { %>
        <div class="empty"><i class="fa fa-inbox"></i> 暂无拍品</div>
        <% } else { %>
        <table class="item-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>标题</th>
                    <th>卖家</th>
                    <th>起拍价</th>
                    <th>押金</th>
                    <th>当前价</th>
                    <th>中标人</th>
                    <th>押金 (缴/转/退)</th>
                    <th>状态</th>
                    <th>结束时间</th>
                </tr>
            </thead>
            <tbody>
                <% for (java.util.Map<String, Object> it : items) { %>
                <tr>
                    <td>#<%= it.get("id") %></td>
                    <td><a href="<%=ctx%>/item?action=detail&id=<%= it.get("id") %>" style="color: #FFEE00; text-decoration: none;">
                        <%= it.get("title") %>
                    </a></td>
                    <td><%= it.get("sellerName") %></td>
                    <td class="amount">¥<%= it.get("startPrice") == null ? "0.00" : ((java.math.BigDecimal)it.get("startPrice")).toPlainString() %></td>
                    <td class="amount" style="color: #FFEE00;">¥<%= it.get("deposit") == null ? "0.00" : ((java.math.BigDecimal)it.get("deposit")).toPlainString() %></td>
                    <td class="amount">¥<%= it.get("currentPrice") == null ? "0.00" : ((java.math.BigDecimal)it.get("currentPrice")).toPlainString() %></td>
                    <td><%= it.get("winnerName") == null ? "<span style='color: rgba(255, 238, 0, 0.3);'>-</span>" : it.get("winnerName") %></td>
                    <td style="font-family: 'Courier New', monospace; font-size: 11px;">
                        <span style="color: rgba(255, 238, 0, 0.5);"><%= it.get("depositActive") %></span> /
                        <span style="color: #00FF41;"><%= it.get("depositTransferred") %></span> /
                        <span style="color: #00F0FF;"><%= it.get("depositRefunded") %></span>
                    </td>
                    <td>
                        <%
                            int st = it.get("status") == null ? 0 : (Integer)it.get("status");
                            String sCls = "badge-1", sTxt = "拍卖中";
                            if (st == 2) { sCls = "badge-2"; sTxt = "已成交"; }
                            else if (st == 3) { sCls = "badge-3"; sTxt = "已流拍"; }
                            else if (st == 0) { sCls = "badge-3"; sTxt = "待审核"; }
                            else if (st == 4) { sCls = "badge-3"; sTxt = "已下架"; }
                        %>
                        <span class="badge <%= sCls %>"><%= sTxt %></span>
                    </td>
                    <td style="font-size: 11px; color: rgba(255, 238, 0, 0.5);">
                        <%
                            java.time.LocalDateTime et = (java.time.LocalDateTime)it.get("endTime");
                            if (et != null) out.print(et.toString().substring(0, Math.min(16, et.toString().length())));
                        %>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
        <% } %>
    </div>

    <!-- 用户余额 -->
    <div class="section">
        <div class="section-title">用户余额快照</div>
        <div class="user-grid">
            <% for (java.util.Map<String, Object> u : users) { %>
            <div class="user-card">
                <div class="name"><%= u.get("username") %></div>
                <div class="phone"><i class="fa fa-phone"></i> <%= u.get("phone") %></div>
                <div class="bal">¥<%= u.get("balance") == null ? "0.00" : ((java.math.BigDecimal)u.get("balance")).toPlainString() %></div>
            </div>
            <% } %>
        </div>
    </div>

    <!-- 平台账户 -->
    <div class="section">
        <div class="section-title">平台虚拟账户（system_account）</div>
        <% if (sa != null) { %>
        <table class="item-table">
            <tr>
                <th>当前余额</th>
                <th>累计收入</th>
                <th>累计支出</th>
                <th>更新时间</th>
            </tr>
            <tr>
                <td class="amount">¥<%= sa.getBalance() == null ? "0.00" : sa.getBalance().toPlainString() %></td>
                <td class="amount" style="color: #00FF41;">¥<%= sa.getTotalIn() == null ? "0.00" : sa.getTotalIn().toPlainString() %></td>
                <td class="amount" style="color: #FF003C;">¥<%= sa.getTotalOut() == null ? "0.00" : sa.getTotalOut().toPlainString() %></td>
                <td><%= sa.getUpdateTime() == null ? "-" : sa.getUpdateTime().toString().substring(0, 19).replace("T", " ") %></td>
            </tr>
        </table>
        <% } %>
    </div>

    <!-- 近期流水 -->
    <div class="section">
        <div class="section-title">最近 20 条资金流水（payment_record）</div>
        <% if (recentRecords.isEmpty()) { %>
        <div class="empty"><i class="fa fa-list-alt"></i> 暂无流水</div>
        <% } else { %>
            <% for (org.example.entity.PaymentRecord r : recentRecords) {
                boolean pos = r.getAmount() != null && r.getAmount().compareTo(java.math.BigDecimal.ZERO) > 0;
            %>
            <div class="record-row">
                <span class="badge badge-1"><%= r.getTypeText() %></span>
                <div>
                    <div style="color: #FFEE00; font-size: 12px;"><%= r.getRemark() == null ? "" : r.getRemark() %></div>
                    <div style="color: rgba(255, 238, 0, 0.5); font-size: 11px; margin-top: 2px;">
                        用户 #<%= r.getUserId() %> ·
                        <%= r.getMethodText() %> ·
                        <% if (r.getOrderNo() != null) { %>
                            单号 <%= r.getOrderNo().substring(0, Math.min(8, r.getOrderNo().length())) %>... ·
                        <% } %>
                        <% if (r.getBalanceAfter() != null) { %>余额后 ¥<%= r.getBalanceAfter().toPlainString() %><% } %>
                    </div>
                </div>
                <div class="amt <%= pos ? "pos" : "neg" %>">
                    <%= pos ? "+" : "" %>¥<%= r.getAmount() == null ? "0.00" : r.getAmount().toPlainString() %>
                </div>
            </div>
            <% } %>
        <% } %>
    </div>
</div>

<script>
function triggerSettle() {
    // 先异步取一下当前能结算的拍品数
    const xhr1 = new XMLHttpRequest();
    xhr1.open('GET', '<%=ctx%>/admin?action=settle-list', true);
    xhr1.onreadystatechange = function() {
        if (xhr1.readyState !== 4) return;
        let count = 0;
        let titles = [];
        try {
            const r = JSON.parse(xhr1.responseText);
            if (r.success) {
                count = r.count;
                titles = (r.items || []).map(it => '#' + it.id + ' ' + it.title);
            }
        } catch (e) {}
        const msg = '当前有 ' + count + ' 个可结算的拍品：\n\n' +
                    (titles.length ? titles.join('\n') + '\n\n' : '') +
                    '⚠ 警告：\n' +
                    '· 如果没出价，会直接流拍（再也没法出价了）\n' +
                    '· 如果已出价，会触发退押金 + 中标者押金转货款\n\n' +
                    '请确认你已经完成 alice/bob 缴押金 + 出价，再点确定。\n\n' +
                    '确定要触发结算吗？';
        if (!confirm(msg)) return;
        doSettle();
    };
    xhr1.send();
}

function doSettle() {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', '<%=ctx%>/bid?action=settle', true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== 4) return;
        try {
            const r = JSON.parse(xhr.responseText);
            const el = document.getElementById('settleResult');
            if (r.success) {
                el.innerHTML = '<div style="padding: 12px 16px; background: rgba(0, 255, 65, 0.1); border: 1px solid #00FF41; border-radius: 2px; color: #00FF41; font-size: 13px;">' +
                    '<b>✓ ' + (r.message || '结算完成') + '</b><br>' +
                    '结算: ' + r.settled + ' 拍品 · ' +
                    '成交: ' + r.soldCount + ' · 流拍: ' + r.flowCount + ' · ' +
                    '退押金: ' + r.refundDeposits + ' 笔 · ' +
                    '转货款: ' + r.transferredDeposits + ' 笔' +
                    '</div>';
                setTimeout(() => location.reload(), 1500);
            } else {
                el.innerHTML = '<div style="padding: 12px 16px; background: rgba(255, 0, 60, 0.1); border: 1px solid #FF003C; border-radius: 2px; color: #FF003C; font-size: 13px;">' +
                    '✗ ' + (r.message || '结算失败') +
                    '</div>';
            }
        } catch (e) {
            document.getElementById('settleResult').innerHTML = '<div style="color: #FF003C;">请求失败：' + e.message + '</div>';
        }
    };
    xhr.send();
}
</script>

</body>
</html>
