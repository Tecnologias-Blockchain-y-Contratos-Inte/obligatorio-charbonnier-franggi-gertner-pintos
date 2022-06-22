const { expect, use } = require("chai");
const { waffle } = require("hardhat");
const { deployContract, provider, solidity } = waffle;
const TokenContract = require("../artifacts/contracts/TokenContract.sol/TokenContract.json");

let tokenContract;
const [wallet, walletTo, thirdWallet] = provider.getWallets();
let name = "Token";
let symbol = "Symbol";

describe("TokenContract", () => {
  beforeEach(async () => {
    tokenContract = await deployContract(wallet, TokenContract, [name, symbol]);
  });

  describe("Constructor", () => {
    it("should deploy the contract with name", async () => {
      expect(await tokenContract.name()).to.equal(name);
    });

    it("should deploy the contract with symbol", async () => {
      expect(await tokenContract.symbol()).to.equal(symbol);
    });

    it("should deploy the contract with owner", async () => {
      expect(await tokenContract.owner()).to.equal(wallet.address);
    });
  });

  describe("Decimals", () => {
    it("should return the number of decimals", async () => {
      expect(await tokenContract.decimals()).to.equal(18);
    });
  });

  describe("Set Vault", () => {
    it("should set Vault", async () => {
      await tokenContract.setVault(walletTo.address);

      expect(await tokenContract.vault()).to.equal(walletTo.address);
    });

    it("should not set Vault", async () => {
      const tokenContractNotAdmin = tokenContract.connect(walletTo.address);

      await expect(tokenContractNotAdmin.setVault(walletTo.address)).to.be
        .reverted;
    });
  });

  describe("Mint", () => {
    it("should mint tokens", async () => {
      await tokenContract.setVault(walletTo.address);
      const tokenContractFromVault = tokenContract.connect(walletTo);
      const amount = 10;
      await tokenContractFromVault.mint(amount);

      expect(await tokenContract.balanceOf(walletTo.address)).to.equal(amount);
    });

    it("should not mint tokens", async () => {
      await tokenContract.setVault(walletTo.address);
      const amount = 10;

      await expect(tokenContract.mint(amount)).to.be.reverted;
    });
  });

  describe("Transfer", () => {
    it("should transfer tokens", async () => {
      await tokenContract.setVault(walletTo.address);
      const tokenContractFromVault = tokenContract.connect(walletTo);
      const amount = 10;
      await tokenContractFromVault.mint(amount);
      await tokenContractFromVault.transfer(walletTo.address, amount);

      expect(await tokenContract.balanceOf(walletTo.address)).to.equal(amount);
    });

    it("should not transfer tokens", async () => {
      await tokenContract.setVault(walletTo.address);
      const tokenContractFromVault = tokenContract.connect(walletTo);
      const amount = 10;
      await tokenContractFromVault.mint(amount);

      await expect(
        tokenContractFromVault.transfer(walletTo.address, amount + 1)
      ).to.be.reverted;
    });
  });

  describe("Approve", () => {
    it("should approve tokens to another address", async () => {
      await tokenContract.setVault(walletTo.address);
      const tokenContractFromVault = tokenContract.connect(walletTo);
      const amount = 10;
      await tokenContractFromVault.mint(amount);
      await tokenContractFromVault.approve(wallet.address, amount);

      expect(
        await tokenContract.allowance(walletTo.address, wallet.address)
      ).to.equal(amount);
    });
  });

  describe("TransferFrom", () => {
    it("should transfer tokens from allowed account", async () => {
      await tokenContract.setVault(walletTo.address);
      const tokenContractFromVault = tokenContract.connect(walletTo);
      const amount = 10;
      await tokenContractFromVault.mint(amount);
      await tokenContractFromVault.approve(thirdWallet.address, amount);
      const tokenContractFromThird = tokenContract.connect(thirdWallet);
      await tokenContractFromThird.transferFrom(
        walletTo.address,
        wallet.address,
        amount
      );

      expect(await tokenContract.balanceOf(wallet.address)).to.equal(amount);
    });

    it("should not transfer tokens from not allowed account", async () => {
      await tokenContract.setVault(walletTo.address);
      const tokenContractFromVault = tokenContract.connect(walletTo);
      const amount = 10;
      await tokenContractFromVault.mint(amount);
      const tokenContractFromThird = tokenContract.connect(thirdWallet);

      await expect(
        tokenContractFromThird.transferFrom(
          walletTo.address,
          wallet.address,
          amount
        )
      ).to.be.reverted;
    });
  });
});
