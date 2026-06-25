package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.Address;

import java.util.List;

/**
 * 收货地址 Mapper
 */
public interface AddressMapper {

    /** 按 ID 查询 */
    Address findById(@Param("id") Integer id);

    /** 查询用户的所有地址（按默认优先 + 创建时间倒序） */
    List<Address> findByUserId(@Param("userId") Integer userId);

    /** 查询用户的默认地址 */
    Address findDefaultByUserId(@Param("userId") Integer userId);

    /** 新增地址 */
    int insert(Address address);

    /** 更新地址 */
    int updateById(Address address);

    /** 删除地址 */
    int deleteById(@Param("id") Integer id);

    /** 把用户所有地址都置为非默认（用于切换默认地址时） */
    int clearDefaultByUserId(@Param("userId") Integer userId);

    /** 设为默认地址 */
    int setDefault(@Param("id") Integer id);
}