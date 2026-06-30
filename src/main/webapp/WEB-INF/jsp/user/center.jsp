<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.util.EscapeUtil" %>
<%!
    /** 渲染拍品网格（限当前用户发布，3 个 tab 复用） */
    private String renderItemGrid(java.util.List<org.example.entity.AuctionItem> items, String ctx) {
        if (items == null || items.isEmpty()) {
            return "<div class=\"empty-state\"><i class=\"fa fa-inbox\"></i>暂无相关拍品</div>";
        }
        StringBuilder sb = new StringBuilder("<div class=\"cp-goods-grid\">");
        for (org.example.entity.AuctionItem item : items) {
            String cover = item.getCoverImage() != null && !item.getCoverImage().isEmpty()
                    ? "background-image: url('" + item.getCoverImage() + "'); background-size: cover; background-position: center;"
                    : "";
            String placeholder = (item.getCoverImage() == null || item.getCoverImage().isEmpty())
                    ? "<i class=\"fa fa-image\"></i>" : "";
            String overlay = "";
            if (item.getStatus() != null && item.getStatus() == 2) {
                overlay = "<div class=\"sold-tag\">已成交</div>";
            } else if (item.getStatus() != null && item.getStatus() == 3) {
                overlay = "<div class=\"sold-tag\" style=\"background: rgba(100,100,100,0.7); color: #888;\">已流拍</div>";
            }
            sb.append("<a href=\"").append(ctx).append("/item?action=detail&id=").append(item.getId())
              .append("\" class=\"cp-goods-card\">")
              .append("<div class=\"cp-goods-cover\" style=\"").append(cover).append("\">")
              .append(placeholder).append(overlay)
              .append("</div>")
              .append("<div class=\"cp-goods-body\">")
              .append("<div class=\"cp-goods-title\">").append(EscapeUtil.html(item.getTitle())).append("</div>")
              .append("<div class=\"cp-goods-price\"><small>¥</small>")
              .append(item.getCurrentPrice() == null ? "0.00" : item.getCurrentPrice().toPlainString())
              .append("</div></div></a>");
        }
        sb.append("</div>");
        return sb.toString();
    }
