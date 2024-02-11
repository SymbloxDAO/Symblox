pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SymbloxToken is ERC20 {
    uint256 public constant DECIMALS = 18;
    address public admin;

    // Constructor sets up initial supply and admin rights
    constructor(address _teamAndInvestorsAddress) ERC20("Symblox", "SYM") {
        admin = msg.sender; 
        _mint(_teamAndInvestorsAddress, 200e6 * 10**DECIMALS); // Reserve 200 million SYM
    }

    // Only admin can call this function to mint new tokens
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == admin, "Unauthorized");
        _mint(_to, _amount);
    }

    // Admin can update rewards APR
    function setRewardsAPR(uint256 _newAPR) public {
        require(msg.sender == admin, "Unauthorized");
        // Logic to set new APR
    }

    // Function to migrate and swap to SYM at a 1 for 1 ratio
    function migrateTokens(address _fromContract, uint256 _amount) public {
        // Verify tokens from the _fromContract
        // Perform 1 for 1 token swap 
        // we can use migration contract.
    }
}
