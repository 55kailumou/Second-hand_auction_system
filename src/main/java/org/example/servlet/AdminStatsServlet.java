package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.mapper.StatsMapper;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 - 数据统计 Servlet
 *
 * URL 模式：/admin/stats
 *   - GET /admin/stats                  → 转发到 stats.jsp（受 AdminAuthFilter 保护）
 *   - GET /admin/stats?action=overview  → 返回全部统计数据（JSON）
 *
 * 设计要点：
 *   - JSP 用 Vue + Chart.js 渲染，一次性拉全部数据后按需渲染
 *   - 趋势统计固定 30 天（无需 query 参数；如需切换可加 ?days=7/30/90）
 *   - 拍品分类分布只取 Top 10（避免柱状图过于细长）
 *   - 热门拍品 Top 10 按 view_count 降序
 */
@WebServlet("/admin/stats")
public class AdminStatsServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    /** 拍品状态中文映射（auction_item.status 0~5） */
    private static final Map<Integer, String> ITEM_STATUS_NAME = new LinkedHashMap<>();
    static {
        ITEM_STATUS_NAME.put(0, "待审核");
        ITEM_STATUS_NAME.put(1, "拍卖中");
        ITEM_STATUS_NAME.put(2, "已成交");
        ITEM_STATUS_NAME.put(3, "已流拍");
        ITEM_STATUS_NAME.put(4, "已下架");
        ITEM_STATUS_NAME.put(5, "审核未通过");
    }

    /** 订单状态中文映射（order_info.status 0~6） */
    private static final Map<Integer, String> ORDER_STATUS_NAME = new LinkedHashMap<>();
    static {
        ORDER_STATUS_NAME.put(0, "待付款");
        ORDER_STATUS_NAME.put(1, "已付款");
        ORDER_STATUS_NAME.put(2, "已发货");
        ORDER_STATUS_NAME.put(3, "已收货");
        ORDER_STATUS_NAME.put(4, "退款中");
        ORDER_STATUS_NAME.put(5, "已退款");
        ORDER_STATUS_NAME.put(6, "已取消");
    }

    /** 拍品状态配色（与 Chart.js 调色板保持风格统一） */
    private static final Map<Integer, String> ITEM_STATUS_COLOR = new LinkedHashMap<>();
    static {
        ITEM_STATUS_COLOR.put(0, "#fbbf24");  // 黄 - 待审核
        ITEM_STATUS_COLOR.put(1, "#3b82f6");  // 蓝 - 拍卖中
        ITEM_STATUS_COLOR.put(2, "#10b981");  // 绿 - 已成交
        ITEM_STATUS_COLOR.put(3, "#9ca3af");  // 灰 - 已流拍
        ITEM_STATUS_COLOR.put(4, "#6b7280");  // 深灰 - 已下架
        ITEM_STATUS_COLOR.put(5, "#ef4444");  // 红 - 审核未通过
    }

    private static final Map<Integer, String> ORDER_STATUS_COLOR = new LinkedHashMap<>();
    static {
        ORDER_STATUS_COLOR.put(0, "#fbbf24");  // 黄
        ORDER_STATUS_COLOR.put(1, "#3b82f6");  // 蓝
        ORDER_STATUS_COLOR.put(2, "#8b5cf6");  // 紫
        ORDER_STATUS_COLOR.put(3, "#10b981");  // 绿
        ORDER_STATUS_COLOR.put(4, "#f97316");  // 橙
        ORDER_STATUS_COLOR.put(5, "#ef4444");  // 红
        ORDER_STATUS_COLOR.put(6, "#9ca3af");  // 灰
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "page";

        switch (action) {
            case "page":
                showPage(req, resp, admin);
                break;
            case "overview":
                getOverview(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/admin/stats");
        }
    }

    /** 渲染统计页（JSP） */
    private void showPage(HttpServletRequest req, HttpServletResponse resp, Admin admin) throws ServletException, IOException {
        req.setAttribute("admin", admin);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/stats.jsp").forward(req, resp);
    }

    /** 返回全部统计数据（JSON 格式） */
    private void getOverview(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int trendDays = 30;
        try {
            String d = req.getParameter("days");
            if (d != null && !d.isEmpty()) trendDays = Integer.parseInt(d);
            if (trendDays < 7) trendDays = 7;
            if (trendDays > 90) trendDays = 90;
        } catch (Exception ignored) {}

        Map<String, Object> data = new LinkedHashMap<>();
        try (SqlSession session = MyBatisUtil.openSession()) {
            StatsMapper mapper = session.getMapper(StatsMapper.class);

            // 1. KPI 总览
            Map<String, Object> overview = mapper.getOverview(trendDays);
            // 统一转 number（MySQL SUM/COUNT 在 MyBatis 默认是 BigDecimal/Long）
            overview.put("userCount", toInt(overview.get("userCount")));
            overview.put("itemCount", toInt(overview.get("itemCount")));
            overview.put("completedOrderCount", toInt(overview.get("completedOrderCount")));
            overview.put("totalOrderCount", toInt(overview.get("totalOrderCount")));
            overview.put("totalBidCount", toInt(overview.get("totalBidCount")));
            overview.put("activeItemCount", toInt(overview.get("activeItemCount")));
            overview.put("pendingRefundCount", toInt(overview.get("pendingRefundCount")));
            overview.put("gmv", toDouble(overview.get("gmv")));
            data.put("overview", overview);

            // 2. 用户增长趋势
            data.put("userTrend", fillMissingDates(mapper.userTrend(trendDays), trendDays));

            // 3. 拍品状态分布（补全所有状态，0 也要显示）
            data.put("itemStatus", enrichStatusDistribution(
                    mapper.itemStatusDistribution(), ITEM_STATUS_NAME, ITEM_STATUS_COLOR));

            // 4. 拍品分类分布 Top 10
            data.put("categoryDistribution", mapper.categoryDistribution(10));

            // 5. 订单趋势
            data.put("orderTrend", fillMissingDatesWithAmount(mapper.orderTrend(trendDays), trendDays));

            // 6. 订单状态分布（补全所有状态）
            data.put("orderStatus", enrichStatusDistribution(
                    mapper.orderStatusDistribution(), ORDER_STATUS_NAME, ORDER_STATUS_COLOR));

            // 7. 热门拍品 Top 10
            data.put("topItems", mapper.topItemsByViews(10));

            // 8. 趋势天数（前端展示用）
            data.put("trendDays", trendDays);

            writeJson(resp, ResponseUtil.successOf(data));
        } catch (Exception e) {
            ResponseUtil.handleException(e, "数据统计");
            writeJson(resp, ResponseUtil.errorOf("加载统计数据失败，请稍后重试"));
        }
    }

    /**
     * 补全缺失日期：返回的 Map 中某天没有数据，前端折线图就会断线
     * 这里生成 [today - N + 1, today] 完整日期序列，无数据的填 0
     */
    private List<Map<String, Object>> fillMissingDates(List<Map<String, Object>> raw, int days) {
        Map<String, Long> dateCount = new LinkedHashMap<>();
        for (Map<String, Object> row : raw) {
            dateCount.put(String.valueOf(row.get("date")), toLong(row.get("cnt")));
        }
        List<Map<String, Object>> result = new ArrayList<>();
        java.time.LocalDate today = java.time.LocalDate.now();
        for (int i = days - 1; i >= 0; i--) {
            String key = today.minusDays(i).format(java.time.format.DateTimeFormatter.ofPattern("MM-dd"));
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("date", key);
            row.put("cnt", dateCount.getOrDefault(key, 0L));
            result.add(row);
        }
        return result;
    }

    /** 同上，但带 amount 字段 */
    private List<Map<String, Object>> fillMissingDatesWithAmount(List<Map<String, Object>> raw, int days) {
        Map<String, long[]> dateAmount = new LinkedHashMap<>();
        for (Map<String, Object> row : raw) {
            long[] arr = new long[2];
            arr[0] = toLong(row.get("cnt"));
            arr[1] = Math.round(toDouble(row.get("amount")));
            dateAmount.put(String.valueOf(row.get("date")), arr);
        }
        List<Map<String, Object>> result = new ArrayList<>();
        java.time.LocalDate today = java.time.LocalDate.now();
        for (int i = days - 1; i >= 0; i--) {
            String key = today.minusDays(i).format(java.time.format.DateTimeFormatter.ofPattern("MM-dd"));
            long[] arr = dateAmount.getOrDefault(key, new long[]{0, 0});
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("date", key);
            row.put("cnt", arr[0]);
            row.put("amount", arr[1]);
            result.add(row);
        }
        return result;
    }

    /** 给状态分布补全所有状态码（数据库没有的状态也要显示，前端饼图不会出现"消失的扇形"） */
    private List<Map<String, Object>> enrichStatusDistribution(
            List<Map<String, Object>> raw,
            Map<Integer, String> nameMap,
            Map<Integer, String> colorMap) {
        Map<Integer, Long> statusCount = new LinkedHashMap<>();
        for (Map<String, Object> row : raw) {
            statusCount.put(toInt(row.get("status")), toLong(row.get("cnt")));
        }
        List<Map<String, Object>> result = new ArrayList<>();
        for (Map.Entry<Integer, String> entry : nameMap.entrySet()) {
            int status = entry.getKey();
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("status", status);
            row.put("name", entry.getValue());
            row.put("color", colorMap.get(status));
            row.put("cnt", statusCount.getOrDefault(status, 0L));
            result.add(row);
        }
        return result;
    }

    // ===================== 工具方法 =====================

    private static int toInt(Object o) {
        if (o == null) return 0;
        if (o instanceof Number) return ((Number) o).intValue();
        try { return Integer.parseInt(o.toString()); } catch (Exception e) { return 0; }
    }

    private static long toLong(Object o) {
        if (o == null) return 0L;
        if (o instanceof Number) return ((Number) o).longValue();
        try { return Long.parseLong(o.toString()); } catch (Exception e) { return 0L; }
    }

    private static double toDouble(Object o) {
        if (o == null) return 0.0;
        if (o instanceof Number) return ((Number) o).doubleValue();
        try { return Double.parseDouble(o.toString()); } catch (Exception e) { return 0.0; }
    }

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(JSON.writeValueAsString(obj));
        out.flush();
    }

    private static Map<String, Object> errorOf(String msg) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("success", false);
        r.put("message", msg);
        return r;
    }
}
