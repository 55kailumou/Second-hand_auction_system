package org.example.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * 密码加密工具：SHA-256 哈希
 *
 * 注意：
 * - 这是基础版（教学用），生产环境建议加 salt + bcrypt
 * - 初始管理员密码 "123456" 的 SHA-256 值已写入 ddl.sql
 */
public class PasswordUtil {

    /** 把明文密码加密为 SHA-256 十六进制字符串 */
    public static String encrypt(String rawPassword) {
        if (rawPassword == null) return null;
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(rawPassword.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 算法不可用", e);
        }
    }

    /** 校验明文与密文是否匹配 */
    public static boolean matches(String rawPassword, String encrypted) {
        if (rawPassword == null || encrypted == null) return false;
        return encrypted.equals(encrypt(rawPassword));
    }
}