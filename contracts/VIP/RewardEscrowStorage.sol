// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RewardEscrowV2Frozen/IRewardEscrowV2Frozen.sol";

import "./interfaces/IRewardEscrowV2.sol";

import "./SignedSafeMath.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";

import "./State.sol";


contract RewardEscrowV2Storage is IRewardEscrowV2Storage, State {
    using SafeMath for uint;
    using SignedSafeMath for int;

    struct StorageEntry {
        uint32 endTime;
        uint224 escrowAmount;
    }

    mapping(address => mapping(uint => StorageEntry)) internal _vestingSchedules;

    mapping(address => uint[]) internal _accountVestingEntryIds;

    mapping(address => int) internal _fallbackCounts;

    mapping(address => int) internal _totalEscrowedAccountBalance;

    mapping(address => int) internal _totalVestedAccountBalance;

    uint internal _totalEscrowedBalance;

    uint public nextEntryId;

    uint public firstNonFallbackId;

    int internal constant ZERO_PLACEHOLDER = -1;

    IRewardEscrowV2Frozen public fallbackRewardEscrow;

    bytes32 public constant CONTRACT_NAME = "RewardEscrowStorage";

    constructor(address _owner, address _associatedContract) public Owned(_owner) State(_associatedContract) {}

    function setFallbackRewardEscrow(IRewardEscrowV2Frozen _fallbackRewardEscrow) external onlyOwner {
        require(address(fallbackRewardEscrow) == address(0), "already set");
        require(address(_fallbackRewardEscrow) != address(0), "cannot be zero address");

        fallbackRewardEscrow = _fallbackRewardEscrow;
        nextEntryId = _fallbackRewardEscrow.nextEntryId();
        firstNonFallbackId = nextEntryId;

        _totalEscrowedBalance = fallbackRewardEscrow.totalEscrowedBalance();
    }

    function vestingSchedules(address account, uint entryId)
        public
        view
        withFallback
        returns (VestingEntries.VestingEntry memory entry)
    {
        StorageEntry memory stored = _vestingSchedules[account][entryId];
        entry = VestingEntries.VestingEntry({endTime: stored.endTime, escrowAmount: stored.escrowAmount});
        if (entryId < firstNonFallbackId && entry.endTime == 0) {
            entry = fallbackRewardEscrow.vestingSchedules(account, entryId);
        }
        return entry;
    }

    function accountVestingEntryIDs(address account, uint index) public view withFallback returns (uint) {
        uint fallbackCount = _fallbackNumVestingEntries(account);

        if (index < fallbackCount) {
            return fallbackRewardEscrow.accountVestingEntryIDs(account, index);
        } else {
            return _accountVestingEntryIds[account][index - fallbackCount];
        }
    }

    function totalEscrowedBalance() public view withFallback returns (uint) {
        return _totalEscrowedBalance;
    }

    function totalEscrowedAccountBalance(address account) public view withFallback returns (uint) {
        int v = _totalEscrowedAccountBalance[account];

        if (v == 0) {
            return fallbackRewardEscrow.totalEscrowedAccountBalance(account);
        } else {
            return _readWithZeroPlaceholder(v);
        }
    }

    function totalVestedAccountBalance(address account) public view withFallback returns (uint) {
        int v = _totalVestedAccountBalance[account];

        if (v == 0) {
            return fallbackRewardEscrow.totalVestedAccountBalance(account);
        } else {
            return _readWithZeroPlaceholder(v);
        }
    }

    function numVestingEntries(address account) public view withFallback returns (uint) {
        return _fallbackNumVestingEntries(account) + _accountVestingEntryIds[account].length;
    }

    function _fallbackNumVestingEntries(address account) internal view returns (uint) {
        int v = _fallbackCounts[account];
        if (v == 0) {
            return fallbackRewardEscrow.numVestingEntries(account);
        } else {
            return _readWithZeroPlaceholder(v);
        }
    }

    function setZeroAmount(address account, uint entryId) public withFallback onlyAssociatedContract {
        StorageEntry storage storedEntry = _vestingSchedules[account][entryId];
        uint endTime = storedEntry.endTime;
        if (endTime == 0) {
            endTime = fallbackRewardEscrow.vestingSchedules(account, entryId).endTime;
        }
        _setZeroAmountWithEndTime(account, entryId, endTime);
    }

    function setZeroAmountUntilTarget(
        address account,
        uint startIndex,
        uint targetAmount
    )
        external
        withFallback
        onlyAssociatedContract
        returns (
            uint total,
            uint endIndex,
            uint lastEntryTime
        )
    {
        require(targetAmount > 0, "targetAmount is zero");

        _cacheFallbackIDCount(account);

        uint numIds = numVestingEntries(account);
        require(numIds > 0, "no entries to iterate");
        require(startIndex < numIds, "startIndex too high");

        uint entryID;
        uint i;
        VestingEntries.VestingEntry memory entry;
        for (i = startIndex; i < numIds; i++) {
            entryID = accountVestingEntryIDs(account, i);
            entry = vestingSchedules(account, entryID);

            // skip vested
            if (entry.escrowAmount > 0) {
                total = total.add(entry.escrowAmount);

                _setZeroAmountWithEndTime(account, entryID, entry.endTime);

                if (total >= targetAmount) {
                    break;
                }
            }
        }
        i = i == numIds ? i - 1 : i; // i was incremented one extra time if there was no break
        return (total, i, entry.endTime);
    }

    function updateEscrowAccountBalance(address account, int delta) external withFallback onlyAssociatedContract {
        int total = int(totalEscrowedAccountBalance(account)).add(delta);
        require(total >= 0, "updateEscrowAccountBalance: balance must be positive");
        _totalEscrowedAccountBalance[account] = _writeWithZeroPlaceholder(uint(total));

        updateTotalEscrowedBalance(delta);
    }

    function updateVestedAccountBalance(address account, int delta) external withFallback onlyAssociatedContract {
        int total = int(totalVestedAccountBalance(account)).add(delta);
        require(total >= 0, "updateVestedAccountBalance: balance must be positive");
        _totalVestedAccountBalance[account] = _writeWithZeroPlaceholder(uint(total));
    }

    function updateTotalEscrowedBalance(int delta) public withFallback onlyAssociatedContract {
        int total = int(totalEscrowedBalance()).add(delta);
        require(total >= 0, "updateTotalEscrowedBalance: balance must be positive");
        _totalEscrowedBalance = uint(total);
    }

    function addVestingEntry(address account, VestingEntries.VestingEntry calldata entry)
        external
        withFallback
        onlyAssociatedContract
        returns (uint)
    {
        require(entry.endTime != 0, "vesting target time zero");

        uint entryId = nextEntryId;
        _vestingSchedules[account][entryId] = StorageEntry({
            endTime: uint32(entry.endTime),
            escrowAmount: uint224(entry.escrowAmount)
        });

        _accountVestingEntryIds[account].push(entryId);

        nextEntryId++;

        return entryId;
    }

    function _setZeroAmountWithEndTime(
        address account,
        uint entryId,
        uint endTime
    ) internal {
        StorageEntry storage storedEntry = _vestingSchedules[account][entryId];
        storedEntry.endTime = uint32(endTime != 0 ? endTime : block.timestamp);
        storedEntry.escrowAmount = 0;
    }

    function _cacheFallbackIDCount(address account) internal {
        if (_fallbackCounts[account] == 0) {
            uint fallbackCount = fallbackRewardEscrow.numVestingEntries(account);
            _fallbackCounts[account] = _writeWithZeroPlaceholder(fallbackCount);
        }
    }

    function _writeWithZeroPlaceholder(uint v) internal pure returns (int) {
        return v == 0 ? ZERO_PLACEHOLDER : int(v);
    }

    function _readWithZeroPlaceholder(int v) internal pure returns (uint) {
        return uint(v == ZERO_PLACEHOLDER ? 0 : v);
    }

    modifier withFallback() {
        require(address(fallbackRewardEscrow) != address(0), "fallback not set");
        _;
    }
}