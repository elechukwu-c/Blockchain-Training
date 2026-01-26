// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureAuth {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address public immutable authorizedSigner;
    mapping(address => uint256) public nonces;

    constructor(address _authorizedSigner) {
        authorizedSigner = _authorizedSigner;
    }

    function authenticate(bytes calldata signature) external returns (bool) {
        uint256 nonce = nonces[msg.sender];

        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, nonce)
        );

        bytes32 ethSignedMessageHash =
            messageHash.toEthSignedMessageHash();

        address signer = ethSignedMessageHash.recover(signature);

        require(signer == authorizedSigner, "Invalid signature");

        nonces[msg.sender]++;

        return true;
    }
}
