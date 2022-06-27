const { expect, use } = require("chai");
const { deployMockContract } = require("ethereum-waffle");
const { waffle } = require("hardhat");
const { deployContract, provider, solidity } = waffle;
const Vault = require("../artifacts/contracts/Vault.sol/Vault.json");
const TokenContract = require("../artifacts/contracts/TokenContract.sol/TokenContract.json");
const { ethers } = require("ethers");

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
      const sellPrice = ethers.utils.parseEther("3");
      const buyPrice = ethers.utils.parseEther("2");
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
      const buyPrice = ethers.utils.parseEther("4");
      // Assert
      await expect(vault.setBuyPrice(buyPrice)).to.be.reverted;
    });

    it("should be able to set sell price greater than buy price, as an admin", async () => {
      // Arrange
      const sellPrice = ethers.utils.parseEther("4");
      // Act
      await vault.setSellPrice(sellPrice);
      // Assert
      expect(await vault.sellPrice()).to.equal(sellPrice);
    });

    it("should not be able to set sell price greater than buy price, as not an admin", async () => {
      // Arrange
      const sellPrice = ethers.utils.parseEther("3");
      const vaultFromAnotherAccount = vault.connect(walletTo);
      // Assert
      await expect(vaultFromAnotherAccount.setSellPrice(sellPrice)).to.be
        .reverted;
    });

    it("should not be able to set sell price less than buy price, as an admin", async () => {
      // Arrange
      const initialSellPrice = ethers.utils.parseEther("4");
      const sellPrice = 5;
      const buyPrice = 10;
      await vault.setSellPrice(initialSellPrice);
      await vault.setBuyPrice(buyPrice);
      // Assert
      await expect(vault.setSellPrice(sellPrice)).to.be.reverted;
    });
  });

  describe("Mint", () => {
    it("should be able to vote to mint as admin", async () => {
      const amount = 20;
      await vault.mint(amount);
      expect(await vault.getVote(amount)).to.equal(true);
    });

    it("should not be able to vote as not admin", async () => {
      const amount = 20;
      const vaultFromAnotherAccount = vault.connect(walletTo);
      await expect(vaultFromAnotherAccount.mint(amount)).to.be.reverted;
    });

    it("should be able to mint when multi-firm is complete", async () => {
      const amount = 20;
      const mintingNumber = ethers.BigNumber.from(
        await vault.mintingNumber()
      ).toNumber();
      await vault.mint(amount);
      await vault.addAdmin(walletTo.address);
      const tokenContract = await deployMockContract(wallet, TokenContract.abi);
      await tokenContract.mock.mint.withArgs(amount).returns(true);
      const vaultFromAnotherAccount = vault.connect(walletTo);
      await vaultFromAnotherAccount.mint(amount);
      const newMintingNumber = ethers.BigNumber.from(
        await vault.mintingNumber()
      ).toNumber();

      expect(newMintingNumber).to.equal(mintingNumber + 1);
    });
  });

  describe("Burn", () => {
    it("should be able to burn", async () => {
      await walletTo.sendTransaction({
        to: vault.address,
        value: ethers.utils.parseEther("2"),
      });

      const amount = 2;
      const tokenContract = await deployMockContract(wallet, TokenContract.abi);
      await tokenContract.mock.burn
        .withArgs(amount, wallet.address)
        .returns(true);

      const balanceBefore = await provider.getBalance(wallet.address);
      const tx = await vault.burn(amount);
      const receipt = await tx.wait();
      const gasSpent = receipt.gasUsed.mul(receipt.effectiveGasPrice);
      const balanceAfter = await provider.getBalance(wallet.address);

      expect(balanceAfter.sub(balanceBefore).add(gasSpent)).to.eq(
        ethers.utils.parseEther("1")
      );
    });
  });
});
