package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.Category;
import org.example.entity.ItemImage;
import org.example.entity.User;
import org.example.entity.WatchList;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.mapper.CategoryMapper;
import org.example.mapper.ItemImageMapper;
import org.example.mapper.WatchListMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 拍品 Servlet：列表 / 详情 / 发布
 *
 * URL 模式：/item?action=xxx
 *   - GET  /item?action=list&page=&size=&category=&keyword=&sort=     → 拍品列表 JSP
 *   - GET  /item?action=detail&id=                                    → 拍品详情 JSP
 *   - GET  /item?action=publish-page                                  → 发布页 JSP（需登录）
 *   - POST /item?action=publish                                       → 提交发布（需登录）
 *
 * 关键约定：
 *   - Servlet 端用 ObjectMapper 把 List 转成 JSON 字符串塞到 request，
 *     JSP 里通过 ${itemsJson} 直接给 Vue 当数组用
 *   - Java 8 时间字段通过 JavaTimeModule + ISO 字符串输出，方便前端解析
 */
@WebServlet("/item")
public class ItemServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
            .disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":
                showList(req, resp);
                break;
            case "detail":
                showDetail(req, resp);
                break;
            case "publish-page":
                showPublishPage(req, resp);
                break;
            case "result":
                showResult(req, resp);
                break;
            case "edit-page":
                showEditPage(req, resp);
                break;
            case "my-items":
                showMyItems(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/item?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        switch (action == null ? "" : action) {
            case "publish":
                doPublish(req, resp);
                break;
            case "edit":
                doEdit(req, resp);
                break;
            case "offline":
                doOffline(req, resp);
                break;
            default:
                doGet(req, resp);
        }
    }

    // ===================== 1. 列表 =====================

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 解析参数
        int page = parseInt(req.getParameter("page"), 1);
        int size = parseInt(req.getParameter("size"), 12);
        if (page < 1) page = 1;
        if (size < 1 || size > 60) size = 12;

        Integer categoryId = parseIntOrNull(req.getParameter("category"));
        String keyword = trim(req.getParameter("keyword"));
        String sort = req.getParameter("sort");
        if (sort == null || sort.isEmpty()) sort = "newest";

        Map<String, Object> params = new HashMap<>();
        params.put("categoryId", categoryId);
        params.put("keyword", keyword);
        params.put("sort", sort);
        params.put("status", 1);                     // 列表只显示拍卖中的
        params.put("offset", (page - 1) * size);
        params.put("limit", size);

        List<AuctionItem> items;
        int total;
        List<Category> categories;
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);
            items = itemMapper.findByCondition(params);
            total = itemMapper.countByCondition(params);
            categories = catMapper.findAll();
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "拍品列表");
            items = new ArrayList<>();
            total = 0;
            categories = new ArrayList<>();
            req.setAttribute("error", "加载失败，请稍后重试");
        }

        int totalPages = (total + size - 1) / size;

        // 传给 JSP
        req.setAttribute("itemsJson", safeToJson(items));
        req.setAttribute("categoriesJson", safeToJson(categories));
        req.setAttribute("page", page);
        req.setAttribute("size", size);
        req.setAttribute("total", total);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("categoryId", categoryId);
        req.setAttribute("keyword", keyword == null ? "" : keyword);
        req.setAttribute("sort", sort);

        req.getRequestDispatcher("/WEB-INF/jsp/item/list.jsp").forward(req, resp);
    }

    // ===================== 2. 详情 =====================

    private void showDetail(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            resp.sendRedirect(req.getContextPath() + "/item?action=list");
            return;
        }

        AuctionItem item;
        List<BidRecord> bids;
        Category category;
        User seller;
        List<ItemImage> itemImages;  // 拍品图片（item_image 表）
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);
            ItemImageMapper imgMapper = session.getMapper(ItemImageMapper.class);

            item = itemMapper.findById(id);
            if (item == null) {
                resp.sendRedirect(req.getContextPath() + "/item?action=list");
                return;
            }
            // 浏览数 +1（需显式 commit，否则 MyBatis 默认 autoCommit=false，session 关闭时会 rollback）
            itemMapper.incrementViewCount(id);
            session.commit();
            item.setViewCount(item.getViewCount() == null ? 1 : item.getViewCount() + 1);

            bids = bidMapper.findByItemIdOrderByAmountDesc(id);
            category = catMapper.findById(item.getCategoryId());
            seller = session.getMapper(org.example.mapper.UserMapper.class).findById(item.getSellerId());

            // 优先从 item_image 表读图（已 bind 到拍品的图）；若为空，fallback 到 cover_image/image_urls 字段
            itemImages = imgMapper.findByItemId(id);
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "拍品详情");
            req.setAttribute("error", "加载详情失败，请稍后重试");
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
            return;
        }

        // 标记当前用户是否已登录、是否是卖家本人
        HttpSession session = req.getSession();
        User currentUser = (User) session.getAttribute("currentUser");
        boolean loggedIn = currentUser != null;
        boolean isOwner = loggedIn && currentUser.getId().equals(item.getSellerId());

        // 计算下一个最低出价
        BigDecimal nextMinBid = item.getCurrentPrice().add(item.getBidIncrement());

        // 拍卖是否进行中
        LocalDateTime now = LocalDateTime.now();
        boolean active = item.getStatus() != null
                && item.getStatus() == 1
                && item.getEndTime() != null
                && item.getEndTime().isAfter(now);

        req.setAttribute("itemJson", safeToJson(item));
        req.setAttribute("bidsJson", safeToJson(bids));
        req.setAttribute("categoryJson", safeToJson(category));
        req.setAttribute("sellerJson", safeToJson(seller));
        req.setAttribute("itemImagesJson", safeToJson(itemImages));
        req.setAttribute("loggedIn", loggedIn);
        req.setAttribute("isOwner", isOwner);
        req.setAttribute("active", active);
        req.setAttribute("nextMinBid", nextMinBid.toPlainString());

        // 收藏状态（仅登录用户才查；不能收藏自己发布的拍品）
        boolean favorited = false;
        if (loggedIn && !isOwner) {
            try (SqlSession favSession = MyBatisUtil.openSession()) {
                WatchList w = favSession.getMapper(WatchListMapper.class)
                        .findByUserAndItem(currentUser.getId(), id);
                favorited = w != null;
            } catch (Exception ignored) {
                // 查收藏失败不影响主流程
            }
        }
        req.setAttribute("favorited", favorited);

        req.getRequestDispatcher("/WEB-INF/jsp/item/detail.jsp").forward(req, resp);
    }

    // ===================== 3. 发布页 =====================

    private void showPublishPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 登录拦截（AuthFilter 已处理大部分，这里双保险）
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/item?action=publish-page", "UTF-8"));
            return;
        }

        List<Category> categories;
        try (SqlSession session = MyBatisUtil.openSession()) {
            categories = session.getMapper(CategoryMapper.class).findAll();
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "拍品发布页分类查询");
            categories = new ArrayList<>();
        }

        req.setAttribute("categoriesJson", safeToJson(categories));
        req.getRequestDispatcher("/WEB-INF/jsp/item/publish.jsp").forward(req, resp);
    }

    // ===================== 4. 发布提交 =====================

    private void doPublish(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            // 未登录跳登录页，登录后跳回当前 URL（含 query string）
            String back = req.getRequestURI();
            String query = req.getQueryString();
            if (query != null) back = back + "?" + query;
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode(back, "UTF-8"));
            return;
        }

        // 取表单
        Integer categoryId = parseIntOrNull(req.getParameter("categoryId"));
        String title = trim(req.getParameter("title"));
        String description = trim(req.getParameter("description"));
        String brand = trim(req.getParameter("brand"));
        String model = trim(req.getParameter("model"));
        String conditionLevel = trim(req.getParameter("conditionLevel"));
        String flawDesc = trim(req.getParameter("flawDesc"));
        String imageUrls = trim(req.getParameter("imageUrls"));
        BigDecimal startPrice = parseDecimal(req.getParameter("startPrice"));
        BigDecimal bidIncrement = parseDecimal(req.getParameter("bidIncrement"));
        BigDecimal reservePrice = parseDecimal(req.getParameter("reservePrice"));
        LocalDateTime startTime = parseDateTime(req.getParameter("startTime"));
        LocalDateTime endTime = parseDateTime(req.getParameter("endTime"));

        // 校验
        String error = validatePublish(categoryId, title, description, startPrice,
                bidIncrement, startTime, endTime);
        if (error != null) {
            failPublish(req, resp, error, categoryId, title, description, brand, model,
                    conditionLevel, flawDesc, imageUrls, startPrice,
                    bidIncrement, reservePrice, startTime, endTime);
            return;
        }

        // coverImage 由 syncItemImages 在解析 + 处理 URL 列表后填入（取第一张成功的图）
        AuctionItem item = new AuctionItem();
        item.setSellerId(user.getId());
        item.setCategoryId(categoryId);
        item.setTitle(title);
        item.setDescription(description);
        item.setBrand(brand);
        item.setModel(model);
        item.setConditionLevel(conditionLevel == null ? "9成新" : conditionLevel);
        item.setFlawDesc(flawDesc);
        item.setCoverImage(null);          // 后面由 syncItemImages 回填
        item.setImageUrls(imageUrls);      // 保留原始字符串便于编辑时回填
        item.setStartPrice(startPrice);
        item.setCurrentPrice(startPrice);  // 初始当前价 = 起拍价
        item.setBidIncrement(bidIncrement == null ? new BigDecimal("1.00") : bidIncrement);
        item.setReservePrice(reservePrice);
        item.setStartTime(startTime);
        item.setEndTime(endTime);
        item.setStatus(1);                 // 直接进入拍卖中（暂不接审核流）
        item.setViewCount(0);

        // 插入
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper mapper = session.getMapper(AuctionItemMapper.class);
            int rows = mapper.insert(item);
            if (rows > 0 && item.getId() != null) {
                // ============ 同步写入 item_image 表 + 回填 cover_image ============
                // 业务逻辑：imageUrls 是用户在 publish.jsp 提交的远程 URL 列表（每行一个）
                //   syncItemImages 只接受 http(s):// 远程 URL，原样写入 item_image 表
                //   第一条同时回填为拍品的 cover_image
                String coverUrl = syncItemImages(session, item.getId(), imageUrls);
                if (coverUrl != null) {
                    item.setCoverImage(coverUrl);
                    mapper.updateById(item);   // 把 cover_image 写回 auction_item
                }
                session.commit();

                resp.sendRedirect(req.getContextPath() + "/item?action=detail&id=" + item.getId());
                return;
            } else {
                failPublish(req, resp, "发布失败，请稍后再试", categoryId, title, description,
                        brand, model, conditionLevel, flawDesc, imageUrls,
                        startPrice, bidIncrement, reservePrice, startTime, endTime);
            }
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "发布拍品");
            failPublish(req, resp, "发布出错，请稍后重试", categoryId, title, description,
                    brand, model, conditionLevel, flawDesc, imageUrls,
                    startPrice, bidIncrement, reservePrice, startTime, endTime);
        }
    }

    /**
     * 把 imageUrls 字符串解析成 URL 列表，逐条写入 item_image 表
     * 兼容格式：JSON 数组 / 换行分隔 / 逗号分隔 / 单条 URL
     *
     * 策略：仅支持远程 URL（http:// 或 https://），不下载不存储。
     *       第一条作为 cover_image 返回。
     */
    private String syncItemImages(SqlSession session, Integer itemId, String imageUrls) {
        if (imageUrls == null || imageUrls.trim().isEmpty()) return null;
        ItemImageMapper imgMapper = session.getMapper(ItemImageMapper.class);

        List<String> urls = parseImageUrls(imageUrls);
        if (urls.isEmpty()) return null;

        int order = 0;
        String firstUrl = null;
        for (String url : urls) {
            if (url == null) continue;
            url = url.trim();
            if (url.isEmpty()) continue;
            // 仅接受 http(s):// 远程 URL
            if (!(url.startsWith("http://") || url.startsWith("https://"))) {
                System.out.println("[syncItemImages] 跳过非远程 URL: " + url);
                continue;
            }

            ItemImage img = new ItemImage(itemId, url, order++);
            imgMapper.insert(img);
            if (firstUrl == null) firstUrl = url;
        }
        session.commit();
        return firstUrl;
    }

    /**
     * 解析图片 URL 字符串为列表
     * 兼容：JSON 数组 ['a','b'] / 换行 a\nb / 逗号 a,b / 单条 a
     */
    private List<String> parseImageUrls(String raw) {
        if (raw == null) return Collections.emptyList();
        String s = raw.trim();
        if (s.isEmpty()) return Collections.emptyList();

        // 尝试 JSON 解析
        if (s.startsWith("[")) {
            try {
                ObjectMapper om = new ObjectMapper();
                String[] arr = om.readValue(s, String[].class);
                return Arrays.asList(arr);
            } catch (Exception ignored) {
                // 不是合法 JSON，走下面分隔符方案
            }
        }

        // 换行 / 逗号 分隔
        List<String> out = new ArrayList<>();
        for (String part : s.split("[\\n,]")) {
            String t = part.trim();
            if (!t.isEmpty()) out.add(t);
        }
        return out;
    }

    private String validatePublish(Integer categoryId, String title, String description,
                                   BigDecimal startPrice, BigDecimal bidIncrement,
                                   LocalDateTime startTime, LocalDateTime endTime) {
        if (categoryId == null) return "请选择分类";
        if (title == null || title.length() < 5 || title.length() > 100) return "标题长度必须 5-100";
        if (description == null || description.length() < 10) return "描述至少 10 个字";
        if (startPrice == null || startPrice.compareTo(BigDecimal.ZERO) <= 0) return "起拍价必须大于 0";
        if (bidIncrement != null && bidIncrement.compareTo(BigDecimal.ZERO) <= 0) return "加价幅度必须大于 0";
        if (startTime == null) return "请填写拍卖开始时间";
        if (endTime == null) return "请填写拍卖结束时间";
        if (!endTime.isAfter(startTime)) return "结束时间必须晚于开始时间";
        return null;
    }

    private void failPublish(HttpServletRequest req, HttpServletResponse resp, String msg,
                             Integer categoryId, String title, String description, String brand,
                             String model, String conditionLevel, String flawDesc,
                             String imageUrls, BigDecimal startPrice, BigDecimal bidIncrement,
                             BigDecimal reservePrice, LocalDateTime startTime, LocalDateTime endTime)
            throws ServletException, IOException {
        req.setAttribute("error", msg);
        req.setAttribute("preCategoryId", categoryId);
        req.setAttribute("preTitle", title);
        req.setAttribute("preDescription", description);
        req.setAttribute("preBrand", brand);
        req.setAttribute("preModel", model);
        req.setAttribute("preConditionLevel", conditionLevel);
        req.setAttribute("preFlawDesc", flawDesc);
        req.setAttribute("preImageUrls", imageUrls);
        req.setAttribute("preStartPrice", startPrice == null ? "" : startPrice.toPlainString());
        req.setAttribute("preBidIncrement", bidIncrement == null ? "" : bidIncrement.toPlainString());
        req.setAttribute("preReservePrice", reservePrice == null ? "" : reservePrice.toPlainString());
        req.setAttribute("preStartTime", startTime == null ? "" :
                startTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")));
        req.setAttribute("preEndTime", endTime == null ? "" :
                endTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm")));
        // 重新加载分类
        List<Category> categories;
        try (SqlSession session = MyBatisUtil.openSession()) {
            categories = session.getMapper(CategoryMapper.class).findAll();
        } catch (Exception e) {
            categories = new ArrayList<>();
        }
        req.setAttribute("categoriesJson", safeToJson(categories));
        req.getRequestDispatcher("/WEB-INF/jsp/item/publish.jsp").forward(req, resp);
    }

    // ===================== 4. 拍卖结果页 =====================

    private void showResult(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            resp.sendRedirect(req.getContextPath() + "/item?action=list");
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            org.example.mapper.UserMapper userMapper = session.getMapper(org.example.mapper.UserMapper.class);

            AuctionItem item = itemMapper.findById(id);
            if (item == null) {
                req.setAttribute("error", "拍品不存在");
                req.getRequestDispatcher("/WEB-INF/jsp/item/result.jsp").forward(req, resp);
                return;
            }

            String resultType;
            org.example.entity.BidRecord winner = null;
            org.example.entity.User winnerUser = null;
            int bidCount = 0;

            Integer status = item.getStatus();
            if (status != null && status == 2) {
                // 已成交
                resultType = "sold";
                winner = bidMapper.findCurrentWinning(id);
                if (winner != null) {
                    winnerUser = userMapper.findById(winner.getBidderId());
                    bidCount = bidMapper.findByItemIdOrderByAmountDesc(id).size();
                }
            } else if (status != null && status == 3) {
                // 已流拍
                resultType = "failed";
            } else {
                resultType = "unknown";
            }

            // 结果页图片 URL 拼 contextPath
            req.setAttribute("item", item);
            req.setAttribute("winner", winner);
            req.setAttribute("winnerUser", winnerUser);
            req.setAttribute("bidCount", bidCount);
            req.setAttribute("resultType", resultType);
            req.getRequestDispatcher("/WEB-INF/jsp/item/result.jsp").forward(req, resp);

        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "拍品结果");
            req.setAttribute("error", "加载失败，请稍后重试");
            req.getRequestDispatcher("/WEB-INF/jsp/item/result.jsp").forward(req, resp);
        }
    }

    // ===================== 4.5 我发布的拍品（个人中心） =====================

    /**
     * 我发布的拍品列表：所有状态（待审核/拍卖中/已成交/已流拍/已下架/审核未通过）
     * 列表项含编辑/撤拍按钮，按状态联动
     */
    private void showMyItems(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/item?action=my-items", "UTF-8"));
            return;
        }

        List<AuctionItem> items;
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper mapper = session.getMapper(AuctionItemMapper.class);
            // 用 findByCondition 配合 sellerId（不限状态）
            Map<String, Object> params = new HashMap<>();
            params.put("sellerId", user.getId());
            params.put("offset", 0);
            params.put("limit", 100);
            params.put("sort", "newest");
            items = mapper.findByCondition(params);
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "我发布的拍品");
            items = new ArrayList<>();
            req.setAttribute("error", "加载失败，请稍后重试");
        }

        // 缩略图 URL 拼 contextPath
        req.setAttribute("itemsJson", safeToJson(items));
        req.getRequestDispatcher("/WEB-INF/jsp/item/my_items.jsp").forward(req, resp);
    }

    // ===================== 5. 编辑页 =====================

    /**
     * 卖家编辑页：加载已有拍品 + 计算当前可编辑范围
     *
     * 可编辑规则（方案 2）：
     *   - 0 待审核              → 全字段可改（价格时间也能改）
     *   - 5 审核未通过          → 全字段可改（修正后重新审核）
     *   - 1 拍卖中（未开始）    → 全字段可改
     *   - 1 拍卖中（已开始）    → 只可改描述/瑕疵/封面/多图（描述图等"软信息"）
     *   - 2 已成交 / 3 已流拍 / 4 已下架 → 禁止编辑（只能查看）
     */
    private void showEditPage(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        // 登录校验
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            String back = req.getRequestURI() + "?" + (req.getQueryString() == null ? "" : req.getQueryString());
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode(back, "UTF-8"));
            return;
        }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            resp.sendRedirect(req.getContextPath() + "/item?action=list");
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            AuctionItem item = itemMapper.findById(id);
            if (item == null) {
                resp.sendRedirect(req.getContextPath() + "/item?action=list");
                return;
            }

            // 必须是卖家本人
            if (!user.getId().equals(item.getSellerId())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "只能编辑自己的拍品");
                return;
            }

            // 加载分类列表
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);
            List<Category> categories = catMapper.findAll();

            // 计算可编辑范围
            EditableScope scope = computeEditableScope(item);

            req.setAttribute("item", item);
            req.setAttribute("itemJson", safeToJson(item));
            req.setAttribute("categoriesJson", safeToJson(categories));
            req.setAttribute("editable", scope);  // 传给 JSP 的可编辑范围
            req.getRequestDispatcher("/WEB-INF/jsp/item/edit.jsp").forward(req, resp);
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "编辑页加载");
            req.setAttribute("error", "加载失败，请稍后重试");
            req.getRequestDispatcher("/WEB-INF/jsp/error.jsp").forward(req, resp);
        }
    }

    /**
     * 计算当前拍品的可编辑范围
     *
     * @return EditableScope 各字段是否可改 + 提示文案
     */
    private EditableScope computeEditableScope(AuctionItem item) {
        EditableScope scope = new EditableScope();
        int status = item.getStatus() == null ? -1 : item.getStatus();
        LocalDateTime now = LocalDateTime.now();
        boolean notStarted = item.getStartTime() != null && item.getStartTime().isAfter(now);
        boolean bidding = (status == 1) && !notStarted;

        // 是否允许进入编辑页（任何非"成交/流拍/下架"状态都能进）
        boolean canEnter = (status == 0) || (status == 5) || (status == 1) || (status == 4);
        scope.canEnter = canEnter;
        scope.reason = canEnter ? "" : "该状态不允许编辑";

        // 软信息（标题/描述/品牌/型号/新旧/瑕疵/封面/多图）：永远可改（除非已成交/流拍）
        scope.editableSoftFields = canEnter && status != 2 && status != 3;

        // 硬信息（价格/时间/分类）：仅待审核/未开始/审核未通过 时可改
        scope.editableHardFields = (status == 0) || (status == 5) || (status == 1 && notStarted);

        // 是否可撤拍
        //   0 待审核 → 可撤
        //   5 审核未通过 → 可撤
        //   1 未开始 → 可撤
        //   1 已开始（bidding） → 不可撤（保护已出价者）
        //   2 已成交 → 不可撤（走订单）
        //   3 已流拍 → 不可撤（拍卖已结束）
        //   4 已下架 → 已下架
        scope.canOffline = (status == 0) || (status == 5) || (status == 1 && notStarted);
        scope.bidding = bidding;
        return scope;
    }

    /**
     * 可编辑范围 DTO（前后端约定）
     */
    public static class EditableScope {
        public boolean canEnter;            // 是否允许进入编辑页
        public String  reason;              // 不可进入的原因（前端提示）
        public boolean editableSoftFields;  // 描述/图/品牌/型号等可改
        public boolean editableHardFields;  // 价格/时间/分类可改
        public boolean canOffline;          // 是否可撤拍
        public boolean bidding;             // 是否已开始拍卖（前端红色提示用）
    }

    // ===================== 6. 提交编辑 =====================

    private void doEdit(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login");
            return;
        }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            resp.sendRedirect(req.getContextPath() + "/item?action=list");
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper mapper = session.getMapper(AuctionItemMapper.class);
            AuctionItem origin = mapper.findById(id);
            if (origin == null) {
                resp.sendRedirect(req.getContextPath() + "/item?action=list");
                return;
            }
            // 卖家本人校验
            if (!user.getId().equals(origin.getSellerId())) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "只能编辑自己的拍品");
                return;
            }

            // 重算可编辑范围（防止绕过前端）
            EditableScope scope = computeEditableScope(origin);
            if (!scope.canEnter) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, scope.reason);
                return;
            }

            // 取表单
            Integer categoryId   = parseIntOrNull(req.getParameter("categoryId"));
            String  title        = trim(req.getParameter("title"));
            String  description  = trim(req.getParameter("description"));
            String  brand        = trim(req.getParameter("brand"));
            String  model        = trim(req.getParameter("model"));
            String  conditionLevel = trim(req.getParameter("conditionLevel"));
            String  flawDesc     = trim(req.getParameter("flawDesc"));
            String  imageUrls    = trim(req.getParameter("imageUrls"));
            BigDecimal startPrice   = parseDecimal(req.getParameter("startPrice"));
            BigDecimal bidIncrement  = parseDecimal(req.getParameter("bidIncrement"));
            BigDecimal reservePrice = parseDecimal(req.getParameter("reservePrice"));
            LocalDateTime startTime  = parseDateTime(req.getParameter("startTime"));
            LocalDateTime endTime    = parseDateTime(req.getParameter("endTime"));

            // 校验（按状态区分）
            String error = validateEdit(scope, title, description, startPrice, startTime, endTime);
            if (error != null) {
                failEdit(req, resp, error, origin, categoryId, title, description, brand, model,
                        conditionLevel, flawDesc, imageUrls, startPrice,
                        bidIncrement, reservePrice, startTime, endTime, scope);
                return;
            }

            // 根据 scope 决定调用哪个 update
            // cover_image 不在表单里读，由 syncItemImages 解析 imageUrls 后回填（取第一条）
            // 但 updateEditableFieldsByOwner / updateAllFieldsByOwner 的 SQL 都包含 cover_image 字段，
            // update 对象必须先保留原值，否则会被写成 null
            AuctionItem update = new AuctionItem();
            update.setId(id);
            update.setSellerId(user.getId());
            update.setCoverImage(origin.getCoverImage());   // 关键：先保留原值
            update.setTitle(title);
            update.setDescription(description);
            update.setBrand(brand);
            update.setModel(model);
            update.setConditionLevel(conditionLevel);
            update.setFlawDesc(flawDesc);
            update.setImageUrls(imageUrls);

            int rows;
            if (scope.editableHardFields) {
                // 全字段更新（含价格时间）
                update.setCategoryId(categoryId);
                update.setStartPrice(startPrice);
                update.setBidIncrement(bidIncrement == null ? new BigDecimal("1.00") : bidIncrement);
                update.setReservePrice(reservePrice);
                update.setStartTime(startTime);
                update.setEndTime(endTime);
                rows = mapper.updateAllFieldsByOwner(update);
            } else {
                // 只更新软字段
                rows = mapper.updateEditableFieldsByOwner(update);
            }
            session.commit();

            // 同步更新 item_image 表（保留已绑定的图，未上传的新图也写进去）
            // 第一条远程 URL 同步回拍品的 cover_image 字段
            if (imageUrls != null) {
                String newCover = syncItemImages(session, id, imageUrls);
                if (newCover != null) {
                    update.setCoverImage(newCover);
                    mapper.updateById(update);
                }
            }

            if (rows > 0) {
                resp.sendRedirect(req.getContextPath() + "/item?action=detail&id=" + id);
            } else {
                failEdit(req, resp, "更新失败，请稍后再试", origin, categoryId, title, description,
                        brand, model, conditionLevel, flawDesc, imageUrls,
                        startPrice, bidIncrement, reservePrice, startTime, endTime, scope);
            }
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "编辑拍品");
            resp.sendRedirect(req.getContextPath() + "/item?action=list");
        }
    }

    private String validateEdit(EditableScope scope, String title, String description,
                                BigDecimal startPrice, LocalDateTime startTime, LocalDateTime endTime) {
        // 软字段校验（任何可编辑情况都要校验）
        if (title == null || title.length() < 5 || title.length() > 100) return "标题长度必须 5-100";
        if (description == null || description.length() < 10) return "描述至少 10 个字";

        // 硬字段校验（仅当允许改时校验）
        if (scope.editableHardFields) {
            if (startPrice == null || startPrice.compareTo(BigDecimal.ZERO) <= 0) return "起拍价必须大于 0";
            if (startTime == null) return "请填写拍卖开始时间";
            if (endTime == null) return "请填写拍卖结束时间";
            if (!endTime.isAfter(startTime)) return "结束时间必须晚于开始时间";
        }
        return null;
    }

    private void failEdit(HttpServletRequest req, HttpServletResponse resp, String msg,
                          AuctionItem origin, Integer categoryId, String title, String description,
                          String brand, String model, String conditionLevel, String flawDesc,
                          String imageUrls, BigDecimal startPrice,
                          BigDecimal bidIncrement, BigDecimal reservePrice,
                          LocalDateTime startTime, LocalDateTime endTime, EditableScope scope)
            throws ServletException, IOException {
        req.setAttribute("error", msg);
        req.setAttribute("item", origin);
        req.setAttribute("itemJson", safeToJson(origin));
        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);
            req.setAttribute("categoriesJson", safeToJson(catMapper.findAll()));
        } catch (Exception ignored) {}
        req.setAttribute("editable", scope);
        // 把用户修改的值回填（优先级高于 origin）
        // 简化处理：直接用 origin + 部分覆盖
        // 实际上表单数据浏览器会自己保留，这里主要是显示错误
        req.getRequestDispatcher("/WEB-INF/jsp/item/edit.jsp").forward(req, resp);
    }

    // ===================== 7. 撤拍 =====================

    private void doOffline(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            writeJson(resp, java.util.Map.of("success", false, "message", "请先登录"));
            return;
        }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) {
            writeJson(resp, java.util.Map.of("success", false, "message", "缺少参数 id"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper mapper = session.getMapper(AuctionItemMapper.class);
            AuctionItem item = mapper.findById(id);
            if (item == null) {
                writeJson(resp, java.util.Map.of("success", false, "message", "拍品不存在"));
                return;
            }
            if (!user.getId().equals(item.getSellerId())) {
                writeJson(resp, java.util.Map.of("success", false, "message", "只能撤自己的拍品"));
                return;
            }

            // 校验：是否允许撤拍（按业务规则）
            EditableScope scope = computeEditableScope(item);
            if (!scope.canOffline) {
                String reason = "已开始拍卖（有人出价中）的拍品不能撤拍";
                if (item.getStatus() != null && item.getStatus() == 2) reason = "已成交的拍品不能撤拍（请走订单退款流程）";
                else if (item.getStatus() != null && item.getStatus() == 3) reason = "已流拍的拍品不能撤拍";
                else if (item.getStatus() != null && item.getStatus() == 4) reason = "该拍品已下架";
                writeJson(resp, java.util.Map.of("success", false, "message", reason));
                return;
            }

            // status → 4 已下架
            int rows = mapper.updateStatus(id, 4);
            session.commit();

            if (rows > 0) {
                writeJson(resp, java.util.Map.of("success", true, "message", "撤拍成功", "itemId", id));
            } else {
                writeJson(resp, java.util.Map.of("success", false, "message", "撤拍失败，请稍后重试"));
            }
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "撤拍");
            writeJson(resp, java.util.Map.of("success", false, "message", "撤拍失败，请稍后重试"));
        }
    }

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print(JSON.writeValueAsString(obj));
        resp.getWriter().flush();
    }

    // ===================== 工具 =====================

    private String safeToJson(Object obj) {
        try {
            return JSON.writeValueAsString(obj);
        } catch (Exception e) {
            org.example.util.ResponseUtil.handleException(e, "JSON 序列化");
            return "[]";
        }
    }

    private int parseInt(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; }
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private BigDecimal parseDecimal(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return new BigDecimal(s.trim()); } catch (Exception e) { return null; }
    }

    private LocalDateTime parseDateTime(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        String t = s.trim().replace(' ', 'T');
        try { return LocalDateTime.parse(t); } catch (Exception e) { return null; }
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
    }
}
