// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwapper is Ownable {
    IERC20 public otherToken;
    IERC20 public symToken;

    event TokensSwapped(address indexed user, uint256 amount);

    constructor(IERC20 _otherToken, IERC20 _symToken) {
        require(address(_otherToken) != address(0), "Other token address cannot be zero");
        require(address(_symToken) != address(0), "SYM token address cannot be zero");

        otherToken = _otherToken;
        symToken = _symToken;
    }

    /**
     * Swap from the other token to the SYM token on a 1:1 basis.
     *
     * @param amount The amount of other tokens to swap.
     */
    function swap(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer other tokens to this contract
        bool sent = otherToken.transferFrom(msg.sender, address(this), amount);
        require(sent, "Failed to transfer other tokens");

        // Ensure that this contract has enough SYM tokens for swapping
        require(symToken.balanceOf(address(this)) >= amount, "Insufficient SYM balance in the contract");

        // Transfer SYM tokens back to user
        symToken.transfer(msg.sender, amount);

        emit TokensSwapped(msg.sender, amount);
    }

    /**
     * Withdraw SYM tokens from this contract (in case of excess or end of campaign).
     *
     * @param amount The number of SYM tokens to withdraw.
     */
    function withdrawSYM(uint256 amount) external onlyOwner {
        require(amount <= symToken.balanceOf(address(this)), "Insufficient balance to withdraw");
        symToken.transfer(msg.sender, amount);
    }
}
