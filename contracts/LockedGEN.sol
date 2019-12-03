pragma solidity ^0.5.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LockedGEN is ERC20 {
    event StartLockPeriod(uint _lockId, address indexed _owner, uint _amount, uint _releaseTime);
    event ReleaseGEN(uint _lockId, address indexed _owner, uint _amount);

    struct lock {
        address owner;
        uint amount;
        uint releaseTime;
        bool released;
    }

    // Token details:
    string public constant name = "Locked-GEN";
    string public constant symbol = "LGN";
    uint8 public constant decimals = 18;

    // Constant parameters:
    ERC20 public GENtoken;
    uint public lockTime;

    // Contract storage:
    mapping (uint=>lock) public locks;
    uint public locksCounter;

    constructor(ERC20 _GENtoken, uint _lockTime) public {
        GENtoken = _GENtoken;
        lockTime = _lockTime;
    }

    function createLGN(uint _amount) public {
        GENtoken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function returnLGN(uint _amount) public returns(uint _lockId) {
        // Check user has enough on his balance, and burn his tokens:
        require(balanceOf(msg.sender) >= _amount, "balance is too low");
        _burn(msg.sender, _amount);

        // Set lock:
        _lockId = locksCounter;
        uint releaseTime = block.timestamp + lockTime;
        locks[_lockId] = lock(msg.sender, _amount, releaseTime, false);
        emit StartLockPeriod(_lockId, msg.sender, _amount, releaseTime);
        locksCounter++;
    }

    function release(uint _lockId) public {
        // Check locking time has passed, and tokens were not released in the past
        require(block.timestamp > locks[_lockId].releaseTime, "Locking time is not over");
        require(! locks[_lockId].released, "GENs already collected");

        // release GEN:
        locks[_lockId].released = true;
        GENtoken.transfer(msg.sender, locks[_lockId].amount);
        emit ReleaseGEN(_lockId, msg.sender, locks[_lockId].amount);
    }
}
