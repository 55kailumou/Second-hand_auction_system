package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Message;

import java.util.List;
import java.util.Map;

/**
 * 消息通知 Mapper
 */
public interface MessageMapper {

    /** 按 ID 查询 */
    Message findById(@Param("id") Integer id);

    /** 插入消息 */
    int insert(Message message);

    /**
     * 查某用户的全部消息（按时间倒序，分页）
     * @param params 支持的 key:
     *   - userId : Integer   必传
     *   - isRead : Integer   0未读 1已读 null 全部
     *   - offset : Integer
     *   - limit  : Integer
     */
    List<Message> findByCondition(Map<String, Object> params);

    /** 计数（同条件） */
    int countByCondition(Map<String, Object> params);

    /** 未读消息数（顶 nav 角标用） */
    int countUnreadByUserId(@Param("userId") Integer userId);

    /** 标记单条已读 */
    int markRead(@Param("id") Integer id, @Param("userId") Integer userId);

    /** 标记全部已读 */
    int markAllRead(@Param("userId") Integer userId);

    /** 删除单条 */
    int deleteById(@Param("id") Integer id, @Param("userId") Integer userId);
}
