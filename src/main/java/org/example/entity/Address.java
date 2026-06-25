package org.example.entity;

import java.time.LocalDateTime;

/**
 * 收货地址实体（对应 address 表）
 *
 * 一个用户可以有多个地址，其中一个为默认地址
 */
public class Address {
    private Integer id;
    private Integer userId;
    private String receiverName;     // 收货人姓名
    private String receiverPhone;    // 收货人电话
    private String province;         // 省
    private String city;             // 市
    private String district;         // 区/县
    private String detailAddress;    // 详细地址
    private Integer isDefault;       // 是否默认 0否 1是
    private LocalDateTime createTime;

    // ===== 便捷方法：拼接完整地址 =====

    public String getFullAddress() {
        return province + city + district + detailAddress;
    }

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getUserId() { return userId; }
    public void setUserId(Integer userId) { this.userId = userId; }

    public String getReceiverName() { return receiverName; }
    public void setReceiverName(String receiverName) { this.receiverName = receiverName; }

    public String getReceiverPhone() { return receiverPhone; }
    public void setReceiverPhone(String receiverPhone) { this.receiverPhone = receiverPhone; }

    public String getProvince() { return province; }
    public void setProvince(String province) { this.province = province; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getDistrict() { return district; }
    public void setDistrict(String district) { this.district = district; }

    public String getDetailAddress() { return detailAddress; }
    public void setDetailAddress(String detailAddress) { this.detailAddress = detailAddress; }

    public Integer getIsDefault() { return isDefault; }
    public void setIsDefault(Integer isDefault) { this.isDefault = isDefault; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    @Override
    public String toString() {
        return "Address{id=" + id + ", userId=" + userId +
                ", receiver='" + receiverName + "', fullAddress='" + getFullAddress() + "'}";
    }
}