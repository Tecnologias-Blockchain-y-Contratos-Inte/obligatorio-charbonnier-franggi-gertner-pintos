//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Farm {
    uint256 public constant VERSION = 100;
    uint256 private constant INCREASE = 1;
    uint256 private constant DECREASE = 2;

    address public tokenContract;

    mapping(address => FarmData) private balances;

    uint256 public totalStake = 0; // total amount of tokens staked by all users
    uint256 public totalYieldPaid = 0; // total amount of yield paid out for all users
    uint256 public APR;

    struct FarmData {
        uint256 stake;
        uint256 APR;
        uint256 timestamp;
    }

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    // TODO: test functionality when token contract ready.
    function stake(uint256 _amount) external returns (bool) {
        uint256 oldStake = 0;
        uint256 newStake = _amount;
        uint256 newAPR = APR;
        uint256 newTimestamp = block.timestamp;

        // TODO: add permissions in TokenContract for Farm to do this.
        bytes memory transferFrom = abi.encodeWithSignature("transferFrom(address, address, uint256)", msg.sender, address(this), _amount);
        (bool _success, ) = tokenContract.call(transferFrom);
        
        require(_success, "You don't have enough tokens to stake");

        if (balances[msg.sender].stake > 0 && balances[msg.sender].APR > 0 && balances[msg.sender].timestamp > 0) {
            oldStake = balances[msg.sender].stake;
            uint256 income = (balances[msg.sender].stake + _amount) * balances[msg.sender].APR * 100; // Yield for an year without actual yield
            newStake = _getNewStakeForTimestamp(newTimestamp, _amount, INCREASE);
            newAPR = income * 100 / newStake;

            return true;
        }

        totalStake += newStake - oldStake;
        balances[msg.sender].stake = newStake;
        balances[msg.sender].APR = newAPR;
        balances[msg.sender].timestamp = newTimestamp;

        return true;
    }

    // TODO: test functionality when token contract ready.
    function unstake(uint256 _amount) external returns (bool) {
        require(balances[msg.sender].stake > 0 && balances[msg.sender].APR > 0 && balances[msg.sender].timestamp > 0, "You don't have any tokens to unstake");
        
        uint256 newTimestamp = block.timestamp;
        uint256 newStake = _getNewStakeForTimestamp(newTimestamp, _amount, DECREASE);
        
        require(newStake >= 0, "You don't have enough tokens to unstake");

        uint256 oldStake = balances[msg.sender].stake;
        bytes memory transfer = abi.encodeWithSignature("transfer(address, uint256)", msg.sender, _amount);
        (bool _success, ) = tokenContract.call(transfer);

        require(_success, "Something went wrong while unstaking");

        uint256 income = (balances[msg.sender].stake - _amount) * balances[msg.sender].APR * 100; // Yield for an year without actual yield
        uint256 newAPR = income * 100 / newStake;

        totalStake -= oldStake - newStake;
        balances[msg.sender].stake = newStake;
        balances[msg.sender].APR = newAPR;
        balances[msg.sender].timestamp = newTimestamp;
        
        return true;
    }

    // TODO: test functionality when token contract ready.
    function withdrawYield() external returns (bool) {
        uint256 newTimestamp = block.timestamp;
        uint256 yield = _getYieldForTimestamp(newTimestamp);
        
        // TODO: create yield (mint)
        bytes memory transfer = abi.encodeWithSignature("transfer(address, uint256)", msg.sender, yield);
        (bool _success, ) = tokenContract.call(transfer);
        
        require(_success, "Something went wrong while withdrawing yield");

        balances[msg.sender].timestamp = newTimestamp;
        balances[msg.sender].APR = APR;
        totalYieldPaid += yield;
        return true;
    }

    function getYield() public view returns (uint256) {
        return _getYieldForTimestamp(block.timestamp);
    }

    function getStake() external view returns (uint256) {
        return balances[msg.sender].stake;
    }

    function _getYieldForTimestamp(uint256 _timestamp) private view returns (uint256) {
        uint256 timeDiff = _timestamp - balances[msg.sender].timestamp / 60 / 60 / 24 / 36524 * 100; // time in years
        uint256 yield = balances[msg.sender].stake * balances[msg.sender].APR * timeDiff / 100;
        return yield;
    }

    function _getNewStakeForTimestamp(uint256 _timestamp, uint256 _amount, uint256 _variation) private view returns (uint256) {
        uint256 yield = _getYieldForTimestamp(_timestamp);
        if (_variation == INCREASE) {
            return balances[msg.sender].stake + yield + _amount;
        } else if (_variation == INCREASE) {
            return balances[msg.sender].stake + yield - _amount;
        } else {
            revert("Invalid variation");
        }
    }
}
