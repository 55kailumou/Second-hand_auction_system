# 二手物品拍卖系统 · 进度总结 & 接力文档

> 写给新窗口的 Mavis：读这份文件能 30 秒内进入状态。

---

## 🎯 项目一句话

**Java Web 期末实训项目** · 二手物品拍卖系统 · **JSP + Servlet + MyBatis + MySQL** · Tomcat 9 · Java 21 · Vue 3 (CDN, 嵌入 JSP)

## 📍 工作目录

```
E:\01_CodeProjects\02_PersonalProjects\Second-hand_auction_system
```

## 🔗 远程仓库

```
https://github.com/55kailumou/Second-hand_auction_system.git
```

## ✅ 已完成的工作

### 1. 需求 & 设计
- [x] 读了原始项目模板（四大刺绣 → 改造成二手拍卖）
- [x] 优化版功能框架图：`docs/auction_system_function_graph.drawio`（用 drawio 画）
- [x] 数据库设计：13 张表 DDL 脚本：`docs/ddl.sql`
- [x] 项目开发流程规划（5 阶段）

### 2. 技术栈定稿
| 层 | 技术 |
|---|---|
| 后端语言 | Java 21 |
| Web 框架 | Servlet 4.0（`javax.*`） + JSP 2.3 + JSTL 1.2 |
| ORM | MyBatis 3.5.16 |
| 数据库 | MySQL 8.0 |
| Web 容器 | Tomcat 9.0（注意是 9，不是 11） |
| 前端增强 | Vue 3 (CDN, 嵌入 JSP) + Element-UI 风格 + axios |
| 构建 | Maven 3.x |
| IDE | IDEA Ultimate 2025.2 |

### 3. 项目骨架（已跑通 ✅）
- Maven `pom.xml`：含 javax.servlet / MyBatis / JSTL / Jackson
- 配置：`db.properties`（被 git ignore）、`mybatis-config.xml`、`web.xml`
- 工具类：`MyBatisUtil`、`PasswordUtil`（SHA-256 加密）
- Filter：`EncodingFilter`（统一 UTF-8）、`AuthFilter`（登录拦截）
- 公共资源：`static/css/common.css`、`static/js/common.js`（Vue 加载器 + Toast + 工具函数）
- 欢迎页：`index.jsp`（顶部导航 + Hero 搜索 + 用户面板）

### 4. 用户注册/登录模块 ✅
- `entity/User.java`、`mapper/UserMapper.java` + XML（含 `findByUsername`、`findByPhone`、`login`、`insert`、`countAll`、`findAll`）
- `servlet/UserServlet.java`：统一处理 login/register/logout/check-username/check-phone
- 视图：`login.jsp`（用户名/手机号两种登录方式）、`register.jsp`（实时校验 + AJAX 查重）

### 5. Git 仓库
- 本地 commit 2 个：
  - `55ec9ae` feat: 初始化项目骨架与用户注册/登录模块
  - `c916301` chore: 移除 db.properties 追踪，使用 .example 模板管理敏感配置
- 远端分支：master（**第一次 push 我这边成功了，第二次 push 因为网络问题失败，用户在 IDEA 里手动 push 即可**）

---

## 📂 项目目录（关键文件）

```
Second-hand_auction_system/
├── pom.xml                                   # Maven 依赖
├── README.md                                  # 项目运行指南
├── .gitignore                                 # 含 db.properties 等敏感配置
├── docs/
│   ├── ddl.sql                                # 13 张表建表脚本
│   ├── auction_system_function_graph.drawio  # 功能图（drawio）
│   ├── auction_system_function_graph2.drawio # 功能图 v2（用户改的）
│   ├── system_framework.html                  # Mermaid 渲染版
│   ├── 二手房.docx                             # 原始模板
│   ├── Snipaste_2026-06-22_15-22-47.png      # 骨架跑通截图
│   └── PROGRESS.md                            # ⭐ 本文件（接力文档）
└── src/main/
    ├── java/org/example/
    │   ├── entity/User.java                   # 用户实体（13 个实体待补）
    │   ├── mapper/UserMapper.java             # MyBatis Mapper 接口
    │   ├── servlet/{Hello,User}Servlet.java   # Servlet 控制器
    │   ├── filter/{Encoding,Auth}Filter.java  # 过滤器
    │   └── util/{MyBatis,Password}Util.java   # 工具类
    ├── resources/
    │   ├── db.properties                      # ⚠️ git ignore，本地配
    │   ├── db.properties.example              # ⭐ 团队模板（git 追踪）
    │   ├── mybatis-config.xml
    │   └── org/example/mapper/UserMapper.xml  # SQL 映射
    └── webapp/
        ├── index.jsp                          # 欢迎页（Vue 增强）
        ├── static/{css/common.css, js/common.js}
        └── WEB-INF/
            ├── web.xml                        # 注册 Filter 顺序
            └── jsp/
                ├── hello.jsp                  # MyBatis 测试页
                ├── error.jsp
                └── user/{login,register}.jsp # 用户模块
```

---

