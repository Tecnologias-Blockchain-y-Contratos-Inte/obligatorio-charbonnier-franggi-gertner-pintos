//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;
    mapping(address => bool) public admins;
    uint256 public sellPrice;
    uint256 public buyPrice;

  struct WithdrawVote {
        uint256 count;
        mapping(address => bool) accounts;
    }

    mapping(uint256 => mapping(uint256 => WithdrawVote)) private withdrawVotes;
    uint256 public adminsThatHaveWithdrawnCount = 1;
    mapping(uint256=> mapping(address => bool)) public adminsThatHaveWithdrawn;
    uint256 public ethersToBeWithdrawn  = 0;
    uint256 withdrawId = 1;
    uint256 public adminCount = 1;
    uint256 private adminsNeededForMultiSignature = 2;
    uint256 public maxPercentageToWithdraw = 50; // max percentage of ethers to be requested in a withdraw request


   constructor(
        uint256 _adminsNeededForMultiSignature,
        uint256 _sellPrice,
        uint256 _buyPrice,
        uint256 _maxPercentageToWithdraw
    ) payable {
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
        require(adminCount > 1, "The last admin cannot be removed.");
        _;
    }

    function addAdmin(address _newAdmin) external onlyAdmin returns (bool) {
        admins[_newAdmin] = true;
        adminCount++;        
        adminsThatHaveWithdrawn[withdrawId][_newAdmin] = false;
        adminsThatHaveWithdrawnCount++;      
        return true;
    }

   function removeAdmin(address _admin) external onlyAdmin notLastAdmin returns (bool)    {
        require(admins[_admin], "The address to remove is not an admin.");
        delete admins[_admin];
        adminCount--;
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

    function setMaxPercentage(uint256 _maxPercentage) external onlyAdmin {
        require(_maxPercentage > 0, "The maximum percentage must be greater than 0.");
        require(_maxPercentage <= 50, "The maximum percentage must be less or equal than 50.");
        maxPercentageToWithdraw = _maxPercentage;
    }

   function requestWithdraw(uint256 _amount) external onlyAdmin {
        require(
            adminsThatHaveWithdrawnCount == adminCount,
            "You can't start two simultaneous withdraw operations."
        );
        require(
            _amount < ((maxPercentageToWithdraw * address(this).balance) / 100),
            "You can't exceed the maximum to withdraw."
        );
        require(
            !withdrawVotes[withdrawId][_amount].accounts[msg.sender],
            "You have already requested this withdraw."
        );

        if (withdrawVotes[withdrawId][_amount].count == 0) {
            WithdrawVote storage newVote = withdrawVotes[withdrawId][_amount];
            newVote.accounts[msg.sender] = true;
            newVote.count = 1;
        } else if (!withdrawVotes[withdrawId][_amount].accounts[msg.sender]) {
            withdrawVotes[withdrawId][_amount].accounts[msg.sender] = true;
            withdrawVotes[withdrawId][_amount].count += 1;
            if (
                withdrawVotes[withdrawId][_amount].count ==
                adminsNeededForMultiSignature
            ) {
                adminsThatHaveWithdrawnCount = 0;
                withdrawId++;                
                uint256 floatCorrection = _amount / adminCount;          
                ethersToBeWithdrawn = floatCorrection * adminCount;
           }
        }
    }

    function withdraw() external payable onlyAdmin {
        require(adminsThatHaveWithdrawnCount != adminCount, "There is nothing to withdraw."); // Everyone has withdrawn
        require(adminsThatHaveWithdrawn[withdrawId][msg.sender] != true, "You have already withdrawn.");
        uint256 transferEthers = ethersToBeWithdrawn / adminCount;
        payable(msg.sender).transfer(transferEthers);
        adminsThatHaveWithdrawnCount++;        
        adminsThatHaveWithdrawn[withdrawId][msg.sender] = true;
    }

    receive() external payable {}
}
