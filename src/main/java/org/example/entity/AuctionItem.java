package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 拍品实体（对应 auction_item 表，核心表）
 *
 * 状态 status 取值：
 *   0 待审核  1 拍卖中  2 已成交  3 已流拍  4 已下架  5 审核未通过
 */
public class AuctionItem {
    private Integer id;
    private Integer sellerId;
    private Integer categoryId;
    private String title;
    private String description;
    private String brand;
    private String model;
    private String conditionLevel;   // 新旧程度，如 "9成新"
    private String flawDesc;         // 瑕疵说明
    private String coverImage;       // 封面图 URL
    private String imageUrls;        // 多图 JSON 数组字符串
    private BigDecimal startPrice;
    private BigDecimal deposit;          // 参拍押金（卖家发布时定，0=免押；默认起拍价×10%）
    private BigDecimal currentPrice;
    private BigDecimal bidIncrement;
    private BigDecimal reservePrice; // 可选
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private Integer status;
    private Integer viewCount;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getSellerId() { return sellerId; }
    public void setSellerId(Integer sellerId) { this.sellerId = sellerId; }

    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getBrand() { return brand; }
    public void setBrand(String brand) { this.brand = brand; }

    public String getModel() { return model; }
    public void setModel(String model) { this.model = model; }

    public String getConditionLevel() { return conditionLevel; }
    public void setConditionLevel(String conditionLevel) { this.conditionLevel = conditionLevel; }

    public String getFlawDesc() { return flawDesc; }
    public void setFlawDesc(String flawDesc) { this.flawDesc = flawDesc; }

    public String getCoverImage() { return coverImage; }
    public void setCoverImage(String coverImage) { this.coverImage = coverImage; }

    public String getImageUrls() { return imageUrls; }
    public void setImageUrls(String imageUrls) { this.imageUrls = imageUrls; }

    public BigDecimal getStartPrice() { return startPrice; }
    public void setStartPrice(BigDecimal startPrice) { this.startPrice = startPrice; }

    public BigDecimal getDeposit() { return deposit; }
    public void setDeposit(BigDecimal deposit) { this.deposit = deposit; }

    public BigDecimal getCurrentPrice() { return currentPrice; }
    public void setCurrentPrice(BigDecimal currentPrice) { this.currentPrice = currentPrice; }

    public BigDecimal getBidIncrement() { return bidIncrement; }
    public void setBidIncrement(BigDecimal bidIncrement) { this.bidIncrement = bidIncrement; }

    public BigDecimal getReservePrice() { return reservePrice; }
    public void setReservePrice(BigDecimal reservePrice) { this.reservePrice = reservePrice; }

    public LocalDateTime getStartTime() { return startTime; }
    public void setStartTime(LocalDateTime startTime) { this.startTime = startTime; }

    public LocalDateTime getEndTime() { return endTime; }
    public void setEndTime(LocalDateTime endTime) { this.endTime = endTime; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Integer getViewCount() { return viewCount; }
    public void setViewCount(Integer viewCount) { this.viewCount = viewCount; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public LocalDateTime getUpdateTime() { return updateTime; }
    public void setUpdateTime(LocalDateTime updateTime) { this.updateTime = updateTime; }

    @Override
    public String toString() {
        return "AuctionItem{id=" + id + ", title='" + title + "', currentPrice=" + currentPrice + ", status=" + status + "}";
    }
}
