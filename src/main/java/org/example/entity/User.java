package org.example.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 用户实体类（对应 user 表）
 * 统一身份：买家 + 卖家
 */
public class User {
    private Integer id;
    private String username;
    private String password;        // SHA-256 加密存储
    private String phone;
    private String email;
    private String realName;        // 真实姓名
    private String idCard;          // 身份证号
    private String avatar;          // 头像URL
    private Integer creditScore;    // 信用分 默认100
    private BigDecimal balance;     // 账户余额
    private Integer status;         // 0正常 1封禁
    private LocalDateTime registerTime;
    private LocalDateTime lastLoginTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getRealName() { return realName; }
    public void setRealName(String realName) { this.realName = realName; }

    public String getIdCard() { return idCard; }
    public void setIdCard(String idCard) { this.idCard = idCard; }

    public String getAvatar() { return avatar; }
    public void setAvatar(String avatar) { this.avatar = avatar; }

    public Integer getCreditScore() { return creditScore; }
    public void setCreditScore(Integer creditScore) { this.creditScore = creditScore; }

    public BigDecimal getBalance() { return balance; }
    public void setBalance(BigDecimal balance) { this.balance = balance; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public LocalDateTime getRegisterTime() { return registerTime; }
    public void setRegisterTime(LocalDateTime registerTime) { this.registerTime = registerTime; }

    public LocalDateTime getLastLoginTime() { return lastLoginTime; }
    public void setLastLoginTime(LocalDateTime lastLoginTime) { this.lastLoginTime = lastLoginTime; }

    @Override
    public String toString() {
        return "User{id=" + id + ", username='" + username + "', balance=" + balance + "}";
    }
}