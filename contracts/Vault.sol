//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;
    mapping(address => bool) private admins;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(!admins[msg.sender], "The sender address is not an admin.");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _admin) external onlyAdmin {
        if (admins[_admin]) {
            delete admins[_admin];
        }
    }
}
