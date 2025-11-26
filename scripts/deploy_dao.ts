import { ethers } from "hardhat";
import fs from "fs";

async function main() {
  const [deployer] = await ethers.getSigners();
  const deploymentAddresses = JSON.parse(
    fs.readFileSync("deployment-addresses.json", "utf8")
  );

  const tokenAddress = deploymentAddresses.token;
  const timelockAddress = deploymentAddresses.timelock;

  const DAO = await ethers.getContractFactory("ASPPIBRADAO");
  const Timelock = await ethers.getContractFactory("Timelock");

  const daoImplementation = await DAO.deploy();
  await daoImplementation.deployed();

  const timelock = await Timelock.attach(timelockAddress);

  const PROPOSER_ROLE = await timelock.PROPOSER_ROLE();
  const EXECUTOR_ROLE = await timelock.EXECUTOR_ROLE();
  const ADMIN_ROLE = await timelock.TIMELOCK_ADMIN_ROLE();

  const governor = await ethers.getContractAt("ASPPIBRADAO", deploymentAddresses.dao);

  // Grant roles
  await timelock.grantRole(PROPOSER_ROLE, governor.address);
  await timelock.grantRole(EXECUTOR_ROLE, ethers.constants.AddressZero); // anyone can execute

  // Revoke admin role from deployer
  await timelock.revokeRole(ADMIN_ROLE, deployer.address);

  console.log("DAO Roles configured on Timelock");


  console.log("DAO deployed to:", governor.address);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});