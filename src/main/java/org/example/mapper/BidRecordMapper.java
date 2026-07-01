package org.example.mapper;

import org.apache.ibatis.annotations.Param;
import org.example.entity.BidRecord;

import java.util.List;

/**
 * 出价记录 Mapper
 */
public interface BidRecordMapper {

    /** 插入一条出价 */
    int insert(BidRecord record);

    /** 按 ID 查询 */
    BidRecord findById(Integer id);

    /** 把某个拍品的所有 isWinning 置为 0（用于新的最高价产生时） */
    int resetWinningByItem(Integer itemId);

    /** 查询某拍品的所有出价（按金额倒序） */
    List<BidRecord> findByItemIdOrderByAmountDesc(Integer itemId);

    /** 查询某拍品的当前最高出价 */
    BidRecord findCurrentWinning(Integer itemId);

    /** 查询某用户的全部出价（个人中心） */
    List<BidRecord> findByBidderId(Integer bidderId);

    /** 统计某拍品的出价人数 */
    int countBiddersByItem(Integer itemId);
}
