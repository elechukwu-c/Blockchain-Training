// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    VaultGame
    ----------
    Users deposit ETH.
    After a lock period, they can withdraw with a "bonus".
    Owner can pause withdrawals.
    Intended to be proxy-compatible.
*/

contract VaultGame {
    // -----------------------
    // STORAGE
    // -----------------------
    
    address public owner;
    bool public paused;
    uint256 public totalDeposits;
    

    // adding initialization varaible 
    bool private initialized;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public depositTime;

    // ---------------------
    // ERRORS
    // ---------------------
    error AlreadyInitialized();
    error UseDeposit();
    error InvalidOwner();
    error ZeroAddress();

    // -----------------------
    // EVENTS (INTENTIONALLY INCOMPLETE)
    // -----------------------
    event Deposited(address indexed user, uint256 amount);
    // Missing Withdraw event
    event Withdrawal(address indexed user, uint256 amount);
    // Missing OwnerChanged event
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    // Missing Paused event
    event Paused(address indexed owner);

    // -----------------------
    // MODIFIERS
    // -----------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    // -----------------------
    // INITIALIZATION (PROXY)
    // -----------------------
    function initialize(address _owner) external {
      // Prevent re-initialization
      if(initialized) revert AlreadyInitialized();
        owner = _owner;
        initialized = true;
    }

    // -----------------------
    // CORE LOGIC
    // -----------------------
    // Recommendation: Update global invariants before user-specific state.
    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Zero deposit");

        totalDeposits += msg.value;
        balances[msg.sender] += msg.value;
        depositTime[msg.sender] = block.timestamp;
        //totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

// Medium — Time-Based Bonus Logic in Upgradeable Contract
// The withdrawal logic applies a 10% bonus based on block.timestamp relative to depositTime.
// This introduces time-dependence and economic assumptions that persist across upgrades.
// Additionally, the bonus is applied without explicit reward funding, which may lead to
// insolvency depending on protocol design.
// Recommendation: Consider isolating bonus logic via configurable parameters (e.g., delay, rate)
// and ensure rewards are economically backed. In upgradeable architectures, such parameters
// should be introduced cautiously to avoid storage layout issues.
function withdraw() external whenNotPaused {
      // Check balance
        uint256 bal = balances[msg.sender];
        require(bal > 0, "No balance");

        // Bonus: 10% if locked > 1 day
        if (block.timestamp > depositTime[msg.sender] + 1 days) {
            bal = bal + (bal / 10);
        }
      
      //  Moved effect before interaction following Checks-Effects-Interactions pattern
      //  and to prevent re-entrancy attacks.
      //  Effects
        balances[msg.sender] = 0;
        depositTime[msg.sender] = 0;
        
      // Interactions
        // External call BEFORE state update
        (bool ok, ) = msg.sender.call{value: bal}("");
        require(ok, "ETH transfer failed");

      emit Withdrawal(msg.sender, bal);
        
    }

    // -----------------------
    // ADMIN
    // -----------------------
    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

  // Critial: Missing access control
  // function changeOwner(address newOwner) external {
  //     owner = newOwner;
  // }
  //Low — Zero Address Ownership Risk
    function changeOwner(address newOwner) external onlyOwner {
      // require(newOwner != address(0), ZeroAddress());
        owner = newOwner;
        emit OwnerChanged(msg.sender, newOwner);
    }

    // -----------------------
    // RECEIVE
    // -----------------------
    // Frozen Funds Vulnerability Example
    // Anyone can send ETH directly to the contract, bypassing deposit logic
    receive() external payable {
        //totalDeposits += msg.value;
        revert UseDeposit();
    }
}
