package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.OrderInfo;

import java.util.List;
import java.util.Map;

/**
 * 订单 Mapper
 */
public interface OrderMapper {

    /** 按 ID 查询 */
    OrderInfo findById(@Param("id") Integer id);

    /** 按订单号查询 */
    OrderInfo findByOrderNo(@Param("orderNo") String orderNo);

    /** 创建订单（插入） */
    int insert(OrderInfo order);

    /** 更新订单状态（通用） */
    int updateStatus(@Param("id") Integer id, @Param("status") Integer status);

    /** 付款（更新 status 0→1 + 付款时间） */
    int markPaid(@Param("id") Integer id);

    /** 发货（更新 status 1→2 + 物流信息 + 发货时间） */
    int markDelivered(@Param("id") Integer id,
                      @Param("logisticsCompany") String logisticsCompany,
                      @Param("trackingNumber") String trackingNumber);

    /** 确认收货（更新 status 2→3 + 收货时间） */
    int markReceived(@Param("id") Integer id);

    /** 取消订单（更新 status 0→6） */
    int cancel(@Param("id") Integer id);

    /** 我的订单列表（按角色 + 状态筛选 + 分页）
     * @param params 支持的 key:
     *   - userId   : Integer   当前用户 ID（必传）
     *   - role     : String    "buyer" | "seller" | "all"，角色筛选
     *   - status   : Integer   状态筛选（可选）
     *   - offset   : Integer
     *   - limit    : Integer
     *   - keyword  : String    订单号/拍品标题模糊查询（可选）
     */
    List<OrderInfo> findByCondition(Map<String, Object> params);

    /** 计数（同条件） */
    int countByCondition(Map<String, Object> params);

    /** 统计某状态的订单数（个人中心用） */
    int countByBuyerAndStatus(@Param("buyerId") Integer buyerId, @Param("status") Integer status);

    // ============ 退款流程（阶段二） ============

    /** 买家申请退款（status 1/2 → 4） */
    int markRefundRequested(@Param("id") Integer id,
                            @Param("refundReason") String refundReason);

    /** 管理员同意退款（status 4 → 5） */
    int markRefunded(@Param("id") Integer id,
                     @Param("auditResult") String auditResult);

    /** 管理员驳回退款（status 4 → 1） */
    int markRefundRejected(@Param("id") Integer id,
                           @Param("auditResult") String auditResult);

    /**
     * 退款审批列表查询
     * @param params 支持的 key:
     *   - status  : Integer   4 待审核 / 5 已完成 / null 全部
     *   - keyword : String    订单号/拍品标题/退款理由 模糊查询
     *   - offset  : Integer
     *   - limit   : Integer
     */
    List<OrderInfo> findRefundByCondition(Map<String, Object> params);

    /** 退款列表计数（同条件） */
    int countRefundByCondition(Map<String, Object> params);

    /** 待审核退款数（admin 首页角标用） */
    int countPendingRefund();
}