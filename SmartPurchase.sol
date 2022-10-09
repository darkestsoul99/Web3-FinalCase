// This is a sample smart contract for safe remote purchase ethereum  

// Pragma version 

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.7; 

contract Agreement { 
    // Event declarations 
    event TransactionLog(
        uint date, 
        string message,
        uint val,
        address buyer 
    ); 

    // State Variables 
    struct Transaction {
        uint date; 
        uint payment; 
        address buyer_account;  
    }
    uint public value; // Value of the item
    uint public transactionCount = 0; // Total Transcation count 
    address payable public owner; // Owner of the account variable, aka Seller  
    address payable public buyer; // Buyer variable
    Transaction[] public transaction_array; // Transaction array 
    mapping(uint => Transaction) public transactions; // Transaction logs for each purchase 

    // Status enumarations of the contract 
    enum State {
        Created, 
        Locked, // When purchase is done 
        Release // After confirmation of the receive of item 
    }

    State public state; // Assigned default variable (Created) 

    // Constructor 
    constructor() payable {
        owner = payable(msg.sender); // Set the sender account as the owner
    } 

    // Payable contract 
    receive() external payable {}

    // Error Handling 
    /// The function cannot be called at the current state. 
    error InvalidState();
    /// Only the buyer can call this function 
    error OnlyBuyer(); 
    /// Only the seller can call this function 
    error OnlySeller(); 

    // Modifiers
    modifier inState(State _state) {
        if(state != _state) {
            revert InvalidState(); 
        }
        _; 
    }  

    modifier onlyBuyer() {
        if(msg.sender != buyer) {
            revert OnlyBuyer(); 
        }
        _; 
    }

    modifier onlySeller() {
        if(msg.sender != owner) {
            revert OnlySeller(); 
        }
        _; 
    }

    // Set the price 
    function setPrice() external onlySeller inState(State.Created) payable {
        value = msg.value; // Set the Ether price of this contract 
    }

    // Set the given account address as buyer 
    function setCurrentBuyer() external inState(State.Created) payable {
        buyer = payable(msg.sender); 
    }

    // Function for confirmation of Purchase
    function confirmPurchase() external onlyBuyer inState(State.Created) payable {
        require(msg.value == value, "Please send in 2x the purchase amount"); 
        state = State.Locked; // Lock the state of contract 
    } 

    // Function for receive 
    function confirmReceived() external onlyBuyer inState(State.Locked) {
        state = State.Release; // Go ahead and release funds
    }

    // Function to pay seller
    function paySeller() external onlySeller inState(State.Release) { 
        state = State.Created; // Update state to inactive
        owner.transfer(value*2); // Send 
        Transaction memory transaction; 
        transaction = Transaction(block.timestamp,value, buyer);  // Transaction create
        transaction_array.push(transaction); // Push each transaction to transaction array
        transactions[transactionCount] = transaction; // Mapping transactions 
        transactionCount++; // Count the number of transactions 
        emit TransactionLog(block.timestamp, "Transaction was successful.", value, buyer); // Transaction log  
        value = 0; // Set the price to zero, purchase is completed 
    } 

    // Abort purchase 
    function abort() external onlySeller inState(State.Created) { 
        state = State.Created; 
        owner.transfer(address(this).balance); 
        value = 0; 
    }

    // Get all transactions from an array
    function getTransactionArray() public view returns(Transaction[] memory) {
        return transaction_array; 
    }

    // Get all transactions from mapping 
    function getTransactionMapping() public view returns(Transaction[] memory) {
        Transaction[] memory internal_transaction = new Transaction[](transactionCount); 
        for (uint i=0; i<transactionCount; i++) {
            internal_transaction[i] = transactions[i]; 
        }
        return internal_transaction; 
    }

    // Get balance of the contract 
    function getBalance() public view returns(uint) {
        return address(this).balance; 
    }
} 
