    // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";

import { Batch } from "src/types/DataTypes.sol";

import { Fork_Test } from "../Fork.t.sol";
import { ArrayBuilder } from "../../utils/ArrayBuilder.sol";
import { BatchBuilder } from "../../utils/BatchBuilder.sol";

/// @dev Runs against multiple fork assets.
abstract contract SubStreamerTester is Fork_Test {
    IERC20 myAsset;
    constructor(IERC20 asset_) Fork_Test(asset_) {
        myAsset = asset_;
    }

    function setUp() public virtual override {
        Fork_Test.setUp();
    }

    /* Test: GoodWeatherNoCliff
       Expected failure: - (good weather)
       Description: Send 200 tokens to substreamer contract and divide them 50-50 between two users.
       Tokens sent: 200
       Cliff: 0 (taken from initial stream)
       Total duration: 10 (taken from initial stream)
    */
    function testFork_GoodWeatherNoCliff() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 0;
        uint40 duration = 10;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: cliff, total: duration});
        params.recipient = address(subStreamer);

        // Deal 1000 coins to alice
        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        // Dea zero coins to Eve
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve LockupLinear to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        // Create initial stream
        uint256 streamId = lockupLinear.createWithDurations(params);

        // Verify Alice's balance
        assertEq(asset.balanceOf(users.alice), coinsDealt - coinsTransfered);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;

        uint128[] memory weights = new uint128[](2);
        weights[0] = 50;
        weights[1] = 50;


        uint256[] memory substreams = subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff, duration);

        // Check balance of WERC20 of the lockupLinear contract
        assertEq(wrapper.balanceOf(address(lockupLinear)), coinsTransfered);

        // Check the two streams have been created
        assertEq(substreams[0], streamId + 1);
        assertEq(substreams[1], streamId + 2);


        changePrank({msgSender: users.eve });

        uint256 startTime = lockupLinear.getStartTime(streamId);
        uint256 endTime = lockupLinear.getEndTime(streamId);
        uint256 midTime = startTime + (endTime - startTime) / 2;

        // pass time until half duration
        vm.warp({timestamp: midTime});

        // 50% of 200 coins is 100. After half the time passes, Eve should be able to withdraw 50 coins

        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 50);
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 50);
        assertEq(asset.balanceOf(users.eve), 50);

        // Withdraw all of it at the end
        vm.warp({timestamp: endTime});
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 50);
        assertEq(asset.balanceOf(users.eve), 100);
    }

    /* Test: GoodWeatherCliffAndWeights
       Expected failure: - (good weather)
       Description: Send 200 tokens to substreamer contract and divide them 30-70 between two users.
        - Eve should not be able to withdraw anything at midtime, but should be able to withdraw
        75% of it at 75% of time passed (105) coins. Test ends by withdrawing everything at the end (140)
       Tokens sent: 200
       Cliff: 13 (taken from initial stream)
       Total duration: 20 (taken from initial stream)
    */
    function testFork_GoodWeatherCliffAndWeights() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 13;
        uint40 duration = 20;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: cliff, total: duration});
        params.recipient = address(subStreamer);

        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        changePrank({ msgSender: params.sender });

        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        uint256 streamId = lockupLinear.createWithDurations(params);

        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;

        uint128[] memory weights = new uint128[](2);
        weights[0] = 30;
        weights[1] = 70;

        uint256[] memory substreams = subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff, duration);

        assertEq(wrapper.balanceOf(address(lockupLinear)), coinsTransfered);

        assertEq(substreams[0], streamId + 1);
        assertEq(substreams[1], streamId + 2);


        changePrank({msgSender: users.eve });

        uint256 startTime = lockupLinear.getStartTime(streamId);
        uint256 endTime = lockupLinear.getEndTime(streamId);
        uint256 midTime = startTime + (endTime - startTime) / 2;
        uint256 thirdQTime = midTime + (endTime - midTime) / 2;

        // pass time until half duration
        vm.warp({timestamp: midTime});

        // Due to cliff, Eve should not be able to withdraw
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 0);

        // Warp to third quarter (75%) of time passed
        vm.warp({timestamp: thirdQTime});
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 105);

        // Withdraw all of it at the end
        vm.warp({timestamp: endTime});

        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 140);
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 140);
        assertEq(asset.balanceOf(users.eve), 140);
    }

    /* Test: GoodWeatherNoCliffToCliff
       Expected failure: - (good weather)
       Description: Send 200 tokens to substreamer contract and divide them 30-70 between two users.
        - Eve should not be able to withdraw anything at midtime, although parent stream has a null cliff time.
       Tokens sent: 200
       Cliff: 13
       Total duration: 20 (taken from initial stream)
    */
    function testFork_GoodWeatherNoCliffToCliff() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 13; // only used for substreamer
        uint40 duration = 20;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: 0, total: duration});
        params.recipient = address(subStreamer);

        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        changePrank({ msgSender: params.sender });

        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        uint256 streamId = lockupLinear.createWithDurations(params);

        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;

        uint128[] memory weights = new uint128[](2);
        weights[0] = 30;
        weights[1] = 70;

        uint256[] memory substreams = subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff, duration);

        assertEq(wrapper.balanceOf(address(lockupLinear)), coinsTransfered);

        assertEq(substreams[0], streamId + 1);
        assertEq(substreams[1], streamId + 2);

        changePrank({msgSender: users.eve });

        uint256 startTime = lockupLinear.getStartTime(streamId);
        uint256 endTime = lockupLinear.getEndTime(streamId);
        uint256 midTime = startTime + (endTime - startTime) / 2;
        uint256 thirdQTime = midTime + (endTime - midTime) / 2;

        // pass time until half duration
        vm.warp({timestamp: midTime});

        // Eve should not be able to withdraw, but parent stream should
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 0);
        assertEq(lockupLinear.withdrawableAmountOf(streamId), 100);

        // Warp to third quarter (75%) of time passed
        vm.warp({timestamp: thirdQTime});
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 105);

        // Withdraw all of it at the end
        vm.warp({timestamp: endTime});

        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 140);
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 140);
        assertEq(asset.balanceOf(users.eve), 140);
    }


    /* Test: GoodWeatherNoCliffToCliffAndLongerDuration
       Expected failure: - (good weather)
       Description: Send 200 tokens to substreamer contract and divide them 50-50 between two users.
        - Same as before, but duration is longer
       Tokens sent: 200
       Cliff: 13
       Total duration: 20 parent, 30 children
    */
    function testFork_GoodWeatherNoCliffToCliffAndLongerDuration() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 13; // only used for substreamer
        uint40 duration_parent = 20;
        uint40 duration_child = 30;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: 0, total: duration_parent});
        params.recipient = address(subStreamer);

        // Deal 1000 coins to alice
        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        // Deal zero coins to Eve
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve LockupLinear to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        // Create initial stream
        uint256 streamId = lockupLinear.createWithDurations(params);

        // Verify Alice's balance
        assertEq(asset.balanceOf(users.alice), coinsDealt - coinsTransfered);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;

        uint128[] memory weights = new uint128[](2);
        weights[0] = 50;
        weights[1] = 50;

        uint256[] memory substreams = subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff, duration_child);

        // Check balance of WERC20 of the lockupLinear contract
        assertEq(wrapper.balanceOf(address(lockupLinear)), coinsTransfered);

        // Check the two streams have been created
        assertEq(substreams[0], streamId + 1);
        assertEq(substreams[1], streamId + 2);


        changePrank({msgSender: users.eve });

        uint256 startTimeParent = lockupLinear.getStartTime(streamId);
        uint256 endTimeParent = lockupLinear.getEndTime(streamId);
        uint256 midTimeParent = startTimeParent + (endTimeParent - startTimeParent) / 2;
        uint256 thirdQTimeParent = midTimeParent + (endTimeParent - midTimeParent) / 2;
        uint256 endTimeChild = startTimeParent + duration_child;

        // pass time until half duration for parent (t = 10)
        vm.warp({timestamp: midTimeParent});

        // Eve should not be able to withdraw, but parent stream should
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 0);
        assertEq(lockupLinear.withdrawableAmountOf(streamId), 100);

        // Warp to third quarter (75%) of time for parent passed (15s)
        vm.warp({timestamp: thirdQTimeParent});
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 50);
        assertEq(lockupLinear.withdrawableAmountOf(streamId), 150); // half of 30s

        // Withdraw all of it at the end
        vm.warp({timestamp: endTimeChild});

        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 100);
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 100);
        assertEq(asset.balanceOf(users.eve), 100);
    }

    // Bad weather

    /* Not handling cases handled by lockupLinear:
     *  - empty or invalid stream number
     *
     */

    /* Test: BadWeatherArgs
       Expected failure: Wrong cliff size, wrong duration size, wrong weight, wrong wight sum
       Description: Validate input arguments
    */
    function testFork_BadWeatherArgs() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 13; // only used for substreamer
        uint40 duration = 20;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: cliff, total: duration});
        params.recipient = address(subStreamer);

        // Deal 1000 coins to alice
        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        // Deal zero coins to Eve
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve LockupLinear to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        // Create initial stream
        uint256 streamId = lockupLinear.createWithDurations(params);

        // Verify Alice's balance
        assertEq(asset.balanceOf(users.alice), coinsDealt - coinsTransfered);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;


        uint128[] memory wrongWeights = new uint128[](2);
        wrongWeights[0] = 0;
        wrongWeights[1] = 100;


        uint128[] memory wrongWeightsSum = new uint128[](2);
        wrongWeightsSum[0] = 55;
        wrongWeightsSum[1] = 55;

        uint128[] memory weights = new uint128[](2);
        weights[0] = 50;
        weights[1] = 50;

        vm.expectRevert(bytes("Cliff time of child stream must be later in time than cliff time of parent"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff-1, duration);
        vm.expectRevert(bytes("Duration of child stream cannot be smaller than duration of parent"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff, duration-1);

        vm.expectRevert(bytes("Weight invalid"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, wrongWeights, cliff, duration);
        vm.expectRevert(bytes("Weight sum invalid"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, wrongWeightsSum, cliff, duration);

    }

/* Test: BadWeatherArgs
       Expected failure: Wrong cliff size, wrong duration size, wrong weight, wrong wight sum
       Description: Validate input arguments
    */
    function testFork_BadWeatherRecipient() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 13; // only used for substreamer
        uint40 duration = 20;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: cliff, total: duration});
        params.recipient = users.eve;

        // Deal 1000 coins to alice
        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        // Deal zero coins to Eve
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve LockupLinear to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        // Create initial stream
        uint256 streamId = lockupLinear.createWithDurations(params);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;

        address[] memory tooManyRecipients = new address[](20);
        uint128[] memory tooManyWeights = new uint128[](20);
        for(uint i = 0; i < 20; i++)
        {
            tooManyRecipients[i] = users.eve;
            tooManyWeights[i] = 5;
        }

        uint128[] memory weightsThree = new uint128[](3);
        weightsThree[0] = 30;
        weightsThree[1] = 30;
        weightsThree[2] = 30;

        uint128[] memory weights = new uint128[](2);
        weights[0] = 50;
        weights[1] = 50;

        vm.expectRevert(bytes("Recipient of provided stream is not current contract"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, cliff, duration);
        vm.expectRevert(bytes("Too many recipients"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, tooManyRecipients, tooManyWeights, cliff, duration);
        vm.expectRevert(bytes("Recipients and weight sizes do not match"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weightsThree, cliff, duration);


    }

    /* Test: BadWeatherRecipientNull
       Expected failure: Null recipient
       Description: Validate input arguments
    */
    function testFork_BadWeatherRecipientNull() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 cliff = 13; // only used for substreamer
        uint40 duration = 20;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: cliff, total: duration});
        params.recipient = address(subStreamer);

        // Deal 1000 coins to alice
        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        // Deal zero coins to Eve
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve LockupLinear to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        // Create initial stream
        uint256 streamId = lockupLinear.createWithDurations(params);

        // Verify Alice's balance
        assertEq(asset.balanceOf(users.alice), coinsDealt - coinsTransfered);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;


        address[] memory badRecipients = new address[](2);
        badRecipients[0] = address(0);
        badRecipients[1] = users.eve;
        uint128[] memory weights = new uint128[](2);
        weights[0] = 50;
        weights[1] = 50;


        vm.expectRevert(bytes("Cannot send to null recipient"));
        subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, badRecipients, weights, cliff, duration);

    }

    /* Test: BadWeatherWithdraw
       Expected failure: Cannot withdraw
    */
    function testFork_BadWeatherWithdraw() external {

        uint128 coinsTransfered = 200;
        uint128 coinsDealt = 1000;
        uint40 duration = 20;
        // Start by creating a stream having the substreamer contract as recipient
        LockupLinear.CreateWithDurations memory params = defaults.createWithDurations(asset);
        params.cancelable = false;
        params.totalAmount = coinsTransfered;
        params.durations = LockupLinear.Durations({cliff: 0, total: duration});
        params.recipient = address(subStreamer);

        // Deal 1000 coins to alice
        deal({ token: address(asset), to: params.sender, give: coinsDealt });

        // Deal zero coins to Eve
        deal({ token: address(asset), to: users.eve, give: uint256(0)});

        // Switching to Alice
        changePrank({ msgSender: params.sender });

        // Approve LockupLinear to spend on behalf of Alice
        asset.approve({ spender: address(lockupLinear), amount: coinsTransfered});

        // Create initial stream
        uint256 streamId = lockupLinear.createWithDurations(params);

        // Verify Alice's balance
        assertEq(asset.balanceOf(users.alice), coinsDealt - coinsTransfered);

        // Call substreamer
        address[] memory recipients = new address[](2);
        recipients[0] = users.admin;
        recipients[1] = users.eve;


        uint128[] memory weights = new uint128[](2);
        weights[0] = 50;
        weights[1] = 50;


        uint256[] memory substreams = subStreamer.createLinearSubStreamsWithDuration(streamId, lockupLinear, recipients, weights, 0, duration);

        changePrank({msgSender: users.eve });

        uint256 startTime = lockupLinear.getStartTime(streamId);
        uint256 endTime = lockupLinear.getEndTime(streamId);
        uint256 midTime = startTime + (endTime - startTime) / 2;

        // pass time until half duration
        vm.warp({timestamp: midTime});

        // 50% of 200 coins is 100. After half the time passes, Eve should be able to withdraw 50 coins

        assertEq(lockupLinear.withdrawableAmountOf(substreams[0]), 50);
        assertEq(lockupLinear.withdrawableAmountOf(substreams[1]), 50);
        vm.expectRevert(bytes("Invalid requester"));
        subStreamer.withdraw(lockupLinear, substreams[0], users.eve, 50);
        vm.expectRevert(bytes("Exceeding withdrawable amount"));
        subStreamer.withdraw(lockupLinear, substreams[1], users.eve, 51);


    }





}
