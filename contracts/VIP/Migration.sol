// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MigrationContract is Ownable {
    IERC20 public oldToken;
    IERC20 public newToken;

    // Event to log the migration of tokens.
    event Migrate(address indexed user, uint256 amount);

    constructor(address _oldToken, address _newToken) {
        require(_oldToken != address(0) && _newToken != address(0), "Token addresses cannot be zero");
        oldToken = IERC20(_oldToken);
        newToken = IERC20(_newToken);
    }

    function migrate(uint256 amount) external {
        // Require the user has enough tokens to migrate
        require(oldToken.balanceOf(msg.sender) >= amount, "Not enough tokens to migrate");

        // Transfer the old tokens from the user to this contract
        oldToken.transferFrom(msg.sender, address(this), amount);

        // Mint or transfer the new tokens to the user
        // Assuming the newToken has a mint function accessible by this contract
        // newToken.mint(msg.sender, amount);
        // If newToken isn't mintable and uses a fixed supply, then it should be transferred instead
        require(newToken.transfer(msg.sender, amount), "Failed to transfer new tokens");

        // Emit the migration event
        emit Migrate(msg.sender, amount);
    }

    // In case you need to update the tokens addresses
    function setOldToken(address _oldToken) external onlyOwner {
        require(_oldToken != address(0), "Token address cannot be zero");
        oldToken = IERC20(_oldToken);
    }

    function setNewToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "Token address cannot be zero");
        newToken = IERC20(_newToken);
    }
}
