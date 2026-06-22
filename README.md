# 二手物品拍卖系统 · 项目骨架

> JSP + Servlet + MyBatis + MySQL · Java 21 · Tomcat 9（Java EE 8 / `javax.*`）

---

## 🚀 怎么把这个骨架跑起来

### 第 1 步：让 IDEA 识别项目

1. 打开 IDEA → **File → Open** → 选 `Second-hand_auction_system` 目录
2. 识别为 Maven 项目 → 等待 IDEA 自动下载依赖（首次约 1-3 分钟）
3. 打开 **Maven 面板**（右侧边栏），点 **Reload All Maven Projects** 确认依赖加载完成

### 第 2 步：填数据库密码

打开 `src/main/resources/db.properties`，把密码改成你自己的 MySQL root 密码：

```properties
jdbc.password=你的MySQL密码
```

### 第 3 步：配置 Tomcat 9

1. 右上角 **Add Configuration...** → 点 **+** → **Tomcat Server → Local**
2. 选 `E:\02_DevToolchains\Tomcat\apache-tomcat-9.0.113`
3. **Deployment** 标签页 → 点 **+** → **Artifact** → 选 `Second-hand_auction_system:war exploded`
4. Application context 改成 `/auction`（或者 `/`，看你喜好）

### 第 4 步：启动！

点右上角绿色三角形 ▶，浏览器访问：

- **首页**：http://localhost:8080/auction/
- **MyBatis 连通测试**：http://localhost:8080/auction/hello

---

## 📂 项目结构

```
Second-hand_auction_system/
├── pom.xml                              ← Maven 依赖（MyBatis / Servlet / JSP / JSTL）
├── docs/
│   ├── ddl.sql                          ← 13 张表的建表脚本
│   └── system_framework.html            ← 框架图（Mermaid 渲染版）
└── src/main/
    ├── java/org/example/
    │   ├── entity/User.java             ← 实体类（对应 user 表）
    │   ├── mapper/UserMapper.java       ← MyBatis Mapper 接口
    │   ├── servlet/HelloServlet.java    ← 示例 Servlet（验证 MyBatis 通）
    │   ├── filter/EncodingFilter.java   ← 字符编码过滤器
    │   └── util/
    │       ├── MyBatisUtil.java         ← SqlSession 工厂单例
    │       └── PasswordUtil.java        ← SHA-256 密码加密
    ├── resources/
    │   ├── db.properties                ← 数据库连接配置
    │   ├── mybatis-config.xml           ← MyBatis 主配置
    │   └── org/example/mapper/
    │       └── UserMapper.xml           ← SQL 映射文件
    └── webapp/
        ├── index.jsp                    ← 欢迎页
        └── WEB-INF/
            ├── web.xml                  ← Servlet/Filter 注册（本项目用注解）
            └── jsp/
                ├── hello.jsp            ← MyBatis 测试结果页
                └── error.jsp            ← 404 错误页
```

---

## ✅ 验证骨架成功的标志

启动后浏览器应该看到：

1. **首页**：紫色渐变背景，"🎉 骨架跑通啦！" 大字，下面三个按钮
2. **点 "测试 MyBatis 连通"**：跳到 `/hello`，看到 `user` 表里的数据（应该是 admin / test / alice / bob 这 4 条）

---

## 🎯 下一步开发计划

按"4 层循环"逐个功能模块实现：

1. **用户注册/登录**（最先做）
   - `entity/User.java`（已有）
   - `mapper/UserMapper.java` 加 `login` / `insert`（已有）
   - 新增 `servlet/UserServlet.java`
   - 新增 `webapp/WEB-INF/jsp/login.jsp` / `register.jsp`

2. **拍品发布/浏览/出价**
3. **订单生成**
4. **个人中心**
5. **管理后台**
6. **收藏、消息、评价等周边**

每个模块 = `entity + mapper + servlet + jsp` 四件套。

---

## 🆘 常见问题

| 问题 | 解决 |
|---|---|
| 启动报 `java.lang.NoClassDefFoundError: jakarta/servlet/...` | 你用了 Tomcat 11，把 pom.xml 改成 jakarta.servlet-api 5.0.0 |
| 中文乱码 | 检查 EncodingFilter 是否生效，JSP 顶部有没有 `<%@ page contentType="text/html;charset=UTF-8" %>` |
| `Communications link failure` | MySQL 没启动，或 db.properties 密码错了 |
| `Access denied for user 'root'` | db.properties 密码不对 |
| Maven 依赖下载慢 | 配置 IDEA 的 Maven 国内镜像（阿里云） |