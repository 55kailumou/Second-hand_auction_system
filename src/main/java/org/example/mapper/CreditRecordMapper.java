package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.CreditRecord;

import java.util.List;
import java.util.Map;

/**
 * 信用评价 Mapper
 */
public interface CreditRecordMapper {

    /** 按 ID 查询 */
    CreditRecord findById(@Param("id") Integer id);

    /**
     * 按 orderId + evaluatorId 查询（检查是否已评价过）
     * 唯一约束 uk_order_evaluator 保证最多 1 条
     */
    CreditRecord findByOrderAndEvaluator(@Param("orderId") Integer orderId,
                                         @Param("evaluatorId") Integer evaluatorId);

    /** 新增评价 */
    int insert(CreditRecord record);

    /**
     * 评价列表（按 evaluator 或 target 查）
     * @param params 支持的 key:
     *   - userId  : Integer  必传，作为 evaluatorId 或 targetId
     *   - type    : String   "sent" 我发出的 / "received" 我收到的
     *   - offset  : Integer
     *   - limit   : Integer
     */
    List<CreditRecord> findByCondition(Map<String, Object> params);

    /** 计数（同条件） */
    int countByCondition(Map<String, Object> params);

    /**
     * 统计收到的评价分数（用于计算平均分）
     * @param userId 被评价人 ID
     * @return {count, avgScore} map
     */
    Map<String, Object> statReceivedScore(@Param("userId") Integer userId);
}
