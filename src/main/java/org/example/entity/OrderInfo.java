package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 订单实体（对应 order_info 表）
 *
 * 状态机：
 * 0 待付款  →  1 已付款  →  2 已发货  →  3 已收货  ✓
 *              ↓
 *              4 申请退款  →  5 已退款
 *   ↓
 *   6 已取消（超时未付款）
 *
 * 订单号用 UUID 去横线，32 位唯一标识
 */
public class OrderInfo {
    private Integer id;
    private String orderNo;             // 订单号
    private Integer itemId;
    private String itemTitle;           // 拍品标题快照（下单时拍品标题/图片可能改）
    private String coverImage;          // 封面图快照
    private Integer buyerId;
    private Integer sellerId;
    private BigDecimal finalPrice;      // 成交价
    private Integer addressId;          // 收货地址 ID
    private Integer status;             // 0待付款 1已付款 2已发货 3已收货 4申请退款 5已退款 6已取消
    private LocalDateTime payTime;
    private LocalDateTime deliverTime;
    private LocalDateTime receiveTime;
    private String logisticsCompany;
    private String trackingNumber;
    private LocalDateTime createTime;
    private String refundReason;          // 退款理由（买家填）
    private LocalDateTime refundAuditTime; // 退款审核时间
    private String refundAuditResult;     // 退款审核结果说明

    // ===== 状态便捷方法 =====

    public String getStatusText() {
        if (status == null) return "未知";
        switch (status) {
            case 0: return "待付款";
            case 1: return "已付款";
            case 2: return "已发货";
            case 3: return "已收货";
            case 4: return "申请退款";
            case 5: return "已退款";
            case 6: return "已取消";
            default: return "未知";
        }
    }

    public String getStatusBadgeClass() {
        if (status == null) return "badge-gray";
        switch (status) {
            case 0: return "badge-warning";  // 待付款 - 警告色
            case 1: return "badge-info";     // 已付款 - 信息色
            case 2: return "badge-primary";  // 已发货 - 主色
            case 3: return "badge-success";  // 已收货 - 成功色
            case 4: return "badge-warning";  // 申请退款 - 警告色
            case 5: return "badge-gray";     // 已退款 - 灰色
            case 6: return "badge-gray";     // 已取消 - 灰色
            default: return "badge-gray";
        }
    }

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getOrderNo() { return orderNo; }
    public void setOrderNo(String orderNo) { this.orderNo = orderNo; }

    public Integer getItemId() { return itemId; }
    public void setItemId(Integer itemId) { this.itemId = itemId; }

    public String getItemTitle() { return itemTitle; }
    public void setItemTitle(String itemTitle) { this.itemTitle = itemTitle; }

    public String getCoverImage() { return coverImage; }
    public void setCoverImage(String coverImage) { this.coverImage = coverImage; }

    public Integer getBuyerId() { return buyerId; }
    public void setBuyerId(Integer buyerId) { this.buyerId = buyerId; }

    public Integer getSellerId() { return sellerId; }
    public void setSellerId(Integer sellerId) { this.sellerId = sellerId; }

    public BigDecimal getFinalPrice() { return finalPrice; }
    public void setFinalPrice(BigDecimal finalPrice) { this.finalPrice = finalPrice; }

    public Integer getAddressId() { return addressId; }
    public void setAddressId(Integer addressId) { this.addressId = addressId; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public LocalDateTime getPayTime() { return payTime; }
    public void setPayTime(LocalDateTime payTime) { this.payTime = payTime; }

    public LocalDateTime getDeliverTime() { return deliverTime; }
    public void setDeliverTime(LocalDateTime deliverTime) { this.deliverTime = deliverTime; }

    public LocalDateTime getReceiveTime() { return receiveTime; }
    public void setReceiveTime(LocalDateTime receiveTime) { this.receiveTime = receiveTime; }

    public String getLogisticsCompany() { return logisticsCompany; }
    public void setLogisticsCompany(String logisticsCompany) { this.logisticsCompany = logisticsCompany; }

    public String getTrackingNumber() { return trackingNumber; }
    public void setTrackingNumber(String trackingNumber) { this.trackingNumber = trackingNumber; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public String getRefundReason() { return refundReason; }
    public void setRefundReason(String refundReason) { this.refundReason = refundReason; }

    public LocalDateTime getRefundAuditTime() { return refundAuditTime; }
    public void setRefundAuditTime(LocalDateTime refundAuditTime) { this.refundAuditTime = refundAuditTime; }

    public String getRefundAuditResult() { return refundAuditResult; }
    public void setRefundAuditResult(String refundAuditResult) { this.refundAuditResult = refundAuditResult; }

    @Override
    public String toString() {
        return "OrderInfo{id=" + id + ", orderNo='" + orderNo +
                "', itemId=" + itemId + ", finalPrice=" + finalPrice +
                ", status=" + status + "}";
    }
}