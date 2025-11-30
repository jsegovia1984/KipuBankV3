// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {KipuBankV3} from "../src/KipuBankV3.sol";

/**
 * @title DeployKipuBankV3
 * @notice Deployment script for KipuBankV3 contract on Sepolia testnet
 * @dev Uses Sepolia-specific addresses for USDC and Uniswap V2 Router
 * @author jorge Segovia
 */
contract DeployKipuBankV3 is Script {

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */
    address constant SEPOLIA_USDC = 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
    address constant SEPOLIA_ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;

    uint256 constant BANK_CAP = 100_000 * 10 ** 6;
    uint256 constant WITHDRAW_LIMIT = 5_000 * 10 ** 6;
    /**
     * @notice Main deployment function for Sepolia testnet
     * @return kipuBank Deployed KipuBankV3 contract instance
    **/
    function run() external returns (KipuBankV3) {
  

        console.log("Deploying KipuBankV3 to Sepolia...");
        console.log("Bank Cap:", BANK_CAP / 10 ** 6, "USDC");
        console.log("Withdraw Limit:", WITHDRAW_LIMIT / 10 ** 6, "USDC");
        console.log("USDC Address:", SEPOLIA_USDC);
        console.log("Router Address:", SEPOLIA_ROUTER);

        vm.startBroadcast();
        KipuBankV3 kipuBank = new KipuBankV3(BANK_CAP, WITHDRAW_LIMIT, SEPOLIA_USDC, SEPOLIA_ROUTER);
        vm.stopBroadcast();

        console.log("KipuBankV3 deployed at:", address(kipuBank));
        console.log("Contract Owner:", kipuBank.owner());

        return kipuBank;
    }
}
