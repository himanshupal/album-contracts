const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Marketplace", function () {
  let alex, bob, carl;
  let contract;

  this.beforeEach(async function () {
    [alex, bob, carl] = await ethers.getSigners();
    const factory = await ethers.getContractFactory("Marketplace");
    contract = await factory.deploy("Marketplace", "MMKT");
  });

  it("reads", async function () {
    expect(await contract.name()).eq("Marketplace");
    expect(await contract.symbol()).eq("MMKT");
  });

  it("mints", async function () {
    expect(await contract.mint(bob.address, "123456")).to.not.throw;
    expect(await contract.mint(bob.address, "1234153")).to.not.throw;
    expect((await contract.totalSupply()).eq(2)).to.be.true;
    expect((await contract.tokenId("123456")).eq(1)).to.be.true;
    expect(await contract.tokenURI(1)).to.eq("123456");
    expect(await contract.ownerOf(1)).to.eq(bob.address);
    const userTokens = await contract.userTokens(bob.address);
    userTokens.forEach((token, index) => expect(token.toNumber()).to.eq(index + 1));
    await expect(contract.mint(carl.address, "123456")).to.throw;
  });

  it("burns", async function () {
    await expect(contract.mint(carl.address, "123457")).to.not.throw;
    await expect(contract.mint(carl.address, "1534")).to.not.throw;
    expect(await contract.ownerOf(1)).eq(carl.address);
    expect((await contract.totalSupply()).eq(2)).to.be.true;
    let userTokens = await contract.userTokens(carl.address);
    userTokens.forEach((token, index) => expect(token.toNumber()).to.eq(index + 1));
    await expect(contract["burn(uint256)"](2)).to.not.throw;
    expect((await contract.totalSupply()).eq(1)).to.be.true;
    await expect(contract.ownerOf(2)).to.throw;
    await expect(contract.tokenURI(2)).to.throw;
    userTokens = await contract.userTokens(carl.address);
    userTokens[0].eq(1);
  });

  it("transfers", async function () {
    await contract.mint(alex.address, "123458");
    const tokenId = await contract.tokenId("123458");
    expect(await contract.ownerOf(tokenId)).to.eq(alex.address);
    expect((await contract.userTokens(alex.address)).length).to.eq(1);
    await expect(contract.connect(bob).transferFrom(alex.address, bob.address, tokenId)).to.throw;
    await contract.transferFrom(alex.address, bob.address, tokenId);
    expect(await contract.ownerOf(tokenId)).to.eq(bob.address);
    expect((await contract.userTokens(alex.address)).length).to.eq(0);
    // with approval
    expect(await contract.connect(bob).approve(alex.address, tokenId)).to.not.throw;
    await contract.transferFrom(bob.address, alex.address, tokenId);
    expect((await contract.userTokens(alex.address)).length).to.eq(1);
    expect((await contract.userTokens(bob.address)).length).to.eq(0);
  });
});
