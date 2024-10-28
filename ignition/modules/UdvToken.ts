import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0x88Bf80AAFFf16bED6f7DDD6a63F49D651a00479F";

const StakingERC20TokenModule = buildModule("StakingERC20TokenMModule", (m) => {

    const stakeERC = m.contract("StakingERC20Token", [tokenAddress]);

    return { stakeERC };
});

export default StakingERC20TokenModule;