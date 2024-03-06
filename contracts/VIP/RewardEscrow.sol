// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BaseRewardEscrow.sol";
import "./interfaces/IRewardEscrow.sol";

contract RewardEscrow is BaseRewardEscrow {
    bytes32 private constant CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM = "SynthetixBridgeToOptimism";

    constructor(address _owner, address _resolver) public BaseRewardEscrowV2(_owner, _resolver) {}

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = BaseRewardEscrowV2.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](1);
        newAddresses[0] = CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM;
        return combineArrays(existingAddresses, newAddresses);
    }

    function synthetixBridgeToOptimism() internal view returns (address) {
        return requireAndGetAddress(CONTRACT_SYNTHETIX_BRIDGE_OPTIMISM);
    }

    function burnForMigration(address account, uint[] calldata entryIDs)
        external
        onlySynthetixBridge
        returns (uint256 escrowedAccountBalance, VestingEntries.VestingEntry[] memory vestingEntries)
    {
        require(entryIDs.length > 0, "Entry IDs required");

        vestingEntries = new VestingEntries.VestingEntry[](entryIDs.length);

        for (uint i = 0; i < entryIDs.length; i++) {
            VestingEntries.VestingEntry memory entry = vestingSchedules(account, entryIDs[i]);

            if (entry.escrowAmount > 0) {
                vestingEntries[i] = entry;

                escrowedAccountBalance = escrowedAccountBalance.add(entry.escrowAmount);

                state().setZeroAmount(account, entryIDs[i]);
            }
        }

        if (escrowedAccountBalance > 0) {
            state().updateEscrowAccountBalance(account, -SafeCast.toInt256(escrowedAccountBalance));
            synthetixERC20().transfer(synthetixBridgeToOptimism(), escrowedAccountBalance);
        }

        emit BurnedForMigrationToL2(account, entryIDs, escrowedAccountBalance, block.timestamp);

        return (escrowedAccountBalance, vestingEntries);
    }

    modifier onlySynthetixBridge() {
        require(msg.sender == synthetixBridgeToOptimism(), "Can only be invoked by SynthetixBridgeToOptimism contract");
        _;
    }

    event BurnedForMigrationToL2(address indexed account, uint[] entryIDs, uint escrowedAmountMigrated, uint time);
}