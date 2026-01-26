// // SPDX-License-Identifier: MIT

 /*  🟢 LEVEL 1 — BEGINNER
//     Focus

//     Function visibility

//     Pausable logic

//     Constructor initialization mistakes

//     Missing checks


    
//    === 🧠 Auditor Checklist (Beginner) ===

//     You should ask:

//     Who can call pause()?

//     Is owner trusted or user-supplied?

//     What if constructor is called with a malicious _owner?

//     Is pause logic consistently enforced?

//     Any missing access control modifiers?


❌ Vulnerable Contract (Audit This)
pragma solidity ^0.8.20;

contract SimpleVault {
    address public owner;
    bool public paused;
    mapping(address => uint256) public balances;

    constructor(address _owner) payable {
        owner = _owner; // ⚠️ user-controlled owner
    }

    function pause() public {
        paused = true; // ⚠️ anyone can pause
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(!paused, "paused");
        require(balances[msg.sender] >= amount);

        balances[msg.sender] -= amount;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok);
    }
}

 */

 /*///////////////////////////////////////////////////////////////////////////////////////////////////

                                    LEVEL 1 — BEGINNER AUDITED 

 //////////////////////////////////////////////////////////////////////////////////////////////////*/    

                                 
pragma solidity ^0.8.20;

contract SimpleVault {

    //Error
    error _paused();
    error NotOwner();
    error InsufficientBalance();

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    

    // State variables
    // added immutable after seeing correction from GPT
    address public immutable owner;
    bool public paused;
    mapping(address => uint256) public balances;

    // added onlyOwner modifier to restrict access control.
    modifier onlyOwner() {
        require(msg.sender == owner, NotOwner());
        _;
    }

    // Adding a modifer to check if the contract is paused.
    // edited my modifier after seeing correction from GPT.
    modifier whenNotPaused(){
        if (paused) {
            revert _paused();
        }
        _;
    }
    
    // corecting this contructor after i mistaknely overlooked it.
    constructor() payable {
        owner = msg.sender; // trusted initializer
    }

    // chanaging the visibility from public to external and adding onlyOnwer modifier to resitict who can call this function.
    function pause() external onlyOwner {
        paused = true; // added onlyOwner modifier to restrict access control.
    }

    //Adding another function to unpause the contract with onlyOwner modifier.
    function unPaused() external onlyOwner {
        paused = false;
    }

    /* ommited the checkPause
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    */

    //Corrected Deposit function
    function deposit() external payable whenNotPaused {
        //CHECK
        // added whenNotPaused modifier to check if the contract is paused.
        //EFFECT
        balances[msg.sender] += msg.value;
        //EVENT
        emit Deposit(msg.sender, msg.value);
    }

    /* Broke the logic while trying to audit this withdrawal function, for it was not onlyOwner withdrawal function.
    function withdraw(uint256 amount) external whenNotPaused onlyOwner {
        // i removed the redundant pause check here as its already being checked in the modifier.
        _checkPaused();
       emit Paused(msg.sender);
        //require(!paused, "paused");
        require(balances[msg.sender] >= amount, __InsufficientBalance());
        

        balances[msg.sender] -= amount;

        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok);
        emit Withdraw(msg.sender, amount);
    }
    */


    // Corrected of the withdrawal function
    function withdraw(uint256 amount) external whenNotPaused {
        //CHECK
       uint256 userBalance = balances[msg.sender];
       if (userBalance < amount) {
        revert InsufficientBalance();
       }

        //EFFECT
        balances[msg.sender] = userBalance - amount;

        //INTERACTION
        (bool ok, ) = msg.sender.call{value: amount}(" ");
        require(ok);
        
        //EVENT
        emit Withdraw(msg.sender, amount);
    }
}




