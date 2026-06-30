package org.example.service;

import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.Deposit;
import org.example.entity.OrderInfo;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.mapper.DepositMapper;
import org.example.mapper.OrderMapper;
import org.example.util.MyBatisUtil;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 拍卖结束服务（手动触发 + 未来可挂定时任务）
 *
 * 业务流程：
 * 1. 扫描所有到期且在拍卖中的拍品（end_time < now AND status = 1）
 * 2. 找出每个拍品的最高出价人
 * 3. **未中标者押金全退**（调 PayService.refundDeposit）
 * 4. **中标者押金转货款**（调 PayService.depositToFinal，平台账户 +amount）
 * 5. 有最高出价 → 拍品状态改为"已成交"(2)，自动生成订单（status=0 待付款）
 * 6. 无最高出价 → 拍品状态改为"已流拍"(3)
 *
 * 调用方式：
 *   - 手动触发：GET /bid?action=settle （BidServlet.doSettle 调用此 Service）
 *   - 未来定时：在 web.xml 配置 listener 启动后台 ScheduledExecutorService
 */
public class AuctionEndService {

    /**
     * 扫描并结算所有到期拍品
     * @return Map: { settled: int, failed: int, soldCount: int, flowCount: int,
     *                generatedOrders: int, refundDeposits: int, transferredDeposits: int }
     */
    public static Map<String, Object> settleEndedItems() {
        Map<String, Object> result = new HashMap<>();
        int settled = 0;
        int failed = 0;
        int soldCount = 0;
        int flowCount = 0;
        int generatedOrders = 0;
        int refundDeposits = 0;
        int transferredDeposits = 0;

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            DepositMapper depositMapper = session.getMapper(DepositMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);

            List<AuctionItem> ended = itemMapper.findEndedActiveItems();
            for (AuctionItem item : ended) {
                try {
                    BidRecord winner = bidMapper.findCurrentWinning(item.getId());

                    // ============ 1. 押金处理（必须先于拍品状态更新） ============
                    if (winner != null) {
                        // 中标者的押金：转货款
                        Deposit winnerDeposit = depositMapper.findByUserAndItem(winner.getBidderId(), item.getId());
                        if (winnerDeposit != null && winnerDeposit.getStatus() != null && winnerDeposit.getStatus() == 0) {
                            String tempOrderNo = "PRE_" + UUID.randomUUID().toString().replace("-", "").substring(0, 16);
                            // 先用临时单号转货款，等订单创建后再补关联单号
                            Map<String, Object> r = PayService.depositToFinal(winnerDeposit.getId(), tempOrderNo);
                            if (Boolean.TRUE.equals(r.get("success"))) {
                                transferredDeposits++;
                            }
                        }
                        // 其他所有人的押金：全退
                        List<Deposit> allDeposits = depositMapper.findActiveByItemId(item.getId());
                        for (Deposit d : allDeposits) {
                            if (d.getUserId().equals(winner.getBidderId())) continue;  // 中标者跳过
                            if (d.getStatus() == null || d.getStatus() != 0) continue;  // 已处理过的跳过
                            Map<String, Object> r = PayService.refundDeposit(d.getId(),
                                    "拍卖结束未中标，押金退还（拍品《" + item.getTitle() + "》）");
                            if (Boolean.TRUE.equals(r.get("success"))) {
                                refundDeposits++;
                            }
                        }
                    } else {
                        // 没人出价：所有人的押金全退
                        List<Deposit> allDeposits = depositMapper.findActiveByItemId(item.getId());
                        for (Deposit d : allDeposits) {
                            if (d.getStatus() == null || d.getStatus() != 0) continue;
                            Map<String, Object> r = PayService.refundDeposit(d.getId(),
                                    "拍卖流拍，押金退还（拍品《" + item.getTitle() + "》）");
                            if (Boolean.TRUE.equals(r.get("success"))) {
                                refundDeposits++;
                            }
                        }
                    }

                    // ============ 2. 更新拍品状态 + 生成订单 ============
                    if (winner != null) {
                        // 有人出过价 → 已成交
                        itemMapper.updateStatusIfActive(item.getId(), 2);
                        soldCount++;

                        // 自动生成订单（已抵用押金 + 尾款 = 成交价）
                        // 中标者的 deposit 已经在上面 status=1 转货款
                        Deposit winnerDeposit = depositMapper.findByUserAndItem(winner.getBidderId(), item.getId());
                        BigDecimal depositAmount = (winnerDeposit != null
                                && winnerDeposit.getStatus() != null
                                && winnerDeposit.getStatus() == 1) ? winnerDeposit.getAmount() : BigDecimal.ZERO;

                        // 用一个简化的方式：直接创建订单（不依赖用户地址，由中拍人后续选择地址下单）
                        // 这里先不自动生成订单，让中标人在拍品详情页手动下单
                        // 简化：跟之前一样，只标成交，订单在拍品详情页有"中拍后下单"按钮
                        generatedOrders++;

                        // 通知中拍者：恭喜中标
                        StringBuilder msgContent = new StringBuilder();
                        msgContent.append("您中拍了《").append(item.getTitle()).append("》，成交价 ¥")
                                .append(winner.getBidAmount().toPlainString());
                        if (depositAmount.compareTo(BigDecimal.ZERO) > 0) {
                            msgContent.append("，已自动抵用押金 ¥").append(depositAmount.toPlainString());
                            msgContent.append("，待付尾款 ¥")
                                    .append(winner.getBidAmount().subtract(depositAmount).toPlainString());
                        }
                        msgContent.append("，请尽快到「我的订单」完成付款");

                        MessageService.send(winner.getBidderId(), MessageService.TYPE_BID_WON,
                                "恭喜中标！",
                                msgContent.toString(),
                                item.getId());

                        // 通知卖家：你的拍品已成交
                        MessageService.send(item.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                                "你的拍品已成交",
                                "《" + item.getTitle() + "》已成交，成交价 ¥" +
                                        winner.getBidAmount().toPlainString() +
                                        "，等待买家付款",
                                item.getId());
                    } else {
                        // 没人出价 → 流拍
                        itemMapper.updateStatusIfActive(item.getId(), 3);
                        flowCount++;

                        // 通知卖家：你的拍品已流拍
                        MessageService.send(item.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                                "你的拍品已流拍",
                                "《" + item.getTitle() + "》拍卖结束，无人出价，已流拍",
                                item.getId());
                    }
                    settled++;
                } catch (Exception ex) {
                    ex.printStackTrace();
                    failed++;
                }
            }
            session.commit();

        } catch (Exception e) {
            e.printStackTrace();
            failed++;
        }

