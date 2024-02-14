// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SymbloxGovernance {
    struct User {
        uint256 stakedAmount;
        uint256 gSymBalance;
        bool isStaked;
    }

    mapping(address => User) public users;
    mapping(address => bool) public oracleNodes;

    // Event triggered when a user stakes SYM tokens
    event Staked(address indexed user, uint256 amount);

    // Event triggered when a user unstakes SYM tokens
    event Unstaked(address indexed user, uint256 amount);

    // Event triggered when a user's gSYM balance changes
    event GSymBalanceChanged(address indexed user, uint256 newBalance);

    // Function for users to stake SYM tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(!users[msg.sender].isStaked, "Already staked");

        // Transfer SYM tokens from the user to this contract
        // (Assuming the token transfer is implemented elsewhere)
        // token.transferFrom(msg.sender, address(this), amount);

        // Update user's staked amount and gSYM balance
        users[msg.sender].stakedAmount = amount;
        users[msg.sender].gSymBalance = amount;
        users[msg.sender].isStaked = true;

        emit Staked(msg.sender, amount);
        emit GSymBalanceChanged(msg.sender, amount);
    }

    // Function for users to unstake SYM tokens
    function unstake() external {
        require(users[msg.sender].isStaked, "Not staked");

        // Transfer staked SYM tokens back to the user
        // (Assuming the token transfer is implemented elsewhere)
        // token.transfer(msg.sender, users[msg.sender].stakedAmount);

        // Reset user's staked amount and gSYM balance
        uint256 amount = users[msg.sender].stakedAmount;
        users[msg.sender].stakedAmount = 0;
        users[msg.sender].gSymBalance = 0;
        users[msg.sender].isStaked = false;

        emit Unstaked(msg.sender, amount);
        emit GSymBalanceChanged(msg.sender, 0);
    }

    // Function for users to vote
    function vote(uint256 proposalId) external {
        require(users[msg.sender].isStaked, "Not staked");
        // Perform voting logic here
    }

    // Function for oracle nodes to stake gSYM tokens
    function stakeOracleNode() external {
        require(!oracleNodes[msg.sender], "Already staked as oracle node");

        // Transfer gSYM tokens from the user to this contract
        // (Assuming the token transfer is implemented elsewhere)
        // gSymToken.transferFrom(msg.sender, address(this), amount);

        // Add the sender as an oracle node
        oracleNodes[msg.sender] = true;
    }

    // Function for oracle nodes to unstake gSYM tokens
    function unstakeOracleNode() external {
        require(oracleNodes[msg.sender], "Not staked as oracle node");

        // Transfer staked gSYM tokens back to the user
        // (Assuming the token transfer is implemented elsewhere)
        // gSymToken.transfer(msg.sender, stakedAmount);

        // Remove the sender as an oracle node
        oracleNodes[msg.sender] = false;
    }

    // Function to adjust the overcollateralization ratio for a vault
    function adjustOvercollateralizationRatio(uint256 vaultId, uint256 newRatio) external {
        // Perform overcollateralization ratio adjustment logic here
    }
}