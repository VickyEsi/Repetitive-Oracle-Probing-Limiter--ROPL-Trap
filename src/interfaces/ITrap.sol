// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITrap Interface
 * @author Drosera Network
 * @notice The interface that all Drosera traps must implement.
 */
interface ITrap {
    /**
     * @notice A view function that collects on-chain data for the trap.
     * This function is executed by Drosera operators.
     * @return The collected data, ABI-encoded.
     */
    function collect() external view returns (bytes memory);

    /**
     * @notice A pure function that decides if a response should be triggered.
     * It receives an array of historical data collected by the `collect` function.
     * @param data An array of ABI-encoded data points from past `collect` calls.
     * @return A boolean indicating if a response is needed, and the data for the response.
     */
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}
