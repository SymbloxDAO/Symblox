// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17; 

contract RewardsContract {
    uint256 public rewardApr; // Annual Percentage Rate for rewards
    
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardDebt; // Amount of SYM to be subtracted from the calculated reward
        // Additional fields can go here
    }
    
    mapping(address => StakerInfo) public stakers;

    // Assume this contract has an ERC20 token interface to interact with the SYM token contract
    IERC20 public immutable symToken;

    // Event emitted when APR is updated
    event AprUpdated(uint256 newApr);

    constructor(address _symTokenAddress) {
        symToken = IERC20(_symTokenAddress);
        rewardApr = 10; // Initial APR, for example, set to 10%
    }

    modifier onlyAuthorized() {
        // Placeholder for access control logic
        _;
    }

    // Function to update the APR (can be called by governance or an authorized account)
    function setRewardApr(uint256 _newApr) public onlyAuthorized {
        require(_newApr > 0, "APR must be greater than 0");
        rewardApr = _newApr;
        emit AprUpdated(_newApr);
    }

    // Function to calculate rewards for a staker
    function calculateReward(address staker) public view returns (uint256) {
        StakerInfo storage info = stakers[staker];
        return ((info.stakedAmount * rewardApr) / 100) / 365; // Daily reward approximation
    }

    // Function for a staker to claim their rewards
    function claimReward() public {
        StakerInfo storage info = stakers[msg.sender];
        uint256 reward = calculateReward(msg.sender);
        
        require(reward > 0, "No reward available");

        // Update rewardDebt to prevent re-claiming
        info.rewardDebt += reward;

        // Transfer the reward to staker
        symToken.transfer(msg.sender, reward);
    }

    // Function to allow users to stake SYM tokens
    function stake(uint256 amount) public {
        // Logic for transferring SYM tokens from the user to the contract
        // Update staker's information
    }
    
    // Function to allow users to unstake SYM tokens
    function unstake(uint256 amount) public {
        // Logic for transferring SYM tokens from the contract to the user
        // Update staker's information
    }

    // Additional functions to handle staking and rewards might be needed 
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    // Additional ERC20 functions used by the contract
}
