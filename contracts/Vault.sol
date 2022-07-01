//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract Vault {
    uint256 public constant VERSION = 100;
    uint256 public adminsThatHaveWithdrawnCount = 1;
    uint256 public mintingNumber = 1;
    uint256 public withdrawId = 1;
    uint256 public adminCount = 1;
    uint256 public ethersToBeWithdrawn = 0;
    uint256 public maxPercentageToWithdraw;
    uint256 public sellPrice;
    uint256 public buyPrice;
    address public tokenContract;
    uint256 private adminsNeededForMultiSignature;

    mapping(address => bool) public admins;
    mapping(uint256 => mapping(address => bool)) public adminsThatHaveWithdrawn;
    mapping(uint256 => mapping(uint256 => Votes)) private mintingVotes;
    mapping(uint256 => mapping(uint256 => WithdrawVote)) private withdrawVotes;

    struct Votes {
        uint256 count;
        mapping(address => bool) accounts;
    }

    struct WithdrawVote {
        uint256 count;
        mapping(address => bool) accounts;
    }

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

    modifier numberValid(uint256 _number) {
        require(_number > 0, "The number must be greater than 0.");
        require(
            _number < 2**256 - 1,
            "The number must be less than 2**256 - 1."
        );
        _;
    }

    receive() external payable {}

    function addAdmin(address _newAdmin) external onlyAdmin returns (bool) {
        admins[_newAdmin] = true;
        adminCount++;
        adminsThatHaveWithdrawn[withdrawId][_newAdmin] = false;
        adminsThatHaveWithdrawnCount++;
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

    function setMaxPercentage(uint256 _maxPercentage) external onlyAdmin {
        require(
            _maxPercentage > 0,
            "The maximum percentage must be greater than 0."
        );
        require(
            _maxPercentage <= 50,
            "The maximum percentage must be less or equal than 50."
        );
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
        require(
            adminsThatHaveWithdrawnCount != adminCount,
            "There is nothing to withdraw."
        );
        require(
            adminsThatHaveWithdrawn[withdrawId][msg.sender] != true,
            "You have already withdrawn."
        );
        uint256 transferEthers = ethersToBeWithdrawn / adminCount;
        payable(msg.sender).transfer(transferEthers);
        adminsThatHaveWithdrawnCount++;
        adminsThatHaveWithdrawn[withdrawId][msg.sender] = true;
    }

    function mint(uint256 _amount) external onlyAdmin returns (bool) {
        if (mintingVotes[mintingNumber][_amount].count == 0) {
            Votes storage newVote = mintingVotes[mintingNumber][_amount];
            newVote.accounts[msg.sender] = true;
            newVote.count = 1;
        } else if (!mintingVotes[mintingNumber][_amount].accounts[msg.sender]) {
            mintingVotes[mintingNumber][_amount].accounts[msg.sender] = true;
            mintingVotes[mintingNumber][_amount].count += 1;

            if (mintingVotes[mintingNumber][_amount].count == 2) {
                mintingNumber++;
                bytes memory mintCall = abi.encodeWithSignature(
                    "mint(uint256)",
                    _amount
                );
                (bool _success, ) = tokenContract.call(mintCall);
                require(_success, "TokenContract::mint call has failed.");
            }
        }
        return true;
    }

    function burn(uint256 _amount) external returns (bool) {
        address owner = msg.sender;
        bytes memory burnCall = abi.encodeWithSignature(
            "burn(uint256, address)",
            _amount,
            owner
        );
        (bool _success, ) = tokenContract.call(burnCall);
        require(_success, "TokenContract::burn call has failed.");
        payable(owner).transfer(_amount * (buyPrice / 2));
        return true;
    }

    function getVote(uint256 _amount) external view returns (bool) {
        return mintingVotes[mintingNumber][_amount].accounts[msg.sender];
    }

    function setTokenContract(address _address) external onlyAdmin {
        tokenContract = _address;
    }
}
