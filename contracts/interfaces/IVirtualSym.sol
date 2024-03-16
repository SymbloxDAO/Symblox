// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISym.sol";

interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISym);

    // Mutative functions
    function settle(address account) external;
}