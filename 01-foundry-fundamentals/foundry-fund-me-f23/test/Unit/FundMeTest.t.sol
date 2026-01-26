/*
  Types of Tests:

  1. Unit Tests: Test individual functions or components in isolation.
  2. Integration Tests: Test how different components work together.
  3. End-to-End Tests: Test the entire application flow from start to finish.
  4. Regression Tests: Ensure that new changes do not break existing functionality.
  5. Performance Tests: Measure the performance of the application under load.
  6. Security Tests: Identify vulnerabilities and security issues in the application.
  7. Smoke Tests: Quick tests to check if the basic functionality works.
  8. Acceptance Tests: Validate the application against business requirements.
  9. Exploratory Tests: Ad-hoc testing to discover issues not covered by other tests.
  10. Fork Tests: Test the application on a forked network to simulate real-world conditions.
  11. Gas Tests: Measure the gas consumption of functions to ensure efficiency.
  12. Fuzz Tests: Test the application with random inputs to discover edge cases.
  
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // This contract is used to test the FundMe contract
    // It will be used to test the fund and withdraw functions
    // It will also be used to test the onlyOwner modifier
    // Add your test functions here
    // You can use the Hardhat or Foundry testing framework to write your tests
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000
    uint256 constant STRATING_BALANCE = 10 ether; // 10000000000000000000
    uint256 constant GAS_PRICE = 1; // 1000000000 wei

    function setUp() external {
        // This function is called before each test function
        // You can use it to set up the state of the contract
        // For example, you can deploy the FundMe contract here
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // You can also set up any other state you need for your tests
        DeployFundMe deployFundMe = new DeployFundMe();
        // Deploy the FundMe contract using the DeployFundMe script
        fundMe = deployFundMe.run();
        vm.deal(USER, STRATING_BALANCE); // Give USER some ether
    }

    function testMinimumDollarIsFive() public view {
        // This function tests that the minimum dollar amount is set to 5
        /* uint256 expectedMinimum = 5 * 10 ** 18; // 5 USD in wei
        assertEq(fundMe.MINIMUM_USD(), expectedMinimum, "Minimum USD should be 5");
        */
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // This function tests that the owner of the contract is the message sender
        //  console.log("Owner address:", fundMe.i_owner());
        //  console.log("Message sender address:", msg.sender);
        assertEq(
            //fundMe.i_owner(),
            fundMe.getOwner(),
            msg.sender,
            "Owner should be the address that deployed the contract"
        );
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4, "Price feed version should be 4");
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // Expect a revert when trying to fund with less than the minimum amount
        // assert(This tx fails/reverts)
        fundMe.fund(); // This should fail because no ETH is sent
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}(); // Fund with exactly 5 USD worth of ETH
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(
            amountFunded,
            SEND_VALUE,
            "Amount funded should match SEND_VALUE"
        );
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER); // The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}(); // Fund with exactly 5 USD worth of ETH
        address funder = fundMe.getFunder(0); // Get the first funder
        assertEq(funder, USER, "Funder should be USER's address");
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}(); // Fund the contract before running the test
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert(); // Expect a revert when USER tries to withdraw

        fundMe.withdraw(); // USER tries to withdraw, should fail
    }

    function testWtihdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act

        vm.prank(fundMe.getOwner()); // The next TX will be sent by the owner (c: 200 )
        fundMe.withdraw(); // Owner withdraws funds

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance,
            "Owner should have received all funds"
        );
    }

    function testWithdrawFromMuiltipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address(i);
            // vm.deal new address(i), SEND_VALUE);
            // address()
            hoax(address(i), SEND_VALUE); // Create a new address and send SEND_VALUE to it
            fundMe.fund{value: SEND_VALUE}(); // Fund the contract with SEND_VALUE
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner()); // The next TX will be sent by the
        fundMe.withdraw(); // Owner withdraws funds
        vm.stopPrank();

        // Assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    // Gas-Optimized withdraw funtion
    function testWithdrawFromMuiltipleFundersCheapers() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank new address(i);
            // vm.deal new address(i), SEND_VALUE);
            // address()
            hoax(address(i), SEND_VALUE); // Create a new address and send SEND_VALUE to it
            fundMe.fund{value: SEND_VALUE}(); // Fund the contract with SEND_VALUE
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner()); // The next TX will be sent by the
        fundMe.cheaperWithdraw(); // Owner withdraws funds
        vm.stopPrank();

        // Assert

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
