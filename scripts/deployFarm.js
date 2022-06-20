const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

// Contract to deploy
const contractToDeploy = "Farm";

async function main() {
  // Get provider
  const provider = ethers.provider;

  // Get provider for testnet
  // const accessPoint_URL = process.env.GANACHE_ACCESSPOINT_URL;
  // const provider = new ethers.providers.JsonRpcProvider(accessPoint_URL);

  // Get signer
  const [signer, tokenContract] = await ethers.getSigners();

  // Get Contracts to deploy
  const contractPath =
    "contracts/" + contractToDeploy + ".sol:" + contractToDeploy;
  const contractFactory = await ethers.getContractFactory(contractPath, signer);
  const deployedContract = await contractFactory.deploy(tokenContract.address);

  // Check transaction result. 1 it is the number of transction to wait
  tx_hash = deployedContract.deployTransaction.hash;
  const confirmations_number = 1;
  tx_result = await provider.waitForTransaction(tx_hash, confirmations_number);
  if (tx_result.confirmations < 0 || tx_result === undefined) {
    throw new Error(
      contractToDeploy ||
        " Contract ERROR: Deploy transaction is undefined or has 0 confirmations."
    );
  }

  // Get contract read only instance
  const contractABIPath =
    path.resolve(process.cwd(), "artifacts/contracts/", contractToDeploy) +
    ".sol/" +
    contractToDeploy +
    ".json";
  const contractArtifact = JSON.parse(fs.readFileSync(contractABIPath, "utf8"));
  const deployedContractInstance = new ethers.Contract(
    deployedContract.address,
    contractArtifact.abi,
    provider
  );
  const signerBalance = ethers.utils.formatEther(await signer.getBalance());

  // Check getVersion function
  const contractVersion = await deployedContractInstance.VERSION();
  if (contractVersion != 100) {
    throw new Error(
      `-- ${contractToDeploy} contract ERROR: Version check fail.`
    );
  } else {
    console.log("");
    console.log(
      "---------------------------------------------------------------------------------------"
    );
    console.log("-- Deployed contract:\t", contractToDeploy);
    console.log(
      "---------------------------------------------------------------------------------------"
    );
    console.log("-- Contract address:\t", deployedContractInstance.address);
    console.log("-- Contract version:\t", parseInt(contractVersion));
    console.log(
      "---------------------------------------------------------------------------------------"
    );
    console.log("-- Signer address:\t", signer.address);
    console.log("-- Signer balance:\t", signerBalance);
    console.log(
      "---------------------------------------------------------------------------------------"
    );
    console.log("-- Deploy successfully");
    console.log(
      "---------------------------------------------------------------------------------------"
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
