import { ethers, upgrades } from "hardhat";
import fs from "fs";

async function main() {
  const [deployer] = await ethers.getSigners();

  const Token = await ethers.getContractFactory("GovernanceToken");
  const token = await upgrades.deployProxy(Token, [deployer.address, deployer.address], { initializer: 'initialize' });

  await token.deployed();

  const deploymentAddresses = {
    token: token.address,
  };

  fs.writeFileSync(
    "deployment-addresses.json",
    JSON.stringify(deploymentAddresses)
  );

  console.log("Token deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});