package org.example.mapper;

import org.apache.ibatis.annotations.Param;
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
    User findByUsername(@Param("username") String username);

    /** 按手机号查询 */
    User findByPhone(@Param("phone") String phone);

    /** 按邮箱查询 */
    User findByEmail(@Param("email") String email);

    /** 登录查询：手机号或邮箱 + 密码 + 状态正常 */
    User loginByPhoneOrEmail(@Param("account") String account, @Param("password") String password);

    /** 注册（插入用户） */
    int insert(User user);

    /** 统计用户总数 */
    int countAll();

    /**
     * 调整信用分（增量更新，范围由 service 层控制 0-150）
     * @param userId 用户 ID
     * @param delta 增量（可正可负）
     */
    int updateCreditScore(@Param("userId") Integer userId,
                          @Param("delta") Integer delta);

    /** 查询所有用户（用于管理后台 / 测试） */
    List<User> findAll();

    /**
     * 管理后台：按条件分页查询用户列表
     * @param params 支持 status / keyword / offset / limit
     *   - status: 0=正常 1=封禁 null=全部
     *   - keyword: 模糊匹配 username / phone / email
     */
    List<User> findByCondition(java.util.Map<String, Object> params);

    /**
     * 管理后台：按条件统计用户数（同 findByCondition 条件）
     */
    int countByCondition(java.util.Map<String, Object> params);

    /**
     * 管理后台：单字段更新用户状态（封禁 / 解封）
     * 单字段 UPDATE 避免覆盖其他并发修改
     */
    int updateStatusByAdmin(@Param("userId") Integer userId,
                            @Param("status") Integer status);

    /**
     * 管理后台：重置用户密码（写入 SHA-256 加密值）
     */
    int resetPasswordByAdmin(@Param("userId") Integer userId,
                             @Param("password") String password);

    // ============ 余额原子操作（支付系统用） ============

    /**
     * 用户余额加钱（原子）
     * @return affected rows（1=成功 0=用户不存在）
     */
    int addBalance(@Param("userId") Integer userId,
                   @Param("amount") java.math.BigDecimal amount);

    /**
     * 用户余额减钱（带防超扣）
     * @return affected rows（1=成功 0=失败：用户不存在或余额不足）
     */
    int subtractBalance(@Param("userId") Integer userId,
                        @Param("amount") java.math.BigDecimal amount);
}