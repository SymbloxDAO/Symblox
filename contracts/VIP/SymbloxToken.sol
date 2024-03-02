// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SymbloxToken is ERC20, Ownable {
    uint256 public constant INITIAL_RESERVE_AMOUNT = 200_000_000 * (10**decimals());
    uint256 public rewardsAPR;

    // Event for adjusting the Rewards APR
    event RewardsAPRAdjusted(uint256 newAPR);

    constructor(address reserveAddress) ERC20("Symblox", "SYM") {
        require(reserveAddress != address(0), "Reserve address cannot be zero.");
        _mint(reserveAddress, INITIAL_RESERVE_AMOUNT);
    }

    function adjustRewardsAPR(uint256 newAPR) public onlyOwner {
        rewardsAPR = newAPR;
        emit RewardsAPRAdjusted(newAPR);
    }

    function mint(address to, uint256 amount) public override onlyOwner {
        _mint(to, amount);
    }

    function mintRewards(address user, uint256 rewardBase) public onlyOwner {
        require(user != address(0), "Cannot mint to the zero address");
        uint256 rewardAmount = (rewardBase * rewardsAPR) / 100;
        _mint(user, rewardAmount);
    }
}
