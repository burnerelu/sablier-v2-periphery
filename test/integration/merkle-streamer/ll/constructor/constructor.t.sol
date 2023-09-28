// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupLinear } from "@sablier/v2-core/src/types/DataTypes.sol";

import { SablierV2MerkleStreamerLL } from "src/SablierV2MerkleStreamerLL.sol";

import { MerkleStreamer_Integration_Test } from "../../MerkleStreamer.t.sol";

contract Constructor_MerkleStreamerLL_Integration_Test is MerkleStreamer_Integration_Test {
    /// @dev Needed to prevent "Stack too deep" error
    struct Vars {
        address actualAdmin;
        uint256 actualAllowance;
        address actualAsset;
        bool actualCancelable;
        bool actualTransferable;
        LockupLinear.Durations actualDurations;
        uint40 actualExpiration;
        address actualLockupLinear;
        bytes32 actualMerkleRoot;
        address expectedAdmin;
        uint256 expectedAllowance;
        address expectedAsset;
        bool expectedCancelable;
        bool expectedTransferable;
        LockupLinear.Durations expectedDurations;
        uint40 expectedExpiration;
        address expectedLockupLinear;
        bytes32 expectedMerkleRoot;
    }

    function test_Constructor() external {
        SablierV2MerkleStreamerLL constructedStreamerLL = new SablierV2MerkleStreamerLL(
            users.admin.addr,
            lockupLinear,
            asset,
            defaults.merkleRoot(),
            defaults.EXPIRATION(),
            defaults.durations(),
            defaults.CANCELABLE(), 
            defaults.TRANSFERABLE()
        );

        Vars memory vars;

        vars.actualAdmin = constructedStreamerLL.admin();
        vars.expectedAdmin = users.admin.addr;
        assertEq(vars.actualAdmin, vars.expectedAdmin, "admin");

        vars.actualAsset = address(constructedStreamerLL.asset());
        vars.expectedAsset = address(asset);
        assertEq(vars.actualAsset, vars.expectedAsset, "asset");

        vars.actualMerkleRoot = constructedStreamerLL.merkleRoot();
        vars.expectedMerkleRoot = defaults.merkleRoot();
        assertEq(vars.actualMerkleRoot, vars.expectedMerkleRoot, "merkleRoot");

        vars.actualCancelable = constructedStreamerLL.cancelable();
        vars.expectedCancelable = defaults.CANCELABLE();
        assertEq(vars.actualCancelable, vars.expectedCancelable, "cancelable");

        vars.actualTransferable = constructedStreamerLL.transferable();
        vars.expectedTransferable = defaults.TRANSFERABLE();
        assertEq(vars.actualTransferable, vars.expectedTransferable, "transferable");

        vars.actualExpiration = constructedStreamerLL.expiration();
        vars.expectedExpiration = defaults.EXPIRATION();
        assertEq(vars.actualExpiration, vars.expectedExpiration, "expiration");

        vars.actualLockupLinear = address(constructedStreamerLL.lockupLinear());
        vars.expectedLockupLinear = address(lockupLinear);
        assertEq(vars.actualLockupLinear, vars.expectedLockupLinear, "lockupLinear");

        (vars.actualDurations.cliff, vars.actualDurations.total) = constructedStreamerLL.streamDurations();
        vars.expectedDurations = defaults.durations();
        assertEq(vars.actualDurations.cliff, vars.expectedDurations.cliff, "durations.cliff");
        assertEq(vars.actualDurations.total, vars.expectedDurations.total, "durations.total");

        vars.actualAllowance = asset.allowance(address(constructedStreamerLL), address(lockupLinear));
        vars.expectedAllowance = MAX_UINT256;
        assertEq(vars.actualAllowance, vars.expectedAllowance, "allowance");
    }
}
