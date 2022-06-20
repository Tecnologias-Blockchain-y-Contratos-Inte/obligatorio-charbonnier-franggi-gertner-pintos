const { expect, use } = require("chai");
const { waffle } = require("hardhat");
const { deployContract, provider, solidity } = waffle;
const Farm = require("../artifacts/contracts/Farm.sol/Farm.json");

let farm;
const [wallet, walletTo, tokenWallet] = provider.getWallets();

describe("Farm", () => {
  beforeEach(async () => {
    farm = await deployContract(wallet, Farm, [tokenWallet.address]);
  });

  describe("Constructor", () => {
    it("should deploy the contract and set the token contract", async () => {
      expect(await farm.tokenContract).to.equal(tokenWallet.address);
    });
  });

  // TODO: add tests for all functions
});
