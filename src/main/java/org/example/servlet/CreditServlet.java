package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.CreditRecord;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.CreditRecordMapper;
import org.example.mapper.OrderMapper;
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
 * 信用评价 Servlet
 *
 * URL 模式：/credit?action=xxx
 *   - GET  /credit?action=list&type=sent|received&page=  → 我的评价（JSP）
 *   - GET  /credit?action=for-order&orderNo=xx            → 查某订单当前用户评价状态（JSON，详情页用）
 *   - POST /credit?action=submit                          → 提交评价（JSON）
 *
 * 业务规则：
 *   - 已收货（status 3）才能评价
 *   - 同一订单同一评价人只能评一次（uk_order_evaluator 唯一约束）
 *   - role 自动判定：当前用户是 buyer → 1（评卖家）；是 seller → 2（评买家）
 *   - 提交后同步更新被评价人 credit_score（+5/+1/0/-3/-5；范围 0-150，DB 层 GREATEST/LEAST 兜底）
 */
@WebServlet("/credit")
public class CreditServlet extends HttpServlet {

    private static final ObjectMapper JSON = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list":
                showList(req, resp);
                break;
            case "for-order":
                getForOrder(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/credit?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "submit":
                doSubmit(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 我的评价列表 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/credit?action=list", "UTF-8"));
            return;
        }

        String type = req.getParameter("type");
        if (type == null) type = "received";   // 默认看"我收到的"
        if (!"sent".equals(type) && !"received".equals(type) && !"all".equals(type)) {
            type = "received";
        }

        int pageNo = 1;
        try { pageNo = Integer.parseInt(req.getParameter("page")); } catch (Exception ignored) {}
        if (pageNo < 1) pageNo = 1;
        int pageSize = 10;
        int offset = (pageNo - 1) * pageSize;

        // 装载评价 + 关联拍品/订单/对方用户
        List<Map<String, Object>> rows = new ArrayList<>();
        int total = 0;
        Map<String, Object> stat = new HashMap<>();   // 我收到的统计
        stat.put("count", 0);
        stat.put("avgScore", 0.0);
        try (SqlSession session = MyBatisUtil.openSession()) {
            CreditRecordMapper creditMapper = session.getMapper(CreditRecordMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);

            Map<String, Object> params = new HashMap<>();
            params.put("userId", user.getId());
            params.put("type", type);
            params.put("offset", offset);
            params.put("limit", pageSize);

            List<CreditRecord> credits = creditMapper.findByCondition(params);
            total = creditMapper.countByCondition(params);

            // 收到的统计（仅 type=received 时取）
            if ("received".equals(type) || "all".equals(type)) {
                Map<String, Object> s = creditMapper.statReceivedScore(user.getId());
                if (s != null) {
                    stat.put("count", s.get("count"));
                    stat.put("avgScore", s.get("avgScore"));
                }
            }

            for (CreditRecord c : credits) {
                OrderInfo order = orderMapper.findById(c.getOrderId());
                User target = userMapper.findById(c.getTargetId());
                User evaluator = userMapper.findById(c.getEvaluatorId());

                Map<String, Object> row = new HashMap<>();
                row.put("id", c.getId());
                row.put("orderId", c.getOrderId());
                row.put("orderNo", order == null ? "未知" : order.getOrderNo());
                row.put("itemId", order == null ? null : order.getItemId());
                row.put("itemTitle", order == null ? "(订单已删除)" : order.getItemTitle());
                row.put("coverImage", order == null ? null : order.getCoverImage());
                row.put("score", c.getScore());
                row.put("content", c.getContent());
                row.put("role", c.getRole());
                row.put("roleText", c.getRoleText());
                row.put("createTime", c.getCreateTime());
                row.put("targetId", c.getTargetId());
                row.put("targetUsername", target == null ? "用户#" + c.getTargetId() : target.getUsername());
                row.put("evaluatorId", c.getEvaluatorId());
                row.put("evaluatorUsername", evaluator == null ? "用户#" + c.getEvaluatorId() : evaluator.getUsername());
                rows.add(row);
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "评价列表");
            req.setAttribute("error", "加载评价失败，请稍后重试");
        }

        int totalPages = (total + pageSize - 1) / pageSize;

        req.setAttribute("rowsJson", safeToJson(rows));
        req.setAttribute("total", total);
        req.setAttribute("pageNo", pageNo);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("type", type);
        req.setAttribute("stat", stat);
        req.getRequestDispatcher("/WEB-INF/jsp/credit/list.jsp").forward(req, resp);
    }

