import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";

pragma solidity ^0.8.19;


interface ISablierV2SubStreamer {

    function initWrapper(address wrapper) external;

    function getSubStream(uint256 streamId, address receiver) external view returns (uint256);

    function createLinearSubStreamsWithDuration(uint256 streamId, ISablierV2LockupLinear lockupLinear, address[] calldata receivers, uint16[] calldata weightsPercent) external returns (uint256[] memory);

    function withdraw(ISablierV2LockupLinear lockupLinear, uint256 subStreamId, address to, uint128 amount) external;


}
