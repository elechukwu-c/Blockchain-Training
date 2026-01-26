// Fund
// Withdraw

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    // This contract is used to interact with the FundMe contract
    // It will be used to test the fund and withdraw functions
    // It will also be used to test the onlyOwner modifier

    uint256 constant SEND_VALUE = 0.01 ether;

    // The run function will be used to fund the FundMe contract
    function fundFundMe(address mostRecentDeployer) public {
        FundMe(payable(mostRecentDeployer)).fund{value: SEND_VALUE}();

        console.log("Funded FundMe contract with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        //vm.startBroadcast();
        fundFundMe(mostRecentlyDeployed);
        // vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentDeployer) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentDeployer)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        withdrawFundMe(mostRecentlyDeployed);
        vm.stopBroadcast();
    }
}
