// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    // Maps user addresses to a mapping of token addresses and their balances
    mapping(address => mapping(address => uint256)) public balances;

    // Event emitted when a deposit is made
    event Deposit(address indexed user, address indexed token, uint256 amount);

    // Event emitted when a withdrawal is made
    event Withdrawal(address indexed user, address indexed token, uint256 amount);

    // Deposits a certain amount of tokens from a specified ERC20 contract
    function deposit(address _token, uint256 _amount) external {
        require(_amount > 0, "Cannot deposit zero tokens");

        // Transfer the tokens from the sender to this contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Record that the sender has deposited the tokens
        balances[msg.sender][_token] += _amount;

        emit Deposit(msg.sender, _token, _amount);
    }

    // Withdraws a certain amount of tokens to the sender's address
    function withdraw(address _token, uint256 _amount) external {
        require(_amount > 0, "Cannot withdraw zero tokens");
        require(balances[msg.sender][_token] >= _amount, "Insufficient balance");

        // Deduct the tokens from the sender's Vault balance
        balances[msg.sender][_token] -= _amount;

        // Transfer the tokens to the sender
        IERC20(_token).transfer(msg.sender, _amount);

        emit Withdrawal(msg.sender, _token, _amount);
    }

    // Additional functionality can be added here such as handling collateralization,
    // issuing loans, and liquidation mechanisms etc.
}
