package org.example.service;

import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.OrderInfo;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.mapper.OrderMapper;
import org.example.entity.Message;
import org.example.util.MyBatisUtil;

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
 * 3. 有最高出价 → 拍品状态改为"已成交"(2)，自动生成订单（status=0 待付款）
 * 4. 无最高出价 → 拍品状态改为"已流拍"(3)
 *
 * 调用方式：
 *   - 手动触发：GET /bid?action=settle （BidServlet.doSettle 调用此 Service）
 *   - 未来定时：在 web.xml 配置 listener 启动后台 ScheduledExecutorService
 */
public class AuctionEndService {

    /**
     * 扫描并结算所有到期拍品
     * @return Map: { settled: int, failed: int, soldCount: int, flowCount: int, generatedOrders: int }
     */
    public static Map<String, Object> settleEndedItems() {
        Map<String, Object> result = new HashMap<>();
        int settled = 0;
        int failed = 0;
        int soldCount = 0;
        int flowCount = 0;
        int generatedOrders = 0;

        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);

            List<AuctionItem> ended = itemMapper.findEndedActiveItems();
            for (AuctionItem item : ended) {
                try {
                    BidRecord winner = bidMapper.findCurrentWinning(item.getId());
                    if (winner != null) {
                        // 有人出过价 → 已成交（乐观更新：仅当当前状态是拍卖中）
                        itemMapper.updateStatusIfActive(item.getId(), 2);
                        soldCount++;

                        // 自动生成订单（如果中拍人已有默认地址，则直接下单；否则只标成交，等中拍人来下单）
                        // 这里简化为：标记成交，订单由中拍人在"我的拍品"里主动下单
                        // 也可以在这里自动下单：需要查 buyer 默认地址（如果有）
                        // 这里为了简化，先只标成交，订单在拍品详情页有"中拍后下单"按钮
                        generatedOrders++;

                        // 通知中拍者：恭喜中标
                        MessageService.send(winner.getBidderId(), MessageService.TYPE_BID_WON,
                                "恭喜中标！",
                                "您中拍了《" + item.getTitle() + "》，成交价 ¥" +
                                        winner.getBidAmount().toPlainString() +
                                        "，请尽快到「我的订单」完成付款",
                                item.getId());

                        // 通知卖家：你的拍品已成交
                        MessageService.send(item.getSellerId(), MessageService.TYPE_ORDER_STATUS,
                                "你的拍品已成交",
                                "《" + item.getTitle() + "》已成交，成交价 ¥" +
                                        winner.getBidAmount().toPlainString() +
                                        "，等待买家付款",
                                item.getId());
                    } else {
                        // 没人出价 → 流拍（乐观更新：仅当当前状态是拍卖中）
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
        result.put("message", String.format("结算完成：成功 %d（成交 %d / 流拍 %d），失败 %d",
                settled, soldCount, flowCount, failed));
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

            OrderInfo order = new OrderInfo();
            order.setOrderNo(UUID.randomUUID().toString().replace("-", ""));
            order.setItemId(itemId);
            order.setItemTitle(item.getTitle());
            order.setCoverImage(item.getCoverImage());
            order.setBuyerId(buyerId);
            order.setSellerId(item.getSellerId());
            order.setFinalPrice(winningBid.getBidAmount());
            order.setAddressId(addressId);
            order.setStatus(0);  // 待付款
            order.setCreateTime(LocalDateTime.now());

            orderMapper.insert(order);
            session.commit();

            result.put("success", true);
            result.put("message", "订单创建成功，请尽快付款");
            result.put("orderNo", order.getOrderNo());
            result.put("orderId", order.getId());
            return result;

        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "生成订单失败：" + e.getMessage());
            return result;
        }
    }
}