package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Category;

import java.util.List;

/**
 * 拍品分类 Mapper
 */
public interface CategoryMapper {

    /** 按 ID 查询 */
    Category findById(Integer id);

    /** 查询所有一级分类（parent_id = 0） */
    List<Category> findTopLevel();

    /** 查询所有分类 */
    List<Category> findAll();

    /** 按 parentId 查询子分类 */
    List<Category> findByParentId(Integer parentId);

    /** 新增分类 */
    int insert(Category category);

    /** 按 ID 删除 */
    int deleteById(Integer id);

    /** 按 ID 更新 */
    int updateById(Category category);

    /** 统计该分类下的拍品数（连表） */
    int countItemsByCategory(Integer categoryId);

    /**
     * 管理后台：单字段更新启用/禁用状态（status 0=禁用 1=启用）
     * 单字段 UPDATE 避免覆盖其他并发修改
     */
    int updateStatusByAdmin(@Param("categoryId") Integer categoryId,
                            @Param("status") Integer status);
}
