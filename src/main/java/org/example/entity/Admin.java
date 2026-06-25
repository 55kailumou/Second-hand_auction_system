package org.example.entity;

import java.time.LocalDateTime;

/**
 * 管理员实体（对应 admin 表）
 *
 * 字段对照 admin 表:
 *   id, admin_account, admin_password, admin_name,
 *   role (super/admin/normal), status (0禁用 1启用),
 *   create_time, last_login_time
 */
public class Admin {
    private Integer id;
    private String adminAccount;     // 登录账号
    private String adminPassword;    // 登录密码（SHA-256）
    private String adminName;        // 管理员姓名
    private String role;             // super / admin / normal
    private Integer status;          // 0禁用 1启用
    private LocalDateTime createTime;
    private LocalDateTime lastLoginTime;

    // ===== Getter / Setter =====

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getAdminAccount() { return adminAccount; }
    public void setAdminAccount(String adminAccount) { this.adminAccount = adminAccount; }

    public String getAdminPassword() { return adminPassword; }
    public void setAdminPassword(String adminPassword) { this.adminPassword = adminPassword; }

    public String getAdminName() { return adminName; }
    public void setAdminName(String adminName) { this.adminName = adminName; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public Integer getStatus() { return status; }
    public void setStatus(Integer status) { this.status = status; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }

    public LocalDateTime getLastLoginTime() { return lastLoginTime; }
    public void setLastLoginTime(LocalDateTime lastLoginTime) { this.lastLoginTime = lastLoginTime; }

    @Override
    public String toString() {
        return "Admin{id=" + id + ", account='" + adminAccount +
                "', name='" + adminName + "', role='" + role + "'}";
    }
}
