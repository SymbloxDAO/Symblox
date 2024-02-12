// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IStaking {
    function stakeSYM(uint256 amount) external;
    function unstakeSYM(uint256 amount) external;
    // Additional functions for staking logic
}
