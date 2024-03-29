// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { CreateWithMilestones_Batch_Fork_Test } from "../batch/createWithMilestones.t.sol";
import { CreateWithRange_Batch_Fork_Test } from "../batch/createWithRange.t.sol";
import { MerkleStreamerLL_Fork_Test } from "../merkle-streamer/MerkleStreamerLL.t.sol";

IERC20 constant usdt = IERC20(0xc9940AD8F43aAD8e8f33A4D5dbBf0a8F7FF4429A);

contract USDT_CreateWithMilestones_Batch_Fork_Test is CreateWithMilestones_Batch_Fork_Test(usdt) { }

contract USDT_CreateWithRange_Batch_Fork_Test is CreateWithRange_Batch_Fork_Test(usdt) { }

contract USDT_MerkleStreamerLL_Fork_Test is MerkleStreamerLL_Fork_Test(usdt) { }
