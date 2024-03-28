// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierV2LockupDynamic } from "@sablier/v2-core/src/interfaces/ISablierV2LockupDynamic.sol";
import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";

import { Fuzzers as V2CoreFuzzers } from "@sablier/v2-core/test/utils/Fuzzers.sol";

import { Defaults } from "../utils/Defaults.sol";
import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test, V2CoreFuzzers {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_) {
        asset = asset_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 5579331, urlOrAlias: "sepolia" });

        // Set up the base test contract.
        Base_Test.setUp();

        // Load the external dependencies.
        loadDependencies();

        // Deploy the defaults contract and allow it to access cheatcodes.
        defaults = new Defaults(users, asset);
        vm.allowCheatcodes(address(defaults));

        // Deploy V2 Periphery.
        deployPeripheryConditionally();

        // Label the contracts.
        labelContracts();

        // Approve the relevant contracts.
        approveContracts();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address user, address recipient) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(user != address(0) && recipient != address(0));

        // The goal is to not have overlapping users because the asset balance tests would fail otherwise.
        vm.assume(user != recipient);
        vm.assume(user != address(lockupDynamic) && recipient != address(lockupDynamic));
        vm.assume(user != address(lockupLinear) && recipient != address(lockupLinear));

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(asset), user);
        assumeNoBlacklisted(address(asset), recipient);
    }

    /// @dev Loads all dependencies pre-deployed on Mainnet.
    function loadDependencies() private {
        lockupDynamic = ISablierV2LockupDynamic(0xc9940AD8F43aAD8e8f33A4D5dbBf0a8F7FF4429A);
        lockupLinear = ISablierV2LockupLinear(0x7a43F8a888fa15e68C103E18b0439Eb1e98E4301);
    }
}