/*/////////////////////////////////////////////////////////////////////////////////////////////////

                                    LEVEL 2 — INTERMEDIATE

///////////////////////////////////////////////////////////////////////////////////////////////////*/
/*
    🟡 LEVEL 2 — INTERMEDIATE
    Focus

    ETH transfer patterns

    Reentrancy

    Visibility mistakes

    Initialization attack surface

    ❌ Vulnerable Contract (Audit This)

    🧠 Auditor Checklist (Intermediate)

    Look for:

    Can initialize() be called multiple times?

    What happens if attacker initializes first?

    Reentrancy pattern (call before state update)

    Missing access control

    Public initialization without constructor
*/

/*

pragma solidity ^0.8.20;

contract RewardPool {
    address public owner;
    bool public initialized;

    mapping(address => uint256) public rewards;

    function initialize(address _owner) external {
        owner = _owner;          // ⚠️ no guard
        initialized = true;
    }

    function addReward(address user) external payable {
        rewards[user] += msg.value;
    }

    function claim() external {
        uint256 reward = rewards[msg.sender];
        require(reward > 0);

        (bool ok, ) = msg.sender.call{value: reward}("");
        require(ok);

        rewards[msg.sender] = 0; // ⚠️ state update after call
    }
}

*/

//pragma solidity ^0.8.20;

contract RewardPool {
    // State variables
    address public owner;
    bool public initialized;
    mapping(address => uint256) public rewards;

    // Errors
    error AlreadyInitialized();
    error NoRewards();
    error NotOwner();
    //error TransferFailed();

    // Events 
    event Initialized(address indexed owner);
    event RewardAdded(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    // modifier to restrict access control
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    // initialize function with access control and initialization check
    function initialize(address _owner) external {
        // state update
        if (initialized){
            revert AlreadyInitialized();
        }
        owner = _owner;
        initialized = true;
        emit Initialized(_owner);
    }

    // function to add rewards
    function addReward(address user) external payable onlyOwner {
        rewards[user] += msg.value;
        emit RewardAdded(user, msg.value);
    }

    // function to claim rewards with reentrancy protection
    function claim() external {
        //Check
        uint256 reward = rewards[msg.sender];
        if (reward == 0 ){
            revert NoRewards();
        }
        // state update before interaction
        // EFFECT
        rewards[msg.sender] = 0;

        // INTEREACTION
        (bool ok, ) = msg.sender.call{value: reward}("");
        require (ok, "Transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

}




/*/////////////////////////////////////////////////////////////////////////////////////////////////

                                    LEVEL 3 — ADVANCED

///////////////////////////////////////////////////////////////////////////////////////////////////*/
/*

/*
    🔴 LEVEL 3 — ADVANCED
    Focus

    Proxy-style initialization

    Delegatecall context

    Storage collision awareness

    Ownership takeover patterns

    Assume this is used behind a proxy via delegatecall.

    🧠 Auditor Checklist (Advanced)

    You should immediately think:

    Delegatecall → storage of proxy

    Can attacker call initialize() on proxy?

    Any initializer guard?

    Storage layout fixed?

    ETH balance tracked manually (⚠️)

    ❌ Vulnerable Contract (Audit This)


    contract WalletLogic {
        address public owner;
        uint256 public balance;

        function initialize(address _owner) external {
            owner = _owner; // ⚠️ no initializer guard
        }

        function withdraw(uint256 amount) external {
            require(msg.sender == owner);
            (bool ok, ) = msg.sender.call{value: amount}("");
            require(ok);
        }

        receive() external payable {
            balance += msg.value;
        }
    }


*/

contract walletLogic {
    //Error
    error NotOwner();
    error AlreadyInitialized();

    //Event
    event _withdraw(address indexed owner, uint256 amount);
    event _receive(address indexed sender, uint256 amount);

    // State variables
    address public owner;
    bool public initialized;
    /* i removed the balance variable as its not needed to track balance manually.
    uint256 public balance;
    */

    // Access control modifier
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function initialize(address _owner) external {
        if (initialized) {
            revert AlreadyInitialized();
        }
        owner = _owner; 
        initialized = true;
    }

    function withdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = owner.call{value: amount}("");
        require(ok);
        emit _withdraw(owner, amount);
    }

    receive() external payable {
        emit _receive(msg.sender, msg.value);
    }
}