-- ================================================================
--  二手物品拍卖系统 · 数据库初始化脚本
--  MySQL 8.0+ / utf8mb4 / InnoDB
--  说明：所有金额 DECIMAL(10,2)，时间 DATETIME，主键统一为 id
--  执行方式：source ddl.sql;   或   mysql -uroot -p < ddl.sql
-- ================================================================

DROP DATABASE IF EXISTS `auction_db`;
CREATE DATABASE `auction_db`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE `auction_db`;

-- ================================================================
-- 1. user：用户表（统一身份：买家 + 卖家）
-- ================================================================
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
    `id`              INT            NOT NULL AUTO_INCREMENT        COMMENT '用户ID',
    `username`        VARCHAR(30)    NOT NULL                       COMMENT '用户名',
    `password`        VARCHAR(64)    NOT NULL                       COMMENT '密码(SHA-256)',
    `phone`           VARCHAR(11)    DEFAULT NULL                   COMMENT '手机号',
    `email`           VARCHAR(50)    DEFAULT NULL                   COMMENT '邮箱',
    `real_name`       VARCHAR(20)    DEFAULT NULL                   COMMENT '真实姓名',
    `id_card`         VARCHAR(18)    DEFAULT NULL                   COMMENT '身份证号',
    `avatar`          VARCHAR(255)   DEFAULT NULL                   COMMENT '头像URL',
    `credit_score`    INT            NOT NULL DEFAULT 100           COMMENT '信用分 默认100',
    `balance`         DECIMAL(10,2)  NOT NULL DEFAULT 0.00          COMMENT '账户余额',
    `status`          TINYINT        NOT NULL DEFAULT 0             COMMENT '0正常 1已封禁',
    `register_time`   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `last_login_time` DATETIME       DEFAULT NULL                   COMMENT '最近登录',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- ================================================================
