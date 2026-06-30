package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 平台虚拟账户实体（对应 system_account 表，只存 1 行 id=1）
 *
 * 用于暂时保管买家支付的尾款 + 中标者的押金，
 * 在买家确认收货后由平台打款给卖家。
 */
public class SystemAccount {
    private Integer id;            // 固定为 1
    private BigDecimal balance;    // 当前余额
    private BigDecimal totalIn;    // 累计收入
    private BigDecimal totalOut;   // 累计支出
    private LocalDateTime updateTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public BigDecimal getBalance() { return balance; }
    public void setBalance(BigDecimal balance) { this.balance = balance; }

    public BigDecimal getTotalIn() { return totalIn; }
    public void setTotalIn(BigDecimal totalIn) { this.totalIn = totalIn; }

    public BigDecimal getTotalOut() { return totalOut; }
    public void setTotalOut(BigDecimal totalOut) { this.totalOut = totalOut; }

    public LocalDateTime getUpdateTime() { return updateTime; }
    public void setUpdateTime(LocalDateTime updateTime) { this.updateTime = updateTime; }

    @Override
    public String toString() {
        return "SystemAccount{id=" + id + ", balance=" + balance +
                ", totalIn=" + totalIn + ", totalOut=" + totalOut + "}";
    }
}
