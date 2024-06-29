import { response, serveWithOptions } from "../_shared/api.ts";
import { getSignedUser } from "../_shared/supabase.ts";
import { createOracleSignature } from "./oracle-sign.ts";
import { getReferralUser } from "./referral.ts";
import { generateWalletLinkingNonce, linkWalletToUser } from "./user-wallet.ts";

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
    const { price } = await req.json();
    if (!price) throw new Error("Missing price");
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    const referralUser = await getReferralUser(user.id);
    if (!referralUser?.wallet_address) return response("0x");

    const signature = await createOracleSignature(
      BigInt(price),
      0n,
      referralUser.wallet_address,
      10000000000000000n,
    );
    return response(signature);
  }
});
