// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITargetContract {
    function rateLimitAddress(address user) external;
}

/**
 * @title ResponseContract
 * @author Gemini
 * @notice This contract is called by the Drosera network upon a successful trap trigger.
 * It calls the TargetContract to apply the rate limit to the offending address.
 */
contract ResponseContract {
    // The address of the TargetContract that this response handler interacts with.
    // This is a placeholder and must be replaced with the actual deployed TargetContract address.
    address public constant TARGET_CONTRACT = 0x0000000000000000000000000000000000000002;

    /**
     * @notice The entrypoint called by the Drosera network.
     * @param responseData The abi-encoded address of the offender to be rate-limited.
     */
    function executeResponse(bytes calldata responseData) external {
        // Decode the offender's address from the response data.
        (address offender) = abi.decode(responseData, (address));

        // Call the TargetContract to apply the rate limit.
        ITargetContract(TARGET_CONTRACT).rateLimitAddress(offender);
    }
}
