    // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";

import { Batch } from "src/types/DataTypes.sol";

import { Fork_Test } from "../Fork.t.sol";
import { ArrayBuilder } from "../../utils/ArrayBuilder.sol";
import { BatchBuilder } from "../../utils/BatchBuilder.sol";

/// @dev Runs against multiple fork assets.
abstract contract CreateTwoSubStreams is Fork_Test {
    IERC20 myAsset;
    constructor(IERC20 asset_) Fork_Test(asset_) {
        myAsset = asset_;
    }

    function setUp() public virtual override {
        Fork_Test.setUp();
    }

    function testFork_CreateTwoSubStreams() external {

        // Start by creating a stream having the substreamer contract as recipient

        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.sender = users.alice;
        params.totalAmount = 200;
        params.durations = LockupLinear.Durations({cliff: 0, total: 10});
        params.recipient = address(subStreamer);


        // Alice has 1000 coins
        deal({ token: address(asset), to: params.sender, give: uint256(1000) });

        // Eve has zero coins
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve both protocols to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: 1000});
        asset.approve({ spender: address(subStreamer), amount: 1000});


        uint256 streamId = lockupLinear.createWithDurations(params);

        assertEq(asset.balanceOf(users.alice), 800);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;

        uint16[] memory weights = new uint16[](2);
        weights[0] = 30;
        weights[1] = 70;

        subStreamer.initWrapper(address(wrapper));
        uint256[] memory substreams = subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights);
        assertEq(wrapper.balanceOf(address(lockupLinear)), 200);

        assertEq(substreams[0], streamId + 1);
        assertEq(substreams[1], streamId + 2);

        changePrank({msgSender: users.eve });


        uint256 startTime = lockupLinear.getStartTime(streamId);
        uint256 endTime = lockupLinear.getEndTime(streamId);
        uint256 midTime = startTime + (endTime - startTime) / 2;
        vm.warp({timestamp: midTime});

        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 70);
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 70);
        assertEq(asset.balanceOf(users.eve), 70);

        vm.warp({timestamp: endTime});
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 70);
        assertEq(asset.balanceOf(users.eve), 140);
    }
}
