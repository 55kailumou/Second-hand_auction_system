package org.example.servlet;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.apache.ibatis.session.SqlSession;
import org.example.entity.Admin;
import org.example.entity.Category;
import org.example.mapper.AuctionItemMapper;
import org.example.mapper.CategoryMapper;
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
 * 管理后台 - 分类管理 Servlet
 *
 * URL 模式：/admin/category
 *   - GET  /admin/category?action=list                          → 分类列表（JSP，受 AdminAuthFilter 保护）
 *   - GET  /admin/category?action=detail&id=xx                  → 分类详情（JSON）
 *   - POST /admin/category?action=create                        → 新增分类（JSON）
 *   - POST /admin/category?action=update&id=                    → 更新分类（JSON）
 *   - POST /admin/category?action=delete&id=                    → 删除分类（JSON，需先检查拍品数）
 *   - POST /admin/category?action=set-status&id=&status=        → 启用/禁用（JSON，0=禁用 1=启用）
 *
 * 业务规则：
 *   - 支持二级分类（parentId=0 一级）
 *   - 删除前必须检查该分类下没有拍品（有则禁止删除，提示先转移）
 *   - 禁用后该分类在前台不可见，但已有数据不丢失
 */
@WebServlet("/admin/category")
public class AdminCategoryServlet extends HttpServlet {

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
            case "detail":
                getDetail(req, resp);
                break;
            case "parents":
                getParentOptions(req, resp);  // 给新增/编辑弹窗用：返回一级分类列表
                break;
            default:
                resp.sendRedirect(req.getContextPath() + "/admin/category?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "create":
                doCreate(req, resp);
                break;
            case "update":
                doUpdate(req, resp);
                break;
            case "delete":
                doRemove(req, resp);
                break;
            case "set-status":
                doSetStatus(req, resp);
                break;
            default:
                writeJson(resp, errorOf("unknown action"));
        }
    }

    // ============ 列表 ============

    private void showList(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) {
            resp.sendRedirect(req.getContextPath() + "/admin/login");
            return;
        }

        List<Category> categories = null;
        int total = 0;
        int enabledCount = 0;
        int disabledCount = 0;
        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper mapper = session.getMapper(CategoryMapper.class);
            categories = mapper.findAll();
            total = categories == null ? 0 : categories.size();
            if (categories != null) {
                for (Category c : categories) {
                    if (c.getStatus() != null && c.getStatus() == 1) enabledCount++;
                    else disabledCount++;
                }
            }
        } catch (Exception e) {
            ResponseUtil.handleException(e, "分类列表");
            req.setAttribute("error", "加载分类列表失败，请稍后重试");
        }

        req.setAttribute("admin", admin);
        req.setAttribute("categoriesJson", safeToJson(categories == null ? new java.util.ArrayList<>() : categories));
        req.setAttribute("total", total);
        req.setAttribute("enabledCount", enabledCount);
        req.setAttribute("disabledCount", disabledCount);
        req.getRequestDispatcher("/WEB-INF/jsp/admin/categories.jsp").forward(req, resp);
    }

    // ============ 详情（JSON） ============

    private void getDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            Category category = session.getMapper(CategoryMapper.class).findById(id);
            if (category == null) { writeJson(resp, errorOf("分类不存在")); return; }
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("category", category);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "分类详情"));
        }
    }

    // ============ 父分类选项（给弹窗用） ============

    private void getParentOptions(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            List<Category> tops = session.getMapper(CategoryMapper.class).findTopLevel();
            // 加一个 "无（一级分类）" 选项
            java.util.List<Map<String, Object>> opts = new java.util.ArrayList<>();
            Map<String, Object> none = new HashMap<>();
            none.put("id", 0);
            none.put("name", "（一级分类）");
            opts.add(none);
            for (Category c : tops) {
                Map<String, Object> o = new HashMap<>();
                o.put("id", c.getId());
                o.put("name", c.getCategoryName());
                opts.add(o);
            }
            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("options", opts);
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "父分类选项"));
        }
    }

    // ============ 新增 ============

    private void doCreate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        String name = trim(req.getParameter("categoryName"));
        Integer parentId = parseIntOrNull(req.getParameter("parentId"));
        Integer sortOrder = parseIntOrNull(req.getParameter("sortOrder"));
        String icon = trim(req.getParameter("icon"));
        Integer status = parseIntOrNull(req.getParameter("status"));

        // 校验
        if (name == null || name.isEmpty()) { writeJson(resp, errorOf("分类名不能为空")); return; }
        if (name.length() > 20) { writeJson(resp, errorOf("分类名不超过 20 字")); return; }
        if (parentId == null) parentId = 0;
        if (sortOrder == null) sortOrder = 0;
        if (status == null || (status != 0 && status != 1)) status = 1;
        if (icon == null) icon = null;

        // 如果指定了 parentId，必须验证父分类存在且也是一级分类
        if (parentId != 0) {
            try (SqlSession session = MyBatisUtil.openSession()) {
                Category parent = session.getMapper(CategoryMapper.class).findById(parentId);
                if (parent == null) { writeJson(resp, errorOf("父分类不存在")); return; }
                if (parent.getParentId() != null && parent.getParentId() != 0) {
                    writeJson(resp, errorOf("不支持三级分类：父分类必须是顶级"));
                    return;
                }
            } catch (Exception e) {
                writeJson(resp, ResponseUtil.handleException(e, "新增分类"));
                return;
            }
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            Category category = new Category();
            category.setCategoryName(name);
            category.setParentId(parentId);
            category.setSortOrder(sortOrder);
            category.setIcon(icon);
            category.setStatus(status);

            session.getMapper(CategoryMapper.class).insert(category);
            session.commit();

            Map<String, Object> data = new HashMap<>();
            data.put("success", true);
            data.put("message", "分类已新增：" + name);
            data.put("id", category.getId());
            writeJson(resp, data);
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "新增分类"));
        }
    }

    // ============ 更新 ============

    private void doUpdate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        String name = trim(req.getParameter("categoryName"));
        Integer parentId = parseIntOrNull(req.getParameter("parentId"));
        Integer sortOrder = parseIntOrNull(req.getParameter("sortOrder"));
        String icon = trim(req.getParameter("icon"));
        Integer status = parseIntOrNull(req.getParameter("status"));

        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (name == null || name.isEmpty()) { writeJson(resp, errorOf("分类名不能为空")); return; }
        if (name.length() > 20) { writeJson(resp, errorOf("分类名不超过 20 字")); return; }
        if (parentId == null) parentId = 0;
        if (sortOrder == null) sortOrder = 0;
        if (status == null || (status != 0 && status != 1)) status = 1;

        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper mapper = session.getMapper(CategoryMapper.class);
            Category old = mapper.findById(id);
            if (old == null) { writeJson(resp, errorOf("分类不存在")); return; }

            // 防呆：分类不能把自己的子类作为父类
            if (parentId == id) { writeJson(resp, errorOf("分类不能把自己设为父分类")); return; }

            // 防呆：父分类必须是顶级
            if (parentId != 0) {
                Category parent = mapper.findById(parentId);
                if (parent == null) { writeJson(resp, errorOf("父分类不存在")); return; }
                if (parent.getParentId() != null && parent.getParentId() != 0) {
                    writeJson(resp, errorOf("不支持三级分类：父分类必须是顶级"));
                    return;
                }
            }

            Category category = new Category();
            category.setId(id);
            category.setCategoryName(name);
            category.setParentId(parentId);
            category.setSortOrder(sortOrder);
            category.setIcon(icon);
            category.setStatus(status);
            category.setCreateTime(old.getCreateTime());

            int rows = mapper.updateById(category);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "分类已更新：" + name);
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("更新失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "更新分类"));
        }
    }

    // ============ 删除（带保护） ============

    private void doRemove(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }

        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper catMapper = session.getMapper(CategoryMapper.class);
            AuctionItemMapper itemMapper = session.getMapper(AuctionItemMapper.class);

            Category category = catMapper.findById(id);
            if (category == null) { writeJson(resp, errorOf("分类不存在")); return; }

            // 防呆 1：分类下有拍品不能删
            int itemCount = itemMapper.countByCondition(java.util.Collections.singletonMap("categoryId", id));
            if (itemCount > 0) {
                writeJson(resp, errorOf("该分类下还有 " + itemCount + " 个拍品，请先转移或下架拍品后再删除"));
                return;
            }

            // 防呆 2：一级分类下有子分类不能删
            java.util.List<Category> children = catMapper.findByParentId(id);
            if (children != null && !children.isEmpty()) {
                writeJson(resp, errorOf("该分类下还有 " + children.size() + " 个子分类，请先删除子分类"));
                return;
            }

            int rows = catMapper.deleteById(id);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "分类已删除：" + category.getCategoryName());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("删除失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "删除分类"));
        }
    }

    // ============ 启用/禁用 ============

    private void doSetStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Admin admin = (Admin) req.getSession().getAttribute("currentAdmin");
        if (admin == null) { writeJson(resp, errorOf("请先登录管理员")); return; }

        Integer id = parseIntOrNull(req.getParameter("id"));
        Integer newStatus = parseIntOrNull(req.getParameter("status"));
        if (id == null) { writeJson(resp, errorOf("参数错误：缺少 id")); return; }
        if (newStatus == null || (newStatus != 0 && newStatus != 1)) {
            writeJson(resp, errorOf("status 必须为 0（禁用）或 1（启用）"));
            return;
        }

        try (SqlSession session = MyBatisUtil.openSession()) {
            CategoryMapper mapper = session.getMapper(CategoryMapper.class);
            Category category = mapper.findById(id);
            if (category == null) { writeJson(resp, errorOf("分类不存在")); return; }

            int oldStatus = category.getStatus() == null ? 1 : category.getStatus();
            if (oldStatus == newStatus) {
                writeJson(resp, errorOf("状态未变化"));
                return;
            }

            int rows = mapper.updateStatusByAdmin(id, newStatus);
            session.commit();

            if (rows > 0) {
                Map<String, Object> data = new HashMap<>();
                data.put("success", true);
                data.put("message", "分类已" + (newStatus == 1 ? "启用" : "禁用") + "：" + category.getCategoryName());
                writeJson(resp, data);
            } else {
                writeJson(resp, errorOf("操作失败"));
            }
        } catch (Exception e) {
            writeJson(resp, ResponseUtil.handleException(e, "改状态"));
        }
    }

    // ============ 工具 ============

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String trim(String s) {
        return s == null ? null : s.trim();
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