// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script {
    // This contract is used to deploy the FundMe contract
    // It will be used to deploy the FundMe contract with the correct constructor parameters
    // You can use the Hardhat or Foundry deployment framework to deploy your contracts
    // Add your deployment logic here
    // For example, you can use the `new` keyword to deploy the FundMe contract
    // function deployFundMe() external returns (address) {
    //     FundMe fundMe = new FundMe();
    //     return address(fundMe);
    // }

    function run() external returns (FundMe) {
        // Anything that is before the broadcasr is only run locally

        HelperConfig helperConfig = new HelperConfig();
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

        // Anything that is after the broadcast is run on the chain
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
