# 二手物品拍卖系统

> JSP + Servlet + MyBatis + MySQL · Java 21 · Tomcat 9（Java EE 8 / `javax.*`）

面向校园 / 社区的 Web 二手拍卖平台：用户注册登录后可发布拍品、浏览出价、成交订单、管理个人中心；管理员后台处理申诉、退款、分类与公告。

**当前阶段**：业务模块已成型（拍品 / 订单 / 收藏 / 消息 / 投诉 / 积分 / 地址 / 管理后台），首页已完成整体重构（分类色块 / Hero / 推荐 / 热搜）。

---

## 🚀 怎么把项目跑起来

### 第 1 步：让 IDEA 识别项目

1. 打开 IDEA → **File → Open** → 选 `Second-hand_auction_system` 目录
2. 识别为 Maven 项目 → 等待 IDEA 自动下载依赖（首次约 1-3 分钟）
3. 打开 **Maven 面板**（右侧边栏），点 **Reload All Maven Projects** 确认依赖加载完成

### 第 2 步：下载中文字体（必做）

首页与全局样式使用了 `SarasaMonoSC`（更纱黑体 SC）中文字体，仓库 **未追踪字体文件**（单文件 13–15 MB，三个合计约 42 MB）。

1. 打开 https://github.com/be5invis/Sarasa-Gothic/releases ，下载最新 Release 的 **TTF** 完整包
2. 解压后，把这 3 个文件复制到 `src/main/webapp/static/fonts/` 下：
   - `SarasaMonoSC-Regular.ttf`
   - `SarasaMonoSC-Bold.ttf`
   - `SarasaMonoSC-Italic.ttf`

> 不放字体也能跑，首页中文会变成默认字体（甚至方框），但业务功能不受影响。

### 第 3 步：填数据库密码

打开 `src/main/resources/db.properties`，把密码改成你自己的 MySQL root 密码：

```properties
jdbc.password=你的MySQL密码
```

### 第 4 步：初始化数据库

1. 启动 MySQL
2. 用 root 登录，执行 `docs/ddl.sql` 建库建表（13 张表）

### 第 5 步：配置 Tomcat 9

1. 右上角 **Add Configuration...** → 点 **+** → **Tomcat Server → Local**
2. 选你的 Tomcat 9 安装路径
3. **Deployment** 标签页 → 点 **+** → **Artifact** → 选 `Second-hand_auction_system:war exploded`
4. Application context 改成 `/auction`（或者 `/`，看你喜好）

### 第 6 步：启动

点右上角绿色三角形 ▶，浏览器访问：

| 地址 | 用途 |
|---|---|
| http://localhost:8080/auction/ | 首页（分类色块 / Hero / 推荐 / 热搜） |
| http://localhost:8080/auction/hello | MyBatis 连通测试 |
| http://localhost:8080/auction/admin/login | 管理员后台（默认 `admin` / `123456`） |

---

## 🔤 字体说明

| 文件 | 用途 | 大小 |
|---|---|---|
| `SarasaMonoSC-Regular.ttf` | 全局正文 | ~14 MB |
| `SarasaMonoSC-Bold.ttf` | 标题 / 按钮 | ~14 MB |
| `SarasaMonoSC-Italic.ttf` | 强调 | ~15 MB |

**为什么不上传到仓库？**
- 单文件 13–15 MB，接近 GitHub 推荐的 50 MB 上限
- clone 速度变慢，三个文件约 42 MB 完全是冗余下载
- `.gitignore` 已排除 `src/main/webapp/static/fonts/`

---

## 📂 项目结构

```
Second-hand_auction_system/
├── pom.xml                                ← Maven 依赖（MyBatis / Servlet / JSP / JSTL）
├── docs/                                  ← 设计文档（本地参考，gitignore）
│   ├── ddl.sql                            ← 13 张表的建表脚本
│   └── system_framework.html              ← 框架图（Mermaid 渲染版）
└── src/main/
    ├── java/org/example/
    │   ├── entity/                        ← 13 个实体（User / AuctionItem / OrderInfo / ...）
    │   ├── mapper/                        ← 14 个 MyBatis Mapper 接口
    │   ├── service/                       ← 业务服务（AuctionEndService 自动结束拍卖 等）
    │   ├── servlet/                       ← 19 个 Servlet（用户 / 拍品 / 订单 / 管理 / ...）
    │   ├── filter/                        ← 字符编码 / 登录鉴权 / 管理员鉴权
    │   └── util/                          ← MyBatisUtil / PasswordUtil / ResponseUtil / EscapeUtil
    ├── resources/
    │   ├── db.properties                  ← 数据库连接（本地，gitignore）
    │   ├── mybatis-config.xml
    │   └── org/example/mapper/            ← 14 个 SQL 映射 XML
    └── webapp/
        ├── index.jsp                      ← 首页（分类色块 / Hero / 推荐 / 热搜）
        ├── static/                        ← css / js / 字体（字体本地放）
        └── WEB-INF/
            ├── web.xml
            └── jsp/
                ├── user/                  ← 登录 / 注册 / 个人中心
                ├── item/                  ← 列表 / 详情 / 发布 / 编辑 / 我的 / 结果
                ├── order/                 ← 订单列表 / 详情
                ├── credit/                ← 积分流水
                ├── complaint/             ← 投诉
                ├── favorite/              ← 收藏
                ├── message/               ← 站内信
                ├── address/               ← 收货地址
                └── admin/                 ← 管理后台（用户 / 拍品 / 申诉 / 退款 / 分类 / 公告 / 统计）
```

---

## ✅ 验证项目跑通

启动后浏览器应该看到：

1. **首页**：顶部公告 banner + 8 个一级分类色块 + Hero 主推拍品 + 推荐商品瀑布流 + 热搜词
2. **点 "测试 MyBatis 连通"**（`/hello`）：看到 `user` 表里的数据
3. **个人中心**（登录后 `/user/center`）：能看到「我发布的拍品 / 我的订单 / 收藏 / 积分 / 站内信」5 个 tab
4. **管理员后台**（`/admin/login`，`admin` / `123456`）：看到统计概览（用户 / 拍品 / 订单 / GMV）

---

## 🛠 技术栈

| 层 | 技术 |
|---|---|
| 后端 | Java 21 + JSP / Servlet（Java EE 8，`javax.*`）+ MyBatis 3 |
| 前端 | JSP + Vue 3（global prod build）+ Axios + 原生 CSS（无 Tailwind / 无打包） |
| 数据库 | MySQL 8.x |
| 服务器 | Tomcat 9 |
| 构建 | Maven |

---

## 🆘 常见问题

| 问题 | 解决 |
|---|---|
| 启动报 `java.lang.NoClassDefFoundError: jakarta/servlet/...` | 你用了 Tomcat 11，把 `pom.xml` 改成 `jakarta.servlet-api 5.0.0` |
| 中文乱码 | 检查 `EncodingFilter` 是否生效，JSP 顶部有没有 `<%@ page contentType="text/html;charset=UTF-8" %>` |
| 首页中文是方框 / 默认字体 | 没装字体（见上方 "字体说明" 章节），业务功能不受影响 |
| `Communications link failure` | MySQL 没启动，或 `db.properties` 密码错了 |
| `Access denied for user 'root'` | `db.properties` 密码不对 |
| Maven 依赖下载慢 | 配置 IDEA 的 Maven 国内镜像（阿里云） |

---

## 📜 License

仅供学习交流。