// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { ISablierV2Lockup } from "@sablier/v2-core/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupLinear } from "@sablier/v2-core/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupDynamic } from "@sablier/v2-core/interfaces/ISablierV2LockupDynamic.sol";
import { LockupDynamic, LockupLinear } from "@sablier/v2-core/types/DataTypes.sol";

import { Batch, Permit2Params } from "../types/DataTypes.sol";

/// @title ISablierV2ProxyTarget
/// @notice Proxy target contract with stateless scripts for interacting with Sablier V2 Core.
/// @dev Meant to be used with an instance of PRBProxy via DELEGATECALL.
interface ISablierV2ProxyTarget {
    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Cancels multiple streams across different lockup contracts.
    ///
    /// @dev Notes:
    /// - All refunded assets are forwarded to the proxy owner.
    /// - It is assumed that the `assets` array includes all the assets associated with `params.streamIds`. If any asset
    /// is missing, the refunded amount will be left in the proxy.
    ///
    /// @param params Struct encapsulating the lockup contract's address and the stream ids to cancel.
    /// @param assets The contract addresses of the ERC-20 assets used for streaming.
    function batchCancelMultiple(Batch.CancelMultiple[] calldata params, IERC20[] calldata assets) external;

    /// @notice Mirror for {ISablierV2Lockup.cancel}.
    function cancel(ISablierV2Lockup lockup, uint256 streamId) external;

    /// @notice Mirror for {ISablierV2Lockup.cancelMultiple}.
    ///
    /// @dev Notes:
    /// - All refunded assets are forwarded to the proxy owner.
    /// - It is assumed that the `assets` array includes all the assets associated with `params.streamIds`. If any asset
    /// is missing, the refunded amount will be left in the proxy.
    ///
    /// @param lockup The address of the lockup streaming contract.
    /// @param assets The contract addresses of the ERC-20 assets used for streaming.
    /// @param streamIds The stream ids to cancel.
    function cancelMultiple(ISablierV2Lockup lockup, IERC20[] calldata assets, uint256[] calldata streamIds) external;

    /// @notice Mirror for {ISablierV2Lockup.renounce}.
    function renounce(ISablierV2Lockup lockup, uint256 streamId) external;

    /// @notice Mirror for {ISablierV2Lockup.withdraw}.
    function withdraw(ISablierV2Lockup lockup, uint256 streamId, address to, uint128 amount) external;

