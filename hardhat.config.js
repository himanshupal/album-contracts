require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-tracer");
require("dotenv/config");

/**
 * @type {import("hardhat/config").HardhatUserConfig}
 */
const config = {
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
    goerli: {
      chainId: 5,
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.DEPLOYER],
    },
  },
};

module.exports = config;
