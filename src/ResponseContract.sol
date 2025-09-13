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
    address public immutable TARGET_CONTRACT;
    address public immutable GUARDIAN;

    modifier onlyGuardian() {
        require(msg.sender == GUARDIAN, "Only guardian can call this function");
        _;
    }

    constructor(address target, address guardian) {
        TARGET_CONTRACT = target;
        GUARDIAN = guardian;
    }

    /**
     * @notice The entrypoint called by the Drosera network.
     * @param responseData The abi-encoded address of the offender to be rate-limited.
     */
    function executeResponse(bytes calldata responseData) external onlyGuardian {
        // Decode the offender's address from the response data.
        (address offender) = abi.decode(responseData, (address));

        // Call the TargetContract to apply the rate limit.
        ITargetContract(TARGET_CONTRACT).rateLimitAddress(offender);
    }
}