-- 2. admin：管理员表
-- ================================================================
DROP TABLE IF EXISTS `admin`;
CREATE TABLE `admin` (
    `id`              INT          NOT NULL AUTO_INCREMENT      COMMENT '管理员ID',
    `admin_account`   VARCHAR(30)  NOT NULL                     COMMENT '登录账号',
    `admin_password`  VARCHAR(64)  NOT NULL                     COMMENT '密码(SHA-256)',
    `admin_name`      VARCHAR(20)  NOT NULL                     COMMENT '姓名',
    `role`            VARCHAR(20)  NOT NULL DEFAULT 'admin'    COMMENT 'super / admin',
    `status`          TINYINT      NOT NULL DEFAULT 0           COMMENT '0启用 1停用',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `last_login_time` DATETIME     DEFAULT NULL                 COMMENT '最近登录',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_admin_account` (`admin_account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='管理员表';

-- ================================================================
-- 3. category：拍品分类表（支持二级分类）
-- ================================================================
DROP TABLE IF EXISTS `category`;
CREATE TABLE `category` (
    `id`            INT          NOT NULL AUTO_INCREMENT          COMMENT '分类ID',
    `category_name` VARCHAR(20)  NOT NULL                         COMMENT '分类名',
    `parent_id`     INT          NOT NULL DEFAULT 0               COMMENT '父分类ID 0为一级',
    `sort_order`    INT          NOT NULL DEFAULT 0               COMMENT '排序号',
    `icon`          VARCHAR(255) DEFAULT NULL                     COMMENT '图标URL',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='拍品分类表';

-- ================================================================
-- 4. auction_item：拍品表（核心）
-- ================================================================
DROP TABLE IF EXISTS `auction_item`;
CREATE TABLE `auction_item` (
    `id`              INT            NOT NULL AUTO_INCREMENT          COMMENT '拍品ID',
    `seller_id`       INT            NOT NULL                         COMMENT '卖家ID',
    `category_id`     INT            NOT NULL                         COMMENT '分类ID',
    `title`           VARCHAR(100)   NOT NULL                         COMMENT '标题',
    `description`     TEXT           NOT NULL                         COMMENT '详细描述',
    `brand`           VARCHAR(50)    DEFAULT NULL                     COMMENT '品牌',
    `model`           VARCHAR(50)    DEFAULT NULL                     COMMENT '型号',
    `condition_level` VARCHAR(20)    NOT NULL DEFAULT '9成新'         COMMENT '新旧程度',
    `flaw_desc`       VARCHAR(255)   DEFAULT NULL                     COMMENT '瑕疵说明',
    `cover_image`     VARCHAR(255)   DEFAULT NULL                     COMMENT '封面图',
    `image_urls`      TEXT           DEFAULT NULL                     COMMENT '多图JSON数组',
    `start_price`     DECIMAL(10,2)  NOT NULL                         COMMENT '起拍价',
    `current_price`   DECIMAL(10,2)  NOT NULL                         COMMENT '当前最高价',
    `bid_increment`   DECIMAL(10,2)  NOT NULL DEFAULT 1.00            COMMENT '加价幅度',
    `reserve_price`   DECIMAL(10,2)  DEFAULT NULL                     COMMENT '保留价(可选)',
    `start_time`      DATETIME       NOT NULL                         COMMENT '拍卖开始时间',
    `end_time`        DATETIME       NOT NULL                         COMMENT '拍卖结束时间',
    `status`          TINYINT        NOT NULL DEFAULT 0               COMMENT '0待审核 1拍卖中 2已成交 3已流拍 4已下架 5审核未通过',
    `view_count`      INT            NOT NULL DEFAULT 0               COMMENT '浏览次数',
    `create_time`     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    `update_time`     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_seller_id` (`seller_id`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_status` (`status`),
    KEY `idx_end_time` (`end_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='拍品表';

-- ================================================================
-- 5. bid_record：出价记录表（核心）
-- ================================================================
DROP TABLE IF EXISTS `bid_record`;
CREATE TABLE `bid_record` (
    `id`          INT            NOT NULL AUTO_INCREMENT            COMMENT '出价ID',
    `item_id`     INT            NOT NULL                           COMMENT '拍品ID',
    `bidder_id`   INT            NOT NULL                           COMMENT '出价人ID',
    `bid_amount`  DECIMAL(10,2)  NOT NULL                           COMMENT '出价金额',
    `is_winning`  TINYINT        NOT NULL DEFAULT 0                 COMMENT '是否当前最高 0否 1是',
    `is_proxy`    TINYINT        NOT NULL DEFAULT 0                 COMMENT '是否代理出价 0否 1是',
    `bid_time`    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '出价时间',
    PRIMARY KEY (`id`),
    KEY `idx_item_id` (`item_id`),
    KEY `idx_bidder_id` (`bidder_id`),
    KEY `idx_item_amount` (`item_id`, `bid_amount` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='出价记录表';

-- ================================================================
-- 6. watch_list：收藏/关注表
-- ================================================================
DROP TABLE IF EXISTS `watch_list`;
CREATE TABLE `watch_list` (
    `id`        INT      NOT NULL AUTO_INCREMENT                  COMMENT '收藏ID',
    `user_id`   INT      NOT NULL                                 COMMENT '用户ID',
    `item_id`   INT      NOT NULL                                 COMMENT '拍品ID',
    `add_time`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP       COMMENT '收藏时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_item` (`user_id`, `item_id`),
    KEY `idx_item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收藏关注表';

-- ================================================================
-- 7. address：收货地址表
-- ================================================================
DROP TABLE IF EXISTS `address`;
CREATE TABLE `address` (
    `id`              INT          NOT NULL AUTO_INCREMENT        COMMENT '地址ID',
    `user_id`         INT          NOT NULL                       COMMENT '用户ID',
    `receiver_name`   VARCHAR(20)  NOT NULL                       COMMENT '收货人',
    `receiver_phone`  VARCHAR(11)  NOT NULL                       COMMENT '收货人电话',
    `province`        VARCHAR(20)  NOT NULL                       COMMENT '省',
    `city`            VARCHAR(20)  NOT NULL                       COMMENT '市',
    `district`        VARCHAR(20)  NOT NULL                       COMMENT '区/县',
    `detail_address`  VARCHAR(100) NOT NULL                       COMMENT '详细地址',
    `is_default`      TINYINT      NOT NULL DEFAULT 0             COMMENT '是否默认 0否 1是',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收货地址表';

-- ================================================================
-- 8. order_info：订单表（避免与 SQL 关键字 order 冲突）
-- ================================================================
DROP TABLE IF EXISTS `order_info`;
CREATE TABLE `order_info` (
    `id`                 INT            NOT NULL AUTO_INCREMENT             COMMENT '订单ID',
    `order_no`           VARCHAR(32)    NOT NULL                            COMMENT '订单号(UUID)',
    `item_id`            INT            NOT NULL                            COMMENT '拍品ID',
    `item_title`         VARCHAR(100)   NOT NULL                            COMMENT '拍品标题(快照)',
    `cover_image`        VARCHAR(255)   DEFAULT NULL                        COMMENT '封面图(快照)',
    `buyer_id`           INT            NOT NULL                            COMMENT '买家ID',
    `seller_id`          INT            NOT NULL                            COMMENT '卖家ID',
    `final_price`        DECIMAL(10,2)  NOT NULL                            COMMENT '成交价',
    `address_id`         INT            NOT NULL                            COMMENT '收货地址ID',
    `status`             TINYINT        NOT NULL DEFAULT 0                  COMMENT '0待付款 1已付款 2已发货 3已收货 4申请退款 5已退款 6已取消',
    `pay_time`           DATETIME       DEFAULT NULL                        COMMENT '付款时间',
    `deliver_time`       DATETIME       DEFAULT NULL                        COMMENT '发货时间',
    `receive_time`       DATETIME       DEFAULT NULL                        COMMENT '收货时间',
    `logistics_company`  VARCHAR(50)    DEFAULT NULL                        COMMENT '物流公司',
    `tracking_number`    VARCHAR(50)    DEFAULT NULL                        COMMENT '物流单号',
    `create_time`        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '下单时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_no` (`order_no`),
    KEY `idx_buyer_id` (`buyer_id`),
    KEY `idx_seller_id` (`seller_id`),
    KEY `idx_item_id` (`item_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单表';

-- ================================================================
-- 9. message：消息通知表
-- ================================================================
DROP TABLE IF EXISTS `message`;
CREATE TABLE `message` (
    `id`          INT          NOT NULL AUTO_INCREMENT             COMMENT '消息ID',
    `user_id`     INT          NOT NULL                            COMMENT '接收用户ID',
    `type`        TINYINT      NOT NULL                            COMMENT '1中标 2出价被超越 3拍卖开始 4即将结束 5订单状态 6审核结果 7系统公告',
    `title`       VARCHAR(100) NOT NULL                            COMMENT '消息标题',
    `content`     VARCHAR(500) NOT NULL                            COMMENT '消息内容',
    `related_id`  INT          DEFAULT NULL                        COMMENT '关联业务ID',
    `is_read`     TINYINT      NOT NULL DEFAULT 0                  COMMENT '0未读 1已读',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '发送时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_is_read` (`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息通知表';

-- ================================================================
-- 10. notice：系统公告表
-- ================================================================
DROP TABLE IF EXISTS `notice`;
CREATE TABLE `notice` (
    `id`          INT          NOT NULL AUTO_INCREMENT             COMMENT '公告ID',
    `admin_id`    INT          NOT NULL                            COMMENT '发布管理员ID',
    `title`       VARCHAR(100) NOT NULL                            COMMENT '公告标题',
    `content`     TEXT         NOT NULL                            COMMENT '公告内容',
    `is_top`      TINYINT      NOT NULL DEFAULT 0                  COMMENT '是否置顶 0否 1是',
    `status`      TINYINT      NOT NULL DEFAULT 1                  COMMENT '0草稿 1已发布 2已撤回',
    `publish_time` DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '发布时间',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP  COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_admin_id` (`admin_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统公告表';

-- ================================================================
-- 11. credit_record：信用评价表（交易后互评）
-- ================================================================
DROP TABLE IF EXISTS `credit_record`;
CREATE TABLE `credit_record` (
    `id`            INT          NOT NULL AUTO_INCREMENT              COMMENT '评价ID',
    `order_id`      INT          NOT NULL                             COMMENT '订单ID',
    `evaluator_id`  INT          NOT NULL                             COMMENT '评价人ID',
    `target_id`     INT          NOT NULL                             COMMENT '被评价人ID',
    `role`          TINYINT      NOT NULL                             COMMENT '1买家评价卖家 2卖家评价买家',
    `score`         TINYINT      NOT NULL                             COMMENT '评分1-5',
    `content`       VARCHAR(500) DEFAULT NULL                         COMMENT '评价内容',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP   COMMENT '评价时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_evaluator` (`order_id`, `evaluator_id`),
    KEY `idx_target_id` (`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='信用评价表';

-- ================================================================
-- 12. complaint：投诉表
-- ================================================================
DROP TABLE IF EXISTS `complaint`;
CREATE TABLE `complaint` (
    `id`             INT          NOT NULL AUTO_INCREMENT              COMMENT '投诉ID',
    `order_id`       INT          NOT NULL                             COMMENT '关联订单ID',
    `complainant_id` INT          NOT NULL                             COMMENT '投诉人ID',
    `respondent_id`  INT          NOT NULL                             COMMENT '被投诉人ID',
    `reason`         VARCHAR(500) NOT NULL                             COMMENT '投诉原因',
    `evidence`       VARCHAR(500) DEFAULT NULL                         COMMENT '证据图片URL',
    `status`         TINYINT      NOT NULL DEFAULT 0                   COMMENT '0待处理 1处理中 2已处理 3已驳回',
    `handler_id`     INT          DEFAULT NULL                         COMMENT '处理管理员ID',
    `handle_result`  VARCHAR(500) DEFAULT NULL                         COMMENT '处理结果',
    `create_time`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP   COMMENT '投诉时间',
    `handle_time`    DATETIME     DEFAULT NULL                         COMMENT '处理时间',
    PRIMARY KEY (`id`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='投诉表';

-- ================================================================
-- 13. item_image：拍品图片表（也可直接用 auction_item.image_urls JSON）
-- 单独建表更便于多图管理，按需启用
-- ================================================================
DROP TABLE IF EXISTS `item_image`;
CREATE TABLE `item_image` (
    `id`        INT          NOT NULL AUTO_INCREMENT            COMMENT '图片ID',
    `item_id`   INT          NOT NULL                           COMMENT '拍品ID',
    `image_url` VARCHAR(255) NOT NULL                           COMMENT '图片URL',
    `sort_order` INT         NOT NULL DEFAULT 0                 COMMENT '排序',
    PRIMARY KEY (`id`),
    KEY `idx_item_id` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='拍品图片表';

-- ================================================================
-- 初始数据：管理员账号 (admin / 123456)  - 首次登录请改密码
-- ================================================================
-- SHA-256 of "123456" = 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92
INSERT INTO `admin` (`admin_account`, `admin_password`, `admin_name`, `role`) VALUES
('admin', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '超级管理员', 'super');

-- 初始分类数据
INSERT INTO `category` (`category_name`, `parent_id`, `sort_order`) VALUES
('数码电子', 0, 1),
('服饰鞋帽', 0, 2),
('图书音像', 0, 3),
('家居生活', 0, 4),
('运动户外', 0, 5),
('美妆护肤', 0, 6),
('其他',     0, 99);

-- 测试用户 (test / 123456) - 密码 SHA-256
INSERT INTO `user` (`username`, `password`, `phone`, `email`, `balance`) VALUES
('test',  '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '13800138000', 'test@example.com', 1000.00),
('alice', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '13800138001', 'alice@example.com', 5000.00),
('bob',   '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '13800138002', 'bob@example.com',   3000.00);

-- ================================================================
-- 验证：列出所有表
-- ================================================================
SHOW TABLES;