// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IVault {
    function createVault(address token) external;
    function adjustCollateralizationRatio(uint256 newRatio) external;
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    // Additional functions relevant to managing vaults
}
