package org.example.mapper;

import org.apache.ibatis.annotations.Param;

import java.util.List;
import java.util.Map;

/**
 * 数据统计 Mapper
 *
 * 提供 admin 后台"数据统计"页所需的全部聚合 SQL。
 * 一次性接口：getOverview() 返回所有统计结果（用 LinkedHashMap 保持顺序）。
 */
public interface StatsMapper {

    /**
     * 一次性拉全部统计数据
     *
     * @param params 支持的 key:
     *   - trendDays : Integer   趋势统计的天数（默认 30）
     */
    Map<String, Object> getOverview(@Param("trendDays") Integer trendDays);

    // ============ 单独方法（备用，便于将来单图刷新） ============

    /** 用户总数 */
    int countUsers();

    /** 拍品总数 */
    int countItems();

    /** 已成交订单数（status 2 已发货 / 3 已收货） */
    int countCompletedOrders();

    /** 总成交额 GMV（已成交订单的 final_price 之和） */
    Double sumGmv();

    /** 用户增长趋势（最近 N 天） */
    List<Map<String, Object>> userTrend(@Param("days") Integer days);

    /** 拍品状态分布 */
    List<Map<String, Object>> itemStatusDistribution();

    /** 拍品分类分布（按二级分类聚合，限 Top N） */
    List<Map<String, Object>> categoryDistribution(@Param("limit") Integer limit);

    /** 订单趋势（最近 N 天）：每日新增订单数 + 金额 */
    List<Map<String, Object>> orderTrend(@Param("days") Integer days);

    /** 订单状态分布 */
    List<Map<String, Object>> orderStatusDistribution();

    /** 热门拍品 Top N（按 view_count 降序） */
    List<Map<String, Object>> topItemsByViews(@Param("limit") Integer limit);
}
