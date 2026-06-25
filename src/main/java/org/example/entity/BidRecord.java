package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 出价记录实体（对应 bid_record 表）
 *
 * isWinning 0 否 1 是当前最高价
 * isProxy   0 否 1 是代理出价
 */
public class BidRecord {
    private Integer id;
    private Integer itemId;
    private Integer bidderId;
    private BigDecimal bidAmount;
    private Integer isWinning;
    private Integer isProxy;
    private LocalDateTime bidTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getItemId() { return itemId; }
    public void setItemId(Integer itemId) { this.itemId = itemId; }

    public Integer getBidderId() { return bidderId; }
    public void setBidderId(Integer bidderId) { this.bidderId = bidderId; }

    public BigDecimal getBidAmount() { return bidAmount; }
    public void setBidAmount(BigDecimal bidAmount) { this.bidAmount = bidAmount; }

    public Integer getIsWinning() { return isWinning; }
    public void setIsWinning(Integer isWinning) { this.isWinning = isWinning; }

    public Integer getIsProxy() { return isProxy; }
    public void setIsProxy(Integer isProxy) { this.isProxy = isProxy; }

    public LocalDateTime getBidTime() { return bidTime; }
    public void setBidTime(LocalDateTime bidTime) { this.bidTime = bidTime; }

    @Override
    public String toString() {
        return "BidRecord{id=" + id + ", itemId=" + itemId + ", bidderId=" + bidderId +
                ", bidAmount=" + bidAmount + ", isWinning=" + isWinning + "}";
    }
}
