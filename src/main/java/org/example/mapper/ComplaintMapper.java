package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Complaint;

import java.util.List;
import java.util.Map;

/**
 * 投诉 Mapper
 */
public interface ComplaintMapper {

    /** 按 ID 查询 */
    Complaint findById(@Param("id") Integer id);

    /** 提交投诉（插入） */
    int insert(Complaint complaint);

    /**
     * 条件查询（用户端"我的投诉" / 管理员端"投诉列表"）
     * @param params 支持的 key:
     *   - userId     : Integer   必传（用户端查"我的" / 管理员端查"全部"）
     *   - role       : String    "complainant" / "respondent" / "all"，用户端区分方向
     *   - status     : Integer   0/1/2/3 状态筛选
     *   - keyword    : String    订单号/投诉原因 模糊查询
     *   - offset     : Integer
     *   - limit      : Integer
     */
    List<Complaint> findByCondition(Map<String, Object> params);

    /** 计数（同条件） */
    int countByCondition(Map<String, Object> params);

    /** 待处理投诉数（admin 首页角标用） */
    int countPending();

    /** 我发起的投诉数（用户中心"我的投诉"角标） */
    int countMyComplaints(@Param("userId") Integer userId);

    /** 检查某订单是否被当前用户投诉过（避免重复投诉） */
    Complaint findByOrderAndComplainant(@Param("orderId") Integer orderId,
                                        @Param("complainantId") Integer complainantId);

    /** 管理员处理（更新 status + handler_id + handle_result + handle_time） */
    int processComplaint(@Param("id") Integer id,
                         @Param("status") Integer status,
                         @Param("handlerId") Integer handlerId,
                         @Param("handleResult") String handleResult);
}
