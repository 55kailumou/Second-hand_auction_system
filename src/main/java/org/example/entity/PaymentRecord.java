package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 资金流水实体（对应 payment_record 表）
 *
 * type 类型：
 *   1 押金缴纳
 *   2 押金退还
 *   3 押金转货款（中标后抵用）
 *   4 尾款支付
 *   5 平台打款给卖家
 *   6 平台退款给买家
 *   7 账户充值（预留）
 *
 * userRole：payer（付款方）/ receiver（收款方）/ platform（平台自身）
 * method：balance / alipay / wechat / platform
 *
 * amount 约定：正数=收入，负数=支出
 */
public class PaymentRecord {
    private Integer id;
    private Integer userId;
    private String userRole;
    private Integer type;
    private BigDecimal amount;
    private String method;
    private String orderNo;
    private Integer itemId;
    private BigDecimal balanceAfter;   // 用户余额（仅余额变动时记录）
    private BigDecimal platformAfter;  // 平台账户余额（涉及平台时记录）
    private String remark;
    private LocalDateTime createTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public String getUserRole() { return userRole; }
    public void setUserRole(String userRole) { this.userRole = userRole; }

    public Integer getType() { return type; }
    public void setType(Integer type) { this.type = type; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getMethod() { return method; }
    public void setMethod(String method) { this.method = method; }

    public String getOrderNo() { return orderNo; }
    public void setOrderNo(String orderNo) { this.orderNo = orderNo; }

    public Integer getItemId() { return itemId; }
    public void setItemId(Integer itemId) { this.itemId = itemId; }

    public BigDecimal getBalanceAfter() { return balanceAfter; }
    public void setBalanceAfter(BigDecimal balanceAfter) { this.balanceAfter = balanceAfter; }

    public BigDecimal getPlatformAfter() { return platformAfter; }
    public void setPlatformAfter(BigDecimal platformAfter) { this.platformAfter = platformAfter; }

    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public String getTypeText() {
        if (type == null) return "未知";
        switch (type) {
            case 1: return "押金缴纳";
            case 2: return "押金退还";
            case 3: return "押金转货款";
            case 4: return "尾款支付";
            case 5: return "平台打款";
            case 6: return "平台退款";
            case 7: return "账户充值";
            default: return "未知";
        }
    }

    public String getMethodText() {
        if (method == null) return "-";
        switch (method) {
            case "balance": return "余额";
            case "alipay":  return "支付宝";
            case "wechat":  return "微信";
            case "platform": return "平台";
            default: return method;
        }
    }

    @Override
    public String toString() {
        return "PaymentRecord{id=" + id + ", userId=" + userId + ", type=" + type +
                ", amount=" + amount + ", orderNo='" + orderNo + "'}";
    }
}
