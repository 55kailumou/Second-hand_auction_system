package org.example.entity;

import java.time.LocalDateTime;

/**
 * 消息通知实体（对应 message 表）
 *
 * 字段对照 message:
 *   id, user_id, type, title, content, related_id, is_read, create_time
 *
 * type 含义（与 ddl 注释保持一致）:
 *   1 中标通知（买家：你中拍了）
 *   2 出价被超越（买家：你的出价被其他人超过）
 *   3 拍卖开始（系统通知）
 *   4 即将结束（系统通知）
 *   5 订单状态变更（付款/发货/收货/退款申请）
 *   6 审核结果（退款通过/驳回）
 *   7 系统公告
 */
public class Message {
    private Integer id;
    private Integer userId;        // 接收用户
    private Integer type;
    private String title;
    private String content;
    private Integer relatedId;     // 关联业务 ID（订单/拍品/退款等）
    private Integer isRead;        // 0未读 1已读
    private LocalDateTime createTime;

    // ===== 便捷方法 =====

    public String getTypeText() {
        if (type == null) return "未知";
        switch (type) {
            case 1: return "中标通知";
            case 2: return "出价被超越";
            case 3: return "拍卖开始";
            case 4: return "即将结束";
            case 5: return "订单状态";
            case 6: return "审核结果";
            case 7: return "系统公告";
            default: return "其他";
        }
    }

    /** 不同 type 对应的图标 */
    public String getTypeIcon() {
        if (type == null) return "fa-bell";
        switch (type) {
            case 1: return "fa-trophy";         // 中标
            case 2: return "fa-arrow-up";       // 出价被超
            case 3: return "fa-gavel";          // 拍卖开始
            case 4: return "fa-hourglass-half"; // 即将结束
            case 5: return "fa-shopping-cart";  // 订单状态
            case 6: return "fa-check-circle";   // 审核结果
            case 7: return "fa-bullhorn";       // 公告
            default: return "fa-bell";
        }
    }

    /** 不同 type 对应的颜色（CSS 变量） */
    public String getTypeColor() {
        if (type == null) return "var(--color-muted)";
        switch (type) {
            case 1: return "#f59e0b";           // 金 - 中标
            case 2: return "#ef4444";           // 红 - 出价被超
            case 3: return "#3b82f6";           // 蓝 - 拍卖开始
            case 4: return "#f97316";           // 橙 - 即将结束
            case 5: return "#10b981";           // 绿 - 订单状态
            case 6: return "#8b5cf6";           // 紫 - 审核
            case 7: return "#06b6d4";           // 青 - 公告
            default: return "var(--color-muted)";
        }
    }

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public Integer getType() { return type; }
    public void setType(Integer type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Integer getRelatedId() { return relatedId; }
    public void setRelatedId(Integer relatedId) { this.relatedId = relatedId; }

    public Integer getIsRead() { return isRead; }
    public void setIsRead(Integer isRead) { this.isRead = isRead; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    @Override
    public String toString() {
        return "Message{id=" + id + ", userId=" + userId + ", type=" + type +
                ", title='" + title + "', isRead=" + isRead + "}";
    }
}
