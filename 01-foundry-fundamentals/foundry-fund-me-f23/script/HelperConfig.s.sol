// SPDX-License-Identifier: MIT

// things to do here:
// 1. Deploy mocks when we are on a local anvil chain
// 2. Keep track of contract address across different chains
// example: Sepolia ETH/USD price feed address
// example: Mainnet ETH/USD price feed address

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // This contract is used to configure helper functions for the FundMe contract
    // It will be used to set up the price feed and other dependencies
    // IF we are on local anvil, we dploy mocks
    // Otherwise, grab the existing address from the live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8; // Number of decimals for the price feed
    int256 public constant IITIAL_PRICE = 2000e8; // Initial price for the price feed (2000 USD with 8 decimals)

    struct NetworkConfig {
        address priceFeed; // Eth/USD price feed address
    }

    constructor() {
        // This constructor is called when the contract is deployed
        // You can use it to set up the initial state of the contract
        // For example, you can set the active network configuration here
        if (block.chainid == 11155111) {
            // Sepolia network
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            // Mainnet network
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 31337) {
            // Anvil network
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        } else {
            revert("No active network configuration found");
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        // This function returns the configuration for the Sepolia network
        // It will return the address of the ETH/USD price feed on Sepolia
        // You can use this function to get the price feed address for your tests
        // For example, you can use it to set up the price feed in your FundMe contract
        // return 0x694AA1769357215DE4FAC081bf1f309aDC325306; // Sepolia ETH/USD price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // Sepolia ETH/USD price feed address
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // This function returns the configuration for the Mainnet network
        // It will return the address of the ETH/USD price feed on Mainnet
        // You can use this function to get the price feed address for your tests
        // return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // Mainnet ETH/USD price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 // Mainnet ETH/USD price feed address
        });
        return ethConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            // If the price feed is already set, return the existing configuration
            return activeNetworkConfig;
        }
        // price feed address for Anvil network
        // 1. Deploy a mock price feed contract
        // 2. Return the address of the mock price feed contract

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            IITIAL_PRICE
        ); // 2000 USD with 8 decimals
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
