// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiCollateralVault is Ownable {
    // Data structure to hold collateral information
    struct CollateralInfo {
        uint256 balance;
        bool isActive;
    }

    // Mapping from token address to user address to CollateralInfo
    mapping(address => mapping(address => CollateralInfo)) public vaults;

    event CollateralDeposited(address indexed token, address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed token, address indexed user, uint256 amount);

    /**
     * Deposit collateral into the vault.
     *
     * @param token The address of the token being deposited.
     * @param amount The amount of tokens to deposit as collateral.
     */
    function depositCollateral(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token != address(0), "Token address cannot be zero");

        // Transfer the tokens to this contract as collateral
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Update the user's collateral balance in the vault
        vaults[token][msg.sender].balance += amount;
        vaults[token][msg.sender].isActive = true;

        emit CollateralDeposited(token, msg.sender, amount);
    }

    /**
     * Withdraw collateral from the vault.
     *
     * @param token The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw from collateral.
     */
    function withdrawCollateral(address token, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token != address(0), "Token address cannot be zero");
        require(vaults[token][msg.sender].isActive, "Vault is not active");
        require(vaults[token][msg.sender].balance >= amount, "Insufficient collateral balance");

        // Decrease the user's collateral balance in the vault
        vaults[token][msg.sender].balance -= amount;

        if (vaults[token][msg.sender].balance == 0) {
            vaults[token][msg.sender].isActive = false;
        }

        // Transfer the collateral back to the user
        IERC20(token).transfer(msg.sender, amount);

        emit CollateralWithdrawn(token, msg.sender, amount);
    }

    // Additional functions like `getCollateralBalance` and `liquidateCollateral`
    // could be implemented to complete the functionality of the vault.
}
