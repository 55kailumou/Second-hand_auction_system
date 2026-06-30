package org.example.service;

import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.Deposit;
import org.example.entity.OrderInfo;
import org.example.entity.PaymentRecord;
import org.example.entity.SystemAccount;
import org.example.entity.User;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.DepositMapper;
import org.example.mapper.OrderMapper;
import org.example.mapper.PaymentRecordMapper;
import org.example.mapper.SystemAccountMapper;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * 支付服务（核心·所有资金流集中在这里）
 *
 * 职责：
 *   - 押金缴纳（payDeposit）
 *   - 押金退还（refundDeposit）
 *   - 押金转货款（depositToFinal，用于中标后抵货款）
 *   - 尾款支付（payFinal，标 order.status 0→1 + 平台账户+）
 *   - 平台打款给卖家（settleToSeller，标 order.status 2→3 + settled_time + 平台账户- → 卖家余额+）
 *   - 平台退款给买家（refundToBuyer）
 *   - 余额查询 / 平台账户查询
 *
 * 设计原则：
 *   1. 所有"扣 A 加 B"放在同一个 SqlSession 事务里
 *   2. 用户/平台余额变动用 MyBatis 的原子 SQL（CAS），按 affected rows 判断成败
 *   3. 每次变动都写一条 payment_record 流水（审计可追溯）
 *   4. 不在这里做"业务校验"（如订单状态是否正确），那是 Servlet 的事
 */
public class PayService {

    // ============ 押金（缴/退/转） ============

    /**
     * 缴纳押金（拍前必交）
     * @param userId  缴纳人
     * @param itemId  拍品 ID
     * @param method  支付方式 balance / alipay / wechat
     * @return Map: { success, message, depositId, balanceAfter }
     */
    public static Map<String, Object> payDeposit(Integer userId, Integer itemId, String method) {
        Map<String, Object> result = new HashMap<>();
        if (userId == null || itemId == null) {
            result.put("success", false);
            result.put("message", "参数错误");
            return result;
        }
        if (method == null) method = "balance";
        if (!"balance".equals(method) && !"alipay".equals(method) && !"wechat".equals(method)) {
            result.put("success", false);
            result.put("message", "支付方式不支持");
            return result;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper userMapper = session.getMapper(UserMapper.class);
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            DepositMapper depositMapper = session.getMapper(DepositMapper.class);
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);

            // 1. 拍品存在 + 在拍中
            AuctionItem item = itemMapper.findById(itemId);
            if (item == null) {
                result.put("success", false); result.put("message", "拍品不存在"); return result;
            }
            if (item.getStatus() == null || item.getStatus() != 1) {
                result.put("success", false); result.put("message", "该拍品当前不在拍卖中"); return result;
            }

            // 2. 押金金额
            BigDecimal amount = item.getDeposit();
            if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
                result.put("success", false); result.put("message", "该拍品无需押金"); return result;
            }

            // 3. 不能重复缴纳
            Deposit exists = depositMapper.findByUserAndItem(userId, itemId);
            if (exists != null && exists.getStatus() != null) {
                if (exists.getStatus() == 0) {
                    result.put("success", false); result.put("message", "您已缴纳过押金"); return result;
                }
                if (exists.getStatus() == 1) {
                    result.put("success", false); result.put("message", "您的押金已转为货款"); return result;
                }
            }

            // 4. 余额支付 → 扣用户余额
            BigDecimal balanceAfter = null;
            if ("balance".equals(method)) {
                int rows = userMapper.subtractBalance(userId, amount);
                if (rows == 0) {
                    result.put("success", false); result.put("message", "余额不足，请先充值或换用其他支付方式");
                    return result;
                }
                User u = userMapper.findById(userId);
                balanceAfter = u == null ? null : u.getBalance();
            }
            // alipay / wechat：模拟支付，不动用户余额（直接记"平台代收"）

            // 5. 写 user_deposit
            Deposit d = new Deposit();
            d.setUserId(userId);
            d.setItemId(itemId);
            d.setAmount(amount);
            d.setStatus(0);
            d.setPayMethod(method);
            d.setPayTime(LocalDateTime.now());
            d.setRemark("缴纳参拍押金");
            depositMapper.insert(d);

