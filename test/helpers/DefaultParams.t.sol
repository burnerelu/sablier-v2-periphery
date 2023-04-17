// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ud2x18, UD60x18 } from "@sablier/v2-core/types/Math.sol";
import { Broker, Lockup, LockupDynamic, LockupLinear } from "@sablier/v2-core/types/DataTypes.sol";
import { IAllowanceTransfer } from "permit2/interfaces/IAllowanceTransfer.sol";

import { Batch, Permit2Params } from "src/types/DataTypes.sol";

import { Users } from "./Types.t.sol";

library DefaultParams {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////
                                     GENERIC
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant BATCH_COUNT = 10;
    UD60x18 internal constant BROKER_FEE = UD60x18.wrap(0);
    uint40 internal constant CLIFF_DURATION = 2500 seconds;
    uint40 internal constant CLIFF_TIME = START_TIME + CLIFF_DURATION;
    uint40 internal constant END_TIME = START_TIME + TOTAL_DURATION;
    uint256 internal constant ETHER_AMOUNT = 10_000 ether;
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint256 internal constant MAX_SEGMENT_COUNT = 1000;
    uint128 internal constant PER_STREAM_TOTAL_AMOUNT = 10_000e18;
    uint128 internal constant REFUND_AMOUNT = 7500e18;
    uint40 internal constant START_TIME = 100;
    uint40 internal constant TIME_WARP = 2600 seconds;
    uint40 internal constant TOTAL_DURATION = 10_000 seconds;
    uint128 internal constant TRANSFER_AMOUNT = 100_000e18;
    uint128 internal constant WITHDRAW_AMOUNT = 2500e18;

    /*//////////////////////////////////////////////////////////////////////////
                                      PERMIT2
    //////////////////////////////////////////////////////////////////////////*/

    uint48 internal constant PERMIT2_EXPIRATION = type(uint48).max;
    uint48 internal constant PERMIT2_NONCE = 0;
    uint256 internal constant PERMIT2_SIG_DEADLINE = 100;

    function permitDetails(
        address asset,
        uint160 amount
    )
        internal
        pure
        returns (IAllowanceTransfer.PermitDetails memory details)
    {
        details = IAllowanceTransfer.PermitDetails({
            amount: amount,
            expiration: PERMIT2_EXPIRATION,
            nonce: PERMIT2_NONCE,
            token: asset
        });
    }

    function permitDetailsWithNonce(
        address asset,
        uint160 amount,
        uint48 nonce
    )
        internal
        pure
        returns (IAllowanceTransfer.PermitDetails memory details)
    {
        details = IAllowanceTransfer.PermitDetails({
            amount: amount,
            expiration: PERMIT2_EXPIRATION,
            nonce: nonce,
            token: asset
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function assets(IERC20 asset) internal pure returns (IERC20[] memory assets_) {
        assets_ = new IERC20[](1);
        assets_[0] = asset;
    }

    function statusAfterCancel() internal pure returns (Lockup.Status status) {
        status = Lockup.Status.CANCELED;
    }

    function statusBeforeCancel() internal pure returns (Lockup.Status status) {
        status = Lockup.Status.ACTIVE;
    }

    function statusesAfterCancelMultiple() internal pure returns (Lockup.Status[] memory statuses) {
        statuses = new Lockup.Status[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            statuses[i] = Lockup.Status.CANCELED;
        }
    }

    function statusesBeforeCancelMultiple() internal pure returns (Lockup.Status[] memory statuses) {
        statuses = new Lockup.Status[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            statuses[i] = Lockup.Status.ACTIVE;
        }
    }

    function streamIds() internal pure returns (uint256[] memory streamIds_) {
        streamIds_ = new uint256[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            streamIds_[i] = i + 1;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-V2-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDeltas(
        Users memory users,
        address proxy,
        IERC20 asset
    )
        internal
        pure
        returns (LockupDynamic.CreateWithDeltas memory params)
    {
        params = LockupDynamic.CreateWithDeltas({
            asset: asset,
            broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
            cancelable: true,
            recipient: users.recipient.addr,
            segments: segmentsWithDeltas({ amount0: 2500e18, amount1: 7500e18 }),
            sender: proxy,
            totalAmount: PER_STREAM_TOTAL_AMOUNT
        });
    }

    function createWithMilestones(
        Users memory user,
        address proxy,
        IERC20 asset
    )
        internal
        pure
        returns (LockupDynamic.CreateWithMilestones memory params)
    {
        params = LockupDynamic.CreateWithMilestones({
            asset: asset,
            broker: Broker({ account: user.broker.addr, fee: BROKER_FEE }),
            cancelable: true,
            recipient: user.recipient.addr,
            segments: segments({ amount0: 2500e18, amount1: 7500e18 }),
            sender: proxy,
            startTime: START_TIME,
            totalAmount: PER_STREAM_TOTAL_AMOUNT
        });
    }

    function dynamicRange() internal pure returns (LockupDynamic.Range memory) {
        return LockupDynamic.Range({ start: START_TIME, end: END_TIME });
    }

    /// @dev Helper function to return an array of `LockupDynamic.Segment`.
    function segments(
        uint128 amount0,
        uint128 amount1
    )
        internal
        pure
        returns (LockupDynamic.Segment[] memory segments_)
    {
        segments_ = new LockupDynamic.Segment[](2);
        segments_[0] = LockupDynamic.Segment({
            amount: amount0,
            exponent: ud2x18(3.14e18),
            milestone: START_TIME + CLIFF_DURATION
        });
        segments_[1] = LockupDynamic.Segment({
            amount: amount1,
            exponent: ud2x18(3.14e18),
            milestone: START_TIME + TOTAL_DURATION
        });
    }

    /// @dev Helper function to return an array of `LockupDynamic.SegmentWithDelta`.
    function segmentsWithDeltas(
        uint128 amount0,
        uint128 amount1
    )
        internal
        pure
        returns (LockupDynamic.SegmentWithDelta[] memory segments_)
    {
        segments_ = new LockupDynamic.SegmentWithDelta[](2);
        segments_[0] =
            LockupDynamic.SegmentWithDelta({ amount: amount0, exponent: ud2x18(3.14e18), delta: 2500 seconds });
        segments_[1] =
            LockupDynamic.SegmentWithDelta({ amount: amount1, exponent: ud2x18(3.14e18), delta: 7500 seconds });
    }

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-V2-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    function durations() internal pure returns (LockupLinear.Durations memory) {
        return LockupLinear.Durations({ cliff: CLIFF_DURATION, total: TOTAL_DURATION });
    }

    function createWithDurations(
        Users memory users,
        address proxy,
        IERC20 asset
    )
        internal
        pure
        returns (LockupLinear.CreateWithDurations memory params)
    {
        params = LockupLinear.CreateWithDurations({
            asset: asset,
            broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
            durations: durations(),
            cancelable: true,
            recipient: users.recipient.addr,
            sender: proxy,
            totalAmount: PER_STREAM_TOTAL_AMOUNT
        });
    }

    function createWithRange(
        Users memory users,
        address proxy,
        IERC20 asset
    )
        internal
        pure
        returns (LockupLinear.CreateWithRange memory params)
    {
        params = LockupLinear.CreateWithRange({
            asset: asset,
            broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
            cancelable: true,
            range: linearRange(),
            recipient: users.recipient.addr,
            sender: proxy,
            totalAmount: PER_STREAM_TOTAL_AMOUNT
        });
    }

    function linearRange() internal pure returns (LockupLinear.Range memory) {
        return LockupLinear.Range({ start: START_TIME, cliff: CLIFF_TIME, end: END_TIME });
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2-PROXY-TARGET
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to return an array of `Batch.CreateWithDeltas`.
    function batchCreateWithDeltas(
        Users memory users,
        address proxy
    )
        internal
        pure
        returns (Batch.CreateWithDeltas[] memory params)
    {
        params = new Batch.CreateWithDeltas[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            params[i] = Batch.CreateWithDeltas({
                broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
                cancelable: true,
                recipient: users.recipient.addr,
                segments: segmentsWithDeltas({ amount0: 2500e18, amount1: 7500e18 }),
                sender: proxy,
                totalAmount: PER_STREAM_TOTAL_AMOUNT
            });
        }
    }

    /// @dev Helper function to return an array of `Batch.CreateWithDurations`.
    function batchCreateWithDurations(
        Users memory users,
        address proxy
    )
        internal
        pure
        returns (Batch.CreateWithDurations[] memory params)
    {
        params = new Batch.CreateWithDurations[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            params[i] = Batch.CreateWithDurations({
                broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
                cancelable: true,
                durations: durations(),
                recipient: users.recipient.addr,
                sender: proxy,
                totalAmount: PER_STREAM_TOTAL_AMOUNT
            });
        }
    }

    /// @dev Helper function to return an array of `Batch.CreateWithMilestones`.
    function batchCreateWithMilestones(
        Users memory users,
        address proxy
    )
        internal
        pure
        returns (Batch.CreateWithMilestones[] memory params)
    {
        params = new Batch.CreateWithMilestones[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            params[i] = Batch.CreateWithMilestones({
                broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
                cancelable: true,
                recipient: users.recipient.addr,
                segments: segments({ amount0: 2500e18, amount1: 7500e18 }),
                sender: proxy,
                startTime: START_TIME,
                totalAmount: PER_STREAM_TOTAL_AMOUNT
            });
        }
    }

    /// @dev Helper function to return an array of `Batch.CreateWithRange`.
    function batchCreateWithRange(
        Users memory users,
        address proxy
    )
        internal
        pure
        returns (Batch.CreateWithRange[] memory params)
    {
        params = new Batch.CreateWithRange[](BATCH_COUNT);
        for (uint256 i = 0; i < BATCH_COUNT; ++i) {
            params[i] = Batch.CreateWithRange({
                broker: Broker({ account: users.broker.addr, fee: BROKER_FEE }),
                cancelable: true,
                range: linearRange(),
                recipient: users.recipient.addr,
                sender: proxy,
                totalAmount: PER_STREAM_TOTAL_AMOUNT
            });
        }
    }
}
