<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%
    String ctx = request.getContextPath();
    org.example.entity.User currentUser =
            (org.example.entity.User) session.getAttribute("currentUser");
    if (currentUser == null) {
        // login filter should have caught this; defensive redirect
        response.sendRedirect(ctx + "/user?action=login");
        return;
    }

    org.example.entity.AuctionItem preItem =
            (org.example.entity.AuctionItem) request.getAttribute("item");
    if (preItem == null) {
        response.sendRedirect(ctx + "/item?action=list");
        return;
    }

    org.example.servlet.ItemServlet.EditableScope scope =
            (org.example.servlet.ItemServlet.EditableScope) request.getAttribute("editable");
    if (scope == null) scope = new org.example.servlet.ItemServlet.EditableScope();

    String categoriesJson   = (String) request.getAttribute("categoriesJson");
    String error            = (String) request.getAttribute("error");
    if (categoriesJson == null) categoriesJson = "[]";

    // 把 entity 字段摊平成 preXxx 局部变量（JSP 后面的脚本引用）
    String   preTitle           = preItem.getTitle();
    String   preDescription     = preItem.getDescription();
    String   preBrand           = preItem.getBrand();
    String   preModel           = preItem.getModel();
    String   preConditionLevel  = preItem.getConditionLevel();
    String   preFlawDesc        = preItem.getFlawDesc();
    String   preCoverImage      = preItem.getCoverImage();
    String   preImageUrls       = preItem.getImageUrls();
    String   preStartPrice      = preItem.getStartPrice() == null ? "" : preItem.getStartPrice().toPlainString();
    String   preBidIncrement    = preItem.getBidIncrement() == null ? "" : preItem.getBidIncrement().toPlainString();
    String   preReservePrice    = preItem.getReservePrice() == null ? "" : preItem.getReservePrice().toPlainString();
    String   preStartTime       = "";
    String   preEndTime         = "";
    if (preItem.getStartTime() != null) {
        preStartTime = preItem.getStartTime().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"));
    }
    if (preItem.getEndTime() != null) {
        preEndTime = preItem.getEndTime().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm"));
    }
    Integer  preCategoryId     = preItem.getCategoryId();
    Integer  preItemId         = preItem.getId();
    Integer  preStatus         = preItem.getStatus();

    String statusText = "未知";
    if (preStatus != null) {
        switch (preStatus) {
            case 0: statusText = "待审核"; break;
            case 1: statusText = scope.bidding ? "拍卖中（已开始）" : "拍卖中（未开始）"; break;
            case 2: statusText = "已成交"; break;
            case 3: statusText = "已流拍"; break;
            case 4: statusText = "已下架"; break;
            case 5: statusText = "审核未通过"; break;
        }
    }
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>发布拍品 · 二手物品拍卖系统</title>
    <link rel="stylesheet" href="<%=ctx%>/static/css/common.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/font-awesome@4.7.0/css/font-awesome.min.css">
    <style>
        /* ============================================================
         * 发布拍品页 v2
         * - 顶 nav 统一（白底 + 搜索框 + 用户区）
         * - 单卡加宽 960px，4 个分组大标题
         * - 字段两两并排 / 实时图片预览 / 快捷金额+时长按钮
         * - 底部提交 sticky 跟随
         * - 保留所有 Vue 接管、Servlet 提交、URL 跳转
         * ============================================================ */
        body { background: #f5f5f5; }

        /* ---------- 顶 nav（与首页/列表页统一） ---------- */
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
            font-size: 13px; font-weight: 600;
        }
        .user-name-link { color: var(--color-text); font-weight: 500; }

        /* ---------- 主体 ---------- */
        .publish-wrap { max-width: 960px; margin: 24px auto 120px; padding: 0 16px; }
        .publish-card {
            background: #fff; border-radius: 12px;
            padding: 36px 44px 28px; box-shadow: 0 2px 12px rgba(0,0,0,0.05);
        }
        .publish-head { margin-bottom: 28px; padding-bottom: 20px;
                        border-bottom: 1px solid var(--color-border-soft); }
        .publish-title {
            font-size: 24px; font-weight: 700; color: var(--color-text);
            display: flex; align-items: center; gap: 10px; margin-bottom: 8px;
        }
        .publish-title-icon {
            width: 36px; height: 36px; border-radius: 8px;
            background: var(--color-primary-light); color: var(--color-primary);
            display: grid; place-items: center; font-size: 18px;
        }
        .publish-sub { color: var(--color-muted); font-size: 13px; }

        /* ---------- 分组 ---------- */
        .section-block { margin-bottom: 32px; }
        .section-block:last-of-type { margin-bottom: 0; }
        .section-head {
            display: flex; align-items: baseline; gap: 12px; margin-bottom: 16px;
        }
        .section-num {
            width: 26px; height: 26px; border-radius: 6px;
            background: var(--color-primary); color: #fff;
            display: grid; place-items: center;
            font-size: 13px; font-weight: 700; flex-shrink: 0;
        }
        .section-title { font-size: 16px; font-weight: 600; color: var(--color-text); }
        .section-tip { color: var(--color-muted); font-size: 12px; margin-left: auto; }

        /* ---------- 表单字段 ---------- */
        .form-group { margin-bottom: 16px; }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .form-row-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 16px; }
        @media (max-width: 600px) {
            .form-row, .form-row-3 { grid-template-columns: 1fr; }
        }
        .form-label {
            display: block; font-size: 13px; color: var(--color-text);
            margin-bottom: 6px; font-weight: 500;
        }
        .form-label .required { color: var(--color-danger); margin-left: 2px; }
        .form-input {
            width: 100%; padding: 10px 12px;
            border: 1.5px solid var(--color-border);
            border-radius: 6px; font-size: 14px; color: var(--color-text);
            background: #fff; transition: border-color 0.15s, box-shadow 0.15s;
            font-family: inherit;
        }
        .form-input:hover { border-color: #cbd5e1; }
        .form-input:focus {
            outline: none; border-color: var(--color-primary);
            box-shadow: 0 0 0 3px rgba(255,107,53,0.12);
        }
        .form-input.error { border-color: var(--color-danger); }
        .form-input.error:focus { box-shadow: 0 0 0 3px rgba(239,68,68,0.12); }
        textarea.form-input { resize: vertical; min-height: 90px; line-height: 1.6; }
        .form-hint { font-size: 12px; color: var(--color-muted); margin-top: 4px; }
        .form-error { font-size: 12px; color: var(--color-danger); margin-top: 4px; min-height: 16px; }

        /* ---------- 快捷按钮（起拍价 / 拍卖时长） ---------- */
        .quick-row {
            display: flex; align-items: center; gap: 6px; flex-wrap: wrap;
            margin-top: 8px;
        }
        .quick-row-label {
            font-size: 12px; color: var(--color-muted);
            margin-right: 2px; flex-shrink: 0;
        }
        .quick-btn {
            padding: 4px 12px; font-size: 12px;
            background: var(--color-primary-light); color: var(--color-primary);
            border: 1px solid transparent; border-radius: 14px;
            cursor: pointer; transition: all 0.15s; font-weight: 500;
        }
        .quick-btn:hover {
            background: var(--color-primary); color: #fff;
            transform: translateY(-1px);
        }

        /* ---------- 图片预览 ---------- */
        .image-row { display: grid; grid-template-columns: 1fr 120px; gap: 16px; align-items: start; }
        .cover-preview {
            width: 120px; height: 120px; border-radius: 8px;
            background: var(--color-primary-soft);
            display: grid; place-items: center;
            border: 1.5px dashed #fed7aa; overflow: hidden;
            color: var(--color-placeholder); font-size: 12px;
        }
        .cover-preview img { width: 100%; height: 100%; object-fit: cover; }
        .cover-preview .ph-icon { font-size: 28px; color: rgba(255,107,53,0.4); }
        .cover-preview .ph-text { display: block; margin-top: 4px; }

        .image-thumbs {
            display: grid; grid-template-columns: repeat(5, 1fr);
            gap: 6px; margin-top: 10px;
        }
        .image-thumb {
            position: relative;
            aspect-ratio: 1; background: var(--color-primary-soft);
            border-radius: 6px; overflow: hidden;
            border: 1.5px dashed #fed7aa;
            display: grid; place-items: center;
            color: var(--color-placeholder);
        }
        .image-thumb img { width: 100%; height: 100%; object-fit: cover; }
        .image-thumb.empty i { font-size: 18px; color: rgba(255,107,53,0.35); }
        .image-thumb.cover {
            border: 2px solid var(--color-primary);
            box-shadow: 0 0 0 3px rgba(255,107,53,0.18);
        }
        .thumb-actions {
            position: absolute; inset: auto 0 0 0;
            display: flex; justify-content: center; gap: 4px;
            padding: 4px;
            background: linear-gradient(transparent, rgba(0,0,0,0.55));
            opacity: 0; transition: opacity 0.15s;
        }
        .image-thumb:hover .thumb-actions { opacity: 1; }
        .thumb-btn {
            width: 26px; height: 26px; padding: 0;
            border: none; border-radius: 4px; cursor: pointer;
            background: rgba(255,255,255,0.92); color: var(--color-text-sub);
            font-size: 12px; display: grid; place-items: center;
        }
        .thumb-btn:hover { background: #fff; color: var(--color-primary); }
        .thumb-btn.danger:hover { color: var(--color-danger); }
        .thumb-btn.cover-tag {
            background: var(--color-primary); color: #fff; cursor: default;
        }
        .thumb-btn.cover-tag:hover { background: var(--color-primary); color: #fff; }

        /* 上传按钮条 */
        .upload-bar { display: flex; align-items: center; gap: 8px; }
        .upload-btn {
            display: inline-flex; align-items: center; gap: 8px;
            padding: 9px 18px;
            background: var(--color-primary); color: #fff;
            border-radius: 6px; cursor: pointer;
            font-size: 13px; font-weight: 600;
            transition: background 0.15s;
        }
        .upload-btn:hover { background: var(--color-primary-hover, #e85a25); }
        .upload-btn:has(input:disabled) { opacity: 0.6; cursor: not-allowed; }

        /* ---------- 错误条 ---------- */
        .alert { padding: 12px 16px; border-radius: 8px; margin-bottom: 16px; font-size: 13px; }
        .alert-error { background: #fee2e2; color: var(--color-danger); }

        /* ---------- 提交按钮（sticky 在底部） ---------- */
        .submit-bar {
            position: sticky; bottom: 0; z-index: 50;
            margin: 0 -44px -28px; padding: 16px 44px;
            background: #fff;
            border-top: 1px solid var(--color-border-soft);
            border-radius: 0 0 12px 12px;
            display: flex; align-items: center; justify-content: flex-end; gap: 12px;
        }
        .submit-bar .draft-hint {
            margin-right: auto; font-size: 12px; color: var(--color-muted);
        }
        .submit-bar .draft-hint i { color: var(--color-success); }
        .btn-publish {
            padding: 11px 32px; background: var(--color-primary); color: #fff;
            font-size: 15px; font-weight: 600; border-radius: 6px;
            display: inline-flex; align-items: center; gap: 6px;
            transition: background 0.15s, transform 0.15s;
            border: none; cursor: pointer;
        }
        .btn-publish:hover:not(:disabled) {
            background: var(--color-primary-hover); transform: translateY(-1px);
        }
        .btn-publish:disabled { opacity: 0.6; cursor: not-allowed; }
        .btn-cancel {
            padding: 11px 24px; color: var(--color-text-sub);
            font-size: 14px; border-radius: 6px;
            border: 1px solid var(--color-border); background: #fff;
            transition: all 0.15s; cursor: pointer;
        }
        .btn-cancel:hover { border-color: var(--color-primary); color: var(--color-primary); }
        .btn-offline {
            padding: 11px 22px; background: #fff; color: var(--color-danger);
            font-size: 14px; font-weight: 600; border-radius: 6px;
            border: 1.5px solid var(--color-danger); cursor: pointer;
            transition: all 0.15s;
        }
        .btn-offline:hover { background: var(--color-danger); color: #fff; }

        /* 禁用态：所有可禁用字段 */
        .form-input:disabled, .form-input.disabled {
            background: #f9fafb; color: var(--color-muted);
            cursor: not-allowed; border-color: var(--color-border-soft);
        }
        .form-input:disabled::placeholder { color: #d1d5db; }

        /* 状态 badge */
        .status-badge {
            margin-left: 12px; padding: 4px 12px; border-radius: 12px;
            background: rgba(255,107,53,0.1); color: var(--color-primary);
            font-size: 12px; font-weight: 600;
        }

        /* ---------- 页脚 ---------- */
        .publish-footer {
            background: #1f2937; color: #d1d5db;
            padding: 24px 16px; text-align: center;
            font-size: 12px; color: #6b7280;
        }

        /* ---------- 响应式 ---------- */
        @media (max-width: 1024px) {
            .nav-tags { display: none; }
            .nav-search { flex: 0 1 280px; }
        }
        @media (max-width: 768px) {
            .header-inner { gap: 8px; padding: 0 12px; }
            .nav { display: none; }
            .nav-search { flex: 1; }
            .publish-card { padding: 24px 20px 20px; }
            .submit-bar { margin: 0 -20px -20px; padding: 14px 20px; }
            .image-row { grid-template-columns: 1fr; }
            .image-thumbs { grid-template-columns: repeat(4, 1fr); }
        }

        [v-cloak] { display: none; }
        .loading-placeholder { padding: 60px 20px; text-align: center; color: var(--color-muted); font-size: 14px; }
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
            <a href="<%=ctx%>/item?action=publish-page" class="active">发布拍品</a>
            <a href="javascript:void(0)" onclick="go('<%=ctx%>/item?action=list&sort=hot')">热门拍品</a>
            <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=center')">个人中心</a>
        </nav>
        <form action="<%=ctx%>/item" method="get" class="nav-search">
            <input type="hidden" name="action" value="list">
            <input type="text" name="keyword" placeholder="搜索拍品 · 数码 / 服饰 / 书籍 ...">
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
            <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=center')" class="user-name-link"><%= currentUser.getUsername() %></a>
            <a href="javascript:void(0)" onclick="go('<%=ctx%>/user?action=logout')" style="font-size: 12px; color: var(--color-muted);">退出</a>
            <span class="avatar"><%= currentUser.getUsername().substring(0, 1).toUpperCase() %></span>
        </div>
    </div>
</header>

<div class="publish-wrap">
    <div id="app" class="publish-card">
        <!-- 页面头 -->
        <div class="publish-head">
            <div class="publish-title">
                <span class="publish-title-icon"><i class="fa fa-plus"></i></span>
                <span>编辑拍品</span>
                <span class="status-badge">状态：<%= statusText %></span>
            </div>
            <p class="publish-sub">
                <% if (scope.editableHardFields) { %>
                    全字段可编辑（价格/时间/分类也可改）。
                <% } else if (scope.editableSoftFields) { %>
                    <span style="color: var(--color-warning); font-weight: 600;">⚠ 拍卖已开始</span>，只能编辑"描述/瑕疵/图片"等软信息；价格、时间、分类已锁定（保护已出价者信任）。
                <% } else { %>
                    当前状态不允许编辑。
                <% } %>
            </p>
        </div>

        <div v-if="serverError" class="alert alert-error">{{ serverError }}</div>

        <form action="<%=ctx%>/item?action=edit&id=<%= preItemId %>" method="post"
              @submit.prevent="handleSubmit($event)" novalidate>

            <!-- ========== 分组 1：基本信息 ========== -->
            <div class="section-block">
                <div class="section-head">
                    <span class="section-num">1</span>
                    <span class="section-title">基本信息</span>
                    <span class="section-tip">分类 + 标题 + 详细描述</span>
                </div>

                <div class="form-group">
                    <label class="form-label">分类<span class="required">*</span></label>
                    <select name="categoryId" class="form-input" v-model.number="form.categoryId"
                            :disabled="!editable.editableHardFields"
                            :class="{ error: touched.categoryId && errors.categoryId, disabled: !editable.editableHardFields }">
                        <option :value="null">请选择分类</option>
                        <option v-for="c in topCategories" :key="'t' + (c && c.id || 'x')" :value="c ? c.id : null">
                            {{ c ? c.categoryName : '' }}
                        </option>
                        <option v-for="c in childCategories" :key="'c' + (c && c.id || 'x')" :value="c ? c.id : null">
                            &nbsp;&nbsp;&nbsp;&nbsp;{{ c ? c.categoryName : '' }}
                        </option>
                    </select>
                    <span class="form-error" v-if="touched.categoryId && errors.categoryId">{{ errors.categoryId }}</span>
                </div>

                <div class="form-group">
                    <label class="form-label">标题<span class="required">*</span></label>
                    <input type="text" name="title" class="form-input" maxlength="100"
                           v-model="form.title" placeholder="5-100 字，例如：iPhone 14 Pro 256G 深空黑 99新"
                           @blur="touched.title = true; validateField('title')"
                           :class="{ error: touched.title && errors.title }">
                    <span class="form-hint">好的标题能吸引更多出价者 · 已输入 {{ form.title.length || 0 }} / 100 字</span>
                    <span class="form-error" v-if="touched.title && errors.title">{{ errors.title }}</span>
                </div>

                <div class="form-group">
                    <label class="form-label">详细描述<span class="required">*</span></label>
                    <textarea name="description" class="form-input" rows="5"
                              v-model="form.description"
                              placeholder="请详细描述商品情况：购买时间、使用频率、配件是否齐全、转手原因 ..."
                              @blur="touched.description = true; validateField('description')"
                              :class="{ error: touched.description && errors.description }"></textarea>
                    <span class="form-error" v-if="touched.description && errors.description">{{ errors.description }}</span>
                </div>
            </div>

            <!-- ========== 分组 2：规格参数 ========== -->
            <div class="section-block">
                <div class="section-head">
                    <span class="section-num">2</span>
                    <span class="section-title">规格参数</span>
                    <span class="section-tip">品牌 / 型号 / 新旧 / 瑕疵（选填）</span>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">品牌</label>
                        <input type="text" name="brand" class="form-input" maxlength="50"
                               v-model="form.brand" placeholder="如：Apple / 华为">
                    </div>
                    <div class="form-group">
                        <label class="form-label">型号</label>
                        <input type="text" name="model" class="form-input" maxlength="50"
                               v-model="form.model" placeholder="如：iPhone 14 Pro">
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">新旧程度<span class="required">*</span></label>
                        <select name="conditionLevel" class="form-input" v-model="form.conditionLevel">
                            <option value="全新">全新</option>
                            <option value="99新">99新</option>
                            <option value="9.9新">9.9新</option>
                            <option value="95新">95新</option>
                            <option value="9.5新">9.5新</option>
                            <option value="9成新">9成新</option>
                            <option value="8成新">8成新</option>
                            <option value="7成新">7成新</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label">瑕疵说明</label>
                        <input type="text" name="flawDesc" class="form-input" maxlength="255"
                               v-model="form.flawDesc" placeholder="无明显瑕疵可留空">
                    </div>
                </div>
            </div>

            <!-- ========== 分组 3：拍品图片 ========== -->
            <div class="section-block">
                <div class="section-head">
                    <span class="section-num">3</span>
                    <span class="section-title">拍品图片</span>
                    <span class="section-tip">每行一个远程 URL，最多 5 张，第一行作为封面</span>
                </div>

                <div class="form-group">
                    <label class="form-label">图片 URL<span class="required">*</span></label>
                    <textarea name="imageUrls" class="form-input" rows="5"
                              v-model="form.imageUrls"
                              @blur="touched.imageUrls = true; validateField('imageUrls')"
                              :class="{ error: touched.imageUrls && errors.imageUrls }"
                              placeholder="每行一个远程图片 URL，例如：&#10;https://example.com/iphone-1.jpg&#10;https://example.com/iphone-2.jpg"></textarea>
                    <span class="form-hint">
                        仅支持远程 URL（以 <code>http://</code> 或 <code>https://</code> 开头），每行一个，最多 5 张，第一行作为封面。
                    </span>
                    <span class="form-error" v-if="touched.imageUrls && errors.imageUrls">{{ errors.imageUrls }}</span>
                </div>

                <!-- URL 预览（仅当 URL 是 webapp 内可访问时显示） -->
                <div v-if="imageUrlList.length > 0" class="image-thumbs">
                    <div v-for="(u, idx) in imageUrlList" :key="idx"
                         class="image-thumb" :class="{ cover: idx === 0 }">
                        <img :src="u" @error="onImgError($event)" :alt="'图' + (idx+1)">
                    </div>
                    <div v-for="i in (5 - imageUrlList.length)" :key="'empty'+i"
                         v-if="imageUrlList.length < 5" class="image-thumb empty">
                        <i class="fa fa-plus"></i>
                    </div>
                </div>
            </div>

            <!-- ========== 分组 4：价格与拍卖时间 ========== -->
            <div class="section-block">
                <div class="section-head">
                    <span class="section-num">4</span>
                    <span class="section-title">价格与拍卖时间</span>
                    <span class="section-tip">起拍价 / 加价幅度 / 保留价 / 起止时间</span>
                </div>

                <div class="form-row-3">
                    <div class="form-group">
                        <label class="form-label">起拍价 (元)<span class="required">*</span></label>
                        <input type="number" name="startPrice" class="form-input" min="0.01" step="0.01"
                               v-model.number="form.startPrice"
                               :disabled="!editable.editableHardFields"
                               @blur="touched.startPrice = true; validateField('startPrice')"
                               :class="{ error: touched.startPrice && errors.startPrice, disabled: !editable.editableHardFields }">
                        <div class="quick-row" v-if="editable.editableHardFields">
                            <span class="quick-row-label">快捷：</span>
                            <span class="quick-btn" @click="form.startPrice = 10">¥10</span>
                            <span class="quick-btn" @click="form.startPrice = 50">¥50</span>
                            <span class="quick-btn" @click="form.startPrice = 100">¥100</span>
                            <span class="quick-btn" @click="form.startPrice = 500">¥500</span>
                            <span class="quick-btn" @click="form.startPrice = 1000">¥1000</span>
                        </div>
                        <span class="form-error" v-if="touched.startPrice && errors.startPrice">{{ errors.startPrice }}</span>
                    </div>
                    <div class="form-group">
                        <label class="form-label">加价幅度 (元)<span class="required">*</span></label>
                        <input type="number" name="bidIncrement" class="form-input" min="0.01" step="0.01"
                               v-model.number="form.bidIncrement"
                               :disabled="!editable.editableHardFields"
                               @blur="touched.bidIncrement = true; validateField('bidIncrement')"
                               :class="{ error: touched.bidIncrement && errors.bidIncrement, disabled: !editable.editableHardFields }">
                        <div class="quick-row" v-if="editable.editableHardFields">
                            <span class="quick-row-label">快捷：</span>
                            <span class="quick-btn" @click="form.bidIncrement = 1">¥1</span>
                            <span class="quick-btn" @click="form.bidIncrement = 5">¥5</span>
                            <span class="quick-btn" @click="form.bidIncrement = 10">¥10</span>
                            <span class="quick-btn" @click="form.bidIncrement = 50">¥50</span>
                        </div>
                        <span class="form-hint">默认 1.00 元</span>
                        <span class="form-error" v-if="touched.bidIncrement && errors.bidIncrement">{{ errors.bidIncrement }}</span>
                    </div>
                    <div class="form-group">
                        <label class="form-label">保留价 (元)</label>
                        <input type="number" name="reservePrice" class="form-input" min="0" step="0.01"
                               v-model.number="form.reservePrice" placeholder="选填"
                               :disabled="!editable.editableHardFields"
                               :class="{ disabled: !editable.editableHardFields }">
                        <span class="form-hint">不到保留价可流拍</span>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label">开始时间<span class="required">*</span></label>
                        <input type="datetime-local" name="startTime" class="form-input"
                               v-model="form.startTime"
                               :disabled="!editable.editableHardFields"
                               @blur="touched.startTime = true; validateField('startTime')"
                               :class="{ error: touched.startTime && errors.startTime, disabled: !editable.editableHardFields }">
                        <span class="form-error" v-if="touched.startTime && errors.startTime">{{ errors.startTime }}</span>
                    </div>
                    <div class="form-group">
                        <label class="form-label">结束时间<span class="required">*</span></label>
                        <input type="datetime-local" name="endTime" class="form-input"
                               v-model="form.endTime"
                               :disabled="!editable.editableHardFields"
                               @blur="touched.endTime = true; validateField('endTime')"
                               :class="{ error: touched.endTime && errors.endTime, disabled: !editable.editableHardFields }">
                        <div class="quick-row" v-if="editable.editableHardFields">
                            <span class="quick-row-label">时长：</span>
                            <span class="quick-btn" @click="setEndTime(1)">1 天</span>
                            <span class="quick-btn" @click="setEndTime(3)">3 天</span>
                            <span class="quick-btn" @click="setEndTime(7)">7 天</span>
                            <span class="quick-btn" @click="setEndTime(14)">14 天</span>
                        </div>
                        <span class="form-error" v-if="touched.endTime && errors.endTime">{{ errors.endTime }}</span>
                    </div>
                </div>
            </div>

            <!-- 提交按钮 sticky 底部 -->
            <div class="submit-bar">
                <span class="draft-hint" v-if="draftSaved">
                    <i class="fa fa-check-circle"></i> 草稿已自动保存
                </span>
                <a href="<%=ctx%>/item?action=detail&id=<%= preItemId %>" class="btn-cancel">取消</a>
                <% if (scope.canOffline) { %>
                    <button type="button" class="btn-offline" @click="offlineItem">
                        <i class="fa fa-trash-o"></i> 撤拍
                    </button>
                <% } %>
                <button type="submit" class="btn-publish" :disabled="submitting">
                    <i class="fa fa-save"></i>
                    {{ submitting ? '保存中...' : '保存修改' }}
                </button>
            </div>
        </form>
    </div>
</div>

<footer class="publish-footer">
    © 2025 二手物品拍卖系统 · Powered by JSP + Servlet + MyBatis + Vue
</footer>

<script src="<%=ctx%>/static/js/vue.global.prod.js"></script>
<script src="<%=ctx%>/static/js/axios.min.js"></script>
<script src="<%=ctx%>/static/js/common.js"></script>
<script>
    // 全局跳转
    function go(path) { window.location.href = path; }

    // 把 Java 端的 ctx（contextPath）暴露给 JS，供 axios/fetch 拼 URL 用
    const ctxPath = '<%=ctx%>';

    // ====== 服务端注入的数据（null-safe 处理）======
    const categories = <%= categoriesJson != null ? categoriesJson : "[]" %>;
    const pre = {
        categoryId:     <%= preCategoryId == null ? "null" : preCategoryId.toString() %>,
        title:          '<%= preTitle == null ? "" : preTitle.replace("'", "\\'") %>',
        description:    '<%= preDescription == null ? "" : preDescription.replace("'", "\\'").replace("\n", "\\n") %>',
        brand:          '<%= preBrand == null ? "" : preBrand.replace("'", "\\'") %>',
        model:          '<%= preModel == null ? "" : preModel.replace("'", "\\'") %>',
        conditionLevel: '<%= preConditionLevel == null ? "9成新" : preConditionLevel.replace("'", "\\'") %>',
        flawDesc:       '<%= preFlawDesc == null ? "" : preFlawDesc.replace("'", "\\'") %>',
        coverImage:     '<%= preCoverImage == null ? "" : preCoverImage.replace("'", "\\'") %>',
        imageUrls:      '<%= preImageUrls == null ? "" : preImageUrls.replace("'", "\\'") %>',
        startPrice:     <%= preStartPrice == null || preStartPrice.isEmpty() ? "0" : preStartPrice %>,
        bidIncrement:   <%= preBidIncrement == null || preBidIncrement.isEmpty() ? "1.00" : preBidIncrement %>,
        reservePrice:   <%= preReservePrice == null || preReservePrice.isEmpty() ? "null" : preReservePrice %>,
        startTime:      '<%= preStartTime == null ? "" : preStartTime.replace("'", "\\'") %>',
        endTime:        '<%= preEndTime == null ? "" : preEndTime.replace("'", "\\'") %>'
    };
    const serverError = '<%= error == null ? "" : error.replace("'", "\\'") %>';
    const DRAFT_KEY = 'publish_draft_v2';

    // ====== 安全启动 Vue（带错误捕获）======
    function bootVue() {
        if (!window.Vue) {
            console.error('[publish] Vue 全局对象未找到，请检查 vue.global.prod.js 是否加载成功');
            document.getElementById('app').innerHTML = '<div class="alert alert-error">Vue 加载失败，请刷新页面重试</div>';
            return;
        }
        try {
            const { createApp, ref, reactive, computed, watch } = Vue;
            createApp({
                setup() {
                    const categoriesRef = ref(Array.isArray(categories) ? categories : []);

                    // 尝试从 localStorage 恢复草稿（如果有的话，覆盖 pre）
                    let draftForm = null;
                    try {
                        const saved = localStorage.getItem(DRAFT_KEY);
                        if (saved) draftForm = JSON.parse(saved);
                    } catch (e) { /* localStorage 不可用，忽略 */ }
                    const init = (key, fallback) => {
                        if (draftForm && draftForm[key] !== undefined && draftForm[key] !== null && draftForm[key] !== '') {
                            return draftForm[key];
                        }
                        return fallback;
                    };

                    const form = reactive({
                        categoryId:     init('categoryId', pre.categoryId),
                        title:          init('title', pre.title || ''),
                        description:    init('description', pre.description || ''),
                        brand:          init('brand', pre.brand || ''),
                        model:          init('model', pre.model || ''),
                        conditionLevel: init('conditionLevel', pre.conditionLevel || '9成新'),
                        flawDesc:       init('flawDesc', pre.flawDesc || ''),
                        coverImage:     init('coverImage', pre.coverImage || ''),
                        imageUrls:      init('imageUrls', pre.imageUrls || ''),
                        startPrice:     init('startPrice', pre.startPrice || 0),
                        bidIncrement:   init('bidIncrement', pre.bidIncrement || 1),
                        reservePrice:   init('reservePrice', pre.reservePrice),
                        startTime:      init('startTime', pre.startTime || ''),
                        endTime:        init('endTime', pre.endTime || '')
                    });
                    const errors  = reactive({});
                    const touched = reactive({});
                    const submitting = ref(false);
                    const serverErrorRef = ref(serverError);
                    const draftSaved = ref(false);

                    // ============ 图片 URL 列表（从 form.imageUrls 解析）============
                    // 仅支持远程 URL（http:// 或 https://），每行一个
                    // 兼容：JSON 数组 / 换行 / 逗号 / 单条
                    const imageUrlList = computed(() => {
                        const raw = (form.imageUrls || '').trim();
                        if (!raw) return [];
                        // 优先按 JSON 数组解析（编辑模式从后端载入的格式）
                        if (raw.startsWith('[')) {
                            try {
                                const arr = JSON.parse(raw);
                                if (Array.isArray(arr)) {
                                    return arr.map(s => String(s).trim()).filter(Boolean).slice(0, 5);
                                }
                            } catch (e) { /* 不是 JSON，走下面 */ }
                        }
                        // 否则按换行 / 逗号分隔
                        return raw.split(/[\n,]/).map(s => s.trim()).filter(Boolean).slice(0, 5);
                    });

                    // 把当前 imageUrlList 序列化为 textarea 友好的格式（每行一个）
                    function syncImageUrlsToTextarea() {
                        form.imageUrls = imageUrlList.value.join('\n');
                    }

                    const topCategories = computed(() => (categoriesRef.value || []).filter(c => c && c.parentId === 0));
                    const childCategories = computed(() => (categoriesRef.value || []).filter(c => c && c.parentId !== 0));
                    function getChildren(parentId) {
                        return (categoriesRef.value || []).filter(c => c && c.parentId === parentId);
                    }

                    // 快捷时长：设置结束时间
                    function setEndTime(days) {
                        if (!form.startTime) {
                            // 没填开始时间，用现在 +1 分钟
                            const now = new Date();
                            now.setMinutes(now.getMinutes() + 1);
                            form.startTime = formatDateTimeLocal(now);
                        }
                        const start = new Date(form.startTime);
                        const end = new Date(start.getTime() + days * 24 * 60 * 60 * 1000);
                        form.endTime = formatDateTimeLocal(end);
                    }
                    function formatDateTimeLocal(d) {
                        const pad = n => String(n).padStart(2, '0');
                        return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate()) +
                               'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
                    }

                    // 图片加载失败
                    function onImgError(e) {
                        e.target.style.display = 'none';
                    }

                    // 草稿自动保存（防抖 1 秒）
                    let draftTimer = null;
                    watch(form, () => {
                        clearTimeout(draftTimer);
                        draftTimer = setTimeout(() => {
                            try {
                                localStorage.setItem(DRAFT_KEY, JSON.stringify(form));
                                draftSaved.value = true;
                                setTimeout(() => { draftSaved.value = false; }, 2000);
                            } catch (e) { /* 写入失败忽略 */ }
                        }, 1000);
                    }, { deep: true });

                    function validateField(field) {
                        let err = '';
                        switch (field) {
                            case 'categoryId':
                                if (!form.categoryId) err = '请选择分类'; break;
                            case 'title':
                                if (!form.title) err = '请填写标题';
                                else if (form.title.length < 5 || form.title.length > 100) err = '标题长度 5-100';
                                break;
                            case 'description':
                                if (!form.description) err = '请填写描述';
                                else if (form.description.length < 10) err = '描述至少 10 个字';
                                break;
                            case 'imageUrls':
                                if (imageUrlList.value.length === 0) {
                                    err = '至少填写 1 张图片 URL';
                                } else if (imageUrlList.value.length > 5) {
                                    err = '最多 5 张图片';
                                }
                                break;
                            case 'startPrice':
                                if (!form.startPrice || form.startPrice <= 0) err = '起拍价必须 > 0'; break;
                            case 'bidIncrement':
                                if (!form.bidIncrement || form.bidIncrement <= 0) err = '加价幅度必须 > 0'; break;
                            case 'startTime':
                                if (!form.startTime) err = '请选择开始时间'; break;
                            case 'endTime':
                                if (!form.endTime) err = '请选择结束时间';
                                else if (form.startTime && form.endTime <= form.startTime) err = '结束必须晚于开始';
                                break;
                        }
                        if (err) errors[field] = err; else delete errors[field];
                        return !err;
                    }

                    function handleSubmit(e) {
                        // 提交前把 imageUrlList 同步回 textarea（保证后端拿到的格式干净）
                        syncImageUrlsToTextarea();
                        const fields = ['categoryId','title','description','imageUrls','startPrice','bidIncrement','startTime','endTime'];
                        const failed = [];
                        fields.forEach(f => {
                            touched[f] = true;
                            if (!validateField(f)) failed.push({ field: f, msg: errors[f] || '未通过' });
                        });
                        if (failed.length > 0) {
                            const labels = {
                                categoryId: '分类', title: '标题', description: '描述',
                                imageUrls: '图片 URL', startPrice: '起拍价', bidIncrement: '加价幅度',
                                startTime: '开始时间', endTime: '结束时间'
                            };
                            const detail = failed.map(f => '· ' + (labels[f.field] || f.field) + '：' + f.msg).join('\n');
                            toast('请补全/修正以下字段：\n' + detail, 'error');
                            console.warn('[edit] 校验失败：', failed, '\n当前 form 状态：', JSON.parse(JSON.stringify(form)));
                            return;
                        }
                        submitting.value = true;
                        // 提交成功后清草稿
                        try { localStorage.removeItem(DRAFT_KEY); } catch (e) {}
                        e.target.submit();
                    }

                    return {
                        categories: categoriesRef, form, errors, touched, submitting,
                        serverError: serverErrorRef, draftSaved,
                        imageUrlList,
                        topCategories, getChildren,
                        setEndTime, onImgError,
                        validateField, handleSubmit,
                        // ============ 编辑专属 ============
                        editable: <%= scope != null ? "JSON.parse('" + new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(scope).replace("'", "\\'") + "')" : "null" %>,
                        offlineItem
                    };

                    async function offlineItem() {
                        if (!confirm('确定要撤拍吗？\\n撤拍后该拍品将立即下架，前台不再展示。')) return;
                        loadAxios().then(() => {
                            axios.post(ctxPath + '/item?action=offline&id=<%= preItemId %>')
                                .then(r => {
                                    if (r.data.success) {
                                        toast(r.data.message || '撤拍成功', 'success');
                                        setTimeout(() => location.href = ctxPath + '/item?action=detail&id=<%= preItemId %>', 800);
                                    } else {
                                        toast(r.data.message || '撤拍失败', 'error');
                                    }
                                })
                                .catch(() => toast('网络错误', 'error'));
                        });
                    }
                }
            }).mount('#app');
            console.log('[publish] Vue 挂载成功，分类数:', categories.length);
        } catch (err) {
            console.error('[publish] Vue 挂载失败:', err);
            document.getElementById('app').innerHTML = '<div class="alert alert-error">页面初始化失败：' + err.message + '<br>请按 F12 查看 Console 详情</div>';
        }
    }

    if (typeof loadVue === 'function') {
        loadVue().then(bootVue);
    } else if (window.Vue) {
        bootVue();
    } else {
        console.error('[publish] Vue 加载函数不存在，且 window.Vue 也未定义');
        document.getElementById('app').innerHTML = '<div class="alert alert-error">JS 加载异常，请刷新页面重试</div>';
    }
</script>
</body>
</html>
