const { expect } = require("chai");

describe("DAO contract", function () {
  it("Deployment should succeed", async function () {
    const DAO = await ethers.getContractFactory("DAO");
    const dao = await DAO.deploy();
    expect(dao.address).to.not.be.undefined;
  });
});
