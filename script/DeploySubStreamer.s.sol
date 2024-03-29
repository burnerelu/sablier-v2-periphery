// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19 <0.9.0;

import { BaseScript } from "./Base.s.sol";

import { SablierV2SubStreamer } from "../src/SablierV2SubStreamer.sol";
import { WERC20 } from "../src/tokens/WERC20.sol";

contract DeploySubStreamer is BaseScript {
    function run()
        public
        broadcast
        returns (SablierV2SubStreamer subStreamer, WERC20 wrapper)
    {
        subStreamer = new SablierV2SubStreamer();
        wrapper = new WERC20(0x776b6fC2eD15D6Bb5Fc32e0c89DE68683118c62A, address(subStreamer));
    }
}
