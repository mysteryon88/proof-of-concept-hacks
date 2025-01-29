import { ethers, TransactionReceipt } from "ethers";
require("dotenv").config();
import safe111AndFactoryConfig from "./safe111AndFactoryConfig.json";
import safe120Config from "./safe120Config.json";

// npx hardhat run scripts\deploy.s.ts

const multisigAddr = "0x4f3a120E72C76c22ae802D129F599BFDbc31cb81";
const deployerAddr = "0x1aa7451DD11b8cb16AC089ED7fE05eFa00100A6A";

const rpcUrl = process.env.RPC_URL!;
const privateKey = process.env.PRIVATE_KEY!;

const provider = new ethers.JsonRpcProvider(rpcUrl);
const funder = new ethers.Wallet(privateKey, provider);

const waitForTx = async (signedTx: string): Promise<TransactionReceipt> => {
  const tx = await provider.broadcastTransaction(signedTx);
  const receipt = await tx.wait();
  if (!receipt) {
    throw new Error("Transaction failed or was not mined.");
  }
  return receipt;
};
const checkCode = async (
  address: string,
  expectedCode: string
): Promise<void> => {
  const code = await provider.getCode(address);
  console.log(
    `Deployment ${code === expectedCode ? "was successful" : "has failed"}`
  );
};

const deploy111AndFactory = async (): Promise<void> => {
  // Переводим токены чтобы отправить транзу
  await sendETH(deployerAddr, "10");
  // Пополняем пустой адрес мультисига
  await sendETH(multisigAddr, "100");

  const nonce = await provider.getTransactionCount(
    safe111AndFactoryConfig.deployer
  );
  if (nonce !== 0) {
    console.warn("Deployment account has been used on this network");
    return;
  }

  const deploymentCosts = BigInt(safe111AndFactoryConfig.deploymentCosts);
  const deploymentAccountBalance = await provider.getBalance(
    safe111AndFactoryConfig.deployer
  );

  if (deploymentAccountBalance < deploymentCosts) {
    const tx = await funder.sendTransaction({
      to: safe111AndFactoryConfig.deployer,
      value: deploymentCosts - deploymentAccountBalance,
    });
    await tx.wait();
  }

  console.log("------ Deploy Safe 1.1.1 ------");
  await waitForTx(safe111AndFactoryConfig.deploymentTx);
  await checkCode(
    safe111AndFactoryConfig.safeAddress,
    safe111AndFactoryConfig.runtimeCode
  );

  console.log("------ Execute Config Tx ------");
  await waitForTx(safe111AndFactoryConfig.configTx);

  console.log("------ Deploy Factory ------");
  await waitForTx(safe111AndFactoryConfig.factoryDeploymentTx);
  await checkCode(
    safe111AndFactoryConfig.factoryAddress,
    safe111AndFactoryConfig.factoryRuntimeCode
  );
};

const deploy120 = async (): Promise<void> => {
  const nonce = await provider.getTransactionCount(safe120Config.deployer);
  if (nonce !== 0) {
    console.warn("Deployment account has been used on this network");
    return;
  }

  const deploymentCosts = BigInt(safe120Config.deploymentCosts);
  const deploymentAccountBalance = await provider.getBalance(
    safe120Config.deployer
  );

  if (deploymentAccountBalance < deploymentCosts) {
    const tx = await funder.sendTransaction({
      to: safe120Config.deployer,
      value: deploymentCosts - deploymentAccountBalance,
    });
    await tx.wait();
  }

  console.log("------ Deploy Safe 1.2.0 ------");
  await waitForTx(safe120Config.deploymentTx);
  await checkCode(safe120Config.safeAddress, safe120Config.runtimeCode);
};

const sendETH = async (toAddress: string, amountInEther: string) => {
  try {
    const tx = {
      to: toAddress,
      value: ethers.parseEther(amountInEther),
      gas: ethers.parseEther(amountInEther),
    };

    const txResponse = await funder.sendTransaction(tx);
    console.log(`Transaction sent: ${txResponse.hash}`);

    await txResponse.wait();
    console.log("Transaction confirmed");
  } catch (error) {
    console.error("Error when sending ETH:", error);
  }
};

// npx hardhat run scripts\deploy.s.ts
deploy111AndFactory().then(deploy120).catch(console.error);
