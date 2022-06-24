//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;
    uint256 public adminCount = 1;
    uint256 public sellPrice = 2;
    uint256 public buyPrice = 1;
    uint256 public mintingNumber = 1;
    address public tokenContract;
    mapping(address => bool) public admins;
    mapping(uint256 => mapping(uint256 => Votes)) public mintingVotes;

    struct Votes {
        uint256 count;
        mapping(address => bool) accounts;
    }

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

    modifier numberValid(uint256 _number) {
        require(_number > 0, "The number must be greater than 0.");
        require(
            _number < 2**256 - 1,
            "The number must be less than 2**256 - 1."
        );
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin returns (bool) {
        admins[_newAdmin] = true;
        adminCount++;
        return true;
    }

    function removeAdmin(address _admin)
        external
        onlyAdmin
        notLastAdmin
        returns (bool)
    {
        require(admins[_admin], "The address to remove is not an admin.");
        delete admins[_admin];
        adminCount--;
        return true;
    }

    function setSellPrice(uint256 _price)
        external
        onlyAdmin
        numberValid(_price)
    {
        require(
            _price > buyPrice,
            "The sell price must be greater than the buy price."
        );
        sellPrice = _price;
    }

    function setBuyPrice(uint256 _price)
        external
        onlyAdmin
        numberValid(_price)
    {
        require(
            _price < sellPrice,
            "The buy price must be less than the sell price."
        );
        buyPrice = _price;
    }

    function mint(uint256 _amount) external onlyAdmin {
        if (!mintingVotes[_amount][mintingNumber].accounts[msg.sender]) {
            mintingVotes[_amount][mintingNumber].accounts[msg.sender] = true;
            mintingVotes[_amount][mintingNumber].count++;

            if (mintingVotes[_amount][mintingNumber].count == 2) {
                mintingNumber++;
                bytes memory mintCall = abi.encodeWithSignature("mint(uint256)", _amount);
                (bool _success, bytes memory _returnData) = tokenContract.call(mintCall);
                require(_success, "TokenContract::mint call has failed.");
            }
        }
    }

    function setTokenContract(address _address) external onlyAdmin {
        tokenContract = _address;
    }
}
