/* ============================================================
 *  公共 JS：Vue 3 加载器 + 工具函数
 *  使用方法（在 JSP 里）:
 *    <script src="${pageContext.request.contextPath}/static/js/common.js"></script>
 *    <script>loadVue().then(() => { /* Vue 已就绪 *\/ });</script>
 * ============================================================ */

// 当前 web 应用的 context path（由 JSP 模板注入更准，这里给个兜底）
window.CTX = window.CTX || '';

/**
 * 动态加载 Vue 3 CDN（如果已经加载过则直接返回）
 * @returns {Promise<void>}
 */
function loadVue() {
    if (window.Vue) return Promise.resolve();
    return new Promise((resolve, reject) => {
        const s = document.createElement('script');
        s.src = 'https://unpkg.com/vue@3.4.27/dist/vue.global.prod.js';
        s.onload = () => resolve();
        s.onerror = () => reject(new Error('Vue CDN 加载失败，请检查网络'));
        document.head.appendChild(s);
    });
}

/**
 * 动态加载 axios（用于 AJAX 请求）
 */
function loadAxios() {
    if (window.axios) return Promise.resolve();
    return new Promise((resolve, reject) => {
        const s = document.createElement('script');
        s.src = 'https://unpkg.com/axios@1.6.7/dist/axios.min.js';
        s.onload = () => resolve();
        s.onerror = () => reject(new Error('axios CDN 加载失败'));
        document.head.appendChild(s);
    });
}

/**
 * 简单 Toast 提示（页面顶部浮窗，3 秒后自动消失）
 * @param {string} message
 * @param {'success'|'error'|'info'} type
 */
function toast(message, type = 'info') {
    let toastEl = document.getElementById('__toast__');
    if (!toastEl) {
        toastEl = document.createElement('div');
        toastEl.id = '__toast__';
        toastEl.style.cssText = `
            position: fixed; top: 24px; left: 50%; transform: translateX(-50%);
            padding: 12px 24px; border-radius: 8px; font-size: 14px; font-weight: 500;
            box-shadow: 0 4px 20px rgba(0,0,0,0.15); z-index: 99999;
            opacity: 0; transition: opacity 0.3s, transform 0.3s;
            pointer-events: none;
        `;
        document.body.appendChild(toastEl);
    }
    const colors = {
        success: { bg: '#10b981', fg: '#ffffff' },
        error:   { bg: '#ef4444', fg: '#ffffff' },
        info:    { bg: '#3b82f6', fg: '#ffffff' }
    };
    const c = colors[type] || colors.info;
    toastEl.style.backgroundColor = c.bg;
    toastEl.style.color = c.fg;
    toastEl.textContent = message;
    toastEl.style.opacity = '1';
    toastEl.style.transform = 'translateX(-50%) translateY(0)';
    clearTimeout(toast._timer);
    toast._timer = setTimeout(() => {
        toastEl.style.opacity = '0';
        toastEl.style.transform = 'translateX(-50%) translateY(-20px)';
    }, 3000);
}

/**
 * 格式化金额（数字 → "￥1,234.50"）
 */
function formatMoney(n) {
    if (n == null) return '￥0.00';
    return '￥' + Number(n).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

/**
 * 格式化时间（"2024-01-15 14:30"）
 */
function formatDateTime(dt) {
    if (!dt) return '';
    const d = new Date(dt);
    if (isNaN(d)) return dt;
    const pad = n => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/**
 * 倒计时（毫秒 → "X天X时X分X秒"）
 */
function formatCountdown(ms) {
    if (ms <= 0) return '已结束';
    const sec = Math.floor(ms / 1000);
    const days = Math.floor(sec / 86400);
    const hours = Math.floor((sec % 86400) / 3600);
    const mins = Math.floor((sec % 3600) / 60);
    const secs = sec % 60;
    if (days > 0) return `${days}天${hours}时${mins}分`;
    if (hours > 0) return `${hours}时${mins}分${secs}秒`;
    return `${mins}分${secs}秒`;
}

/**
 * 防抖
 */
function debounce(fn, delay = 300) {
    let timer;
    return function (...args) {
        clearTimeout(timer);
        timer = setTimeout(() => fn.apply(this, args), delay);
    };
}

/**
 * 字段校验工具集
 */
const Validators = {
    required: v => v != null && String(v).trim().length > 0,
    username: v => v && /^[a-zA-Z0-9_\u4e00-\u9fa5]{3,20}$/.test(v),
    password: v => v && v.length >= 6 && v.length <= 20,
    phone:    v => v && /^1[3-9]\d{9}$/.test(v),
    email:    v => v && /^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$/.test(v),
    same: (a, b) => a === b
};