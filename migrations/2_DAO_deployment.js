const DAOCont = artifacts.require("DAO");

const { setEnvValue } = require("../utils/env-man");

const conf = require("../migration-parameters");

const setDAO = (n, v) => {
  setEnvValue("../", `DAO_ADDRESS${n.toUpperCase()}`, v);
};

module.exports = async (deployer, network, accounts) => {
  switch (network) {
    case "rinkeby":
      c = { ...conf.rinkeby };
      break;
    case "mainnet":
      c = { ...conf.mainnet };
      break;
    case "mumbai":
      c = { ...conf.mumbai };
    case "development":
    default:
      c = { ...conf.devnet };
  }

  // deploy Crowdfunding
  await deployer.deploy(DAOCont, c.contractAddess, c.tokenIds);

  const DAO = await DAOCont.deployed();

  if (DAO) {
    console.log(
      `Deployed: DAO
       network: ${network}
       address: ${DAO.address}
       creator: ${accounts[0]}
    `
    );
    setDAO(network, DAO.address);
  } else {
    console.log("DAO Deployment UNSUCCESSFUL");
  }
};
