import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("hardhat-ethernal");
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    // hardhat: {
    //   mining: {
    //     auto: false,
    //     interval: 2000,
    //   },
    // },
  },
};

export default config;
