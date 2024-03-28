pragma solidity ^0.8.19;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ISablierV2LockupLinear } from "@sablier/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2SubStreamer } from "./interfaces/ISablierV2SubStreamer.sol";
import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IWERC20 } from "./interfaces/tokens/IWERC20.sol";
import { Lockup, LockupDynamic, LockupLinear, Broker } from "@sablier/v2-core/src/types/DataTypes.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

contract SablierV2SubStreamer is ISablierV2SubStreamer {
    using SafeERC20 for IERC20;

    IWERC20 wrappedAsset;

    mapping(uint256 => uint256[]) private substreams;
    mapping(uint256 => mapping(address => uint256)) private streams;
    mapping(uint256 => uint256) private parentStream;

    /* Initializes token wrapper variable with address of contract */
    function initWrapper(address wrapper) public
    {
        wrappedAsset = IWERC20(wrapper);
    }

    /* Public getters */
    function getSubStream(uint256 streamId, address receiver) public view returns (uint256)
    {
        require(streamId > 0, "Stream id must be greater than 0");
        //TODO check if exists
        return streams[streamId][receiver];
    }

    /* This should have been a modifier, but I had stack size issues */
    function _checkCorrectWeights(uint16[] calldata weightsPercent) private pure {
        {
            uint16 totalSum;
            for(uint8 i = 0; i < weightsPercent.length; i++)
            {
                require((weightsPercent[i] > 0) && (weightsPercent[i] < 100), "Weight invalid");
                totalSum += weightsPercent[i];
            }
            require(totalSum <= 100, "Weight sum invalid");
        }
    }

    /* Weghts must be in percents (0-100) */
    function createLinearSubStreamsWithDuration(
        uint256 streamId,
        ISablierV2LockupLinear lockupLinear,
        address[] calldata recipients,
        uint16[] calldata weightsPercent
    ) public  returns (uint256[] memory)
    {
        // Verifies weights and their sum. Should have been a modifier, but I had stack size issues
        _checkCorrectWeights(weightsPercent);
        // Let's first check the source stream id exists
        LockupLinear.Stream memory stream = lockupLinear.getStream(streamId);

        // Check recipent
        require(lockupLinear.getRecipient(streamId) == address(this), "Recipient of provided stream is not current contract");

        // determine number of people to pay
        require(recipients.length < 10, "Too many recipients");
        uint128 recipientsSize = uint128(recipients.length);

        for (uint8 i = 0; i < recipientsSize; i++) {
            // compute how many wrapped coins to create
            uint128 amount = stream.amounts.deposited * weightsPercent[i] / 100;

            // wrap currency   TODO add limit?
            wrappedAsset.wrap(amount);

            require(wrappedAsset.balanceOf(address(this)) == amount, "Failed to mint wrapped coin");

            wrappedAsset.approve({spender: address(lockupLinear), amount: amount});

            uint256 subStreamId = lockupLinear.createWithDurations(
                LockupLinear.CreateWithDurations({
                    asset: wrappedAsset,
                    broker: Broker({account: address(0), fee: ud(0) }), // TODO check what we should put here
                    cancelable: stream.isCancelable, // TODO check how to hook cancels
                    durations: LockupLinear.Durations({ cliff: stream.cliffTime - stream.startTime, total: stream.endTime - stream.startTime}), // TODO TODO TODO TODO TODO why not end - start?
                    recipient: address(this),
                    sender: msg.sender, // doesn't matter
                    totalAmount: amount, // TODO ask about protocol fee and broker fee => How can i see net value
                    transferable: true // TODO ...
                })
            );

            streams[streamId][recipients[i]] = subStreamId;
            substreams[streamId].push(subStreamId);
            parentStream[subStreamId] = streamId;
        }
        return substreams[streamId];
    }


    function withdraw(ISablierV2LockupLinear lockupLinear, uint256 subStreamId, address to, uint128 amount) public {

        // TODO permissions?
        uint256 streamId = parentStream[subStreamId];

        require(streams[streamId][msg.sender] == subStreamId, "Invalid requester");

        // Safe to downast
        uint128 recipientsSize = uint128(substreams[streamId].length);

        // Value that can be withdrawn from parent stream
        uint128 withdrawable = lockupLinear.withdrawableAmountOf(subStreamId);
        require(amount <= withdrawable, "Exceeding withdrawable amount");

        // withdraw performs actual check
        lockupLinear.withdraw(subStreamId, address(this), amount);

        // Unwrap the tokens:
        wrappedAsset.unwrap(amount);

        IERC20 asset = lockupLinear.getAsset(streamId);
        lockupLinear.withdraw(streamId, address(this), amount);

        asset.safeTransfer({to: to, value: amount});

    }



}
