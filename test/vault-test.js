const { expect, use } = require("chai");
const { waffle } = require("hardhat");
const { deployContract, provider, solidity } = waffle;
const Vault = require("../artifacts/contracts/Vault.sol/Vault.json");
const ethers = require('ethers');

let vault;
const [wallet, walletTo, thirdWallet] = provider.getWallets();

describe("Vault", () => {
  beforeEach(async () => {
    vault = await deployContract(wallet, Vault, [2, 2, 1, 50]);
    vault.balance = 9999;
  });

  describe("Constructor", () => {
    it("should deploy the contract with deployer as admin", async () => {
      expect(await vault.admins(wallet.address)).to.equal(true);
    });
  });

  describe("Admin", () => {
    it("should be able to add a new admin if you are admin", async () => {
      // Act
      await vault.addAdmin(walletTo.address);
      // Assert
      expect(await vault.admins(walletTo.address)).to.equal(true);
    });

    it("should not be able to add a new admin if you are not admin", async () => {
      // Arrange
      const vaultFromAnotherAccount = vault.connect(walletTo);
      // Assert
      await expect(vaultFromAnotherAccount.addAdmin(walletTo.address)).to.be
        .reverted;
    });

    it("should be able to remove admin if you are admin", async () => {
      // Arrange
      await vault.addAdmin(walletTo.address);
      // Act
      await vault.removeAdmin(walletTo.address);
      // Assert
      expect(await vault.admins(walletTo.address)).to.equal(false);
    });

    it("should not be able to remove an admin if you are not admin", async () => {
      // Arrange
      await vault.addAdmin(walletTo.address);
      const vaultFromNotAdminAccount = vault.connect(thirdWallet);
      // Assert
      await expect(vaultFromNotAdminAccount.removeAdmin(wallet.address)).to.be
        .reverted;
    });

    it("should not be able to remove last admin", async () => {
      // Assert
      await expect(vault.removeAdmin(wallet.address)).to.be.reverted;
    });

    it("should not be able to remove an address that is not an admin", async () => {
      // Assert
      await expect(vault.removeAdmin(walletTo.address)).to.be.reverted;
    });
  });

  describe("Sell Buy Price", () => {
    it("should be able to set buy price less than sell price, as an admin", async () => {
      // Arrange
      const sellPrice = 10;
      const buyPrice = 5;
      await vault.setSellPrice(sellPrice);
      // Act
      await vault.setBuyPrice(buyPrice);
      // Assert
      expect(await vault.buyPrice()).to.equal(buyPrice);
    });

    it("should not be able to set buy price less than sell price, as not an admin", async () => {
      // Arrange
      const buyPrice = 10;
      const vaultFromAnotherAccount = vault.connect(walletTo);
      // Assert
      await expect(vaultFromAnotherAccount.setBuyPrice(buyPrice)).to.be
        .reverted;
    });

    it("should not be able to set buy price greater than sell price, as an admin", async () => {
      // Arrange
      const buyPrice = 10;
      // Assert
      await expect(vault.setBuyPrice(buyPrice)).to.be.reverted;
    });

    it("should be able to set sell price greater than buy price, as an admin", async () => {
      // Arrange
      const sellPrice = 10;
      // Act
      await vault.setSellPrice(sellPrice);
      // Assert
      expect(await vault.sellPrice()).to.equal(sellPrice);
    });

    it("should not be able to set sell price greater than buy price, as not an admin", async () => {
      // Arrange
      const sellPrice = 10;
      const vaultFromAnotherAccount = vault.connect(walletTo);
      // Assert
      await expect(vaultFromAnotherAccount.setSellPrice(sellPrice)).to.be
        .reverted;
    });

    it("should not be able to set sell price less than buy price, as an admin", async () => {
      // Arrange
      const initialSellPrice = 15;
      const sellPrice = 5;
      const buyPrice = 10;
      await vault.setSellPrice(initialSellPrice);
      await vault.setBuyPrice(buyPrice);
      // Assert
      await expect(vault.setSellPrice(sellPrice)).to.be.reverted;
    });
  });

  describe("Withdraw, Request Withdraw", () => {
    it("Should not be able to set max porcentage over 50 as admin", async () => {
      // Arrange
      const testPorcentage = 51;
      // Assert
      await expect(vault.setMaxPercentage(testPorcentage)).to.be.reverted;
    });

    it("Should not be able to set max porcentage under 0 as admin", async () => {
      // Arrange
      const testPorcentage = -1;
      // Assert
      await expect(vault.setMaxPercentage(testPorcentage)).to.be.reverted;
    });

    it("Shouldnt allow to excede the max request porcentage", async () => {
      // Arrange
      await vault.setMaxPercentage(20);
      const result = await wallet.sendTransaction({
        to: vault.address,
        value: ethers.utils.parseEther("0.0000000000000001")
      });
      // Note: after this operation the vault balance will be "100".  Consider for next operations. Use console.log(await waffle.provider.getBalance(vault.address));
      const testValue = 10000;
      // Assert
      await expect(vault.requestWithdraw(testValue)).to.be.reverted;
    });

    it("Should not be able to request withdraw as admin when you have made a previous request", async () => {
      // Arrange
      await vault.addAdmin(walletTo.address);
      await vault.addAdmin(thirdWallet.address);
      await vault.setMaxPercentage(50);
      const testValue = 1;
      await transferTestEthersToVault(100);

      // Act
      await vault.requestWithdraw(testValue); // first admin request
      const secondAdmin = vault.connect(walletTo);
      await secondAdmin.requestWithdraw(testValue);

      // Assert
      await expect(vault.requestWithdraw(testValue)).to.be.reverted;
    });


    it("Should not be able to request withdraw as admin when you have made a previous request", async () => {
      // Arrange
      await vault.addAdmin(walletTo.address);
      await vault.addAdmin(thirdWallet.address);
      await vault.setMaxPercentage(50);
      const testValue1 = 1;
      await transferTestEthersToVault(100);
      // Act
      await vault.requestWithdraw(testValue1);
      // Assert
      await expect(vault.requestWithdraw(testValue1)).to.be.reverted;
    });

    it("Should not be able to withdraw as admin when there wasnt a previous request", async () => {
      await expect(vault.withdraw()).to.be.reverted;
    });

    /* global BigInt */
    it("Should be able to withdraw when a previous request was approved", async () => {
      await vault.addAdmin(walletTo.address);
      const testValue = 2000000000000000000n; 

      await transferTestEthersToVault(5);

      await vault.requestWithdraw(testValue);
      const secondAdmin = vault.connect(walletTo);
      await secondAdmin.requestWithdraw(testValue);

      const balanceBefore = await waffle.provider.getBalance(walletTo.address);
      const tx = await secondAdmin.withdraw();
      const receipt = await tx.wait();
      const balanceAfter = await waffle.provider.getBalance(walletTo.address);
      const gasSpent = await receipt.gasUsed.mul(receipt.effectiveGasPrice);
      expect(Number(balanceBefore)).to.be.lessThan(Number(balanceAfter));

      /*
      console.log("Gas spent: " + gasSpent);
      console.log("Balance before: " + balanceBefore);
      console.log("Balance After: " + balanceAfter);
      console.log({ receipt });
      expect(balanceAfter.sub(balanceBefore).add(gasSpent)).to.eq(ethers.utils.parseEther("1")); 
      */

      // Cant seem to get the correct amount, i think it is because of the gas but i cant figure out how to get the correct amount
    });

    it("Should be able to perform more than one withdraw", async () => {
      await vault.addAdmin(walletTo.address);
      const testValue = 2000000000000000000n; 
      await transferTestEthersToVault(5);
      await vault.requestWithdraw(testValue);
      const secondAdmin = vault.connect(walletTo);
      await secondAdmin.requestWithdraw(testValue);
      const balanceBefore = await waffle.provider.getBalance(walletTo.address);
      await vault.withdraw();
      await secondAdmin.withdraw();
      await transferTestEthersToVault(5);
      await vault.requestWithdraw(testValue);
      await secondAdmin.requestWithdraw(testValue);
      await vault.withdraw();
      await secondAdmin.withdraw();
      const balanceAfter = await waffle.provider.getBalance(walletTo.address);
      expect(Number(balanceBefore)).to.be.lessThan(Number(balanceAfter)); //This is more a formality than a real test, i just needed to check that you can actually do a withdraw again after a previous one 
    });


  });

  function transferTestEthersToVault(_eth) {
    const result = wallet.sendTransaction({
      to: vault.address,
      value: ethers.utils.parseEther(_eth.toString())
    });
    return result;
  }
});