%>
<%
    String ctx = request.getContextPath();
    org.example.entity.User user =
            (org.example.entity.User) request.getAttribute("user");
    java.util.Map<String, Integer> sellerStats =
            (java.util.Map<String, Integer>) request.getAttribute("sellerStats");
    Integer ordersPending = (Integer) request.getAttribute("ordersPending");
    Integer ordersPaid = (Integer) request.getAttribute("ordersPaid");
    Integer ordersShipped = (Integer) request.getAttribute("ordersShipped");
    Integer ordersDone = (Integer) request.getAttribute("ordersDone");
    Integer myBidsCount = (Integer) request.getAttribute("myBidsCount");
    Integer favoritesCount = (Integer) request.getAttribute("favoritesCount");
    Integer addressCount = (Integer) request.getAttribute("addressCount");
    Integer unreadMessageCount = (Integer) request.getAttribute("unreadMessageCount");
    Integer myComplaintCount = (Integer) request.getAttribute("myComplaintCount");
    Integer sellerOrdersToShip = (Integer) request.getAttribute("sellerOrdersToShip");
    java.util.List<org.example.entity.AuctionItem> activeItems =
            (java.util.List<org.example.entity.AuctionItem>) request.getAttribute("activeItems");
    java.util.List<org.example.entity.AuctionItem> soldItems =
            (java.util.List<org.example.entity.AuctionItem>) request.getAttribute("soldItems");
    java.util.List<org.example.entity.AuctionItem> failedItems =
            (java.util.List<org.example.entity.AuctionItem>) request.getAttribute("failedItems");
    String error = (String) request.getAttribute("error");
    if (sellerStats == null) sellerStats = new java.util.HashMap<>();
    if (ordersPending == null) ordersPending = 0;
    if (ordersPaid == null) ordersPaid = 0;
    if (ordersShipped == null) ordersShipped = 0;
    if (ordersDone == null) ordersDone = 0;
    if (myBidsCount == null) myBidsCount = 0;
    if (favoritesCount == null) favoritesCount = 0;
    if (addressCount == null) addressCount = 0;
    if (unreadMessageCount == null) unreadMessageCount = 0;
    if (myComplaintCount == null) myComplaintCount = 0;
    if (sellerOrdersToShip == null) sellerOrdersToShip = 0;
    if (activeItems == null) activeItems = new java.util.ArrayList<>();
    if (soldItems == null) soldItems = new java.util.ArrayList<>();
    if (failedItems == null) failedItems = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>// 个人中心 · 二手拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * CYBERPUNK 2077 — PERSONAL CENTER
         * Theme: black / yellow #FFEE00 / gold / monospace
         * Visual: clip-path polygons, scanlines, neon borders
         * ============================================================ */
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            background: #0a0a0a;
            color: #FFEE00;
            font-family: 'JetBrains Mono', 'Courier New', monospace;
            min-height: 100vh;
            position: relative;
            overflow-x: hidden;
        }

        /* ---- scanline overlay ---- */
        .scanline {
            position: fixed; inset: 0; z-index: 9999;
            pointer-events: none;
            background: repeating-linear-gradient(
                0deg,
                transparent,
                transparent 2px,
                rgba(255,238,0,0.015) 2px,
                rgba(255,238,0,0.015) 4px
            );
        }

        /* ---- glitch accent border ---- */
        .glitch-border {
            position: relative;
        }
        .glitch-border::before {
            content: '';
            position: absolute; inset: -2px; z-index: -1;
            background: linear-gradient(45deg, #FFEE00, #ff8800, #FFEE00);
            clip-path: polygon(2% 0%, 98% 0%, 100% 2%, 100% 98%, 98% 100%, 2% 100%, 0% 98%, 0% 2%);
        }

        /* ========== NAV (cp-nav) — 由 cyberpunk.css 统一管理 ========== */

        /* ========== MAIN GRID (cp-container) ========== */
        .cp-container {
            max-width: 1200px; margin: 12px auto 0;
            padding: 0 16px;
            display: grid;
            grid-template-columns: 200px 1fr 40px;
            gap: 12px;
            align-items: start;
        }

        /* ========== SIDEBAR (cp-card-sm) ========== */
        .cp-card-sm {
            background: #0d0d0d;
            border: 1px solid #333;
            clip-path: polygon(2% 0%, 98% 0%, 100% 2%, 100% 98%, 98% 100%, 2% 100%, 0% 98%, 0% 2%);
            position: sticky; top: 72px;
            padding: 8px 0;
        }
        .side-group { margin-bottom: 4px; }
        .side-group-title {
            display: flex; align-items: center; gap: 8px;
            padding: 10px 16px; font-size: 12px; color: #FFEE00;
            cursor: pointer; transition: color 0.15s;
            font-weight: 600; font-family: 'Orbitron', monospace;
        }
        .side-group-title:hover { color: #fff; text-shadow: 0 0 8px #FFEE00; }
        .side-group-title i:first-child { width: 16px; color: #FFEE00; }
        .side-group-title .arrow {
            margin-left: auto; font-size: 10px; color: #FFEE00;
            transition: transform 0.2s;
        }
        .side-group.collapsed .arrow { transform: rotate(-90deg); }
        .side-list { list-style: none; padding: 0 0 6px; }
        .side-group.collapsed .side-list { display: none; }
        .side-link {
            display: flex; align-items: center; gap: 8px;
            padding: 7px 16px 7px 40px; font-size: 12px;
            color: #777; transition: all 0.15s;
            cursor: pointer; position: relative; text-decoration: none;
        }
        .side-link::before {
            content: '>';
            position: absolute; left: 26px; top: 50%;
            transform: translateY(-50%);
            color: #FFEE00; font-size: 10px; font-weight: 700;
        }
        .side-link:hover { color: #FFEE00; background: rgba(255,238,0,0.05); }
        .side-link.active { color: #FFEE00; background: rgba(255,238,0,0.08); font-weight: 600; }

        /* cp-badge for counts */
        .cp-badge {
            margin-left: auto; font-size: 10px;
            background: #FFEE00; color: #0a0a0a;
            padding: 1px 6px; min-width: 18px; text-align: center;
            clip-path: polygon(10% 0, 90% 0, 100% 50%, 90% 100%, 10% 100%, 0% 50%);
            font-weight: 700;
        }
        .cp-badge.gray { background: #333; color: #777; }

        /* ========== CONTENT ========== */
        .content { min-width: 0; }

        /* ---- profile card CYBERPUNK ---- */
        .profile-card {
            background: linear-gradient(135deg, #1a1a0a 0%, #2a2a00 100%);
            border: 1px solid #FFEE00;
            clip-path: polygon(1% 0%, 99% 0%, 100% 2%, 100% 98%, 99% 100%, 1% 100%, 0% 98%, 0% 2%);
            padding: 24px 28px;
            box-shadow: 0 0 20px rgba(255,238,0,0.1);
            display: grid; grid-template-columns: 80px 1fr auto; gap: 20px;
            align-items: center; position: relative; overflow: hidden;
        }
        .profile-card::before {
            content: '';
            position: absolute; right: -40px; top: -40px;
            width: 200px; height: 200px;
            border: 1px solid rgba(255,238,0,0.06);
            clip-path: polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);
        }
        .profile-card::after {
            content: '';
            position: absolute; right: 60px; bottom: -60px;
            width: 140px; height: 140px;
            border: 1px solid rgba(255,238,0,0.04);
            clip-path: polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);
        }
        .profile-avatar {
            width: 80px; height: 80px;
            background: #FFEE00; color: #0a0a0a;
            display: grid; place-items: center;
            font-size: 32px; font-weight: 700;
            font-family: 'Orbitron', monospace;
            clip-path: polygon(20% 0%, 80% 0%, 100% 20%, 100% 80%, 80% 100%, 20% 100%, 0% 80%, 0% 20%);
            position: relative; z-index: 1;
            text-shadow: none;
        }
        .profile-info { position: relative; z-index: 1; }
        .profile-name { font-size: 22px; font-weight: 700; margin-bottom: 6px;
                        display: flex; align-items: center; gap: 8px; color: #FFEE00;
                        font-family: 'Orbitron', monospace;
                        text-shadow: 0 0 10px rgba(255,238,0,0.3); }
        .profile-name .hello { font-size: 13px; font-weight: 400; color: #888; }
        .profile-tags { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 6px; }
        .profile-tag {
            padding: 3px 10px;
            border: 1px solid #FFEE00;
            color: #FFEE00; font-size: 11px;
            display: flex; align-items: center; gap: 4px;
            clip-path: polygon(6% 0, 94% 0, 100% 50%, 94% 100%, 6% 100%, 0% 50%);
        }
        .profile-meta { font-size: 12px; color: #888;
                        display: flex; gap: 14px; flex-wrap: wrap; }
        .profile-meta span { display: flex; align-items: center; gap: 4px; }
        .profile-actions { display: flex; flex-direction: column; gap: 8px;
                            position: relative; z-index: 1; }
        .profile-action {
            padding: 8px 18px;
            background: #FFEE00; color: #0a0a0a;
            font-size: 12px; font-weight: 700; text-align: center;
            border: none; cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; justify-content: center; gap: 5px;
            text-decoration: none;
            clip-path: polygon(4% 0, 96% 0, 100% 50%, 96% 100%, 4% 100%, 0% 50%);
            font-family: 'Orbitron', monospace;
        }
        .profile-action:hover { background: #ffcc00; box-shadow: 0 0 12px rgba(255,238,0,0.5); }
        .profile-action.outline {
            background: transparent; color: #FFEE00;
            border: 1px solid #FFEE00;
        }
        .profile-action.outline:hover {
            background: rgba(255,238,0,0.1); color: #FFEE00;
        }

        /* ---- 4 KPI cards (cp-kpi-card) ---- */
        .core-stats {
            display: grid; grid-template-columns: repeat(4, 1fr);
            gap: 10px; margin-top: 12px;
        }
        .cp-kpi-card {
            background: #0d0d0d;
            border: 1px solid #333;
            clip-path: polygon(2% 0%, 98% 0%, 100% 2%, 100% 98%, 98% 100%, 2% 100%, 0% 98%, 0% 2%);
            padding: 18px 16px;
            display: flex; align-items: center; gap: 12px;
            cursor: pointer; transition: all 0.15s;
            text-decoration: none; color: inherit;
        }
        .cp-kpi-card:hover {
            border-color: #FFEE00;
            box-shadow: 0 0 16px rgba(255,238,0,0.15);
        }
        .cp-kpi-icon {
            width: 44px; height: 44px;
            background: #1a1a00;
            border: 1px solid #FFEE00;
            display: grid; place-items: center;
            font-size: 20px; flex-shrink: 0;
            clip-path: polygon(12% 0, 88% 0, 100% 12%, 100% 88%, 88% 100%, 12% 100%, 0 88%, 0 12%);
            color: #FFEE00;
        }
        .cp-kpi-body { min-width: 0; }
        .cp-kpi-value { font-size: 22px; font-weight: 700; color: #FFEE00; line-height: 1.1;
                        font-family: 'Orbitron', monospace; }
        .cp-kpi-label { font-size: 11px; color: #777; margin-top: 2px; }

        /* ---- order stats (cp-card) ---- */
        .cp-card {
            background: #0d0d0d;
            border: 1px solid #333;
            clip-path: polygon(1% 0%, 99% 0%, 100% 1%, 100% 99%, 99% 100%, 1% 100%, 0% 99%, 0% 1%);
            margin-top: 12px; padding: 16px 20px;
        }
        .cp-card-head {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 12px;
        }
        .cp-card-title {
            font-size: 13px; font-weight: 600;
            font-family: 'Orbitron', monospace;
            color: #FFEE00;
        }
        .cp-card-title::before {
            content: '// ';
            color: #FFEE00;
        }
        .cp-card-link { font-size: 11px; color: #555; text-decoration: none; }
        .cp-card-link:hover { color: #FFEE00; }
        .cp-order-grid {
            display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px;
        }
        .cp-order-item {
            padding: 14px;
            background: #111;
            text-align: center;
            cursor: pointer; transition: all 0.15s;
            text-decoration: none; color: inherit;
            clip-path: polygon(4% 0, 96% 0, 100% 50%, 96% 100%, 4% 100%, 0% 50%);
        }
        .cp-order-item:hover { background: #1a1a00; border-color: #FFEE00; }
        .cp-order-num { font-size: 22px; font-weight: 700; color: #555; font-family: 'Orbitron', monospace; }
        .cp-order-num.has { color: #FFEE00; }
        .cp-order-label { font-size: 11px; color: #777; margin-top: 2px; }
        .cp-order-dot {
            display: inline-block; width: 6px; height: 6px;
            background: #ff4444; margin-left: 4px; vertical-align: top;
            clip-path: polygon(50% 0%, 100% 50%, 50% 100%, 0% 50%);
        }

        /* ---- todo bar ---- */
        .todo-bar {
            background: #1a1a00; border: 1px solid #FFEE00;
            clip-path: polygon(1% 0%, 99% 0%, 100% 50%, 99% 100%, 1% 100%, 0% 50%);
            padding: 10px 16px; margin-top: 12px;
            display: flex; align-items: center; gap: 8px;
            font-size: 12px; color: #FFEE00;
        }
        .todo-bar .todo-link {
            margin-left: auto; color: #FFEE00; font-weight: 600; text-decoration: none;
        }
        .todo-bar .todo-link:hover { text-shadow: 0 0 8px rgba(255,238,0,0.6); }

        /* ---- item section (cp-grid-section) ---- */
        .cp-grid-section {
            background: #0d0d0d;
            border: 1px solid #333;
            clip-path: polygon(0.5% 0%, 99.5% 0%, 100% 0.5%, 100% 99.5%, 99.5% 100%, 0.5% 100%, 0% 99.5%, 0% 0.5%);
            margin-top: 12px; overflow: hidden;
        }
        .cp-grid-tabs {
            display: flex; align-items: center;
            padding: 12px 20px 0;
            border-bottom: 1px solid #222;
        }
        .cp-grid-tab {
            padding: 10px 18px; font-size: 12px; color: #555;
            cursor: pointer; transition: color 0.15s;
            position: relative; font-weight: 500; text-decoration: none;
            font-family: 'Orbitron', monospace;
        }
        .cp-grid-tab:hover { color: #FFEE00; }
        .cp-grid-tab.active { color: #FFEE00; font-weight: 600; }
        .cp-grid-tab.active::after {
            content: '';
            position: absolute;
            bottom: 0; left: 50%; transform: translateX(-50%);
            width: 24px; height: 2px; background: #FFEE00;
            clip-path: polygon(10% 0, 90% 0, 100% 100%, 0% 100%);
        }
        .cp-grid-tab .tab-num {
            margin-left: 4px; font-size: 11px; color: #555;
        }
        .cp-grid-tab.active .tab-num { color: #FFEE00; }
        .cp-grid-head-right {
            margin-left: auto; padding: 10px 0;
            font-size: 11px; color: #555;
        }
        .cp-grid-head-right a { color: #555; text-decoration: none; }
        .cp-grid-head-right a:hover { color: #FFEE00; }
        .cp-grid-body { padding: 16px 20px; min-height: 100px; }

        /* ---- seller stats ---- */
        .seller-stats {
            display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px;
        }
        .seller-stat {
            background: #111; padding: 14px;
            clip-path: polygon(4% 0, 96% 0, 100% 50%, 96% 100%, 4% 100%, 0% 50%);
            text-align: center;
        }
        .seller-stat-num { font-size: 22px; font-weight: 700; color: #555; font-family: 'Orbitron', monospace; }
        .seller-stat-num.primary { color: #FFEE00; }
        .seller-stat-num.success { color: #66ff66; }
        .seller-stat-num.muted   { color: #555; }
        .seller-stat-label { font-size: 11px; color: #777; margin-top: 2px; }

        /* ---- item grid (cp-goods-grid) ---- */
        .cp-goods-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
        }
        @media (max-width: 1200px) { .cp-goods-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .cp-goods-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .cp-goods-grid { grid-template-columns: repeat(3, 1fr); } }

        .cp-goods-card {
            background: #0d0d0d;
            border: 1px solid #222;
            overflow: hidden; cursor: pointer;
            transition: all 0.15s; text-decoration: none; color: inherit;
            clip-path: polygon(2% 0%, 98% 0%, 100% 2%, 100% 98%, 98% 100%, 2% 100%, 0% 98%, 0% 2%);
        }
        .cp-goods-card:hover {
            border-color: #FFEE00;
            box-shadow: 0 0 12px rgba(255,238,0,0.15);
        }
        .cp-goods-cover {
            width: 100%; aspect-ratio: 1; background: #111;
            position: relative; display: grid; place-items: center;
            overflow: hidden;
        }
        .cp-goods-cover img { width: 100%; height: 100%; object-fit: cover; }
        .cp-goods-cover i { font-size: 32px; color: rgba(255,238,0,0.15); }
        .cp-goods-cover .sold-tag {
            position: absolute; inset: 0;
            background: rgba(0,0,0,0.7);
            display: grid; place-items: center;
            color: #FFEE00; font-size: 16px; font-weight: 700;
            font-family: 'Orbitron', monospace;
            letter-spacing: 0.15em;
        }
        .cp-goods-body { padding: 8px; }
        .cp-goods-title {
            font-size: 11px; line-height: 1.4; margin-bottom: 4px;
            color: #ccc;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        }
        .cp-goods-price {
            font-size: 14px; font-weight: 700; color: #FFEE00;
            font-family: 'Orbitron', monospace;
        }
        .cp-goods-price small { font-size: 10px; margin-right: 1px; }

        /* ---- empty state ---- */
        .empty-state {
            text-align: center; padding: 40px 20px;
            color: #555; font-size: 13px;
        }
        .empty-state i { font-size: 36px; opacity: 0.3; margin-bottom: 8px; display: block; }
        .empty-state a { color: #FFEE00; }

        /* ---- alert CYBERPUNK ---- */
        .alert {
            padding: 10px 16px;
            font-size: 12px;
            clip-path: polygon(1% 0%, 99% 0%, 100% 50%, 99% 100%, 1% 100%, 0% 50%);
            margin-bottom: 12px;
        }
        .alert-warning {
            background: #1a1a00;
            border: 1px solid #FFEE00;
            color: #FFEE00;
        }

        /* ========== FLOATS (cp-floats) ========== */
        .cp-floats {
            position: sticky; top: 72px;
            display: flex; flex-direction: column; gap: 6px;
        }
        .cp-float-btn {
            width: 40px; height: 40px;
            background: #0d0d0d; border: 1px solid #333;
            display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            color: #555;
            transition: all 0.15s; cursor: pointer; font-size: 9px; gap: 1px;
            text-decoration: none;
            clip-path: polygon(15% 0, 85% 0, 100% 15%, 100% 85%, 85% 100%, 15% 100%, 0 85%, 0 15%);
        }
        .cp-float-btn i { font-size: 14px; }
        .cp-float-btn:hover { border-color: #FFEE00; color: #FFEE00; }
        .cp-float-btn.primary { background: #FFEE00; color: #0a0a0a; border-color: #FFEE00; }

        /* ========== FOOTER (cp-footer) ========== */
        .cp-footer {
            background: #050505;
            border-top: 1px solid #222;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 11px;
        }
        .cp-footer-inner {
            max-width: 1200px; margin: 0 auto;
            color: #555; font-family: 'JetBrains Mono', monospace;
        }
        .cp-footer-inner::before {
            content: '> ';
            color: #FFEE00;
        }

        /* ========== RESPONSIVE ========== */
        @media (max-width: 1024px) {
            .cp-container { grid-template-columns: 180px 1fr; }
            .cp-floats { display: none; }

        }
        @media (max-width: 768px) {
            .cp-container { grid-template-columns: 1fr; padding: 0 8px; }
            .cp-card-sm { position: static; }

            .profile-card { grid-template-columns: 64px 1fr; padding: 16px; }
            .profile-actions { grid-column: 1 / -1; flex-direction: row; }
            .profile-action { flex: 1; }
            .core-stats, .cp-order-grid, .seller-stats { grid-template-columns: repeat(2, 1fr); }
        }

        /* ---- scrollbar ---- */
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: #0a0a0a; }
        ::-webkit-scrollbar-thumb { background: #333; clip-path: polygon(10% 0, 90% 0, 100% 50%, 90% 100%, 10% 100%, 0% 50%); }
        ::-webkit-scrollbar-thumb:hover { background: #FFEE00; }

        /* ---- selection ---- */
        ::selection { background: #FFEE00; color: #0a0a0a; }
    </style>
</head>
<body>

<!-- scanline overlay -->
<div class="scanline"></div>

<!-- ========== NAV ========== -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="cp-logo-icon"><i class="fa fa-gavel"></i></span>
            <span>// AUCTION</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/order?action=list">我的订单</a>
            <a href="<%=ctx%>/user?action=center" class="active">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="cp-nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="cp-nav-tags">
            <span class="cp-nav-tags-label">热搜:</span>
            <a href="<%=ctx%>/item/list?keyword=iPhone" class="cp-nav-tag hot">iPhone 15</a>
            <a href="<%=ctx%>/item/list?keyword=相机" class="cp-nav-tag">相机</a>
            <a href="<%=ctx%>/item/list?keyword=球鞋" class="cp-nav-tag">球鞋</a>
            <a href="<%=ctx%>/item/list?keyword=茅台" class="cp-nav-tag hot">茅台</a>
        </div>
        <div class="cp-nav-user">
            <a href="<%=ctx%>/user?action=center" class="cp-user-name-link"><%= user.getUsername() %></a>
            <a href="<%=ctx%>/user?action=logout" style="font-size: 11px; color: #555; text-decoration: none;">[退出]</a>
            <a href="<%=ctx%>/user?action=center" class="cp-avatar">
                <%= user.getUsername() != null && !user.getUsername().isEmpty()
                    ? user.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </a>
        </div>
    </div>
</header>

<!-- ========== MAIN GRID ========== -->
<div class="cp-container">

    
    <aside class="cp-card-sm">
        
        <div class="side-group">
            <div class="side-group-title">
                <i class="fa fa-user-circle"></i>
                <span>// 个人中心</span>
            </div>
            <ul class="side-list">
                <li><a href="<%=ctx%>/message?action=list" class="side-link">
                    <i class="fa fa-envelope-o"></i> MESSAGES
                    <% if (unreadMessageCount != null && unreadMessageCount > 0) { %>
                        <span class="cp-badge"><%= unreadMessageCount %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/complaint?action=list" class="side-link">
                    <i class="fa fa-flag-o"></i> COMPLAINTS
                    <% if (myComplaintCount != null && myComplaintCount > 0) { %>
                        <span class="cp-badge"><%= myComplaintCount %></span>
                    <% } else { %>
                        <span class="cp-badge gray">0</span>
                    <% } %>
                </a></li>
            </ul>
        </div>

        
        <div class="side-group">
            <div class="side-group-title" onclick="toggleGroup(this)">
                <i class="fa fa-handshake-o"></i>
                <span>// 我的交易</span>
                <i class="fa fa-angle-down arrow"></i>
            </div>
            <ul class="side-list">
                <li><a href="<%=ctx%>/item?action=my-items" class="side-link">
                    我的发布
                    <% if (sellerStats.get("total") != null && sellerStats.get("total") > 0) { %>
                        <span class="cp-badge"><%= sellerStats.get("total") %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/item?action=my-bids" class="side-link">
                    <i class="fa fa-gavel"></i> 我的出价
                    <% if (myBidsCount > 0) { %>
                        <span class="cp-badge"><%= myBidsCount %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/order?action=list&role=buyer" class="side-link">
                    我的订单（买家）
                    <% if (ordersPending + ordersPaid + ordersShipped + ordersDone > 0) { %>
                        <span class="cp-badge"><%= ordersPending + ordersPaid + ordersShipped + ordersDone %></span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/deposit?action=my" class="side-link">
                    <i class="fa fa-shield"></i> 我的押金
                </a></li>
                <li><a href="<%=ctx%>/payment?action=ledger" class="side-link">
                    <i class="fa fa-list-alt"></i> 账户流水
                </a></li>
                <li><a href="<%=ctx%>/order?action=list&role=seller" class="side-link">
                    卖出订单（卖家）
                    <% if (sellerOrdersToShip > 0) { %>
                        <span class="cp-badge"><%= sellerOrdersToShip %></span>
                    <% } else { %>
                        <span class="cp-badge gray">0</span>
                    <% } %>
                </a></li>
            </ul>
        </div>

        <!-- My Favorites -->
        <div class="side-group">
            <div class="side-group-title" onclick="toggleGroup(this)">
                <i class="fa fa-heart-o"></i>
                <span>// 我的收藏</span>
                <i class="fa fa-angle-down arrow"></i>
            </div>
            <ul class="side-list">
                <li><a href="<%=ctx%>/favorite?action=list" class="side-link">
                    我的收藏
                    <% if (favoritesCount != null && favoritesCount > 0) { %>
                        <span class="cp-badge"><%= favoritesCount %></span>
                    <% } else { %>
                        <span class="cp-badge gray">0</span>
                    <% } %>
                </a></li>
                <li><a href="javascript:void(0)" onclick="toast('关注的卖家开发中', 'info')" class="side-link">
                    关注的卖家
                    <span class="cp-badge gray">0</span>
                </a></li>
            </ul>
        </div>

        <!-- Account Settings -->
        <div class="side-group">
            <div class="side-group-title" onclick="toggleGroup(this)">
                <i class="fa fa-cog"></i>
                <span>// 账户设置</span>
                <i class="fa fa-angle-down arrow"></i>
            </div>
            <ul class="side-list">
                <li><a href="javascript:void(0)" onclick="toast('个人资料编辑开发中', 'info')" class="side-link">个人资料</a></li>
                <li><a href="javascript:void(0)" onclick="toast('账号安全开发中', 'info')" class="side-link">账号安全</a></li>
                <li><a href="<%=ctx%>/address?action=list" class="side-link">
                    收货地址
                    <% if (addressCount != null && addressCount > 0) { %>
                        <span class="cp-badge"><%= addressCount %></span>
                    <% } else { %>
                        <span class="cp-badge gray">0</span>
                    <% } %>
                </a></li>
                <li><a href="<%=ctx%>/credit?action=list" class="side-link">
                    <i class="fa fa-star-o"></i> 我的评价
                </a></li>
            </ul>
        </div>
    </aside>

    
    <main class="content">
        <% if (error != null) { %>
        <div class="alert alert-warning">
            <i class="fa fa-exclamation-circle"></i> 错误 // <%= error %>
        </div>
        <% } %>

        <!-- 个人资料 CARD -->
        <div class="profile-card">
            <div class="profile-avatar">
                <%= user.getUsername() != null && !user.getUsername().isEmpty()
                    ? user.getUsername().substring(0, 1).toUpperCase() : "?" %>
            </div>
            <div class="profile-info">
                <div class="profile-name">
                    <%= user.getUsername() %>
                    <span class="hello">// 欢迎回来</span>
                </div>
                <div class="profile-tags">
                    <span class="profile-tag"><i class="fa fa-star"></i> 信用分 <%= user.getCreditScore() %></span>
                    <span class="profile-tag"><i class="fa fa-trophy"></i> 信用优秀</span>
                    <% if (user.getPhone() != null && !user.getPhone().isEmpty()) { %>
                        <span class="profile-tag"><i class="fa fa-phone"></i> 已认证</span>
                    <% } %>
                </div>
                <div class="profile-meta">
                    <span><i class="fa fa-calendar"></i> 注册于
                        <%= user.getRegisterTime() == null ? "-" : user.getRegisterTime().toString().substring(0, 10) %>
                    </span>
                    <span><i class="fa fa-users"></i> 0 粉丝</span>
                    <span><i class="fa fa-eye"></i> 0 关注的卖家</span>
                </div>
            </div>
            <div class="profile-actions">
                <a href="<%=ctx%>/item?action=publish-page" class="profile-action">
                    <i class="fa fa-plus"></i> 发布拍品
                </a>
                <a href="javascript:void(0)" onclick="toast('编辑资料开发中', 'info')" class="profile-action outline">
                    <i class="fa fa-pencil"></i> 编辑资料
                </a>
            </div>
        </div>

        <!-- TODO BAR -->
        <% if (ordersPending > 0) { %>
        <div class="todo-bar">
            <i class="fa fa-bell"></i>
            您有 <strong><%= ordersPending %></strong> 笔订单待付款
            <a href="<%=ctx%>/order?action=list&role=buyer&status=0" class="todo-link">立即处理 →</a>
        </div>
        <% } %>
        <% if (sellerOrdersToShip > 0) { %>
        <div class="todo-bar">
            <i class="fa fa-truck"></i>
            您有 <strong><%= sellerOrdersToShip %></strong> 笔订单待发货
            <a href="<%=ctx%>/order?action=list&role=seller&status=1" class="todo-link">立即发货 →</a>
        </div>
        <% } %>

        <!-- 4 CORE STATS -->
        <div class="core-stats">
            <a href="<%=ctx%>/item?action=my-items" class="cp-kpi-card">
                <div class="cp-kpi-icon"><i class="fa fa-gavel"></i></div>
                <div class="cp-kpi-body">
                    <div class="cp-kpi-value"><%= sellerStats.get("total") == null ? 0 : sellerStats.get("total") %></div>
                    <div class="cp-kpi-label">我的发布</div>
                </div>
            </a>
            <a href="<%=ctx%>/item?action=my-bids" class="cp-kpi-card">
                <div class="cp-kpi-icon"><i class="fa fa-hand-paper-o"></i></div>
                <div class="cp-kpi-body">
                    <div class="cp-kpi-value"><%= myBidsCount %></div>
                    <div class="cp-kpi-label">我的出价</div>
                </div>
            </a>
            <a href="<%=ctx%>/order?action=list&role=buyer" class="cp-kpi-card">
                <div class="cp-kpi-icon"><i class="fa fa-list-alt"></i></div>
                <div class="cp-kpi-body">
                    <div class="cp-kpi-value"><%= ordersPending + ordersPaid + ordersShipped + ordersDone %></div>
                    <div class="cp-kpi-label">我的订单</div>
                </div>
            </a>
            <a href="<%=ctx%>/favorite?action=list" class="cp-kpi-card">
                <div class="cp-kpi-icon"><i class="fa fa-heart"></i></div>
                <div class="cp-kpi-body">
                    <div class="cp-kpi-value"><%= favoritesCount %></div>
                    <div class="cp-kpi-label">我的收藏</div>
                </div>
            </a>
        </div>

        
        <div class="cp-card">
            <div class="cp-card-head">
                <div class="cp-card-title">MY 我的订单（买家）</div>
                <a href="<%=ctx%>/order?action=list&role=buyer" class="cp-card-link">查看全部 →</a>
            </div>
            <div class="cp-order-grid">
                <a href="<%=ctx%>/order?action=list&role=buyer&status=0" class="cp-order-item">
                    <div class="cp-order-num <%= ordersPending > 0 ? "has" : "" %>">
                        <%= ordersPending %><% if (ordersPending > 0) { %><span class="cp-order-dot"></span><% } %>
                    </div>
                    <div class="cp-order-label">待付款</div>
                </a>
                <a href="<%=ctx%>/order?action=list&role=buyer&status=1" class="cp-order-item">
                    <div class="cp-order-num <%= ordersPaid > 0 ? "has" : "" %>">
                        <%= ordersPaid %>
                    </div>
                    <div class="cp-order-label">已付款</div>
                </a>
                <a href="<%=ctx%>/order?action=list&role=buyer&status=2" class="cp-order-item">
                    <div class="cp-order-num <%= ordersShipped > 0 ? "has" : "" %>">
                        <%= ordersShipped %>
                    </div>
                    <div class="cp-order-label">已发货</div>
                </a>
                <a href="<%=ctx%>/order?action=list&role=buyer&status=3" class="cp-order-item">
                    <div class="cp-order-num <%= ordersDone > 0 ? "has" : "" %>">
                        <%= ordersDone %>
                    </div>
                    <div class="cp-order-label">已收货</div>
                </a>
            </div>
        </div>

        
        <div class="cp-grid-section">
            <div class="cp-grid-tabs">
                <a href="javascript:void(0)" class="cp-grid-tab active" data-tab="active">
                    拍卖中 <span class="tab-num">(<%= sellerStats.get("active") == null ? 0 : sellerStats.get("active") %>)</span>
                </a>
                <a href="javascript:void(0)" class="cp-grid-tab" data-tab="sold">
                    已成交 <span class="tab-num">(<%= sellerStats.get("sold") == null ? 0 : sellerStats.get("sold") %>)</span>
                </a>
                <a href="javascript:void(0)" class="cp-grid-tab" data-tab="failed">
                    已流拍 <span class="tab-num">(<%= sellerStats.get("failed") == null ? 0 : sellerStats.get("failed") %>)</span>
                </a>
                <div class="cp-grid-head-right">
                    <a href="<%=ctx%>/item?action=publish-page">+ 发布新拍品</a>
                </div>
            </div>
            <div class="cp-grid-body">
                <!-- 4 number stats -->
                <div class="seller-stats" style="margin-bottom: 16px;">
                    <div class="seller-stat">
                        <div class="seller-stat-num"><%= sellerStats.get("total") == null ? 0 : sellerStats.get("total") %></div>
                        <div class="seller-stat-label">全部</div>
                    </div>
                    <div class="seller-stat">
                        <div class="seller-stat-num primary"><%= sellerStats.get("active") == null ? 0 : sellerStats.get("active") %></div>
                        <div class="seller-stat-label">拍卖中</div>
                    </div>
                    <div class="seller-stat">
                        <div class="seller-stat-num success"><%= sellerStats.get("sold") == null ? 0 : sellerStats.get("sold") %></div>
                        <div class="seller-stat-label">已成交</div>
                    </div>
                    <div class="seller-stat">
                        <div class="seller-stat-num muted"><%= sellerStats.get("failed") == null ? 0 : sellerStats.get("failed") %></div>
                        <div class="seller-stat-label">已流拍</div>
                    </div>
                </div>

                <!-- item grid (3 panels, tab-switched) -->
                <div class="tab-panel" data-panel="active">
                    <%= renderItemGrid(activeItems, ctx) %>
                </div>
                <div class="tab-panel" data-panel="sold" style="display:none;">
                    <%= renderItemGrid(soldItems, ctx) %>
                </div>
                <div class="tab-panel" data-panel="failed" style="display:none;">
                    <%= renderItemGrid(failedItems, ctx) %>
                </div>
            </div>
        </div>

    </main>

    <!-- 右侧浮动操作栏 -->
    <aside class="cp-floats">
        <a href="<%=ctx%>/item?action=publish-page" class="cp-float-btn primary" title="发布拍品">
            <i class="fa fa-plus"></i><span>发布</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('消息中心开发中', 'info')" class="cp-float-btn" title="消息">
            <i class="fa fa-envelope-o"></i><span>消息</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('APP 下载敬请期待', 'info')" class="cp-float-btn" title="APP">
            <i class="fa fa-mobile"></i><span>应用</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('反馈功能开发中', 'info')" class="cp-float-btn" title="反馈">
            <i class="fa fa-commenting-o"></i><span>反馈</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('客服：400-888-8888', 'info')" class="cp-float-btn" title="SUPPORT">
            <i class="fa fa-headphones"></i><span>客服</span>
        </a>
        <a href="javascript:void(0)" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" class="cp-float-btn" title="顶部" style="margin-top: auto;">
            <i class="fa fa-arrow-up"></i><span>顶部</span>
        </a>
    </aside>
</div>

<!-- 页脚 -->
<footer class="cp-footer">
    <div class="cp-footer-inner">
        // 2025 赛博拍卖系统 // JSP + SERVLET + MYBATIS + VUE
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // toggle sidebar group collapse/expand
    function toggleGroup(titleEl) {
        const group = titleEl.parentElement;
        group.classList.toggle('collapsed');
    }

    // item tab switching: 切换 tab + 显示对应拍品面板
    document.querySelectorAll('.cp-grid-tab').forEach(tab => {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.cp-grid-tab').forEach(t => t.classList.remove('active'));
            this.classList.add('active');
            const tabName = this.dataset.tab; // active / sold / failed
            document.querySelectorAll('.tab-panel').forEach(p => {
                p.style.display = (p.dataset.panel === tabName) ? '' : 'none';
            });
        });
    });
</script>
</body>
</html>
