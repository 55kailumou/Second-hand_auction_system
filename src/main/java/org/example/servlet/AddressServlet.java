package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Address;
import org.example.entity.OrderInfo;
import org.example.entity.User;
import org.example.mapper.AddressMapper;
import org.example.mapper.OrderMapper;
import org.example.util.MyBatisUtil;
import org.example.util.ResponseUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 收货地址 Servlet
 *
 * URL 模式：/address?action=xxx
 *   - GET  /address?action=list          → 我的地址列表（JSP）
 *   - POST /address?action=add           → 新增收货地址（JSON）
 *   - POST /address?action=update        → 更新收货地址（JSON）
 *   - POST /address?action=remove        → 删除收货地址（JSON，避开 doDelete 同名）
 *   - POST /address?action=set-default   → 设为默认地址（JSON）
 *
 * 业务规则：
 *   - 第一个地址自动设为默认
 *   - 删除默认地址：自动把剩余地址中"最近创建"的设为默认
 *   - 删除前检查：未完成的订单（待付款/已付款/已发货，status 0/1/2）不能删除对应地址
 *   - 最多 10 个地址（业务上限）
 *   - 取消默认：clearDefaultByUserId + setDefault 新默认（同一事务）
 */
@WebServlet("/address")
public class AddressServlet extends HttpServlet {

