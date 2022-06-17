//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;

    mapping(address => bool) public admins;
    uint256 public adminsCount = 1;
    uint256 private _adminsNeededForMultiSignature;

    uint256 public sellPrice;
    uint256 public buyPrice;

    struct WithdrawRequest {
        mapping(address => bool) hasRequested; // address => hasRequested the withdraw
        uint256 count; // number of withdraw requests for this amount and withdraw number
    }

    mapping(uint256 => mapping(uint256 => WithdrawRequest)) private _withdrawRequests; // account => (address => (withdraw number => has requested)
    mapping(address => uint256) private _adminsThatHaveWithdrawn;
    uint256 private _adminsThatHaveWithdrawnCount = 0; // number of admins that have withdrawn
    uint256 private _ethersToBeWithdrawn = 0; // amount of ethers to be withdrawn by all admins in total
    uint256 private _activeWithdraw = 1; // active withdraw number
    
    uint256 private _maxPercentageToWithdraw; // max percentage of ethers to be requested in a withdraw request


    constructor(uint256 _adminsNeeded, uint256 _sellPrice, uint256 _buyPrice, uint256 _maxPercentage) {
        admins[msg.sender] = true;
        _adminsNeededForMultiSignature = _adminsNeeded;
        sellPrice = _sellPrice;
        buyPrice = _buyPrice;
        _maxPercentageToWithdraw = _maxPercentage;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "The sender address is not an admin.");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin {
        admins[_newAdmin] = true;
        // if there is an active withdraw, then we need to update the admins that have withdrawn
        if (_adminsThatHaveWithdrawnCount != adminsCount) {
            _adminsThatHaveWithdrawn[_newAdmin] = _activeWithdraw;
            _adminsThatHaveWithdrawnCount++;
        }
        adminsCount++;
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(adminsCount > 1, "The last admin cannot be removed.");

        if (admins[_admin]) {
            delete admins[_admin];
            // if the admin has not withdrawn, then we need to update the ethers to be withdrawn,
            if (_adminsThatHaveWithdrawnCount != adminsCount && _adminsThatHaveWithdrawn[msg.sender] != _activeWithdraw) {
                _ethersToBeWithdrawn -= _ethersToBeWithdrawn / (adminsCount - _adminsThatHaveWithdrawnCount);
            // if the admin has already withdrawn, then we need to update the admins that have withdrawn count
            } else {
                _adminsThatHaveWithdrawnCount--;
            }
            adminsCount--;
        }
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
        _maxPercentageToWithdraw = _maxPercentage;
    }

    function requestWithdraw(uint256 _amount) external onlyAdmin {
        require(_adminsThatHaveWithdrawnCount == adminsCount, "You can't start two simultaneous withdraw operations.");
        require(_amount < ((_maxPercentageToWithdraw / 100) * address(this).balance), "You can't exceed the maximum to withdraw.");
        require(!_withdrawRequests[_amount][_activeWithdraw].hasRequested[msg.sender], "You have already requested this withdraw.");

        _withdrawRequests[_amount][_activeWithdraw].hasRequested[msg.sender] = true;
        _withdrawRequests[_amount][_activeWithdraw].count += 1;

        if (_withdrawRequests[_amount][_activeWithdraw].count == _adminsNeededForMultiSignature) {
            _adminsThatHaveWithdrawnCount = 0;
            _ethersToBeWithdrawn = _amount;
            _activeWithdraw += 1;
        }
    }

    function withdraw() external payable onlyAdmin { 
        require(_adminsThatHaveWithdrawnCount != adminsCount, "There is nothing to withdraw.");
        require(_adminsThatHaveWithdrawn[msg.sender] != _activeWithdraw, "You have already withdrawn.");

        payable(msg.sender).transfer(_ethersToBeWithdrawn / (adminsCount - _adminsThatHaveWithdrawnCount));
        _adminsThatHaveWithdrawnCount++;
        _adminsThatHaveWithdrawn[msg.sender] = _activeWithdraw;
    }
}
