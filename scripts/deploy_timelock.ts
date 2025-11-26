import { ethers } from "hardhat";
import fs from "fs";

async function main() {
  const [deployer] = await ethers.getSigners();
  const minDelay = 2 * 24 * 60 * 60; // 2 days

  const Timelock = await ethers.getContractFactory("Timelock");
  const timelock = await Timelock.deploy(minDelay, [], [], deployer.address);

  await timelock.deployed();

  const deploymentAddresses = JSON.parse(
    fs.readFileSync("deployment-addresses.json", "utf8")
  );

  deploymentAddresses.timelock = timelock.address;

  fs.writeFileSync(
    "deployment-addresses.json",
    JSON.stringify(deploymentAddresses)
  );

  console.log("Timelock deployed at:", timelock.address);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});