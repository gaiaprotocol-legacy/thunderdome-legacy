import { response, serveWithOptions } from "../_shared/api.ts";
import { getSignedUser } from "../_shared/supabase.ts";
import { createOracleSignature } from "./oracle-sign.ts";
import { getReferralUser } from "./referral.ts";
import { generateWalletLinkingNonce, linkWalletToUser } from "./user-wallet.ts";
import { ethers } from "https://esm.sh/ethers@6.7.0";
import HashtagTradeWithReferralContract from "../_shared/contracts/HashtagTradeWithReferralContract.ts";

serveWithOptions(async (req) => {
  const url = new URL(req.url);
  const uri = url.pathname.replace("/api/", "");

  if (uri === "new-wallet-linking-nonce") {
    const { walletAddress } = await req.json();
    if (!walletAddress) throw new Error("Missing wallet address");
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    const nonce = await generateWalletLinkingNonce(user.id, walletAddress);
    return response(nonce);
  }

  if (uri === "link-wallet-to-user") {
    const { walletType, walletAddress, signedMessage } = await req.json();
    if (!walletAddress || !signedMessage) {
      throw new Error("Missing wallet address or signed message");
    }
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    await linkWalletToUser(user.id, walletType, walletAddress, signedMessage);
  }

  if (uri === "create-oracle-signature") {
    const { chain } = await req.json();
    if (!chain) throw new Error("Missing chain");
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    const referralUser = await getReferralUser(user.id);
    if (!referralUser?.wallet_address) return response("0x");

    const additionalFeePercent = 0n;

    const provider = new ethers.JsonRpcProvider(
      Deno.env.get(`${chain.toUpperCase()}_RPC_URL`),
    );
    const signer = new ethers.JsonRpcSigner(provider, ethers.ZeroAddress);
    const contract = new HashtagTradeWithReferralContract(signer);
    const referralFeePercent = await contract.referralFeePercent();
    const signingNonce = await contract.signingNonce();

    const signature = await createOracleSignature(
      additionalFeePercent,
      referralUser.wallet_address,
      referralFeePercent,
      signingNonce,
    );
    return response({
      additionalFeePercent: additionalFeePercent.toString(),
      referrer: referralUser.wallet_address,
      signature,
    });
  }
});
