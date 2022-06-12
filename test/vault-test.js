const { expect, use } = require("chai");
const { waffle } = require("hardhat");
const { deployContract, provider, solidity } = waffle;
const Vault = require("../artifacts/contracts/Vault.sol/Vault.json");

let vault;
const [wallet, walletTo, thirdWallet] = provider.getWallets();

describe("Vault", () => {
  beforeEach(async () => {
    vault = await deployContract(wallet, Vault, []);
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
      await expect(vault.removeAdmin(wallet.address)).to.be.reverted;
    });
  });

  describe("Sell Buy Price", () => {
    it("should be able to set buy price grater than sell price, as an admin", async () => {
      // Arrange
      const buyPrice = 10;
      // Act
      await vault.setBuyPrice(buyPrice);
      // Assert
      expect(await vault.buyPrice()).to.equal(buyPrice);
    });

    it("should not be able to set buy price grater than sell price, as not an admin", async () => {
      // Arrange
      const buyPrice = 10;
      const vaultFromAnotherAccount = vault.connect(walletTo);
      // Assert
      await expect(vaultFromAnotherAccount.setBuyPrice(buyPrice)).to.be
        .reverted;
    });

    it("should not be able to set buy price less than sell price, as an admin", async () => {
      // Arrange
      const initialBuyPrice = 15;
      const sellPrice = 10;
      const buyPrice = 5;
      await vault.setBuyPrice(initialBuyPrice);
      await vault.setSellPrice(sellPrice);
      // Assert
      await expect(vault.setBuyPrice(buyPrice)).to.be.reverted;
    });

    it("should be able to set sell price less than buy price, as an admin", async () => {
      // Arrange
      const buyPrice = 10;
      const sellPrice = 5;
      await vault.setBuyPrice(buyPrice);
      // Act
      await vault.setSellPrice(sellPrice);
      // Assert
      expect(await vault.sellPrice()).to.equal(sellPrice);
    });

    it("should not be able to set sell price less than buy price, as not an admin", async () => {
      // Arrange
      const buyPrice = 10;
      const sellPrice = 5;
      await vault.setBuyPrice(buyPrice);
      const vaultFromAnotherAccount = vault.connect(walletTo);
      // Assert
      await expect(vaultFromAnotherAccount.setSellPrice(sellPrice)).to.be
        .reverted;
    });

    it("should not be able to set sell price grater than buy price, as an admin", async () => {
      // Arrange
      const sellPrice = 10;
      const buyPrice = 5;
      await vault.setBuyPrice(buyPrice);
      // Assert
      await expect(vault.setSellPrice(sellPrice)).to.be.reverted;
    });
  });
});
