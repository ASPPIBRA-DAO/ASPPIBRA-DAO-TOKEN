const { expect } = require("chai");

describe("Presale contract", function () {
  it("Deployment should succeed", async function () {
    const Presale = await ethers.getContractFactory("Presale");
    const presale = await Presale.deploy();
    expect(presale.address).to.not.be.undefined;
  });
});
