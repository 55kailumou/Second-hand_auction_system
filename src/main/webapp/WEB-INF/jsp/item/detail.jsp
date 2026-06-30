<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    Integer categoryId  = (Integer) request.getAttribute("categoryId");
    String itemJson      = (String) request.getAttribute("itemJson");
    String bidsJson      = (String) request.getAttribute("bidsJson");
    String categoryJson  = (String) request.getAttribute("categoryJson");
    String sellerJson    = (String) request.getAttribute("sellerJson");
    String itemImagesJson= (String) request.getAttribute("itemImagesJson");
    String relatedItemsJson = (String) request.getAttribute("relatedItemsJson");
    Boolean loggedIn     = (Boolean) request.getAttribute("loggedIn");
    Boolean isOwner      = (Boolean) request.getAttribute("isOwner");
    Boolean active       = (Boolean) request.getAttribute("active");
    Boolean favorited    = (Boolean) request.getAttribute("favorited");
    String nextMinBid    = (String) request.getAttribute("nextMinBid");
    Integer currentUserId = currentUser == null ? null : currentUser.getId();
    // 顶部搜索框回显（避免嵌套引号问题）
    String kwParam = request.getParameter("kw");
    String kwValue = kwParam == null ? "" : kwParam;
    if (itemJson == null) itemJson = "null";
    if (bidsJson == null) bidsJson = "[]";
    if (categoryJson == null) categoryJson = "null";
    if (sellerJson == null) sellerJson = "null";
    if (itemImagesJson == null) itemImagesJson = "[]";
    if (relatedItemsJson == null) relatedItemsJson = "[]";
    if (loggedIn == null) loggedIn = false;
    if (isOwner == null) isOwner = false;
    if (active == null) active = false;
    if (favorited == null) favorited = false;
    if (nextMinBid == null) nextMinBid = "0";
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>拍品详情 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/cyberpunk.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * CYBERPUNK 2077 — 拍品详情
         * 暗黑霓虹主题 / 黄 / 青 / 红 三色
         * ============================================================ */

        /* ---------- 全局 ---------- */
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #000;
            color: #FFEE00;
            font-family: 'Sarasa Mono SC', 'Source Code Pro', monospace;
            line-height: 1.5;
            min-height: 100vh;
        }
        a { color: #00F0FF; text-decoration: none; transition: color 0.15s; }
        a:hover { color: #FFEE00; text-shadow: 0 0 6px #FFEE00; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: #0a0a0a; }
        ::-webkit-scrollbar-thumb { background: #00F0FF; border-radius: 3px; }

        /* ---------- 扫描线 ---------- */
        .scanline {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            pointer-events: none; z-index: 9999;
            background: repeating-linear-gradient(
                0deg,
                transparent, transparent 2px,
                rgba(0, 240, 255, 0.03) 2px, rgba(0, 240, 255, 0.03) 4px
            );
        }

        /* ---------- Nav ---------- */

        .cp-logo:hover { color: #FFEE00; text-shadow: 0 0 10px #FFEE00; }

        .cp-nav-search button:hover { background: #FFEE00; color: #000; }

        .nav-tags-label { flex-shrink: 0; }
        
        .cp-nav-tag:hover { color: #00F0FF; text-shadow: 0 0 6px #00F0FF; }
        .cp-nav-tag-hot { color: #FF003C; font-weight: 700; }
        .cp-nav-tag-hot:hover { color: #FF003C; text-shadow: 0 0 8px #FF003C; }

        .cp-nav-user .user-name-link { color: #00F0FF; font-weight: 500; }
        .cp-nav-user .user-name-link:hover { color: #FFEE00; }

        /* ---------- 主体包装 ---------- */
        .detail-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px; }

        /* ---------- 卖家信息条 ---------- */
        .seller-bar {
            background: #0d0d0d; border-radius: 2px;
            border: 1px solid rgba(0, 240, 255, 0.15);
            padding: 14px 20px;
            display: flex; align-items: center; gap: 14px;
            margin-bottom: 12px;
        }
        .seller-bar-avatar {
            width: 48px; height: 48px; border-radius: 2px;
            background: rgba(0, 240, 255, 0.1); color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.3);
            display: grid; place-items: center;
            font-size: 20px; font-weight: 700; flex-shrink: 0;
        }
        .seller-bar-info { flex: 1; min-width: 0; }
        .seller-bar-name {
            font-size: 15px; font-weight: 600; color: #FFEE00;
            margin-bottom: 4px;
            display: flex; align-items: center; gap: 6px;
        }
        .seller-bar-name .name-link { color: #00F0FF; }
        .seller-bar-name .name-link:hover { color: #FFEE00; text-shadow: 0 0 6px #FFEE00; }
        .seller-bar-name .credit-tag {
            font-size: 11px; padding: 1px 6px;
            background: rgba(0, 240, 255, 0.1); color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.3);
            border-radius: 2px; font-weight: 500;
        }
        .seller-bar-meta {
            display: flex; gap: 14px; font-size: 12px; color: rgba(255, 238, 0, 0.5);
        }
        .seller-bar-meta span { display: flex; align-items: center; gap: 3px; }
        .seller-bar-meta .sep { color: rgba(0, 240, 255, 0.2); }
        .seller-bar-actions { display: flex; gap: 8px; flex-shrink: 0; }
        .btn-chat {
            padding: 8px 18px; background: rgba(0, 240, 255, 0.08); color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.3); border-radius: 2px;
            font-size: 13px; font-weight: 600; cursor: pointer;
            display: flex; align-items: center; gap: 5px;
            transition: all 0.15s; font-family: 'Sarasa Mono SC', monospace;
        }
        .btn-chat:hover { background: #00F0FF; color: #000; border-color: #00F0FF; }
        .btn-follow {
            padding: 8px 18px; background: transparent; color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.3); border-radius: 2px;
            font-size: 13px; cursor: pointer; display: flex; align-items: center; gap: 5px;
            transition: all 0.15s; font-family: 'Sarasa Mono SC', monospace;
        }
        .btn-follow:hover { border-color: #FFEE00; color: #FFEE00; }

        /* ---------- 主体两栏：左图廊 + 右信息 ---------- */
        .detail-layout {
            display: grid; grid-template-columns: 1fr 460px; gap: 16px;
            align-items: start;
        }
        @media (max-width: 1024px) {
            .detail-layout { grid-template-columns: 1fr; }
        }

        /* ---------- 左侧：图廊 + 描述 + 规格 ---------- */
        .cp-gallery-thumbs {
            display: flex; flex-direction: column; gap: 6px;
            max-height: 500px; overflow-y: auto;
        }
        .cp-gallery-thumbs::-webkit-scrollbar { width: 4px; }
        .cp-gallery-thumbs::-webkit-scrollbar-thumb { background: rgba(0, 240, 255, 0.2); border-radius: 2px; }
        .cp-gallery-thumb {
            width: 72px; height: 72px; border-radius: 2px;
            background: #0a0a0a; cursor: pointer; overflow: hidden;
            border: 1px solid rgba(0, 240, 255, 0.12);
            display: grid; place-items: center; flex-shrink: 0;
            transition: border-color 0.15s;
        }
        .cp-gallery-thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }
        .cp-gallery-thumb i { font-size: 22px; color: rgba(0, 240, 255, 0.2); }
        .cp-gallery-thumb.active { border-color: #00F0FF; box-shadow: 0 0 8px rgba(0, 240, 255, 0.2); }

        .cp-gallery-main {
            aspect-ratio: 1; background: #0a0a0a;
            border-radius: 2px; overflow: hidden;
            display: grid; place-items: center;
            position: relative;
        }
        .cp-gallery-main img { width: 100%; height: 100%; object-fit: contain; display: block; }
        .cp-gallery-main i { font-size: 80px; color: rgba(0, 240, 255, 0.12); }
        .cp-gallery-main .placeholder-text {
            position: absolute; bottom: 16px; left: 50%; transform: translateX(-50%);
            color: rgba(255, 238, 0, 0.4); font-size: 13px;
        }
        /* ---------- 通用卡片 ---------- */
        .cp-card {
            background: #0d0d0d; border-radius: 2px;
            border: 1px solid rgba(0, 240, 255, 0.12);
            padding: 20px 24px;
        }

        /* 图廊卡（特殊布局：左缩略 + 右大图） */
        .cp-card.gallery-card {
            display: grid;
            grid-template-columns: 80px 1fr; gap: 12px;
            padding: 16px;
        }

        /* ---------- 描述卡 ---------- */
        .cp-card-title {
            font-size: 15px; font-weight: 600;
            margin-bottom: 14px; display: flex; align-items: center; gap: 8px;
            color: #FFEE00;
        }
        .cp-card-title::before {
            content: ''; display: inline-block; width: 3px; height: 16px;
            background: #00F0FF; border-radius: 2px;
            box-shadow: 0 0 6px #00F0FF;
        }
        .cp-card-content { font-size: 14px; line-height: 1.8; color: #FFEE00; white-space: pre-wrap; }

        .cp-spec-table {
            display: grid; grid-template-columns: 1fr 1fr; gap: 10px 24px;
            font-size: 13px;
        }
        .cp-spec-row { display: flex; gap: 8px; }
        .cp-spec-key { color: rgba(255, 238, 0, 0.45); flex-shrink: 0; min-width: 70px; }
        .cp-spec-val { color: #FFEE00; }

        /* ---------- 右侧：信息区（sticky） ---------- */
        .cp-info-col { position: sticky; top: 72px; display: flex; flex-direction: column; gap: 12px; }
        @media (max-width: 1024px) { .cp-info-col { position: static; } }

        /*
         * 以下 .badge / .badge-* 由 Vue computed 属性 statusBadgeClass 直接返回类名字符串，
         * 故保留原类名，仅覆盖为赛博朋克配色。
         */
        .badge {
            padding: 3px 10px; border-radius: 2px; font-size: 12px; font-weight: 600;
            display: inline-flex; align-items: center; gap: 4px;
            border: 1px solid; letter-spacing: 0.3px;
        }
        .badge-primary { background: rgba(0, 240, 255, 0.1); color: #00F0FF; border-color: rgba(0, 240, 255, 0.3); }
        .badge-success { background: rgba(0, 255, 65, 0.1);  color: #00FF41; border-color: rgba(0, 255, 65, 0.3); }
        .badge-warning { background: rgba(255, 238, 0, 0.1); color: #FFEE00; border-color: rgba(255, 238, 0, 0.3); }
        .badge-danger  { background: rgba(255, 0, 60, 0.1);  color: #FF003C; border-color: rgba(255, 0, 60, 0.3); }
        .badge-info    { background: rgba(0, 240, 255, 0.08); color: #00F0FF; border-color: rgba(0, 240, 255, 0.2); }

        .cp-info-status-row {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 12px;
        }
        .cp-info-status-row .left { display: flex; gap: 6px; align-items: center; }

        .cp-info-meta-right { font-size: 12px; color: rgba(255, 238, 0, 0.45); }
        .cp-info-meta-right i { margin-right: 3px; }

        .cp-price-row {
            display: flex; align-items: baseline; gap: 10px;
            margin-bottom: 8px;
        }
        .cp-price-current {
            font-size: 32px; font-weight: 800; color: #00F0FF; line-height: 1;
        }
        .cp-price-current small { font-size: 16px; font-weight: 600; margin-right: 2px; }
        .cp-price-tag {
            padding: 2px 8px; font-size: 11px;
            background: rgba(0, 240, 255, 0.08); color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.3); border-radius: 2px;
        }

        .cp-info-title {
            font-size: 16px; font-weight: 500; line-height: 1.6;
            color: #FFEE00; margin: 12px 0 14px;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* 规格简表 */
        .cp-spec-compact {
            display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px;
            font-size: 12px; margin-bottom: 14px;
            padding: 12px 14px; background: #0a0a0a; border-radius: 2px;
            border: 1px solid rgba(0, 240, 255, 0.08);
        }
        .cp-spec-compact .cp-spec-key { min-width: 50px; }
        .cp-spec-compact .cp-spec-val { color: #00F0FF; font-weight: 500; }

        /* 倒计时 */
        .cp-countdown-block {
            background: rgba(0, 240, 255, 0.04); border: 1px dashed rgba(0, 240, 255, 0.25);
            border-radius: 2px; padding: 12px 16px; margin-bottom: 12px;
            text-align: center;
        }
        .cp-countdown-block.urgent { border-color: #FF003C; background: rgba(255, 0, 60, 0.08); }
        .cp-countdown-block.ended { border-color: rgba(255, 238, 0, 0.15); background: rgba(40, 40, 40, 0.5); }
        .cp-countdown-label { font-size: 12px; color: rgba(255, 238, 0, 0.45); margin-bottom: 4px; }
        .cp-countdown-time {
            font-size: 22px; font-weight: 700; color: #00F0FF;
            font-family: 'Sarasa Mono SC', monospace; letter-spacing: 2px;
        }
        .cp-countdown-block.urgent .cp-countdown-time { color: #FF003C; text-shadow: 0 0 8px #FF003C; }
        .cp-countdown-block.ended .cp-countdown-time { color: rgba(255, 238, 0, 0.3); font-size: 16px; }

        /* 出价区 */
        .cp-bid-area { margin-bottom: 12px; }
        .cp-bid-label { font-size: 12px; color: rgba(255, 238, 0, 0.5); margin-bottom: 6px; }
        .cp-bid-row { display: flex; gap: 8px; align-items: stretch; }
        .cp-bid-input {
            flex: 1; padding: 11px 14px;
            border: 1px solid rgba(0, 240, 255, 0.25);
            border-radius: 2px; font-size: 16px; outline: none;
            transition: border-color 0.15s; background: #0a0a0a;
            min-width: 0; color: #00F0FF;
            font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-bid-input:focus { border-color: #00F0FF; box-shadow: 0 0 8px rgba(0, 240, 255, 0.15); }
        .cp-bid-input::placeholder { color: rgba(0, 240, 255, 0.25); }

        .cp-btn {
            padding: 11px 22px; background: #00F0FF; color: #000;
            font-size: 14px; font-weight: 700; border-radius: 2px;
            border: 1px solid #00F0FF; cursor: pointer; transition: all 0.15s;
            white-space: nowrap; font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-btn:hover:not(:disabled) { background: #FFEE00; border-color: #FFEE00; color: #000; }
        .cp-btn:disabled { opacity: 0.5; cursor: not-allowed; }

        .cp-bid-hint { font-size: 11px; color: rgba(255, 238, 0, 0.4); margin-top: 4px; }
        .cp-bid-shortcut { display: flex; gap: 4px; margin-top: 6px; flex-wrap: wrap; }

        .cp-btn-sm {
            padding: 2px 8px; font-size: 11px;
            background: transparent; color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.3); border-radius: 2px;
            cursor: pointer; transition: all 0.15s;
            font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-btn-sm:hover { background: rgba(0, 240, 255, 0.1); color: #FFEE00; border-color: #00F0FF; }

        .cp-bid-action-row {
            display: flex; gap: 8px; margin-top: 8px;
        }
        .cp-btn-secondary {
            flex: 1; padding: 10px 0; background: transparent; color: #00F0FF;
            border: 1px solid rgba(0, 240, 255, 0.2); border-radius: 2px;
            font-size: 13px; cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; justify-content: center; gap: 5px;
            font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-btn-secondary:hover { border-color: #00F0FF; color: #FFEE00; }
        .cp-btn-secondary.danger:hover { border-color: #FF003C; color: #FF003C; }

        .cp-info-footer {
            margin-top: 14px; padding-top: 12px;
            border-top: 1px solid rgba(0, 240, 255, 0.1);
            display: flex; align-items: center; gap: 12px;
            font-size: 12px; color: rgba(255, 238, 0, 0.45);
        }
        .cp-info-footer a { color: rgba(255, 238, 0, 0.5); }
        .cp-info-footer a:hover { color: #00F0FF; }

        /* 出价历史卡 */
        .cp-bids-head {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 14px;
        }
        .cp-bids-list { max-height: 360px; overflow-y: auto; }
        .cp-bids-list::-webkit-scrollbar { width: 4px; }
        .cp-bids-list::-webkit-scrollbar-thumb { background: rgba(0, 240, 255, 0.2); border-radius: 2px; }
        .cp-bid-row-item {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 0; border-bottom: 1px solid rgba(0, 240, 255, 0.06);
        }
        .cp-bid-row-item:last-child { border-bottom: none; }

        .cp-bid-rank {
            display: inline-grid; place-items: center;
            width: 22px; height: 22px; border-radius: 2px;
            background: rgba(255, 238, 0, 0.08); color: rgba(255, 238, 0, 0.5);
            font-size: 11px; font-weight: 700; flex-shrink: 0;
        }
        .cp-bid-rank.gold   { background: #FFEE00; color: #000; }
        .cp-bid-rank.silver { background: rgba(255, 238, 0, 0.2); color: #FFEE00; }
        .cp-bid-rank.bronze { background: rgba(255, 0, 60, 0.25); color: #FF003C; }

        .cp-bid-user { flex: 1; min-width: 0; font-size: 13px; }
        .cp-bid-user .u-name {
            display: flex; align-items: center; gap: 4px;
        }
        .cp-bid-user .u-name .crown { color: #FFEE00; font-size: 12px; text-shadow: 0 0 4px #FFEE00; }
        .cp-bid-user .u-time { font-size: 11px; color: rgba(255, 238, 0, 0.4); margin-top: 2px; }
        .cp-bid-amount {
            font-size: 15px; font-weight: 700; color: #00F0FF;
            text-align: right; flex-shrink: 0;
        }

        .cp-bids-empty {
            text-align: center; padding: 30px; color: rgba(255, 238, 0, 0.35); font-size: 13px;
        }
        .cp-bids-empty i { font-size: 32px; opacity: 0.2; margin-bottom: 6px; display: block; }

        /* 提示条 */
        .cp-info-note {
            padding: 10px 14px; border-radius: 2px;
            font-size: 13px; margin-bottom: 12px;
            display: flex; align-items: center; gap: 8px;
            border: 1px solid;
        }
        .cp-info-note-warning { background: rgba(255, 238, 0, 0.06); color: #FFEE00; border-color: rgba(255, 238, 0, 0.2); }
        .cp-info-note-info    { background: rgba(0, 240, 255, 0.06); color: #00F0FF; border-color: rgba(0, 240, 255, 0.2); }

        /* 卖家专属操作按钮 */
        .cp-owner-actions { display: flex; gap: 8px; margin-top: 10px; }
        .cp-owner-btn {
            flex: 1; padding: 10px 16px; border-radius: 2px;
            font-size: 13px; font-weight: 600; cursor: pointer;
            text-decoration: none; text-align: center;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            transition: all 0.15s; border: 1px solid transparent;
            font-family: 'Sarasa Mono SC', monospace;
        }
        .cp-owner-btn-edit { background: transparent; color: #00F0FF; border-color: #00F0FF; }
        .cp-owner-btn-edit:hover { background: #00F0FF; color: #000; }
        .cp-owner-btn-offline { background: transparent; color: #FF003C; border-color: #FF003C; }
        .cp-owner-btn-offline:hover { background: #FF003C; color: #000; }

        /* 空 / 加载失败 */
        .cp-empty {
            text-align: center; padding: 80px 20px; color: rgba(255, 238, 0, 0.35);
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.12);
            border-radius: 2px;
        }
        .cp-empty i { font-size: 48px; opacity: 0.2; margin-bottom: 8px; display: block; }

        /* 为你推荐 */
        .cp-recommend-head {
            display: flex; align-items: baseline; justify-content: space-between;
            margin-bottom: 14px;
        }
        .cp-recommend-title { font-size: 16px; font-weight: 700; color: #FFEE00; }
        .cp-recommend-link { font-size: 12px; color: rgba(255, 238, 0, 0.5); }
        .cp-recommend-link:hover { color: #00F0FF; }

        .cp-goods-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
        }
        @media (max-width: 1200px) { .cp-goods-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .cp-goods-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .cp-goods-grid { grid-template-columns: repeat(3, 1fr); } }

        .cp-goods-card {
            background: #0d0d0d; border: 1px solid rgba(0, 240, 255, 0.12);
            border-radius: 2px; overflow: hidden; cursor: pointer;
            transition: all 0.15s; text-decoration: none; color: inherit;
        }
        .cp-goods-card:hover {
            border-color: #00F0FF;
            transform: translateY(-2px);
            box-shadow: 0 0 16px rgba(0, 240, 255, 0.15);
        }

        .cp-goods-cover {
            width: 100%; aspect-ratio: 1; background: #0a0a0a;
            display: grid; place-items: center; position: relative;
        }
        .cp-goods-cover i { font-size: 30px; color: rgba(0, 240, 255, 0.12); }
        .cp-goods-cover .cp-goods-price-tag {
            position: absolute; bottom: 4px; left: 4px; right: 4px;
            background: rgba(0, 0, 0, 0.85);
            color: #00F0FF; font-size: 11px; font-weight: 600; padding: 3px 6px;
            text-align: center; border: 1px solid rgba(0, 240, 255, 0.15);
        }
        .cp-goods-body { padding: 6px 8px 8px; }
        .cp-goods-title {
            font-size: 12px; line-height: 1.4; min-height: 32px;
            color: #FFEE00;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* 右侧浮动操作栏 */
        .cp-floats {
            position: fixed; right: 16px; top: 50%; transform: translateY(-50%);
            display: flex; flex-direction: column; gap: 6px; z-index: 50;
        }
        .cp-float-btn {
            width: 40px; height: 40px; background: #0d0d0d;
            border: 1px solid rgba(0, 240, 255, 0.15); border-radius: 2px;
            display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            color: #00F0FF; box-shadow: 0 0 6px rgba(0, 240, 255, 0.05);
            transition: all 0.15s; cursor: pointer; font-size: 10px; gap: 1px;
            text-decoration: none; border: 1px solid rgba(0, 240, 255, 0.15);
        }
        .cp-float-btn i { font-size: 14px; }
        .cp-float-btn:hover { background: #00F0FF; color: #000; transform: translateY(-1px); box-shadow: 0 0 12px #00F0FF; }
        .cp-float-btn.primary { background: #00F0FF; color: #000; border-color: #00F0FF; }
        @media (max-width: 1200px) { .cp-floats { display: none; } }

        /* 页脚 */
        .detail-footer {
            background: #050505; color: rgba(255, 238, 0, 0.4);
            border-top: 1px solid rgba(0, 240, 255, 0.1);
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .detail-footer-inner { max-width: 1200px; margin: 0 auto; color: rgba(255, 238, 0, 0.25); }

        [v-cloak] { display: none; }
    </style>
</head>
<body>

<div class="scanline" aria-hidden="true"></div>

<!-- ========== 顶 nav ========== -->
<header class="cp-nav">
    <div class="cp-nav-inner">
        <a href="<%=ctx%>/index.jsp" class="cp-logo">
            <span class="cp-logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="cp-nav-menu">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/item?action=hot-ranks">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="<%=ctx%>/user?action=center">个人中心</a>
            <% } %>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="cp-nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ..."
                   value="<%= kwValue %>">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="cp-nav-tags">
            <span class="nav-tags-label">热搜：</span>
            <a href="<%=ctx%>/item/list?keyword=iPhone" class="cp-nav-tag cp-nav-tag-hot">iPhone 15</a>
            <a href="<%=ctx%>/item/list?keyword=相机" class="cp-nav-tag">佳能相机</a>
            <a href="<%=ctx%>/item/list?keyword=球鞋" class="cp-nav-tag">球鞋</a>
            <a href="<%=ctx%>/item/list?keyword=茅台" class="cp-nav-tag cp-nav-tag-hot">茅台</a>
        </div>
        <div class="cp-nav-user">
            <% if (currentUser != null) { %>
                <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= currentUser.getUsername() %></a>
                <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: rgba(255,238,0,0.5);">退出</a>
                <a href="<%=ctx%>/user?action=center" class="avatar"><%= currentUser.getUsername().substring(0, 1).toUpperCase() %></a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" style="font-size: 13px; padding: 6px 12px; color: #00F0FF; border: 1px solid #00F0FF; border-radius: 2px;">登录</a>
                <a href="<%=ctx%>/user?action=register" style="font-size: 13px; padding: 6px 12px; color: #000; background: #00F0FF; border-radius: 2px;">注册</a>
            <% } %>
        </div>
    </div>
</header>

<div class="detail-wrap" id="app" v-cloak>

    <!-- ========== 卖家信息条（仿闲鱼） ========== -->
    <div v-if="item" class="seller-bar">
        <div class="seller-bar-avatar">{{ sellerInitial }}</div>
        <div class="seller-bar-info">
            <div class="seller-bar-name">
                <a href="javascript:void(0)" class="name-link">{{ seller ? seller.username : '匿名卖家' }}</a>
                <span class="credit-tag" v-if="seller && seller.creditScore >= 90">信用优秀</span>
            </div>
            <div class="seller-bar-meta">
                <span v-if="seller"><i class="fa fa-map-marker"></i> 北京</span>
                <span class="sep">|</span>
                <span><i class="fa fa-clock-o"></i> 25 分钟前来过</span>
                <span class="sep">|</span>
                <span><i class="fa fa-calendar"></i> 来闲鱼 {{ sellerDays }} 天</span>
                <span class="sep">|</span>
                <span><i class="fa fa-gavel"></i> 卖出 {{ seller ? (seller.soldCount || 0) : 0 }} 件</span>
                <span class="sep">|</span>
                <span><i class="fa fa-thumbs-up"></i> 好评率 100%</span>
            </div>
        </div>
        <div class="seller-bar-actions">
            <button class="btn-chat" @click="onChat">
                <i class="fa fa-commenting-o"></i> 私聊
            </button>
            <button class="btn-follow" @click="onFollow">
                <i class="fa fa-plus"></i> 关注
            </button>
        </div>
    </div>

    <!-- ========== 主体两栏 ========== -->
    <div v-if="item" class="detail-layout">
        <!-- 左侧：图廊 + 描述 + 规格 -->
        <div>
            <!-- 图廊 -->
            <div class="cp-card gallery-card">
                <div class="cp-gallery-thumbs" v-if="galleryImages.length > 0">
                    <div v-for="(img, idx) in galleryImages" :key="idx"
                         :class="['cp-gallery-thumb', { active: currentImageIdx === idx }]"
                         @click="currentImageIdx = idx">
                        <img v-if="img" :src="img" :alt="'图' + (idx+1)" @error="onImgError($event)">
                        <i v-else class="fa fa-image"></i>
                    </div>
                </div>
                <div v-else class="cp-gallery-thumbs">
                    <div class="cp-gallery-thumb active">
                        <i class="fa fa-image"></i>
                    </div>
                </div>
                <div class="cp-gallery-main">
                    <img v-if="currentImage" :src="currentImage" :alt="item.title" @error="onImgError($event)">
                    <i v-else class="fa fa-image"></i>
                </div>
            </div>

            <!-- 拍品描述 -->
            <div class="cp-card" style="margin-top:12px;">
                <div class="cp-card-title">拍品描述</div>
                <div class="cp-card-content">{{ item.description || '卖家未填写详细描述' }}</div>
            </div>

            <!-- 规格参数 -->
            <div class="cp-card" style="margin-top:12px;">
                <div class="cp-card-title">规格参数</div>
                <div class="cp-spec-table">
                    <div class="cp-spec-row"><span class="cp-spec-key">品牌：</span><span class="cp-spec-val">{{ item.brand || '-' }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">型号：</span><span class="cp-spec-val">{{ item.model || '-' }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">成色：</span><span class="cp-spec-val">{{ item.conditionLevel || '-' }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">瑕疵：</span><span class="cp-spec-val">{{ item.flawDesc || '无' }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">起拍价：</span><span class="cp-spec-val">¥{{ formatPrice(item.startPrice) }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">加价幅度：</span><span class="cp-spec-val">¥{{ formatPrice(item.bidIncrement) }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">开始时间：</span><span class="cp-spec-val">{{ formatDateTime(item.startTime) }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">结束时间：</span><span class="cp-spec-val">{{ formatDateTime(item.endTime) }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">分类：</span><span class="cp-spec-val">{{ category ? category.categoryName : '-' }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">浏览数：</span><span class="cp-spec-val">{{ item.viewCount || 0 }}</span></div>
                </div>
            </div>
        </div>

        <!-- 右侧：信息 + 出价 -->
        <div class="cp-info-col">
            <div class="cp-card">
                <!-- 状态 + 浏览数 -->
                <div class="cp-info-status-row">
                    <div class="left">
                        <span :class="statusBadgeClass">
                            <i v-if="active" class="fa fa-gavel"></i>
                            <i v-else-if="item.status === 2" class="fa fa-check-circle"></i>
                            <i v-else class="fa fa-clock-o"></i>
                            {{ statusLabel }}
                        </span>
                        <span class="badge badge-info" v-if="item.conditionLevel">{{ item.conditionLevel }}</span>
                    </div>
                    <div class="cp-info-meta-right">
                        <i class="fa fa-eye"></i> {{ item.viewCount || 0 }} 浏览
                    </div>
                </div>

                <!-- 价格 -->
                <div class="cp-price-row">
                    <div class="cp-price-current">
                        <small>¥</small>{{ formatPrice(item.currentPrice) }}
                    </div>
                    <span class="cp-price-tag"><i class="fa fa-truck"></i> 包邮</span>
                </div>

                <!-- 标题 -->
                <h1 class="cp-info-title">{{ item.title }}</h1>

                <!-- 规格简表 -->
                <div class="cp-spec-compact">
                    <div class="cp-spec-row" v-if="item.brand"><span class="cp-spec-key">品牌</span><span class="cp-spec-val">{{ item.brand }}</span></div>
                    <div class="cp-spec-row" v-if="item.model"><span class="cp-spec-key">型号</span><span class="cp-spec-val">{{ item.model }}</span></div>
                    <div class="cp-spec-row" v-if="category"><span class="cp-spec-key">分类</span><span class="cp-spec-val">{{ category.categoryName }}</span></div>
                    <div class="cp-spec-row"><span class="cp-spec-key">浏览</span><span class="cp-spec-val">{{ item.viewCount || 0 }}</span></div>
                </div>

                <!-- 倒计时 -->
                <div :class="['cp-countdown-block', { urgent: isUrgent, ended: !active && item.status !== 2 }]">
                    <div class="cp-countdown-label">
                        <span v-if="active">距结束</span>
                        <span v-else-if="item.status === 2">已成交</span>
                        <span v-else>已结束</span>
                    </div>
                    <div class="cp-countdown-time">{{ countdownText }}</div>
                </div>

                <!-- 出价区 -->
                <div v-if="isOwner">
                    <div class="cp-info-note cp-info-note-info">
                        <i class="fa fa-info-circle"></i> 这是您自己发布的拍品，不能出价
                    </div>
                    <!-- 卖家专属操作按钮（编辑/撤拍） -->
                    <div class="cp-owner-actions" v-if="canEdit || canOffline">
                        <a v-if="canEdit" :href="'<%=ctx%>/item?action=edit-page&id=' + item.id" class="cp-owner-btn cp-owner-btn-edit">
                            <i class="fa fa-pencil"></i> 编辑拍品
                        </a>
                        <button v-if="canOffline" type="button" class="cp-owner-btn cp-owner-btn-offline" @click="offlineItem">
                            <i class="fa fa-trash-o"></i> 撤拍
                        </button>
                    </div>
                </div>
                <div v-else-if="!loggedIn">
                    <a :href="loginUrl" class="cp-btn" style="display: block; text-align: center; text-decoration: none;">
                        <i class="fa fa-sign-in"></i> 登录后参与竞拍
                    </a>
                </div>
                <div v-else-if="!active && item.status === 2" :class="['cp-info-note', isWinner ? 'cp-info-note-info' : 'cp-info-note-warning']" style="display: flex; flex-direction: column; align-items: flex-start; gap: 8px;">
                    <div>
                        <i class="fa fa-check-circle"></i>
                        <span v-if="isWinner">恭喜您中拍了！请尽快下单完成付款</span>
                        <span v-else>本场拍卖已成交</span>
                    </div>
                    <a v-if="isWinner" :href="ctxPath + '/order?action=create&itemId=' + item.id" class="cp-btn"
                       style="display: inline-block; text-decoration: none; padding: 10px 20px; font-size: 14px;"
                       onclick="event.preventDefault(); createOrderNow();">
                        <i class="fa fa-shopping-cart"></i> 立即下单
                    </a>
                </div>
                <div v-else-if="!active" class="cp-info-note cp-info-note-warning">
                    <i class="fa fa-clock-o"></i> 本场拍卖已结束，无法再出价
                </div>
                <div v-else>
                    <!-- 押金提示（如果有押金时显示） -->
                    <div v-if="item.deposit && parseFloat(item.deposit) > 0" :class="['cp-info-note', depositPaid ? 'cp-info-note-info' : 'cp-info-note-warning']" style="margin-bottom: 12px;">
                        <i :class="['fa', depositPaid ? 'fa-check-circle' : 'fa-shield']"></i>
                        <div style="flex: 1;">
                            <div v-if="depositPaid">
                                <span style="color: #00F0FF; font-weight: 600;">已缴纳押金 ¥{{ formatPrice(item.deposit) }}</span>
                                <span style="font-size: 12px; opacity: 0.7; margin-left: 6px;">出价资格已激活</span>
                            </div>
                            <div v-else>
                                <div>本拍品需缴纳押金 <span style="color: #FFEE00; font-weight: 700;">¥{{ formatPrice(item.deposit) }}</span> 才能出价</div>
                                <a :href="ctxPath + '/deposit?action=checkout&itemId=' + item.id"
                                   class="cp-btn" style="margin-top: 8px; padding: 8px 16px; font-size: 13px; display: inline-block; text-decoration: none;">
                                    <i class="fa fa-shield"></i> 立即缴纳押金
                                </a>
                            </div>
                        </div>
                    </div>

                    <div class="cp-bid-area">
                    <div class="cp-bid-label">您的出价（最低 ¥{{ nextMinBid }}）</div>
                    <div class="cp-bid-row">
                        <input type="number" class="cp-bid-input" v-model.number="bidAmount"
                               :min="nextMinBid" :step="item.bidIncrement"
                               :placeholder="'至少 ' + nextMinBid">
                        <button class="cp-btn" :disabled="bidding" @click="placeBid">
                            {{ bidding ? '出价中...' : '立即出价' }}
                        </button>
                    </div>
                    <div class="cp-bid-shortcut">
                        <span class="cp-btn-sm" @click="addQuickBid(0)">起拍价</span>
                        <span class="cp-btn-sm" @click="addQuickBid(1)">+1 步</span>
                        <span class="cp-btn-sm" @click="addQuickBid(3)">+3 步</span>
                        <span class="cp-btn-sm" @click="addQuickBid(5)">+5 步</span>
                    </div>
                    </div>
                </div>

                <!-- 次级操作 -->
                <div class="cp-bid-action-row">
                    <button class="cp-btn-secondary" @click="onFavorite" :disabled="favoriting"
                            :title="canFavorite ? '' : (isOwner ? '不能收藏自己发布的拍品' : '请先登录')">
                        <i :class="['fa', favorited ? 'fa-heart' : 'fa-heart-o']"
                           :style="favorited ? 'color: #ef4444;' : ''"></i>
                        {{ favorited ? '已收藏' : '收藏' }}
                    </button>
                    <button class="cp-btn-secondary" @click="onShare">
                        <i class="fa fa-share-alt"></i> 分享
                    </button>
                    <button class="cp-btn-secondary" title="举报该拍品"
                            onclick="window.location.href='<%=ctx%>/complaint?action=list&itemId=<%= request.getAttribute("itemId") %>'">
                        <i class="fa fa-flag"></i> 举报
                    </button>
                </div>

                <!-- 担保 / 担保说明 -->
                <div class="cp-info-footer">
                    <span><i class="fa fa-shield"></i> 担保交易</span>
                    <span style="font-size: 11px; opacity: 0.6;">如需投诉请在订单页操作</span>
                </div>
            </div>

            <!-- 出价历史 -->
            <div class="cp-card">
                <div class="cp-bids-head">
                    <div class="cp-card-title" style="margin-bottom: 0;">出价记录</div>
                    <span style="font-size: 12px; color: rgba(255,238,0,0.45);">
                        共 {{ bids.length }} 次 / {{ bidderCount }} 人
                    </span>
                </div>
                <div v-if="bids.length === 0" class="cp-bids-empty">
                    <i class="fa fa-inbox"></i>
                    暂无出价记录，赶快来抢沙发
                </div>
                <div v-else class="cp-bids-list">
                    <div v-for="(bid, idx) in bids" :key="bid.id" class="cp-bid-row-item">
                        <span :class="['cp-bid-rank', rankClass(idx)]">{{ idx + 1 }}</span>
                        <div class="cp-bid-user">
                            <div class="u-name">
                                <span>{{ '用户 #' + bid.bidderId }}</span>
                                <i v-if="bid.isWinning === 1" class="fa fa-crown crown" title="当前领先"></i>
                            </div>
                            <div class="u-time">{{ formatDateTime(bid.bidTime) }}</div>
                        </div>
                        <div class="cp-bid-amount">¥{{ formatPrice(bid.bidAmount) }}</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 加载失败 -->
    <div v-else class="cp-empty">
        <i class="fa fa-exclamation-circle"></i>
        <p>加载失败，请稍后再试</p>
    </div>

    <!-- ========== 为你推荐（★ Phase 4 改：动态加载同分类其他在拍） ========== -->
    <div class="cp-card" style="margin-top:16px;">
        <div class="cp-recommend-head">
            <div class="cp-recommend-title">同分类推荐</div>
            <a href="<%=ctx%>/item?action=list&categoryId=<%= categoryId %>" class="cp-recommend-link">查看更多 →</a>
        </div>
        <div class="cp-goods-grid" id="relatedItemsGrid">
            <%-- 由 relatedItemsJson + Vue 动态渲染 --%>
        </div>
    </div>

</div>

<!-- 浮动操作栏 -->
<aside class="cp-floats">
    <button class="cp-float-btn primary" title="发拍品" onclick="go('<%=ctx%>/item?action=publish-page')">
        <i class="fa fa-plus"></i><span>发布</span>
    </button>
    <button class="cp-float-btn" title="消息" onclick="toast('消息中心开发中', 'info')">
        <i class="fa fa-envelope-o"></i><span>消息</span>
    </button>
    <button class="cp-float-btn" title="APP" onclick="toast('APP 下载敬请期待', 'info')">
        <i class="fa fa-mobile"></i><span>APP</span>
    </button>
    <button class="cp-float-btn" title="反馈" onclick="toast('反馈功能开发中', 'info')">
        <i class="fa fa-commenting-o"></i><span>反馈</span>
    </button>
    <button class="cp-float-btn" title="客服" onclick="toast('客服：400-888-8888', 'info')">
        <i class="fa fa-headphones"></i><span>客服</span>
    </button>
    <button class="cp-float-btn" title="回顶部" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" style="margin-top: auto;">
        <i class="fa fa-arrow-up"></i><span>顶部</span>
    </button>
</aside>

<!-- 页脚 -->
<footer class="detail-footer">
    <div class="detail-footer-inner">
        © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
    </div>
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // 全局跳转
    function go(path) { window.location.href = path; }

    // 立即下单（中标者用）
    function createOrderNow() {
        const itemId = item ? item.id : null;
        if (!itemId) { alert('拍品 ID 缺失'); return; }
        // 1. 先查默认地址
        loadAxios().then(() => {
            axios.get(ctxPath + '/address', { params: { action: 'default' } })
                .then(r => {
                    const data = r.data;
                    if (!data.success) {
                        if (confirm('您还没有收货地址，是否前往添加？')) {
                            window.location.href = ctxPath + '/address?action=list&returnUrl=' +
                                encodeURIComponent(window.location.pathname + window.location.search);
                        }
                        return;
                    }
                    const addressText = data.addressText || '默认地址';
                    if (!confirm('使用以下地址下单？\n\n' + addressText + '\n\n点击确定即可创建订单。')) return;
                    // 2. 创建订单
                    axios.post(ctxPath + '/order?action=create', new URLSearchParams({
                        itemId: itemId,
                        addressId: data.addressId
                    })).then(r2 => {
                        if (r2.data.success) {
                            toast(r2.data.message || '下单成功', 'success');
                            setTimeout(() => {
                                window.location.href = ctxPath + '/order?action=list&role=buyer';
                            }, 800);
                        } else {
                            toast(r2.data.message || '下单失败', 'error');
                        }
                    }).catch(() => toast('网络错误', 'error'));
                })
                .catch(() => toast('查询地址失败', 'error'));
        });
    }

    const item       = <%= itemJson %>;
    const bids       = <%= bidsJson %>;
    const category   = <%= categoryJson %>;
    const seller     = <%= sellerJson %>;
    // item_images 表的图片列表（来自 ItemImageMapper.findByItemId）；为空则 fallback 到 item.coverImage / item.imageUrls
    const itemImages = <%= itemImagesJson %>;
    const relatedItems = <%= relatedItemsJson %>;

    // 渲染同分类推荐（vanilla JS，不依赖 Vue 挂载）
    (function() {
        const grid = document.getElementById('relatedItemsGrid');
        if (!grid) return;
        if (!relatedItems || relatedItems.length === 0) {
            grid.innerHTML = '<div style="grid-column: 1 / -1; text-align: center; padding: 30px 20px; color: rgba(255,238,0,0.4); font-size: 13px;">' +
                '<i class="fa fa-info-circle" style="opacity: 0.4;"></i> 同分类暂无其他在拍拍品</div>';
            return;
        }
        const fallback = '<%=ctx%>/static/img/placeholder.png';
        grid.innerHTML = relatedItems.map(it => {
            const cover = it.coverImage || fallback;
            const price = it.currentPrice ? parseFloat(it.currentPrice).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00';
            const title = (it.title || '').replace(/</g, '&lt;');
            return '<a href="<%=ctx%>/item?action=detail&id=' + it.id + '" class="cp-goods-card">' +
                '<div class="cp-goods-cover">' +
                (cover ? '<img src="' + cover + '" onerror="this.style.display=\'none\'" style="width:100%;height:100%;object-fit:cover;">' : '<i class="fa fa-image"></i>') +
                '<div class="cp-goods-price-tag">¥' + price + '</div>' +
                '</div>' +
                '<div class="cp-goods-body"><div class="cp-goods-title">' + title + '</div></div>' +
                '</a>';
        }).join('');
    })();
    const loggedIn   = <%= loggedIn.toString() %>;
    const isOwner    = <%= isOwner.toString() %>;
    const activeInit = <%= active.toString() %>;
    const favoritedInit = <%= favorited.toString() %>;
    const nextMinBid = <%= nextMinBid %>;
    const currentUserIdInit = <%= currentUserId == null ? "null" : currentUserId.toString() %>;
    const ctxPath    = '<%=ctx%>';

    loadVue().then(() => {
        const { createApp, ref, computed, onMounted, onUnmounted } = Vue;
        createApp({
            setup() {
                const itemRef = ref(item);
                const bidsRef = ref(bids);
                const categoryRef = ref(category);
                const sellerRef = ref(seller);
                const bidderCount = ref(bids.length > 0 ? new Set(bids.map(b => b.bidderId)).size : 0);
                const active = ref(activeInit);
                const now = ref(Date.now());
                const bidding = ref(false);
                const bidAmount = ref(parseFloat(nextMinBid));
                const favorited = ref(favoritedInit);
                const favoriting = ref(false);
                const canFavorite = computed(() => loggedIn && !isOwner);
                // 押金状态：true=已缴（status=0/1），false=未缴
                const depositPaid = ref(false);
                // 当前用户是不是中标者
                const currentUserIdRef = ref(currentUserIdInit);
                const isWinner = computed(() => {
                    if (!loggedIn || currentUserIdRef.value == null) return false;
                    if (!bidsRef.value || bidsRef.value.length === 0) return false;
                    const top = bidsRef.value[0];
                    return top && top.isWinning === 1 && top.bidderId === currentUserIdRef.value;
                });
                const currentImageIdx = ref(0);
                let timer = null;

                onMounted(() => {
                    timer = setInterval(() => { now.value = Date.now(); }, 1000);
                    // 查询押金状态
                    if (loggedIn && !isOwner) {
                        loadAxios().then(() => {
                            axios.get(ctxPath + '/deposit', { params: { action: 'status', itemId: itemRef.value.id } })
                                .then(r => {
                                    depositPaid.value = !!r.data.deposited;
                                })
                                .catch(() => {});
                        });
                    }
                });
                onUnmounted(() => { if (timer) clearInterval(timer); });

                // 解析多图 URL 列表（与 publish.jsp 同样的解析逻辑）
                // 优先 item_image 表（结构化，更可靠），fallback 到 item.coverImage + item.imageUrls 旧字段
                const galleryImages = computed(() => {
                    if (!itemRef.value) return [];
                    const urls = [];

                    // 1. 优先 item_image 表（已 bind 到本拍品的图，按 sort_order ASC）
                    if (Array.isArray(itemImages) && itemImages.length > 0) {
                        itemImages.forEach(img => {
                            if (img && img.imageUrl && !urls.includes(img.imageUrl)) {
                                urls.push(img.imageUrl);
                            }
                        });
                        return urls.slice(0, 8);
                    }

                    // 2. fallback：coverImage + imageUrls
                    if (itemRef.value.coverImage) urls.push(itemRef.value.coverImage);
                    if (itemRef.value.imageUrls) {
                        try {
                            const arr = JSON.parse(itemRef.value.imageUrls);
                            if (Array.isArray(arr)) {
                                arr.forEach(u => { if (u && !urls.includes(u)) urls.push(u); });
                            }
                        } catch (e) {
                            itemRef.value.imageUrls.split(/[\n,]/).forEach(u => {
                                const t = u.trim();
                                if (t && !urls.includes(t)) urls.push(t);
                            });
                        }
                    }
                    return urls.slice(0, 8);
                });
                const currentImage = computed(() => galleryImages.value[currentImageIdx.value] || null);
                const isUrgent = computed(() => {
                    if (!itemRef.value || !itemRef.value.endTime) return false;
                    const left = new Date(itemRef.value.endTime).getTime() - now.value;
                    return left > 0 && left < 30 * 60 * 1000; // 30 分钟内变红
                });

                // 卖家信息条假数据（实际可从后端拿）
                const sellerDays = computed(() => {
                    if (!sellerRef.value || !sellerRef.value.registerTime) return 30;
                    const reg = new Date(sellerRef.value.registerTime).getTime();
                    return Math.max(1, Math.floor((now.value - reg) / 86400000));
                });

                const countdownText = computed(() => {
                    if (!itemRef.value || !itemRef.value.endTime) return '-';
                    const left = new Date(itemRef.value.endTime).getTime() - now.value;
                    if (left <= 0) { active.value = false; return '已结束'; }
                    const sec = Math.floor(left / 1000);
                    const days = Math.floor(sec / 86400);
                    const hours = Math.floor((sec % 86400) / 3600);
                    const mins = Math.floor((sec % 3600) / 60);
                    const secs = sec % 60;
                    const pad = n => String(n).padStart(2, '0');
                    if (days > 0) return days + '天 ' + pad(hours) + ':' + pad(mins) + ':' + pad(secs);
                    return pad(hours) + ':' + pad(mins) + ':' + pad(secs);
                });

                const statusLabel = computed(() => {
                    if (!itemRef.value) return '';
                    if (active.value) return '拍卖中';
                    if (itemRef.value.status === 2) return '已成交';
                    if (itemRef.value.status === 3) return '已流拍';
                    if (itemRef.value.status === 4) return '已下架';
                    if (itemRef.value.status === 0) return '待审核';
                    if (itemRef.value.status === 5) return '审核未通过';
                    return '其他';
                });
                const statusBadgeClass = computed(() => {
                    if (active.value) return 'badge badge-primary';
                    if (itemRef.value && itemRef.value.status === 2) return 'badge badge-success';
                    return 'badge badge-warning';
                });

                const sellerInitial = computed(() => {
                    if (sellerRef.value && sellerRef.value.username) {
                        return sellerRef.value.username.charAt(0).toUpperCase();
                    }
                    return '?';
                });

                const loginUrl = computed(() => {
                    const back = encodeURIComponent(window.location.pathname + window.location.search);
                    return ctxPath + '/user?action=login&returnUrl=' + back;
                });

                function formatPrice(p) {
                    return Number(p).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
                }
                function formatDateTime(dt) {
                    if (!dt) return '-';
                    const d = new Date(dt);
                    if (isNaN(d)) return dt;
                    const pad = n => String(n).padStart(2, '0');
                    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) +
                        ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes());
                }
                function rankClass(idx) {
                    if (idx === 0) return 'gold';
                    if (idx === 1) return 'silver';
                    if (idx === 2) return 'bronze';
                    return '';
                }
                function onImgError(e) {
                    e.target.style.display = 'none';
                }

                // 快捷加价
                function addQuickBid(steps) {
                    if (!itemRef.value) return;
                    const inc = parseFloat(itemRef.value.bidIncrement) || 1;
                    const base = steps === 0 ? parseFloat(itemRef.value.startPrice) : parseFloat(bidAmount.value);
                    bidAmount.value = base + inc * steps;
                }

                // 收藏 / 私聊 / 关注 / 分享
                function onFavorite() {
                    if (!loggedIn) {
                        const back = encodeURIComponent(window.location.pathname + window.location.search);
                        window.location.href = ctxPath + '/user?action=login&returnUrl=' + back;
                        return;
                    }
                    if (isOwner) {
                        toast('不能收藏自己发布的拍品', 'info');
                        return;
                    }
                    if (favoriting.value) return;
                    favoriting.value = true;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/favorite?action=toggle', null, {
                            params: { itemId: itemRef.value.id }
                        }).then(r => {
                            if (r.data.success) {
                                favorited.value = !!r.data.favorited;
                                toast(r.data.message || (favorited.value ? '已加入收藏' : '已取消收藏'), 'success');
                            } else {
                                toast(r.data.message || '操作失败', 'error');
                            }
                            favoriting.value = false;
                        }).catch(() => {
                            toast('网络错误', 'error');
                            favoriting.value = false;
                        });
                    });
                }
                function onChat() {
                    toast('私聊功能开发中', 'info');
                }
                function onFollow() {
                    toast('关注成功（前端占位）', 'success');
                }
                function onShare() {
                    if (navigator.clipboard) {
                        navigator.clipboard.writeText(window.location.href).then(() => {
                            toast('链接已复制到剪贴板', 'success');
                        }).catch(() => { toast('复制失败，请手动复制', 'error'); });
                    } else {
                        toast('请手动复制地址栏链接', 'info');
                    }
                }

                function placeBid() {
                    const amount = parseFloat(bidAmount.value);
                    if (!amount || amount <= 0) { toast('请输入有效出价', 'error'); return; }
                    if (amount < parseFloat(nextMinBid)) {
                        toast('出价至少 ¥' + nextMinBid, 'error');
                        return;
                    }
                    bidding.value = true;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/bid?action=place', null, {
                            params: { itemId: itemRef.value.id, amount: amount }
                        }).then(r => {
                            const data = r.data;
                            if (data.success) {
                                toast(data.message, 'success');
                                itemRef.value.currentPrice = parseFloat(data.currentPrice);
                                bidAmount.value = parseFloat(data.currentPrice) + parseFloat(itemRef.value.bidIncrement);
                                refreshHistory();
                            } else {
                                // 押金未交 → 弹窗询问
                                if (data.code === 'DEPOSIT_REQUIRED' && data.depositUrl) {
                                    if (confirm(data.message + '\n\n是否立即前往缴纳押金？')) {
                                        window.location.href = data.depositUrl;
                                    }
                                } else {
                                    toast(data.message || '出价失败', 'error');
                                }
                            }
                            bidding.value = false;
                        }).catch(err => {
                            console.error(err);
                            toast('网络错误：' + (err.message || ''), 'error');
                            bidding.value = false;
                        });
                    });
                }

                function refreshHistory() {
                    loadAxios().then(() => {
                        axios.get(ctxPath + '/bid?action=history', {
                            params: { itemId: itemRef.value.id }
                        }).then(r => {
                            if (r.data.success) {
                                bidsRef.value = r.data.bids;
                                bidderCount.value = r.data.bidderCount;
                            }
                        });
                    });
                }

                const loggedInRef = ref(<%= loggedIn.toString() %>);
                const isOwnerRef  = ref(<%= isOwner.toString() %>);

                // ============ 卖家专属：编辑/撤拍 ============
                // 是否可编辑（不能成交/流拍）
                const canEdit = computed(() => {
                    if (!itemRef.value) return false;
                    const s = itemRef.value.status;
                    return s !== 2 && s !== 3;
                });
                // 是否可撤拍（已开始拍卖、已成交、已流拍、已下架 → 都不可撤）
                const canOffline = computed(() => {
                    if (!itemRef.value) return false;
                    const s = itemRef.value.status;
                    if (s === 0 || s === 5) return true;                      // 待审核 / 审核未通过
                    if (s === 1 && itemRef.value.startTime && new Date(itemRef.value.startTime) > new Date()) return true;
                    return false;
                });
                function offlineItem() {
                    if (!confirm('确定要撤拍「' + itemRef.value.title + '」吗？\n撤拍后前台不再展示。')) return;
                    loadAxios().then(() => {
                        axios.post(ctxPath + '/item?action=offline&id=' + itemRef.value.id)
                            .then(r => {
                                if (r.data.success) {
                                    toast(r.data.message || '撤拍成功', 'success');
                                    setTimeout(() => location.reload(), 800);
                                } else {
                                    toast(r.data.message || '撤拍失败', 'error');
                                }
                            })
                            .catch(() => toast('网络错误', 'error'));
                    });
                }

                return {
                    item: itemRef, bids: bidsRef, category: categoryRef, seller: sellerRef,
                    bidderCount, active, bidding, bidAmount, nextMinBid, favorited,
                    galleryImages, currentImage, currentImageIdx, isUrgent,
                    sellerDays, countdownText, statusLabel, statusBadgeClass, sellerInitial, loginUrl,
                    loggedIn: loggedInRef, isOwner: isOwnerRef,
                    formatPrice, formatDateTime, rankClass, onImgError,
                    addQuickBid, onFavorite, onChat, onFollow, onShare,
                    placeBid,
                    canEdit, canOffline, offlineItem,
                    ctxPath,                // ★ Phase 2 加的押金提示按钮需要
                    depositPaid,            // ★ Phase 2 加的押金状态
                    isWinner                // ★ 中标者按钮需要
                };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
