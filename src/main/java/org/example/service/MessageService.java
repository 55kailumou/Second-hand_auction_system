package org.example.service;

import org.apache.ibatis.session.SqlSession;
import org.example.entity.Message;
import org.example.mapper.MessageMapper;
import org.example.util.MyBatisUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * 消息通知 Service
 *
 * 统一 send 接口供各业务 servlet 调用：
 *   - BidServlet       出价被超越 → type=2
 *   - OrderServlet     订单状态变化 → type=5
 *   - AdminRefundServlet 退款审核结果 → type=6
 *   - AuctionEndService 拍卖结束（中标/流拍） → type=1
 *
 * 设计要点：
 *   - 独立 SqlSession，独立 commit（不与主业务事务绑定）
 *   - 失败只 log，不抛异常（消息发送失败不能阻塞主流程）
 *   - 支持批量发送（同一业务多用户通知）
 */
public class MessageService {

    private static final Logger log = LoggerFactory.getLogger(MessageService.class);

    /** 消息类型常量（与 Message entity 保持一致） */
    public static final int TYPE_BID_WON          = 1;   // 中标通知
    public static final int TYPE_BID_OUTBID       = 2;   // 出价被超越
    public static final int TYPE_AUCTION_START    = 3;   // 拍卖开始
    public static final int TYPE_AUCTION_ENDING   = 4;   // 即将结束
    public static final int TYPE_ORDER_STATUS     = 5;   // 订单状态变更
    public static final int TYPE_AUDIT_RESULT     = 6;   // 审核结果
    public static final int TYPE_SYSTEM_NOTICE    = 7;   // 系统公告

    /**
     * 发送一条消息（独立事务，失败不影响主流程）
     * @param userId   接收用户 ID
     * @param type     消息类型（1-7）
     * @param title    标题（≤ 100 字）
     * @param content  内容（≤ 500 字）
     * @param relatedId 关联业务 ID（订单/拍品等，可为 null）
     * @return 是否成功
     */
    public static boolean send(int userId, int type, String title, String content, Integer relatedId) {
        if (userId <= 0) return false;
        if (title == null || title.isEmpty()) return false;
        if (content == null) content = "";

        try (SqlSession session = MyBatisUtil.openSession()) {
            MessageMapper mapper = session.getMapper(MessageMapper.class);
            Message m = new Message();
            m.setUserId(userId);
            m.setType(type);
            m.setTitle(title.length() > 100 ? title.substring(0, 100) : title);
            m.setContent(content.length() > 500 ? content.substring(0, 500) : content);
            m.setRelatedId(relatedId);
            mapper.insert(m);
            session.commit();
            return true;
        } catch (Exception e) {
            log.error("[消息发送失败] userId={}, type={}, title={}, err={}", userId, type, title, e.getMessage(), e);
            return false;
        }
    }

    /**
     * 批量发送（同一事件通知多个用户）
     * @param messages 已构造的 Message 列表（userId/type/title/content/relatedId）
     * @return 成功条数
     */
    public static int sendBatch(List<Message> messages) {
        if (messages == null || messages.isEmpty()) return 0;
        int ok = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            MessageMapper mapper = session.getMapper(MessageMapper.class);
            for (Message m : messages) {
                try {
                    mapper.insert(m);
                    ok++;
                } catch (Exception e) {
                    log.error("[批量消息发送失败] title={}, err={}", m.getTitle(), e.getMessage());
                }
            }
            session.commit();
        } catch (Exception e) {
            log.error("[批量消息发送失败] err={}", e.getMessage(), e);
        }
        return ok;
    }
}
