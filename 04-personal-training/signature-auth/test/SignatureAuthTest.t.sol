// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SignatureAuth.sol";
import {MessageHashUtils} from
    "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureAuthTest is Test {
    using MessageHashUtils for bytes32;

    SignatureAuth auth;

    uint256 signerPrivateKey;
    address signer;

    function setUp() external {
        signerPrivateKey = 0xA11CE;
        signer = vm.addr(signerPrivateKey);

        auth = new SignatureAuth(signer);
    }

    function testValidSignature() external {
        address user = address(0xBEEF);

        uint256 nonce = auth.nonces(user);

        bytes32 messageHash = keccak256(
            abi.encodePacked(user, nonce)
        );

        bytes32 ethSignedMessageHash =
            messageHash.toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, ethSignedMessageHash);

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        bool success = auth.authenticate(signature);

        assertTrue(success);
    }

    function testReplayAttackFails() external {
        address user = address(0xBEEF);

        uint256 nonce = auth.nonces(user);

        bytes32 messageHash = keccak256(
            abi.encodePacked(user, nonce)
        );

        bytes32 ethSignedMessageHash =
            messageHash.toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPrivateKey, ethSignedMessageHash);

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(user);
        auth.authenticate(signature);

        vm.prank(user);
        vm.expectRevert();
        auth.authenticate(signature);
    }
}
