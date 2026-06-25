package org.example.entity;

import java.time.LocalDateTime;

/**
 * 投诉实体（对应 complaint 表）
 *
 * 业务说明：
 *   - 投诉必须关联**订单**（不是拍品）—— 已有交易才能投诉
 *   - 投诉人/被投诉人是订单的买家/卖家
 *   - 0待处理 1处理中 2已处理 3已驳回
 *
 * 字段对照 complaint:
 *   id, order_id, complainant_id, respondent_id, reason, evidence,
 *   status, handler_id, handle_result, create_time, handle_time
 */
public class Complaint {
    private Integer id;
    private Integer orderId;
    private Integer complainantId;     // 投诉人
    private Integer respondentId;      // 被投诉人
    private String reason;             // 投诉原因
    private String evidence;           // 证据 URL（可选）
    private Integer status;            // 0待处理 1处理中 2已处理 3已驳回
    private Integer handlerId;         // 处理管理员 ID
    private String handleResult;       // 处理结果说明
    private LocalDateTime createTime;
    private LocalDateTime handleTime;

    // ===== 便捷方法 =====

    public String getStatusText() {
        if (status == null) return "未知";
        switch (status) {
            case 0: return "待处理";
            case 1: return "处理中";
            case 2: return "已处理";
            case 3: return "已驳回";
            default: return "未知";
        }
    }

    public String getStatusBadgeClass() {
        if (status == null) return "badge-gray";
        switch (status) {
            case 0: return "badge-warning";
            case 1: return "badge-info";
            case 2: return "badge-success";
            case 3: return "badge-gray";
            default: return "badge-gray";
        }
    }

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getOrderId() { return orderId; }
    public void setOrderId(Integer orderId) { this.orderId = orderId; }

    public Integer getComplainantId() { return complainantId; }
    public void setComplainantId(Integer complainantId) { this.complainantId = complainantId; }

    public Integer getRespondentId() { return respondentId; }
    public void setRespondentId(Integer respondentId) { this.respondentId = respondentId; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getEvidence() { return evidence; }
    public void setEvidence(String evidence) { this.evidence = evidence; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public Integer getHandlerId() { return handlerId; }
    public void setHandlerId(Integer handlerId) { this.handlerId = handlerId; }

    public String getHandleResult() { return handleResult; }
    public void setHandleResult(String handleResult) { this.handleResult = handleResult; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public LocalDateTime getHandleTime() { return handleTime; }
    public void setHandleTime(LocalDateTime handleTime) { this.handleTime = handleTime; }

    @Override
    public String toString() {
        return "Complaint{id=" + id + ", orderId=" + orderId +
                ", complainant=" + complainantId + ", status=" + status + "}";
    }
}
