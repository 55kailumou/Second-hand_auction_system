<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String ctx = request.getContextPath();
    String type        = (String) request.getAttribute("type");
    String method      = (String) request.getAttribute("method");
    String amount      = (String) request.getAttribute("amount");
    String title       = (String) request.getAttribute("title");
    String itemTitle   = (String) request.getAttribute("itemTitle");
    String itemId      = (String) request.getAttribute("itemId");
    String orderNo     = (String) request.getAttribute("orderNo");
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) { response.sendRedirect(ctx + "/user?action=login"); return; }
    if (amount == null) amount = "0.00";
    if (type == null) type = "deposit";
    if (method == null) method = "wechat";
    if (itemTitle == null) itemTitle = "";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>微信支付 · 模拟</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #ededed; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
            min-height: 100vh; display: flex; flex-direction: column;
        }
        .wx-header {
            background: #fff; color: #333; padding: 12px 16px;
            display: flex; align-items: center; justify-content: space-between;
            border-bottom: 1px solid #e5e5e5;
        }
        .wx-header .back { color: #333; text-decoration: none; font-size: 18px; }
        .wx-header .title { font-size: 16px; font-weight: 500; }
        .wx-header .close { color: #999; text-decoration: none; font-size: 22px; }

        .wx-banner {
            background: #07c160; color: #fff; text-align: center; padding: 28px 16px;
        }
        .wx-banner .logo { font-size: 36px; font-weight: 800; letter-spacing: 2px; }
        .wx-banner .sub { font-size: 12px; opacity: 0.85; margin-top: 4px; }

        .wx-body { padding: 16px; }
        .amount-card {
            background: #fff; border-radius: 8px; padding: 24px 20px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
            text-align: center; margin-bottom: 12px;
        }
        .amount-label { font-size: 13px; color: #888; margin-bottom: 10px; }
        .amount-value { font-size: 38px; font-weight: 700; color: #07c160; letter-spacing: 1px; }
        .amount-value small { font-size: 18px; margin-right: 2px; }

        .detail-card {
            background: #fff; border-radius: 8px; padding: 14px 20px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04); font-size: 13px;
        }
        .detail-card .row { display: flex; justify-content: space-between; padding: 6px 0; }
        .detail-card .row .k { color: #999; }
        .detail-card .row .v { color: #333; max-width: 60%; text-align: right; }

        .pwd-card {
            background: #fff; border-radius: 8px; padding: 16px 20px; margin-top: 12px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
        }
        .pwd-label { font-size: 13px; color: #888; margin-bottom: 8px; }
        .pwd-input {
            width: 100%; padding: 12px 14px; font-size: 16px;
            border: 1px solid #ddd; border-radius: 6px; outline: none;
            letter-spacing: 4px; font-family: monospace;
        }
        .pwd-input:focus { border-color: #07c160; }
        .pwd-tip { font-size: 11px; color: #aaa; margin-top: 4px; }

        .actions { padding: 16px; display: flex; gap: 10px; margin-top: auto; }
        .btn-cancel {
            flex: 1; padding: 14px; background: #fff; color: #666;
            border: 1px solid #ddd; border-radius: 24px;
            font-size: 15px; cursor: pointer;
        }
        .btn-confirm {
            flex: 2; padding: 14px; background: #07c160; color: #fff;
            border: none; border-radius: 24px;
            font-size: 15px; font-weight: 600; cursor: pointer;
        }
        .btn-confirm:disabled { opacity: 0.5; cursor: not-allowed; }

        .footer { text-align: center; padding: 12px; font-size: 11px; color: #bbb; }
    </style>
</head>
<body>

<div class="wx-header">
    <a href="javascript:history.back()" class="back">&lt;</a>
    <div class="title">微信支付</div>
    <a href="#" class="close" onclick="document.getElementById('cancelForm').submit(); return false;">×</a>
</div>

<div class="wx-banner">
    <div class="logo">微信支付</div>
    <div class="sub">模拟支付 · 演示用</div>
</div>

<div class="wx-body">
    <div class="amount-card">
        <div class="amount-label"><%= "deposit".equals(type) ? "缴纳押金" : "支付尾款" %></div>
        <div class="amount-value">
            <small>¥</small><%= amount %>
        </div>
    </div>

    <div class="detail-card">
        <div class="row"><span class="k">商品</span><span class="v"><%= itemTitle %></span></div>
        <div class="row"><span class="k">商户</span><span class="v">二手物品拍卖系统</span></div>
        <div class="row"><span class="k">交易号</span><span class="v" id="tradeNo">生成中...</span></div>
    </div>

    <div class="pwd-card">
        <div class="pwd-label">支付密码（演示：随便输 6 位数字）</div>
        <input type="password" class="pwd-input" id="pwd" maxlength="6" placeholder="******" autocomplete="off">
        <div class="pwd-tip">⚠ 本页面为模拟收银台，不会发起真实扣款</div>
    </div>
</div>

<div class="actions">
    <button class="btn-cancel" onclick="document.getElementById('cancelForm').submit()">取消</button>
    <button class="btn-confirm" id="confirmBtn" onclick="doPay()">确认支付</button>
</div>

<div class="footer">© 二手拍卖 · 模拟支付演示</div>

<form id="cancelForm" method="post" action="<%=ctx%>/payment" style="display:none;">
    <input type="hidden" name="action" value="cancel">
    <input type="hidden" name="type" value="<%= type %>">
    <input type="hidden" name="method" value="<%= method %>">
    <input type="hidden" name="itemId" value="<%= itemId %>">
    <input type="hidden" name="orderNo" value="<%= orderNo %>">
</form>

<script>
    const tradeNo = 'wx' + Date.now() + Math.floor(Math.random() * 1000);
    document.getElementById('tradeNo').textContent = tradeNo;

    function doPay() {
        const pwd = document.getElementById('pwd').value;
        if (pwd.length < 6) {
            alert('请输入 6 位支付密码（演示用，任意 6 位数字即可）');
            return;
        }
        const btn = document.getElementById('confirmBtn');
        if (btn.disabled) return;
        btn.disabled = true;
        btn.innerHTML = '<span>支付中...</span>';

        const f = document.createElement('form');
        f.method = 'POST';
        f.action = '<%=ctx%>/payment';
        const fields = {
            action: 'callback',
            type: '<%= type %>',
            method: '<%= method %>',
            tradeNo: tradeNo,
            itemId: '<%= itemId %>',
            orderNo: '<%= orderNo %>'
        };
        for (const k in fields) {
            const i = document.createElement('input');
            i.type = 'hidden';
            i.name = k;
            i.value = fields[k];
            f.appendChild(i);
        }
        document.body.appendChild(f);
        f.submit();
    }
</script>

</body>
</html>
