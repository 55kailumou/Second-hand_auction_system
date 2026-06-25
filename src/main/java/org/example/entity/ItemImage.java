package org.example.entity;

/**
 * 拍品图片实体（对应 item_image 表）
 *
 * 一对多：一个 AuctionItem 对应多条 ItemImage
 * - sort_order = 0 的为封面图
 * - sort_order 越大越靠后
 *
 * 注：DDL 里 item_image 表已建好但之前未启用，本实体配套 Mapper + Servlet 上线。
 */
public class ItemImage {
    private Integer id;
    private Integer itemId;        // 拍品 ID（FK -> auction_item.id）
    private String imageUrl;       // 图片 URL（远程 URL：http(s)://...，浏览器直接加载）
    private Integer sortOrder;     // 排序：0=封面，其余递增

    public ItemImage() {}

    public ItemImage(Integer itemId, String imageUrl, Integer sortOrder) {
        this.itemId = itemId;
        this.imageUrl = imageUrl;
        this.sortOrder = sortOrder;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getItemId() { return itemId; }
    public void setItemId(Integer itemId) { this.itemId = itemId; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public Integer getSortOrder() { return sortOrder; }
    public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }

    @Override
    public String toString() {
        return "ItemImage{id=" + id + ", itemId=" + itemId +
                ", imageUrl='" + imageUrl + "', sortOrder=" + sortOrder + "}";
    }
}
