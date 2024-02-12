// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20MultiChain {
    function mint(address to, uint256 amount) external;
}

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SymbloxToken is IERC20MultiChain, Ownable {
    using SafeMath for uint256;

    string public constant name = "Symblox";
    string public constant symbol = "SYM";
    uint8 public constant decimals = 18;

    uint256 private _totalSupply;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private chainId;
    address public reserveAddress;
    uint256 public rewardsAPR;

    event Minted(address indexed to, uint256 amount);
    event RewardsAPRAdjusted(uint256 newAPR);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address _reserveAddress) {
        require(_reserveAddress != address(0), "Reserve address cannot be zero.");
        reserveAddress = _reserveAddress;
        uint256 reserveAmount = 200_000_000 * (10**uint256(decimals));
        _mint(reserveAddress, reserveAmount);
        chainId = block.chainid; // Recommended way to get the current chainId
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[chainId][account];
    }

    function adjustRewardsAPR(uint256 _newAPR) external onlyOwner {
        rewardsAPR = _newAPR;
        emit RewardsAPRAdjusted(_newAPR);
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        require(to != address(0), "Mint to the zero address");
        require(amount > 0, "Mint amount must be positive");

        _mint(to, amount);
        emit Minted(to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[chainId][account] = _balances[chainId][account].add(amount);

        emit Transfer(address(0), account, amount);
    }

    function getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }

        return id;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(balanceOf(msg.sender) >= amount, "Transfer amount exceeds balance");

        _balances[chainId][msg.sender] = _balances[chainId][msg.sender].sub(amount);
        _balances[chainId][recipient] = _balances[chainId][recipient].add(amount);

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        require(spender != address(0), "Approve to the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[chainId][sender] >= amount, "Transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "Transfer amount exceeds allowance");

        _balances[chainId][sender] = _balances[chainId][sender].sub(amount);
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        _balances[chainId][recipient] = _balances[chainId][recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }
}
