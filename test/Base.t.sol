// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { AllowanceTransfer } from "@permit2/AllowanceTransfer.sol";
import { IAllowanceTransfer } from "@permit2/interfaces/IAllowanceTransfer.sol";
import { IPRBProxy } from "@prb/proxy/interfaces/IPRBProxy.sol";
import { PRBProxyRegistry } from "@prb/proxy/PRBProxyRegistry.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SablierV2Comptroller } from "@sablier/v2-core/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "@sablier/v2-core/SablierV2LockupLinear.sol";
import { SablierV2LockupDynamic } from "@sablier/v2-core/SablierV2LockupDynamic.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { SablierV2ProxyTarget } from "src/SablierV2ProxyTarget.sol";

import { SablierV2NFTDescriptor } from "./mockups/SablierV2NFTDescriptor.t.sol";
import { Constants } from "./helpers/Constants.t.sol";

/// @title Base_Test
/// @notice Base test contract with common logic needed by all test contracts.
abstract contract Base_Test is Constants, PRBTest, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20 internal asset = new ERC20("Asset Coin", "Asset");
    AllowanceTransfer internal permit2 = new AllowanceTransfer();

    PRBProxyRegistry internal registry = new PRBProxyRegistry();
    IPRBProxy internal proxy;

    SablierV2Comptroller internal comptroller;
    SablierV2NFTDescriptor internal descriptor = new SablierV2NFTDescriptor();
    SablierV2LockupDynamic internal dynamic;
    SablierV2LockupLinear internal linear;
    SablierV2ProxyTarget internal target;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    struct PrivateKeys {
        uint256 admin;
        uint256 alice;
        uint256 broker;
        uint256 eve;
        uint256 recipient;
        uint256 sender;
    }

    struct Users {
        address payable admin;
        address payable alice;
        address payable broker;
        address payable eve;
        address payable recipient;
        address payable sender;
    }

    IAllowanceTransfer.PermitDetails internal defaultPermitDetails = IAllowanceTransfer.PermitDetails({
        token: address(asset),
        amount: uint160(DEFAULT_TOTAL_AMOUNT),
        expiration: UINT48_MAX,
        nonce: DEFAULT_PERMIT2_NONCE
    });
    PrivateKeys internal privateKeys;
    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        // Deploy the target contract.
        target = new SablierV2ProxyTarget();

        // Label all the contracts just deployed.
        vm.label({ account: address(asset), newLabel: "Asset" });
        vm.label({ account: address(registry), newLabel: "ProxyRegistry" });
        vm.label({ account: address(permit2), newLabel: "Permit2" });
        vm.label({ account: address(target), newLabel: "Target" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        (users.admin, privateKeys.admin) = createUser("Admin");
        (users.alice, privateKeys.alice) = createUser("Alice");
        (users.broker, privateKeys.broker) = createUser("Broker");
        (users.eve, privateKeys.eve) = createUser("Eve");
        (users.recipient, privateKeys.recipient) = createUser("Recipient");
        (users.sender, privateKeys.sender) = createUser("Sender");

        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to get the signature given the `privateKey`.
    function getPermit2Signature(uint256 privateKey, address spender) internal view returns (bytes memory sig) {
        bytes32 permitHash = keccak256(abi.encode(PERMIT_DETAILS_TYPEHASH, defaultPermitDetails));
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_SINGLE_TYPEHASH, permitHash, spender, DEFAULT_PERMIT2_SIG_DEADLINE))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        sig = bytes.concat(r, s, bytes1(v));
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to approve the `permit2` contract to spend ERC-20 assets from
    /// the sender, recipient, Alice and Eve.
    function approvePermit2() internal {
        changePrank({ msgSender: users.sender });
        asset.approve({ spender: address(permit2), amount: UINT256_MAX });
        changePrank({ msgSender: users.recipient });
        asset.approve({ spender: address(permit2), amount: UINT256_MAX });
        changePrank({ msgSender: users.alice });
        asset.approve({ spender: address(permit2), amount: UINT256_MAX });
        changePrank({ msgSender: users.eve });
        asset.approve({ spender: address(permit2), amount: UINT256_MAX });
    }

    /// @dev Generates an address by hashing the name, labels the address and funds it with 100 ETH, 1 million assets.
    function createUser(string memory name) internal returns (address payable, uint256) {
        (address addr, uint256 privateKey) = makeAddrAndKey(name);
        vm.deal({ account: addr, newBalance: 100 ether });
        deal({ token: address(asset), to: addr, give: 1_000_000e18 });
        return (payable(addr), privateKey);
    }

    function deployCore() internal {
        comptroller = new SablierV2Comptroller(users.admin);
        linear = new SablierV2LockupLinear(users.admin, comptroller, descriptor, DEFAULT_MAX_FEE);
        dynamic =
            new SablierV2LockupDynamic(users.admin, comptroller, descriptor, DEFAULT_MAX_FEE, DEFAULT_MAX_SEGMENT_COUNT);
        vm.label({ account: address(comptroller), newLabel: "Comptroller" });
        vm.label({ account: address(dynamic), newLabel: "LockupDynamic" });
        vm.label({ account: address(linear), newLabel: "LockupLinear" });
    }

    /// @dev Expects a call to the `transfer` function of the default ERC-20 asset.
    function expectTransferFromCall(address from, address to, uint256 amount) internal {
        vm.expectCall(address(asset), abi.encodeCall(ERC20.transferFrom, (from, to, amount)));
    }

    /// @dev Expects `BATCH_PARAMS_COUNT` calls to the `transfer` function of the default ERC-20 asset.
    function expectTransferFromCallMutiple(address from, address to, uint256 amount) internal {
        for (uint256 i = 0; i < BATCH_PARAMS_COUNT; ++i) {
            expectTransferFromCall(from, to, amount);
        }
    }
}
