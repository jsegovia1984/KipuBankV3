# KipuBankV3 Smart Contract
![Tests](https://github.com/jorgeSegovia/KipuBank/actions/workflows/tests.yml/badge.svg)

## 1. Overview

KipuBankV3 is a decentralized financial vault built on the Ethereum blockchain. The contract allows users to deposit ETH or any ERC20 token, which are then automatically swapped for USDC via the Uniswap V2 protocol. The core purpose of the vault is to consolidate diverse crypto assets into a stablecoin (USDC).

Users can withdraw their funds from the vault at any time in the form of USDC. The contract is designed with security and administrative controls in mind, incorporating features like pausability, reentrancy guards, and owner-privileged functions for maintenance and emergencies.

**Target Audience**: This document is intended for technical users, including frontend developers who need to integrate with the contract and security auditors examining its architecture and risk profile.

## 2. Core Mechanism: Automated USDC Conversion

The primary function of KipuBankV3 is to act as a USDC-based savings vault. This is achieved through direct integration with a Uniswap V2 Router.

-   **On-Deposit Swap**: When a user deposits ETH (`depositETH`) or an ERC20 token (`depositToken`), the contract does not store the original asset. Instead, it immediately initiates a swap on Uniswap V2 to convert the entire deposited amount into USDC.
-   **USDC Accounting**: The resulting USDC amount from the swap is credited to the user's internal balance within the KipuBankV3 contract. All internal accounting is handled in USDC.
-   **Withdrawal**: Users can only withdraw their balance in USDC (`withdrawUSDC`).

This mechanism simplifies the vault's internal logic by standardizing all holdings to a single, stable asset.

## 3. Key Features

-   **Multi-Asset Deposits**: Accepts ETH and any ERC20 token as deposits.
-   **Automatic Conversion**: All deposited assets are automatically converted to USDC.
-   **USDC Withdrawals**: Users can withdraw their portion of the vault's USDC.
-   **Administrative Controls**:
    -   **Ownable**: A single owner has administrative privileges.
    -   **Pausable**: The owner can pause core functions (`deposit`/`withdraw`) in an emergency.
    -   **Emergency Withdraw**: The owner can withdraw any asset from the contract to handle unforeseen situations.
-   **Security Hardening**:
    -   **Non-Reentrant**: Protects key functions from reentrancy attacks.
    -   **Capacity Limits**: Enforces a total bank capacity and a per-transaction withdrawal limit.
    -   **SafeERC20**: Uses OpenZeppelin's `SafeERC20` library for safe token interactions.

---

## 4. For Frontend Developers

This section outlines the primary API and events needed to build a user interface for KipuBankV3.

### Public State Variables

These variables can be read directly from the blockchain to display key contract information.

-   `s_usdcToken`: `address` - The contract address of the USDC token.
-   `s_uniswapRouter`: `address` - The contract address of the Uniswap V2 Router.
-   `I_BANKCAP`: `uint256` - The maximum total USDC the vault can hold.
-   `I_WITHDRAWLIMIIT`: `uint256` - The maximum USDC that can be withdrawn in a single transaction.
-   `totalUSDCinBank`: `uint256` - The current total USDC held by the contract.
-   `s_balances[user_address]`: `mapping(address => uint256)` - Returns the USDC balance for a given user.

### Public Functions (User-Facing)

-   **`depositETH()`** `payable`
    -   **Description**: Deposits ETH into the vault. The ETH is immediately swapped for USDC, and the user's balance is credited.
    -   **Parameters**: None. The amount is sent as `msg.value`.

-   **`depositToken(address _token, uint256 _amount)`**
    -   **Description**: Deposits a specified amount of an ERC20 token. The token is swapped for USDC. The user must first approve the KipuBankV3 contract to spend `_amount` of `_token`.
    -   **Parameters**:
        -   `_token`: The address of the ERC20 token being deposited.
        -   `_amount`: The amount of the token to deposit.

-   **`withdrawUSDC(uint256 _amount)`**
    -   **Description**: Withdraws a specified amount of USDC from the user's balance.
    -   **Parameters**:
        -   `_amount`: The amount of USDC to withdraw.
    -   **Emits**: `Withdraw` event.

-   **`estimateSwap(address _token, uint256 _amount)`** `returns (uint256)`
    -   **Description**: A view function to estimate the amount of USDC that will be received from swapping a given amount of an ERC20 token or ETH (use WETH address for ETH). Useful for showing users an expected output before they deposit.
    -   **Parameters**:
        -   `_token`: The address of the token to be swapped (use WETH for ETH).
        -   `_amount`: The amount of the token.

### Events

-   **`Deposit(address indexed user, uint256 indexed amountUSDC)`**
    -   **Description**: Emitted when a user's deposit (and the subsequent swap to USDC) is successfully processed. `amountUSDC` is the value credited to their balance.

-   **`Withdraw(address indexed user, uint256 indexed amountUSDC)`**
    -   **Description**: Emitted when a user successfully withdraws USDC.

---

## 5. For Auditors & Security Analysts

This section details the security model, trust assumptions, and a potential risks.

### Access Control

-   **`Ownable`**: The contract uses OpenZeppelin's `Ownable`. The owner is set at deployment and has exclusive access to critical, administrative functions.
-   **Owner-Privileged Functions**:
    -   `pause()` / `unpause()`: Halts and resumes core contract functionality.
    -   `setBankCap(uint256)`: Adjusts the total vault capacity.
    -   `setWithdrawLimit(uint256)`: Adjusts the per-transaction withdrawal limit.
    -   `recoverERC20(address)`: Allows the owner to rescue any non-USDC tokens accidentally sent to the contract.
    -   **`emergencyWithdraw(address token, uint256 amount)`**: **[High-Risk]** This function allows the owner to withdraw *any* asset (including all USDC) from the contract at any time. This represents a significant centralization risk and requires complete trust in the owner.

### Security Features

-   **`nonReentrant` Modifier**: A custom reentrancy guard is applied to all state-changing public functions (`depositETH`, `depositToken`, `withdrawUSDC`) to prevent reentrancy attacks.
-   **Input Validation**: `withdrawUSDC` checks that the requested withdrawal amount does not exceed the user's balance or the transaction limit. Deposit functions check against the bank's total capacity.
-   **Slippage Protection**: The swap functions (`_swapTokensForTokens`, `_swapEthForTokens`) have a hardcoded `amountOutMin` of `1`. **This provides minimal protection against slippage** and could be a vector for value loss in volatile market conditions or with low-liquidity pairs.

### Trust Assumptions & External Dependencies

-   **Uniswap V2 Router**: The contract is tightly coupled to the provided Uniswap V2 Router address. The integrity and availability of Uniswap are critical for the contract's operation.
-   **USDC Contract**: The contract relies on the specified USDC token contract, which is assumed to be a standard and secure ERC20 token.
-   **Owner Trust**: Users must trust the owner not to abuse their privileged functions, particularly `emergencyWithdraw`.

### Testing Limitations

-   The test suite (`KipuBankV3Test.t.sol`) uses a mock contract (`MockDeFi.sol`) to simulate the Uniswap Router and USDC token.
-   **Conclusion**: The tests validate the internal accounting, access control, and business logic of the vault. However, they **do not cover the live integration with the Uniswap V2 Router**. Potential failure modes of Uniswap (e.g., failed swaps, high slippage, low liquidity) are not tested.

---

## 6. Project Structure

```
.
├── lib/                  # Dependencies (forge-std, openzeppelin-contracts)
├── script/
│   └── DeployKipuBankV3.s.sol # Deployment script
├── src/
│   └── KipuBankV3.sol      # The core smart contract
└── test/
    ├── KipuBankV3Test.t.sol # Test suite for the contract
    └── mocks/
        └── MockDeFi.sol     # Mock contract for Uniswap and USDC
```

## 7. Local Development

### Prerequisites

-   [Foundry](https://getfoundry.sh/)

### Setup

1.  Install dependencies:
    ```bash
    forge install
    ```

### Compilation

2.  Build the project:
    ```bash
    forge build
    ```

### Testing

3.  Run the test suite:
    ```bash
    forge test
    ```

## 8. Deployment

The contract can be deployed using the provided Foundry script.

1.  **Configure Environment**: Set the required environment variables in a `.env` file. You will need a `SEPOLIA_RPC_URL` and a `PRIVATE_KEY`.

2.  **Run the Deployment Script**:
    ```bash
    # Example for Sepolia testnet
    forge script script/DeployKipuBankV3.s.sol:DeployKipuBankV3 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
    ```
    The script uses the following hardcoded addresses for Sepolia:
    -   **USDC**: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
    -   **Uniswap V2 Router**: `0xC532a74256D3Db421394a2f443552C54bb7ee72A`
---

# KipuBankV3 Protocol Analysis and Improvements

## High-Level Explanation

This section details the improvements implemented in **KipuBankV3**, the rationale behind them, and the design decisions made.

### Implemented Improvements

KipuBankV3 introduces several key improvements over previous versions, focusing on asset standardization, security, and administrability.

1.  **Automatic Conversion to USDC**: Every deposited asset (ETH or any ERC20 token) is automatically converted to USDC via Uniswap V2.
    *   **Why**: This measure drastically simplifies the vault's internal accounting. Instead of managing multiple balances of different tokens, the contract only needs to track each user's USDC balance. This reduces complexity, minimizes the attack surface, and standardizes the value of the vault's assets to a stablecoin.

2.  **Robust Administrative Controls**: Functions were implemented for the contract owner to manage the vault in emergency situations.
    *   **Pausable**: Allows stopping deposits and withdrawals if a vulnerability is discovered.
    *   **Capacity Limits**: A total deposit limit (`I_BANKCAP`) and a per-transaction limit (`I_WITHDRAWLIMIIT`) can be configured to control risk.
    *   **Emergency Withdraw**: The owner can withdraw funds directly, a last-resort measure to protect user assets from a catastrophic failure.
    *   **Why**: These controls provide a layer of managed security, allowing for a rapid response to unforeseen events, although it introduces a risk of centralization.

3.  **Enhanced Security**: Industry-standard security patterns were adopted.
    *   **Reentrancy Protection**: OpenZeppelin's `nonReentrant` modifier protects critical functions against reentrancy attacks.
    *   **Use of `SafeERC20`**: All interactions with ERC20 tokens use the `SafeERC20` library to avoid issues with non-standard tokens.
    *   **Why**: Security is the top priority. Using audited and battle-tested implementations like those from OpenZeppelin is a fundamental decision to protect user funds.

## Deployment and Interaction Instructions

### Deployment

1.  **Configure Environment**: Create a `.env` file in the project root and define the following variables:
    *   `SEPOLIA_RPC_URL`: The URL of an RPC node for the Sepolia network.
    *   `PRIVATE_KEY`: The private key of the account that will deploy the contract.
    *   `ETHERSCAN_API_KEY`: An Etherscan API key to automatically verify the contract.

2.  **Run the Deployment Script**: Use the following Foundry command to deploy and verify the contract on the Sepolia network.
    ```bash
    forge script script/DeployKipuBankV3.s.sol:DeployKipuBankV3 --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
    ```

### Interaction

Once deployed, users and applications can interact with the contract as follows:

-   **Deposit ETH**: Call the `depositETH()` function, sending the amount of ETH in the transaction.
-   **Deposit ERC20 Tokens**:
    1.  **Approval**: The user must first approve the KipuBankV3 contract to spend their tokens. This is done by calling the `approve(KIPU_BANK_ADDRESS, amount)` function on the token contract.
    2.  **Deposit**: Call the `depositToken(token_address, amount)` function.
-   **Withdraw USDC**: Call the `withdrawUSDC(amount)` function to withdraw the desired amount of USDC. The user must have a sufficient balance.

## Notes on Design Decisions and Trade-offs

1.  **Standardization to USDC vs. Diversification**:
    *   **Decision**: Force the conversion of all assets to USDC.
    *   **Trade-off**: Simplicity is gained, and the risk of volatility from non-stable assets is reduced. However, it introduces a strong dependency on Uniswap V2 and USDC itself. Additionally, users are exposed to `slippage` at the time of conversion, which could result in a slight loss of value.

2.  **Centralization vs. Active Security**:
    *   **Decision**: Grant the contract owner significant powers (`pause`, `emergencyWithdraw`).
    *   **Trade-off**: This creates a **centralization risk**. Users must fully trust that the owner will not abuse their powers. In return, the protocol gains the ability to respond quickly to threats, potentially protecting funds from a hack or bug.

3.  **Minimal Slippage Protection**:
    *   **Decision**: The `amountOutMin` has been fixed at `1` in the swap functions.
    -   **Trade-off**: This simplifies the user interface and contract logic, as the user does not need to specify a minimum output. However, it offers almost no protection against slippage, which can be detrimental in volatile markets or when swapping illiquid tokens. A more mature version should delegate this decision to the user.

## Threat Analysis Report

### Protocol Weaknesses and Steps Toward Maturity

1.  **Owner Centralization Risk**: As mentioned, the owner has full control.
    *   **Steps to mature**: The contract ownership should be transferred to a DAO (Decentralized Autonomous Organization) or a multi-signature wallet (`multisig`) so that no single entity can control the funds.

2.  **Dependency on Uniswap V2**: The protocol is entirely dependent on a single decentralized exchange.
    *   **Steps to mature**: Integrate a DEX aggregator (like 1inch or Matcha) to always find the best swap route, minimizing slippage and increasing resilience if Uniswap V2 ceases to be optimal.

3.  **Unmanaged Slippage**: Users cannot protect themselves from slippage.
    *   **Steps to mature**: Modify the deposit functions to accept a `minAmountOut` parameter, allowing the user to define the minimum amount of USDC they are willing to receive.

4.  **Limited Real-World Testing**: The current tests use `mocks`.
    *   **Steps to mature**: Implement a "forking" test suite with Foundry. This would allow testing the contract on a local copy of the mainnet or a testnet, interacting with the real versions of Uniswap and USDC to validate behavior in an environment identical to production.

### Test Coverage

Test coverage is a metric that indicates what percentage of the contract's source code is executed by the test suite. High coverage is desirable but does not guarantee the absence of bugs.

-   **How to generate it**: Foundry allows for easy generation of a coverage report.
    ```bash
    forge coverage
    ```
-   **Interpretation**: This command runs the tests and displays a summary of coverage by contract and function. The detailed result is saved in an `lcov.info` file, which can be used by external tools to visualize which lines of code have not been tested.

#### Latest Coverage Report
```
╭-------------------------------+------------------+-----------------+----------------+----------------╮
| File                          | % Lines          | % Statements    | % Branches     | % Funcs        |
+======================================================================================================+
| script/DeployKipuBankV3.s.sol | 0.00% (0/12)     | 0.00% (0/12)    | 100.00% (0/0)  | 0.00% (0/1)    |
|-------------------------------+------------------+-----------------+----------------+----------------|
| src/KipuBankV3.sol            | 77.60% (97/125)  | 70.69% (82/116) | 43.48% (10/23) | 86.21% (25/29) |
|-------------------------------+------------------+-----------------+----------------+----------------|
| test/mocks/MockDeFi.sol       | 56.52% (13/23)   | 52.94% (9/17)   | 100.00% (0/0)  | 66.67% (4/6)   |
|-------------------------------+------------------+-----------------+----------------+----------------|
| Total                         | 68.75% (110/160) | 62.76% (91/145) | 43.48% (10/23) | 80.56% (29/36) |
╰-------------------------------+------------------+-----------------+----------------+----------------╯
```

### Testing Methods

The following testing methods were used to validate the contract:

1.  **Unit Testing**: The `KipuBankV3Test.t.sol` file contains tests that verify each function of the contract in isolation. Business logic, access modifiers (`onlyOwner`, `whenNotPaused`), and state updates are checked for predictable scenarios.

2.  **Fuzz Testing**: Foundry allows for fuzzing in tests. Instead of using a single input value, multiple random values are provided for function parameters. This is crucial for discovering edge cases that were not anticipated, such as deposits of `0`, very large amounts, or unexpected interactions between functions.

3.  **Use of Mocks**: To isolate the behavior of the `KipuBankV3` contract from its external dependencies (Uniswap and USDC), a `mock` contract (`MockDeFi.sol`) was used. This mock simulates the behavior of Uniswap and USDC, allowing tests to be fast, deterministic, and not require an internet connection or a testnet.