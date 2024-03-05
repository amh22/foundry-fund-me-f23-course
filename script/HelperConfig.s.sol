// SPDX-License-Identifier: MIT

// 1. Deploy mocks when we are on a local Anvil chain
// 2. Keep track of contract addresses across differnet chains

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

// This contract serves two main purposes:
// It deploys mocks when we're on a local anvil chain
// Maintains track of contract addresses across various chains

contract HelperConfig is Script {
    // If we are on a local Anvil chain, we will deploy mocks
    // Otherwise, grab the exiting address from the live network

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; // ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // Grab the exiting address from the live network
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    // Mocks for local Anvil chain
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Don't deploy a new contract if one has already been deployed
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy the mocks
        // Return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