    /** 单个用户最多地址数 */
    private static final int MAX_ADDRESSES_PER_USER = 10;

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
            case "default":
                getDefaultAddress(req, resp);
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/address?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "add":
                doAdd(req, resp);
                break;
            case "update":
                doUpdate(req, resp);
                break;
            case "remove":
                doRemove(req, resp);
                break;
            case "set-default":
                doSetDefault(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 列表页 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/user?action=login&returnUrl=" +
                    java.net.URLEncoder.encode("/address?action=list", "UTF-8"));
            return;
        }

        List<Address> addresses;
        try (SqlSession session = MyBatisUtil.openSession()) {
            AddressMapper mapper = session.getMapper(AddressMapper.class);
            addresses = mapper.findByUserId(user.getId());
        } catch (Exception e) {
            ResponseUtil.handleException(e, "地址列表");
            addresses = new java.util.ArrayList<>();
            req.setAttribute("error", "加载地址失败，请稍后重试");
        }

        // 传给 JSP：JSON 字符串
        String addressesJson = safeToJson(addresses);
        req.setAttribute("addressesJson", addressesJson);
        req.setAttribute("addressCount", addresses == null ? 0 : addresses.size());
        req.setAttribute("maxAddresses", MAX_ADDRESSES_PER_USER);
        req.getRequestDispatcher("/WEB-INF/jsp/address/list.jsp").forward(req, resp);
    }

    // ============ 新增 ============

    private void doAdd(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Address a = parseAddressFromForm(req);
        String err = validateAddress(a);
        if (err != null) { writeJson(resp, errorOf(err)); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AddressMapper mapper = session.getMapper(AddressMapper.class);

            // 检查数量上限
            int count = mapper.findByUserId(user.getId()).size();
            if (count >= MAX_ADDRESSES_PER_USER) {
                writeJson(resp, errorOf("最多只能添加 " + MAX_ADDRESSES_PER_USER + " 个地址"));
                return;
            }

            a.setUserId(user.getId());
            // 第一个地址自动默认
            if (count == 0) {
                a.setIsDefault(1);
            } else {
                a.setIsDefault(a.getIsDefault() == null ? 0 : a.getIsDefault());
            }
            int rows = mapper.insert(a);
            session.commit();

            if (rows > 0 && a.getId() != null) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "地址添加成功");
                data.put("addressId", a.getId());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("添加失败，请稍后再试"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "新增地址"));
        }
    }

    // ============ 更新 ============

    private void doUpdate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        Address a = parseAddressFromForm(req);
        String err = validateAddress(a);
        if (err != null) { writeJson(resp, errorOf(err)); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AddressMapper mapper = session.getMapper(AddressMapper.class);

            // 校验归属
            Address existing = mapper.findById(id);
            if (existing == null) { writeJson(resp, errorOf("地址不存在")); return; }
            if (!existing.getUserId().equals(user.getId())) {
                writeJson(resp, errorOf("无权操作此地址"));
                return;
            }

            a.setId(id);
            a.setUserId(user.getId());
            int rows = mapper.updateById(a);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "地址更新成功");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("更新失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "更新地址"));
        }
    }

    // ============ 删除 ============

    private void doRemove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AddressMapper mapper = session.getMapper(AddressMapper.class);
            OrderMapper orderMapper = session.getMapper(OrderMapper.class);

            // 校验归属
            Address existing = mapper.findById(id);
            if (existing == null) { writeJson(resp, errorOf("地址不存在")); return; }
            if (!existing.getUserId().equals(user.getId())) {
                writeJson(resp, errorOf("无权操作此地址"));
                return;
            }

            // 检查未完成订单
            Map<String, Object> params = new HashMap<>();
            params.put("userId", user.getId());
            params.put("role", "buyer");
            params.put("offset", 0);
            params.put("limit", 200);
            List<OrderInfo> myOrders = orderMapper.findByCondition(params);
            for (OrderInfo o : myOrders) {
                if (id.equals(o.getAddressId())
                        && o.getStatus() != null
                        && o.getStatus() <= 2) {   // 0待付款 1已付款 2已发货
                    writeJson(resp, errorOf("此地址有进行中的订单（订单号 " + o.getOrderNo() + "），暂不能删除"));
                    return;
                }
            }

            int rows = mapper.deleteById(id);
            // 如果删的是默认地址 → 把剩余地址中最近创建的设为默认
            if (existing.getIsDefault() != null && existing.getIsDefault() == 1) {
                List<Address> remain = mapper.findByUserId(user.getId());
                if (!remain.isEmpty()) {
                    Address newest = remain.get(0);   // 已经按"默认优先 + 创建时间倒序"，最新的一定在第一个
                    mapper.setDefault(newest.getId());
                }
            }
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "地址已删除");
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("删除失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "删除地址"));
        }
    }

    // ============ 设为默认 ============

    private void doSetDefault(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        if (user == null) { writeJson(resp, errorOf("请先登录")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            AddressMapper mapper = session.getMapper(AddressMapper.class);

            // 校验归属
            Address existing = mapper.findById(id);
            if (existing == null) { writeJson(resp, errorOf("地址不存在")); return; }
            if (!existing.getUserId().equals(user.getId())) {
                writeJson(resp, errorOf("无权操作此地址"));
                return;
            }

            // 已经默认
            if (existing.getIsDefault() != null && existing.getIsDefault() == 1) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "已经是默认地址");
                writeJson(resp, data);
                return;
            }

            // 事务：先全部清掉，再设新的
            mapper.clearDefaultByUserId(user.getId());
            mapper.setDefault(id);
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "已设为默认地址");
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "设置默认地址"));
        }
    }

    // ============ 查默认地址（JSON） ============

    private void getDefaultAddress(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        User user = (User) req.getSession().getAttribute("currentUser");
        Map<String, Object> data = new HashMap<>();
        if (user == null) {
            data.put("success", false);
            data.put("message", "请先登录");
            writeJson(resp, data);
            return;
        }
        try (SqlSession session = MyBatisUtil.openSession()) {
            AddressMapper mapper = session.getMapper(AddressMapper.class);
            Address addr = mapper.findDefaultByUserId(user.getId());
            if (addr == null) {
                // 没默认地址 → 取第一个
                List<Address> all = mapper.findByUserId(user.getId());
                if (all != null && !all.isEmpty()) {
                    addr = all.get(0);
                }
            }
            if (addr == null) {
                data.put("success", false);
                data.put("message", "请先添加收货地址");
                data.put("hasAddress", false);
            } else {
                data.put("success", true);
                data.put("hasAddress", true);
                data.put("addressId", addr.getId());
                data.put("addressText",
                        addr.getReceiverName() + " " + addr.getReceiverPhone() + " " +
                        addr.getProvince() + addr.getCity() + addr.getDistrict() + " " +
                        addr.getDetailAddress());
            }
        } catch (Exception e) {
            data.put("success", false);
            data.put("message", e.getMessage());
        }
        writeJson(resp, data);
    }

    // ============ 工具方法 ============

    private Address parseAddressFromForm(HttpServletRequest req) {
        Address a = new Address();
        a.setReceiverName(trim(req.getParameter("receiverName")));
        a.setReceiverPhone(trim(req.getParameter("receiverPhone")));
        a.setProvince(trim(req.getParameter("province")));
        a.setCity(trim(req.getParameter("city")));
        a.setDistrict(trim(req.getParameter("district")));
        a.setDetailAddress(trim(req.getParameter("detailAddress")));
        String isDefaultStr = req.getParameter("isDefault");
        a.setIsDefault("1".equals(isDefaultStr) ? 1 : 0);
        return a;
    }

    private String validateAddress(Address a) {
        if (a.getReceiverName() == null || a.getReceiverName().isEmpty()) return "请填写收货人";
        if (a.getReceiverName().length() > 20) return "收货人姓名不超过 20 字";
        if (a.getReceiverPhone() == null || a.getReceiverPhone().isEmpty()) return "请填写手机号";
        if (!a.getReceiverPhone().matches("^1[3-9]\\d{9}$")) return "手机号格式不正确";
        if (a.getProvince() == null || a.getProvince().isEmpty()) return "请填写省份";
        if (a.getCity() == null || a.getCity().isEmpty()) return "请填写城市";
        if (a.getDistrict() == null || a.getDistrict().isEmpty()) return "请填写区/县";
        if (a.getDetailAddress() == null || a.getDetailAddress().isEmpty()) return "请填写详细地址";
        if (a.getDetailAddress().length() > 100) return "详细地址不超过 100 字";
        return null;
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String safeToJson(Object obj) {
        try {
            return JSON.writeValueAsString(obj);
        } catch (Exception e) {
            ResponseUtil.handleException(e, "JSON 序列化");
            return "[]";
        }
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