    // ============ 查某订单当前用户的评价状态（详情页用） ============

    private void getForOrder(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("缺少订单号")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            CreditRecordMapper creditMapper = session.getMapper(CreditRecordMapper.class);

            OrderInfo order = orderMapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }

            // 必须是买家或卖家本人
            boolean isBuyer = order.getBuyerId().equals(user.getId());
            boolean isSeller = order.getSellerId().equals(user.getId());
            if (!isBuyer && !isSeller) {
                writeJson(resp, errorOf("无权查看此订单评价"));
                return;
            }

            CreditRecord existing = creditMapper.findByOrderAndEvaluator(order.getId(), user.getId());

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("orderNo", order.getOrderNo());
            data.put("status", order.getStatus());
            data.put("canEvaluate", order.getStatus() != null && order.getStatus() == 3);
            data.put("myRole", isBuyer ? 1 : 2);
            data.put("targetId", isBuyer ? order.getSellerId() : order.getBuyerId());
            if (existing != null) {
                data.put("evaluated", true);
                data.put("score", existing.getScore());
                data.put("content", existing.getContent());
                data.put("createTime", existing.getCreateTime());
            } else {
                data.put("evaluated", false);
            }
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "查订单评价"));
        }
    }

    // ============ 提交评价 ============

    private void doSubmit(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        String orderNo = req.getParameter("orderNo");
        Integer score = parseIntOrNull(req.getParameter("score"));
        String content = req.getParameter("content");

        if (orderNo == null || orderNo.isEmpty()) { writeJson(resp, errorOf("缺少订单号")); return; }
        if (score == null || score < 1 || score > 5) {
            writeJson(resp, errorOf("评分必须为 1-5 星"));
            return;
        }
        if (content != null && content.length() > 500) {
            writeJson(resp, errorOf("评价内容不超过 500 字"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);
            CreditRecordMapper creditMapper = session.getMapper(CreditRecordMapper.class);
            UserMapper userMapper = session.getMapper(UserMapper.class);

            OrderInfo order = orderMapper.findByOrderNo(orderNo);
            if (order == null) { writeJson(resp, errorOf("订单不存在")); return; }

            // 必须已收货
            if (order.getStatus() == null || order.getStatus() != 3) {
                writeJson(resp, errorOf("只有已收货的订单才能评价"));
                return;
            }

            // 必须有权限
            boolean isBuyer = order.getBuyerId().equals(user.getId());
            boolean isSeller = order.getSellerId().equals(user.getId());
            if (!isBuyer && !isSeller) {
                writeJson(resp, errorOf("只有订单的买家或卖家才能评价"));
                return;
            }
            // 不能给自己评价（理论上不会发生，因为买家 ≠ 卖家）
            Integer targetId = isBuyer ? order.getSellerId() : order.getBuyerId();
            if (targetId.equals(user.getId())) {
                writeJson(resp, errorOf("不能给自己评价"));
                return;
            }

            // 唯一性：uk_order_evaluator
            CreditRecord existing = creditMapper.findByOrderAndEvaluator(order.getId(), user.getId());
            if (existing != null) {
                writeJson(resp, errorOf("此订单你已经评价过"));
                return;
            }

            // 插入评价
            CreditRecord c = new CreditRecord();
            c.setOrderId(order.getId());
            c.setEvaluatorId(user.getId());
            c.setTargetId(targetId);
            c.setRole(isBuyer ? 1 : 2);
            c.setScore(score);
            c.setContent(content == null ? null : content.trim());
            creditMapper.insert(c);

            // 同步更新被评人 credit_score
            int delta = scoreToDelta(score);
            userMapper.updateCreditScore(targetId, delta);

            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "评价成功，感谢你的反馈！");
            data.put("creditId", c.getId());
            data.put("delta", delta);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "提交评价"));
        }
    }

    /** 评分 → 信用分变化 */
    private int scoreToDelta(int score) {
        switch (score) {
            case 5: return  1;   // 好评
            case 4: return  0;   // 中评
            case 3: return -1;   // 中差
            case 2: return -3;   // 差评
            case 1: return -5;   // 极差
            default: return 0;
        }
    }

    // ============ 工具 ============

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String safeToJson(Object obj) {
        try { return JSON.writeValueAsString(obj); }
        catch (Exception e) { ResponseUtil.handleException(e, "JSON 序列化"); return "[]"; }
    }

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
}
