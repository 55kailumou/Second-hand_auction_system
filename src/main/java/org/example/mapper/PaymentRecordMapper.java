package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.PaymentRecord;

import java.util.List;
import java.util.Map;

/**
 * 资金流水 Mapper（个人中心账户流水页 + 后台查询用）
 */
public interface PaymentRecordMapper {

    /** 插入一条流水 */
    int insert(PaymentRecord record);

    /** 按 ID 查询 */
    PaymentRecord findById(@Param("id") Integer id);

    /** 最近 N 条全部流水（admin 演示控制台用） */
    List<PaymentRecord> findRecent(Map<String, Object> params);

    /**
     * 分页查某用户的流水
     * @param params: userId, type(可选), offset, limit
     */
    List<PaymentRecord> findByUserIdPaged(Map<String, Object> params);

    int countByUserId(Map<String, Object> params);

    /** 某用户某 type 的流水总额（收入正数/支出负数） */
    java.math.BigDecimal sumByUserAndType(@Param("userId") Integer userId,
                                          @Param("type") Integer type);

    /** 某订单相关的所有流水 */
    List<PaymentRecord> findByOrderNo(@Param("orderNo") String orderNo);
}
