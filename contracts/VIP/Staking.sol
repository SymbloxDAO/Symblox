// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IxUSD {
    function mint(address to, uint256 amount) external;
}

contract SYMStaking {

    // Addresses for xUSD and gSYM contracts (placeholders)
    address public constant xUSDAddress = 0x123...; // Replace with actual contract address
    address public constant gSYMAddress = 0x456...; // Replace with actual contract address

    // Overcollateralization ratio
    uint256 public constant OVERCOLLATERALIZATION_RATIO = 350;

    // Keep track of staked SYM
    mapping(address => uint256) public stakes;

    // Assume we have an ERC20 token interface for SYM tokens
    IERC20 public SYMToken;

    constructor(address _SYMTokenAddress) {
        SYMToken = IERC20(_SYMTokenAddress);
    }

    function stakeSYM(uint256 symAmount) external {
        // Transfer SYM tokens to this contract for staking
        require(SYMToken.transferFrom(msg.sender, address(this), symAmount), "Transfer failed");

        // Update the user's stake
        stakes[msg.sender] += symAmount;

        // Calculate xUSD amount to mint based on overcollateralization
        uint256 xUSDAmtToMint = symAmount * 1000 / OVERCOLLATERALIZATION_RATIO;

        // Mint xUSD and send to the staker
        IxUSD(xUSDAddress).mint(msg.sender, xUSDAmtToMint);

        // Emit an event for obtaining gSYM (This is where actual gSYM NFT would be minted and sent)
        emit gSYMMinted(msg.sender);
    }

    // Placeholder for unstaking functionality
    function unstakeSYM(uint256 symAmount) external {
        // Implement unstaking logic, including checks and balances
    }

    // Events to emit for logging and tracking
    event gSYMMinted(address indexed staker);
    event SYMUnstaked(address indexed staker, uint256 amount);
}

// Interface for the SYM ERC20 functions we use
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
