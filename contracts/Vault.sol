//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;
    mapping(address => bool) public admins;
    uint256 public adminCount = 1;
    uint256 public sellPrice = 1;
    uint256 public buyPrice = 2;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "The sender address is not an admin.");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        admins[_newAdmin] = true;
        adminCount++;
    }

    modifier notLastAdmin() {
        require(adminCount > 1, "The last admin cannot be removed.");
        _;
    }

    function removeAdmin(address _admin) external onlyAdmin notLastAdmin {
        if (admins[_admin]) {
            delete admins[_admin];
            adminCount--;
        }
    }

    modifier numberValid(uint256 _number) {
        require(_number > 0, "The number must be greater than 0.");
        require(
            _number < 2**256 - 1,
            "The number must be less than 2**256 - 1."
        );
        _;
    }

    function setSellPrice(uint256 _price)
        external
        onlyAdmin
        numberValid(_price)
    {
        require(
            _price < buyPrice,
            "The sell price must be less than the buy price."
        );
        sellPrice = _price;
    }

    function setBuyPrice(uint256 _price)
        external
        onlyAdmin
        numberValid(_price)
    {
        require(
            _price > sellPrice,
            "The buy price must be greater than the sell price."
        );
        buyPrice = _price;
    }
}
