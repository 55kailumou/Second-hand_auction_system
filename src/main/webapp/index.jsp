<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ page import="org.example.entity.Notice" %>
<%@ page import="org.example.entity.Category" %>
<%@ page import="org.example.entity.AuctionItem" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.LinkedHashMap" %>
<%@ page import="java.util.HashMap" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    // ============== 首页全部数据集中查询 ==============
    List<Notice> topNotices = new java.util.ArrayList<>();
    List<Category> topCategories = new java.util.ArrayList<>();   // 一级分类（侧栏 + 色块）
    Map<Integer, Integer> catCountMap = new HashMap<>();         // 一级分类 → 拍品数
    int totalItemCount = 0;                                       // 总数（"全部"）
    AuctionItem heroItem = null;                                  // Hero 主推：跨 status，按 create_time DESC 取最新发布的拍品（不论拍卖中 / 已成交 / 已流拍 / 已下架都展示）
    Map<Integer, List<AuctionItem>> catItemsMap = new LinkedHashMap<>(); // 一级分类 ID → top3 拍品
    List<AuctionItem> hotItems = new java.util.ArrayList<>();     // 12 个推荐商品（按 view_count DESC）
    Map<Integer, org.example.entity.User> hotItemSellerMap = new HashMap<>();   // item_id → 卖家
    Map<Integer, Integer> hotItemBidCountMap = new HashMap<>();  // item_id → 出价人数
    // 子分类（用于 trending tags + 热搜词）
    List<Category> allSubCategories = new java.util.ArrayList<>();

    try (org.apache.ibatis.session.SqlSession _sql =
                 org.example.util.MyBatisUtil.openSession()) {
        org.example.mapper.NoticeMapper noticeMapper =
                _sql.getMapper(org.example.mapper.NoticeMapper.class);
        org.example.mapper.CategoryMapper categoryMapper =
                _sql.getMapper(org.example.mapper.CategoryMapper.class);
        org.example.mapper.AuctionItemMapper itemMapper =
                _sql.getMapper(org.example.mapper.AuctionItemMapper.class);
        org.example.mapper.BidRecordMapper bidMapper =
                _sql.getMapper(org.example.mapper.BidRecordMapper.class);

        // 公告
        topNotices = noticeMapper.findPublished(5);

        // 一级分类 + 拍品数
        topCategories = categoryMapper.findTopLevel();
        for (Category c : topCategories) {
            int cnt = categoryMapper.countItemsByCategory(c.getId());
            // 加上二级分类的拍品数
            List<Category> subs = categoryMapper.findByParentId(c.getId());
            for (Category sub : subs) {
                cnt += categoryMapper.countItemsByCategory(sub.getId());
                allSubCategories.add(sub);
            }
            catCountMap.put(c.getId(), cnt);
            totalItemCount += cnt;
        }

        // Hero 主推：跨 status（不论拍卖中 / 已成交 / 已流拍 / 已下架），按 create_time DESC 取最新发布的拍品
        // 说明：原版 heroParams.put("status", 1) 只查拍卖中，数据库里没有 status=1 的拍品时 heroItem 为 null → 首页"暂无拍品"
        //      改用 findRecent(1) 跨 status 取最新发布的一条，hero 永远有内容可显示
        List<AuctionItem> heroList = itemMapper.findRecent(1);
        if (heroList != null && !heroList.isEmpty()) {
            heroItem = heroList.get(0);
        }

        // 4 个分类色块：取前 4 个一级分类（跳过"其他"），每个 top 3
        int blocks = 0;
        for (Category c : topCategories) {
            if (c.getId() == 7) continue;  // 跳过"其他"
            if (blocks >= 4) break;
            List<AuctionItem> items = itemMapper.findHotByTopCategory(c.getId(), 3);
            catItemsMap.put(c.getId(), items);
            blocks++;
        }

        // 12 个推荐商品（按 view_count DESC，跨 status）
        java.util.Map<String, Object> hotParams = new java.util.HashMap<>();
        hotParams.put("sort", "hot");
        hotParams.put("limit", 12);
        hotItems = itemMapper.findByCondition(hotParams);

        // 12 个商品的卖家信息 + 出价人数（避免 N+1）
        org.example.mapper.UserMapper userMapper =
                _sql.getMapper(org.example.mapper.UserMapper.class);
        for (AuctionItem item : hotItems) {
            if (item.getSellerId() != null) {
                hotItemSellerMap.put(item.getId(), userMapper.findById(item.getSellerId()));
                hotItemBidCountMap.put(item.getId(), bidMapper.countBiddersByItem(item.getId()));
            }
        }

    } catch (Exception _e) {
        _e.printStackTrace();
    }

    // 把数据放到 page scope（让 EL / JSTL 能拿到）
    pageContext.setAttribute("topCategories", topCategories);
    pageContext.setAttribute("catCountMap", catCountMap);
    pageContext.setAttribute("totalItemCount", totalItemCount);
    pageContext.setAttribute("heroItem", heroItem);
    pageContext.setAttribute("hotItems", hotItems);
    pageContext.setAttribute("hotItemSellerMap", hotItemSellerMap);
    pageContext.setAttribute("hotItemBidCountMap", hotItemBidCountMap);
    pageContext.setAttribute("catItemsMap", catItemsMap);
    pageContext.setAttribute("allSubCategories", allSubCategories);

    // 侧边栏分类名 → Font Awesome 图标
    java.util.Map<String, String> catIconMap = new java.util.HashMap<>();
    catIconMap.put("数码电子", "fa-mobile");
    catIconMap.put("服饰鞋帽", "fa-tag");
    catIconMap.put("图书音像", "fa-book");
    catIconMap.put("家居生活", "fa-home");
    catIconMap.put("运动户外", "fa-futbol-o");
    catIconMap.put("美妆护肤", "fa-paint-brush");
    catIconMap.put("其他",   "fa-th");
    pageContext.setAttribute("catIconMap", catIconMap);
%>
<%!
    // 信用分转文字（首页用）
    private String creditText(Integer score) {
        if (score == null) return "一般";
        if (score >= 95) return "极好";
        if (score >= 80) return "良好";
        if (score >= 60) return "一般";
        return "较差";
    }
    // 倒计时格式化（end_time → "HH:mm:ss" 或 "X 天 Y 小时"）
    private String formatCountdown(java.time.LocalDateTime endTime) {
        if (endTime == null) return "";
        java.time.Duration d = java.time.Duration.between(java.time.LocalDateTime.now(), endTime);
        if (d.isNegative()) return "已结束";
        long days = d.toDays();
        long hours = d.toHours() % 24;
        long mins = d.toMinutes() % 60;
        long secs = d.toSeconds() % 60;
        if (days > 0) return days + "天" + hours + "时";
        return String.format("%02d:%02d:%02d", hours, mins, secs);
    }
    // 价格格式化（2000.00 → "2,000"，20260622 → "20,260,622"）
    private String formatPrice(java.math.BigDecimal price) {
        if (price == null) return "0";
        return String.format("%,d", price.longValue());
    }
