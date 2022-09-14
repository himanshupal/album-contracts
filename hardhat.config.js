require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("hardhat-tracer");

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
};

module.exports = config;
