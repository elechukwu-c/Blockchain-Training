// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    uint256 myFavoriteNumber;

    struct Person {
        uint256 favoriteNumber;
        string name;
    }
    // uint256[] public anArray;
    Person[] public listOfPeople;

    mapping(string => uint256) public nameToFavoriteNumber;

    


    function store(uint256 _favoriteNumber) public {
        myFavoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return myFavoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }





    //////////////////////////////////////////////////////////////

    error ZeroWithdrawal();
    error InsufficientBalance(uint256 available, uint256 required);

    mapping(address => uint256) private balances;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function withdraw(uint256 amount) external {
        require (amount > 0, "Zero withdrawal");
        require (balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        
    }

    function withdrawall2(uint256 amount) external  {
        //CHECKS
        if (amount == 0) { 
            revert ZeroWithdrawal();}
        uint256 userBalance = balances[msg.sender];
        if (userBalance < amount) {
            revert InsufficientBalance({available: userBalance, required: amount});
        }

        // EFFECT
        balances[msg.sender] = userBalance - amount;

        //INTERACTION
        (bool success, ) = payable(msg.sender).call{value: amount} ("");
        require (success, "failed");

    }


}

