//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;

    mapping(address => bool) public admins;
    uint256 public adminsCount = 1;
    uint256 private adminsNeededForMultiSignature;

    uint256 public sellPrice;
    uint256 public buyPrice;

    struct WithdrawRequest {
        mapping(address => bool) hasRequested; // address => hasRequested the withdraw
        uint256 count; // number of withdraw requests for this amount and withdraw number
    }

    mapping(uint256 => mapping(uint256 => WithdrawRequest)) private _withdrawRequests; // account => (address => (withdraw number => has requested)
    mapping(address => uint256) private adminsThatHaveWithdrawn;
    uint256 private adminsThatHaveWithdrawnCount = 0; // number of admins that have withdrawn
    uint256 private ethersToBeWithdrawn = 0; // amount of ethers to be withdrawn by all admins in total
    uint256 private activeWithdraw = 1; // active withdraw number
    
    uint256 private maxPercentageToWithdraw; // max percentage of ethers to be requested in a withdraw request


    constructor(uint256 _adminsNeededForMultiSignature, uint256 _sellPrice, uint256 _buyPrice, uint256 _maxPercentageToWithdraw) {
        admins[msg.sender] = true;
        adminsNeededForMultiSignature = _adminsNeededForMultiSignature;
        sellPrice = _sellPrice;
        buyPrice = _buyPrice;
        maxPercentageToWithdraw = _maxPercentageToWithdraw;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "The sender address is not an admin.");
        _;
    }

    modifier notLastAdmin() {
        require(adminsCount > 1, "The last admin cannot be removed.");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin returns (bool) {
        admins[_newAdmin] = true;
        // if there is an active withdraw, then we need to update the admins that have withdrawn
        if (adminsThatHaveWithdrawnCount != adminsCount) {
            adminsThatHaveWithdrawn[_newAdmin] = activeWithdraw;
            adminsThatHaveWithdrawnCount++;
        }
        adminsCount++;
        return true;
    }

    function removeAdmin(address _admin) external onlyAdmin notLastAdmin returns (bool) {
        require(admins[_admin], "The address to remove is not an admin.");

        delete admins[_admin];
        // if the admin has not withdrawn, then we need to update the ethers to be withdrawn,
        if (adminsThatHaveWithdrawnCount != adminsCount && adminsThatHaveWithdrawn[msg.sender] != activeWithdraw) {
            ethersToBeWithdrawn -= ethersToBeWithdrawn / (adminsCount - adminsThatHaveWithdrawnCount);
        } else { // if the admin has already withdrawn, then we need to update the admins that have withdrawn count
            adminsThatHaveWithdrawnCount--;
        }
        adminsCount--;
        return true;
    }

    modifier numberValid(uint256 _number) {
        require(_number > 0, "The number must be greater than 0.");
        require(_number < 2**256 - 1, "The number must be less than 2**256 - 1.");
        _;
    }

    function setSellPrice(uint256 _price) external onlyAdmin numberValid(_price) {
        require(_price > buyPrice, "The sell price must be greater than the buy price.");
        sellPrice = _price;
    }

    function setBuyPrice(uint256 _price) external onlyAdmin numberValid(_price) {
        require(_price < sellPrice, "The buy price must be less than the sell price.");
        buyPrice = _price;
    }

    function setMaxPercentage(uint8 _maxPercentage) external onlyAdmin {
        require(_maxPercentage > 0, "The maximum percentage must be greater than 0.");
        require(_maxPercentage <= 50, "The maximum percentage must be less or equal than 50.");
        maxPercentageToWithdraw = _maxPercentage;
    }

    function requestWithdraw(uint256 _amount) external onlyAdmin {
        require(adminsThatHaveWithdrawnCount == adminsCount, "You can't start two simultaneous withdraw operations.");
        require(_amount < ((maxPercentageToWithdraw / 100) * address(this).balance), "You can't exceed the maximum to withdraw.");
        require(!_withdrawRequests[_amount][activeWithdraw].hasRequested[msg.sender], "You have already requested this withdraw.");

        _withdrawRequests[_amount][activeWithdraw].hasRequested[msg.sender] = true;
        _withdrawRequests[_amount][activeWithdraw].count += 1;

        if (_withdrawRequests[_amount][activeWithdraw].count == adminsNeededForMultiSignature) {
            adminsThatHaveWithdrawnCount = 0;
            ethersToBeWithdrawn = _amount;
            activeWithdraw += 1;
        }
    }

    function withdraw() external payable onlyAdmin { 
        require(adminsThatHaveWithdrawnCount != adminsCount, "There is nothing to withdraw.");
        require(adminsThatHaveWithdrawn[msg.sender] != activeWithdraw, "You have already withdrawn.");

        payable(msg.sender).transfer(ethersToBeWithdrawn / (adminsCount - adminsThatHaveWithdrawnCount));
        adminsThatHaveWithdrawnCount++;
        adminsThatHaveWithdrawn[msg.sender] = activeWithdraw;
    }
}
