package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.SystemAccount;

import java.math.BigDecimal;

/**
 * 平台账户 Mapper（system_account 表只有 1 行 id=1）
 *
 * 重要：所有"加减钱"操作都走原子 SQL（CAS），
 *      根据 affected rows 判断是否成功（防并发超扣）。
 */
public interface SystemAccountMapper {

    /** 取唯一一行 */
    SystemAccount get();

    /**
     * 平台账户入金（加钱）
     * @return affected rows，1=成功 0=失败
     */
    int addBalance(@Param("amount") BigDecimal amount,
                   @Param("remark") String remark);

    /**
     * 平台账户出金（减钱）
     * 带条件 balance >= amount 防超扣
     * @return affected rows，1=成功 0=失败（余额不足）
     */
    int subtractBalance(@Param("amount") BigDecimal amount,
                        @Param("remark") String remark);
}
