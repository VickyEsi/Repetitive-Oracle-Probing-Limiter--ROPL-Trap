# Repetitive Oracle-Probing Rate Limiter Trap

This project is a proof-of-concept (PoC) implementation of a Drosera security trap designed to protect smart contracts from a specific type of malicious behavior: repetitive probing.

## The Problem: Oracle Probing

DeFi protocols, especially those involving lending, borrowing, or derivatives, often rely on external price oracles (like Chainlink) to function. Attackers can try to find vulnerabilities or favorable conditions by rapidly sending transactions that interact with the protocol, causing them to revert or succeed based on the oracle's current price. This "probing" can be a precursor to a more significant attack, such as price manipulation or exploiting a liquidation mechanism.

This trap aims to detect and mitigate this behavior in a reactive manner.

## How It Works: A Reactive Defense

This system follows Drosera's reactive design principles. It doesn't proactively block transactions but rather observes patterns of behavior and responds when a malicious pattern is detected.

The system consists of three main components:

1.  **`TargetContract.sol`**: This is the main contract you want to protect. It contains a `guardedOperation()` function that an attacker might probe. It also includes the logic to enforce a rate limit on a specific address.

2.  **`RateLimiterTrap.sol`**: This is the core, stateless Drosera trap. Its job is to analyze the history of transactions sent to the `TargetContract`. It implements two key functions:
    *   `collect()`: A simple view function that returns the address of the transaction's originator (`tx.origin`).
    *   `shouldRespond(bytes[] calldata data)`: This function receives a list of addresses from recent transactions. It counts how many times each address appears. If an address appears more than a defined `PROBE_THRESHOLD`, the function triggers a response.

3.  **`ResponseContract.sol`**: This contract is the final piece of the puzzle. When the `RateLimiterTrap` triggers, the Drosera network calls the `executeResponse` function on this contract. Its only job is to call the `rateLimitAddress` function on the `TargetContract`, effectively blocking the offender for a set duration.

### The Flow

1.  An attacker (the "offender") rapidly sends multiple transactions to `guardedOperation()` on the `TargetContract`.
2.  The Drosera network nodes, which are monitoring the `TargetContract`, call the `RateLimiterTrap.collect()` function for each of these transactions, gathering a list of the offender's address.
3.  The nodes pass this list to the `RateLimiterTrap.shouldRespond()` function.
4.  `shouldRespond()` detects that the offender's address has appeared more times than the `PROBE_THRESHOLD`.
5.  The trap returns `true`, indicating a response is needed, along with the offender's address as response data.
6.  The Drosera network calls `ResponseContract.executeResponse()` with the offender's address.
7.  The `ResponseContract` calls `TargetContract.rateLimitAddress()`, passing in the offender's address.
8.  The `TargetContract` updates its internal state, blocking the offender from calling `guardedOperation()` for one hour.

## How to Use This Project

This project is built using the [Foundry](https://book.getfoundry.sh/) framework.

### Build

To build the contracts, run:

```bash
forge build
```

### Test

To run the test suite, use:

```bash
forge test
```

**Note:** As of the last update, the end-to-end test (`test_E2E_RateLimitingFlow`) is failing. The individual components and the trap's trigger logic are testing successfully, but the final step of the integration test is reverting unexpectedly. This requires further investigation.

### Deployment

1.  **Deploy Contracts**: Deploy `TargetContract.sol` and `ResponseContract.sol` using your preferred method (e.g., `forge create`).
2.  **Update Hardcoded Addresses**: Before deploying the final contracts, you must replace the placeholder addresses in `TargetContract.sol` and `ResponseContract.sol` with their actual deployed addresses.
3.  **Deploy Trap**: Deploy the `RateLimiterTrap.sol` contract.
4.  **Configure `drosera.toml`**: Update the `drosera.toml` file with the correct deployed addresses for the trap, target, and handler contracts.
5.  **Register with Drosera**: Use the Drosera CLI to register your trap with the network.