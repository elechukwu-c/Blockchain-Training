//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {VaultGame} from "../src/VaultGame.sol";

contract VaultGameTest is Test {
    VaultGame vault;

    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
      vm.prank(owner);
        vault = new VaultGame();
        vault.initialize(owner);

        vm.deal(user, 10 ether);
       
    }

    // Testing the initalizer function, to set the owner correctly
    function testInitializeSetsOwner() public {
      vault = new VaultGame();

      vm.prank (owner);
      vault.initialize(owner);
      assertEq(vault.owner(), owner);
    }

    // Testing if the initializer function prevents re-initialization
    function testInitializeCanNotBeCalledTwice() public {
      vault = new VaultGame();

      vm.prank (owner);
      vault.initialize(owner);

      vm.expectRevert(VaultGame.AlreadyInitialized.selector);
      vault.initialize(address(0x3));
    }

    // Testing deposit function to ensure funds are correctly deposited
    function testUserCanDepositFunds() public {
      vm.prank(user);
      vault.deposit{value: 1 ether}();

      assertEq(vault.balances(user), 1 ether);
      assertEq(address(vault).balance, 1 ether);
    }

    // Testing negative deposit revert scenario
    function testRevertOnZeroDeposit() public {
      vm.prank(user);
      vm.expectRevert("Zero deposit");
      vault.deposit{value: 0}();
    }

    // Testing deposit fails when paused
    function testDepositFailsWhenPaused() public {
      vm.prank(owner);
      vault.pause();

      vm.prank(user);
      vm.expectRevert("Paused");
      vault.deposit{value: 1 ether}();
    }



    // Testing withdraw before one day has passed
    function testWithdrawBeforeOneDay_NoBonus() public {
      vm.prank(user);
      vault.deposit{value: 1 ether}();

      uint256 initialBalance = user.balance;

      vm.prank(user);
      vault.withdraw();
      uint256 finalBalance = user.balance;

      assertEq(finalBalance - initialBalance, 1 ether);
    }

    // Testing withdraw after one day to check bonus application
    // function testWithdrawAfterOneDay_WithBonus() public {
    //   vm.prank(user);
    //   vault.deposit{value: 1 ether}();

    //   vm.warp(block.timestamp + 1 days + 1);

    //   uint256 initialBalance = user.balance;

    //   vm.prank(user);
    //   vault.withdraw();
      
    //   uint256 finalBalance = user.balance;

    //   assertEq(finalBalance - initialBalance, 1.01 ether);
    // }
}