package org.example.entity;

import java.time.LocalDateTime;

/**
 * 信用评价实体（对应 credit_record 表）
 *
 * 一条评价 = 一次"评价人 → 被评价人"打分
 *   - role=1: 买家评价卖家
 *   - role=2: 卖家评价买家
 * 唯一约束 (order_id, evaluator_id)：同一订单同一评价人只能评一次
 *
 * 字段对照 credit_record:
 *   id, order_id, evaluator_id, target_id, role, score, content, create_time
 */
public class CreditRecord {
    private Integer id;
    private Integer orderId;
    private Integer evaluatorId;     // 评价人
    private Integer targetId;        // 被评价人
    private Integer role;            // 1买家评价卖家 2卖家评价买家
    private Integer score;           // 1-5
    private String content;          // 评价内容（可选）
    private LocalDateTime createTime;

    // ===== 便捷方法 =====

    /** 角色文字 */
    public String getRoleText() {
        if (role == null) return "未知";
        return role == 1 ? "买家评价卖家" : "卖家评价买家";
    }

    /** 星星数组（用于 Vue v-for） */
    public boolean[] getStars() {
        boolean[] arr = new boolean[5];
        if (score != null) {
            for (int i = 0; i < 5; i++) arr[i] = i < score;
        }
        return arr;
    }

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getOrderId() { return orderId; }
    public void setOrderId(Integer orderId) { this.orderId = orderId; }

    public Integer getEvaluatorId() { return evaluatorId; }
    public void setEvaluatorId(Integer evaluatorId) { this.evaluatorId = evaluatorId; }

    public Integer getTargetId() { return targetId; }
    public void setTargetId(Integer targetId) { this.targetId = targetId; }

    public Integer getRole() { return role; }
    public void setRole(Integer role) { this.role = role; }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    @Override
    public String toString() {
        return "CreditRecord{id=" + id + ", orderId=" + orderId +
                ", evaluator=" + evaluatorId + ", target=" + targetId +
                ", role=" + role + ", score=" + score + "}";
    }
}
