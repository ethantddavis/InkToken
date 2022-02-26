const hre = require("hardhat");

async function main() {

  const InkToken = await hre.ethers.getContractFactory("InkToken");
  const kovanNftAddress = " ";
  const inkToken = await RentToken.deploy(kovanNftAddress);

  await inkToken.deployed();

  console.log(inkToken.address);

}



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });