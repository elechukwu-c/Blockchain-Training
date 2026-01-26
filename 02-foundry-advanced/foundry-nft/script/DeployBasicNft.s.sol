// SPDX-License-Identifier: MIT

import "forge-std/script.sol";
import {BasicNft} from "../src/BasicNft.sol";

pragma solidity ^0.8.18;

contract DeployBasicNft is Script {
    function run() external returns (BasicNft) {
        vm.startBroadcast();
        BasicNft basicNft = new BasicNft();
        vm.stopBroadcast();
        return basicNft;
    }
}
