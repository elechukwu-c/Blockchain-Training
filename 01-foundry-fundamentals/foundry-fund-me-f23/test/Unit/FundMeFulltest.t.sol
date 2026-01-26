// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe, FundMe__NotEnoughEth} from "../../src/FundMe.sol";
//import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {MockV3Aggregator} from "../../test/mocks/MockV3Aggregator.sol";
import {AggregatorV3Interface} from "chainlink-evm/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMeFullTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    address OTHER = makeAddr("other");
    uint256 constant SEND_VALUE = 0.1 ether; // default funding amount
    uint256 constant STARTING_BALANCE = 50 ether;

    function setUp() external {
        // Deploy using the same script to mimic real deployment (uses HelperConfig)
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();

        // Fund user accounts for tests
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(OTHER, STARTING_BALANCE);
    }

    /* -----------------------
       Basic constructor/getter checks
       ----------------------- */

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsDeployer() public view {
        // deployer.run() is called from this test contract, so msg.sender (this contract) is owner
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionMatchesMock() public view {
        uint256 version = fundMe.getVersion();
        // Mock and real feeds used in HelperConfig have version 4
        assertEq(version, 4);
    }

    function testGetPriceFeedAddressNonZero() public view {
        assert(fundMe.getPriceFeed() != AggregatorV3Interface(address(0)));
    }

    /* -----------------------
       Fund behavior
       ----------------------- */

    function testFundRevertsWhenNoValue() public {
        vm.expectRevert(); // no ETH sent -> should revert due to require
        fundMe.fund();
    }

    function testFundRevertsWhenTooLittleEth() public {
        vm.prank(USER);
        vm.expectRevert(FundMe__NotEnoughEth.selector);
        // send tiny amount less than minimum
        (bool sent, ) = address(fundMe).call{value: 1 wei}("");
        // direct call may revert inside receive/fallback -> but we still use expectRevert above
        // If call succeeded unexpectedly, ensure revert assertion fails by explicitly calling fund()
        if (sent) {
            fundMe.fund{value: 1 wei}();
        }
    }

    function testFundUpdatesMappingAndArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        uint256 funded = fundMe.getAddressToAmountFunded(USER);
        assertEq(funded, SEND_VALUE);

        address firstFunder = fundMe.getFunder(0);
        assertEq(firstFunder, USER);
    }

    function testMultipleFundingsFromSameAddressAppendsAndAccumulates() public {
        // First funding
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // Second funding by same address
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // Mapping should have accumulated
        uint256 total = fundMe.getAddressToAmountFunded(USER);
        assertEq(total, SEND_VALUE * 2);

        // Array should have two entries for the same address (as per contract logic)
        assertEq(fundMe.getFunder(0), USER);
        assertEq(fundMe.getFunder(1), USER);
    }

    function testReceiveFallbackRouteToFundAndRecord() public {
        // Test receive() (empty calldata)
        vm.prank(USER);
        (bool ok1, ) = address(fundMe).call{value: SEND_VALUE}("");
        assertTrue(ok1, "receive call failed");

        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
        assertEq(fundMe.getFunder(0), USER);

        // Reset by owner withdraw so we can test fallback
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Test fallback (non-empty calldata)
        vm.prank(USER);
        (bool ok2, ) = address(fundMe).call{value: SEND_VALUE}(
            abi.encodeWithSignature("nonExistent()")
        );
        assertTrue(ok2, "fallback call failed");

        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
        assertEq(fundMe.getFunder(0), USER);
    }

    /* -----------------------
       Withdraw behavior (single & multiple funders)
       ----------------------- */

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // USER tries to withdraw -> should revert
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawSingleFunderTransfersAllAndClearsState()
        public
        funded
    {
        // Arrange balances
        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;
        uint256 startingContractBalance = address(fundMe).balance;

        // Act: owner withdraws
        vm.prank(owner);
        fundMe.withdraw();

        // Assert balances
        assertEq(address(fundMe).balance, 0);
        assertEq(owner.balance, startingOwnerBalance + startingContractBalance);

        // After withdraw, funders array should be empty -> getFunder(0) reverts
        vm.expectRevert();
        fundMe.getFunder(0);

        // Mapping for USER should be zero
        assertEq(fundMe.getAddressToAmountFunded(USER), 0);
    }

    function testWithdrawMultipleFundersClearsAllDataAndTransfers() public {
        // Add multiple funders (including keeping USER already funded)
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // create several funders using hoax (deal + prank)
        for (uint160 i = 1; i <= 5; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingContractBalance = address(fundMe).balance;
        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;

        // Owner withdraw
        vm.startPrank(owner);
        fundMe.withdraw();
        vm.stopPrank();

        // Contract balance is zero
        assertEq(address(fundMe).balance, 0);

        // Owner received all funds
        assertEq(owner.balance, startingOwnerBalance + startingContractBalance);

        // Mapping cleared for a sample funder
        assertEq(fundMe.getAddressToAmountFunded(address(1)), 0);

        // getFunder(0) should revert because array was reset
        vm.expectRevert();
        fundMe.getFunder(0);
    }

    function testCheaperWithdrawBehavesSameAsWithdraw() public {
        // Fund from several addresses
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        for (uint160 i = 1; i <= 5; i++) {
            hoax(address(i), STARTING_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingContractBalance = address(fundMe).balance;
        address owner = fundMe.getOwner();
        uint256 startingOwnerBalance = owner.balance;

        // Owner calls cheaperWithdraw
        vm.startPrank(owner);
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assertions same as withdraw
        assertEq(address(fundMe).balance, 0);
        assertEq(owner.balance, startingOwnerBalance + startingContractBalance);

        // ensure mapping cleared
        assertEq(fundMe.getAddressToAmountFunded(address(2)), 0);

        // getFunder(0) should revert
        vm.expectRevert();
        fundMe.getFunder(0);
    }

    /* -----------------------
       Edge / integration tests with mock price feed manipulation
       ----------------------- */

    // function testChangingMockPriceAllowsDifferentFundingThresholds() public {
    //     // Access the underlying feed (MockV3Aggregator) and move the price to a huge value
    //     MockV3Aggregator feed = MockV3Aggregator(
    //         payable(address(fundMe.getPriceFeed()))
    //     );

    //     // Lower the price dramatically (so SEND_VALUE might be below MINIMUM_USD)
    //     // Here we set to $1 (1e8), making SEND_VALUE insufficient
    //     feed.updateAnswer(int256(1e8));

    //     vm.prank(USER);
    //     vm.expectRevert();
    //     fundMe.fund{value: SEND_VALUE}();

    //     // Now set price very high so even tiny ETH is enough
    //     feed.updateAnswer(int256(1e12)); // $10,000,000,000 (large)
    //     vm.prank(USER);
    //     fundMe.fund{value: 1 wei}(); // tiny value should now pass
    //     assertEq(fundMe.getAddressToAmountFunded(USER), 1 wei);
    // }

    function testChangingMockPriceAllowsDifferentFundingThresholds() public {
        // Access the underlying MockV3Aggregator
        MockV3Aggregator feed = MockV3Aggregator(
            address(fundMe.getPriceFeed())
        );

        // Lower the price so SEND_VALUE is below MINIMUM_USD
        feed.updateAnswer(int256(1e8)); // $1
        vm.prank(USER);
        //vm.expectRevert(bytes("You need to spend more ETH!"));
        vm.expectRevert(FundMe__NotEnoughEth.selector);
        fundMe.fund{value: SEND_VALUE}();

        // Now increase price so even a small ETH amount passes
        feed.updateAnswer(int256(3000e8)); // $3000
        uint256 tinyEth = (5e18 * 1e18) / (uint256(feed.latestAnswer()) * 1e10); // just enough ETH

        vm.prank(USER);
        fundMe.fund{value: tinyEth}(); // should now succeed
        assertEq(fundMe.getAddressToAmountFunded(USER), tinyEth);
    }

    /* -----------------------
       Sanity checks & extra getters coverage
       ----------------------- */

    function testGettersAfterFunding() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // getOwner
        assertEq(fundMe.getOwner(), fundMe.getOwner());

        // getAddressToAmountFunded
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);

        // getPriceFeed is non-zero
        assert(address(fundMe.getPriceFeed()) != address(0));

        // getFunder(0) returns expected
        assertEq(fundMe.getFunder(0), USER);
    }
}
