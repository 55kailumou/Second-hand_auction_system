package org.example.listener;

import org.example.service.AuctionEndService;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import java.util.Map;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * 拍卖自动结算调度器
 *
 * <p>Tomcat 启动时由 {@link ServletContextListener} 触发，启动一个 daemon 后台线程，
 * 每 30 秒扫描一次到期未结算的拍品，调用 {@link AuctionEndService#settleEndedItems()}
 * 完成状态流转（status 1 → 2 已成交 / 3 已流拍）。</p>
 *
 * <p><b>修复的问题：</b>在没有定时调度的环境里，{@code auction_item.status} 会一直停在 1（拍卖中），
 * 即使 end_time 已经过期。导致详情页判断 {@code item.status === 2} 失败，胜出者看不到「立即下单」按钮。</p>
 *
 * <p><b>触发时机：</b></p>
 * <ul>
 *   <li>Tomcat 启动后第 5 秒跑一次（让 Tomcat 完整初始化，避免资源竞争）</li>
 *   <li>之后每 30 秒跑一次（兼顾体验与数据库压力）</li>
 * </ul>
 *
 * <p><b>线程模型：</b>单线程 ScheduledExecutorService + daemon 线程。
 * 单次失败被 try-catch 包裹，<b>不会</b>导致后续调度中断。</p>
 *
 * <p><b>手动兜底：</b>万一定时器挂了，登录用户仍可访问 {@code /bid?action=settle} 触发全量结算。</p>
 *
 * <p><b>配合改动：</b>首页 / 列表页 / 详情页底部推荐已改为跨 status 显示拍品（不限 status=1），
 * 即便所有 status=1 被本调度器清空，首页/列表仍然有数据可展示（按 status 区分按钮语义）。</p>
 *
 * @see AuctionEndService#settleEndedItems()
 */
@WebListener
public class AuctionEndScheduler implements ServletContextListener {

    private static final Logger log = Logger.getLogger(AuctionEndScheduler.class.getName());

    /** 首次执行延迟（秒）。给 Tomcat 留初始化时间。 */
    private static final long INITIAL_DELAY_SECONDS = 5L;

    /** 调度间隔（秒）。30 秒既能保证用户体验（最长 30 秒延迟看到「已成交」），又不会压垮数据库。 */
    private static final long PERIOD_SECONDS = 30L;

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        log.info("[AuctionEndScheduler] 启动，每 " + PERIOD_SECONDS + " 秒扫描一次到期拍品");

        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "auction-end-scheduler");
            t.setDaemon(true);  // daemon 线程，Tomcat 关闭时不阻塞 shutdown
            return t;
        });

        scheduler.scheduleWithFixedDelay(
                this::runSettleSafely,
                INITIAL_DELAY_SECONDS,
                PERIOD_SECONDS,
                TimeUnit.SECONDS
        );
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            log.info("[AuctionEndScheduler] 关闭");
            scheduler.shutdown();
            try {
                if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                    log.warning("[AuctionEndScheduler] 5 秒内未优雅关闭，强制 shutdownNow");
                    scheduler.shutdownNow();
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                scheduler.shutdownNow();
            }
        }
    }

    /**
     * 包装一层 try-catch，单次失败不影响后续调度。
     * 注意：{@code settleEndedItems()} 内部已经有事务 try-catch，但这里再包一层防御。
     */
    private void runSettleSafely() {
        try {
            Map<String, Object> r = AuctionEndService.settleEndedItems();
            // 只在有实际工作时打 INFO，避免日志噪音
            int settled = ((Number) r.getOrDefault("settled", 0)).intValue();
            int failed  = ((Number) r.getOrDefault("failed", 0)).intValue();
            if (settled > 0 || failed > 0) {
                log.info("[AuctionEndScheduler] " + r.get("message"));
            }
        } catch (Exception e) {
            log.log(Level.WARNING, "[AuctionEndScheduler] 单次结算异常（下次调度不受影响）", e);
        }
    }
}