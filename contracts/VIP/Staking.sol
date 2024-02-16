// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IVault.sol";

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
    address public immutable xUSDAddress; 
    address public immutable gSYMAddress; 

    // Overcollateralization ratio
    // uint256 public overcollateralizationRatio;
    mapping(address => uint256) public overcollateralizationRatio;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Keep track of staked SYM
    mapping(address => uint256) public stakes;
    mapping(address => IVault) public vaults;
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
        owner = msg.sender;
        overcollateralizationRatio[owner] = 350;
    }

    function serOvercollateralizationRatio(address vaultAddress, uint256 _newRatio) external onlyOwner {
        require(_newRatio > 0, "Ratio must be bigger than zero");
        overcollateralizationRatio[vaultAddress] = _newRatio;
    }

    function stakeSYM(address vaultAddress, uint256 symAmount) external {
        require(symAmount > 0, "Can't Stake 0 Amount");
        require(SYMToken.transferFrom(msg.sender, address(this), symAmount), "Transfer failed");

        IVault vault = vaults[vaultAddress];
        require(vault != IVault(address(0)), "Vault does not exist");

        uint256 collateralRatio = overcollateralizationRatio[vaultAddress];
        require(collateralRatio > 0, "Collateral ratio not set");

        stakes[msg.sender] += symAmount;
        emit SYMStaked(msg.sender, symAmount);

        uint256 xUSDAmtToMint = symAmount * 100 / collateralRatio;
        IxUSD(xUSDAddress).mint(msg.sender, xUSDAmtToMint);

        // Emit an event for obtaining gSYM (This is where actual gSYM NFT would be minted and sent)
        emit gSYMMinted(msg.sender);
    }

    //need to check requirements & compare to synthetix 
    function unstakeSYM(uint256 symAmount) external {
        require(stakes[msg.sender] >= symAmount, "Insufficient staked balance");

        uint256 collateralRatio = overcollateralizationRatio[msg.sender];
        require(collateralRatio > 0, "Collateral ratio not set");

        uint256 xUSDAmtToBurn = symAmount * 100 / collateralRatio;
        require(IxUSD(xUSDAddress).balanceOf(msg.sender) >= xUSDAmtToBurn, "Insufficient xUSD balance");

        IxUSD(xUSDAddress).burn(msg.sender, xUSDAmtToBurn);
        stakes[msg.sender] -= symAmount;
        require(SYMToken.transfer(msg.sender, symAmount), "Transfer failed");
        
        emit SYMUnstaked(msg.sender, symAmount);
    }
}
