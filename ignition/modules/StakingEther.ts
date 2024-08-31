import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakingEtherModule = buildModule("StakingEtherModule", (m) => {

    const stake = m.contract("StakingEther");

    return { stake };
});

export default StakingEtherModule;