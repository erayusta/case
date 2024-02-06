// Import the necessary libraries
import { ethers } from "hardhat";

// Define the main function
async function main() {
  // Deploy the Era contract
  const Era = await ethers.getContractFactory("Era");
  const era = await Era.deploy(); // Add constructor arguments if any
  console.log(`Era deployed to: ${era.target}`);



  // Deploy the RewardDistributor contract
  const RewardDistributor = await ethers.getContractFactory("RewardDistributor");
  const rewardDistributor = await RewardDistributor.deploy(era.target, 387, 2592000); // Set rewardFactor to 0.387 and periodLength to 2592000
  
  console.log("RewardDistributor contract deployed at:", rewardDistributor.target);

}

// Catch and log errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