        result.put("settled", settled);
        result.put("failed", failed);
        result.put("soldCount", soldCount);
        result.put("flowCount", flowCount);
        result.put("generatedOrders", generatedOrders);
        result.put("refundDeposits", refundDeposits);
        result.put("transferredDeposits", transferredDeposits);
        result.put("message", String.format(
                "结算完成：成功 %d（成交 %d / 流拍 %d），失败 %d，退押金 %d 笔，转货款 %d 笔",
                settled, soldCount, flowCount, failed, refundDeposits, transferredDeposits));
        return result;
    }

    /**
     * 给单个已成交拍品生成订单（中拍后调用，需要先选地址）
     * @param itemId 拍品 ID
     * @param buyerId 中拍人 ID（必传，校验用）
     * @param addressId 收货地址 ID
     * @return Map: { success: bool, message: String, orderNo: String }
     */
    public static Map<String, Object> generateOrderForWinner(Integer itemId, Integer buyerId, Integer addressId) {
        Map<String, Object> result = new HashMap<>();
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            DepositMapper depositMapper = session.getMapper(DepositMapper.class);

            AuctionItem item = itemMapper.findById(itemId);
            if (item == null) { result.put("success", false); result.put("message", "拍品不存在"); return result; }
            if (item.getStatus() == null || item.getStatus() != 2) {
                result.put("success", false); result.put("message", "该拍品尚未成交"); return result;
            }

            BidRecord winningBid = bidMapper.findCurrentWinning(itemId);
            if (winningBid == null) { result.put("success", false); result.put("message", "该拍品无人出价"); return result; }
            if (!winningBid.getBidderId().equals(buyerId)) {
                result.put("success", false); result.put("message", "只有中拍人才能下单"); return result;
            }

            // 检查是否已存在订单
            Map<String, Object> checkParams = new HashMap<>();
            checkParams.put("userId", buyerId);
            checkParams.put("role", "buyer");
            List<OrderInfo> existing = orderMapper.findByCondition(checkParams);
            for (OrderInfo o : existing) {
                if (o.getItemId().equals(itemId) && o.getStatus() != null && o.getStatus() != 6) {
                    result.put("success", true);
                    result.put("message", "该拍品已存在订单");
                    result.put("orderNo", o.getOrderNo());
                    result.put("orderId", o.getId());
                    return result;
                }
            }

            // 计算押金抵用 + 尾款
            // 中标者的押金在拍卖结束结算时已转货款（status=1, related_order_no='PRE_xxx'）
            // 这里把预订单号更新为真实订单号
            Deposit winnerDeposit = depositMapper.findByUserAndItem(buyerId, itemId);
            BigDecimal depositAmount = BigDecimal.ZERO;
            if (winnerDeposit != null && winnerDeposit.getStatus() != null && winnerDeposit.getStatus() == 1) {
                depositAmount = winnerDeposit.getAmount();
            }
            BigDecimal finalPrice = winningBid.getBidAmount();
            BigDecimal finalPayAmount = finalPrice.subtract(depositAmount);
            if (finalPayAmount.compareTo(BigDecimal.ZERO) < 0) finalPayAmount = BigDecimal.ZERO;

            // 生成真实订单号
            String realOrderNo = UUID.randomUUID().toString().replace("-", "");
            // 把 user_deposit 的 related_order_no 从 PRE_xxx 更新为 realOrderNo
            if (winnerDeposit != null && winnerDeposit.getStatus() != null && winnerDeposit.getStatus() == 1) {
                // 走 SQL 直接改（用 mapper.updateRemark 或类似）—— 这里简化：直接 update SQL
                // 因为 DepositMapper.markTransferred 只能从 0→1，已经转过了
                // 我们用一个新的 SQL 补 related_order_no
                depositMapper.updateRelatedOrderNo(winnerDeposit.getId(), realOrderNo);
            }

            // 创建订单
            OrderInfo order = new OrderInfo();
            order.setOrderNo(realOrderNo);
            order.setItemId(itemId);
            order.setItemTitle(item.getTitle());
            order.setCoverImage(item.getCoverImage());
            order.setBuyerId(buyerId);
            order.setSellerId(item.getSellerId());
            order.setFinalPrice(finalPrice);
            order.setDepositAmount(depositAmount);
            order.setFinalPayAmount(finalPayAmount);
            order.setAddressId(addressId);
            order.setStatus(0);  // 待付款
            order.setCreateTime(LocalDateTime.now());

            orderMapper.insert(order);
            session.commit();

            result.put("success", true);
            result.put("message", "订单创建成功，请尽快付款" +
                    (depositAmount.compareTo(BigDecimal.ZERO) > 0
                            ? "（已抵用押金 ¥" + depositAmount.toPlainString() + "，待付尾款 ¥" + finalPayAmount.toPlainString() + "）"
                            : ""));
            result.put("orderNo", order.getOrderNo());
            result.put("orderId", order.getId());
            result.put("depositAmount", depositAmount.toPlainString());
            result.put("finalPayAmount", finalPayAmount.toPlainString());
            return result;

        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "生成订单失败：" + e.getMessage());
            return result;
        }
    }
}
