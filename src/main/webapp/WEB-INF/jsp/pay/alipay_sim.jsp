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
    if (method == null) method = "alipay";
    if (itemTitle == null) itemTitle = "";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>支付宝收银台 · 模拟</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #f5f5f5; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif;
            min-height: 100vh; display: flex; flex-direction: column;
        }
        /* 顶部蓝色导航 */
        .alipay-header {
            background: #1677ff; color: #fff; padding: 12px 16px;
            display: flex; align-items: center; justify-content: space-between;
        }
        .alipay-header .back { color: #fff; text-decoration: none; font-size: 14px; display: flex; align-items: center; gap: 4px; }
        .alipay-header .title { font-size: 15px; font-weight: 500; }
        .alipay-header .close { color: rgba(255, 255, 255, 0.85); text-decoration: none; font-size: 20px; }

        .alipay-logo { text-align: center; padding: 32px 16px 16px; }
        .alipay-logo .icon { font-size: 48px; color: #1677ff; }
        .alipay-logo .name { font-size: 20px; font-weight: 700; color: #1677ff; margin-top: 6px; letter-spacing: 1px; }
        .alipay-logo .sub { font-size: 12px; color: #999; margin-top: 4px; }

        .alipay-body {
            background: #fff; margin: 0 16px; border-radius: 12px;
            padding: 24px 20px; box-shadow: 0 2px 12px rgba(0, 0, 0, 0.05);
        }
        .amount-row {
            text-align: center; padding: 18px 0;
            border-bottom: 1px dashed #eee;
        }
        .amount-label { font-size: 13px; color: #999; margin-bottom: 8px; }
        .amount-value { font-size: 36px; font-weight: 700; color: #333; letter-spacing: 1px; }
        .amount-value small { font-size: 18px; margin-right: 2px; }

        .pay-detail { padding: 14px 0; font-size: 13px; color: #666; }
        .pay-detail .row { display: flex; justify-content: space-between; padding: 6px 0; }
        .pay-detail .row .k { color: #999; }
        .pay-detail .row .v { color: #333; max-width: 60%; text-align: right; }

        .pwd-area {
            margin-top: 16px; padding-top: 16px; border-top: 1px solid #eee;
        }
        .pwd-label { font-size: 13px; color: #999; margin-bottom: 8px; }
        .pwd-input {
            width: 100%; padding: 12px 14px; font-size: 16px;
            border: 1px solid #ddd; border-radius: 6px; outline: none;
            letter-spacing: 4px; font-family: monospace;
        }
        .pwd-input:focus { border-color: #1677ff; }
        .pwd-tip { font-size: 11px; color: #aaa; margin-top: 4px; }

        .actions { padding: 16px; display: flex; gap: 10px; margin-top: auto; }
        .btn-cancel {
            flex: 1; padding: 14px; background: #fff; color: #666;
            border: 1px solid #ddd; border-radius: 24px;
            font-size: 15px; cursor: pointer; text-align: center; text-decoration: none;
        }
        .btn-confirm {
            flex: 2; padding: 14px; background: #1677ff; color: #fff;
            border: none; border-radius: 24px;
            font-size: 15px; font-weight: 600; cursor: pointer;
            display: flex; align-items: center; justify-content: center; gap: 4px;
        }
        .btn-confirm:disabled { opacity: 0.5; cursor: not-allowed; }

        .countdown {
            text-align: center; font-size: 12px; color: #999; padding: 8px 0;
        }
        .countdown .sec { color: #1677ff; font-weight: 600; }

        .footer {
            text-align: center; padding: 12px; font-size: 11px; color: #bbb;
        }
    </style>
</head>
<body>

<div class="alipay-header">
    <a href="javascript:history.back()" class="back"><span>&lt;</span> 返回</a>
    <div class="title">支付宝收银台</div>
    <a href="#" class="close" onclick="document.getElementById('cancelForm').submit(); return false;">×</a>
</div>

<div class="alipay-logo">
    <div class="icon">支</div>
    <div class="name">支付宝</div>
    <div class="sub">模拟支付 · 演示用</div>
</div>

<div class="alipay-body">
    <div class="amount-row">
        <div class="amount-label"><%= "deposit".equals(type) ? "缴纳押金" : "支付尾款" %></div>
        <div class="amount-value">
            <small>¥</small><%= amount %>
        </div>
    </div>

    <div class="pay-detail">
        <div class="row"><span class="k">商品</span><span class="v"><%= itemTitle %></span></div>
        <div class="row"><span class="k">商户</span><span class="v">二手物品拍卖系统</span></div>
        <div class="row"><span class="k">支付方式</span><span class="v">余额宝 / 快捷支付</span></div>
        <div class="row"><span class="k">交易号</span><span class="v" id="tradeNo">生成中...</span></div>
    </div>

    <div class="pwd-area">
        <div class="pwd-label">支付密码（演示：随便输 6 位数字即可）</div>
        <input type="password" class="pwd-input" id="pwd" maxlength="6" placeholder="******" autocomplete="off">
        <div class="pwd-tip">⚠ 本页面为模拟收银台，不会发起真实扣款</div>
    </div>

    <div class="countdown">支付剩余时间 <span class="sec" id="countdown">15:00</span></div>
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
    // 生成模拟交易号
    const tradeNo = '2025' + Date.now() + Math.floor(Math.random() * 1000);
    document.getElementById('tradeNo').textContent = tradeNo;

    // 倒计时
    let sec = 15 * 60;
    const cdEl = document.getElementById('countdown');
    const cdTimer = setInterval(() => {
        sec--;
        if (sec <= 0) {
            clearInterval(cdTimer);
            cdEl.textContent = '00:00';
            alert('支付已超时');
            document.getElementById('cancelForm').submit();
            return;
        }
        const m = String(Math.floor(sec / 60)).padStart(2, '0');
        const s = String(sec % 60).padStart(2, '0');
        cdEl.textContent = m + ':' + s;
    }, 1000);

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

        // 构造隐藏 form 提交
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
