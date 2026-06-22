package org.example.mapper;

import org.example.entity.User;

import java.util.List;

/**
 * 用户 Mapper 接口
 * MyBatis 会通过动态代理自动生成实现类，SQL 在 UserMapper.xml 里
 */
public interface UserMapper {

    /** 按 ID 查询 */
    User findById(Integer id);

    /** 按用户名查询 */
    User findByUsername(String username);

    /** 按手机号查询 */
    User findByPhone(String phone);

    /** 登录查询：用户名 + 密码 + 状态正常 */
    User login(String username, String password);

    /** 注册（插入用户） */
    int insert(User user);

    /** 统计用户总数 */
    int countAll();

    /** 查询所有用户（用于管理后台 / 测试） */
    List<User> findAll();
}