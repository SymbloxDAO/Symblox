// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Owned.sol";
import "./MixinResolver.sol";
import "./RewardEscrowStorage.sol";
import "./LimitedSetup.sol";
import "./interfaces/IRewardEscrow.sol";

import "./SafeCast.sol";
import "./SafeDecimalMath.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IIssuer.sol";

contract BaseRewardEscrowV2 is Owned, IRewardEscrow, LimitedSetup(8 weeks), MixinResolver {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    mapping(address => address) public nominatedReceiver;
    mapping(address => bool) public permittedEscrowCreators;

    uint public max_duration = 2 * 52 weeks; // Default max 2 years duration

    uint public maxAccountMergingDuration = 4 weeks; // Default 4 weeks is max

    uint public accountMergingDuration = 1 weeks;

    uint public accountMergingStartTime;

    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_REWARDESCROWV2STORAGE = "RewardEscrowV2Storage";

    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function synthetixERC20() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHETIX));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    function state() internal view returns (IRewardEscrowV2Storage) {
        return IRewardEscrowV2Storage(requireAndGetAddress(CONTRACT_REWARDESCROWV2STORAGE));
    }

    function _notImplemented() internal pure {
        revert("Cannot be run on this layer");
    }

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](4);
        addresses[0] = CONTRACT_SYNTHETIX;
        addresses[1] = CONTRACT_FEEPOOL;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_REWARDESCROWV2STORAGE;
    }

    function numVestingEntries(address account) public view returns (uint) {
        return state().numVestingEntries(account);
    }

    function totalEscrowedBalance() public view returns (uint) {
        return state().totalEscrowedBalance();
    }

    function totalEscrowedAccountBalance(address account) public view returns (uint) {
        return state().totalEscrowedAccountBalance(account);
    }

    function totalVestedAccountBalance(address account) external view returns (uint) {
        return state().totalVestedAccountBalance(account);
    }

    function nextEntryId() external view returns (uint) {
        return state().nextEntryId();
    }

    function vestingSchedules(address account, uint256 entryId) public view returns (VestingEntries.VestingEntry memory) {
        return state().vestingSchedules(account, entryId);
    }

    function accountVestingEntryIDs(address account, uint256 index) public view returns (uint) {
        return state().accountVestingEntryIDs(account, index);
    }

    function balanceOf(address account) public view returns (uint) {
        return totalEscrowedAccountBalance(account);
    }

    function getVestingEntry(address account, uint256 entryID) external view returns (uint64 endTime, uint256 escrowAmount) {
        VestingEntries.VestingEntry memory entry = vestingSchedules(account, entryID);
        return (entry.endTime, entry.escrowAmount);
    }

    function getVestingSchedules(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (VestingEntries.VestingEntryWithID[] memory) {
        uint256 endIndex = index + pageSize;

        if (endIndex <= index) {
            return new VestingEntries.VestingEntryWithID[](0);
        }

        if (endIndex > numVestingEntries(account)) {
            endIndex = numVestingEntries(account);
        }

        uint256 n = endIndex - index;
        uint256 entryID;
        VestingEntries.VestingEntry memory entry;
        VestingEntries.VestingEntryWithID[] memory vestingEntries = new VestingEntries.VestingEntryWithID[](n);
        for (uint256 i; i < n; i++) {
            entryID = accountVestingEntryIDs(account, i + index);

            entry = vestingSchedules(account, entryID);

            vestingEntries[i] = VestingEntries.VestingEntryWithID({
                endTime: uint64(entry.endTime),
                escrowAmount: entry.escrowAmount,
                entryID: entryID
            });
        }
        return vestingEntries;
    }

    function getAccountVestingEntryIDs(
        address account,
        uint256 index,
        uint256 pageSize
    ) external view returns (uint256[] memory) {
        uint256 endIndex = index + pageSize;

        uint numEntries = numVestingEntries(account);
        if (endIndex > numEntries) {
            endIndex = numEntries;
        }
        if (endIndex <= index) {
            return new uint256[](0);
        }

        uint256 n = endIndex - index;
        uint256[] memory page = new uint256[](n);
        for (uint256 i; i < n; i++) {
            page[i] = accountVestingEntryIDs(account, i + index);
        }
        return page;
    }

    function getVestingQuantity(address account, uint256[] calldata entryIDs) external view returns (uint total) {
        VestingEntries.VestingEntry memory entry;
        for (uint i = 0; i < entryIDs.length; i++) {
            entry = vestingSchedules(account, entryIDs[i]);

            if (entry.escrowAmount != 0) {
                uint256 quantity = _claimableAmount(entry);

                total = total.add(quantity);
            }
        }
    }

    function getVestingEntryClaimable(address account, uint256 entryID) external view returns (uint) {
        return _claimableAmount(vestingSchedules(account, entryID));
    }

    function _claimableAmount(VestingEntries.VestingEntry memory _entry) internal view returns (uint256) {
        uint256 quantity;
        if (_entry.escrowAmount != 0) {
            quantity = block.timestamp >= _entry.endTime ? _entry.escrowAmount : 0;
        }
        return quantity;
    }
    
    function vest(uint256[] calldata entryIDs) external {
        address account = msg.sender;

        uint256 total;
        VestingEntries.VestingEntry memory entry;
        uint256 quantity;
        for (uint i = 0; i < entryIDs.length; i++) {
            entry = vestingSchedules(account, entryIDs[i]);

            if (entry.escrowAmount != 0) {
                quantity = _claimableAmount(entry);

                if (quantity > 0) {
                    state().setZeroAmount(account, entryIDs[i]);
                }

                total = total.add(quantity);
            }
        }

        if (total != 0) {
            _subtractAndTransfer(account, account, total);
            // update total vested
            state().updateVestedAccountBalance(account, SafeCast.toInt256(total));
            emit Vested(account, block.timestamp, total);
        }
    }
    
    function revokeFrom(
        address account,
        address recipient,
        uint targetAmount,
        uint startIndex
    ) external onlySynthetix {
        require(account != address(0), "account not set");
        require(recipient != address(0), "recipient not set");

        (uint total, uint endIndex, uint lastEntryTime) =
            state().setZeroAmountUntilTarget(account, startIndex, targetAmount);

        require(total >= targetAmount, "entries sum less than target");

        if (total > targetAmount) {
            uint refund = total.sub(targetAmount);
            uint entryID =
                state().addVestingEntry(
                    account,
                    VestingEntries.VestingEntry({endTime: uint64(lastEntryTime), escrowAmount: refund})
                );
            uint duration = lastEntryTime > block.timestamp ? lastEntryTime.sub(block.timestamp) : 0;
            emit VestingEntryCreated(account, block.timestamp, refund, duration, entryID);
        }

        _subtractAndTransfer(account, recipient, targetAmount);

        emit Revoked(account, recipient, targetAmount, startIndex, endIndex);
    }

    function _subtractAndTransfer(
        address subtractFrom,
        address transferTo,
        uint256 amount
    ) internal {
        state().updateEscrowAccountBalance(subtractFrom, -SafeCast.toInt256(amount));
        synthetixERC20().transfer(transferTo, amount);
    }

    function setPermittedEscrowCreator(address creator, bool permitted) external onlyOwner {
        permittedEscrowCreators[creator] = permitted;
    }

    function createEscrowEntry(
        address beneficiary,
        uint256 deposit,
        uint256 duration
    ) external {
        require(beneficiary != address(0), "Cannot create escrow with address(0)");
        require(permittedEscrowCreators[msg.sender], "Only permitted escrow creators can create escrow entries");

        require(synthetixERC20().transferFrom(msg.sender, address(this), deposit), "token transfer failed");

        _appendVestingEntry(beneficiary, deposit, duration);
    }

    function appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) external onlyFeePool {
        _appendVestingEntry(account, quantity, duration);
    }

    function _appendVestingEntry(
        address account,
        uint256 quantity,
        uint256 duration
    ) internal {
        require(quantity != 0, "Quantity cannot be zero");
        require(duration > 0 && duration <= max_duration, "Cannot escrow with 0 duration OR above max_duration");

        state().updateEscrowAccountBalance(account, SafeCast.toInt256(quantity));

        require(
            totalEscrowedBalance() <= synthetixERC20().balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        uint endTime = block.timestamp + duration;

        uint entryID =
            state().addVestingEntry(
                account,
                VestingEntries.VestingEntry({endTime: uint64(endTime), escrowAmount: quantity})
            );

        emit VestingEntryCreated(account, block.timestamp, quantity, duration, entryID);
    }

    function accountMergingIsOpen() public view returns (bool) {
        return accountMergingStartTime.add(accountMergingDuration) > block.timestamp;
    }

    function startMergingWindow() external onlyOwner {
        accountMergingStartTime = block.timestamp;
        emit AccountMergingStarted(accountMergingStartTime, accountMergingStartTime.add(accountMergingDuration));
    }

    function setAccountMergingDuration(uint256 duration) external onlyOwner {
        require(duration <= maxAccountMergingDuration, "exceeds max merging duration");
        accountMergingDuration = duration;
        emit AccountMergingDurationUpdated(duration);
    }

    function setMaxAccountMergingWindow(uint256 duration) external onlyOwner {
        maxAccountMergingDuration = duration;
        emit MaxAccountMergingDurationUpdated(duration);
    }

    function setMaxEscrowDuration(uint256 duration) external onlyOwner {
        max_duration = duration;
        emit MaxEscrowDurationUpdated(duration);
    }

    /* Nominate an account to merge escrow and vesting schedule */
    function nominateAccountToMerge(address account) external {
        require(account != msg.sender, "Cannot nominate own account to merge");
        require(accountMergingIsOpen(), "Account merging has ended");
        require(issuer().debtBalanceOf(msg.sender, "sUSD") == 0, "Cannot merge accounts with debt");
        nominatedReceiver[msg.sender] = account;
        emit NominateAccountToMerge(msg.sender, account);
    }

    function mergeAccount(address from, uint256[] calldata entryIDs) external {
        require(accountMergingIsOpen(), "Account merging has ended");
        require(issuer().debtBalanceOf(from, "sUSD") == 0, "Cannot merge accounts with debt");
        require(nominatedReceiver[from] == msg.sender, "Address is not nominated to merge");
        address to = msg.sender;

        uint256 totalEscrowAmountMerged;
        VestingEntries.VestingEntry memory entry;
        for (uint i = 0; i < entryIDs.length; i++) {
            entry = vestingSchedules(from, entryIDs[i]);

            if (entry.escrowAmount != 0) {
                state().setZeroAmount(from, entryIDs[i]);

                state().addVestingEntry(to, entry);

                totalEscrowAmountMerged = totalEscrowAmountMerged.add(entry.escrowAmount);
            }
        }

        state().updateEscrowAccountBalance(from, -SafeCast.toInt256(totalEscrowAmountMerged));
        state().updateEscrowAccountBalance(to, SafeCast.toInt256(totalEscrowAmountMerged));

        emit AccountMerged(from, to, totalEscrowAmountMerged, entryIDs, block.timestamp);
    }

    function migrateVestingSchedule(address) external {
        _notImplemented();
    }

    function migrateAccountEscrowBalances(
        address[] calldata,
        uint256[] calldata,
        uint256[] calldata
    ) external {
        _notImplemented();
    }

    function burnForMigration(address, uint[] calldata) external returns (uint256, VestingEntries.VestingEntry[] memory) {
        _notImplemented();
    }

    function importVestingEntries(
        address,
        uint256,
        VestingEntries.VestingEntry[] calldata
    ) external {
        _notImplemented();
    }

    modifier onlyFeePool() {
        require(msg.sender == address(feePool()), "Only the FeePool can perform this action");
        _;
    }

    modifier onlySynthetix() {
        require(msg.sender == address(synthetixERC20()), "Only Synthetix");
        _;
    }

    event Vested(address indexed beneficiary, uint time, uint value);
    event VestingEntryCreated(address indexed beneficiary, uint time, uint value, uint duration, uint entryID);
    event MaxEscrowDurationUpdated(uint newDuration);
    event MaxAccountMergingDurationUpdated(uint newDuration);
    event AccountMergingDurationUpdated(uint newDuration);
    event AccountMergingStarted(uint time, uint endTime);
    event AccountMerged(
        address indexed accountToMerge,
        address destinationAddress,
        uint escrowAmountMerged,
        uint[] entryIDs,
        uint time
    );
    event NominateAccountToMerge(address indexed account, address destination);
    event Revoked(address indexed account, address indexed recipient, uint targetAmount, uint startIndex, uint endIndex);
}