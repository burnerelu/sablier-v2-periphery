pragma solidity ^0.8.19;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IWERC20 } from "../interfaces/tokens/IWERC20.sol";

// TODO Burnable




contract WERC20 is IWERC20, ERC20, Ownable {
    IERC20 _asset;

    constructor(address asset_, address owner_) ERC20("Wraped Asset Mock", "WERC20") {
        _asset = IERC20(asset_);
        transferOwnership(owner_);
    }

    function asset() external view returns (address) {
        return address(_asset);
    }

    function mint(address account_, uint256 amount_) external {
        _mint(account_, amount_);
    }

    /*
     * Wrap 1 ERC20 token to 1 wERC20; TODO only owner?
     */
    function wrap(uint256 assetAmount_) external returns (uint256) {
        require(assetAmount_ > 0, "WERC20: can't wrap zero tokens");
        _mint(msg.sender, assetAmount_);
        //asset.transferFrom(msg.sender, address(this), assetAmount_);
        return assetAmount_;
    }

    function unwrap(uint256 wrappedAmount_) external returns (uint256) {
        require(wrappedAmount_ > 0, "WERC20: can't wrap zero tokens");
        _burn(msg.sender,wrappedAmount_);

        return wrappedAmount_;
    }
}
