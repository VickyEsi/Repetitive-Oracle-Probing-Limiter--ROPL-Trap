// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TargetContract
 * @author Gemini
 * @notice This is the main contract that an attacker might probe.
 * It contains a function that can be rate-limited and the logic to block users.
 * The rate limit is applied by a separate ResponseContract.
 */
contract TargetContract {
    // The address of the ResponseContract, which is authorized to apply rate limits.
    // This is a placeholder and must be replaced with the actual deployed ResponseContract address.
    address public constant RESPONSE_CONTRACT = 0x0000000000000000000000000000000000000001;

    // The duration of the rate limit in seconds.
    uint256 public constant RATE_LIMIT_DURATION = 1 hours;

    // Mapping to store the timestamp until which a user is rate-limited.
    mapping(address => uint256) public rateLimitedUntil;

    // --- Errors ---
    error RateLimited(uint256 expiryTimestamp);
    error Unauthorized();

    // --- Modifiers ---
    modifier onlyResponseContract() {
        if (msg.sender != RESPONSE_CONTRACT) {
            revert Unauthorized();
        }
        _;
    }

    /**
     * @notice A function that is protected by the rate-limiting mechanism.
     * Probing this function repeatedly can get an address rate-limited.
     */
    function guardedOperation() public view {
        if (block.timestamp < rateLimitedUntil[msg.sender]) {
            revert RateLimited(rateLimitedUntil[msg.sender]);
        }
        // In a real-world scenario, this function would perform some state-changing operation.
        // For this PoC, it does nothing if the user is not rate-limited.
    }

    /**
     * @notice Applies a rate limit to a specified user address.
     * Can only be called by the authorized ResponseContract.
     * @param user The address of the user to rate-limit.
     */
    function rateLimitAddress(address user) external onlyResponseContract {
        rateLimitedUntil[user] = block.timestamp + RATE_LIMIT_DURATION;
    }
}
