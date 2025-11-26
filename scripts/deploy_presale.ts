import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  const saleTokenAddress = process.env.SALE_TOKEN!;
  const paymentTokens = {
    usdt: process.env.USDT!,
    usdc: process.env.USDC!,
    dai: process.env.DAI!
  };

  const Presale = await ethers.getContractFactory("Presale");
  // constructor params depend on your Presale.sol; adapt accordingly
  const presale = await Presale.deploy(saleTokenAddress, [paymentTokens.usdt, paymentTokens.usdc, paymentTokens.dai], /* price, caps etc */);
  await presale.deployed();

  console.log("Presale deployed:", presale.address);
}

main().catch((e)=>{ console.error(e); process.exitCode=1; });