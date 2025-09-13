// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrap} from "./interfaces/ITrap.sol";
import {TargetContract} from "./TargetContract.sol";

/**
 * @title RateLimiterTrap
 * @author Gemini
 * @notice A Drosera trap to detect repetitive transaction patterns from a single address.
 * This trap is stateless and relies on the data provided by the Drosera network.
 */
contract RateLimiterTrap is ITrap {
    // The number of times an address can call the target contract in a short period before being flagged.
    uint256 public constant PROBE_THRESHOLD = 5;

    TargetContract public immutable TARGET_CONTRACT;

    struct AddressCount {
        address addr;
        uint256 count;
    }

    constructor(address targetContractAddress) {
        TARGET_CONTRACT = TargetContract(targetContractAddress);
    }

    /**
     * @notice Collects the recent callers from the TargetContract.
     * The Drosera node infrastructure calls this function for transactions targeting a specific contract.
     * @return abi-encoded address[] of the recent callers.
     */
    function collect() external view override returns (bytes memory) {
        return abi.encode(TARGET_CONTRACT.getRecentCallers());
    }

    /**
     * @notice Determines if a response should be triggered based on historical data.
     * @param data An array of abi-encoded `address[]` from recent collect calls.
     * @return A boolean indicating whether to respond, and the response data (the offender's address).
     * @dev The time window for this trap is not based on block timestamps, but on the number of
     * transactions sampled, which is configured by `block_sample_size` in `drosera.toml`.
     */
    function shouldRespond(
        bytes[] calldata data
    ) external pure override returns (bool, bytes memory) {
        // This is an in-memory counter. It does NOT use contract storage.
        // Note: This approach has a potential gas limit issue if `data` is extremely large.
        AddressCount[] memory addressCounts = new AddressCount[](data.length * 100); // Assuming a max of 100 addresses per block sample
        uint256 uniqueAddresses = 0;

        for (uint256 i = 0; i < data.length; i++) {
            address[] memory recentCallers = abi.decode(data[i], (address[]));
            for (uint256 j = 0; j < recentCallers.length; j++) {
                address offender = recentCallers[j];
                if (offender != address(0)) {
                    bool found = false;
                    for (uint256 k = 0; k < uniqueAddresses; k++) {
                        if (addressCounts[k].addr == offender) {
                            addressCounts[k].count++;
                            found = true;
                            if (addressCounts[k].count >= PROBE_THRESHOLD) {
                                return (true, abi.encode(offender));
                            }
                            break;
                        }
                    }
                    if (!found) {
                        addressCounts[uniqueAddresses] = AddressCount(offender, 1);
                        uniqueAddresses++;
                    }
                }
            }
        }

        return (false, bytes(""));
    }
}
