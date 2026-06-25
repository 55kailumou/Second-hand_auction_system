package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.WatchList;

import java.util.List;

/**
 * 收藏关注 Mapper
 */
public interface WatchListMapper {

    /** 按 ID 查询 */
    WatchList findById(@Param("id") Integer id);

    /** 查询某用户是否收藏了某拍品（用于详情页判断"已收藏"状态） */
    WatchList findByUserAndItem(@Param("userId") Integer userId,
                                @Param("itemId") Integer itemId);

    /** 查询某用户的所有收藏（按收藏时间倒序） */
    List<WatchList> findByUserId(@Param("userId") Integer userId);

    /** 收藏数（个人中心用） */
    int countByUserId(@Param("userId") Integer userId);

    /** 新增收藏（如果已存在则返回 0，靠 uk_user_item 唯一索引保证） */
    int insert(WatchList watchList);

    /** 按 userId + itemId 取消收藏（删除） */
    int deleteByUserAndItem(@Param("userId") Integer userId,
                            @Param("itemId") Integer itemId);

    /** 按 ID 删除 */
    int deleteById(@Param("id") Integer id);
}
