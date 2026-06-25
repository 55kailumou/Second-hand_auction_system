package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.User;
import org.example.entity.WatchList;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.WatchListMapper;
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
 * 收藏关注 Servlet
 *
 * URL 模式：/favorite?action=xxx
 *   - GET  /favorite?action=list            → 我的收藏列表（JSP）
 *   - POST /favorite?action=toggle&itemId=xx → 切换收藏状态（已收藏→取消；未收藏→收藏；JSON）
 *   - POST /favorite?action=delete&id=xx     → 取消收藏（收藏列表页用；JSON）
 *   - POST /favorite?action=add&itemId=xx    → 加入收藏（备选，一般走 toggle）
 *
 * 业务约定：
 *   - 同一用户对同一拍品只能收藏一次，靠 DB 唯一索引 (user_id, item_id) 保证
 *   - 取消拍卖中拍品的收藏：只删 watch_list 行，不动 auction_item
 *   - 收藏拍品下架/删除：保留收藏记录（前端展示时拍品为"已下架"灰色状态）
 */
@WebServlet("/favorite")
public class WatchListServlet extends HttpServlet {

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
            default:
                resp.sendRedirect(req.getContextPath() + "/favorite?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "toggle":
                doToggle(req, resp);
                break;
            case "delete":
                doRemove(req, resp);
                break;
            case "add":
                doAdd(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 页面渲染 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/favorite?action=list", "UTF-8"));
            return;
        }

        int page = 1;
        try { page = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (page < 1) page = 1;
        int pageSize = 12;
        int offset = (page - 1) * pageSize;

        List<Map<String, Object>> favoriteItems = new ArrayList<>();
        int total = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            WatchListMapper favMapper = session.getMapper(WatchListMapper.class);
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);

            // 1. 查所有收藏记录
            List<WatchList> favorites = favMapper.findByUserId(user.getId());
            total = favorites.size();

            // 2. 分页（先在内存里截，再 join 拍品详情）
            int end = Math.min(offset + pageSize, total);
            for (int i = offset; i < end; i++) {
                WatchList f = favorites.get(i);
                AuctionItem item = itemMapper.findById(f.getItemId());
                if (item == null) continue;     // 拍品已被硬删除，跳过

                Map<String, Object> row = new HashMap<>();
                row.put("favoriteId", f.getId());
                row.put("itemId", item.getId());
                row.put("title", item.getTitle());
                row.put("coverImage", item.getCoverImage());
                row.put("currentPrice", item.getCurrentPrice());
                row.put("startPrice", item.getStartPrice());
                row.put("endTime", item.getEndTime());
                row.put("status", item.getStatus());
                row.put("viewCount", item.getViewCount());
                row.put("addTime", f.getAddTime());
                favoriteItems.add(row);
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "收藏列表");
            req.setAttribute("error", "加载收藏列表失败，请稍后重试");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("favoriteItems", favoriteItems);
        req.setAttribute("total", total);
        req.setAttribute("page", page);
        req.setAttribute("pageSize", pageSize);
        req.setAttribute("totalPages", totalPages);
        req.getRequestDispatcher("/WEB-INF/jsp/favorite/list.jsp").forward(req, resp);
    }

    // ============ 切换收藏状态（详情页❤️按钮用） ============

    private void doToggle(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        if (itemId == null) { writeJson(resp, errorOf("参数错误：缺少 itemId")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            WatchListMapper mapper = session.getMapper(WatchListMapper.class);
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);

            // 拍品必须存在
            AuctionItem item = itemMapper.findById(itemId);
            if (item == null) { writeJson(resp, errorOf("拍品不存在")); return; }

            // 不能收藏自己的拍品
            if (item.getSellerId().equals(user.getId())) {
                writeJson(resp, errorOf("不能收藏自己发布的拍品"));
                return;
            }

            // 查是否已收藏
            WatchList existing = mapper.findByUserAndItem(user.getId(), itemId);
            boolean nowFavorited;
            if (existing != null) {
                // 已收藏 → 取消
                mapper.deleteById(existing.getId());
                nowFavorited = false;
            } else {
                // 未收藏 → 收藏
                WatchList w = new WatchList();
                w.setUserId(user.getId());
                w.setItemId(itemId);
                mapper.insert(w);
                nowFavorited = true;
            }
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("favorited", nowFavorited);
            data.put("message", nowFavorited ? "已加入收藏" : "已取消收藏");
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "切换收藏状态"));
        }
    }

    // ============ 单条删除（收藏列表页用） ============

    private void doRemove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            WatchListMapper mapper = session.getMapper(WatchListMapper.class);
            WatchList w = mapper.findById(id);
            if (w == null) { writeJson(resp, errorOf("收藏记录不存在")); return; }
            if (!w.getUserId().equals(user.getId())) {
                writeJson(resp, errorOf("无权操作此收藏"));
                return;
            }
            int rows = mapper.deleteById(id);
            session.commit();
            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "已取消收藏");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("取消失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "取消收藏"));
        }
    }

    // ============ 直接添加（备选接口，toggle 为主） ============

    private void doAdd(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        if (itemId == null) { writeJson(resp, errorOf("参数错误：缺少 itemId")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            WatchListMapper mapper = session.getMapper(WatchListMapper.class);

            WatchList existing = mapper.findByUserAndItem(user.getId(), itemId);
            if (existing != null) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("favorited", true);
                data.put("message", "已在收藏中");
                writeJson(resp, data);
                return;
            }

            WatchList w = new WatchList();
            w.setUserId(user.getId());
            w.setItemId(itemId);
            mapper.insert(w);
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("favorited", true);
            data.put("message", "已加入收藏");
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "添加收藏"));
        }
    }

    // ============ 工具方法 ============

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

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }
}
