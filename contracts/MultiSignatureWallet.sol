pragma solidity ^0.5.0;

contract MultiSignatureWallet {

     address[] public owners;
     uint public required;
     uint public transactionCount;

    mapping(address => bool) public isOwner;
    mapping(uint => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations; 

    //confirmations[transactionsId][msg.sender] == false);

    struct Transaction {
      bool executed;
      address destination;
      uint value;
      bytes data;
    }

    

    event Deposit(address indexed sender, uint value);
    event Submission(uint indexed transactionId);
    event Confirmation(address indexed sender, uint indexed transactionsId);
    event Execution(uint indexed transactionsId);
    event ExecutionFailure(uint indexed transactionsId);
    event RevokeConfirmation(address indexed sender, uint indexed transactionsId);

    /// @dev Fallback function allows to deposit ether.
    function()
    	external
        payable
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
	}
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _owners, uint _required) public {
        for(uint i=0; i<_owners.length; i++){
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        
    }

    /// @dev Allows an owner to submit and confirm a transaction.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function submitTransaction(address destination, uint value, bytes memory data) public returns (uint transactionId) {
        require(isOwner[msg.sender]);

        transactionId = addTransaction(destination, value, data);
    }
    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public {
        require(isOwner[msg.sender]);
            require(transactions[transactionId].destination != address(0));
            require(confirmations[transactionId][msg.sender] == false);
            confirmations[transactionId][msg.sender] == true;
            emit Confirmation(msg.sender, transactionId);
            executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
        require(isOwner[msg.sender]);
            require(transactions[transactionId].destination != address(0));
            require(confirmations[transactionId][msg.sender] == true);
            confirmations[transactionId][msg.sender] == false;
            emit RevokeConfirmation(msg.sender, transactionId);
         
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public {
        require(transactions[transactionId].executed == false);
        if (isConfirmed(transactionId)) {
            Transaction storage t = transactions[transactionId];
            t.executed = true;
            (bool success, bytes memory returnedData) =t.destination.call.value(t.value)(t.data);
            if (success)
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                t.executed = false;
            }
        }
    }

		/*
		 * (Possible) Helper Functions
		 */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

    /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @return Returns transaction ID.
    function addTransaction(address destination, uint value, bytes memory data) internal returns (uint transactionId) {
        transactionId = transactionCount;
        transactions[transactionCount] = Transaction({
               executed: false,
               destination: destination,
               value: value,
               data: data
               
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }
}