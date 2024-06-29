import { ethers } from "https://esm.sh/ethers@6.7.0";

const ORACLE_PRIVATE_KEY = Deno.env.get("ORACLE_PRIVATE_KEY")!;

export async function createOracleSignature(
  price: bigint,
  additionalFeeRatio: bigint,
  referrer: string,
  referralFeeRatio: bigint,
): Promise<string> {
  console.log(price, additionalFeeRatio, referrer, referralFeeRatio);

  const wallet = new ethers.Wallet(ORACLE_PRIVATE_KEY);
  const hash = ethers.getBytes(ethers.solidityPackedKeccak256(
    ["uint256", "uint256", "address", "uint256"],
    [price, additionalFeeRatio, referrer, referralFeeRatio],
  ));
  const signature = await wallet.signMessage(hash);

  // Split the signature
  const r = signature.slice(0, 66);
  const s = "0x" + signature.slice(66, 130);
  const v = parseInt(signature.slice(130, 132), 16);

  // Combine the data
  const combinedSignature = ethers.concat([
    ethers.zeroPadValue(ethers.toBeHex(additionalFeeRatio), 32),
    ethers.zeroPadValue(referrer, 32),
    ethers.zeroPadValue(ethers.toBeHex(referralFeeRatio), 32),
    hash,
    ethers.toBeHex(v),
    r.slice(2),
    s.slice(2),
  ]);

  return ethers.hexlify(combinedSignature);
}
