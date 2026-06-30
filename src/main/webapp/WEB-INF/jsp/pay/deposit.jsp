<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.AuctionItem item =
            (org.example.entity.AuctionItem) request.getAttribute("item");
    java.math.BigDecimal balance =
            (java.math.BigDecimal) request.getAttribute("balance");
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    if (item == null) { response.sendError(404, "拍品不存在"); return; }
    if (currentUser == null) { response.sendRedirect(ctx + "/user?action=login"); return; }
    boolean isOwner = currentUser.getId().equals(item.getSellerId());
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>缴纳押金 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #000; color: #FFEE00; font-family: 'Sarasa Mono SC', Consolas, monospace; min-height: 100vh; }
        .scanline {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none; z-index: 9999;
            background: repeating-linear-gradient(0deg, transparent, transparent 2px,
                rgba(0, 240, 255, 0.03) 2px, rgba(0, 240, 255, 0.03) 4px);
        }
        .pay-wrap { max-width: 720px; margin: 32px auto; padding: 0 16px; }
        .pay-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.2);
            border-radius: 2px; padding: 24px 28px;
        }
        .pay-title {
            font-size: 18px; font-weight: 700; color: #FFEE00;
            display: flex; align-items: center; gap: 8px;
            padding-bottom: 12px; margin-bottom: 18px;
            border-bottom: 1px dashed rgba(0, 240, 255, 0.2);
        }
        .pay-title::before { content: '// '; color: rgba(0, 240, 255, 0.5); font-weight: 400; }
        .item-row { display: flex; gap: 14px; align-items: center; padding: 12px 0; border-bottom: 1px solid rgba(0, 240, 255, 0.08); }
        .item-cover {
            width: 64px; height: 64px; background: #0a0a0a;
            border: 1px solid rgba(0, 240, 255, 0.15); border-radius: 2px;
            display: grid; place-items: center; color: rgba(0, 240, 255, 0.3);
            font-size: 22px; flex-shrink: 0; overflow: hidden;
        }
        .item-cover img { width: 100%; height: 100%; object-fit: cover; }
        .item-info { flex: 1; min-width: 0; }
        .item-title { font-size: 14px; color: #FFEE00; line-height: 1.4;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .item-meta { font-size: 12px; color: rgba(255, 238, 0, 0.4); margin-top: 4px; }
        .item-meta span { margin-right: 10px; }

        .deposit-amount {
            background: rgba(0, 240, 255, 0.05);
            border: 1px dashed rgba(0, 240, 255, 0.3);
            border-radius: 2px; padding: 18px 20px; margin: 18px 0;
            text-align: center;
        }
        .deposit-amount-label { font-size: 12px; color: rgba(255, 238, 0, 0.5); margin-bottom: 4px; letter-spacing: 1px; }
        .deposit-amount-value { font-size: 32px; font-weight: 800; color: #00F0FF; letter-spacing: 1px; }
        .deposit-amount-value small { font-size: 18px; margin-right: 4px; }

        .balance-tip {
            background: rgba(255, 238, 0, 0.05); border: 1px solid rgba(255, 238, 0, 0.15);
            border-radius: 2px; padding: 10px 14px; font-size: 13px;
            color: rgba(255, 238, 0, 0.7); margin-bottom: 16px;
            display: flex; align-items: center; gap: 8px;
        }
        .balance-tip i { color: #FFEE00; }

        .methods { display: flex; flex-direction: column; gap: 8px; margin: 14px 0; }
        .method {
            padding: 14px 18px; background: #0a0a0a;
            border: 1px solid rgba(0, 240, 255, 0.15); border-radius: 2px;
            cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; gap: 12px;
        }
        .method:hover { border-color: #00F0FF; background: rgba(0, 240, 255, 0.04); }
        .method.active { border-color: #00F0FF; background: rgba(0, 240, 255, 0.08); box-shadow: 0 0 12px rgba(0, 240, 255, 0.2); }
        .method-logo {
            width: 36px; height: 36px; border-radius: 4px;
            display: grid; place-items: center; font-size: 20px; flex-shrink: 0;
        }
        .method-logo.alipay { background: #1677ff; color: #fff; }
        .method-logo.wechat { background: #07c160; color: #fff; }
        .method-logo.balance { background: #FFEE00; color: #000; }
        .method-name { font-size: 15px; font-weight: 600; color: #FFEE00; flex: 1; }
        .method-desc { font-size: 12px; color: rgba(255, 238, 0, 0.5); margin-top: 2px; }
        .method-radio {
            width: 18px; height: 18px; border: 2px solid rgba(0, 240, 255, 0.3);
            border-radius: 50%; flex-shrink: 0; position: relative;
        }
        .method.active .method-radio { border-color: #00F0FF; }
        .method.active .method-radio::after {
            content: ''; position: absolute; top: 50%; left: 50%;
            transform: translate(-50%, -50%);
            width: 8px; height: 8px; background: #00F0FF; border-radius: 50%;
            box-shadow: 0 0 6px #00F0FF;
        }

        .pay-btn {
            width: 100%; padding: 14px; font-size: 15px; font-weight: 700;
            background: #00F0FF; color: #000; border: none; border-radius: 2px;
            cursor: pointer; transition: all 0.15s;
            font-family: inherit; margin-top: 12px;
            display: flex; align-items: center; justify-content: center; gap: 6px;
        }
        .pay-btn:hover:not(:disabled) { background: #FFEE00; box-shadow: 0 0 16px rgba(255, 238, 0, 0.4); }
        .pay-btn:disabled { opacity: 0.5; cursor: not-allowed; }

        .info-note {
            background: rgba(0, 240, 255, 0.04); border: 1px solid rgba(0, 240, 255, 0.15);
            border-radius: 2px; padding: 12px 16px; margin-top: 14px;
            font-size: 12px; color: rgba(255, 238, 0, 0.6); line-height: 1.7;
        }
        .info-note i { color: #00F0FF; margin-right: 4px; }

        .back-link {
            display: inline-flex; align-items: center; gap: 4px;
            color: rgba(0, 240, 255, 0.7); text-decoration: none; font-size: 13px;
            margin-bottom: 14px;
        }
        .back-link:hover { color: #00F0FF; }
    </style>
</head>
<body>

<div class="scanline"></div>

<div class="pay-wrap">
    <a href="<%=ctx%>/item?action=detail&id=<%= item.getId() %>" class="back-link">
        <i class="fa fa-arrow-left"></i> 返回拍品详情
    </a>

    <% if (isOwner) { %>
    <div class="pay-card" style="text-align: center; padding: 60px 20px;">
        <i class="fa fa-exclamation-circle" style="font-size: 48px; color: #FF003C; opacity: 0.5; display: block; margin-bottom: 12px;"></i>
        <div style="font-size: 16px; color: #FFEE00; margin-bottom: 8px;">您不能给自己发布的拍品缴纳押金</div>
    </div>
    <% } else { %>

    <div class="pay-card">
        <div class="pay-title">缴纳参拍押金</div>

        <div class="item-row">
            <div class="item-cover">
                <c:choose>
                    <c:when test="<%= item.getCoverImage() != null && !item.getCoverImage().isEmpty() %>">
                        <img src="<%= item.getCoverImage() %>" alt="" onerror="this.style.display='none'">
                    </c:when>
                    <c:otherwise><i class="fa fa-image"></i></c:otherwise>
                </c:choose>
            </div>
            <div class="item-info">
                <div class="item-title"><%= item.getTitle() %></div>
                <div class="item-meta">
                    <span><i class="fa fa-tag"></i> 起拍价 ¥<%= item.getStartPrice().toPlainString() %></span>
                    <span><i class="fa fa-clock-o"></i> <%= item.getEndTime() == null ? "-" : item.getEndTime().toString().substring(0, Math.min(16, item.getEndTime().toString().length())) %></span>
                </div>
            </div>
        </div>

        <div class="deposit-amount">
            <div class="deposit-amount-label">应缴押金</div>
            <div class="deposit-amount-value">
                <small>¥</small><%= item.getDeposit() == null ? "0.00" : item.getDeposit().toPlainString() %>
            </div>
        </div>

        <div class="balance-tip">
            <i class="fa fa-info-circle"></i>
            <span>当前账户余额：¥<%= balance == null ? "0.00" : balance.toPlainString() %></span>
        </div>

        <div class="methods" id="methods">
            <div class="method active" data-method="balance" onclick="selectMethod('balance')">
                <div class="method-logo balance"><i class="fa fa-database"></i></div>
                <div style="flex: 1;">
                    <div class="method-name">账户余额</div>
                    <div class="method-desc">即时到账，推荐</div>
                </div>
                <div class="method-radio"></div>
            </div>
            <div class="method" data-method="alipay" onclick="selectMethod('alipay')">
                <div class="method-logo alipay"><i class="fa fa-mobile"></i></div>
                <div style="flex: 1;">
                    <div class="method-name">支付宝</div>
                    <div class="method-desc">模拟支付，演示用</div>
                </div>
                <div class="method-radio"></div>
            </div>
            <div class="method" data-method="wechat" onclick="selectMethod('wechat')">
                <div class="method-logo wechat"><i class="fa fa-weixin"></i></div>
                <div style="flex: 1;">
                    <div class="method-name">微信支付</div>
                    <div class="method-desc">模拟支付，演示用</div>
                </div>
                <div class="method-radio"></div>
            </div>
        </div>

        <button class="pay-btn" id="payBtn" onclick="doPay()">
            <i class="fa fa-shield"></i> 确认缴纳押金
        </button>

        <div class="info-note">
            <div><i class="fa fa-info-circle"></i> 押金缴纳后该笔金额将锁定在平台，拍卖结束后：</div>
            <div style="padding-left: 18px; margin-top: 4px;">
                · <span style="color: #00F0FF;">未中标</span> → 全额退回至您的账户余额<br>
                · <span style="color: #00F0FF;">中标</span> → 自动抵作货款的一部分（剩余尾款仍需支付）
            </div>
        </div>
    </div>

    <% } %>
</div>

<script>
    const itemId = <%= item.getId() %>;
    let selectedMethod = 'balance';

    function selectMethod(method) {
        selectedMethod = method;
        document.querySelectorAll('.method').forEach(el => el.classList.remove('active'));
        document.querySelector('[data-method="' + method + '"]').classList.add('active');
    }

    function doPay() {
        const btn = document.getElementById('payBtn');
        if (btn.disabled) return;
        btn.disabled = true;
        btn.innerHTML = '<i class="fa fa-spinner fa-spin"></i> 处理中...';

        // 余额支付：直接 POST
        // 模拟支付：后端返回 redirect URL
        const xhr = new XMLHttpRequest();
        xhr.open('POST', '<%=ctx%>/deposit?action=pay', true);
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) return;
            btn.disabled = false;
            btn.innerHTML = '<i class="fa fa-shield"></i> 确认缴纳押金';
            try {
                const r = JSON.parse(xhr.responseText);
                if (r.success) {
                    if (r.redirect) {
                        window.location.href = r.redirect;
                    } else {
                        // 余额支付成功，直接跳结果页
                        window.location.href = '<%=ctx%>/payment?action=result&type=deposit&status=success&itemId=' + itemId +
                            '&message=' + encodeURIComponent(r.message || '押金缴纳成功');
                    }
                } else {
                    alert(r.message || '缴纳失败');
                }
            } catch (e) {
                alert('请求失败：' + e.message);
            }
        };
        xhr.send('itemId=' + itemId + '&method=' + selectedMethod);
    }
</script>

</body>
</html>
