package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.AuctionItem;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 拍品 Mapper（核心）
 */
public interface AuctionItemMapper {

    /** 按 ID 查询（详情页） */
    AuctionItem findById(Integer id);

    /** 发布拍品（插入） */
    int insert(AuctionItem item);

    /** 更新拍品（编辑用，不动 current_price/status） */
    int updateById(AuctionItem item);

    /**
     * 卖家编辑"可改字段"：标题/描述/品牌/型号/新旧/瑕疵/封面/多图
     * 不动价格、时间、状态 —— 任何状态都安全（已开始拍卖也能改描述图）
     *
     * ⚠️ Servlet 层必须校验：当前用户是该拍品的卖家
     */
    int updateEditableFieldsByOwner(AuctionItem item);

    /**
     * 卖家编辑"全部字段"（包括价格/时间）
     * 仅用于：status=0 待审核 / status=5 审核未通过 / status=1 未开始（start_time > now）
     * 不动 current_price / status / view_count
     *
     * ⚠️ Servlet 层必须严格校验状态合法性
     */
    int updateAllFieldsByOwner(AuctionItem item);

    /** 乐观锁更新当前价（出价时用）
     *  UPDATE auction_item SET current_price=? WHERE id=? AND current_price<?
     *  返回受影响行数；0 表示价格已被别人更新 */
    int updatePriceOptimistic(@Param("id") Integer id,
                              @Param("newPrice") BigDecimal newPrice,
                              @Param("oldPrice") BigDecimal oldPrice);

    /** 原子自增浏览数 */
    int incrementViewCount(Integer id);

    /** 更新状态（如审核、成交、流拍、下架） */
    int updateStatus(@Param("id") Integer id, @Param("status") Integer status);

    /** 乐观更新状态（仅当 status==1 拍卖中时），用于结算/成交/流拍等场景
     *  返回受影响行数：0 表示状态已经被改过，不能再更新（避免重复结算/并发脏写） */
    int updateStatusIfActive(@Param("id") Integer id, @Param("status") Integer status);

    /**
     * 列表查询（分页+筛选+排序）
     * @param params 支持的 key:
     *   - categoryId : Integer  分类 ID
     *   - sellerId   : Integer  卖家 ID
     *   - status     : Integer  状态
     *   - keyword    : String   标题模糊关键字
     *   - minPrice   : BigDecimal
     *   - maxPrice   : BigDecimal
     *   - sort       : String   "newest" | "ending" | "priceAsc" | "priceDesc" | "hot"
     *   - offset     : Integer
     *   - limit      : Integer
     */
    List<AuctionItem> findByCondition(Map<String, Object> params);

    /** 计数（同条件，配合分页） */
    int countByCondition(Map<String, Object> params);

    /** 拍卖结束自动结算（>= end_time 且 status=1 的拍品） */
    List<AuctionItem> findEndedActiveItems();

    /** 卖家在某状态下的拍品数（个人中心用） */
    int countBySellerAndStatus(@Param("sellerId") Integer sellerId, @Param("status") Integer status);

    /** 管理员修改拍品分类（单字段更新，避免覆盖其他并发改动） */
    int updateCategoryByAdmin(@Param("id") Integer id, @Param("categoryId") Integer categoryId);
}
