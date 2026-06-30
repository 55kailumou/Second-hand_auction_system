package org.example.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * 押金计算工具
 *
 * 规则：
 *   - 如果卖家显式设置了 deposit > 0，用卖家的设置
 *   - 否则按起拍价 × 10% 自动算（最低 1.00 元，向上取整到 0.01）
 *   - 押金为 0 表示"免押拍品"
 */
public class DepositCalculator {

    /** 默认押金比例：起拍价的 10% */
    public static final BigDecimal DEFAULT_RATE = new BigDecimal("0.10");

    /** 最低押金：1.00 元 */
    public static final BigDecimal MIN_DEPOSIT = new BigDecimal("1.00");

    /**
     * 计算押金
     * @param sellerSetDeposit 卖家发布时设置的值（可能为 null 或 0）
     * @param startPrice       起拍价
     * @return 押金金额（向上取整到 0.01）
     */
    public static BigDecimal calculate(BigDecimal sellerSetDeposit, BigDecimal startPrice) {
        if (sellerSetDeposit != null && sellerSetDeposit.compareTo(BigDecimal.ZERO) > 0) {
            // 卖家设置了 → 用卖家的（向上取整到分）
            return sellerSetDeposit.setScale(2, RoundingMode.CEILING);
        }
        if (startPrice == null || startPrice.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }
        BigDecimal auto = startPrice.multiply(DEFAULT_RATE).setScale(2, RoundingMode.CEILING);
        if (auto.compareTo(MIN_DEPOSIT) < 0) {
            return MIN_DEPOSIT;
        }
        return auto;
    }
}
