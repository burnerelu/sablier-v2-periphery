// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { Broker, LockupPro } from "@sablier/v2-core/types/DataTypes.sol";

import { Batch } from "src/types/DataTypes.sol";

import { Base_Test } from "../Base.t.sol";

contract Unit_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        approvePermit2();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to return an array of `Batch.CreateWithDeltas` that is not "storage ref".
    function defaultDeltasParams() internal view returns (Batch.CreateWithDeltas[] memory) {
        Batch.CreateWithDeltas[] memory params = new Batch.CreateWithDeltas[](PARAMS_COUNT);

        for (uint256 i = 0; i < PARAMS_COUNT; ++i) {
            params[i] = Batch.CreateWithDeltas({
                amount: DEFAULT_AMOUNT,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE }),
                cancelable: true,
                recipient: users.recipient,
                segments: defaultSegmentsWithDeltas(),
                sender: users.sender
            });
        }

        return params;
    }

    /// @dev Helper function to return an array of `Batch.CreateWithDurations` that is not "storage ref".
    function defaultDurationsParams() internal view returns (Batch.CreateWithDurations[] memory) {
        Batch.CreateWithDurations[] memory params = new Batch.CreateWithDurations[](PARAMS_COUNT);

        for (uint256 i = 0; i < PARAMS_COUNT; ++i) {
            params[i] = Batch.CreateWithDurations({
                amount: DEFAULT_AMOUNT,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE }),
                cancelable: true,
                durations: DEFAULT_DURATIONS,
                recipient: users.recipient,
                sender: users.sender
            });
        }

        return params;
    }

    /// @dev Helper function to return an array of `Batch.CreateWithMilestones` that is not "storage ref".
    function defaultMilestonesParams() internal view returns (Batch.CreateWithMilestones[] memory) {
        Batch.CreateWithMilestones[] memory params = new Batch.CreateWithMilestones[](PARAMS_COUNT);

        for (uint256 i = 0; i < PARAMS_COUNT; ++i) {
            params[i] = Batch.CreateWithMilestones({
                amount: DEFAULT_AMOUNT,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE }),
                cancelable: true,
                recipient: users.recipient,
                segments: defaultSegments(),
                sender: users.sender,
                startTime: DEFAULT_START_TIME
            });
        }

        return params;
    }

    /// @dev Helper function to return an array of `Batch.CreateWithRange` that is not "storage ref".
    function defaultRangeParams() internal view returns (Batch.CreateWithRange[] memory) {
        Batch.CreateWithRange[] memory params = new Batch.CreateWithRange[](PARAMS_COUNT);

        for (uint256 i = 0; i < PARAMS_COUNT; ++i) {
            params[i] = Batch.CreateWithRange({
                amount: DEFAULT_AMOUNT,
                broker: Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE }),
                cancelable: true,
                range: DEFAULT_LINEAR_RANGE,
                recipient: users.recipient,
                sender: users.sender
            });
        }

        return params;
    }

    /// @dev Helper function to return an array of `LockupPro.Segment` that is not "storage ref".
    function defaultSegments() internal view returns (LockupPro.Segment[] memory) {
        LockupPro.Segment[] memory segments = new LockupPro.Segment[](2);

        segments[0] = LockupPro.Segment({
            amount: 2_500e18,
            exponent: ud2x18(3.14e18),
            milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
        });
        segments[1] = LockupPro.Segment({
            amount: 2_500e18,
            exponent: ud2x18(3.14e18),
            milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
        });

        return segments;
    }

    /// @dev Helper function to return an array of `LockupPro.SegmentWithDelta` that is not "storage ref".
    function defaultSegmentsWithDeltas() internal pure returns (LockupPro.SegmentWithDelta[] memory) {
        LockupPro.SegmentWithDelta[] memory segments = new LockupPro.SegmentWithDelta[](2);

        segments[0] = LockupPro.SegmentWithDelta({ amount: 2_500e18, delta: 2_500 seconds, exponent: ud2x18(3.14e18) });
        segments[1] = LockupPro.SegmentWithDelta({ amount: 2_500e18, delta: 2_500 seconds, exponent: ud2x18(3.14e18) });

        return segments;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates default deltas streams.
    function createWithDeltasMultipleDefault() internal returns (uint256[] memory streamIds) {
        streamIds = target.createWithDeltasMultiple(
            pro,
            asset,
            DEFAULT_TOTAL_AMOUNT,
            defaultDeltasParams(),
            defaultPermit2Params
        );
    }

    /// @dev Creates default durations streams.
    function createWithDurationsMultipleDefault() internal returns (uint256[] memory streamIds) {
        streamIds = target.createWithDurationsMultiple(
            linear,
            asset,
            DEFAULT_TOTAL_AMOUNT,
            defaultDurationsParams(),
            defaultPermit2Params
        );
    }

    /// @dev Creates default milestones streams.
    function createWithMilestonesMultipleDefault() internal returns (uint256[] memory streamIds) {
        streamIds = target.createWithMilestonesMultiple(
            pro,
            asset,
            DEFAULT_TOTAL_AMOUNT,
            defaultMilestonesParams(),
            defaultPermit2Params
        );
    }

    /// @dev Creates default range streams.
    function createWithRangeMultipleDefault() internal returns (uint256[] memory streamIds) {
        streamIds = target.createWithRangeMultiple(
            linear,
            asset,
            DEFAULT_TOTAL_AMOUNT,
            defaultRangeParams(),
            defaultPermit2Params
        );
    }
}
