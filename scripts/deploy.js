const { ethers } = require("hardhat");

const deploy = async function () {
  const Marketplace = await ethers.getContractFactory("Marketplace");
  const marketplace = await Marketplace.deploy("Marketplace", "MMKT");
  console.log({ address: marketplace.address });
};

try {
  deploy();
} catch (err) {
  console.error(err);
}
