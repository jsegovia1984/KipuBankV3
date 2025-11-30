# KipuBankV3 Smart Contract

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

This section details the security model, trust assumptions, and potential risks.

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