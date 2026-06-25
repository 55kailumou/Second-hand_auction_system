package org.example.entity;

import java.time.LocalDateTime;

/**
 * 拍品分类实体（对应 category 表）
 * 支持二级分类（parent_id = 0 表示一级分类）
 */
public class Category {
    private Integer id;
    private String categoryName;
    private Integer parentId;
    private Integer sortOrder;
    private String icon;
    private Integer status;        // 0禁用 1启用（默认1）
    private LocalDateTime createTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public Integer getParentId() { return parentId; }
    public void setParentId(Integer parentId) { this.parentId = parentId; }

    public Integer getSortOrder() { return sortOrder; }
    public void setSortOrder(Integer sortOrder) { this.sortOrder = sortOrder; }

    public String getIcon() { return icon; }
    public void setIcon(String icon) { this.icon = icon; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    @Override
    public String toString() {
        return "Category{id=" + id + ", categoryName='" + categoryName + "', parentId=" + parentId + "}";
    }
}
