<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    String itemJson      = (String) request.getAttribute("itemJson");
    String bidsJson      = (String) request.getAttribute("bidsJson");
    String categoryJson  = (String) request.getAttribute("categoryJson");
    String sellerJson    = (String) request.getAttribute("sellerJson");
    String itemImagesJson= (String) request.getAttribute("itemImagesJson");
    Boolean loggedIn     = (Boolean) request.getAttribute("loggedIn");
    Boolean isOwner      = (Boolean) request.getAttribute("isOwner");
    Boolean active       = (Boolean) request.getAttribute("active");
    Boolean favorited    = (Boolean) request.getAttribute("favorited");
    String nextMinBid    = (String) request.getAttribute("nextMinBid");
    // 顶部搜索框回显（避免嵌套引号问题）
    String kwParam = request.getParameter("kw");
    String kwValue = kwParam == null ? "" : kwParam;
    if (itemJson == null) itemJson = "null";
    if (bidsJson == null) bidsJson = "[]";
    if (categoryJson == null) categoryJson = "null";
    if (sellerJson == null) sellerJson = "null";
    if (itemImagesJson == null) itemImagesJson = "[]";
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
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 拍品详情 v2 · 仿闲鱼
         * - 顶 nav 统一
         * - 卖家信息横条
         * - 主体：左侧图廊 + 右侧信息（出价 sticky）
         * - 下方：为你推荐 6 列网格
         * - 保留所有 Vue 接管（出价、倒计时、刷新历史）
         * ============================================================ */
        body { background: #f5f5f5; }

        /* ---------- 顶 nav ---------- */
        .header { background: #fff; height: 60px; position: sticky; top: 0; z-index: 100;
                  box-shadow: 0 1px 2px rgba(0,0,0,0.04); }
        .header-inner { max-width: 1200px; margin: 0 auto; padding: 0 16px; height: 100%;
                        display: flex; align-items: center; gap: 20px; }
        .logo { font-size: 20px; font-weight: 800; color: var(--color-primary);
                display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
        .logo-icon { width: 30px; height: 30px; background: var(--color-primary);
                     color: #fff; border-radius: 4px; display: grid; place-items: center;
                     font-size: 14px; }
        .nav { display: flex; gap: 24px; }
        .nav a { color: var(--color-text); font-size: 14px; font-weight: 500;
                 padding: 0 4px; height: 60px; display: flex; align-items: center;
                 position: relative; transition: color 0.2s; }
        .nav a:hover, .nav a.active { color: var(--color-primary); }
        .nav a.active::after {
            content: ''; position: absolute;
            bottom: 8px; left: 4px; right: 4px;
            height: 2px; background: var(--color-primary); border-radius: 2px;
        }
        .nav-search {
            flex: 0 1 380px;
            display: flex; background: #fff7ed;
            border: 2px solid var(--color-primary);
            border-radius: 20px; overflow: hidden; height: 36px;
        }
        .nav-search input {
            flex: 1; padding: 0 14px; border: none; outline: none;
            background: transparent; font-size: 13px; color: var(--color-text);
        }
        .nav-search input::placeholder { color: #9ca3af; }
        .nav-search button {
            background: var(--color-primary); color: #fff;
            font-size: 13px; font-weight: 600; padding: 0 18px;
            display: flex; align-items: center; gap: 5px;
        }
        .nav-search button:hover { background: var(--color-primary-hover); }
        .nav-tags { display: flex; gap: 12px; font-size: 12px; color: var(--color-muted);
                    flex: 1; min-width: 0; overflow: hidden; }
        .nav-tags-label { flex-shrink: 0; }
        .nav-tag { white-space: nowrap; transition: color 0.15s; }
        .nav-tag:hover { color: var(--color-primary); }
        .nav-tag.hot { color: var(--color-danger); font-weight: 600; }
        .user-info { display: flex; align-items: center; gap: 8px; font-size: 14px; flex-shrink: 0; margin-left: auto; }
        .user-info .avatar {
            width: 32px; height: 32px; border-radius: 50%;
            background: linear-gradient(135deg, var(--color-primary), #ffaa80);
            color: #fff; display: grid; place-items: center;
            font-size: 13px; font-weight: 600; cursor: pointer;
        }
        .user-name-link { color: var(--color-text); font-weight: 500; }

        /* ---------- 主体 ---------- */
        .detail-wrap { max-width: 1200px; margin: 12px auto 0; padding: 0 16px; }

        /* 卖家信息条（横条，仿闲鱼） */
        .seller-bar {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 14px 20px;
            display: flex; align-items: center; gap: 14px;
            margin-bottom: 12px;
        }
        .seller-bar-avatar {
            width: 48px; height: 48px; border-radius: 50%;
            background: var(--color-primary-light); color: var(--color-primary);
            display: grid; place-items: center;
            font-size: 20px; font-weight: 600; flex-shrink: 0;
        }
        .seller-bar-info { flex: 1; min-width: 0; }
        .seller-bar-name {
            font-size: 15px; font-weight: 600; color: var(--color-text);
            margin-bottom: 4px;
            display: flex; align-items: center; gap: 6px;
        }
        .seller-bar-name .name-link { color: var(--color-text); }
        .seller-bar-name .name-link:hover { color: var(--color-primary); }
        .seller-bar-name .credit-tag {
            font-size: 11px; padding: 1px 6px;
            background: var(--color-primary-light); color: var(--color-primary);
            border-radius: 2px; font-weight: 500;
        }
        .seller-bar-meta {
            display: flex; gap: 14px; font-size: 12px; color: var(--color-muted);
        }
        .seller-bar-meta span { display: flex; align-items: center; gap: 3px; }
        .seller-bar-meta .sep { color: #e5e7eb; }
        .seller-bar-actions { display: flex; gap: 8px; flex-shrink: 0; }
        .btn-chat {
            padding: 8px 18px; background: #fff7ed; color: var(--color-primary);
            border: 1px solid #fed7aa; border-radius: 6px;
            font-size: 13px; font-weight: 600; cursor: pointer;
            display: flex; align-items: center; gap: 5px;
            transition: all 0.15s;
        }
        .btn-chat:hover { background: var(--color-primary); color: #fff; border-color: var(--color-primary); }
        .btn-follow {
            padding: 8px 18px; background: #fff; color: var(--color-text);
            border: 1px solid var(--color-border); border-radius: 6px;
            font-size: 13px; cursor: pointer; display: flex; align-items: center; gap: 5px;
            transition: all 0.15s;
        }
        .btn-follow:hover { border-color: var(--color-primary); color: var(--color-primary); }

        /* 主体两栏：左图廊 + 右信息 */
        .detail-layout {
            display: grid; grid-template-columns: 1fr 460px; gap: 16px;
            align-items: start;
        }
        @media (max-width: 1024px) {
            .detail-layout { grid-template-columns: 1fr; }
        }

        /* ---------- 左侧：图廊 + 描述 + 规格 ---------- */
        .gallery-card {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 16px; display: grid;
            grid-template-columns: 80px 1fr; gap: 12px;
        }
        .gallery-thumbs {
            display: flex; flex-direction: column; gap: 6px;
            max-height: 500px; overflow-y: auto;
        }
        .gallery-thumbs::-webkit-scrollbar { width: 4px; }
        .gallery-thumbs::-webkit-scrollbar-thumb { background: #e5e7eb; border-radius: 2px; }
        .gallery-thumb {
            width: 72px; height: 72px; border-radius: 4px;
            background: #f3f4f6; cursor: pointer; overflow: hidden;
            border: 2px solid transparent;
            display: grid; place-items: center; flex-shrink: 0;
            transition: border-color 0.15s;
        }
        .gallery-thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }
        .gallery-thumb i { font-size: 22px; color: #cbd5e1; }
        .gallery-thumb.active { border-color: var(--color-primary); }
        .gallery-main {
            aspect-ratio: 1; background: #f3f4f6;
            border-radius: 6px; overflow: hidden;
            display: grid; place-items: center;
            position: relative;
        }
        .gallery-main img { width: 100%; height: 100%; object-fit: contain; display: block; }
        .gallery-main i { font-size: 80px; color: rgba(255,107,53,0.3); }
        .gallery-main .placeholder-text {
            position: absolute; bottom: 16px; left: 50%; transform: translateX(-50%);
            color: var(--color-muted); font-size: 13px;
        }
        .gallery-main .watermark {
            position: absolute; bottom: 30px; right: 16px;
            display: flex; gap: 12px; font-size: 12px; color: var(--color-muted);
        }
        .gallery-main .watermark a { color: var(--color-muted); }
        .gallery-main .watermark a:hover { color: var(--color-primary); }

        /* 描述卡 */
        .section-card {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 20px 24px; margin-top: 12px;
        }
        .section-card-title {
            font-size: 15px; font-weight: 600;
            margin-bottom: 14px; display: flex; align-items: center; gap: 8px;
        }
        .section-card-title::before {
            content: ''; display: inline-block; width: 3px; height: 16px;
            background: var(--color-primary); border-radius: 2px;
        }
        .section-card-content { font-size: 14px; line-height: 1.8; color: var(--color-text);
                                white-space: pre-wrap; }
        .spec-table {
            display: grid; grid-template-columns: 1fr 1fr; gap: 10px 24px;
            font-size: 13px;
        }
        .spec-row { display: flex; gap: 8px; }
        .spec-key { color: var(--color-muted); flex-shrink: 0; min-width: 70px; }
        .spec-val { color: var(--color-text); }

        /* ---------- 右侧：信息区（sticky） ---------- */
        .info-col { position: sticky; top: 72px; display: flex; flex-direction: column; gap: 12px; }
        @media (max-width: 1024px) { .info-col { position: static; } }

        .info-card {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            padding: 20px 22px;
        }
        .info-status-row {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 12px;
        }
        .info-status-row .left { display: flex; gap: 6px; align-items: center; }
        .badge {
            padding: 3px 10px; border-radius: 3px; font-size: 12px; font-weight: 500;
            display: inline-flex; align-items: center; gap: 4px;
        }
        .badge-primary { background: var(--color-primary-light); color: var(--color-primary); }
        .badge-success { background: #d1fae5; color: #059669; }
        .badge-warning { background: #fef3c7; color: #b45309; }
        .badge-danger  { background: #fee2e2; color: var(--color-danger); }
        .badge-info    { background: #dbeafe; color: #1d4ed8; }
        .info-meta-right { font-size: 12px; color: var(--color-muted); }
        .info-meta-right i { margin-right: 3px; }

        .price-row {
            display: flex; align-items: baseline; gap: 10px;
            margin-bottom: 8px;
        }
        .price-current {
            font-size: 32px; font-weight: 800; color: var(--color-primary); line-height: 1;
        }
        .price-current small { font-size: 16px; font-weight: 600; margin-right: 2px; }
        .price-tag {
            padding: 2px 8px; font-size: 11px;
            background: #fff7ed; color: var(--color-primary);
            border: 1px solid #fed7aa; border-radius: 3px;
        }

        .info-title {
            font-size: 16px; font-weight: 500; line-height: 1.6;
            color: var(--color-text); margin: 12px 0 14px;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* 规格简表（在右侧出价区上方） */
        .spec-compact {
            display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px;
            font-size: 12px; margin-bottom: 14px;
            padding: 12px 14px; background: #f9fafb; border-radius: 6px;
        }
        .spec-compact .spec-row .spec-key { min-width: 50px; }
        .spec-compact .spec-row .spec-val { color: var(--color-text); font-weight: 500; }

        /* 倒计时 */
        .countdown-block {
            background: #fff7ed; border: 1.5px dashed #fed7aa;
            border-radius: 6px; padding: 12px 16px; margin-bottom: 12px;
            text-align: center;
        }
        .countdown-block.urgent { border-color: var(--color-danger); background: #fee2e2; }
        .countdown-block.ended { border-color: #d1d5db; background: #f3f4f6; }
        .countdown-label { font-size: 12px; color: var(--color-muted); margin-bottom: 4px; }
        .countdown-time {
            font-size: 22px; font-weight: 700; color: var(--color-primary);
            font-family: "Consolas", "Monaco", monospace; letter-spacing: 1px;
        }
        .countdown-block.urgent .countdown-time { color: var(--color-danger); }
        .countdown-block.ended .countdown-time { color: var(--color-muted); font-size: 16px; }

        /* 出价区 */
        .bid-area { margin-bottom: 12px; }
        .bid-label { font-size: 12px; color: var(--color-muted); margin-bottom: 6px; }
        .bid-row { display: flex; gap: 8px; align-items: stretch; }
        .bid-input {
            flex: 1; padding: 11px 14px;
            border: 1.5px solid var(--color-border);
            border-radius: 6px; font-size: 16px; outline: none;
            transition: border-color 0.15s; background: #fff; min-width: 0;
        }
        .bid-input:focus { border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(255,107,53,0.1); }
        .btn-bid {
            padding: 11px 22px; background: var(--color-primary); color: #fff;
            font-size: 14px; font-weight: 600; border-radius: 6px;
            border: none; cursor: pointer; transition: all 0.15s;
            white-space: nowrap;
        }
        .btn-bid:hover:not(:disabled) { background: var(--color-primary-hover); }
        .btn-bid:disabled { opacity: 0.6; cursor: not-allowed; }
        .bid-hint { font-size: 11px; color: var(--color-muted); margin-top: 4px; }
        .bid-shortcut { display: flex; gap: 4px; margin-top: 6px; flex-wrap: wrap; }
        .bid-shortcut-btn {
            padding: 2px 8px; font-size: 11px;
            background: #f3f4f6; color: var(--color-text-sub);
            border: 1px solid var(--color-border); border-radius: 3px;
            cursor: pointer; transition: all 0.15s;
        }
        .bid-shortcut-btn:hover { background: var(--color-primary-light); color: var(--color-primary); border-color: var(--color-primary); }

        .bid-action-row {
            display: flex; gap: 8px; margin-top: 8px;
        }
        .btn-secondary {
            flex: 1; padding: 10px 0; background: #fff; color: var(--color-text);
            border: 1px solid var(--color-border); border-radius: 6px;
            font-size: 13px; cursor: pointer; transition: all 0.15s;
            display: flex; align-items: center; justify-content: center; gap: 5px;
        }
        .btn-secondary:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .btn-secondary.danger:hover { border-color: var(--color-danger); color: var(--color-danger); }

        .info-footer {
            margin-top: 14px; padding-top: 12px;
            border-top: 1px solid var(--color-border-soft);
            display: flex; align-items: center; gap: 12px;
            font-size: 12px; color: var(--color-muted);
        }
        .info-footer a { color: var(--color-muted); }
        .info-footer a:hover { color: var(--color-primary); }

        /* 出价历史卡 */
        .bids-card { padding: 20px 24px; }
        .bids-head {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 14px;
        }
        .bids-list { max-height: 360px; overflow-y: auto; }
        .bids-list::-webkit-scrollbar { width: 4px; }
        .bids-list::-webkit-scrollbar-thumb { background: #e5e7eb; border-radius: 2px; }
        .bid-row-item {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 0; border-bottom: 1px solid var(--color-border-soft);
        }
        .bid-row-item:last-child { border-bottom: none; }
        .bid-rank {
            display: inline-grid; place-items: center;
            width: 22px; height: 22px; border-radius: 50%;
            background: #e5e7eb; color: #6b7280;
            font-size: 11px; font-weight: 700; flex-shrink: 0;
        }
        .bid-rank.gold   { background: #fbbf24; color: #fff; }
        .bid-rank.silver { background: #d1d5db; color: #fff; }
        .bid-rank.bronze { background: #d97706; color: #fff; }
        .bid-user { flex: 1; min-width: 0; font-size: 13px; }
        .bid-user .u-name {
            display: flex; align-items: center; gap: 4px;
        }
        .bid-user .u-name .crown { color: #f59e0b; font-size: 12px; }
        .bid-user .u-time { font-size: 11px; color: var(--color-muted); margin-top: 2px; }
        .bid-amount {
            font-size: 15px; font-weight: 700; color: var(--color-primary);
            text-align: right; flex-shrink: 0;
        }
        .bids-empty {
            text-align: center; padding: 30px; color: var(--color-muted); font-size: 13px;
        }
        .bids-empty i { font-size: 32px; opacity: 0.3; margin-bottom: 6px; display: block; }

        /* 错误 / 提示条 */
        .info-note {
            padding: 10px 14px; border-radius: 6px;
            font-size: 13px; margin-bottom: 12px;
            display: flex; align-items: center; gap: 8px;
        }
        .info-note-warning { background: #fef3c7; color: #b45309; }
        .info-note-info    { background: #dbeafe; color: #1d4ed8; }

        /* 卖家专属操作按钮 */
        .owner-actions { display: flex; gap: 8px; margin-top: 10px; }
        .owner-btn {
            flex: 1; padding: 10px 16px; border-radius: 6px;
            font-size: 13px; font-weight: 600; cursor: pointer;
            text-decoration: none; text-align: center;
            display: inline-flex; align-items: center; justify-content: center; gap: 6px;
            transition: all 0.15s; border: 1.5px solid transparent;
        }
        .owner-btn-edit { background: #fff; color: var(--color-primary); border-color: var(--color-primary); }
        .owner-btn-edit:hover { background: var(--color-primary); color: #fff; }
        .owner-btn-offline { background: #fff; color: var(--color-danger); border-color: var(--color-danger); }
        .owner-btn-offline:hover { background: var(--color-danger); color: #fff; }

        /* 加载失败 */
        .load-fail {
            text-align: center; padding: 80px 20px; color: var(--color-muted);
            background: #fff; border-radius: 8px;
        }
        .load-fail i { font-size: 48px; opacity: 0.3; margin-bottom: 8px; display: block; }

        /* 为你推荐 */
        .recommend-block {
            background: #fff; border-radius: 8px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            margin-top: 16px; padding: 16px 20px;
        }
        .recommend-head {
            display: flex; align-items: baseline; justify-content: space-between;
            margin-bottom: 14px;
        }
        .recommend-title { font-size: 16px; font-weight: 700; }
        .recommend-link { font-size: 12px; color: var(--color-muted); }
        .recommend-link:hover { color: var(--color-primary); }
        .recommend-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 10px;
        }
        @media (max-width: 1200px) { .recommend-grid { grid-template-columns: repeat(5, 1fr); } }
        @media (max-width: 1024px) { .recommend-grid { grid-template-columns: repeat(4, 1fr); } }
        @media (max-width: 768px)  { .recommend-grid { grid-template-columns: repeat(3, 1fr); } }
        .rec-card {
            background: #fff; border: 1px solid transparent;
            border-radius: 4px; overflow: hidden; cursor: pointer;
            transition: all 0.15s; text-decoration: none; color: inherit;
        }
        .rec-card:hover {
            border-color: var(--color-primary);
            transform: translateY(-2px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.06);
        }
        .rec-cover {
            width: 100%; aspect-ratio: 1; background: #fff7ed;
            display: grid; place-items: center; position: relative;
        }
        .rec-cover i { font-size: 30px; color: rgba(255,107,53,0.4); }
        .rec-cover .rec-price-tag {
            position: absolute; bottom: 4px; left: 4px; right: 4px;
            background: rgba(0,0,0,0.6); color: #fff;
            font-size: 11px; font-weight: 600; padding: 3px 6px;
            text-align: center;
        }
        .rec-body { padding: 6px 8px 8px; }
        .rec-title {
            font-size: 12px; line-height: 1.4; min-height: 32px;
            color: var(--color-text);
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* 右侧浮动操作栏 */
        .floats {
            position: fixed; right: 16px; top: 50%; transform: translateY(-50%);
            display: flex; flex-direction: column; gap: 6px; z-index: 50;
        }
        .float-btn {
            width: 40px; height: 40px; background: #fff;
            border-radius: 8px; display: flex; flex-direction: column;
            align-items: center; justify-content: center;
            color: var(--color-text-sub); box-shadow: 0 1px 2px rgba(0,0,0,0.04);
            transition: all 0.15s; cursor: pointer; font-size: 10px; gap: 1px;
            text-decoration: none; border: none;
        }
        .float-btn i { font-size: 14px; }
        .float-btn:hover { background: var(--color-primary); color: #fff; transform: translateY(-1px); }
        .float-btn.primary { background: var(--color-primary); color: #fff; }
        @media (max-width: 1200px) { .floats { display: none; } }

        /* 页脚 */
        .detail-footer {
            background: #1f2937; color: #d1d5db;
            margin-top: 32px; padding: 32px 16px 16px;
            text-align: center; font-size: 12px;
        }
        .detail-footer-inner { max-width: 1200px; margin: 0 auto; color: #6b7280; }

        [v-cloak] { display: none; }
    </style>
</head>
<body>

<!-- ========== 顶 nav ========== -->
<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <span class="logo-icon"><i class="fa fa-gavel"></i></span>
            <span>二手拍卖</span>
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/index.jsp">首页</a>
            <a href="<%=ctx%>/item?action=list">浏览拍品</a>
            <a href="<%=ctx%>/item?action=publish-page">发布拍品</a>
            <a href="<%=ctx%>/item?action=list&sort=hot">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="<%=ctx%>/user?action=center">个人中心</a>
            <% } %>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ..."
                   value="<%= kwValue %>">
            <button type="submit"><i class="fa fa-search"></i> 搜索</button>
        </form>
        <div class="nav-tags">
            <span class="nav-tags-label">热搜：</span>
            <a href="<%=ctx%>/item/list?keyword=iPhone" class="nav-tag hot">iPhone 15</a>
            <a href="<%=ctx%>/item/list?keyword=相机" class="nav-tag">佳能相机</a>
            <a href="<%=ctx%>/item/list?keyword=球鞋" class="nav-tag">球鞋</a>
            <a href="<%=ctx%>/item/list?keyword=茅台" class="nav-tag hot">茅台</a>
        </div>
        <div class="user-info">
            <% if (currentUser != null) { %>
                <a href="<%=ctx%>/user?action=center" class="user-name-link"><%= currentUser.getUsername() %></a>
                <a href="<%=ctx%>/user?action=logout" style="font-size: 12px; color: var(--color-muted);">退出</a>
                <a href="<%=ctx%>/user?action=center" class="avatar"><%= currentUser.getUsername().substring(0, 1).toUpperCase() %></a>
            <% } else { %>
                <a href="<%=ctx%>/user?action=login" style="font-size: 13px; padding: 6px 12px; color: var(--color-primary); border: 1px solid var(--color-primary); border-radius: 4px;">登录</a>
                <a href="<%=ctx%>/user?action=register" style="font-size: 13px; padding: 6px 12px; color: #fff; background: var(--color-primary); border-radius: 4px;">注册</a>
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
            <div class="gallery-card">
                <div class="gallery-thumbs" v-if="galleryImages.length > 0">
                    <div v-for="(img, idx) in galleryImages" :key="idx"
                         :class="['gallery-thumb', { active: currentImageIdx === idx }]"
                         @click="currentImageIdx = idx">
                        <img v-if="img" :src="img" :alt="'图' + (idx+1)" @error="onImgError($event)">
                        <i v-else class="fa fa-image"></i>
                    </div>
                </div>
                <div v-else class="gallery-thumbs">
                    <div class="gallery-thumb active">
                        <i class="fa fa-image"></i>
                    </div>
                </div>
                <div class="gallery-main">
                    <img v-if="currentImage" :src="currentImage" :alt="item.title" @error="onImgError($event)">
                    <i v-else class="fa fa-image"></i>
                    <div class="watermark">
                        <a href="javascript:void(0)" @click="toast('举报已提交（前端占位）', 'success')">
                            <i class="fa fa-flag-o"></i> 举报
                        </a>
                        <a href="javascript:void(0)" @click="onShare">
                            <i class="fa fa-share-alt"></i> 分享
                        </a>
                    </div>
                </div>
            </div>

            <!-- 拍品描述 -->
            <div class="section-card">
                <div class="section-card-title">拍品描述</div>
                <div class="section-card-content">{{ item.description || '卖家未填写详细描述' }}</div>
            </div>

            <!-- 规格参数 -->
            <div class="section-card">
                <div class="section-card-title">规格参数</div>
                <div class="spec-table">
                    <div class="spec-row"><span class="spec-key">品牌：</span><span class="spec-val">{{ item.brand || '-' }}</span></div>
                    <div class="spec-row"><span class="spec-key">型号：</span><span class="spec-val">{{ item.model || '-' }}</span></div>
                    <div class="spec-row"><span class="spec-key">成色：</span><span class="spec-val">{{ item.conditionLevel || '-' }}</span></div>
                    <div class="spec-row"><span class="spec-key">瑕疵：</span><span class="spec-val">{{ item.flawDesc || '无' }}</span></div>
                    <div class="spec-row"><span class="spec-key">起拍价：</span><span class="spec-val">¥{{ formatPrice(item.startPrice) }}</span></div>
                    <div class="spec-row"><span class="spec-key">加价幅度：</span><span class="spec-val">¥{{ formatPrice(item.bidIncrement) }}</span></div>
                    <div class="spec-row"><span class="spec-key">开始时间：</span><span class="spec-val">{{ formatDateTime(item.startTime) }}</span></div>
                    <div class="spec-row"><span class="spec-key">结束时间：</span><span class="spec-val">{{ formatDateTime(item.endTime) }}</span></div>
                    <div class="spec-row"><span class="spec-key">分类：</span><span class="spec-val">{{ category ? category.categoryName : '-' }}</span></div>
                    <div class="spec-row"><span class="spec-key">浏览数：</span><span class="spec-val">{{ item.viewCount || 0 }}</span></div>
                </div>
            </div>
        </div>

        <!-- 右侧：信息 + 出价 -->
        <div class="info-col">
            <div class="info-card">
                <!-- 状态 + 浏览数 -->
                <div class="info-status-row">
                    <div class="left">
                        <span :class="statusBadgeClass">
                            <i v-if="active" class="fa fa-gavel"></i>
                            <i v-else-if="item.status === 2" class="fa fa-check-circle"></i>
                            <i v-else class="fa fa-clock-o"></i>
                            {{ statusLabel }}
                        </span>
                        <span class="badge badge-info" v-if="item.conditionLevel">{{ item.conditionLevel }}</span>
                    </div>
                    <div class="info-meta-right">
                        <i class="fa fa-eye"></i> {{ item.viewCount || 0 }} 浏览
                    </div>
                </div>

                <!-- 价格 -->
                <div class="price-row">
                    <div class="price-current">
                        <small>¥</small>{{ formatPrice(item.currentPrice) }}
                    </div>
                    <span class="price-tag"><i class="fa fa-truck"></i> 包邮</span>
                </div>

                <!-- 标题 -->
                <h1 class="info-title">{{ item.title }}</h1>

                <!-- 规格简表 -->
                <div class="spec-compact">
                    <div class="spec-row" v-if="item.brand"><span class="spec-key">品牌</span><span class="spec-val">{{ item.brand }}</span></div>
                    <div class="spec-row" v-if="item.model"><span class="spec-key">型号</span><span class="spec-val">{{ item.model }}</span></div>
                    <div class="spec-row" v-if="category"><span class="spec-key">分类</span><span class="spec-val">{{ category.categoryName }}</span></div>
                    <div class="spec-row"><span class="spec-key">浏览</span><span class="spec-val">{{ item.viewCount || 0 }}</span></div>
                </div>

                <!-- 倒计时 -->
                <div :class="['countdown-block', { urgent: isUrgent, ended: !active && item.status !== 2 }]">
                    <div class="countdown-label">
                        <span v-if="active">距结束</span>
                        <span v-else-if="item.status === 2">已成交</span>
                        <span v-else>已结束</span>
                    </div>
                    <div class="countdown-time">{{ countdownText }}</div>
                </div>

                <!-- 出价区 -->
                <div v-if="isOwner">
                    <div class="info-note info-note-info">
                        <i class="fa fa-info-circle"></i> 这是您自己发布的拍品，不能出价
                    </div>
                    <!-- 卖家专属操作按钮（编辑/撤拍） -->
                    <div class="owner-actions" v-if="canEdit || canOffline">
                        <a v-if="canEdit" :href="'<%=ctx%>/item?action=edit-page&id=' + item.id" class="owner-btn owner-btn-edit">
                            <i class="fa fa-pencil"></i> 编辑拍品
                        </a>
                        <button v-if="canOffline" type="button" class="owner-btn owner-btn-offline" @click="offlineItem">
                            <i class="fa fa-trash-o"></i> 撤拍
                        </button>
                    </div>
                </div>
                <div v-else-if="!loggedIn">
                    <a :href="loginUrl" class="btn-bid" style="display: block; text-align: center; text-decoration: none;">
                        <i class="fa fa-sign-in"></i> 登录后参与竞拍
                    </a>
                </div>
                <div v-else-if="!active && item.status === 2" class="info-note info-note-warning">
                    <i class="fa fa-check-circle"></i> 本场拍卖已成交，最高出价者请到"我的订单"完成付款
                </div>
                <div v-else-if="!active" class="info-note info-note-warning">
                    <i class="fa fa-clock-o"></i> 本场拍卖已结束，无法再出价
                </div>
                <div v-else class="bid-area">
                    <div class="bid-label">您的出价（最低 ¥{{ nextMinBid }}）</div>
                    <div class="bid-row">
                        <input type="number" class="bid-input" v-model.number="bidAmount"
                               :min="nextMinBid" :step="item.bidIncrement"
                               :placeholder="'至少 ' + nextMinBid">
                        <button class="btn-bid" :disabled="bidding" @click="placeBid">
                            {{ bidding ? '出价中...' : '立即出价' }}
                        </button>
                    </div>
                    <div class="bid-shortcut">
                        <span class="bid-shortcut-btn" @click="addQuickBid(0)">起拍价</span>
                        <span class="bid-shortcut-btn" @click="addQuickBid(1)">+1 步</span>
                        <span class="bid-shortcut-btn" @click="addQuickBid(3)">+3 步</span>
                        <span class="bid-shortcut-btn" @click="addQuickBid(5)">+5 步</span>
                    </div>
                </div>

                <!-- 次级操作 -->
                <div class="bid-action-row">
                    <button class="btn-secondary" @click="onFavorite" :disabled="favoriting"
                            :title="canFavorite ? '' : (isOwner ? '不能收藏自己发布的拍品' : '请先登录')">
                        <i :class="['fa', favorited ? 'fa-heart' : 'fa-heart-o']"
                           :style="favorited ? 'color: #ef4444;' : ''"></i>
                        {{ favorited ? '已收藏' : '收藏' }}
                    </button>
                    <button class="btn-secondary" @click="onShare">
                        <i class="fa fa-share-alt"></i> 分享
                    </button>
                </div>

                <!-- 担保 / 举报 -->
                <div class="info-footer">
                    <span><i class="fa fa-shield"></i> 担保交易</span>
                    <a href="javascript:void(0)" @click="toast('举报已提交（前端占位）', 'success')">
                        <i class="fa fa-flag-o"></i> 举报
                    </a>
                </div>
            </div>

            <!-- 出价历史 -->
            <div class="info-card bids-card">
                <div class="bids-head">
                    <div class="section-card-title" style="margin-bottom: 0;">出价记录</div>
                    <span style="font-size: 12px; color: var(--color-muted);">
                        共 {{ bids.length }} 次 / {{ bidderCount }} 人
                    </span>
                </div>
                <div v-if="bids.length === 0" class="bids-empty">
                    <i class="fa fa-inbox"></i>
                    暂无出价记录，赶快来抢沙发 👀
                </div>
                <div v-else class="bids-list">
                    <div v-for="(bid, idx) in bids" :key="bid.id" class="bid-row-item">
                        <span :class="['bid-rank', rankClass(idx)]">{{ idx + 1 }}</span>
                        <div class="bid-user">
                            <div class="u-name">
                                <span>{{ '用户 #' + bid.bidderId }}</span>
                                <i v-if="bid.isWinning === 1" class="fa fa-crown crown" title="当前领先"></i>
                            </div>
                            <div class="u-time">{{ formatDateTime(bid.bidTime) }}</div>
                        </div>
                        <div class="bid-amount">¥{{ formatPrice(bid.bidAmount) }}</div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- 加载失败 -->
    <div v-else class="load-fail">
        <i class="fa fa-exclamation-circle"></i>
        <p>加载失败，请稍后再试</p>
    </div>

    <!-- ========== 为你推荐 ========== -->
    <div class="recommend-block">
        <div class="recommend-head">
            <div class="recommend-title">为你推荐</div>
            <a href="<%=ctx%>/item?action=list" class="recommend-link">查看更多 →</a>
        </div>
        <div class="recommend-grid">
            <%-- 静态推荐拍品（前端占位，等后端给推荐接口再接） --%>
            <a href="<%=ctx%>/item?action=detail&id=201" class="rec-card">
                <div class="rec-cover"><i class="fa fa-mobile"></i>
                    <div class="rec-price-tag">¥4,250</div>
                </div>
                <div class="rec-body"><div class="rec-title">iPhone 14 Pro 256G 深空黑 99新 自用</div></div>
            </a>
            <a href="<%=ctx%>/item?action=detail&id=202" class="rec-card">
                <div class="rec-cover"><i class="fa fa-clock-o"></i>
                    <div class="rec-price-tag">¥62,000</div>
                </div>
                <div class="rec-body"><div class="rec-title">劳力士 Submariner 黑水鬼 全新未拆封</div></div>
            </a>
            <a href="<%=ctx%>/item?action=detail&id=203" class="rec-card">
                <div class="rec-cover"><i class="fa fa-paw"></i>
                    <div class="rec-price-tag">¥200</div>
                </div>
                <div class="rec-body"><div class="rec-title">出原神 艾尔海森 月之.cos 服全套 S码</div></div>
            </a>
            <a href="<%=ctx%>/item?action=detail&id=204" class="rec-card">
                <div class="rec-cover"><i class="fa fa-microchip"></i>
                    <div class="rec-price-tag">¥3,099</div>
                </div>
                <div class="rec-body"><div class="rec-title">全新未拆 AMD 锐龙 R9 9950X 盒装 CPU</div></div>
            </a>
            <a href="<%=ctx%>/item?action=detail&id=205" class="rec-card">
                <div class="rec-cover"><i class="fa fa-camera-retro"></i>
                    <div class="rec-price-tag">¥16,800</div>
                </div>
                <div class="rec-body"><div class="rec-title">佳能 EOS R6 Mark II 套机 24-105 镜头</div></div>
            </a>
            <a href="<%=ctx%>/item?action=detail&id=206" class="rec-card">
                <div class="rec-cover"><i class="fa fa-headphones"></i>
                    <div class="rec-price-tag">¥1,580</div>
                </div>
                <div class="rec-body"><div class="rec-title">索尼 WH-1000XM5 头戴式降噪耳机</div></div>
            </a>
        </div>
    </div>

</div>

<!-- 浮动操作栏 -->
<aside class="floats">
    <button class="float-btn primary" title="发拍品" onclick="go('<%=ctx%>/item?action=publish-page')">
        <i class="fa fa-plus"></i><span>发布</span>
    </button>
    <button class="float-btn" title="消息" onclick="toast('消息中心开发中', 'info')">
        <i class="fa fa-envelope-o"></i><span>消息</span>
    </button>
    <button class="float-btn" title="APP" onclick="toast('APP 下载敬请期待', 'info')">
        <i class="fa fa-mobile"></i><span>APP</span>
    </button>
    <button class="float-btn" title="反馈" onclick="toast('反馈功能开发中', 'info')">
        <i class="fa fa-commenting-o"></i><span>反馈</span>
    </button>
    <button class="float-btn" title="客服" onclick="toast('客服：400-888-8888', 'info')">
        <i class="fa fa-headphones"></i><span>客服</span>
    </button>
    <button class="float-btn" title="回顶部" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" style="margin-top: auto;">
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

    const item       = <%= itemJson %>;
    const bids       = <%= bidsJson %>;
    const category   = <%= categoryJson %>;
    const seller     = <%= sellerJson %>;
    // item_images 表的图片列表（来自 ItemImageMapper.findByItemId）；为空则 fallback 到 item.coverImage / item.imageUrls
    const itemImages = <%= itemImagesJson %>;
    const loggedIn   = <%= loggedIn.toString() %>;
    const isOwner    = <%= isOwner.toString() %>;
    const activeInit = <%= active.toString() %>;
    const favoritedInit = <%= favorited.toString() %>;
    const nextMinBid = <%= nextMinBid %>;
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
                const currentImageIdx = ref(0);
                let timer = null;

                onMounted(() => { timer = setInterval(() => { now.value = Date.now(); }, 1000); });
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
                                toast(data.message || '出价失败', 'error');
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
                    canEdit, canOffline, offlineItem
                };
            }
        }).mount('#app');
    });
</script>
</body>
</html>
