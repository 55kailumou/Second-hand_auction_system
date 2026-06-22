package org.example.util;

import org.apache.ibatis.io.Resources;
import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.session.SqlSessionFactoryBuilder;

import java.io.IOException;
import java.io.InputStream;

/**
 * MyBatis 工具类：单例 SqlSessionFactory + 便捷获取 SqlSession
 *
 * 使用示例：
 *   try (SqlSession session = MyBatisUtil.openSession()) {
 *       UserMapper mapper = session.getMapper(UserMapper.class);
 *       User user = mapper.findById(1);
 *   }
 */
public class MyBatisUtil {

    private static SqlSessionFactory factory;

    static {
        try (InputStream is = Resources.getResourceAsStream("mybatis-config.xml")) {
            factory = new SqlSessionFactoryBuilder().build(is);
        } catch (IOException e) {
            throw new ExceptionInInitializerError("MyBatis 初始化失败：" + e.getMessage());
        }
    }

    /** 私有构造，禁止实例化 */
    private MyBatisUtil() {}

    /** 获取 SqlSession（需要手动关闭，推荐 try-with-resources） */
    public static SqlSession openSession() {
        return factory.openSession();
    }

    /** 获取 SqlSessionFactory（高级用法，比如插件、缓存清理） */
    public static SqlSessionFactory getFactory() {
        return factory;
    }
}