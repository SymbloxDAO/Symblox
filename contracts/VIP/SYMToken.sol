// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SYMToken is ERC20, Ownable {
    // Constructor to set the details of the token and mint initial reserve
    constructor() ERC20("Symblox", "SYM") {
        mint(msg.sender, 200e6 * (10**uint256(decimals()))); // Mint 200 million tokens for reserve
    }

    /**
     * @dev Function to mint tokens
     * This function can only be called by the owner of the contract
     * @param account The address which will receive the minted tokens
     * @param amount The amount of tokens to mint (in wei)
     */
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Function to allow owner to adjust rewards APR, if needed.
     * Placeholder for actual logic based on requirements.
     * @param newApr The new APR value
     */
    function adjustRewardsApr(uint256 newApr) public onlyOwner {
        // Adjust the rewards APR
        // Actual implementation would require further detail
    }

    // Optionally, you may want to override `_beforeTokenTransfer` 
    // to include business logic that needs to be executed before any transfer, mint or burn

    // ... Additional functions like burning tokens, pause token transfers, etc.
}
