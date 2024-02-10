contract RewardsSystem {
    uint256 public annualPercentageRate;
    mapping(address => uint256) public stakedAmounts;

    function setAPR(uint256 _apr) external onlyOwner {
        annualPercentageRate = _apr;
    }

    function calculateReward(address user) public view returns (uint256) {
        // Calculate the reward based on stakedAmounts[user] and annualPercentageRate
    }

    // Functions for staking, unstaking, claiming rewards...
}
