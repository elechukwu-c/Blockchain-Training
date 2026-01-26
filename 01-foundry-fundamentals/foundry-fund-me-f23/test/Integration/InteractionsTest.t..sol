// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000
    uint256 constant STRATING_BALANCE = 10 ether; // 10000000000000000000
    uint256 constant GAS_PRICE = 1; // 1000000000 wei

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, STRATING_BALANCE); // Give USER some ether
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();

        // Fund the contract with ETH
        vm.deal(address(fundFundMe), 1 ether);

        fundFundMe.fundFundMe(address(fundMe));

        address funder = fundMe.getFunder(0);
        assertEq(funder, address(fundFundMe)); // note: this will now be the funder
    }

    function testUserCanWithdrawInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.deal(address(fundFundMe), 1 ether);
        fundFundMe.fundFundMe(address(fundMe));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
