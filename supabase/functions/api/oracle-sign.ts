import { ethers } from "https://esm.sh/ethers@6.7.0";

const ORACLE_PRIVATE_KEY = Deno.env.get("ORACLE_PRIVATE_KEY")!;

export async function createOracleSignature(
  price: bigint,
  additionalFeeRatio: bigint,
  referrer: string,
  referralFeeRatio: bigint,
): Promise<string> {

  const wallet = new ethers.Wallet(ORACLE_PRIVATE_KEY);
  const messageHash = ethers.keccak256(
    ethers.AbiCoder.defaultAbiCoder().encode(
      ["uint256", "uint256", "address", "uint256"],
      [price, additionalFeeRatio, referrer, referralFeeRatio],
    ),
  );

  const messageHashBytes = ethers.getBytes(messageHash);
  const signature = await wallet.signMessage(messageHashBytes);
  const sig = ethers.Signature.from(signature);

  const combinedSignature = ethers.concat([
    ethers.zeroPadValue(ethers.toBeHex(additionalFeeRatio), 32),
    ethers.zeroPadValue(referrer, 32),
    ethers.zeroPadValue(ethers.toBeHex(referralFeeRatio), 32),
    messageHash,
    sig.r,
    sig.s,
    ethers.toBeHex(sig.v),
  ]);

  /*console.log(
    ethers.getBytes(signature).length,
    ethers.getBytes(combinedSignature).length,
  );*/

  return combinedSignature;
}
