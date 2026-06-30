package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 用户-拍品 押金记录实体（对应 user_deposit 表）
 *
 * status 状态机：
 *   0 已缴纳（锁定中，等拍卖结束）
 *   1 已转为货款（中标者，押金抵货款）
 *   2 已退还（未中标者，押金退回原账户）
 *   3 已没收（拍卖违约等极端情况，预留）
 */
public class Deposit {
    private Integer id;
    private Integer userId;
    private Integer itemId;
    private BigDecimal amount;
    private Integer status;
    private String payMethod;          // balance / alipay / wechat
    private LocalDateTime payTime;
    private LocalDateTime refundTime;  // 退还/转货款时间（status=1 或 2 时记录）
    private String relatedOrderNo;     // 转货款时记录关联订单号
    private String remark;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getItemId() { return itemId; }
    public void setItemId(Integer itemId) { this.itemId = itemId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public String getPayMethod() { return payMethod; }
    public void setPayMethod(String payMethod) { this.payMethod = payMethod; }

    public LocalDateTime getPayTime() { return payTime; }
    public void setPayTime(LocalDateTime payTime) { this.payTime = payTime; }

    public LocalDateTime getRefundTime() { return refundTime; }
    public void setRefundTime(LocalDateTime refundTime) { this.refundTime = refundTime; }

    public String getRelatedOrderNo() { return relatedOrderNo; }
    public void setRelatedOrderNo(String relatedOrderNo) { this.relatedOrderNo = relatedOrderNo; }

    public String getRemark() { return remark; }
    public void setRemark(String remark) { this.remark = remark; }

    public String getStatusText() {
        if (status == null) return "未知";
        switch (status) {
            case 0: return "已缴纳（锁定中）";
            case 1: return "已转货款";
            case 2: return "已退还";
            case 3: return "已没收";
            default: return "未知";
        }
    }

    @Override
    public String toString() {
        return "Deposit{id=" + id + ", userId=" + userId + ", itemId=" + itemId +
                ", amount=" + amount + ", status=" + status + "}";
    }
}
