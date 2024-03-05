// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // Anything BEFORE startBroadcast is not going to be sent as a "real" transaction i.e. will only simualuate the transaction and not cost any gas
        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        // Below is same as above just in 'struct' format
        // address {ethUsdPriceFeed} = helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        // Anything AFTER startBroadcast is a "real" transaction

        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
