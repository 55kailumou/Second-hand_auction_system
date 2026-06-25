package org.example.entity;

import java.time.LocalDateTime;

/**
 * 收藏关注实体（对应 watch_list 表）
 *
 * 一个用户可以收藏多个拍品（同一拍品不能重复收藏，靠 uk_user_item 唯一索引保证）
 *
 * 字段对照表 watch_list:
 *   id, user_id, item_id, add_time
 */
public class WatchList {
    private Integer id;
    private Integer userId;
    private Integer itemId;
    private LocalDateTime addTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getItemId() { return itemId; }
    public void setItemId(Integer itemId) { this.itemId = itemId; }

    public LocalDateTime getAddTime() { return addTime; }
    public void setAddTime(LocalDateTime addTime) { this.addTime = addTime; }

    @Override
    public String toString() {
        return "WatchList{id=" + id + ", userId=" + userId + ", itemId=" + itemId +
                ", addTime=" + addTime + "}";
    }
}
