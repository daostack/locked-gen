const LGN = artifacts.require("./LockedGEN.sol");

const GEN_ADDRESS = "0x543Ff227F64Aa17eA132Bf9886cAb5DB55DCAddf";
const LOCK_TIME = 60*60*24*365*2; // 2 Years

module.exports = function(deployer) {
  deployer.deploy(LGN, GEN_ADDRESS, LOCK_TIME);
};
