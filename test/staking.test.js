const { expect } = require("chai");

describe("Staking contract", function () {
  it("Deployment should succeed", async function () {
    const Staking = await ethers.getContractFactory("Staking");
    const staking = await Staking.deploy();
    expect(staking.address).to.not.be.undefined;
  });
});
