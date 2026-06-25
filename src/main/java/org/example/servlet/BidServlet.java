package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.User;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;
import org.example.service.MessageService;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 出价 Servlet：出价提交（核心·含乐观锁）/ 出价历史查询 / 拍卖结束结算
 *
 * URL 模式：/bid?action=xxx
 *   - POST /bid?action=place&itemId=&amount=     → 提交出价（需登录）→ JSON
 *   - GET  /bid?action=history&itemId=           → 某拍品的全部出价历史 → JSON
 *   - GET  /bid?action=settle                    → 手动触发拍卖结束结算（管理员/定时任务调用）→ JSON
 */
@WebServlet("/bid")
public class BidServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "history";

        switch (action) {
            case "history":
                sendHistory(req, resp);
                break;
            case "settle":
                doSettle(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if ("place".equals(action)) {
            doPlaceBid(req, resp);
        } else {
            doGet(req, resp);
        }
    }

    // ===================== 出价（核心） =====================

    private void doPlaceBid(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // 1. 鉴权
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            writeJson(resp, errorOf("请先登录"));
            return;
        }

        // 2. 取参
        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        BigDecimal amount = parseDecimal(req.getParameter("amount"));
        if (itemId == null || amount == null) {
            writeJson(resp, errorOf("参数错误"));
            return;
        }

        // 3. 业务校验（在事务内做）
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);

            AuctionItem item = itemMapper.findById(itemId);
            if (item == null) {
                writeJson(resp, errorOf("拍品不存在"));
                return;
            }

            // 卖家不能给自己出价
            if (item.getSellerId().equals(user.getId())) {
                writeJson(resp, errorOf("卖家不能给自己的拍品出价"));
                return;
            }

            // 状态校验
            if (item.getStatus() == null || item.getStatus() != 1) {
                writeJson(resp, errorOf("该拍品当前不在拍卖中"));
                return;
            }

            // 时间校验
            LocalDateTime now = LocalDateTime.now();
            if (item.getStartTime() != null && now.isBefore(item.getStartTime())) {
                writeJson(resp, errorOf("拍卖尚未开始"));
                return;
            }
            if (item.getEndTime() != null && !now.isBefore(item.getEndTime())) {
                writeJson(resp, errorOf("拍卖已结束"));
                return;
            }

            // 价格校验：必须 ≥ 当前价 + 加价幅度
            BigDecimal minBid = item.getCurrentPrice().add(item.getBidIncrement());
            if (amount.compareTo(minBid) < 0) {
                writeJson(resp, errorOf("出价至少 " + minBid.toPlainString() + " 元"));
                return;
            }

            // 4. 乐观锁更新当前价（关键）
            int updated = itemMapper.updatePriceOptimistic(itemId, amount, item.getCurrentPrice());
            if (updated == 0) {
                writeJson(resp, errorOf("出价过于频繁，请刷新后重试"));
                return;
            }

            // 5. 写一条出价记录
            // 5.1 先查出原最高出价人（在 reset 之前），用于发送"出价被超越"消息
            BidRecord oldWinner = bidMapper.findCurrentWinning(itemId);

            bidMapper.resetWinningByItem(itemId);   // 把旧最高置 0
            BidRecord rec = new BidRecord();
            rec.setItemId(itemId);
            rec.setBidderId(user.getId());
            rec.setBidAmount(amount);
            rec.setIsWinning(1);
            rec.setIsProxy(0);
            rec.setBidTime(now);
            bidMapper.insert(rec);

            session.commit();

            // 6. 通知原最高出价人：你的出价被超越（独立事务，失败不影响主流程）
            if (oldWinner != null && !oldWinner.getBidderId().equals(user.getId())) {
                MessageService.send(oldWinner.getBidderId(), MessageService.TYPE_BID_OUTBID,
                        "出价被超越",
                        "您在《" + item.getTitle() + "》的出价 ¥" +
                                oldWinner.getBidAmount().toPlainString() +
                                " 已被新出价 ¥" + amount.toPlainString() + " 超越",
                        itemId);
            }

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "出价成功");
            data.put("currentPrice", amount.toPlainString());
            data.put("bidId", rec.getId());
            writeJson(resp, data);

        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "出价"));
        }
    }

    // ===================== 出价历史 =====================

    private void sendHistory(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Integer itemId = parseIntOrNull(req.getParameter("itemId"));
        if (itemId == null) {
            writeJson(resp, errorOf("参数错误"));
            return;
        }
        try (SqlSession session = MyBatisUtil.openSession()) {
            BidRecordMapper mapper = session.getMapper(BidRecordMapper.class);
            List<BidRecord> bids = mapper.findByItemIdOrderByAmountDesc(itemId);
            int bidderCount = mapper.countBiddersByItem(itemId);

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("bids", bids);
            data.put("bidderCount", bidderCount);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "出价历史查询"));
        }
    }

    // ===================== 拍卖结束结算（手动触发，简化版） =====================

    private void doSettle(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // 找出所有到期且还在拍卖中的拍品
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);

            List<AuctionItem> ended = itemMapper.findEndedActiveItems();
            int settled = 0;
            int failed = 0;
            for (AuctionItem item : ended) {
                try {
                    BidRecord winner = bidMapper.findCurrentWinning(item.getId());
                    if (winner != null) {
                        // 有人出过价 → 已成交（乐观更新：仅当 status=1 时生效）
                        itemMapper.updateStatusIfActive(item.getId(), 2);
                    } else {
                        // 没人出价 → 流拍（乐观更新：仅当 status=1 时生效）
                        itemMapper.updateStatusIfActive(item.getId(), 3);
                    }
                    settled++;
                } catch (Exception ex) {
                    ex.printStackTrace();
                    failed++;
                }
            }
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("settled", settled);
            data.put("failed", failed);
            data.put("message", "结算完成：成功 " + settled + "，失败 " + failed);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "出价历史查询"));
        }
    }

    // ===================== 工具 =====================

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(JSON.writeValueAsString(obj));
        out.flush();
    }

    private Map<String, Object> errorOf(String msg) {
        Map<String, Object> r = new HashMap<>();
        r.put("success", false);
        r.put("message", msg);
        return r;
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private BigDecimal parseDecimal(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return new BigDecimal(s.trim()); } catch (Exception e) { return null; }
    }
}
