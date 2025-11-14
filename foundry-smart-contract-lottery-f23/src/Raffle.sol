// SPDX-License-Identtifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A sample Raffle Contract
 * @author Patrick Collins (as Teacher) Elechukwu Chibuike (as Student) AKA 0xECL_
 * @notice This contract is for creating a sample raffle
 * @dev It imlements Chainlink VRFv2.5 and Chainlink Automation
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 balance,
        uint256 playersLength,
        uint256 raffleState
    );

    /* Type declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // Number of confirmations before VRF request is fulfilled
    uint32 private constant NUM_WORDS = 1; // Number of random words to request
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit; // Gas limit for the callback function
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    // 1. Makes migration easier.
    // 2. Makes front end "indexing" easier

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    // What data structure should we use? How to keep track of all players?

    /* Functions */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCordinator,
        bytes32 gaslane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gaslane; // Set the key hash for the VRF request
        i_subscriptionId = subscriptionId; // Set the subscription ID for the VRF request
        i_callbackGasLimit = callbackGasLimit; // Set the callback gas limit for the VRF request

        s_lastTimeStamp = block.timestamp; // Set the last time stamp to the current block timestamp
        s_raffleState = RaffleState.OPEN; // Initialize the raffle state to OPEN
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent!");
        //require(msg.value >= i_entranceFee, Raffle__SendMoreToEnterRaffle());
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        // Check if the raffle is open
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        //calling the event
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev This is the fuction that the ChainLink nodes will call to see
     * If the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between Raffle runs.
     * 2. The Lottery is Open.
     * 3. The Contract has ETH. (has Players)
     * 4. Implicitly, your subscription has LINK.
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Function body should be implemented here
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >=
            i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, hex"");
    }

    // 1. Get a random number
    // 2. Use random number to pick a player
    // 3. Be automatically called.
    function performUpkeep(bytes calldata /* perfromData */) external {
        // check to see if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING; // Set the raffle state to CALCULATING

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient
            .RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pat for VRF request with Sepolia ETH instead
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
        // Get our radndom number
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);

        emit RequestedRaffleWinner(requestId);
    }

    // CEI: Check-Effects-Interactions
    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomWords
    ) internal override {
        // 1. Pick a random player
        // 2. Transfer the balance to the player
        // 3. Reset the players array
        // 4. Reset the last time stamp
        // Example: uint256 winnerIndex = randomWords[0] % s_Players.length;
        // address winner = s_Players[winnerIndex];
        // payable(winner).transfer(address(this).balance);
        // s_Players = new address payable[](0);
        // s_lastTimeStamp = block.timestamp;

        // Checks: Ensure the raffle is in the CALCULATING state(Internal Contract State)

        // Effects: Update the state variables (Internal Contract State)
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN; // Reset the raffle state to OPEN
        s_players = new address payable[](0); // Reset the players array
        s_lastTimeStamp = block.timestamp; // Reset the last time stamp
        emit WinnerPicked(s_recentWinner);

        // Interactions: Transfer the balance to the winner (External Contract Interaction)
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    /**
     * Getter functions
     *
     */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }
}