    /// @notice Mirror for {ISablierV2Lockup.withdrawMax}.
    function withdrawMax(ISablierV2Lockup lockup, uint256 streamId, address to) external;

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-V2-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of linear streams with durations. Permit2 is used to transfer the assets from
    /// the caller to the proxy.
    ///
    /// @dev Requirements:
    /// - `fullAmount` must be greater than zero.
    /// - `fullAmount` must be equal to the sum of all amounts in `params`.
    /// - All requirements from {ISablierV2LockupLinear.createWithDurations} must be met for each stream.
    ///
    /// @param linear The address of the {SablierV2LockupLinear} contract.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param fullAmount The amount of assets for all the streams, in units of the asset's decimals.
    /// @param params Struct encapsulating a subset of the parameters of {SablierV2LockupLinear.createWithDurations}.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamIds The ids of the newly created streams.
    function batchCreateWithDurations(
        ISablierV2LockupLinear linear,
        IERC20 asset,
        uint128 fullAmount,
        Batch.CreateWithDurations[] calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of linear streams with range. Permit2 is used to transfer the assets from the
    /// caller to the proxy.
    ///
    /// @dev Requirements:
    /// - `fullAmount` must be greater than zero.
    /// - `fullAmount` must be equal to the sum of all amounts in `params`.
    /// - All requirements from {ISablierV2LockupLinear.createWithRange} must be met for each stream.
    ///
    /// @param linear The address of the {SablierV2LockupLinear} contract.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param fullAmount The amount of assets for all the streams, in units of the asset's decimals.
    /// @param params Struct encapsulating a subset of the parameters of {SablierV2LockupLinear.createWithRange}.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamIds The ids of the newly created streams.
    function batchCreateWithRange(
        ISablierV2LockupLinear linear,
        IERC20 asset,
        uint128 fullAmount,
        Batch.CreateWithRange[] calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Cancels a stream and creates a new one with durations. Permit2 is used to transfer the assets from
    /// the caller to the proxy.
    ///
    /// @dev Notes:
    /// - See {ISablierV2Lockup.cancel} and {ISablierV2LockupLinear.createWithDurations} for full documentation.
    /// - `streamId` can reference either a linear or a dynamic stream.
    ///
    /// @param lockup The address of the lockup streaming contract where the stream to cancel is.
    /// @param linear The address of the {SablierV2LockupLinear} contract to use for creating the new stream.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return newStreamId The id of the newly created stream.
    function cancelAndCreateWithDurations(
        ISablierV2Lockup lockup,
        ISablierV2LockupLinear linear,
        uint256 streamId,
        LockupLinear.CreateWithDurations calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 newStreamId);

    /// @notice Cancels a stream and creates a new one with range. Permit2 is used to transfer the assets from the
    /// caller to the proxy.
    ///
    /// @dev Notes:
    /// - See {ISablierV2Lockup.cancel} and {ISablierV2LockupLinear.createWithRange} for full documentation.
    /// - `streamId` can reference either a linear or a dynamic stream.
    ///
    /// @param lockup The address of the lockup streaming contract where the stream to cancel is.
    /// @param linear The address of the {SablierV2LockupLinear} contract to use for creating the new stream.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return newStreamId The id of the newly created stream.
    function cancelAndCreateWithRange(
        ISablierV2Lockup lockup,
        ISablierV2LockupLinear linear,
        uint256 streamId,
        LockupLinear.CreateWithRange calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 newStreamId);

    /// @notice Mirror for {SablierV2LockupLinear.createWithDurations}. Permit2 is used to transfer the assets from the
    /// caller to the proxy.
    /// @param linear The address of the {SablierV2LockupLinear} contract.
    /// @param params Struct encapsulating the function parameters, which are documented in Sablier V2 Core.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamId The id of the newly created stream.
    function createWithDurations(
        ISablierV2LockupLinear linear,
        LockupLinear.CreateWithDurations calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 streamId);

    /// @notice Mirror for {SablierV2LockupLinear.createWithRange}. Permit2 is used to transfer the assets from the
    /// caller to the proxy.
    /// @param linear The address of the {SablierV2LockupLinear} contract.
    /// @param params Struct encapsulating the function parameters, which are documented in Sablier V2 Core.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamId The id of the newly created stream.
    function createWithRange(
        ISablierV2LockupLinear linear,
        LockupLinear.CreateWithRange calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 streamId);

    /// @notice Wraps the native asset payment in ERC-20 form and creates a linear stream with durations.
    ///
    /// @dev Notes:
    /// - `params.totalAmount` is overwritten with `msg.value`.
    /// - See {ISablierV2LockupLinear.createWithDurations} for full documentation.
    ///
    /// @param linear The address of the {SablierV2LockupLinear} contract.
    function wrapAndCreateWithDurations(
        ISablierV2LockupLinear linear,
        LockupLinear.CreateWithDurations memory params
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Wraps the native asset payment in ERC-20 form and creates a linear stream with range.
    ///
    /// @dev Notes:
    /// - `params.totalAmount` is overwritten with `msg.value`.
    /// - See {ISablierV2LockupLinear.createWithRange} for full documentation.
    ///
    /// @param linear The address of the {SablierV2LockupLinear} contract.
    function wrapAndCreateWithRange(
        ISablierV2LockupLinear linear,
        LockupLinear.CreateWithRange memory params
    )
        external
        payable
        returns (uint256 streamId);

    /*//////////////////////////////////////////////////////////////////////////
                             SABLIER-V2-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Cancels a stream and creates a new one with deltas. Permit2 is used to transfer the assets from
    /// the caller to the proxy.
    ///
    /// @dev Notes:
    /// - See {ISablierV2Lockup.cancel} and {ISablierV2LockupDynamic.createWithDeltas} for full documentation.
    /// - `streamId` can reference either a linear or a dynamic stream.
    ///
    /// @param lockup The address of the lockup streaming contract where the stream to cancel is.
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract to use for creating the new stream.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return newStreamId The id of the newly created stream.
    function cancelAndCreateWithDeltas(
        ISablierV2Lockup lockup,
        ISablierV2LockupDynamic dynamic,
        uint256 streamId,
        LockupDynamic.CreateWithDeltas calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 newStreamId);

    /// @notice Cancels a stream and creates a new one with milestones. Permit2 is used to transfer the assets from
    /// the caller to the proxy.
    ///
    /// @dev Notes:
    /// - See {ISablierV2Lockup.cancel} and {ISablierV2LockupDynamic.createWithMilestones} for full documentation.
    /// - `streamId` can reference either a linear or a dynamic stream.
    ///
    /// @param lockup The address of the lockup streaming contract where the stream to cancel is.
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract to use for creating the new stream.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return newStreamId The id of the newly created stream.
    function cancelAndCreateWithMilestones(
        ISablierV2Lockup lockup,
        ISablierV2LockupDynamic dynamic,
        uint256 streamId,
        LockupDynamic.CreateWithMilestones calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 newStreamId);

    /// @notice Mirror for {SablierV2LockupDynamic.createWithDeltas}. Permit2 is used to transfer the assets from
    /// the caller to the proxy.
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract.
    /// @param params Struct encapsulating the function parameters, which are documented in Sablier V2 Core.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamId The id of the newly created stream.
    function createWithDeltas(
        ISablierV2LockupDynamic dynamic,
        LockupDynamic.CreateWithDeltas calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 streamId);

    /// @notice Mirror for {SablierV2LockupDynamic.createWithMilestones}. Permit2 is used to transfer the assets from
    /// the caller to the proxy.
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract.
    /// @param params Struct encapsulating the function parameters, which are documented in Sablier V2 Core.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamId The id of the newly created stream.
    function createWithMilestones(
        ISablierV2LockupDynamic dynamic,
        LockupDynamic.CreateWithMilestones calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a batch of dynamic streams with deltas. Permit2 is used to transfer the assets from the caller
    /// to the proxy.
    ///
    /// @dev Requirements:
    /// - `fullAmount` must be greater than zero.
    /// - `fullAmount` must be equal to the sum of all amounts in `params`.
    /// - All requirements from {ISablierV2LockupDynamic.createWithDeltas} must be met for each stream.
    ///
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param totalAmount The amount of assets for all the streams, in units of the asset's decimals.
    /// @param params Struct encapsulating a subset of the parameters of {SablierV2LockupDynamic.createWithDeltas}.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamIds The ids of the newly created streams.
    function batchCreateWithDeltas(
        ISablierV2LockupDynamic dynamic,
        IERC20 asset,
        uint128 totalAmount,
        Batch.CreateWithDeltas[] calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of dynamic streams with milestones. Permit2 is used to transfer the assets from the
    /// caller
    /// to the proxy.
    ///
    /// @dev Requirements:
    /// - `fullAmount` must be greater than zero.
    /// - `fullAmount` must be equal to the sum of all amounts in `params`.
    /// - All requirements from {ISablierV2LockupDynamic.createWithMilestones} must be met for each stream.
    ///
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param totalAmount The amount of assets for all the streams, in units of the asset's decimals.
    /// @param params Struct encapsulating a subset of the parameters of {SablierV2LockupDynamic.createWithMilestones}.
    /// @param permit2Params Struct encapsulating the user parameters needed for Permit2.
    /// @return streamIds The ids of the newly created streams.
    function batchCreateWithMilestones(
        ISablierV2LockupDynamic dynamic,
        IERC20 asset,
        uint128 totalAmount,
        Batch.CreateWithMilestones[] calldata params,
        Permit2Params calldata permit2Params
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Wraps the native asset payment in ERC-20 form and creates a dynamic stream with deltas.
    ///
    /// @dev Notes:
    /// - `params.totalAmount` is overwritten with `msg.value`.
    /// - See {ISablierV2LockupDynamic.createWithDeltas} for full documentation.
    ///
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract.
    /// @param params Struct encapsulating the function parameters, which are documented in Sablier V2 Core.
    /// @return streamId The id of the newly created stream.
    function wrapAndCreateWithDeltas(
        ISablierV2LockupDynamic dynamic,
        LockupDynamic.CreateWithDeltas memory params
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Wraps the native asset payment in ERC-20 form and creates a dynamic stream with milestones.
    ///
    /// @dev Notes:
    /// - `params.totalAmount` is overwritten with `msg.value`.
    /// - See {ISablierV2LockupDynamic.createWithMilestones} for full documentation.
    ///
    /// @param dynamic The address of the {SablierV2LockupDynamic} contract.
    /// @param params Struct encapsulating the function parameters, which are documented in Sablier V2 Core.
    /// @return streamId The id of the newly created stream.
    function wrapAndCreateWithMilestones(
        ISablierV2LockupDynamic dynamic,
        LockupDynamic.CreateWithMilestones memory params
    )
        external
        payable
        returns (uint256 streamId);
}
