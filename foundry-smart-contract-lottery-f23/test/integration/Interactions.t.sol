// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Interactions {
    // function testRaffleEmitsEventOnEntrance() public {
    //     // Arrange
    //     vm.prank(PLAYER);
    //     vm.expectEmit(true, false, false, false, address(raffle));
    //     // Act
    //     emit RaffleEntered(PLAYER);
    //     raffle.enterRaffle{value: entranceFee}();
    // }
    // function testRaffleDoesntAllowEntranceWhenRaffleIsCalculating() public {
    //     // Arrange
    //     vm.prank(PLAYER);
    //     raffle.enterRaffle{value: entranceFee}();
    //     vm.warp(block.timestamp + interval + 1);
    //     vm.roll(block.number + 1);
    //     raffle.performUpkeep("");
    //     // Act / Assert
    //     vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
    //     vm.prank(PLAYER);
    //     raffle.enterRaffle{value: entranceFee}();
    // }
}
