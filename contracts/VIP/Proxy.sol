// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// Inheritance
import "./Owned.sol";

// Internal references
import "./Proxyable.sol";

contract Proxy is Owned {
    Proxyable public target;

    constructor(address _owner) Owned(_owner) {}

    function setTarget(Proxyable _target) external onlyOwner {
        target = _target;
        emit TargetUpdated(_target);
    }

    function _emit(
        bytes calldata callData,
        uint numTopics,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes32 topic4
    ) external onlyTarget {
        uint size = callData.length;
        bytes memory _callData = callData;

        assembly {
            /* The first 32 bytes of callData contain its length (as specified by the abi).
             * Length is assumed to be a uint256 and therefore maximum of 32 bytes
             * in length. It is also leftpadded to be a multiple of 32 bytes.
             * This means moving call_data across 32 bytes guarantees we correctly access
             * the data itself. */
            switch numTopics
                case 0 {
                    log0(add(_callData, 32), size)
                }
                case 1 {
                    log1(add(_callData, 32), size, topic1)
                }
                case 2 {
                    log2(add(_callData, 32), size, topic1, topic2)
                }
                case 3 {
                    log3(add(_callData, 32), size, topic1, topic2, topic3)
                }
                case 4 {
                    log4(add(_callData, 32), size, topic1, topic2, topic3, topic4)
                }
        }
    }

    fallback() external payable {
        // Mutable call setting Proxyable.messageSender as this is using call not delegatecall

        target.setMessageSender(msg.sender);

        assembly {
            let freeMemoryPointer := mload(0x40)
            calldatacopy(freeMemoryPointer, 0, calldatasize())

            /* We must explicitly forward ether to the underlying contract as well. */
            let result := call(gas(), sload(target.slot), callvalue(), freeMemoryPointer, calldatasize(), 0, 0)
            returndatacopy(freeMemoryPointer, 0, returndatasize())

            if iszero(result) {
                revert(freeMemoryPointer, returndatasize())
            }
            return(freeMemoryPointer, returndatasize())
        }
    }

    receive() external payable {
        
    }

    modifier onlyTarget {
        require(Proxyable(msg.sender) == target, "Must be proxy target");
        _;
    }

    event TargetUpdated(Proxyable newTarget);
}