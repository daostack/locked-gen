pragma solidity ^0.5.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LockedGEN is ERC20 {
    event StartLockPeriod(uint256 indexed _lockId, address indexed _owner, uint256 _amount, uint256 _releaseTime);
    event ReleaseGEN(uint256 indexed _lockId, address indexed _owner, uint256 _amount);

    struct lock {
        address owner;
        uint256 amount;
        uint256 releaseTime;
        bool released;
    }

    // Token details:
    string public constant name = "Locked-GEN";
    string public constant symbol = "LGN";
    uint8 public constant decimals = 18;

    // Constant parameters:
    ERC20 public genToken;
    uint256 public lockTime;

    // Contract storage:
    mapping (uint256=>lock) public locks;
    uint256 public locksCounter;

    constructor(ERC20 _genToken, uint256 _lockTime) public {
        genToken = _genToken;
        lockTime = _lockTime;
    }

    function mintLGN(uint256 _amount) public {
        genToken.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function burnLGN(uint256 _amount) public returns(uint256 lockId) {
        // Check user has enough on his balance, and burn his tokens:
        require(balanceOf(msg.sender) >= _amount, "balance is too low");
        _burn(msg.sender, _amount);

        // Set lock:
        lockId = locksCounter;
        uint256 releaseTime = block.timestamp + lockTime;
        locks[lockId] = lock(msg.sender, _amount, releaseTime, false);
        emit StartLockPeriod(lockId, msg.sender, _amount, releaseTime);
        locksCounter++;
    }

    function releaseGEN(uint256 _lockId) public {
        // Check locking time has passed, and tokens were not released in the past
        require(block.timestamp > locks[_lockId].releaseTime, "Locking time is not over");
        require(!locks[_lockId].released, "Lock was already released");

        // release GEN:
        locks[_lockId].released = true;
        genToken.transfer(locks[_lockId].owner, locks[_lockId].amount);
        emit ReleaseGEN(_lockId, msg.sender, locks[_lockId].amount);
    }
}