            // 6. 写流水
            PaymentRecord pr = new PaymentRecord();
            pr.setUserId(userId);
            pr.setUserRole("payer");
            pr.setType(1);   // 1 押金缴纳
            pr.setAmount(amount.negate());  // 支出记负
            pr.setMethod(method);
            pr.setItemId(itemId);
            pr.setBalanceAfter(balanceAfter);
            pr.setRemark("缴纳拍品《" + (item.getTitle() == null ? "" : item.getTitle()) + "》参拍押金");
            pr.setCreateTime(LocalDateTime.now());
            prMapper.insert(pr);

            session.commit();

            result.put("success", true);
            result.put("message", "押金缴纳成功");
            result.put("depositId", d.getId());
            result.put("balanceAfter", balanceAfter);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "押金缴纳失败：" + e.getMessage());
            return result;
        }
    }

    /**
     * 退还押金（未中标者拍卖结束后调用 / 或手动退还）
     * @param depositId 押金记录 ID
     * @param reason    退还原因
     * @return Map: { success, message }
     */
    public static Map<String, Object> refundDeposit(Integer depositId, String reason) {
        Map<String, Object> result = new HashMap<>();
        if (depositId == null) {
            result.put("success", false); result.put("message", "参数错误"); return result;
        }
        try (SqlSession session = MyBatisUtil.openSession()) {
            DepositMapper depositMapper = session.getMapper(DepositMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);

            Deposit d = depositMapper.findById(depositId);
            if (d == null) { result.put("success", false); result.put("message", "押金记录不存在"); return result; }
            if (d.getStatus() != null && d.getStatus() != 0) {
                result.put("success", false); result.put("message", "该押金状态不可退（已转货款/已退/已没收）");
                return result;
            }

            BigDecimal amount = d.getAmount();
            String remark = (reason == null || reason.isEmpty()) ? "拍卖未中标，押金退还" : reason;

            // 1. 更新押金状态 0→2
            int rows = depositMapper.markRefunded(depositId, remark);
            if (rows == 0) {
                result.put("success", false); result.put("message", "押金状态已变化，请刷新后重试");
                return result;
            }

            // 2. 退到余额（统一退到余额，便于用户使用）
            userMapper.addBalance(d.getUserId(), amount);
            User u = userMapper.findById(d.getUserId());
            BigDecimal balanceAfter = u == null ? null : u.getBalance();

            // 3. 写流水
            PaymentRecord pr = new PaymentRecord();
            pr.setUserId(d.getUserId());
            pr.setUserRole("receiver");
            pr.setType(2);   // 2 押金退还
            pr.setAmount(amount);   // 收入记正
            pr.setMethod("balance");
            pr.setItemId(d.getItemId());
            pr.setBalanceAfter(balanceAfter);
            pr.setRemark(remark);
            pr.setCreateTime(LocalDateTime.now());
            prMapper.insert(pr);

            session.commit();

            result.put("success", true);
            result.put("message", "押金已退还 ¥" + amount.toPlainString());
            result.put("balanceAfter", balanceAfter);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "退还失败：" + e.getMessage());
            return result;
        }
    }

    /**
     * 押金转货款（中标的拍品，押金自动抵货款的一部分）
     * 平台账户 += amount，user_deposit.status 0→1
     *
     * 调用时机：拍卖结束中标时（由 AuctionEndService 调用）
     */
    public static Map<String, Object> depositToFinal(Integer depositId, String orderNo) {
        Map<String, Object> result = new HashMap<>();
        if (depositId == null) {
            result.put("success", false); result.put("message", "参数错误"); return result;
        }
        try (SqlSession session = MyBatisUtil.openSession()) {
            DepositMapper depositMapper = session.getMapper(DepositMapper.class);
            SystemAccountMapper saMapper = session.getMapper(SystemAccountMapper.class);
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);

            Deposit d = depositMapper.findById(depositId);
            if (d == null) { result.put("success", false); result.put("message", "押金记录不存在"); return result; }
            if (d.getStatus() != null && d.getStatus() != 0) {
                result.put("success", false); result.put("message", "该押金状态不可转（已转/已退/已没收）");
                return result;
            }

            BigDecimal amount = d.getAmount();
            String remark = "中标后押金转货款（订单 " + (orderNo == null ? "?" : orderNo) + "）";

            // 1. 押金状态 0→1
            int rows = depositMapper.markTransferred(depositId, orderNo, remark);
            if (rows == 0) {
                result.put("success", false); result.put("message", "押金状态已变化，请刷新后重试");
                return result;
            }

            // 2. 平台账户 += amount
            saMapper.addBalance(amount, remark);

            // 3. 取平台账户当前余额
            SystemAccount sa = saMapper.get();
            BigDecimal platformAfter = sa == null ? null : sa.getBalance();

            // 4. 写流水（用户侧·押金锁定结束）
            PaymentRecord pr = new PaymentRecord();
            pr.setUserId(d.getUserId());
            pr.setUserRole("payer");
            pr.setType(3);  // 3 押金转货款
            pr.setAmount(amount.negate());  // 用户的押金锁定结束
            pr.setMethod("platform");
            pr.setOrderNo(orderNo);
            pr.setItemId(d.getItemId());
            pr.setPlatformAfter(platformAfter);
            pr.setRemark(remark);
            pr.setCreateTime(LocalDateTime.now());
            prMapper.insert(pr);

            session.commit();

            result.put("success", true);
            result.put("message", "押金已转货款");
            result.put("platformAfter", platformAfter);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "押金转货款失败：" + e.getMessage());
            return result;
        }
    }

    // ============ 尾款支付 ============

    /**
     * 支付尾款（订单 status 0→1）
     * 余额支付：用户余额 -= finalPayAmount
     * 模拟支付（alipay/wechat）：不动用户余额，直接记"平台代收"
     * 平台账户 += finalPayAmount
     */
    public static Map<String, Object> payFinal(Integer orderId, String method) {
        Map<String, Object> result = new HashMap<>();
        if (orderId == null) { result.put("success", false); result.put("message", "参数错误"); return result; }
        if (method == null) method = "balance";

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);
            SystemAccountMapper saMapper = session.getMapper(SystemAccountMapper.class);
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);

            OrderInfo order = orderMapper.findById(orderId);
            if (order == null) { result.put("success", false); result.put("message", "订单不存在"); return result; }
            if (order.getStatus() == null || order.getStatus() != 0) {
                result.put("success", false); result.put("message", "订单当前状态不能支付"); return result;
            }
            BigDecimal finalPay = order.getFinalPayAmount();
            if (finalPay == null) finalPay = order.getFinalPrice();
            if (finalPay == null || finalPay.compareTo(BigDecimal.ZERO) < 0) finalPay = BigDecimal.ZERO;

            // 1. 余额支付：扣用户余额
            BigDecimal balanceAfter = null;
            if ("balance".equals(method)) {
                if (finalPay.compareTo(BigDecimal.ZERO) > 0) {
                    int rows = userMapper.subtractBalance(order.getBuyerId(), finalPay);
                    if (rows == 0) {
                        result.put("success", false); result.put("message", "余额不足，请先充值或换用其他支付方式");
                        return result;
                    }
                }
                User u = userMapper.findById(order.getBuyerId());
                balanceAfter = u == null ? null : u.getBalance();
            }
            // 模拟支付（alipay/wechat）：不动用户余额

            // 2. 平台账户 += finalPay
            if (finalPay.compareTo(BigDecimal.ZERO) > 0) {
                saMapper.addBalance(finalPay, "订单 " + order.getOrderNo() + " 尾款");
            }
            SystemAccount sa = saMapper.get();
            BigDecimal platformAfter = sa == null ? null : sa.getBalance();

            // 3. 更新订单 status 0→1 + 写支付方式
            int upd = orderMapper.markPaid(order.getId(), finalPay, method);
            if (upd == 0) {
                result.put("success", false); result.put("message", "订单状态已变化，请刷新后重试");
                return result;
            }

            // 4. 写流水（买家侧）
            PaymentRecord pr = new PaymentRecord();
            pr.setUserId(order.getBuyerId());
            pr.setUserRole("payer");
            pr.setType(4);  // 4 尾款支付
            pr.setAmount(finalPay.negate());
            pr.setMethod(method);
            pr.setOrderNo(order.getOrderNo());
            pr.setItemId(order.getItemId());
            pr.setBalanceAfter(balanceAfter);
            pr.setPlatformAfter(platformAfter);
            pr.setRemark("订单 " + order.getOrderNo() + " 支付尾款");
            pr.setCreateTime(LocalDateTime.now());
            prMapper.insert(pr);

            session.commit();

            result.put("success", true);
            result.put("message", "尾款支付成功");
            result.put("balanceAfter", balanceAfter);
            result.put("platformAfter", platformAfter);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "尾款支付失败：" + e.getMessage());
            return result;
        }
    }

    // ============ 平台打款给卖家（确认收货时） ============

    /**
     * 平台打款给卖家（订单 status 2→3 时调用）
     * 平台账户 -= finalPrice → 卖家余额 += finalPrice
     * 写 type=5 流水
     */
    public static Map<String, Object> settleToSeller(Integer orderId) {
        Map<String, Object> result = new HashMap<>();
        if (orderId == null) { result.put("success", false); result.put("message", "参数错误"); return result; }
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);
            SystemAccountMapper saMapper = session.getMapper(SystemAccountMapper.class);
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);

            OrderInfo order = orderMapper.findById(orderId);
            if (order == null) { result.put("success", false); result.put("message", "订单不存在"); return result; }
            if (order.getStatus() == null || order.getStatus() != 2) {
                result.put("success", false); result.put("message", "订单当前状态不能结算（应已发货）"); return result;
            }
            BigDecimal amount = order.getFinalPrice();
            if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
                result.put("success", false); result.put("message", "订单金额异常"); return result;
            }

            // 1. 平台账户 -amount（带防超扣）
            int subRows = saMapper.subtractBalance(amount, "订单 " + order.getOrderNo() + " 打款给卖家");
            if (subRows == 0) {
                result.put("success", false); result.put("message", "平台账户余额不足（异常），请联系管理员");
                return result;
            }

            // 2. 卖家余额 +amount
            userMapper.addBalance(order.getSellerId(), amount);
            User seller = userMapper.findById(order.getSellerId());
            BigDecimal sellerBalanceAfter = seller == null ? null : seller.getBalance();

            // 3. 更新订单 status 2→3 + 写 settled_time
            int upd = orderMapper.markReceived(order.getId());
            if (upd == 0) {
                result.put("success", false); result.put("message", "订单状态已变化，请刷新后重试");
                return result;
            }

            // 4. 取平台账户当前余额
            SystemAccount sa = saMapper.get();
            BigDecimal platformAfter = sa == null ? null : sa.getBalance();

            // 5. 写流水（卖家侧·收入）
            PaymentRecord pr = new PaymentRecord();
            pr.setUserId(order.getSellerId());
            pr.setUserRole("receiver");
            pr.setType(5);  // 5 平台打款
            pr.setAmount(amount);  // 收入正
            pr.setMethod("platform");
            pr.setOrderNo(order.getOrderNo());
            pr.setItemId(order.getItemId());
            pr.setBalanceAfter(sellerBalanceAfter);
            pr.setPlatformAfter(platformAfter);
            pr.setRemark("订单 " + order.getOrderNo() + " 买家确认收货，平台打款");
            pr.setCreateTime(LocalDateTime.now());
            prMapper.insert(pr);

            session.commit();

            result.put("success", true);
            result.put("message", "平台打款成功");
            result.put("sellerBalanceAfter", sellerBalanceAfter);
            result.put("platformAfter", platformAfter);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "打款失败：" + e.getMessage());
            return result;
        }
    }

    // ============ 平台退款给买家（管理员同意退款时） ============

    /**
     * 平台退款给买家
     * 分两种情况：
     *   1. 订单 status=1/2（已付款未收货）→ 平台账户 -= finalPrice → 买家余额 += finalPrice
     *   3. 订单 status=3（已确认收货，平台已打款）→ 卖家余额 -= finalPrice → 买家余额 += finalPrice
     *
     * @param orderId
     * @param auditResult 审核结果说明
     * @param refundedFromPlatform true=从平台账户出，false=从卖家账户出
     */
    public static Map<String, Object> refundToBuyer(Integer orderId, String auditResult, boolean refundedFromPlatform) {
        Map<String, Object> result = new HashMap<>();
        if (orderId == null) { result.put("success", false); result.put("message", "参数错误"); return result; }
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);
            SystemAccountMapper saMapper = session.getMapper(SystemAccountMapper.class);
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);

            OrderInfo order = orderMapper.findById(orderId);
            if (order == null) { result.put("success", false); result.put("message", "订单不存在"); return result; }
            if (order.getStatus() == null || order.getStatus() != 4) {
                result.put("success", false); result.put("message", "订单当前状态不能退款"); return result;
            }
            BigDecimal amount = order.getFinalPrice();
            if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
                result.put("success", false); result.put("message", "订单金额异常"); return result;
            }

            BigDecimal platformAfter = null;
            if (refundedFromPlatform) {
                int subRows = saMapper.subtractBalance(amount, "订单 " + order.getOrderNo() + " 退款");
                if (subRows == 0) {
                    result.put("success", false); result.put("message", "平台账户余额不足（异常），请联系管理员");
                    return result;
                }
                SystemAccount sa = saMapper.get();
                platformAfter = sa == null ? null : sa.getBalance();
            } else {
                int subRows = userMapper.subtractBalance(order.getSellerId(), amount);
                if (subRows == 0) {
                    result.put("success", false); result.put("message", "卖家余额不足，请联系管理员");
                    return result;
                }
            }

            // 买家余额 +amount
            userMapper.addBalance(order.getBuyerId(), amount);
            User buyer = userMapper.findById(order.getBuyerId());
            BigDecimal buyerBalanceAfter = buyer == null ? null : buyer.getBalance();

            // 订单 status 4→5
            int upd = orderMapper.markRefunded(order.getId(), auditResult == null ? "管理员同意退款" : auditResult);
            if (upd == 0) {
                result.put("success", false); result.put("message", "订单状态已变化，请刷新后重试");
                return result;
            }

            // 写流水
            PaymentRecord pr = new PaymentRecord();
            pr.setUserId(order.getBuyerId());
            pr.setUserRole("receiver");
            pr.setType(6);  // 6 平台退款
            pr.setAmount(amount);  // 收入正
            pr.setMethod("balance");
            pr.setOrderNo(order.getOrderNo());
            pr.setItemId(order.getItemId());
            pr.setBalanceAfter(buyerBalanceAfter);
            pr.setPlatformAfter(platformAfter);
            pr.setRemark("订单 " + order.getOrderNo() + " 退款：" + (auditResult == null ? "" : auditResult));
            pr.setCreateTime(LocalDateTime.now());
            prMapper.insert(pr);

            session.commit();

            result.put("success", true);
            result.put("message", "退款成功");
            result.put("balanceAfter", buyerBalanceAfter);
            result.put("platformAfter", platformAfter);
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "退款失败：" + e.getMessage());
            return result;
        }
    }

    // ============ 查询工具 ============

    /** 查用户当前余额（实时） */
    public static BigDecimal getUserBalance(Integer userId) {
        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper userMapper = session.getMapper(UserMapper.class);
            User u = userMapper.findById(userId);
            return u == null ? null : u.getBalance();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    /** 查平台账户 */
    public static SystemAccount getSystemAccount() {
        try (SqlSession session = MyBatisUtil.openSession()) {
            SystemAccountMapper saMapper = session.getMapper(SystemAccountMapper.class);
            return saMapper.get();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
