const { string } = require("hardhat/internal/core/params/argumentTypes");
const { parseEther } = require("ethers/lib/utils");
const { task } = require("hardhat/config");

require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-tracer");
require("dotenv/config");

/**
 * @type {import("hardhat/config").HardhatUserConfig}
 */
const config = {
  defaultNetwork: "localhost",
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  networks: {
    localhost: {
      chainId: 31337,
      url: `http://localhost:8545`,
      accounts: ["0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"],
    },
    goerli: {
      chainId: 5,
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.DEPLOYER],
    },
    mumbai: {
      chainId: 80001,
      url: `https://rpc-mumbai.maticvigil.com`,
      accounts: [process.env.DEPLOYER],
    },
  },
};

module.exports = config;