%><!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>二手拍卖 · 首页 · Cyberpunk 2077</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
    /* ============================================================
       Cyberpunk 2077 风格设计令牌（基于 home-cyberpunk.html v4）
       - 主色：#FFEE00（荧光黄）
       - 辅色：#00F0FF（青蓝）、#FF003C（赛博红）
       - 背景：#000 纯黑 + 网格 + 噪点 + 扫描线
       - 字体：系统字体 + italic 倾斜 + 大写
       - 切角：clip-path 斜切多边形
       - 辉光：text-shadow / box-shadow 黄色光晕
       ============================================================ */
    @font-face {
        font-family: 'Sarasa Mono SC';
        font-weight: 400;
        font-style: normal;
        src: url('<%=ctx%>/static/fonts/SarasaMonoSC-Regular.ttf') format('truetype');
        font-display: swap;
    }
    @font-face {
        font-family: 'Sarasa Mono SC';
        font-weight: 700;
        font-style: normal;
        src: url('<%=ctx%>/static/fonts/SarasaMonoSC-Bold.ttf') format('truetype');
        font-display: swap;
    }
    @font-face {
        font-family: 'Sarasa Mono SC';
        font-weight: 400;
        font-style: italic;
        src: url('<%=ctx%>/static/fonts/SarasaMonoSC-Italic.ttf') format('truetype');
        font-display: swap;
    }

    :root {
        --cp-yellow:  #FFEE00;
        --cp-yellow-dim: #C8BD00;
        --cp-cyan:   #00F0FF;
        --cp-red:    #FF003C;
        --cp-bg:     #000000;
        --cp-bg-2:   #0a0a0a;
        --cp-bg-3:   #141414;
        --cp-line:   #FFEE00;
        --cp-text:   #FFEE00;
        --cp-text-dim: #8a8a3a;

        --font-mono: "Sarasa Mono SC", "Consolas", "Cascadia Code", "JetBrains Mono", "Courier New", monospace;
        --font-display: "Sarasa Mono SC", -apple-system, BlinkMacSystemFont, "Microsoft YaHei", "Impact", sans-serif;
    }

    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { height: 100%; }
    body {
        font-family: var(--font-display);
        font-size: 14px;
        color: var(--cp-text);
        background: var(--cp-bg);
        line-height: 1.5;
        -webkit-font-smoothing: antialiased;
        overflow-x: hidden;
    }

    /* ============================================================
       全局背景：噪点 + 扫描线 + 网格
       ============================================================ */
    body::before {
        /* 噪点纹理 */
        content: '';
        position: fixed; inset: 0;
        background-image:
            radial-gradient(rgba(255,238,0,0.04) 1px, transparent 1px),
            radial-gradient(rgba(255,238,0,0.02) 1px, transparent 1px);
        background-size: 4px 4px, 8px 8px;
        background-position: 0 0, 2px 2px;
        pointer-events: none;
        z-index: 1;
        mix-blend-mode: screen;
    }
    body::after {
        /* CRT 扫描线 */
        content: '';
        position: fixed; inset: 0;
        background: repeating-linear-gradient(
            to bottom,
            transparent 0,
            transparent 2px,
            rgba(0,0,0,0.15) 3px,
            rgba(0,0,0,0.15) 4px
        );
        pointer-events: none;
        z-index: 2;
    }

    a { color: var(--cp-yellow); text-decoration: none; }
    button { font-family: inherit; cursor: pointer; border: none; background: none; color: inherit; }
    input { font-family: inherit; }

    /* ============================================================
       装饰元素
       ============================================================ */
    .scanline {
        position: absolute; left: 0; right: 0; height: 1px;
        background: linear-gradient(90deg, transparent, var(--cp-yellow), transparent);
        animation: scan 4s linear infinite;
        opacity: 0.6;
    }
    @keyframes scan {
        0% { top: 0%; }
        100% { top: 100%; }
    }

    .module-tag {
        font-family: var(--font-mono);
        font-size: 11px;
        color: var(--cp-yellow-dim);
        letter-spacing: 0.15em;
        text-transform: uppercase;
        margin-bottom: 8px;
        display: flex; align-items: center; gap: 6px;
    }
    .module-tag::before { content: '//'; color: var(--cp-yellow-dim); }

    /* 切角按钮 */
    .btn-cp {
        position: relative; display: inline-flex; align-items: center; gap: 8px;
        padding: 10px 28px;
        background: var(--cp-yellow); color: #000;
        font-weight: 800; font-size: 14px; letter-spacing: 0.05em;
        text-transform: uppercase;
        clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
        transition: all 0.2s;
        border: none;
        cursor: pointer;
    }
    .btn-cp:hover {
        background: #fff;
        box-shadow: 0 0 24px rgba(255,238,0,0.6), 0 0 4px var(--cp-yellow);
        transform: translateY(-1px);
    }
    .btn-cp.outline {
        background: transparent; color: var(--cp-yellow);
        border: 1.5px solid var(--cp-yellow);
        box-shadow: 0 0 0 0 transparent;
    }
    .btn-cp.outline:hover {
        background: var(--cp-yellow); color: #000;
        box-shadow: 0 0 24px rgba(255,238,0,0.5);
    }

    /* ============================================================
       1. 顶部导航（黑底 + 黄色切角 + 斜切）
       ============================================================ */
    .nav {
        position: sticky; top: 0; z-index: 100;
        background: #000;
        border-bottom: 1px solid var(--cp-yellow);
        box-shadow: 0 2px 0 var(--cp-yellow), 0 4px 24px rgba(255,238,0,0.15);
    }
    .nav::after {
        content: '';
        position: absolute; bottom: -4px; left: 0; right: 0; height: 1px;
        background: linear-gradient(90deg, transparent, var(--cp-yellow), transparent);
        opacity: 0.4;
    }
    .nav-inner {
        max-width: 1200px; margin: 0 auto;
        padding: 0 24px; height: 60px;
        display: flex; align-items: center; gap: 24px;
    }
    .logo {
        font-size: 22px; font-weight: 900; font-style: italic;
        color: var(--cp-yellow);
        text-transform: uppercase; letter-spacing: -0.01em;
        display: flex; align-items: center; gap: 10px;
        text-shadow: 0 0 12px rgba(255,238,0,0.4);
        white-space: nowrap;
        flex-shrink: 0;
    }
    .logo::before {
        content: ''; width: 30px; height: 30px;
        background: var(--cp-yellow);
        clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
    }
    .nav-menu { display: flex; gap: 8px; flex-wrap: nowrap; }
    .nav-menu a {
        position: relative;
        padding: 6px 16px 8px;
        font-size: 13px; font-weight: 700;
        text-transform: uppercase; letter-spacing: 0.05em;
        color: var(--cp-text);
        transition: all 0.2s;
        clip-path: polygon(6px 0, 100% 0, calc(100% - 6px) 100%, 0 100%);
        cursor: pointer;
        white-space: nowrap;
        flex-shrink: 0;
        line-height: 1.3;
    }
    .nav-menu a::before {
        content: '//';
        display: block;
        font-size: 9px;
        color: var(--cp-yellow-dim);
        font-weight: 600;
        margin-bottom: 2px;
        letter-spacing: 0;
    }
    .nav-menu a:hover, .nav-menu a.active {
        background: var(--cp-yellow); color: #000;
        text-shadow: none;
    }
    .nav-menu a.active { box-shadow: 0 0 16px rgba(255,238,0,0.4); }

    .nav-search {
        flex: 0 1 360px;
        position: relative;
        display: flex;
        background: #000;
        border: 1.5px solid var(--cp-yellow);
        clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
    }
    .nav-search input {
        flex: 1; padding: 0 16px;
        border: none; outline: none;
        background: transparent;
        font-size: 13px; color: var(--cp-yellow);
        font-family: var(--font-mono);
    }
    .nav-search input::placeholder { color: var(--cp-text-dim); }
    .nav-search button {
        background: var(--cp-yellow); color: #000;
        font-weight: 800; font-size: 12px;
        padding: 0 18px;
        text-transform: uppercase;
    }
    .nav-search button:hover { background: #fff; }

    .nav-tags {
        display: flex; gap: 12px; font-size: 11px;
        color: var(--cp-text-dim); font-family: var(--font-mono);
        flex: 1; min-width: 0; overflow: hidden;
        text-transform: uppercase;
    }
    .nav-tags-label { flex-shrink: 0; }
    .nav-tag { white-space: nowrap; transition: all 0.15s; cursor: pointer; }
    .nav-tag:hover { color: var(--cp-cyan); text-shadow: 0 0 8px var(--cp-cyan); }

    .nav-user { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
    .nav-user .icon-btn {
        width: 36px; height: 36px;
        display: grid; place-items: center;
        background: #000; color: var(--cp-yellow);
        border: 1px solid var(--cp-yellow);
        clip-path: polygon(15% 0, 100% 0, 85% 100%, 0 100%);
        position: relative; transition: all 0.15s;
        font-size: 14px;
        cursor: pointer;
    }
    .nav-user .icon-btn:hover { background: var(--cp-yellow); color: #000; }
    .nav-user .icon-btn .dot {
        position: absolute; top: 6px; right: 6px;
        width: 8px; height: 8px;
        background: var(--cp-red);
        border: 1px solid #000; border-radius: 50%;
        box-shadow: 0 0 6px var(--cp-red);
    }
    .nav-user .avatar {
        width: 36px; height: 36px;
        background: var(--cp-yellow); color: #000;
        display: grid; place-items: center;
        font-size: 14px; font-weight: 900;
        clip-path: polygon(15% 0, 100% 0, 85% 100%, 0 100%);
        font-style: italic;
        cursor: pointer;
    }

    /* ============================================================
       2. HERO（赛博朋克 2077 风：黑底 + 黄色大标题 + 装饰元素）
       ============================================================ */
    .hero {
        position: relative;
        padding: 80px 24px 60px;
        background:
            radial-gradient(ellipse at 20% 50%, rgba(255,238,0,0.08) 0%, transparent 50%),
            radial-gradient(ellipse at 80% 80%, rgba(0,240,255,0.05) 0%, transparent 40%),
            #000;
        overflow: hidden;
        border-bottom: 1px solid var(--cp-yellow);
    }
    .hero::before {
        content: '';
        position: absolute; inset: 0;
        background-image:
            linear-gradient(rgba(255,238,0,0.06) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,238,0,0.06) 1px, transparent 1px);
        background-size: 60px 60px;
        pointer-events: none;
    }
    .hero::after {
        content: '';
        position: absolute; top: 0; left: 0; right: 0; height: 4px;
        background: linear-gradient(90deg, var(--cp-yellow) 0%, var(--cp-cyan) 50%, var(--cp-red) 100%);
        box-shadow: 0 0 16px var(--cp-yellow);
    }

    .hero-inner {
        position: relative; z-index: 2;
        max-width: 1200px; margin: 0 auto;
        display: grid; grid-template-columns: 1.4fr 1fr; gap: 48px;
        align-items: center;
    }

    .hero-left .module-tag { color: var(--cp-cyan); }
    .hero-left .module-tag::before { color: var(--cp-cyan); }

    .hero-eyebrow {
        display: inline-flex; align-items: center; gap: 8px;
        padding: 6px 16px;
        background: rgba(255,238,0,0.1);
        border: 1px solid var(--cp-yellow);
        color: var(--cp-yellow);
        font-family: var(--font-mono); font-size: 11px;
        text-transform: uppercase; letter-spacing: 0.15em;
        clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
        margin-bottom: 24px;
    }
    .hero-eyebrow i { color: var(--cp-yellow); animation: pulse 1.5s infinite; }
    @keyframes pulse {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.3; }
    }

    .hero-title {
        font-size: 64px; font-weight: 900; font-style: italic;
        line-height: 0.95; margin-bottom: 16px;
        text-transform: uppercase;
        color: var(--cp-yellow);
        text-shadow:
            4px 0 0 rgba(0,240,255,0.6),
            -4px 0 0 rgba(255,0,60,0.6),
            0 0 24px rgba(255,238,0,0.4);
    }
    .hero-title .accent {
        display: block;
        color: #000;
        background: var(--cp-yellow);
        padding: 0 12px;
        margin-top: 4px;
        width: fit-content;
        clip-path: polygon(0 0, 100% 0, 95% 100%, 0 100%);
        text-shadow: none;
    }

    .hero-sub {
        color: var(--cp-text-dim);
        font-size: 15px;
        max-width: 520px;
        margin-bottom: 28px;
        line-height: 1.7;
        border-left: 2px solid var(--cp-yellow);
        padding-left: 14px;
    }

    .hero-search {
        display: flex;
        background: #000;
        border: 1.5px solid var(--cp-yellow);
        clip-path: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
        margin-bottom: 20px;
        max-width: 540px;
        box-shadow: 0 0 24px rgba(255,238,0,0.15);
    }
    .hero-search-icon {
        display: grid; place-items: center;
        padding: 0 16px;
        background: var(--cp-yellow); color: #000;
        font-weight: 900;
    }
    .hero-search input {
        flex: 1; padding: 16px 18px;
        border: none; outline: none;
        font-size: 14px; color: var(--cp-yellow);
        background: transparent;
        font-family: var(--font-mono);
    }
    .hero-search input::placeholder { color: var(--cp-text-dim); }
    .hero-search button {
        background: var(--cp-yellow); color: #000;
        font-size: 14px; font-weight: 800; padding: 0 28px;
        text-transform: uppercase; letter-spacing: 0.05em;
        transition: all 0.15s;
    }
    .hero-search button:hover { background: #fff; box-shadow: 0 0 16px var(--cp-yellow); }

    .hero-tags { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
    .hero-tags-label {
        font-family: var(--font-mono); font-size: 11px;
        color: var(--cp-text-dim); margin-right: 4px;
        text-transform: uppercase;
    }
    .hero-tag {
        padding: 6px 14px;
        background: rgba(255,238,0,0.05);
        border: 1px solid var(--cp-yellow);
        color: var(--cp-yellow);
        font-size: 12px; font-family: var(--font-mono);
        text-transform: uppercase; letter-spacing: 0.05em;
        clip-path: polygon(6px 0, 100% 0, 100% calc(100% - 6px), calc(100% - 6px) 100%, 0 100%, 0 6px);
        transition: all 0.15s; cursor: pointer;
    }
    .hero-tag:hover {
        background: var(--cp-yellow); color: #000;
        box-shadow: 0 0 12px rgba(255,238,0,0.5);
    }

    /* 右侧主推卡片 */
    .hero-card {
        position: relative;
        background: #000;
        border: 1.5px solid var(--cp-yellow);
        clip-path: polygon(0 0, calc(100% - 24px) 0, 100% 24px, 100% 100%, 24px 100%, 0 calc(100% - 24px));
        box-shadow: 0 0 32px rgba(255,238,0,0.15), inset 0 0 16px rgba(255,238,0,0.05);
        overflow: hidden;
        transition: all 0.3s;
        cursor: pointer;
    }
    .hero-card:hover {
        box-shadow: 0 0 48px rgba(255,238,0,0.4), inset 0 0 24px rgba(255,238,0,0.1);
        transform: translateY(-4px);
    }
    .hero-card::before {
        content: '';
        position: absolute; top: 0; left: 0; right: 0; height: 2px;
        background: linear-gradient(90deg, var(--cp-yellow), var(--cp-cyan), var(--cp-red));
        z-index: 1;
    }

    .hero-card-cover {
        width: 100%;
        aspect-ratio: 16/10;
        background:
            radial-gradient(ellipse at center, rgba(255,238,0,0.2) 0%, transparent 60%),
            linear-gradient(135deg, #1a1a1a 0%, #000 100%);
        position: relative;
        display: grid; place-items: center;
        overflow: hidden;
    }
    .hero-card-cover::before {
        content: '';
        position: absolute; inset: 0;
        background-image:
            linear-gradient(rgba(255,238,0,0.1) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,238,0,0.1) 1px, transparent 1px);
        background-size: 30px 30px;
    }
    .hero-card-cover i {
        font-size: 96px;
        color: var(--cp-yellow);
        text-shadow: 0 0 32px var(--cp-yellow);
        position: relative; z-index: 1;
        filter: drop-shadow(0 0 16px var(--cp-yellow));
    }
    .hero-card-badge {
        position: absolute; top: 14px; left: 14px;
        padding: 4px 12px;
        background: var(--cp-red); color: #fff;
        font-size: 11px; font-weight: 800;
        text-transform: uppercase; letter-spacing: 0.1em;
        clip-path: polygon(6px 0, 100% 0, 100% calc(100% - 6px), calc(100% - 6px) 100%, 0 100%, 0 6px);
        box-shadow: 0 0 12px var(--cp-red);
        display: flex; align-items: center; gap: 4px;
        z-index: 2;
    }
    .hero-card-badge i { color: #fff; text-shadow: none; animation: pulse 1s infinite; }
    .hero-card-body { padding: 20px; position: relative; z-index: 1; }
    .hero-card-title {
        font-size: 16px; font-weight: 700;
        color: var(--cp-yellow);
        line-height: 1.4; margin-bottom: 16px;
        display: -webkit-box; -webkit-line-clamp: 1; -webkit-box-orient: vertical; overflow: hidden;
        text-shadow: 0 0 8px rgba(255,238,0,0.3);
    }
    .hero-card-meta {
        display: flex; align-items: center; justify-content: space-between;
        padding: 14px 16px;
        background: rgba(255,238,0,0.05);
        border: 1px solid var(--cp-yellow);
        margin-bottom: 14px;
        clip-path: polygon(6px 0, 100% 0, 100% calc(100% - 6px), calc(100% - 6px) 100%, 0 100%, 0 6px);
    }
    .hero-card-meta-label {
        font-size: 10px; color: var(--cp-text-dim);
        font-family: var(--font-mono);
        text-transform: uppercase; letter-spacing: 0.1em;
        margin-bottom: 4px;
    }
    .hero-card-price {
        font-size: 28px; font-weight: 900; font-style: italic;
        color: var(--cp-yellow);
        line-height: 1;
        text-shadow: 0 0 12px var(--cp-yellow);
    }
    .hero-card-price small { font-size: 14px; margin-right: 2px; }
    .hero-card-countdown {
        font-family: var(--font-mono);
        font-size: 18px; font-weight: 700;
        color: var(--cp-red);
        letter-spacing: 0.1em;
        text-shadow: 0 0 8px var(--cp-red);
    }
    .hero-card-cta {
        width: 100%;
        padding: 14px;
        background: var(--cp-yellow); color: #000;
        font-weight: 900; font-size: 14px;
        text-transform: uppercase; letter-spacing: 0.1em;
        clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
        transition: all 0.15s;
        display: flex; align-items: center; justify-content: center; gap: 6px;
        cursor: pointer;
    }
    .hero-card-cta:hover {
        background: #fff;
        box-shadow: 0 0 24px var(--cp-yellow);
        text-shadow: 0 0 8px #000;
    }

    /* ============================================================
       公告 banner（黑底 + 黄边）
       ============================================================ */
    .notice-bar {
        background: rgba(0,0,0,0.85);
        border-top: 1px solid var(--cp-yellow);
        border-bottom: 1px solid var(--cp-yellow);
        padding: 10px 24px;
        display: flex; align-items: center; gap: 12px;
        font-size: 13px;
        color: var(--cp-text);
        font-family: var(--font-mono);
        position: relative; z-index: 4;
    }
    .notice-bar-icon {
        width: 28px; height: 28px;
        background: var(--cp-yellow); color: #000;
        display: grid; place-items: center;
        font-size: 13px; font-weight: 900; flex-shrink: 0;
        clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
    }
    .notice-bar-list {
        flex: 1; min-width: 0;
        display: flex; flex-direction: column; gap: 4px;
        overflow: hidden;
    }
    .notice-bar-item {
        display: flex; align-items: center; gap: 8px;
        overflow: hidden;
    }
    .notice-bar-item .top-tag {
        padding: 1px 6px; background: var(--cp-red); color: #fff;
        font-size: 10px; font-weight: 800; flex-shrink: 0;
    }
    .notice-bar-item a {
        color: var(--cp-yellow); font-weight: 700;
        overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
        flex: 1; min-width: 0;
        text-decoration: none;
    }
    .notice-bar-item a:hover { color: var(--cp-cyan); text-shadow: 0 0 8px var(--cp-cyan); }
    .notice-bar-item .time {
        color: var(--cp-text-dim); font-size: 11px; flex-shrink: 0;
    }

    /* ============================================================
       3. 主体三栏：左分类 / 中内容 / 右浮动
       ============================================================ */
    .main {
        max-width: 1200px; margin: 24px auto 0;
        padding: 0 24px;
        display: grid;
        grid-template-columns: 220px 1fr 48px;
        gap: 16px;
        align-items: start;
        position: relative; z-index: 3;
    }

    /* 左侧分类侧栏 */
    .sidebar {
        background: #000;
        border: 1.5px solid var(--cp-yellow);
        clip-path: polygon(0 0, calc(100% - 16px) 0, 100% 16px, 100% 100%, 16px 100%, 0 calc(100% - 16px));
        position: sticky; top: 80px;
        box-shadow: 0 0 24px rgba(255,238,0,0.1);
    }
    .sidebar-head {
        padding: 12px 16px;
        border-bottom: 1px solid var(--cp-yellow);
        background: rgba(255,238,0,0.05);
    }
    .sidebar-title {
        font-family: var(--font-mono);
        font-size: 11px; color: var(--cp-yellow);
        text-transform: uppercase; letter-spacing: 0.15em;
        font-weight: 700;
    }
    .cat-list { list-style: none; padding: 8px 0; }
    .cat-item { position: relative; }
    .cat-link {
        display: flex; align-items: center; gap: 12px;
        padding: 10px 16px; font-size: 13px;
        color: var(--cp-text);
        transition: all 0.15s;
        border-left: 2px solid transparent;
        font-family: var(--font-mono);
        text-transform: uppercase;
        letter-spacing: 0.05em;
        cursor: pointer;
    }
    .cat-link i {
        width: 16px; color: var(--cp-text-dim);
        text-align: center; font-size: 13px; transition: color 0.15s;
    }
    .cat-link:hover, .cat-link.active {
        background: rgba(255,238,0,0.1);
        color: var(--cp-yellow);
        border-left-color: var(--cp-yellow);
        text-shadow: 0 0 8px var(--cp-yellow);
    }
    .cat-link:hover i, .cat-link.active i { color: var(--cp-yellow); }
    .cat-link .count {
        margin-left: auto; font-size: 10px;
        color: var(--cp-text-dim);
        padding: 2px 6px;
        background: rgba(255,238,0,0.05);
        border: 1px solid var(--cp-yellow-dim);
    }
    .cat-link.active .count { color: var(--cp-yellow); border-color: var(--cp-yellow); }

    /* 中央内容 */
    .content { min-width: 0; }

    /* 4 分类色块 */
    .feature {
        display: grid; grid-template-columns: 1fr 1fr; gap: 12px;
        margin-bottom: 16px;
    }
    .cb {
        position: relative;
        background: #000;
        border: 1.5px solid var(--cp-yellow);
        padding: 14px;
        min-height: 140px;
        cursor: pointer;
        transition: all 0.2s;
        clip-path: polygon(0 0, calc(100% - 10px) 0, 100% 10px, 100% 100%, 10px 100%, 0 calc(100% - 10px));
        overflow: hidden;
    }
    .cb:hover {
        box-shadow: 0 0 24px rgba(255,238,0,0.4);
        transform: translateY(-2px);
    }
    .cb-head {
        display: flex; align-items: center; justify-content: space-between;
        margin-bottom: 8px;
        position: relative; z-index: 1;
    }
    .cb-title {
        font-size: 13px; font-weight: 800;
        color: var(--cp-yellow);
        text-transform: uppercase; letter-spacing: 0.05em;
        display: flex; align-items: center; gap: 5px;
    }
    .cb-title .arrow { color: var(--cp-text-dim); font-size: 10px; }
    .cb-sub {
        font-size: 11px; color: var(--cp-text-dim);
        font-family: var(--font-mono);
        text-transform: uppercase; letter-spacing: 0.05em;
        margin-bottom: 8px;
    }
    .cb-thumbs {
        display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px;
        position: relative; z-index: 1;
    }
    .cb-thumb {
        aspect-ratio: 1;
        background: rgba(255,238,0,0.05);
        border: 1px solid var(--cp-yellow);
        display: grid; place-items: center;
        position: relative; overflow: hidden;
    }
    .cb-thumb i { font-size: 18px; color: var(--cp-yellow-dim); }
    .cb-thumb .price {
        position: absolute; bottom: 0; left: 0; right: 0;
        background: rgba(0,0,0,0.85); color: var(--cp-yellow);
        font-size: 10px; font-weight: 700; text-align: center;
        padding: 2px 0;
        font-family: var(--font-mono);
        border-top: 1px solid var(--cp-yellow);
    }
    .cb-icon {
        font-size: 20px;
        color: var(--cp-yellow);
        text-shadow: 0 0 8px var(--cp-yellow);
        flex-shrink: 0;
        line-height: 1;
    }

    /* Tabs + Grid */
    .grid-section {
        background: #000;
        border: 1.5px solid var(--cp-yellow);
        clip-path: polygon(0 0, calc(100% - 16px) 0, 100% 16px, 100% 100%, 16px 100%, 0 calc(100% - 16px));
        box-shadow: 0 0 24px rgba(255,238,0,0.1);
    }
    .tabs {
        display: flex; align-items: center; gap: 4px;
        padding: 14px 16px;
        border-bottom: 1px solid var(--cp-yellow);
        background: rgba(255,238,0,0.03);
        position: relative;
    }
    .tabs::before {
        content: ''; position: absolute; top: 0; left: 16px; right: 16px; height: 2px;
        background: linear-gradient(90deg, var(--cp-yellow), transparent 50%, var(--cp-cyan));
        opacity: 0.5;
    }
    .tab {
        padding: 6px 16px; font-size: 12px;
        color: var(--cp-text-dim);
        font-family: var(--font-mono);
        text-transform: uppercase; letter-spacing: 0.05em;
        cursor: pointer; transition: all 0.15s;
        font-weight: 700;
        clip-path: polygon(6px 0, 100% 0, 100% calc(100% - 6px), calc(100% - 6px) 100%, 0 100%, 0 6px);
    }
    .tab:hover { color: var(--cp-yellow); background: rgba(255,238,0,0.1); }
    .tab.active {
        background: var(--cp-yellow); color: #000;
        box-shadow: 0 0 16px rgba(255,238,0,0.5);
    }
    .tabs-right {
        margin-left: auto; display: flex; gap: 12px;
        font-size: 11px; color: var(--cp-text-dim);
        font-family: var(--font-mono);
        text-transform: uppercase; letter-spacing: 0.05em;
    }
    .tabs-right a:hover { color: var(--cp-cyan); text-shadow: 0 0 6px var(--cp-cyan); }

    /* 6 列商品网格 */
    .goods-grid {
        display: grid; grid-template-columns: repeat(6, 1fr);
        gap: 12px; padding: 16px;
    }
    .goods-card {
        position: relative;
        background: #000;
        border: 1px solid var(--cp-yellow-dim);
        overflow: hidden;
        cursor: pointer;
        transition: all 0.2s;
        clip-path: polygon(0 0, calc(100% - 8px) 0, 100% 8px, 100% 100%, 8px 100%, 0 calc(100% - 8px));
    }
    .goods-card:hover {
        border-color: var(--cp-yellow);
        box-shadow: 0 0 16px rgba(255,238,0,0.4);
        transform: translateY(-2px);
    }
    .goods-card::before {
        content: '';
        position: absolute; top: 0; left: 0; right: 0; height: 1px;
        background: linear-gradient(90deg, var(--cp-yellow), var(--cp-cyan));
        opacity: 0; transition: opacity 0.2s;
    }
    .goods-card:hover::before { opacity: 1; }
    .goods-cover {
        width: 100%; aspect-ratio: 1;
        background:
            radial-gradient(ellipse at center, rgba(255,238,0,0.08) 0%, transparent 70%),
            #0a0a0a;
        display: grid; place-items: center;
        position: relative;
        overflow: hidden;
        border-bottom: 1px solid var(--cp-yellow-dim);
    }
    .goods-cover::before {
        content: '';
        position: absolute; inset: 0;
        background-image: linear-gradient(rgba(255,238,0,0.05) 1px, transparent 1px),
                          linear-gradient(90deg, rgba(255,238,0,0.05) 1px, transparent 1px);
        background-size: 20px 20px;
    }
    .goods-cover i {
        font-size: 36px;
        color: var(--cp-yellow);
        text-shadow: 0 0 12px var(--cp-yellow);
        position: relative; z-index: 1;
    }
    .goods-cover .tag {
        position: absolute; top: 6px; left: 6px;
        padding: 2px 8px;
        background: var(--cp-red); color: #fff;
        font-size: 10px; font-weight: 800;
        text-transform: uppercase; letter-spacing: 0.05em;
        clip-path: polygon(4px 0, 100% 0, 100% calc(100% - 4px), calc(100% - 4px) 100%, 0 100%, 0 4px);
        z-index: 2;
    }
    .goods-cover .tag.warning { background: var(--cp-yellow); color: #000; }
    .goods-cover .tag.info { background: var(--cp-cyan); color: #000; }
    .goods-body { padding: 10px 10px 12px; }
    .goods-title {
        font-size: 12px; line-height: 1.4; margin-bottom: 8px;
        min-height: 34px;
        color: var(--cp-text);
        display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        font-family: var(--font-mono);
    }
    .goods-price-row {
        display: flex; align-items: baseline; justify-content: space-between;
        margin-bottom: 6px;
        padding-bottom: 6px;
        border-bottom: 1px dashed var(--cp-yellow-dim);
    }
    .goods-price {
        font-size: 15px; font-weight: 900; font-style: italic;
        color: var(--cp-yellow);
        line-height: 1;
        text-shadow: 0 0 8px rgba(255,238,0,0.4);
    }
    .goods-price small { font-size: 10px; margin-right: 1px; }
    .goods-bidders {
        font-size: 10px; color: var(--cp-text-dim);
        display: flex; align-items: center; gap: 3px;
        font-family: var(--font-mono);
    }
    .goods-foot {
        display: flex; align-items: center; gap: 5px;
        font-size: 10px; color: var(--cp-text-dim);
        font-family: var(--font-mono);
    }
    .goods-avatar {
        width: 16px; height: 16px; border-radius: 0;
        background: var(--cp-yellow); color: #000;
        display: grid; place-items: center;
        font-size: 9px; font-weight: 900; flex-shrink: 0;
        clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
    }
    .goods-seller { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .goods-credit {
        background: var(--cp-yellow); color: #000;
        font-size: 9px; padding: 1px 4px;
        font-weight: 800; flex-shrink: 0;
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }

    /* 右侧浮动操作栏 */
    .floats {
        position: sticky; top: 80px;
        display: flex; flex-direction: column; gap: 6px;
    }
    .float-btn {
        width: 48px; height: 48px;
        background: #000;
        color: var(--cp-yellow);
        border: 1.5px solid var(--cp-yellow);
        clip-path: polygon(20% 0, 100% 0, 80% 100%, 0 100%);
        display: flex; flex-direction: column;
        align-items: center; justify-content: center;
        transition: all 0.15s;
        cursor: pointer; font-size: 9px; gap: 1px;
        font-family: var(--font-mono);
        text-transform: uppercase; font-weight: 700;
        letter-spacing: 0.05em;
        text-decoration: none;
    }
    .float-btn i { font-size: 14px; }
    .float-btn:hover {
        background: var(--cp-yellow); color: #000;
        box-shadow: 0 0 16px var(--cp-yellow);
        transform: translateX(-2px);
    }
    .float-btn.primary {
        background: var(--cp-yellow); color: #000;
        box-shadow: 0 0 12px rgba(255,238,0,0.4);
    }

    /* 页脚 */
    .footer {
        margin-top: 48px;
        background: #000;
        border-top: 1px solid var(--cp-yellow);
        padding: 32px 24px 24px;
        position: relative; z-index: 3;
    }
    .footer::before {
        content: ''; position: absolute; top: -4px; left: 0; right: 0; height: 4px;
        background: linear-gradient(90deg, var(--cp-yellow) 0%, var(--cp-cyan) 50%, var(--cp-red) 100%);
        box-shadow: 0 0 16px var(--cp-yellow);
    }
    .footer-inner {
        max-width: 1200px; margin: 0 auto;
        display: grid;
        grid-template-columns: 1.5fr 1fr 1fr 1fr;
        gap: 40px;
        padding-bottom: 24px;
        border-bottom: 1px solid var(--cp-yellow-dim);
    }
    .footer-brand .logo { color: var(--cp-yellow); margin-bottom: 12px; }
    .footer-brand p {
        font-size: 12px; color: var(--cp-text-dim);
        line-height: 1.7; max-width: 320px;
        font-family: var(--font-mono);
    }
    .footer-col h4 {
        color: var(--cp-yellow); font-size: 12px; font-weight: 800;
        margin-bottom: 14px; text-transform: uppercase;
        letter-spacing: 0.1em; font-family: var(--font-mono);
    }
    .footer-col a {
        display: block; color: var(--cp-text-dim);
        font-size: 12px; padding: 4px 0;
        transition: color 0.15s; font-family: var(--font-mono);
    }
    .footer-col a i { margin-right: 6px; opacity: 0.7; }
    .footer-col a:hover { color: var(--cp-yellow); text-shadow: 0 0 6px var(--cp-yellow); }
    .footer-bottom {
        max-width: 1200px; margin: 18px auto 0;
        font-size: 11px; color: var(--cp-text-dim);
        text-align: center;
        font-family: var(--font-mono);
        text-transform: uppercase; letter-spacing: 0.1em;
    }

    /* ============================================================
       响应式
       ============================================================ */
    @media (max-width: 1200px) {
        .goods-grid { grid-template-columns: repeat(5, 1fr); }
        .main { grid-template-columns: 200px 1fr 48px; }
    }
    @media (max-width: 1024px) {
        .main { grid-template-columns: 180px 1fr; }
        .floats { display: none; }
        .feature { grid-template-columns: 1fr; }
        .goods-grid { grid-template-columns: repeat(4, 1fr); }
        .nav-tags { display: none; }
        .hero-inner { grid-template-columns: 1fr; }
        .hero-title { font-size: 48px; }
    }
    @media (max-width: 768px) {
        .main { grid-template-columns: 1fr; padding: 0 12px; }
        .sidebar { position: static; }
        .goods-grid { grid-template-columns: repeat(3, 1fr); }
        .nav-menu { display: none; }
        .nav-search { flex: 1; }
        .footer-inner { grid-template-columns: 1fr; }
        .hero-title { font-size: 36px; }
        .hero { padding: 48px 16px 40px; }
        .nav-inner { padding: 0 16px; gap: 12px; }
    }
    </style>
</head>
<body>

<!-- ========== 1. 顶部导航 ========== -->
<header class="nav">
    <div class="nav-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">赛博拍卖</a>
        <nav class="nav-menu">
            <a href="<%=ctx%>/index.jsp" class="active">首页</a>
            <a href="javascript:void(0)" onclick="go('/item?action=list')">浏览拍品</a>
            <a href="javascript:void(0)" onclick="go('/item?action=publish-page')">发布拍品</a>
            <a href="javascript:void(0)" onclick="go('/item?action=hot-ranks')">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('/user?action=center')">个人中心</a>
            <% } %>
        </nav>
        <div id="vue-root" style="display: contents;">
            <div class="nav-search">
                <input type="text" placeholder="> 搜索拍品..."
                       v-model="keyword" @keyup.enter="search">
                <button @click="search"><i class="fa fa-search"></i> 搜索</button>
            </div>
        </div>
        <div class="nav-user">
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('/user?action=center')" class="icon-btn" title="消息">
                    <i class="fa fa-envelope-o"></i><span class="dot"></span>
                </a>
                <a href="javascript:void(0)" onclick="go('/user?action=center')" class="icon-btn" title="用户">
                    <i class="fa fa-user-o"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/item?action=publish-page')" class="icon-btn" title="发布">
                    <i class="fa fa-plus"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/user?action=center')" class="avatar" title="<%= currentUser.getUsername() %>">
                    <%= currentUser.getUsername().substring(0, 1).toUpperCase() %>
                </a>
                <a href="<%=ctx%>/user?action=logout" class="icon-btn" title="退出登录" style="width:auto; padding:0 12px; font-size:11px;">
                    退出
                </a>
            <% } else { %>
                <a href="javascript:void(0)" onclick="go('/user?action=login')" class="icon-btn" title="消息">
                    <i class="fa fa-envelope-o"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/user?action=login')" class="icon-btn" title="登录">
                    <i class="fa fa-user-o"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/item?action=publish-page')" class="icon-btn" title="发布">
                    <i class="fa fa-plus"></i>
                </a>
                <a href="<%=ctx%>/user?action=login" class="avatar" title="登录">
                    <i class="fa fa-sign-in" style="font-size:14px;"></i>
                </a>
            <% } %>
        </div>
    </div>
</header>

<% if (topNotices != null && !topNotices.isEmpty()) { %>
<!-- ========== 公告 banner ========== -->
<div class="notice-bar">
    <div class="notice-bar-icon"><i class="fa fa-bullhorn"></i></div>
    <div class="notice-bar-list">
        <% for (Notice n : topNotices) { %>
            <div class="notice-bar-item">
                <% if (n.getIsTop() != null && n.getIsTop() == 1) { %>
                    <span class="top-tag">置顶</span>
                <% } %>
                <a href="javascript:void(0)" onclick="showNotice(<%= n.getId() %>)">
                    <%= org.example.util.EscapeUtil.html(n.getTitle()) %>
                </a>
                <span class="time">
                    <%= n.getPublishTime() == null ? "" : n.getPublishTime().toString().substring(0, 10) %>
                </span>
            </div>
        <% } %>
    </div>
</div>

<!-- ========== 公告详情弹窗（cyberpunk 风格） ========== -->
<div id="noticeModal" class="cp-modal-overlay" style="display:none;" onclick="if(event.target===this)closeNotice()">
    <div class="cp-modal">
        <div class="cp-modal-title">
            <span id="noticeTitle" style="flex:1; min-width:0; word-break:break-all;">公告</span>
            <span class="cp-modal-close" onclick="closeNotice()">&times;</span>
        </div>
        <div style="display:flex; align-items:center; gap:8px; font-size:11px; color:#888; margin-bottom:14px; padding-bottom:10px; border-bottom:1px solid rgba(255,238,0,0.15);">
            <i class="fa fa-clock-o"></i>
            <span id="noticeMeta"></span>
        </div>
        <div id="noticeContent" style="color:#ccc; line-height:1.8; font-size:14px; white-space:pre-wrap; max-height:50vh; overflow-y:auto; padding-right:4px;"></div>
        <div style="margin-top:18px; padding-top:14px; border-top:1px solid rgba(255,238,0,0.15); display:flex; gap:8px; justify-content:flex-end;">
            <button onclick="closeNotice()" style="padding:8px 24px; background:#FFEE00; color:#000; font-weight:700; border:none; cursor:pointer; font-family:inherit; font-size:13px; clip-path:polygon(8% 0, 100% 0, 92% 100%, 0 100%);">我知道了</button>
        </div>
    </div>
</div>
<script>
    // 公告详情弹窗（公开接口，无需管理员登录）
    window.showNotice = function(id) {
        loadAxios().then(() => {
            axios.get('<%= ctx %>/notice?action=detail&id=' + id).then(r => {
                if (r.data.success) {
                    const n = r.data.notice;
                    document.getElementById('noticeTitle').textContent = n.title || '公告';
                    // 把内容里的换行符保留（pre-wrap 起作用），并把可能的 HTML 标签转义防注入
                    document.getElementById('noticeContent').textContent = n.content || '';
                    const meta = [];
                    if (n.isTop === 1) meta.push('<span style="color:#FF003C;">[置顶]</span>');
                    if (n.publishTime) meta.push(n.publishTime.toString().substring(0, 16));
                    document.getElementById('noticeMeta').innerHTML = meta.join(' · ');
                    document.getElementById('noticeModal').style.display = 'flex';
                } else {
                    toast(r.data.message || '加载失败', 'error');
                }
            }).catch(() => toast('网络错误', 'error'));
        });
    };
    window.closeNotice = function() {
        document.getElementById('noticeModal').style.display = 'none';
    };
    // ESC 键关闭
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') closeNotice();
    });
</script>
<% } %>

<!-- ========== 2. HERO ========== -->
<section class="hero">
    <div class="scanline"></div>
    <div class="hero-inner">
        <!-- 左 -->
        <div class="hero-left">
            <div class="module-tag">在线拍卖网络</div>
            <span class="hero-eyebrow">
                <i class="fa fa-bolt"></i> // 实时竞拍 // 透明公开
            </span>
            <h1 class="hero-title">
                闲置流转<br>
                <span class="accent">价值新生</span>
            </h1>
            <p class="hero-sub">
                &gt;&gt; 登录参与 // 每一件废弃之物寻得新生之主<br>
                &gt;&gt; 每次出价皆为一场意外之喜
            </p>
            <div class="hero-search">
                <span class="hero-search-icon"><i class="fa fa-search"></i></span>
                <input type="text" placeholder="> 搜索:数码 / 服饰 / 图书 ...">
                <button>搜索</button>
            </div>
            <div class="hero-tags">
                <span class="hero-tags-label">// 热门:</span>
                <span class="hero-tag">iPhone</span>
                <span class="hero-tag">相机</span>
                <span class="hero-tag">球鞋</span>
                <span class="hero-tag">图书</span>
                <span class="hero-tag">耳机</span>
            </div>
        </div>

        <!-- 右：主推拍品（数据库：拍卖中 + end_time 最近） -->
        <% if (heroItem != null) { %>
        <div class="hero-card" onclick="go('/item?action=detail&id=<%= heroItem.getId() %>')">
            <div class="hero-card-cover">
                <% if (heroItem.getCoverImage() != null && !heroItem.getCoverImage().isEmpty()) { %>
                    <img src="<%= org.example.util.EscapeUtil.html(heroItem.getCoverImage()) %>" alt="" style="width:100%;height:100%;object-fit:cover;position:absolute;inset:0;">
                <% } else { %>
                    <i class="fa fa-mobile"></i>
                <% } %>
                <span class="hero-card-badge"><i class="fa fa-fire"></i> 即将结束</span>
            </div>
            <div class="hero-card-body">
                <h3 class="hero-card-title"><%= org.example.util.EscapeUtil.html(heroItem.getTitle()) %></h3>
                <div class="hero-card-meta">
                    <div>
                        <div class="hero-card-meta-label">// 当前价格</div>
                        <div class="hero-card-price"><small>¥</small><%= formatPrice(heroItem.getCurrentPrice()) %></div>
                    </div>
                    <div>
                        <div class="hero-card-meta-label">// 剩余时间</div>
                        <div class="hero-card-countdown"><%= formatCountdown(heroItem.getEndTime()) %></div>
                    </div>
                </div>
                <button class="hero-card-cta" onclick="event.stopPropagation(); go('/item?action=detail&id=<%= heroItem.getId() %>')">
                    立即出价 <i class="fa fa-arrow-right"></i>
                </button>
            </div>
        </div>
        <% } else { %>
        <div class="hero-card" style="cursor:default;">
            <div class="hero-card-cover">
                <i class="fa fa-inbox"></i>
                <span class="hero-card-badge"><i class="fa fa-info-circle"></i> 暂无拍品</span>
            </div>
            <div class="hero-card-body">
                <h3 class="hero-card-title">还没有即将结束的拍品</h3>
                <div class="hero-card-meta">
                    <div>
                        <div class="hero-card-meta-label">// 状态</div>
                        <div class="hero-card-price"><small>¥</small>--</div>
                    </div>
                    <div>
                        <div class="hero-card-meta-label">// 剩余时间</div>
                        <div class="hero-card-countdown">--:--:--</div>
                    </div>
                </div>
                <button class="hero-card-cta" onclick="event.stopPropagation(); go('/item?action=publish-page')">
                    去发布拍品 <i class="fa fa-plus"></i>
                </button>
            </div>
        </div>
        <% } %>
    </div>
</section>

<!-- ========== 3. 主体三栏 ========== -->
<div class="main">

    <!-- 左侧分类侧栏 -->
    <aside class="sidebar">
        <div class="sidebar-head">
            <div class="sidebar-title">// 分类目录</div>
        </div>
        <ul class="cat-list">
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list')" class="cat-link active">
                    <i class="fa fa-th-large"></i> 全部
                    <span class="count"><%= totalItemCount %></span>
                </a>
            </li>
            <%-- 一级分类（数据库 + 该一级及其所有子分类拍品总数） --%>
            <c:forEach var="cat" items="${topCategories}">
                <li class="cat-item">
                    <a href="javascript:void(0)" onclick="go('/item?action=list&categoryId=<c:out value="${cat.id}"/>')" class="cat-link">
                        <i class="fa ${catIconMap[cat.categoryName] != null ? catIconMap[cat.categoryName] : 'fa-list'}"></i> <c:out value="${cat.categoryName}"/>
                        <span class="count"><c:out value="${catCountMap[cat.id]}"/></span>
                    </a>
                </li>
            </c:forEach>
        </ul>
    </aside>

    <!-- 中央内容 -->
    <main class="content">

        <!-- 5 分类色块（数据库驱动：每个一级分类 + 其子分类下 top 3 拍品） -->
        <section class="feature">
            <% int cbIdx = 0; %>
            <% for (java.util.Map.Entry<Integer, List<AuctionItem>> e : catItemsMap.entrySet()) {
                   Integer catId = e.getKey();
                   List<AuctionItem> items = e.getValue();
                   Category cbCat = null;
                   for (Category c : topCategories) { if (c.getId().equals(catId)) { cbCat = c; break; } }
                   if (cbCat == null) continue;
                   String[] subIcons = {"fa-mobile", "fa-tag", "fa-book", "fa-home", "fa-futbol-o"};
                   String[] subLabels = {"热门装备", "街头穿搭", "知识海洋", "生活美学", "热血赛场"};
                   String icon = subIcons[Math.min(cbIdx, subIcons.length - 1)];
                   String label = subLabels[Math.min(cbIdx, subLabels.length - 1)];
                   cbIdx++;
            %>
            <div class="cb" onclick="go('/item?action=list&categoryId=<%= cbCat.getId() %>')">
                <div class="cb-head">
                    <div class="cb-title"><%= org.example.util.EscapeUtil.html(cbCat.getCategoryName()) %> <span class="arrow">›</span></div>
                    <i class="cb-icon fa <%= icon %>"></i>
                </div>
                <div class="cb-sub">// <%= label %></div>
                <div class="cb-thumbs">
                    <% if (items != null && items.size() >= 1 && items.get(0) != null) { %>
                        <div class="cb-thumb"><i class="<%= icon %>"></i><span class="price">¥<%= formatPrice(items.get(0).getCurrentPrice()) %></span></div>
                    <% } else { %>
                        <div class="cb-thumb empty"><i class="fa fa-inbox"></i><span class="price">暂无</span></div>
                    <% } %>
                    <% if (items != null && items.size() >= 2 && items.get(1) != null) { %>
                        <div class="cb-thumb"><i class="<%= icon %>"></i><span class="price">¥<%= formatPrice(items.get(1).getCurrentPrice()) %></span></div>
                    <% } else { %>
                        <div class="cb-thumb empty"><i class="fa fa-inbox"></i><span class="price">暂无</span></div>
                    <% } %>
                    <% if (items != null && items.size() >= 3 && items.get(2) != null) { %>
                        <div class="cb-thumb"><i class="<%= icon %>"></i><span class="price">¥<%= formatPrice(items.get(2).getCurrentPrice()) %></span></div>
                    <% } else { %>
                        <div class="cb-thumb empty"><i class="fa fa-inbox"></i><span class="price">暂无</span></div>
                    <% } %>
                </div>
            </div>
            <% } %>
        </section>

        <!-- 标签栏 + 商品网格 -->
        <section class="grid-section">
            <div class="tabs">
                <a class="tab active">猜你喜欢</a>
                <a class="tab" onclick="go('/item?action=list&sort=ending')">即将结束</a>
                <a class="tab" onclick="go('/item?action=list&sort=newest')">最新发布</a>
                <a class="tab" onclick="go('/item?action=hot-ranks')">人气榜</a>
                <a class="tab" onclick="go('/item?action=list&sort=price-asc')">价格升序</a>
                <a class="tab" onclick="go('/item?action=list&sort=price-desc')">价格降序</a>
                <div class="tabs-right">
                    <a href="javascript:void(0)">排序 <i class="fa fa-angle-down"></i></a>
                    <a href="javascript:void(0)">筛选 <i class="fa fa-sliders"></i></a>
                </div>
            </div>

            <div class="goods-grid">
                <%-- 12 个推荐商品（数据库驱动：view_count DESC） --%>
                <% if (hotItems.isEmpty()) { %>
                    <div class="goods-empty" style="grid-column:1/-1;padding:60px 20px;text-align:center;color:var(--cp-text-dim);">
                        <i class="fa fa-inbox" style="font-size:48px;display:block;margin-bottom:12px;"></i>
                        暂无拍品数据，<a href="javascript:void(0)" onclick="go('/item?action=publish-page')" style="color:var(--cp-yellow);">立即发布</a> 第一件拍品
                    </div>
                <% } %>
                <% for (AuctionItem item : hotItems) {
                       org.example.entity.User seller = hotItemSellerMap.get(item.getId());
                       Integer bidCount = hotItemBidCountMap.getOrDefault(item.getId(), 0);
                       String sellerName = seller == null ? "匿名" : seller.getUsername();
                       // 名字脱敏
                       if (sellerName.length() > 2) sellerName = sellerName.substring(0,1) + "***" + sellerName.substring(sellerName.length()-1);
                       else if (sellerName.length() == 2) sellerName = sellerName.substring(0,1) + "*";
                       // 头像首字母
                       String avatarLetter = "U";
                       if (seller != null && seller.getUsername() != null && !seller.getUsername().isEmpty()) {
                           avatarLetter = seller.getUsername().substring(0,1).toUpperCase();
                       }
                       // 是否"即将结束"标签（剩余 < 24h）
                       boolean ending = item.getEndTime() != null
                           && java.time.Duration.between(java.time.LocalDateTime.now(), item.getEndTime()).toHours() < 24
                           && java.time.Duration.between(java.time.LocalDateTime.now(), item.getEndTime()).isPositive();
                %>
                <div class="goods-card" onclick="go('/item?action=detail&id=<%= item.getId() %>')">
                    <div class="goods-cover">
                        <% if (item.getCoverImage() != null && !item.getCoverImage().isEmpty()) { %>
                            <img src="<%= org.example.util.EscapeUtil.html(item.getCoverImage()) %>" alt="" style="width:100%;height:100%;object-fit:cover;position:absolute;inset:0;">
                        <% } else { %>
                            <i class="fa fa-cube"></i>
                        <% } %>
                        <% if (ending) { %>
                            <span class="tag">即将结束</span>
                        <% } %>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title"><%= org.example.util.EscapeUtil.html(item.getTitle()) %></div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small><%= formatPrice(item.getCurrentPrice()) %></div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> <%= bidCount %></div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar"><%= avatarLetter %></span>
                            <span class="goods-seller"><%= sellerName %></span>
                            <span class="goods-credit"><%= creditText(seller == null ? null : seller.getCreditScore()) %></span>
                        </div>
                    </div>
                </div>
                <% } %>
            </div>
        </section>

    </main>

    <!-- 右侧浮动操作栏 -->
    <aside class="floats">
        <a href="javascript:void(0)" onclick="go('/item?action=publish-page')" class="float-btn primary" title="发布">
            <i class="fa fa-plus"></i><span>发布</span>
        </a>
        <a href="javascript:void(0)" onclick="go('<%= currentUser != null ? "/user?action=center" : "/user?action=login" %>')" class="float-btn" title="消息">
            <i class="fa fa-envelope-o"></i><span>消息</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('APP 下载敬请期待', 'info')" class="float-btn" title="APP">
            <i class="fa fa-mobile"></i><span>应用</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('反馈功能开发中', 'info')" class="float-btn" title="反馈">
            <i class="fa fa-commenting-o"></i><span>反馈</span>
        </a>
        <a href="javascript:void(0)" onclick="toast('客服：400-888-NEON', 'info')" class="float-btn" title="客服">
            <i class="fa fa-headphones"></i><span>客服</span>
        </a>
        <a href="javascript:void(0)" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" class="float-btn" title="顶部" style="margin-top: auto;">
            <i class="fa fa-arrow-up"></i><span>顶部</span>
        </a>
    </aside>

</div>

<!-- ========== 4. 页脚 ========== -->
<footer class="footer">
    <div class="footer-inner">
        <div class="footer-brand">
            <div class="logo">赛博拍卖</div>
            <p>// 闲置流转 // 价值新生<br>// 透明 // 安全 // 高效<br>// 二手拍卖平台</p>
        </div>
        <div class="footer-col">
            <h4>// 关于我们</h4>
            <a href="javascript:void(0)">平台介绍</a>
            <a href="javascript:void(0)">用户协议</a>
            <a href="javascript:void(0)">隐私政策</a>
        </div>
        <div class="footer-col">
            <h4>// 帮助中心</h4>
            <a href="javascript:void(0)">拍卖规则</a>
            <a href="javascript:void(0)">买家指南</a>
            <a href="javascript:void(0)">卖家指南</a>
        </div>
        <div class="footer-col">
            <h4>// 联系我们</h4>
            <a href="javascript:void(0)"><i class="fa fa-envelope"></i> support@cyber.auction</a>
            <a href="javascript:void(0)"><i class="fa fa-phone"></i> 400-888-NEON</a>
            <a href="javascript:void(0)"><i class="fa fa-weixin"></i> 微信公众号</a>
        </div>
    </div>
    <div class="footer-bottom">
        &copy; 2025 赛博拍卖 // JSP + SERVLET + MYBATIS + VUE
    </div>
</footer>

<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // 全局跳转函数（供非 Vue 区域调用）
    function go(path) {
        window.location.href = '<%=ctx%>' + path;
    }

    // Vue 接管顶部 nav 内的搜索框
    loadVue().then(() => {
        const { createApp, ref } = Vue;
        createApp({
            setup() {
                const keyword = ref('');
                function search() {
                    if (!keyword.value.trim()) { toast('请输入搜索关键词', 'info'); return; }
                    window.location.href = '<%=ctx%>/item/list?keyword=' + encodeURIComponent(keyword.value);
                }
                return { keyword, search };
            }
        }).mount('#vue-root');
    });
</script>
</body>
</html>