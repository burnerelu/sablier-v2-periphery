pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWERC20 is IERC20 {
    // return address of the wrapped asset
    function asset() external returns (address);

    // wrap asset
    function wrap(uint256 _assetAmount) external returns (uint256);

    // unwrap
    function unwrap(uint256 _wrappedAmount) external returns (uint256);
}
