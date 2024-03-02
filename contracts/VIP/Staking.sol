// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ISYMToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IxUSDToken {
    function mint(address account, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

contract StakingContract {
    ISYMToken public symToken;
    IxUSDToken public xUSDToken;

    address public owner;
    uint256 public constant targetCRatio = 350; // Example c-ratio, e.g., 350%
    uint256 public rewardInterval;
    uint public stakingStartTime;
    
    struct Staker {
        uint256 stakedSYM;
        uint256 borrowedXUSD;
    }
    
    mapping(address => Staker) public stakers;
    mapping(address => uint) public stakingTime;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(address _symAddress, address _xUSDAddress, uint256 _rewardInterval) {
        symToken = ISYMToken(_symAddress);
        xUSDToken = IxUSDToken(_xUSDAddress);
        stakingStartTime = block.timestamp;
        rewardInterval = _rewardInterval;
        owner = msg.sender;
    }
    
    function stakeSYM(uint256 amount) external {
        require(symToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        Staker storage staker = stakers[msg.sender];
        staker.stakedSYM += amount;
    }

    function borrowXUSD(uint256 amount) external {
        Staker storage staker = stakers[msg.sender];
        
        require(staker.stakedSYM > 0, "No SYM staked");
        uint256 maxBorrowable = staker.stakedSYM * targetCRatio / 100;
        require(staker.borrowedXUSD + amount <= maxBorrowable, "Borrow amount exceeds maximum allowed");

        staker.borrowedXUSD += amount;
        xUSDToken.mint(msg.sender, amount);
    }
    
    function burnXUSD(uint256 amount) external {
        xUSDToken.burnFrom(msg.sender, amount);
        
        Staker storage staker = stakers[msg.sender];
        staker.borrowedXUSD -= amount;
    }
    
    function unstakeSYM(uint256 amount) external {
        Staker storage staker = stakers[msg.sender];
        require(staker.borrowedXUSD == 0, "Debt must be repaid before unstaking");
        
        staker.stakedSYM -= amount;
        require(symToken.transfer(msg.sender, amount), "Unstake transfer failed");
    }
    
    function collectWeeklyRewards() external {
        // Weekly rewards distribution logic here
        // Ensure C-Ratio is maintained for eligibility
    }

    // Administrative functions to update the state of the contract
    function adjustTargetCRatio(uint256 newRatio) external onlyOwner {
        // Allow only owner to adjust the target collateralization ratio
    }
    
    function addRewards(uint256 rewardAmount) external onlyOwner {
        // Add rewards to the contract's distribution pool
    }

    function setRewardInterval(uint256 _rewardInterval) public onlyOwner{
        rewardInterval = _rewardInterval;
    }
}
