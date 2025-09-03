// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "./interfaces/ITrap.sol";

/**
 * @title RateLimiterTrap
 * @author Gemini
 * @notice A Drosera trap to detect repetitive transaction patterns from a single address.
 * This trap is stateless and relies on the data provided by the Drosera network.
 */
contract RateLimiterTrap is ITrap {
    // The number of times an address can call the target contract in a short period before being flagged.
    uint256 public constant PROBE_THRESHOLD = 5;

    /**
     * @notice Collects the transaction originator's address.
     * The Drosera node infrastructure calls this function for transactions targeting a specific contract.
     * @return abi-encoded address of the transaction originator (tx.origin).
     */
    function collect() external view override returns (bytes memory) {
        return abi.encode(tx.origin);
    }

    /**
     * @notice Determines if a response should be triggered based on historical data.
     * @param data An array of abi-encoded `tx.origin` addresses from recent transactions.
     * @return A boolean indicating whether to respond, and the response data (the offender's address).
     */
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        if (data.length <= PROBE_THRESHOLD) {
            return (false, "");
        }

        // This is an in-memory map to count occurrences. It does NOT use contract storage.
        // It is only used for the duration of this function call.
        // Note: This approach has a potential gas limit issue if `data` is extremely large
        // and has many unique addresses. For a typical Drosera setup, this is manageable.
        address[] memory uniqueAddresses = new address[](data.length);
        uint256[] memory counts = new uint256[](data.length);
        uint256 uniqueCount = 0;

        for (uint256 i = 0; i < data.length; i++) {
            address offender = abi.decode(data[i], (address));
            bool found = false;

            // Find the address in our temporary list and increment its count.
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (uniqueAddresses[j] == offender) {
                    counts[j]++;
                    found = true;
                    break;
                }
            }

            // If not found, add it to the list.
            if (!found) {
                uniqueAddresses[uniqueCount] = offender;
                counts[uniqueCount] = 1;
                uniqueCount++;
            }
        }

        // Check if any address has exceeded the probe threshold.
        for (uint256 i = 0; i < uniqueCount; i++) {
            if (counts[i] > PROBE_THRESHOLD) {
                // Trigger a response with the offender's address.
                return (true, abi.encode(uniqueAddresses[i]));
            }
        }

        return (false, "");
    }
}
