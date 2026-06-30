<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    String rowsJson = (String) request.getAttribute("rowsJson");
    if (rowsJson == null) rowsJson = "[]";
    String error = (String) request.getAttribute("error");

    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) { response.sendRedirect(ctx + "/user?action=login"); return; }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <title>我的出价 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        body { background: #000; color: #FFEE00; font-family: 'Sarasa Mono SC', Consolas, monospace; min-height: 100vh; }
        .scanline { position: fixed; inset: 0; z-index: 9999; pointer-events: none;
            background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 240, 255, 0.03) 2px, rgba(0, 240, 255, 0.03) 4px); }
        .wrap { max-width: 960px; margin: 32px auto; padding: 0 16px; }
        .page-title {
            font-size: 20px; font-weight: 700; color: #FFEE00;
            padding-bottom: 12px; margin-bottom: 18px;
            border-bottom: 1px dashed rgba(0, 240, 255, 0.2);
            display: flex; align-items: center; gap: 8px;
        }
        .page-title::before { content: '// '; color: rgba(0, 240, 255, 0.5); font-weight: 400; }

        .bid-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.15);
            border-radius: 2px; padding: 14px 18px; margin-bottom: 10px;
            display: grid; grid-template-columns: 80px 1fr auto; gap: 14px; align-items: center;
        }
        .bid-card.winning { border-color: rgba(255, 238, 0, 0.4); background: rgba(255, 238, 0, 0.04); }
        .bid-card.ended { opacity: 0.65; }

        .cover {
            width: 80px; height: 80px; background: #0a0a0a;
            border: 1px solid rgba(0, 240, 255, 0.12); border-radius: 2px;
            display: grid; place-items: center; color: rgba(0, 240, 255, 0.3);
            font-size: 28px; overflow: hidden;
        }
        .cover img { width: 100%; height: 100%; object-fit: cover; }

        .info .title { font-size: 15px; font-weight: 600; color: #FFEE00; margin-bottom: 6px; }
        .info .meta { font-size: 12px; color: rgba(255, 238, 0, 0.5); }
        .info .meta span { margin-right: 12px; }
        .info .badge { padding: 1px 8px; border-radius: 2px; font-size: 11px; font-weight: 600; border: 1px solid; margin-left: 4px; }
        .info .badge.win { background: rgba(255, 238, 0, 0.15); color: #FFEE00; border-color: rgba(255, 238, 0, 0.4); }
        .info .badge.lose { background: rgba(255, 0, 60, 0.1); color: #FF003C; border-color: rgba(255, 0, 60, 0.3); }

        .amount { text-align: right; }
        .amount .my { font-size: 13px; color: rgba(255, 238, 0, 0.6); }
        .amount .val { font-size: 18px; font-weight: 700; color: #00F0FF; }

        .actions { display: flex; flex-direction: column; gap: 4px; align-items: flex-end; }
        .btn { padding: 6px 14px; font-size: 12px; background: #00F0FF; color: #000;
            border: none; border-radius: 2px; text-decoration: none;
            display: inline-block; font-family: inherit; font-weight: 600; }
        .btn:hover { background: #FFEE00; }
        .btn.outline { background: transparent; color: #00F0FF; border: 1px solid #00F0FF; }
        .btn.outline:hover { background: rgba(0, 240, 255, 0.1); color: #FFEE00; }

        .empty { text-align: center; padding: 60px 20px; color: rgba(255, 238, 0, 0.35);
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.1); border-radius: 2px; }
        .empty i { font-size: 48px; opacity: 0.2; display: block; margin-bottom: 12px; }
    </style>
</head>
<body>
<div class="scanline"></div>

<div class="wrap">
    <div class="page-title">我的出价</div>

    <% if (error != null) { %>
    <div class="empty"><i class="fa fa-exclamation-circle"></i><p><%= error %></p></div>
    <% } else { %>
    <div id="bidList"></div>
    <% } %>
</div>

<script>
    const rows = <%= rowsJson %>;
    const ctxPath = '<%=ctx%>';
    const list = document.getElementById('bidList');
    if (!rows || rows.length === 0) {
        list.innerHTML = '<div class="empty"><i class="fa fa-gavel"></i><p>暂无出价记录</p>' +
            '<p style="font-size: 12px; margin-top: 8px; opacity: 0.7;"><a href="' + ctxPath + '/item?action=list" style="color: #00F0FF;">去浏览拍品 →</a></p></div>';
    } else {
        list.innerHTML = rows.map(r => {
            const cover = r.coverImage ?
                '<img src="' + r.coverImage + '" onerror="this.style.display=\'none\'">' :
                '<i class="fa fa-image"></i>';
            const fmt = n => Number(n).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
            const statusText = r.itemStatus === 1 ? (r.itemEnded ? '已结束' : '拍卖中')
                : (r.itemStatus === 2 ? '已成交' : (r.itemStatus === 3 ? '已流拍' : '其他'));
            const statusBadge = r.iAmWinning
                ? '<span class="badge win">领先中</span>'
                : (r.itemEnded ? '<span class="badge lose">未中标</span>' : '');
            const endTime = r.itemEndTime ? r.itemEndTime.substring(0, 16) : '-';
            const cls = (r.iAmWinning ? 'winning' : '') + (r.itemEnded ? ' ended' : '');
            return '<div class="bid-card ' + cls + '">' +
                '<div class="cover">' + cover + '</div>' +
                '<div class="info">' +
                    '<div class="title"><a href="' + ctxPath + '/item?action=detail&id=' + r.itemId + '" style="color: #FFEE00; text-decoration: none;">' +
                    (r.title || '').replace(/</g, '&lt;') + '</a>' + statusBadge + '</div>' +
                    '<div class="meta">' +
                        '<span><i class="fa fa-tag"></i> 起拍 ¥' + fmt(r.startPrice) + '</span>' +
                        '<span><i class="fa fa-arrow-up"></i> 当前 ¥' + fmt(r.currentPrice) + '</span>' +
                        '<span><i class="fa fa-clock-o"></i> ' + endTime + '</span>' +
                        '<span><i class="fa fa-info-circle"></i> ' + statusText + '</span>' +
                    '</div>' +
                '</div>' +
                '<div class="amount">' +
                    '<div class="my">我的出价</div>' +
                    '<div class="val">¥' + fmt(r.myMaxBid) + '</div>' +
                '</div>' +
                '</div>';
        }).join('');
    }
</script>

</body>
</html>
