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

    /**
     * 把"临时图"（item_id IS NULL）的 item_id 绑定到指定拍品（发布拍品时调用）
     *
     * 仅更新 item_id 字段，sort_order 不变。返回受影响行数。
     */
    int bindItemId(@Param("id") Integer id, @Param("itemId") Integer itemId);

    /**
     * 按 URL 查找"临时图"（item_id IS NULL），用于发布时认领本地已上传的图
     */
    ItemImage findTempByUrl(@Param("imageUrl") String imageUrl);

    /** 按 ID 删除（返回受影响行数） */
    int deleteById(@Param("id") Integer id);

    /** 按拍品 ID 删除所有图片（拍品删除时调用） */
    int deleteByItemId(@Param("itemId") Integer itemId);

    /** 按 ID 查询 */
    ItemImage findById(@Param("id") Integer id);

    /** 按拍品 ID 查询所有图片（按 sort_order ASC, id ASC） */
    List<ItemImage> findByItemId(@Param("itemId") Integer itemId);

    /** 按拍品 ID 查询封面图（sort_order=0） */
    ItemImage findCoverByItemId(@Param("itemId") Integer itemId);

    /** 统计某拍品的图片数量 */
    int countByItemId(@Param("itemId") Integer itemId);
}
