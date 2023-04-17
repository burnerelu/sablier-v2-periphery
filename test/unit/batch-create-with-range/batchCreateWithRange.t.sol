// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Batch } from "src/types/DataTypes.sol";

import { Unit_Test } from "../Unit.t.sol";
import { DefaultParams } from "../../helpers/DefaultParams.t.sol";

contract BatchCreateWithRange_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();

        changePrank({ msgSender: users.sender.addr });
    }

    function test_RevertWhen_BatchEmpty() external {
        Batch.CreateWithRange[] memory params;
        bytes memory data = abi.encodeCall(
            target.batchCreateWithRange, (linear, asset, params, permit2Params(DefaultParams.TRANSFER_AMOUNT))
        );
        vm.expectRevert(Errors.SablierV2ProxyTarget_BatchEmpty.selector);
        proxy.execute(address(target), data);
    }

    modifier whenBatchNotEmpty() {
        _;
    }

    function test_BatchCreateWithRange() external whenBatchNotEmpty {
        // Asset flow: sender -> proxy -> linear
        expectTransferFromCall(users.sender.addr, address(proxy), DefaultParams.TRANSFER_AMOUNT);
        expectMultipleCreateWithRangeCalls(DefaultParams.createWithRange(users, address(proxy), asset));
        expectMultipleTransferCalls(address(proxy), address(linear), DefaultParams.PER_STREAM_TOTAL_AMOUNT);

        uint256[] memory streamIds = batchCreateWithRangeDefault();
        assertEq(streamIds, DefaultParams.streamIds());
    }
}
