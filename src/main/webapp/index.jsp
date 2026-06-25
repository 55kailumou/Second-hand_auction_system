<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="org.example.entity.Notice" %>
<%@ page import="java.util.List" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");

    // 公告 banner：取最多 5 条已发布公告（置顶优先）
    List<Notice> topNotices = new java.util.ArrayList<>();
    try (org.apache.ibatis.session.SqlSession _sql =
                 org.example.util.MyBatisUtil.openSession()) {
        topNotices = _sql.getMapper(org.example.mapper.NoticeMapper.class).findPublished(5);
    } catch (Exception _e) {
        // 公告查失败不影响首页主流程
        topNotices = new java.util.ArrayList<>();
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>二手物品拍卖系统 · 首页</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 首页 v6 · Cyberpunk 2077 官网风格（黄黑拼接 + 几何断层）
         * - 主色反转：黄为大背景，黑为元素/边框/按钮
         * - 按钮统一：黑底 + 黄边 + 黄字 + 切角
         * - 板块连接：clip-path 几何斜切断层
         * - 蓝色仅作点缀（tag / 链接 / 状态）
         * - 保留 EL/Vue/跳转函数，只改视觉
         * ============================================================ */
        :root {
            --cp-yellow: #FFEE00;
            --cp-yellow-soft: #FFFCE0;
            --cp-yellow-dim: #C8BD00;
            --cp-black: #000000;
            --cp-dark: #0a0a0a;
            --cp-cyan: #00F0FF;
            --cp-red: #FF003C;
            --cp-font-mono: "Consolas", "Cascadia Code", "JetBrains Mono", "Courier New", monospace;
            --cp-font-display: -apple-system, BlinkMacSystemFont, "Microsoft YaHei", "PingFang SC", sans-serif;
            /* 通用切角多边形（8px） */
            --cp-clip: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
            /* 按钮专用切角（更明显的 12px） */
            --cp-clip-btn: polygon(12px 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%, 0 12px);
        }

        * { box-sizing: border-box; }
        body {
            background: var(--cp-yellow);
            color: var(--cp-black);
            font-family: var(--cp-font-display);
            overflow-x: hidden;
        }
        a { color: inherit; text-decoration: none; }
        button { font-family: inherit; cursor: pointer; border: none; background: none; }

        /* ============================================================
         * 通用：黑底 + 黄边 + 黄字 按钮（cp 标志）
         * 加 hover 故障效果（按文章"故障风格按钮"代码）
         * ============================================================ */
        .cp-btn {
            position: relative;
            display: inline-flex; align-items: center; justify-content: center; gap: 8px;
            padding: 12px 28px;
            background: var(--cp-black); color: var(--cp-yellow);
            border: 2px solid var(--cp-yellow);
            font-weight: 800; font-size: 15px;
            cursor: pointer; transition: all 0.2s;
            clip-path: var(--cp-clip-btn);
            overflow: visible;
        }
        .cp-btn::after {
            /* 文章"故障风格按钮"的核心：多 clip-path 切片 */
            --slice-0: inset(50% 50% 50% 50%);
            --slice-1: inset(80% -6px 0 0);
            --slice-2: inset(50% -6px 30% 0);
            --slice-3: inset(10% -6px 85% 0);
            --slice-4: inset(40% -6px 43% 0);
            --slice-5: inset(80% -6px 5% 0);
            content: '';
            display: block;
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: var(--cp-black);
            border: 2px solid var(--cp-yellow);
            clip-path: var(--slice-0);
            opacity: 0;
            transition: opacity 0.15s;
            pointer-events: none;
        }
        .cp-btn:hover::after {
            opacity: 1;
            animation: 0.9s glitch-btn;
            animation-timing-function: steps(2, end);
        }
        @keyframes glitch-btn {
            0%   { clip-path: var(--slice-1); transform: translate(-20px, -10px); }
            10%  { clip-path: var(--slice-3); transform: translate(10px, 10px); }
            20%  { clip-path: var(--slice-1); transform: translate(-10px, 10px); }
            30%  { clip-path: var(--slice-3); transform: translate(0, 5px); }
            40%  { clip-path: var(--slice-2); transform: translate(-5px, 0); }
            50%  { clip-path: var(--slice-3); transform: translate(5px, 0); }
            60%  { clip-path: var(--slice-4); transform: translate(5px, 10px); }
            70%  { clip-path: var(--slice-2); transform: translate(-10px, 10px); }
            80%  { clip-path: var(--slice-5); transform: translate(20px, -10px); }
            90%  { clip-path: var(--slice-1); transform: translate(-10px, 0); }
            100% { clip-path: var(--slice-1); transform: translate(0); }
        }
        /* 悬停时按钮文字也加一点 RGB 错位 */
        .cp-btn:hover {
            text-shadow: -2px 0 var(--cp-cyan), 2px 0 var(--cp-red);
        }
        .cp-btn-solid {
            background: var(--cp-black); color: var(--cp-yellow);
        }
        .cp-btn-outline {
            background: transparent; color: var(--cp-black);
            border-color: var(--cp-black);
        }
        .cp-btn-outline:hover {
            background: var(--cp-black); color: var(--cp-yellow);
        }
        .cp-btn-sm { padding: 8px 18px; font-size: 12px; }

        /* ============================================================
         * 通用：模块标签 // MODULE_NAME
         * 加 glitched 故障动画（按文章 h1.cyberpunk.glitched）
         * ============================================================ */
        .module-tag {
            font-family: var(--cp-font-mono); font-size: 12px;
            color: var(--cp-black);
            font-weight: 800;
            display: flex; align-items: center; gap: 8px;
            position: relative;
            animation: tag-glitched 1.8s infinite linear;
        }
        @keyframes tag-glitched {
            0%   { transform: translate(-1px, 0); }
            20%  { transform: translate(1px, 0); }
            40%  { transform: translate(-1px, 0); }
            60%  { transform: translate(1px, 0); }
            80%  { transform: translate(-1px, 0); }
            100% { transform: translate(0, 0); }
        }
        .module-tag::before { content: '//'; color: var(--cp-cyan); }
        .module-tag .date { margin-left: auto; color: var(--cp-black); opacity: 0.7; }

        /* ============================================================
         * 顶部 nav（黑底 + 黄菜单字 + 黑边黄字按钮）
         * ============================================================ */
        .header {
            background: var(--cp-black);
            position: sticky; top: 0; z-index: 100;
            border-bottom: 2px solid var(--cp-yellow);
        }
        .header-inner {
            max-width: 1280px; margin: 0 auto; padding: 0 24px;
            height: 64px;
            display: flex; align-items: center; gap: 24px;
        }
        .logo {
            display: flex; align-items: center; gap: 10px; flex-shrink: 0;
            color: var(--cp-yellow);
        }
        .logo-icon {
            width: 38px; height: 38px;
            background: var(--cp-yellow); color: var(--cp-black);
            display: grid; place-items: center; font-size: 18px; font-weight: 900;
            clip-path: var(--cp-clip);
        }
        .logo-text {
            font-size: 22px; font-weight: 900; color: var(--cp-yellow);
            letter-spacing: -0.01em; line-height: 1;
        }
        .logo-text .accent { color: var(--cp-cyan); }

        .nav { display: flex; gap: 24px; }
        .nav a {
            color: var(--cp-yellow); font-size: 14px; font-weight: 600;
            padding: 0 4px; height: 64px; display: flex; align-items: center;
            position: relative; transition: opacity 0.15s; letter-spacing: 0;
        }
        .nav a:hover { opacity: 0.7; }
        .nav a.active::after {
            content: ''; position: absolute;
            bottom: 12px; left: 0; right: 0; height: 2px;
            background: var(--cp-yellow);
        }

        /* 搜索框（不规则切角 + 黑边，按文章 input.cyberpunk） */
        .nav-search {
            flex: 0 1 320px; display: flex;
            /* 文章的核心：复杂 clip-path polygon 多切角 */
            clip-path: polygon(
                0 14px, 14px 0, calc(60% - 14px) 0, 60% 14px, 100% 14px,
                100% calc(100% - 6px), calc(100% - 8px) calc(100% - 6px),
                calc(80% - 6px) calc(100% - 6px), calc(80% - 8px) 100%,
                6px 100%, 0 calc(100% - 6px));
            background: var(--cp-black);
            height: 38px;
        }
        .nav-search input {
            flex: 1; padding: 0 14px; border: none; outline: none;
            background: transparent; font-size: 13px; color: var(--cp-yellow);
            font-family: var(--cp-font-mono);
            border-top: 2px solid var(--cp-yellow);
            border-bottom: 2px solid var(--cp-yellow);
            border-left: 5px solid var(--cp-yellow);
            border-right: 5px solid var(--cp-yellow);
        }
        .nav-search input::placeholder { color: var(--cp-yellow-dim); }
        .nav-search button {
            background: var(--cp-yellow); color: var(--cp-black);
            font-size: 12px; font-weight: 800; padding: 0 18px;
            display: flex; align-items: center; gap: 5px;
            border: none; border-left: 2px solid var(--cp-black);
        }
        .nav-search button:hover {
            background: #fff;
            color: var(--cp-black);
        }

        .nav-tags {
            display: flex; gap: 14px; font-size: 12px;
            flex: 1; min-width: 0; overflow: hidden; align-items: center;
            font-family: var(--cp-font-mono);
        }
        .nav-tags-label {
            flex-shrink: 0; color: var(--cp-yellow); font-weight: 800;
        }
        .nav-tag { white-space: nowrap; color: var(--cp-yellow); transition: opacity 0.15s; }
        .nav-tag:hover { opacity: 0.7; }
        .nav-tag.hot { color: var(--cp-red); font-weight: 700; }

        .user-info { display: flex; align-items: center; gap: 8px; flex-shrink: 0; margin-left: auto; }
        .user-info .icon-btn {
            width: 36px; height: 36px; display: grid; place-items: center;
            color: var(--cp-yellow); transition: all 0.15s;
            position: relative; font-size: 15px;
        }
        .user-info .icon-btn:hover { color: #fff; }
        .user-info .icon-btn .dot {
            position: absolute; top: 6px; right: 6px; width: 8px; height: 8px;
            background: var(--cp-red); border-radius: 50%;
        }
        .user-info .avatar {
            width: 36px; height: 36px;
            background: var(--cp-yellow); color: var(--cp-black);
            display: grid; place-items: center; font-size: 14px; font-weight: 900; cursor: pointer;
            clip-path: var(--cp-clip);
        }
        .user-info .user-name { color: var(--cp-yellow); font-size: 12px; font-weight: 700; font-family: var(--cp-font-mono); }
        .user-info .login-link, .user-info .register-link {
            font-weight: 800; font-size: 13px;
            padding: 8px 18px; transition: all 0.15s; cursor: pointer;
            clip-path: var(--cp-clip-btn);
        }
        .user-info .login-link {
            background: transparent; color: var(--cp-yellow);
            border: 1.5px solid var(--cp-yellow);
        }
        .user-info .login-link:hover { background: var(--cp-yellow); color: var(--cp-black); }
        .user-info .register-link {
            background: var(--cp-yellow); color: var(--cp-black);
            border: 1.5px solid var(--cp-yellow);
        }
        .user-info .register-link:hover { background: #fff; border-color: #fff; }
        .user-info a.logout-link { color: var(--cp-yellow-dim); font-size: 12px; }
        .user-info a.logout-link:hover { color: #fff; }

        /* ============================================================
         * 公告 banner（黄底 + 黑边 + 黑字）
         * ============================================================ */
        .notice-bar {
            background: var(--cp-yellow);
            border-bottom: 2px solid var(--cp-black);
            padding: 10px 24px;
            display: flex; align-items: center; gap: 12px;
            font-size: 13px;
            color: var(--cp-black);
        }
        .notice-bar-icon {
            width: 28px; height: 28px;
            background: var(--cp-black); color: var(--cp-yellow);
            display: grid; place-items: center;
            font-size: 13px; font-weight: 900; flex-shrink: 0;
            clip-path: var(--cp-clip);
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
            padding: 1px 6px; background: var(--cp-red); color: var(--cp-yellow);
            font-size: 10px; font-weight: 800; flex-shrink: 0;
            font-family: var(--cp-font-mono);
        }
        .notice-bar-item a {
            color: var(--cp-black); font-weight: 700;
            overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
            flex: 1; min-width: 0;
            font-family: var(--cp-font-mono);
            text-decoration: none;
        }
        .notice-bar-item a:hover { color: var(--cp-cyan); text-decoration: underline; }
        .notice-bar-item .time {
            color: var(--cp-black); opacity: 0.6; font-size: 11px; flex-shrink: 0;
            font-family: var(--cp-font-mono);
        }

        /* ============================================================
         * 主体布局（侧栏 + 内容 + 浮动栏）
         * ============================================================ */
        .home-main {
            max-width: 1280px; margin: 0 auto;
            padding: 24px;
            display: grid;
            grid-template-columns: 220px 1fr 48px;
            gap: 16px;
            align-items: start;
        }

        /* 左侧分类侧栏（黑底 + 黄边 + 切角） */
        .sidebar {
            background: var(--cp-black); border: 2px solid var(--cp-yellow);
            position: sticky; top: 88px;
            clip-path: var(--cp-clip);
        }
        .sidebar::before {
            content: '// 分类目录';
            display: block; padding: 14px 16px 10px;
            font-family: var(--cp-font-mono); font-size: 11px; color: var(--cp-yellow);
            font-weight: 700;
            border-bottom: 1px solid rgba(255,238,0,0.3);
        }
        .cat-list { list-style: none; padding: 6px 0; }
        .cat-item { position: relative; }
        .cat-link {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 16px; font-size: 13px; color: var(--cp-yellow);
            border-left: 3px solid transparent;
            cursor: pointer; font-family: var(--cp-font-mono);
            transition: all 0.15s;
        }
        .cat-link i { width: 16px; color: var(--cp-yellow-dim); text-align: center; font-size: 13px; transition: color 0.15s; }
        .cat-link:hover {
            background: var(--cp-yellow); color: var(--cp-black);
            border-left-color: var(--cp-black);
        }
        .cat-link:hover i { color: var(--cp-black); }
        .cat-link.active {
            background: var(--cp-yellow); color: var(--cp-black);
            font-weight: 800; border-left-color: var(--cp-black);
        }
        .cat-link.active i { color: var(--cp-black); }
        .cat-link .count { margin-left: auto; font-size: 10px; opacity: 0.7; }

        /* 二级分类 */
        .cat-sub {
            position: absolute; left: 100%; top: 0;
            min-width: 420px; background: var(--cp-black);
            border: 2px solid var(--cp-yellow); padding: 14px;
            display: none; z-index: 50;
            clip-path: var(--cp-clip);
            box-shadow: 0 0 24px rgba(255,238,0,0.4);
        }
        .cat-item:hover .cat-sub { display: block; }
        .cat-sub-row { display: flex; gap: 8px; margin-bottom: 10px; align-items: flex-start; }
        .cat-sub-row:last-child { margin-bottom: 0; }
        .cat-sub-label {
            flex-shrink: 0; width: 56px;
            color: var(--cp-cyan); font-size: 12px; padding-top: 4px;
            font-family: var(--cp-font-mono);
            font-weight: 700;
        }
        .cat-sub-items { flex: 1; display: flex; flex-wrap: wrap; gap: 4px 12px; }
        .cat-sub-items a {
            font-size: 12px; color: var(--cp-yellow); padding: 3px 0; white-space: nowrap;
        }
        .cat-sub-items a:hover { color: var(--cp-cyan); }

        /* ============================================================
         * 中央内容
         * ============================================================ */
        .content { min-width: 0; }

        /* ============================================================
         * HERO 区（黄底大标题 + 黑边黄字按钮 + 右侧主推卡）
         * 仿 cp 官网"享受《赛博朋克 2077》终极体验"风格
         * ============================================================ */
        .hero {
            background: var(--cp-yellow);
            padding: 48px 0 40px;
            position: relative;
        }
        .hero-inner {
            display: grid;
            grid-template-columns: 1.2fr 1fr;
            gap: 40px; align-items: center;
        }
        .hero-title {
            font-size: 64px; font-weight: 900; color: var(--cp-black);
            line-height: 1.05; letter-spacing: -0.02em;
            margin: 18px 0 28px;
            position: relative;
            /* 文章 h1.cyberpunk:before 切角下划线 */
        }
        .hero-title::before {
            content: '';
            display: block;
            position: absolute;
            bottom: -16px; left: 2px;
            width: 100%; height: 10px;
            background-color: var(--cp-black);
            clip-path: polygon(0 0, 85px 0, 90px 5px, 100% 5px, 100% 6px, 85px 6px, 80px 10px, 0 10px);
        }
        /* 标题的"故障"动画变体（按文章 h1.cyberpunk.glitched） */
        .hero-title.glitched {
            animation: hero-glitched 1.26s infinite linear;
        }
        @keyframes hero-glitched {
            0%   { left: -4px; transform: skew(-20deg); }
            11%  { left: 2px;  transform: skew(0deg); }
            50%  { transform: skew(0deg); }
            51%  { transform: skew(10deg); }
            60%  { transform: skew(0deg); }
            100% { transform: skew(0deg); }
        }
        .hero-title .accent { color: var(--cp-black); }
        .hero-title .stroke {
            color: transparent; -webkit-text-stroke: 2px var(--cp-black);
        }
        .hero-desc {
            font-size: 15px; color: var(--cp-black); line-height: 1.7;
            margin-bottom: 32px; max-width: 540px;
            position: relative;
            /* 文章 .cyberpunk.inverse：不规则切角文本框 */
            padding: 18px 20px 18px 18px;
            background: var(--cp-yellow);
            border-left: 2px solid var(--cp-black);
            border-right: 2px solid var(--cp-black);
            clip-path: polygon(
                0 18px, 18px 0, calc(60% - 18px) 0, 60% 18px, 100% 18px,
                100% calc(100% - 8px), calc(100% - 12px) calc(100% - 8px),
                calc(80% - 8px) calc(100% - 8px), calc(80% - 12px) 100%,
                60px 100%, 50px calc(100% - 12px), 0 calc(100% - 12px));
        }
        /* 文章 .cyberpunk.inverse:before "T-XX" 编号 */
        .hero-desc::before {
            content: 'T-71';
            display: block;
            position: absolute;
            bottom: 6px; right: 20px;
            padding: 2px 4px 0;
            font-size: 11px; line-height: 1;
            font-family: var(--cp-font-mono); font-weight: 800;
            color: var(--cp-black);
            background: var(--cp-yellow);
            border-left: 2px solid var(--cp-black);
        }
        .hero-actions {
            display: flex; gap: 16px; flex-wrap: wrap;
        }
        .platform-row {
            display: flex; gap: 24px; margin-top: 32px;
            font-size: 13px; color: var(--cp-black);
            font-weight: 700;
            font-family: var(--cp-font-mono);
        }
        .platform-row .plat { display: flex; align-items: center; gap: 6px; }
        .platform-row .plat i { font-size: 16px; }

        /* 右侧主推拍品（黑底卡 + 切角） */
        .hero-spot {
            background: var(--cp-black);
            border: 2px solid var(--cp-yellow);
            position: relative; overflow: hidden;
            clip-path: var(--cp-clip);
        }
        .hero-spot-cover {
            aspect-ratio: 4/3;
            background:
                radial-gradient(circle at 50% 50%, rgba(255,238,0,0.2) 0%, transparent 60%),
                linear-gradient(135deg, #1a1a1a 0%, #000 50%, #0a0a0a 100%);
            position: relative; display: flex; align-items: center; justify-content: center;
        }
        .hero-spot-cover::before {
            content: ''; position: absolute; inset: 0;
            background-image:
                linear-gradient(rgba(255,238,0,0.06) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,238,0,0.06) 1px, transparent 1px);
            background-size: 30px 30px;
        }
        .hero-spot-cover i {
            font-size: 100px; color: var(--cp-yellow); opacity: 0.85;
            position: relative; z-index: 1;
        }
        .hero-spot-badge {
            position: absolute; top: 16px; left: 16px;
            padding: 4px 12px; background: var(--cp-red); color: var(--cp-yellow);
            font-size: 11px; font-weight: 800; letter-spacing: 0.1em;
            text-transform: uppercase; font-family: var(--cp-font-mono);
            clip-path: var(--cp-clip);
        }
        .hero-spot-body { padding: 16px 20px 20px; }
        .hero-spot-title {
            font-size: 15px; font-weight: 700; color: var(--cp-yellow);
            margin-bottom: 12px; line-height: 1.4;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
        }
        .hero-spot-meta {
            display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px;
        }
        .hero-spot-price {
            font-size: 26px; font-weight: 900; color: var(--cp-yellow);
            font-family: var(--cp-font-mono); line-height: 1;
        }
        .hero-spot-price small { font-size: 14px; margin-right: 3px; }
        .hero-spot-cd {
            font-family: var(--cp-font-mono); font-size: 16px; font-weight: 800;
            color: var(--cp-red); letter-spacing: 0.1em;
        }

        /* ============================================================
         * 4 个分类色块（黄底大区里嵌套黑底小卡）
         * ============================================================ */
        .showcase {
            background: var(--cp-yellow);
            padding: 20px 0 60px;
            position: relative;
        }
        .showcase-head {
            display: flex; align-items: center; gap: 12px;
            margin-bottom: 20px; padding-bottom: 14px;
            border-bottom: 2px solid var(--cp-black);
        }
        .color-blocks {
            display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px;
        }
        .cb {
            background: var(--cp-black);
            border: 2px solid var(--cp-black);
            padding: 16px; position: relative;
            min-height: 200px; cursor: pointer; overflow: hidden;
            /* 文章 .cyberpunk 不规则切角 */
            clip-path: polygon(
                0 18px, 18px 0, calc(60% - 18px) 0, 60% 18px, 100% 18px,
                100% calc(100% - 8px), calc(100% - 12px) calc(100% - 8px),
                calc(80% - 8px) calc(100% - 8px), calc(80% - 12px) 100%,
                50px 100%, 40px calc(100% - 10px), 0 calc(100% - 10px));
            transition: all 0.2s;
        }
        .cb:hover { transform: translateY(-3px); }
        /* 文章 .cyberpunk:before 编号标签 */
        .cb::before {
            content: attr(data-no);
            position: absolute;
            bottom: -10px; right: 18px;
            padding: 2px 5px 0;
            font-family: var(--cp-font-mono); font-size: 11px; line-height: 1;
            font-weight: 800;
            color: var(--cp-yellow);
            background: var(--cp-black);
            border-left: 2px solid var(--cp-yellow);
            z-index: 5;
        }
        .cb-cyan::before { color: var(--cp-cyan); border-left-color: var(--cp-cyan); }
        .cb-red::before { color: var(--cp-red); border-left-color: var(--cp-red); }
        .cb-yellow-dim::before { color: var(--cp-yellow-dim); border-left-color: var(--cp-yellow-dim); }
        .cb:hover { transform: translateY(-3px); }
        .cb-cyan { border-color: var(--cp-cyan); }
        .cb-red { border-color: var(--cp-red); }
        .cb-yellow-dim { border-color: var(--cp-yellow-dim); }

        .cb-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
        .cb-title {
            font-size: 17px; font-weight: 900; color: var(--cp-yellow);
            display: flex; align-items: center; gap: 6px;
        }
        .cb-cyan .cb-title { color: var(--cp-cyan); }
        .cb-red .cb-title { color: var(--cp-red); }
        .cb-yellow-dim .cb-title { color: var(--cp-yellow-dim); }
        .cb-title .arrow { font-size: 12px; opacity: 0.7; }
        .cb-sub { font-size: 11px; color: var(--cp-yellow-dim); margin-bottom: 12px; font-family: var(--cp-font-mono); }
        .cb-thumbs { display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px; }
        .cb-thumb {
            aspect-ratio: 1; background: var(--cp-dark);
            display: grid; place-items: center; position: relative; overflow: hidden;
            border: 1px solid rgba(255,238,0,0.2);
        }
        .cb-thumb i { font-size: 20px; color: var(--cp-yellow-dim); }
        .cb-thumb .price {
            position: absolute; bottom: 0; left: 0; right: 0;
            background: var(--cp-black); color: var(--cp-yellow);
            font-size: 10px; font-weight: 800; text-align: center; padding: 2px 0;
            font-family: var(--cp-font-mono);
        }
        .cb-cyan .cb-thumb { border-color: rgba(0,240,255,0.3); }
        .cb-cyan .cb-thumb i { color: var(--cp-cyan); opacity: 0.6; }
        .cb-cyan .cb-thumb .price { color: var(--cp-cyan); }
        .cb-red .cb-thumb { border-color: rgba(255,0,60,0.3); }
        .cb-red .cb-thumb i { color: var(--cp-red); opacity: 0.6; }
        .cb-red .cb-thumb .price { color: var(--cp-red); }
        .cb-yellow-dim .cb-thumb { border-color: rgba(200,189,0,0.3); }
        .cb-yellow-dim .cb-thumb i { color: var(--cp-yellow-dim); }
        .cb-yellow-dim .cb-thumb .price { color: var(--cp-yellow-dim); }
        .cb-badge {
            position: absolute; top: 12px; right: 12px;
            width: 30px; height: 30px;
            display: grid; place-items: center; color: var(--cp-black); font-size: 12px;
            background: var(--cp-yellow);
            clip-path: var(--cp-clip);
        }
        .cb-cyan .cb-badge { background: var(--cp-cyan); }
        .cb-red .cb-badge { background: var(--cp-red); }
        .cb-yellow-dim .cb-badge { background: var(--cp-yellow-dim); }

        /* ============================================================
         * 几何过渡断层（黄底 section → 黑底 section）
         * 黑底区顶部 ::before 不规则多边形，模拟 cp 官网的尖角过渡
         * ============================================================ */
        .grid-section {
            background: var(--cp-black);
            border-top: none;
            padding: 28px 24px 24px;
            position: relative;
            color: var(--cp-yellow);
            /* 顶部不规则多边形过渡 */
            clip-path: polygon(
                0 40px,                       /* 左上尖角起点 */
                12% 0,                        /* 第一段下降 */
                24% 30px,                     /* 回到低谷 */
                38% 10px,                     /* 抬升 */
                50% 35px,                     /* 谷 */
                62% 5px,                      /* 峰 */
                76% 32px,                     /* 谷 */
                88% 12px,                     /* 抬升 */
                100% 30px,                    /* 终 */
                100% 100%, 0 100%             /* 右边到底 */
            );
        }
        .grid-section .module-tag { color: var(--cp-yellow); margin-bottom: 20px; }
        .grid-section .module-tag::before { color: var(--cp-cyan); }
        .grid-section .module-tag .date { color: var(--cp-yellow-dim); }

        .tabs {
            display: flex; align-items: center; gap: 4px;
            margin-bottom: 18px; padding-bottom: 12px;
            border-bottom: 1px solid rgba(255,238,0,0.3);
            font-family: var(--cp-font-mono);
        }
        .tab {
            padding: 8px 18px; font-size: 13px; color: var(--cp-yellow);
            cursor: pointer; transition: all 0.15s; font-weight: 700;
        }
        .tab:hover { background: rgba(255,238,0,0.1); }
        .tab.active {
            background: var(--cp-yellow); color: var(--cp-black); font-weight: 900;
            clip-path: var(--cp-clip);
        }
        .tabs-right {
            margin-left: auto; display: flex; gap: 14px;
            font-size: 11px; color: var(--cp-yellow-dim);
        }
        .tabs-right a { color: var(--cp-yellow-dim); }
        .tabs-right a:hover { color: var(--cp-cyan); }

        .goods-grid {
            display: grid; grid-template-columns: repeat(6, 1fr); gap: 12px;
        }
        .goods-card {
            background: var(--cp-black); border: 1.5px solid var(--cp-yellow);
            overflow: hidden; cursor: pointer; transition: all 0.2s;
            clip-path: var(--cp-clip);
        }
        .goods-card:hover {
            background: var(--cp-yellow);
            color: var(--cp-black);
            transform: translateY(-2px);
        }
        .goods-card:hover .goods-title { color: var(--cp-black); }
        .goods-card:hover .goods-price { color: var(--cp-black); }
        .goods-card:hover .goods-cover { background: var(--cp-yellow-soft); }
        .goods-card:hover .goods-cover i { color: var(--cp-black); text-shadow: none; }
        .goods-card:hover .goods-credit { color: var(--cp-black); border-color: var(--cp-black); }
        .goods-card:hover .goods-foot, .goods-card:hover .goods-bidders, .goods-card:hover .goods-seller { color: var(--cp-black); }
        .goods-card:hover .goods-avatar { background: var(--cp-black); color: var(--cp-yellow); }

        .goods-cover {
            width: 100%; aspect-ratio: 1;
            background: var(--cp-dark); display: grid; place-items: center;
            position: relative; overflow: hidden;
        }
        .goods-cover::before {
            content: ''; position: absolute; inset: 0;
            background-image:
                linear-gradient(rgba(255,238,0,0.06) 1px, transparent 1px),
                linear-gradient(90deg, rgba(255,238,0,0.06) 1px, transparent 1px);
            background-size: 20px 20px;
        }
        .goods-cover i {
            font-size: 40px; color: var(--cp-yellow); opacity: 0.85;
            position: relative; z-index: 1;
            text-shadow: 0 0 12px rgba(255,238,0,0.4);
        }
        .goods-cover .tag {
            position: absolute; top: 6px; left: 6px;
            padding: 2px 8px; background: var(--cp-yellow); color: var(--cp-black);
            font-size: 10px; font-weight: 800; letter-spacing: 0.1em;
            text-transform: uppercase; z-index: 2;
            font-family: var(--cp-font-mono);
        }
        .goods-cover .tag.danger { background: var(--cp-red); color: var(--cp-yellow); }
        .goods-cover .tag.warning { background: var(--cp-yellow); color: var(--cp-black); }
        .goods-body { padding: 10px; }
        .goods-title {
            font-size: 12px; color: var(--cp-yellow); line-height: 1.4;
            margin-bottom: 8px; min-height: 34px;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
            transition: color 0.15s;
        }
        .goods-price-row {
            display: flex; align-items: baseline; justify-content: space-between; margin-bottom: 6px;
        }
        .goods-price {
            font-size: 15px; font-weight: 900; color: var(--cp-yellow); line-height: 1;
            font-family: var(--cp-font-mono);
            transition: color 0.15s;
        }
        .goods-price small { font-size: 11px; margin-right: 2px; }
        .goods-bidders {
            font-size: 10px; color: var(--cp-yellow-dim);
            display: flex; align-items: center; gap: 3px;
            font-family: var(--cp-font-mono);
            transition: color 0.15s;
        }
        .goods-foot {
            display: flex; align-items: center; gap: 5px;
            font-size: 10px; color: var(--cp-yellow-dim);
            font-family: var(--cp-font-mono);
            transition: color 0.15s;
        }
        .goods-avatar {
            width: 16px; height: 16px;
            background: var(--cp-yellow); color: var(--cp-black);
            display: grid; place-items: center;
            font-size: 9px; font-weight: 800; flex-shrink: 0;
            transition: all 0.15s;
        }
        .goods-seller { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
        .goods-credit {
            background: transparent; color: var(--cp-cyan);
            font-size: 9px; padding: 1px 4px; flex-shrink: 0;
            border: 1px solid var(--cp-cyan);
            transition: all 0.15s;
        }

        /* ============================================================
         * 右侧浮动操作栏
         * ============================================================ */
        .floats {
            position: sticky; top: 88px;
            display: flex; flex-direction: column; gap: 8px;
        }
        .float-btn {
            width: 48px; height: 48px; background: var(--cp-black);
            border: 2px solid var(--cp-yellow); color: var(--cp-yellow);
            display: flex; flex-direction: column; align-items: center; justify-content: center;
            font-size: 11px; gap: 1px; font-weight: 700;
            transition: all 0.15s; cursor: pointer;
            clip-path: var(--cp-clip);
        }
        .float-btn i { font-size: 16px; }
        .float-btn:hover { background: var(--cp-yellow); color: var(--cp-black); }
        .float-btn.primary { background: var(--cp-yellow); color: var(--cp-black); }
        .float-btn.primary:hover { background: #fff; }

        /* ============================================================
         * 页脚（黑底）
         * ============================================================ */
        .home-footer {
            background: var(--cp-black); color: var(--cp-yellow);
            margin-top: 0; padding: 40px 24px 20px;
            border-top: 2px solid var(--cp-yellow);
        }
        .home-footer-inner {
            max-width: 1280px; margin: 0 auto;
            display: grid; grid-template-columns: 1.5fr 1fr 1fr 1fr;
            gap: 48px; padding-bottom: 28px;
            border-bottom: 1px solid rgba(255,238,0,0.2);
        }
        .home-footer .footer-brand .logo {
            display: flex; align-items: center; gap: 10px; margin-bottom: 12px;
            color: var(--cp-yellow);
        }
        .home-footer .footer-brand .logo-icon {
            width: 38px; height: 38px;
            background: var(--cp-yellow); color: var(--cp-black);
            display: grid; place-items: center; font-size: 18px; font-weight: 900;
            clip-path: var(--cp-clip);
        }
        .home-footer .footer-brand .logo-text {
            font-size: 22px; font-weight: 900; color: var(--cp-yellow);
            letter-spacing: -0.01em;
        }
        .home-footer .footer-brand p {
            font-size: 12px; color: var(--cp-yellow-dim); line-height: 1.7; max-width: 320px;
        }
        .home-footer-col h4 {
            color: var(--cp-yellow); font-size: 14px; font-weight: 800;
            margin-bottom: 14px;
            font-family: var(--cp-font-mono);
        }
        .home-footer-col a {
            display: block; color: var(--cp-yellow-dim); font-size: 12px; padding: 4px 0;
            transition: color 0.15s;
        }
        .home-footer-col a i { margin-right: 6px; opacity: 0.7; }
        .home-footer-col a:hover { color: var(--cp-cyan); }
        .home-footer-bottom {
            max-width: 1280px; margin: 18px auto 0;
            font-size: 12px; color: var(--cp-yellow-dim); text-align: center;
            font-family: var(--cp-font-mono);
        }

        /* ============================================================
         * 响应式
         * ============================================================ */
        @media (max-width: 1200px) {
            .home-main { grid-template-columns: 200px 1fr 48px; padding: 20px; }
            .goods-grid { grid-template-columns: repeat(5, 1fr); }
            .color-blocks { grid-template-columns: repeat(4, 1fr); }
            .nav-tags { display: none; }
        }
        @media (max-width: 1024px) {
            .home-main { grid-template-columns: 200px 1fr; padding: 16px; }
            .floats { display: none; }
            .hero-inner { grid-template-columns: 1fr; gap: 28px; }
            .hero-title { font-size: 48px; }
            .goods-grid { grid-template-columns: repeat(4, 1fr); }
            .header-inner { gap: 12px; padding: 0 16px; }
            .nav-search { flex: 0 1 220px; }
        }
        @media (max-width: 768px) {
            .home-main { grid-template-columns: 1fr; padding: 12px; }
            .sidebar { position: static; }
            .goods-grid { grid-template-columns: repeat(2, 1fr); }
            .header-inner { gap: 8px; padding: 0 12px; height: 56px; }
            .nav, .nav-search, .nav-tags { display: none; }
            .hero { padding: 32px 0 24px; }
            .hero-title { font-size: 36px; }
            .color-blocks { grid-template-columns: repeat(2, 1fr); }
            .platform-row { gap: 14px; flex-wrap: wrap; }
            .grid-section { clip-path: polygon(0 20px, 20% 0, 40% 16px, 60% 4px, 80% 18px, 100% 8px, 100% 100%, 0 100%); }
        }
    </style>
</head>
<body>

<!-- ========== 顶部导航 ========== -->
<header class="header">
    <div class="header-inner">
        <a href="<%=ctx%>/index.jsp" class="logo">
            <span class="logo-icon"><i class="fa fa-bolt"></i></span>
            <span class="logo-text">二手拍卖</span>
        </a>
        <nav class="nav">
            <a href="<%=ctx%>/index.jsp" class="active">首页</a>
            <a href="javascript:void(0)" onclick="go('/item?action=list')">浏览拍品</a>
            <a href="javascript:void(0)" onclick="go('/item?action=publish-page')">发布拍品</a>
            <a href="javascript:void(0)" onclick="go('/item?action=list&sort=hot')">热门拍品</a>
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('/user?action=center')">个人中心</a>
            <% } %>
        </nav>
        <div id="vue-root" style="display: contents;">
            <div class="nav-search">
                <input type="text" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ..."
                       v-model="keyword" @keyup.enter="search">
                <button @click="search"><i class="fa fa-search"></i> 搜索</button>
            </div>
        </div>
        <div class="nav-tags">
            <span class="nav-tags-label">// 热搜：</span>
            <a href="javascript:void(0)" onclick="go('/item/list?keyword=iPhone')" class="nav-tag hot">iPhone 15</a>
            <a href="javascript:void(0)" onclick="go('/item/list?keyword=相机')" class="nav-tag">佳能相机</a>
            <a href="javascript:void(0)" onclick="go('/item/list?keyword=球鞋')" class="nav-tag">球鞋</a>
            <a href="javascript:void(0)" onclick="go('/item/list?keyword=茅台')" class="nav-tag hot">茅台</a>
        </div>
        <div class="user-info">
            <% if (currentUser != null) { %>
                <a href="javascript:void(0)" onclick="go('/user?action=center')" class="icon-btn" title="消息">
                    <i class="fa fa-envelope-o"></i><span class="dot"></span>
                </a>
                <a href="javascript:void(0)" onclick="go('/user?action=center')" class="icon-btn" title="我的">
                    <i class="fa fa-user-o"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/item?action=publish-page')" class="icon-btn" title="发拍品">
                    <i class="fa fa-plus"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/user?action=center')" class="avatar" title="<%= currentUser.getUsername() %>">
                    <%= currentUser.getUsername().substring(0, 1).toUpperCase() %>
                </a>
                <span class="user-name" style="font-size: 12px;"><%= currentUser.getUsername() %></span>
                <a href="<%=ctx%>/user?action=logout" class="logout-link">退出</a>
            <% } else { %>
                <a href="javascript:void(0)" onclick="go('/user?action=login')" class="icon-btn" title="消息">
                    <i class="fa fa-envelope-o"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/user?action=login')" class="icon-btn" title="登录">
                    <i class="fa fa-user-o"></i>
                </a>
                <a href="javascript:void(0)" onclick="go('/item?action=publish-page')" class="icon-btn" title="发拍品">
                    <i class="fa fa-plus"></i>
                </a>
                <a href="<%=ctx%>/user?action=login" class="login-link">登录</a>
                <a href="<%=ctx%>/user?action=register" class="register-link">注册</a>
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
<script>
    // 公告详情弹窗（简单 inline 显示）
    window.showNotice = function(id) {
        loadAxios().then(() => {
            axios.get('<%= ctx %>/admin/announcement?action=detail&id=' + id).then(r => {
                if (r.data.success) {
                    const n = r.data.notice;
                    const text = (n.content || '').replace(/\\n/g, '\\n');
                    alert('【' + n.title + '】\\n\\n' + text);
                } else {
                    toast('加载失败', 'error');
                }
            }).catch(() => toast('网络错误', 'error'));
        });
    };
</script>
<% } %>

<!-- ========== 主体三栏 ========== -->
<div class="home-main">

    <!-- 左侧分类侧栏 -->
    <aside class="sidebar">
        <ul class="cat-list">
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list')" class="cat-link active">
                    <i class="fa fa-th-large"></i> 全部拍品
                    <span class="count">1.2k</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=digital')" class="cat-link">
                    <i class="fa fa-mobile"></i> 手机数码
                    <span class="count">328</span>
                </a>
                <div class="cat-sub">
                    <div class="cat-sub-row">
                        <div class="cat-sub-label">手机</div>
                        <div class="cat-sub-items">
                            <a href="javascript:void(0)" onclick="go('/item/list?category=phone-apple')">苹果手机</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=phone-huawei')">华为手机</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=phone-xiaomi')">小米手机</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=phone-oppo')">OPPO</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=phone-vivo')">vivo</a>
                        </div>
                    </div>
                    <div class="cat-sub-row">
                        <div class="cat-sub-label">电脑</div>
                        <div class="cat-sub-items">
                            <a href="javascript:void(0)" onclick="go('/item/list?category=pc-laptop')">笔记本</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=pc-tablet')">平板电脑</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=pc-desktop')">台式机</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=pc-display')">显示器</a>
                        </div>
                    </div>
                    <div class="cat-sub-row">
                        <div class="cat-sub-label">数码</div>
                        <div class="cat-sub-items">
                            <a href="javascript:void(0)" onclick="go('/item/list?category=digital-headphone')">耳机</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=digital-camera')">相机</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=digital-speaker')">音箱</a>
                            <a href="javascript:void(0)" onclick="go('/item/list?category=digital-watch')">智能手表</a>
                        </div>
                    </div>
                </div>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=fashion')" class="cat-link">
                    <i class="fa fa-tag"></i> 服饰鞋包
                    <span class="count">216</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=sport')" class="cat-link">
                    <i class="fa fa-futbol-o"></i> 运动户外
                    <span class="count">142</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=book')" class="cat-link">
                    <i class="fa fa-book"></i> 图书音像
                    <span class="count">189</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=toy')" class="cat-link">
                    <i class="fa fa-paw"></i> 潮玩手办
                    <span class="count">95</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=home')" class="cat-link">
                    <i class="fa fa-home"></i> 家居家电
                    <span class="count">167</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=jewelry')" class="cat-link">
                    <i class="fa fa-diamond"></i> 奢品珠宝
                    <span class="count">38</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=beauty')" class="cat-link">
                    <i class="fa fa-paint-brush"></i> 美妆护肤
                    <span class="count">74</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=collection')" class="cat-link">
                    <i class="fa fa-trophy"></i> 文玩收藏
                    <span class="count">52</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=baby')" class="cat-link">
                    <i class="fa fa-baby"></i> 母婴儿童
                    <span class="count">63</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=car')" class="cat-link">
                    <i class="fa fa-car"></i> 汽车摩托
                    <span class="count">21</span>
                </a>
            </li>
            <li class="cat-item">
                <a href="javascript:void(0)" onclick="go('/item?action=list&category=instrument')" class="cat-link">
                    <i class="fa fa-music"></i> 乐器文具
                    <span class="count">44</span>
                </a>
            </li>
        </ul>
    </aside>

    <!-- 中央内容 -->
    <main class="content">

        <!-- ============================================================
             HERO（黄底大标题 + 黑边黄字按钮 + 右侧主推拍品）
             仿 cp 官网"享受《赛博朋克 2077》终极体验"风格
             ============================================================ -->
        <section class="hero">
            <div class="home-main" style="padding: 0; grid-template-columns: 1.2fr 1fr; gap: 40px;">
                <!-- 左侧：标题 + 描述 + 按钮 + 平台行 -->
                <div>
                    <div class="module-tag">// 欢迎来到夜之城</div>
                    <h1 class="hero-title">
                        享受《<span class="accent">二手</span>拍卖》<br>
                        <span class="stroke">终极</span>竞拍体验
                    </h1>
                    <p class="hero-desc">
                        沉浸探索二手拍卖的赛博宇宙 —— 从手机数码到潮玩手办，从奢侈品到文玩收藏。
                        在这座永不落幕的夜之城，每一件闲置好物都在等待新的主人。
                    </p>
                    <div class="hero-actions">
                        <a href="javascript:void(0)" onclick="go('/item?action=list')" class="cp-btn">
                            <i class="fa fa-bolt"></i> 立刻竞拍
                        </a>
                        <a href="javascript:void(0)" onclick="go('/item?action=publish-page')" class="cp-btn cp-btn-outline">
                            <i class="fa fa-upload"></i> 发布拍品
                        </a>
                    </div>
                    <div class="platform-row">
                        <span class="plat"><i class="fa fa-mobile"></i> 网页端</span>
                        <span class="plat"><i class="fa fa-android"></i> 安卓</span>
                        <span class="plat"><i class="fa fa-apple"></i> 苹果</span>
                        <span class="plat"><i class="fa fa-desktop"></i> 电脑</span>
                        <span class="plat"><i class="fa fa-shield"></i> 担保交易</span>
                    </div>
                </div>

                <!-- 右侧：主推拍品黑底卡 -->
                <div class="hero-spot" onclick="go('/item?action=detail&id=1')" style="cursor: pointer;">
                    <div class="hero-spot-cover">
                        <i class="fa fa-mobile"></i>
                        <span class="hero-spot-badge"><i class="fa fa-fire"></i> 即将结束</span>
                    </div>
                    <div class="hero-spot-body">
                        <h3 class="hero-spot-title">iPhone 15 Pro Max 256G 蓝色 自用 9 成新</h3>
                        <div class="hero-spot-meta">
                            <div class="hero-spot-price"><small>¥</small>5,280</div>
                            <div class="hero-spot-cd">02:34:11</div>
                        </div>
                        <a href="javascript:void(0)" onclick="event.stopPropagation(); go('/item?action=detail&id=1')" class="cp-btn" style="width: 100%;">
                            <i class="fa fa-gavel"></i> 立即出价
                        </a>
                    </div>
                </div>
            </div>
        </section>

        <!-- ============================================================
             SHOWCASE（4 个分类色块，在黄底大区里嵌套黑底小卡）
             ============================================================ -->
        <section class="showcase">
            <div class="home-main" style="padding: 0; grid-template-columns: 1fr; gap: 0;">
                <div class="showcase-head">
                    <div class="module-tag" style="color: var(--cp-black);">// 分类精选 <span class="date">// 热门好物</span></div>
                </div>
                <div class="color-blocks">
                    <div class="cb" data-no="P-01" onclick="go('/item?action=list&category=digital')">
                        <div class="cb-head">
                            <div class="cb-title">手机数码 <span class="arrow">›</span></div>
                        </div>
                        <div class="cb-sub">// 热门装备</div>
                        <div class="cb-thumbs">
                            <div class="cb-thumb"><i class="fa fa-mobile"></i><span class="price">¥999</span></div>
                            <div class="cb-thumb"><i class="fa fa-headphones"></i><span class="price">¥80</span></div>
                            <div class="cb-thumb"><i class="fa fa-laptop"></i><span class="price">¥36.8</span></div>
                        </div>
                        <div class="cb-badge"><i class="fa fa-mobile"></i></div>
                    </div>
                    <div class="cb cb-cyan" data-no="P-02" onclick="go('/item?action=list&category=fashion')">
                        <div class="cb-head">
                            <div class="cb-title">服饰潮搭 <span class="arrow">›</span></div>
                        </div>
                        <div class="cb-sub">// 时尚美衣</div>
                        <div class="cb-thumbs">
                            <div class="cb-thumb"><i class="fa fa-tag"></i><span class="price">¥119</span></div>
                            <div class="cb-thumb"><i class="fa fa-female"></i><span class="price">¥48</span></div>
                            <div class="cb-thumb"><i class="fa fa-shopping-bag"></i><span class="price">¥50</span></div>
                        </div>
                        <div class="cb-badge"><i class="fa fa-tag"></i></div>
                    </div>
                    <div class="cb cb-red" data-no="P-03" onclick="go('/item?action=list&category=book')">
                        <div class="cb-head">
                            <div class="cb-title">图书文具 <span class="arrow">›</span></div>
                        </div>
                        <div class="cb-sub">// 知识海洋</div>
                        <div class="cb-thumbs">
                            <div class="cb-thumb"><i class="fa fa-book"></i><span class="price">¥12</span></div>
                            <div class="cb-thumb"><i class="fa fa-pencil"></i><span class="price">¥9</span></div>
                            <div class="cb-thumb"><i class="fa fa-file-text-o"></i><span class="price">¥25</span></div>
                        </div>
                        <div class="cb-badge"><i class="fa fa-book"></i></div>
                    </div>
                    <div class="cb cb-yellow-dim" data-no="P-04" onclick="go('/item?action=list&category=home')">
                        <div class="cb-head">
                            <div class="cb-title">家居家电 <span class="arrow">›</span></div>
                        </div>
                        <div class="cb-sub">// 焕新生活</div>
                        <div class="cb-thumbs">
                            <div class="cb-thumb"><i class="fa fa-coffee"></i><span class="price">¥299</span></div>
                            <div class="cb-thumb"><i class="fa fa-lightbulb-o"></i><span class="price">¥35</span></div>
                            <div class="cb-thumb"><i class="fa fa-leaf"></i><span class="price">¥58</span></div>
                        </div>
                        <div class="cb-badge"><i class="fa fa-home"></i></div>
                    </div>
                </div>
            </div>
        </section>

        <!-- 标签栏 + 商品网格 -->
        <section class="grid-section">
            <div class="module-tag">拍品列表 <span class="dot-sep">//</span> 全部拍品</div>
            <div class="tabs">
                <a href="javascript:void(0)" class="tab active">猜你喜欢</a>
                <a href="javascript:void(0)" onclick="go('/item?action=list&sort=ending')" class="tab">即将结束</a>
                <a href="javascript:void(0)" onclick="go('/item?action=list&sort=newest')" class="tab">最新发布</a>
                <a href="javascript:void(0)" onclick="go('/item?action=list&sort=hot')" class="tab">人气榜</a>
                <a href="javascript:void(0)" onclick="go('/item?action=list&sort=price-asc')" class="tab">价格低 → 高</a>
                <a href="javascript:void(0)" onclick="go('/item?action=list&sort=price-desc')" class="tab">价格高 → 低</a>
                <div class="tabs-right">
                    <a href="javascript:void(0)">综合 <i class="fa fa-angle-down"></i></a>
                    <a href="javascript:void(0)">筛选 <i class="fa fa-sliders"></i></a>
                </div>
            </div>

            <div class="goods-grid">
                <%-- 商品卡 x 12（首页静态展示，无后端数据） --%>
                <div class="goods-card" onclick="go('/item?action=detail&id=101')">
                    <div class="goods-cover">
                        <i class="fa fa-mobile"></i>
                        <span class="tag danger">即将结束</span>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">iPhone 14 Pro 256G 深空黑 99新 自用一台</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>4,250</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 26</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">A</span>
                            <span class="goods-seller">u***nd</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=102')">
                    <div class="goods-cover">
                        <i class="fa fa-clock-o"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">劳力士 Submariner 黑水鬼 全新未拆封 现货</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>62,000</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 11</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">B</span>
                            <span class="goods-seller">钟***哥</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=103')">
                    <div class="goods-cover">
                        <i class="fa fa-paw"></i>
                        <span class="tag warning">包邮</span>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">出原神 艾尔海森 月之.cos 服全套 S码 几乎全新配件齐</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>200</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 8</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">C</span>
                            <span class="goods-seller">一***人</span>
                            <span class="goods-credit">信用优秀</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=104')">
                    <div class="goods-cover">
                        <i class="fa fa-microchip"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">全新未拆 AMD 锐龙 R9 9950X 盒装 CPU 16 核 32 线程</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>3,099</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 115</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">D</span>
                            <span class="goods-seller">d***d</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=105')">
                    <div class="goods-cover">
                        <i class="fa fa-hdd-o"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">处理一批 2.5G 15KM 40KM 80KM 单模光模块 全新</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>13</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 100</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">E</span>
                            <span class="goods-seller">光***瓜</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=106')">
                    <div class="goods-cover">
                        <i class="fa fa-female"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">毕业出深圳中学女生校裤 9 成新 170 校裤四季款</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>48</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 17</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">F</span>
                            <span class="goods-seller">小***gj</span>
                            <span class="goods-credit">信用优秀</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=107')">
                    <div class="goods-cover">
                        <i class="fa fa-camera-retro"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">佳能 EOS R6 Mark II 套机 24-105 镜头 99 新</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>16,800</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 34</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">G</span>
                            <span class="goods-seller">摄***舍</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=108')">
                    <div class="goods-cover">
                        <i class="fa fa-headphones"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">索尼 WH-1000XM5 头戴式降噪耳机 黑色 9 成新</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>1,580</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 19</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">H</span>
                            <span class="goods-seller">音***控</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=109')">
                    <div class="goods-cover">
                        <i class="fa fa-gamepad"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">Switch OLED 白色 港版 9 成新 附 6 款游戏卡带</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>1,650</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 22</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">I</span>
                            <span class="goods-seller">玩***家</span>
                            <span class="goods-credit">信用优秀</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=110')">
                    <div class="goods-cover">
                        <i class="fa fa-book"></i>
                        <span class="tag">绝版</span>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">三体全集 3 本 刘慈欣 典藏版 全新未拆封</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>128</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 45</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">J</span>
                            <span class="goods-seller">书***屋</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=111')">
                    <div class="goods-cover">
                        <i class="fa fa-bicycle"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">捷安特 TCR 公路自行车 碳纤维 21 速 9 成新</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>4,500</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 7</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">K</span>
                            <span class="goods-seller">骑***者</span>
                            <span class="goods-credit">信用优秀</span>
                        </div>
                    </div>
                </div>

                <div class="goods-card" onclick="go('/item?action=detail&id=112')">
                    <div class="goods-cover">
                        <i class="fa fa-coffee"></i>
                    </div>
                    <div class="goods-body">
                        <div class="goods-title">德龙 ECP33.22 意式半自动咖啡机 白色 自用</div>
                        <div class="goods-price-row">
                            <div class="goods-price"><small>¥</small>680</div>
                            <div class="goods-bidders"><i class="fa fa-user-o"></i> 13</div>
                        </div>
                        <div class="goods-foot">
                            <span class="goods-avatar">L</span>
                            <span class="goods-seller">咖***啡</span>
                            <span class="goods-credit">信用极好</span>
                        </div>
                    </div>
                </div>
            </div>
        </section>

    </main>

    <!-- 右侧浮动操作栏 -->
    <aside class="floats">
        <div class="float-btn primary" title="发拍品" onclick="go('/item?action=publish-page')">
            <i class="fa fa-plus"></i><span>发布</span>
        </div>
        <div class="float-btn" title="消息" onclick="go('<%= currentUser != null ? "/user?action=center" : "/user?action=login" %>')">
            <i class="fa fa-envelope-o"></i><span>消息</span>
        </div>
        <div class="float-btn" title="APP" onclick="toast('APP 下载敬请期待', 'info')">
            <i class="fa fa-mobile"></i><span>APP</span>
        </div>
        <div class="float-btn" title="反馈" onclick="toast('反馈功能开发中', 'info')">
            <i class="fa fa-commenting-o"></i><span>反馈</span>
        </div>
        <div class="float-btn" title="客服" onclick="toast('客服：400-888-8888', 'info')">
            <i class="fa fa-headphones"></i><span>客服</span>
        </div>
        <div class="float-btn" title="回顶部" onclick="window.scrollTo({top: 0, behavior: 'smooth'})" style="margin-top: auto;">
            <i class="fa fa-arrow-up"></i><span>顶部</span>
        </div>
    </aside>

</div>

<!-- 页脚 -->
<footer class="home-footer">
    <div class="home-footer-inner">
        <div class="footer-brand">
            <a href="<%=ctx%>/index.jsp" class="logo">
                <span class="logo-icon"><i class="fa fa-bolt"></i></span>
                <span class="logo-text">二手拍卖</span>
            </a>
            <p>// 让闲置流转，让价值新生。<br>// 一个透明、安全、高效的二手物品竞拍平台。</p>
        </div>
        <div class="home-footer-col">
            <h4>// 关于我们</h4>
            <a href="javascript:void(0)">平台介绍</a>
            <a href="javascript:void(0)">用户协议</a>
            <a href="javascript:void(0)">隐私政策</a>
        </div>
        <div class="home-footer-col">
            <h4>// 帮助中心</h4>
            <a href="javascript:void(0)">拍卖规则</a>
            <a href="javascript:void(0)">买家指南</a>
            <a href="javascript:void(0)">卖家指南</a>
        </div>
        <div class="home-footer-col">
            <h4>// 联系方式</h4>
            <a href="javascript:void(0)"><i class="fa fa-envelope"></i> support@auction.com</a>
            <a href="javascript:void(0)"><i class="fa fa-phone"></i> 400-888-8888</a>
            <a href="javascript:void(0)"><i class="fa fa-weixin"></i> 微信公众号</a>
        </div>
    </div>
    <div class="home-footer-bottom">
        © 2025 二手拍卖 · Powered by JSP + Servlet + MyBatis + Vue
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
