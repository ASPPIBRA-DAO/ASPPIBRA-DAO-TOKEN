import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  const tokenAddress = process.env.SALE_TOKEN ?? ""; // or pass as arg

  if (!tokenAddress) throw new Error("Set SALE_TOKEN env or edit script");

  const Wrapper = await ethers.getContractFactory("ASPPBRGovWrapper");
  const wrapper = await Wrapper.deploy(tokenAddress);
  await wrapper.deployed();

  console.log("Wrapper deployed at:", wrapper.address);
}

main().catch((e)=>{ console.error(e); process.exitCode=1; });