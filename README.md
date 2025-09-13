# Repetitive Oracle-Probing Rate Limiter Trap

This project is a proof-of-concept (PoC) implementation of a Drosera security trap designed to protect smart contracts from a specific type of malicious behavior: repetitive probing.

## The Problem: Oracle Probing

DeFi protocols, especially those involving lending, borrowing, or derivatives, often rely on external price oracles (like Chainlink) to function. Attackers can try to find vulnerabilities or favorable conditions by rapidly sending transactions that interact with the protocol, causing them to revert or succeed based on the oracle's current price. This "probing" can be a precursor to a more significant attack, such as price manipulation or exploiting a liquidation mechanism.

This trap aims to detect and mitigate this behavior in a reactive manner.

## How It Works: A Reactive Defense

This system follows Drosera's reactive design principles. It doesn't proactively block transactions but rather observes patterns of behavior and responds when a malicious pattern is detected.

The system consists of three main components:

1.  **`TargetContract.sol`**: This is the main contract you want to protect. It contains a `guardedOperation()` function that an attacker might probe. It also includes the logic to enforce a rate limit on a specific address. To track recent activity, it maintains a ring buffer of the most recent callers.

2.  **`RateLimiterTrap.sol`**: This is the core, stateless Drosera trap. Its job is to analyze the history of transactions sent to the `TargetContract`. It implements two key functions:
    *   `collect()`: A view function that reads the ring buffer of recent callers from the `TargetContract`.
    *   `shouldRespond(bytes[] calldata data)`: This function receives a list of recent caller arrays from past blocks. It counts how many times each address appears across all the data. If an address appears more than a defined `PROBE_THRESHOLD`, the function triggers a response.

3.  **`ResponseContract.sol`**: This contract is the final piece of the puzzle. When the `RateLimiterTrap` triggers, the Drosera network calls the `executeResponse` function on this contract. This function is protected by a `guardian` role, ensuring only authorized Drosera executors can trigger a response. Its only job is to call the `rateLimitAddress` function on the `TargetContract`, effectively blocking the offender for a set duration.

### The Flow

1.  An attacker (the "offender") rapidly sends multiple transactions to `guardedOperation()` on the `TargetContract`.
2.  The `TargetContract` records the `msg.sender` of each call in its `recentCallers` ring buffer.
3.  The Drosera network nodes, which are monitoring the `TargetContract`, call the `RateLimiterTrap.collect()` function periodically, gathering the list of recent callers.
4.  The nodes pass this historical data to the `RateLimiterTrap.shouldRespond()` function.
5.  `shouldRespond()` detects that the offender's address has appeared more times than the `PROBE_THRESHOLD`.
6.  The trap returns `true`, indicating a response is needed, along with the offender's address as response data.
7.  An authorized Drosera guardian calls `ResponseContract.executeResponse()` with the offender's address.
8.  The `ResponseContract` calls `TargetContract.rateLimitAddress()`, passing in the offender's address.
9.  The `TargetContract` updates its internal state, blocking the offender from calling `guardedOperation()` for one hour.

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

All tests are currently passing.

### Deployment

1.  **Deploy Contracts**: Deploy `TargetContract.sol`, `ResponseContract.sol`, and `RateLimiterTrap.sol` using your preferred method (e.g., `forge create`). Note the constructor arguments for each contract:
    *   `ResponseContract` requires the address of the `TargetContract` and the `guardian`.
    *   `TargetContract` requires the address of the `ResponseContract`.
    *   `RateLimiterTrap` requires the address of the `TargetContract`.
    You will need to manage this deployment order, likely deploying the `TargetContract` with a placeholder for the `ResponseContract` address and then updating it after the `ResponseContract` is deployed, or using a more advanced deployment script.
2.  **Configure `drosera.toml`**: Update the `drosera.toml` file with the correct deployed addresses for the trap, target, and handler contracts.
3.  **Register with Drosera**: Use the Drosera CLI to register your trap with the network.