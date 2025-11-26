import { ethers } from "hardhat";

async function main() {
  const Proxy = await ethers.getContractFactory("Proxy");
  const proxy = await Proxy.deploy();

  await proxy.deployed();

  console.log("Proxy deployed to:", proxy.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});