## 🚦 当前状态

| 项 | 状态 |
|---|---|
| 项目骨架 | ✅ 跑通 |
| 用户注册/登录 | ✅ 跑通 |
| 数据库 | ✅ 13 张表已建好 |
| 远程仓库 | ⚠️ 第一次 push 成功，第二次 push 待用户在 IDEA 里手动 push |
| `db.properties` 编码 | ⚠️ IDEA 缓存了旧的中文版本，需要 Reload from Disk 看新英文版 |

---

## 🎯 下一步要做（按优先级）

### 阶段 1 Day 2：拍品模块（🔴 最优先）
按"4 层循环"开发：
1. **entity/AuctionItem.java** - 拍品实体（对应 `auction_item` 表）
2. **entity/Category.java** - 分类实体
3. **entity/BidRecord.java** - 出价记录实体
4. **mapper/{AuctionItem,Category,BidRecord}Mapper.java + XML** - SQL
5. **servlet/{Item,Category,Bid}Servlet.java** - 控制器
6. **jsp/item/list.jsp** - 拍品列表（Vue 分页 + 筛选 + 排序）
7. **jsp/item/detail.jsp** - 拍品详情（Vue 出价 + 倒计时 + 出价历史）
8. **jsp/item/publish.jsp** - 发布拍品（Vue 表单 + 图片上传）

### 阶段 1 Day 3-4：订单模块
- entity/OrderInfo.java、Address.java
- mapper、servlet、jsp

### 阶段 1 Day 4：个人中心首页
- entity（剩余的）
- jsp/user/center.jsp

### 阶段 2：业务扩展（收藏、消息、评价、投诉）
### 阶段 3：管理后台
### 阶段 4：UI 美化
### 阶段 5：测试 & 文档

---

## 📋 重要的开发约定（保持一致）

1. **包结构**：`org.example.{entity,mapper,servlet,filter,util}`
2. **类命名**：`XxxServlet`、`XxxMapper`、`XxxDao`(不用)、`XxxEntity`(不用)、`XxxUtil`
3. **Mapper 接口 + XML 一一对应**：接口名 = XML namespace，方法名 = SQL id
4. **JSP 路径**：私有 JSP 放 `WEB-INF/jsp/`，按模块分子目录（如 `user/`、`item/`、`order/`、`admin/`）
5. **静态资源**：`webapp/static/{css,js,img}/`
6. **Session 键**：`currentUser`（用户对象）、`cart`（购物车，暂未用）
7. **JSP 传数据给 Vue**：
   ```jsp
   <%= listJson %>   <!-- Servlet 端用 ObjectMapper 转 -->
   ```
8. **AJAX 异步检查**：URL `/user?action=check-username&username=xxx`，返回 `{exists, available, message}`
9. **密码加密**：用 `PasswordUtil.encrypt()` SHA-256，数据库存密文
10. **字符编码**：EncodingFilter 已统一 UTF-8，JSP 顶部必须有 `<%@ page contentType="text/html;charset=UTF-8" %>`

---

## ⚠️ 容易踩的坑

1. **MySQL 8.0 必须加 `allowPublicKeyRetrieval=true`** 到 JDBC URL（已加）
2. **Tomcat 9 用 `javax.*`，Tomcat 10/11 用 `jakarta.*`**（我们用 9，所以 javax）
3. **`order` 是 SQL 关键字** → 订单表叫 `order_info`
4. **并发出价要用乐观锁**：`UPDATE auction_item SET current_price=? WHERE id=? AND current_price<?`
5. **拍卖结束时间**：建议在 Servlet 入口检查 `end_time` 是否到期（不依赖定时任务）
6. **Filter 顺序**：web.xml 里先 EncodingFilter 后 AuthFilter（已配）
7. **`.properties` 文件别用中文**，用英文注释（避免 IDEA 编码坑）
8. **不要把 db.properties 推到 git**（已在 .gitignore）

---

## 🔄 启动 / 部署命令速查

```bash
# 1. 启动 MySQL（已开）
# 2. IDEA 配置 Tomcat 9 → 启动
# 3. 浏览器访问：
#    首页:           http://localhost:8080/Second_hand_auction_system_war/
#    登录:           http://localhost:8080/Second_hand_auction_system_war/user?action=login
#    MyBatis 测试:   http://localhost:8080/Second_hand_auction_system_war/hello

# 4. 团队成员 clone 后：
cp src/main/resources/db.properties.example src/main/resources/db.properties
# 编辑 db.properties 填密码
```

---

## 📌 新窗口的 Mavis 要做什么

新窗口的 Mavis，**第一步读这个文件**，然后告诉用户：

> "读完接力文档了。当前状态：项目骨架 + 用户注册/登录跑通，下一步应该开发拍品模块（entity + mapper + servlet + jsp 四件套）。是按计划继续，还是你想调整方向？"

---

**最后更新时间**：2026-06-22 16:50
**最后 commit**：`c916301` chore: 移除 db.properties 追踪，使用 .example 模板管理敏感配置（未 push 到远程）