import { ethers } from "https://esm.sh/ethers@6.7.0";
import CreatorTradeForSonicContract from "../_shared/contracts/CreatorTradeForSonicContract.ts";
import HashtagTradeWithReferralContract from "../_shared/contracts/HashtagTradeWithReferralContract.ts";
import { getReferralUser } from "./referral.ts";

const ORACLE_PRIVATE_KEY = Deno.env.get("ORACLE_PRIVATE_KEY")!;
const REFERRAL_ENABLED = Deno.env.get("REFERRAL_ENABLED") === "true";
const SONIC_ENABLED = Deno.env.get("SONIC_ENABLED") === "true";

export async function createOracleSignature(
  userId: string,
  chain: string,
  contractType: string,
): Promise<{
  additionalFeePercent: string;
  referrer: string;
  signature: string;
}> {
  const referralUser = await getReferralUser(userId);
  const referrer = referralUser?.wallet_address;
  if (!referrer) {
    return {
      additionalFeePercent: "0",
      referrer: ethers.ZeroAddress,
      signature: "0x",
    };
  }

  const additionalFeePercent = 0n;

  const provider = new ethers.JsonRpcProvider(
    Deno.env.get(`${chain.toUpperCase()}_RPC_URL`),
  );
  const signer = new ethers.JsonRpcSigner(provider, ethers.ZeroAddress);

  let contract;
  if (contractType === "creator-trade") {
    if (SONIC_ENABLED) contract = new CreatorTradeForSonicContract(signer);
    /*TODO: else if (REFERRAL_ENABLED) {
      contract = new CreatorTradeWithReferralContract(signer);
    } else contract = new CreatorTradeContract(signer);*/
  }

  if (contractType === "hashtag-trade") {
    if (REFERRAL_ENABLED) {
      contract = new HashtagTradeWithReferralContract(signer);
    }
    //TODO: else contract = new HashtagTradeContract(signer);
  }

  if (!contract) throw new Error("Invalid contractType");

  const referralFeePercent = await contract.referralFeePercent();
  const signingNonce = await contract.signingNonce();

  const wallet = new ethers.Wallet(ORACLE_PRIVATE_KEY);
  const hash = ethers.getBytes(ethers.solidityPackedKeccak256(
    ["uint256", "address", "uint256", "uint256"],
    [additionalFeePercent, referrer, referralFeePercent, signingNonce],
  ));
  const signature = await wallet.signMessage(hash);

  return {
    additionalFeePercent: additionalFeePercent.toString(),
    referrer,
    signature,
  };
}
