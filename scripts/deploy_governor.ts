import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const wrapperAddress = process.env.WRAPPER ?? "";
  const timelockAddress = process.env.TIMELOCK ?? "";

  if (!wrapperAddress || !timelockAddress) throw new Error("Set WRAPPER and TIMELOCK");

  const Governor = await ethers.getContractFactory("MyGovernor");
  const governor = await Governor.deploy(wrapperAddress, timelockAddress);
  await governor.deployed();

  console.log("Governor deployed at:", governor.address);

  // Grant roles: PROPOSER_ROLE to governor
  const timelock = await ethers.getContractAt("TimelockController", timelockAddress);
  const PROPOSER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("PROPOSER_ROLE"));
  const EXECUTOR_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EXECUTOR_ROLE"));

  // grant proposer to governor
  await timelock.grantRole(PROPOSER_ROLE, governor.address);
  // grant executor to everyone (address(0)) - optional
  await timelock.grantRole(EXECUTOR_ROLE, ethers.constants.AddressZero);

  console.log("Granted roles to governor on timelock");
}

main().catch((e)=>{ console.error(e); process.exitCode=1; });