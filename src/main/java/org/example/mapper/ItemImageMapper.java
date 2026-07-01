package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.ItemImage;

import java.util.List;

/**
 * 拍品图片 Mapper
 *
 * 提供 item_image 表的 CRUD 与按拍品 ID 查询。
 * 注意：item_image 是辅助表，auction_item 表里仍然冗余存了 cover_image 和 image_urls（JSON 数组）
 *       以兼容已有页面。两者保持同步：发布拍品时同时写两张表。
 */
public interface ItemImageMapper {

    /** 单条插入（返回自增 id） */
    int insert(ItemImage image);

    /** 按 ID 删除（返回受影响行数） */
    int deleteById(@Param("id") Integer id);

    /** 按 ID 查询 */
    ItemImage findById(@Param("id") Integer id);

    /** 按拍品 ID 查询所有图片（按 sort_order ASC, id ASC） */
    List<ItemImage> findByItemId(@Param("itemId") Integer itemId);
}
