package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Notice;

import java.util.List;
import java.util.Map;

/**
 * 系统公告 Mapper
 */
public interface NoticeMapper {

    /** 按 ID 查询 */
    Notice findById(Integer id);

    /**
     * 管理后台：按条件分页查询（status / keyword / 分页）
     * @param params 支持 status / keyword / offset / limit
     *   - status: 0=草稿 1=已发布 2=已撤回
     *   - keyword: 模糊匹配 title / content
     */
    List<Notice> findByCondition(Map<String, Object> params);

    /** 管理后台：按条件计数（同 findByCondition 条件） */
    int countByCondition(Map<String, Object> params);

    /**
     * 前台展示：按状态查询（用于首页 banner / 公告列表）
     * @param status 1=已发布
     * @param limit 最多取多少条
     */
    List<Notice> findPublished(@Param("limit") Integer limit);

    /** 新增公告 */
    int insert(Notice notice);

    /** 按 ID 更新（service 层自己控制要改哪些字段） */
    int updateById(Notice notice);

    /**
     * 管理后台：单字段更新状态（发布 / 撤回）
     * 同时会更新 publish_time（status=1 时设 NOW()）
     */
    int updateStatusByAdmin(@Param("noticeId") Integer noticeId,
                            @Param("status") Integer status,
                            @Param("publishTime") String publishTime);

    /**
     * 管理后台：单字段更新置顶
     */
    int updateTopByAdmin(@Param("noticeId") Integer noticeId,
                         @Param("isTop") Integer isTop);

    /** 按 ID 删除 */
    int deleteById(Integer id);
}