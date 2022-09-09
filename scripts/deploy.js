const { ethers } = require("hardhat");

const deploy = async function () {
  const MarketPlace = await ethers.getContractFactory("MarketPlace");
  const marketPlace = await MarketPlace.deploy("Marketplace", "MMKT");
  console.log(`Deployed to`, marketPlace.address);
};

try {
  deploy();
} catch (err) {
  console.error(err);
}
