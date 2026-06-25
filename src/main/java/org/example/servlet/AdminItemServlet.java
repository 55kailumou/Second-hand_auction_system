package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.AuctionItem;
import org.example.entity.Category;
import org.example.entity.User;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.CategoryMapper;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 - 拍品管理 Servlet
 *
 * URL 模式：/admin/item
 *   - GET  /admin/item?action=list&status=&category=&keyword=&page=  → 拍品列表（JSP，受 AdminAuthFilter 保护）
 *   - GET  /admin/item?action=detail&id=xx                              → 拍品详情（JSON）
 *   - POST /admin/item?action=set-status&id=&status=                  → 改状态（JSON）
 *   - POST /admin/item?action=set-category&id=&categoryId=            → 改分类（JSON）
 *   - POST /admin/item?action=remove&id=xx                            → 强制下架（status 改 4，JSON）
 *
 * 状态说明：
 *   0 待审核 1 拍卖中 2 已成交 3 已流拍 4 已下架 5 审核未通过
 *
 * 操作权限：
 *   - 任意状态都能改 status（admin 强制覆盖）
 *   - 任意状态都能改 category
 *   - "删除" = 强制下架（status=4），不真删（保护外键）
 */
@WebServlet("/admin/item")
public class AdminItemServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":
                showList(req, resp);
                break;
            case "detail":
                getDetail(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/admin/item?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "set-status":
                doSetStatus(req, resp);
                break;
            case "set-category":
                doSetCategory(req, resp);
                break;
            case "remove":
                doRemove(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 拍品列表 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        Integer status = parseIntOrNull(req.getParameter("status"));
        Integer categoryId = parseIntOrNull(req.getParameter("category"));
        String keyword = req.getParameter("keyword");
        int pageNo = 1;
        try { pageNo = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (pageNo < 1) pageNo = 1;
        int pageSize = 15;
        int offset = (pageNo - 1) * pageSize;

        List<Map<String, Object>> rows = new ArrayList<>();
        int total = 0;
        int activeCount = 0;
        int totalCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("status", status);
            params.put("categoryId", categoryId);
            params.put("keyword", keyword == null ? null : keyword.trim());
            params.put("sort", "newest");
            params.put("offset", offset);
            params.put("limit", pageSize);

            List<AuctionItem> items = itemMapper.findByCondition(params);
            total = itemMapper.countByCondition(params);

            // 统计：所有拍品数 / 拍卖中数（admin 概览用）
            Map<String, Object> allParams = new HashMap<>();
            totalCount = itemMapper.countByCondition(allParams);
            Map<String, Object> activeParams = new HashMap<>();
            activeParams.put("status", 1);
            activeCount = itemMapper.countByCondition(activeParams);

            for (AuctionItem item : items) {
                Category cat = item.getCategoryId() == null ? null : catMapper.findById(item.getCategoryId());
                User seller = userMapper.findById(item.getSellerId());

                Map<String, Object> row = new HashMap<>();
                row.put("id", item.getId());
                row.put("title", item.getTitle());
                row.put("coverImage", item.getCoverImage());
                row.put("categoryId", item.getCategoryId());
                row.put("categoryName", cat == null ? "未分类" : cat.getCategoryName());
                row.put("sellerId", item.getSellerId());
                row.put("sellerUsername", seller == null ? "用户#" + item.getSellerId() : seller.getUsername());
                row.put("currentPrice", item.getCurrentPrice());
                row.put("startPrice", item.getStartPrice());
                row.put("viewCount", item.getViewCount() == null ? 0 : item.getViewCount());
                row.put("status", item.getStatus());
                row.put("startTime", item.getStartTime());
                row.put("endTime", item.getEndTime());
                row.put("createTime", item.getCreateTime());
                rows.add(row);
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "拍品列表");
            req.setAttribute("error", "加载拍品列表失败，请稍后重试");
        }

        // 分类下拉
        List<Category> categories = new ArrayList<>();
        try (SqlSession session = MyBatisUtil.openSession()) {
            categories = session.getMapper(CategoryMapper.class).findAll();
        } catch (Exception e) {
            ResponseUtil.handleException(e, "分类列表");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("admin", admin);
        req.setAttribute("rowsJson", safeToJson(rows));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("status", status);
        req.setAttribute("categoryId", categoryId);
        req.setAttribute("keyword", keyword == null ? "" : keyword);
        req.setAttribute("totalCount", totalCount);
        req.setAttribute("activeCount", activeCount);
        req.setAttribute("categories", categories);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/items.jsp").forward(req, resp);
    }

    // ============ 拍品详情（JSON） ============

    private void getDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItem item = session.getMapper(AuctionItemMapper.class).findById(id);
            if (item == null) { writeJson(resp, errorOf("拍品不存在")); return; }
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("item", item);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "拍品详情"));
        }
    }

    // ============ 改状态 ============

    private void doSetStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer newStatus = parseIntOrNull(req.getParameter("status"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (newStatus == null || newStatus < 0 || newStatus > 5) {
            writeJson(resp, errorOf("status 必须为 0-5"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper mapper = session.getMapper(AuctionItemMapper.class);
            AuctionItem item = mapper.findById(id);
            if (item == null) { writeJson(resp, errorOf("拍品不存在")); return; }

            int oldStatus = item.getStatus() == null ? -1 : item.getStatus();
            int rows = mapper.updateStatus(id, newStatus);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "状态已从 " + statusText(oldStatus) + " 改为 " + statusText(newStatus));
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败，请稍后重试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "改状态"));
        }
    }

    // ============ 改分类 ============

    private void doSetCategory(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer categoryId = parseIntOrNull(req.getParameter("categoryId"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (categoryId == null) { writeJson(resp, errorOf("参数错误：缺少 categoryId")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);

            AuctionItem item = itemMapper.findById(id);
            if (item == null) { writeJson(resp, errorOf("拍品不存在")); return; }
            Category cat = catMapper.findById(categoryId);
            if (cat == null) { writeJson(resp, errorOf("目标分类不存在")); return; }

            int rows = itemMapper.updateCategoryByAdmin(id, categoryId);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "分类已改为 " + cat.getCategoryName());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "改分类"));
        }
    }

    // ============ 强制下架（改 status=4） ============

    private void doRemove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper mapper = session.getMapper(AuctionItemMapper.class);
            AuctionItem item = mapper.findById(id);
            if (item == null) { writeJson(resp, errorOf("拍品不存在")); return; }
            if (item.getStatus() != null && item.getStatus() == 4) {
                writeJson(resp, errorOf("此拍品已经是下架状态"));
                return;
            }

            int rows = mapper.updateStatus(id, 4);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "拍品已强制下架（status 改为 4）");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "强制下架"));
        }
    }

    // ============ 工具 ============

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String safeToJson(Object obj) {
        try { return JSON.writeValueAsString(obj); }
        catch (Exception e) { ResponseUtil.handleException(e, "JSON 序列化"); return "[]"; }
    }

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(JSON.writeValueAsString(obj));
        out.flush();
    }

    private Map<String, Object> errorOf(String msg) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", false);
        r.put("message", msg);
        return r;
    }

    private String statusText(int s) {
        switch (s) {
            case 0: return "待审核";
            case 1: return "拍卖中";
            case 2: return "已成交";
            case 3: return "已流拍";
            case 4: return "已下架";
            case 5: return "审核未通过";
            default: return "未知";
        }
    }
}
