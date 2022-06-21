//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;
    mapping(address => bool) public admins;
    uint256 public adminCount = 1;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "The sender address is not an admin.");
        _;
    }

    modifier notLastAdmin() {
        require(adminCount > 1, "The last admin cannot be removed.");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin returns (bool) {
        admins[_newAdmin] = true;
        adminCount++;
        return true;
    }

    function removeAdmin(address _admin) external onlyAdmin notLastAdmin returns (bool) {
        require(admins[_admin], "The address to remove is not an admin.");
        delete admins[_admin];
        adminCount--;
        return true;
    }
}
