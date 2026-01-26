// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is StdCheats, Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address public user1 = address(0x1);
    address public user2 = address(0x2);

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        // Give user1 some tokens
        vm.prank(msg.sender); // deployer has the initial supply
        ourToken.transfer(user1, STARTING_BALANCE);
    }

    // -------------------------
    // Deployment Tests
    // -------------------------

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    // -------------------------
    // Transfer Tests
    // -------------------------

    function testTransferDecreasesSenderBalance() public {
        uint256 amount = 10 ether;

        vm.prank(user1);
        ourToken.transfer(user2, amount);

        assertEq(ourToken.balanceOf(user1), STARTING_BALANCE - amount);
        assertEq(ourToken.balanceOf(user2), amount);
    }

    function testTransferEmitsEvent() public {
        uint256 amount = 5 ether;

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Transfer(user1, user2, amount);

        ourToken.transfer(user2, amount);
    }

    function testTransferFailsIfInsufficientBalance() public {
        uint256 tooMuch = STARTING_BALANCE + 1;

        vm.prank(user1);
        vm.expectRevert();
        ourToken.transfer(user2, tooMuch);
    }

    // -------------------------
    // Allowance & Approvals
    // -------------------------

    function testApprovalAndAllowance() public {
        uint256 amount = 20 ether;

        vm.prank(user1);
        ourToken.approve(user2, amount);

        assertEq(ourToken.allowance(user1, user2), amount);
    }

    function testApprovalEmitsEvent() public {
        uint256 amount = 15 ether;

        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit Approval(user1, user2, amount);

        ourToken.approve(user2, amount);
    }

    function testTransferFromWorksWithAllowance() public {
        uint256 amount = 10 ether;

        // user1 approves user2
        vm.prank(user1);
        ourToken.approve(user2, amount);

        // user2 spends tokens from user1
        vm.prank(user2);
        ourToken.transferFrom(user1, user2, amount);

        assertEq(ourToken.balanceOf(user1), STARTING_BALANCE - amount);
        assertEq(ourToken.balanceOf(user2), amount);
        assertEq(ourToken.allowance(user1, user2), 0);
    }

    function testTransferFromFailsWithoutApproval() public {
        uint256 amount = 5 ether;

        vm.prank(user2);
        vm.expectRevert();
        ourToken.transferFrom(user1, user2, amount);
    }

    function testTransferFromFailsIfOverAllowance() public {
        uint256 allowanceAmount = 5 ether;
        uint256 sendAmount = 6 ether;

        vm.prank(user1);
        ourToken.approve(user2, allowanceAmount);

        vm.prank(user2);
        vm.expectRevert();
        ourToken.transferFrom(user1, user2, sendAmount);
    }

    // -------------------------
    // Edge Cases
    // -------------------------

    function testCantTransferToZeroAddress() public {
        vm.prank(user1);
        vm.expectRevert();
        ourToken.transfer(address(0), 1 ether);
    }

    function testCantApproveZeroAddress() public {
        vm.prank(user1);
        vm.expectRevert();
        ourToken.approve(address(0), 1 ether);
    }

    // -------------------------
    // Events (for reference)
    // -------------------------

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// Great job getting started with your first ERC20 token and Solidity-based Foundry tests 👏.
// Since you’re inheriting from OpenZeppelin’s `ERC20`, a lot of the core functionality is already well-tested in their library. But it’s still **important to write your own integration tests** to verify your contract behaves as expected in your environment.

// I’ll extend your `OurTokenTest` suite to cover:

// * **Allowances** (`approve`, `allowance`, `transferFrom`)
// * **Transfers** (`transfer`, `balanceOf`, `transferFrom`)
// * **Events** (`Transfer`, `Approval`)
// * **Edge cases** (zero address, insufficient balance, exceeding allowance)

// Here’s a complete test file with these additions:

// ```solidity

/*

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OutTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobHasBalance() public view {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowance() public {
        uint256 initialAllowance = 1000;

        // Bob apporves Alice to spend 1000 OT on his behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }
}
*/
