package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.AuctionItem;
import org.example.entity.BidRecord;
import org.example.entity.Deposit;
import org.example.entity.PaymentRecord;
import org.example.entity.SystemAccount;
import org.example.entity.User;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.BidRecordMapper;
import org.example.mapper.ComplaintMapper;
import org.example.mapper.DepositMapper;
import org.example.mapper.OrderMapper;
import org.example.mapper.PaymentRecordMapper;
import org.example.mapper.SystemAccountMapper;
import org.example.mapper.UserMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台首页 Servlet
 *
 * URL：
 *   - GET  /admin                       → 后台首页（JSP）
 *   - GET  /admin?action=demo           → 演示控制台（含拍品/押金/平台账户快照 + 一键触发结算）
 *   - GET  /admin?action=settle-list    → 列出所有 end_time < now AND status=1 的拍品（JSON，调试用）
 *
 * 受 AdminAuthFilter 保护
 */
@WebServlet("/admin")
public class AdminIndexServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "index";

        switch (action) {
            case "demo":
                showDemo(req, resp);
                break;
            case "settle-list":
                listSettleableItems(req, resp);
                break;
            case "index":
            default:
                showIndex(req, resp);
        }
    }

    // ===================== 后台首页 =====================

    private void showIndex(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        int pendingRefund = 0;
        int pendingComplaint = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            ComplaintMapper complaintMapper = session.getMapper(ComplaintMapper.class);
            pendingRefund = orderMapper.countPendingRefund();
            pendingComplaint = complaintMapper.countPending();
        } catch (Exception e) {
            ResponseUtil.handleException(e, "管理后台首页");
        }

        req.setAttribute("admin", admin);
        req.setAttribute("pendingRefund", pendingRefund);
        req.setAttribute("pendingComplaint", pendingComplaint);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/index.jsp").forward(req, resp);
    }

    // ===================== 演示控制台 =====================

    private void showDemo(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        // 拍品列表（按 status 排序：1 在拍 / 2 成交 / 3 流拍）
        List<Map<String, Object>> items = new ArrayList<>();
        int activeCount = 0, soldCount = 0, flowCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            BidRecordMapper bidMapper = session.getMapper(BidRecordMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);
            DepositMapper depositMapper = session.getMapper(DepositMapper.class);

            // 简化：只拿最近 20 个（直接 SQL 排序）
            List<AuctionItem> list;
            try {
                list = itemMapper.findRecent(20);
            } catch (Exception e) {
                // 兜底：findAll 之类
                list = new ArrayList<>();
            }
            for (AuctionItem it : list) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", it.getId());
                row.put("title", it.getTitle());
                row.put("startPrice", it.getStartPrice());
                row.put("deposit", it.getDeposit());
                row.put("currentPrice", it.getCurrentPrice());
                row.put("status", it.getStatus());
                row.put("endTime", it.getEndTime());
                row.put("sellerId", it.getSellerId());
                row.put("viewCount", it.getViewCount());

                // 卖家
                User seller = userMapper.findById(it.getSellerId());
                row.put("sellerName", seller == null ? "用户#" + it.getSellerId() : seller.getUsername());

                // 最高出价
                BidRecord winning = bidMapper.findCurrentWinning(it.getId());
                row.put("winningBid", winning == null ? null : winning.getBidAmount());
                if (winning != null) {
                    User w = userMapper.findById(winning.getBidderId());
                    row.put("winnerName", w == null ? "用户#" + winning.getBidderId() : w.getUsername());
                }

                // 押金情况
                List<Deposit> ds = depositMapper.findByItemId(it.getId());
                int active = 0, transferred = 0, refunded = 0;
                for (Deposit d : ds) {
                    if (d.getStatus() == null) continue;
                    if (d.getStatus() == 0) active++;
                    else if (d.getStatus() == 1) transferred++;
                    else if (d.getStatus() == 2) refunded++;
                }
                row.put("depositActive", active);
                row.put("depositTransferred", transferred);
                row.put("depositRefunded", refunded);
                row.put("depositTotal", ds.size());

                // 计数
                if (it.getStatus() != null) {
                    if (it.getStatus() == 1) activeCount++;
                    else if (it.getStatus() == 2) soldCount++;
                    else if (it.getStatus() == 3) flowCount++;
                }

                items.add(row);
            }
        } catch (Exception e) {
            e.printStackTrace();
            ResponseUtil.handleException(e, "演示控制台-拍品列表");
        }

        // 平台账户 + 近期流水
        SystemAccount sa = null;
        List<PaymentRecord> recentRecords = new ArrayList<>();
        try (SqlSession session = MyBatisUtil.openSession()) {
            SystemAccountMapper saMapper = session.getMapper(SystemAccountMapper.class);
            sa = saMapper.get();
            PaymentRecordMapper prMapper = session.getMapper(PaymentRecordMapper.class);
            Map<String, Object> params = new HashMap<>();
            params.put("type", null);
            params.put("offset", 0);
            params.put("limit", 20);
            try {
                recentRecords = prMapper.findRecent(params);
            } catch (Exception e) {
                // findByUserIdPaged 需要 userId，兜底
                recentRecords = new ArrayList<>();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // 用户余额快照
        List<Map<String, Object>> users = new ArrayList<>();
        try (SqlSession session = MyBatisUtil.openSession()) {
            UserMapper userMapper = session.getMapper(UserMapper.class);
            List<User> all = userMapper.findAll();
            for (User u : all) {
                Map<String, Object> row = new HashMap<>();
                row.put("id", u.getId());
                row.put("username", u.getUsername());
                row.put("phone", u.getPhone());
                row.put("balance", u.getBalance());
                users.add(row);
            }
        } catch (Exception e) { e.printStackTrace(); }

        req.setAttribute("admin", admin);
        req.setAttribute("items", items);
        req.setAttribute("activeCount", activeCount);
        req.setAttribute("soldCount", soldCount);
        req.setAttribute("flowCount", flowCount);
        req.setAttribute("sa", sa);
        req.setAttribute("recentRecords", recentRecords);
        req.setAttribute("users", users);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/demo.jsp").forward(req, resp);
    }

    // ===================== 列出可结算的拍品（JSON 调试用） =====================

    private void listSettleableItems(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Map<String, Object> data = new HashMap<>();
        try (SqlSession session = MyBatisUtil.openSession()) {
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);
            List<AuctionItem> ended = itemMapper.findEndedActiveItems();
            List<Map<String, Object>> rows = new ArrayList<>();
            for (AuctionItem it : ended) {
                Map<String, Object> r = new HashMap<>();
                r.put("id", it.getId());
                r.put("title", it.getTitle());
                r.put("endTime", it.getEndTime());
                r.put("status", it.getStatus());
                rows.add(r);
            }
            data.put("success", true);
            data.put("count", rows.size());
            data.put("items", rows);
        } catch (Exception e) {
            data.put("success", false);
            data.put("message", e.getMessage());
        }
        writeJson(resp, data);
    }

    private void writeJson(HttpServletResponse resp, Object obj) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.print(JSON.writeValueAsString(obj));
        out.flush();
    }
}
