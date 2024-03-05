// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Proxy.sol";
import "./interfaces/IERC20.sol";

contract ProxyERC20 is Proxy, IERC20 {
    constructor(address _owner) public Proxy(_owner) {}

    function name() public view returns (string memory) {
        return IERC20(address(target)).name();
    }

    function symbol() public view returns (string memory) {
        return IERC20(address(target)).symbol();
    }

    function decimals() public view returns (uint8) {
        return IERC20(address(target)).decimals();
    }

    function totalSupply() public view returns (uint256) {
        return IERC20(address(target)).totalSupply();
    }

    function balanceOf(address account) public view returns (uint256) {
        return IERC20(address(target)).balanceOf(account);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return IERC20(address(target)).allowance(owner, spender);
    }
    function transfer(address to, uint256 value) public returns (bool) {
        target.setMessageSender(msg.sender);

        IERC20(address(target)).transfer(to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        target.setMessageSender(msg.sender);

        IERC20(address(target)).approve(spender, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        target.setMessageSender(msg.sender);

        IERC20(address(target)).transferFrom(from, to, value);

        return true;
    }
}