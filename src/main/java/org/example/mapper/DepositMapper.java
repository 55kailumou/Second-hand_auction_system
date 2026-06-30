package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Deposit;

import java.util.List;
import java.util.Map;

/**
 * 用户押金 Mapper
 */
public interface DepositMapper {

    /** 插入一条押金记录 */
    int insert(Deposit deposit);

    /** 按 ID 查询 */
    Deposit findById(@Param("id") Integer id);

    /** 按 user_id + item_id 查询（唯一约束） */
    Deposit findByUserAndItem(@Param("userId") Integer userId, @Param("itemId") Integer itemId);

    /** 查询某拍品的所有押金记录 */
    List<Deposit> findByItemId(@Param("itemId") Integer itemId);

    /** 查询某拍品所有 status=0（锁定中）的押金 */
    List<Deposit> findActiveByItemId(@Param("itemId") Integer itemId);

    /** 查询某用户的所有押金 */
    List<Deposit> findByUserId(@Param("userId") Integer userId);

    /** 把某条记录状态改为 1（已转货款） */
    int markTransferred(@Param("id") Integer id,
                        @Param("orderNo") String orderNo,
                        @Param("remark") String remark);

    /** 把某条记录状态改为 2（已退还） */
    int markRefunded(@Param("id") Integer id, @Param("remark") String remark);

    /** 把某条记录状态改为 3（已没收） */
    int markForfeited(@Param("id") Integer id, @Param("remark") String remark);

    /** 某拍品的押金总数（status=0/1 都算） */
    java.math.BigDecimal sumActiveAmountByItem(@Param("itemId") Integer itemId);

    /** 某用户的已缴押金总额（status=0/1） */
    java.math.BigDecimal sumActiveAmountByUser(@Param("userId") Integer userId);

    /** 某拍品的中标者押金记录（status=1） */
    Deposit findTransferredByItem(@Param("itemId") Integer itemId);

    // ===== 流水查询（个人中心账户流水页用） =====

    /**
     * 分页查某用户的押金记录
     * @param params: userId, offset, limit
     */
    List<Deposit> findByUserIdPaged(Map<String, Object> params);

    int countByUserId(@Param("userId") Integer userId);

    /**
     * 更新押金的关联订单号（拍卖结束生成订单后，把 PRE_xxx 预订单号改为真实订单号）
     */
    int updateRelatedOrderNo(@Param("id") Integer id, @Param("orderNo") String orderNo);
}
