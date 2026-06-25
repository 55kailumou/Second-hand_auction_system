package org.example.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * 统一响应工具：异常处理 + 错误响应构造
 *
 * 使用示例：
 *   try {
 *       ...
 *   } catch (Exception e) {
 *       writeJson(resp, ResponseUtil.errorOf("出价失败，请稍后重试"));
 *   }
 *
 * 设计原则：
 *   - 日志：详细异常打到 server log（log.error）
 *   - 响应：只给前端通用提示，**不暴露 SQL 异常、字段名、堆栈**（防信息泄露）
 *   - 错误分类：业务校验错（"金额必须 > 0"）/ 系统错（"系统繁忙，请稍后重试"）
 */
public class ResponseUtil {

    private static final Logger log = LoggerFactory.getLogger(ResponseUtil.class);

    /** 私有构造 */
    private ResponseUtil() {}

    /**
     * 构造错误响应（业务校验用，明文返回给用户）
     */
    public static Map<String, Object> errorOf(String message) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", false);
        r.put("message", message);
        return r;
    }

    /**
     * 构造成功响应
     */
    public static Map<String, Object> successOf(Object data) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", true);
        if (data != null) r.put("data", data);
        return r;
    }

    /**
     * 统一异常处理：详细日志 + 安全返回
     * @param e 异常
     * @param action 触发场景描述（写到日志，便于排查）
     * @return 给前端的通用错误响应（不包含 e.getMessage()）
     */
    public static Map<String, Object> handleException(Exception e, String action) {
        log.error("[{}] 系统异常: {}", action, e.getMessage(), e);
        return errorOf("操作失败，请稍后重试");
    }

    /**
     * 业务校验失败的快捷调用（也是 errorOf，但语义更清晰）
     */
    public static Map<String, Object> validationError(String message) {
        return errorOf(message);
    }
}