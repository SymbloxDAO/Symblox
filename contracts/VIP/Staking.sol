// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IxUSD {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SYMStaking {

    // Addresses for xUSD and gSYM contracts (placeholders)
    address public immutable xUSDAddress; 
    address public immutable gSYMAddress; 

    // Overcollateralization ratio
    uint256 public constant OVERCOLLATERALIZATION_RATIO = 350;

    // Keep track of staked SYM
    mapping(address => uint256) public stakes;

    // Assume we have an ERC20 token interface for SYM tokens
    IERC20 public SYMToken;

    // Events for logging and tracking
    event gSYMMinted(address indexed staker);
    event SYMStaked(address indexed staker, uint256 amount);
    event SYMUnstaked(address indexed staker, uint256 amount);

    constructor(address _SYMTokenAddress, address _xUSDAddress, address _gSYMAddress) {
        SYMToken = IERC20(_SYMTokenAddress);
        xUSDAddress = _xUSDAddress;
        gSYMAddress = _gSYMAddress;
    }

    function stakeSYM(uint256 symAmount) external {
        require(symAmount > 0, "Can't Stake 0 Amount");
        // Transfer SYM tokens to this contract for staking
        require(SYMToken.transferFrom(msg.sender, address(this), symAmount), "Transfer failed");

        // Update the user's stake
        stakes[msg.sender] += symAmount;

        emit SYMStaked(msg.sender, symAmount);
        // Calculate xUSD amount to mint based on overcollateralization
        uint256 xUSDAmtToMint = symAmount * 100 / OVERCOLLATERALIZATION_RATIO;

        // Mint xUSD and send to the staker
        IxUSD(xUSDAddress).mint(msg.sender, xUSDAmtToMint);

        // Emit an event for obtaining gSYM (This is where actual gSYM NFT would be minted and sent)
        emit gSYMMinted(msg.sender);
    }

    function unstakeSYM(uint256 symAmount) external {
        require(stakes[msg.sender] >= symAmount, "Insufficient staked balance");

        uint256 xUSDAmtToBurn = (symAmount * 100) / OVERCOLLATERALIZATION_RATIO;
    
        // Check if the staker has enough xUSD to burn
        require(IxUSD(xUSDAddress).balanceOf(msg.sender) >= xUSDAmtToBurn, "Insufficient xUSD balance");

        // Burn the corresponding xUSD from the staker's balance
        IxUSD(xUSDAddress).burn(msg.sender, xUSDAmtToBurn);
        
        // Reduce the user's stake balance
        stakes[msg.sender] -= symAmount;
        
        // Return the SYM tokens to the staker
        require(SYMToken.transfer(msg.sender, symAmount), "Transfer failed");
        
        // Emit an event for unstaking SYM
        emit SYMUnstaked(msg.sender, symAmount);
    }
}
