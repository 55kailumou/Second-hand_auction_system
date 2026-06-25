package org.example.entity;

import java.time.LocalDateTime;

/**
 * 系统公告实体（对应 notice 表）
 *
 * 字段说明：
 *   id           公告 ID
 *   adminId      发布管理员 ID
 *   title        公告标题
 *   content      公告内容（纯文本或简单 HTML）
 *   isTop        是否置顶 0=否 1=是
 *   status       0=草稿 1=已发布 2=已撤回
 *   publishTime  发布时间
 *   createTime   创建时间
 */
public class Notice {
    private Integer id;
    private Integer adminId;
    private String title;
    private String content;
    private Integer isTop;
    private Integer status;
    private LocalDateTime publishTime;
    private LocalDateTime createTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getAdminId() { return adminId; }
    public void setAdminId(Integer adminId) { this.adminId = adminId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public Integer getIsTop() { return isTop; }
    public void setIsTop(Integer isTop) { this.isTop = isTop; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public LocalDateTime getPublishTime() { return publishTime; }
    public void setPublishTime(LocalDateTime publishTime) { this.publishTime = publishTime; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    @Override
    public String toString() {
        return "Notice{id=" + id + ", title='" + title + "', status=" + status + ", isTop=" + isTop + "}";
    }
}