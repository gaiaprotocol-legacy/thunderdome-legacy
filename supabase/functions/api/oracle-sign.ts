import { ethers } from "https://esm.sh/ethers@6.7.0";

const ORACLE_PRIVATE_KEY = Deno.env.get("ORACLE_PRIVATE_KEY")!;

export async function createOracleSignature(
  additionalFeePercent: bigint,
  referrer: string,
  referralFeePercent: bigint,
  signingNonce: bigint,
): Promise<string> {
  const wallet = new ethers.Wallet(ORACLE_PRIVATE_KEY);
  const hash = ethers.getBytes(ethers.solidityPackedKeccak256(
    ["uint256", "address", "uint256", "uint256"],
    [additionalFeePercent, referrer, referralFeePercent, signingNonce],
  ));
  return await wallet.signMessage(hash);
}
