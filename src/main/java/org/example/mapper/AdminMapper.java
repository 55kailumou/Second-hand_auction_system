package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Admin;

import java.util.List;

/**
 * 管理员 Mapper
 */
public interface AdminMapper {

    /** 按 ID 查询 */
    Admin findById(@Param("id") Integer id);

    /** 按登录账号查询（登录用） */
    Admin findByAccount(@Param("account") String account);

    /** 查询所有管理员（管理后台列表用） */
    List<Admin> findAll();

    /** 更新最后登录时间 */
    int updateLastLoginTime(@Param("id") Integer id);
}
