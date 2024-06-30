import { response, serveWithOptions } from "../_shared/api.ts";
import { getSignedUser } from "../_shared/supabase.ts";
import { createOracleSignature } from "./oracle-sign.ts";
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
    const { chain, contractType } = await req.json();
    if (!chain || !contractType) {
      throw new Error("Missing chain or contract type");
    }
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    const result = await createOracleSignature(user.id, chain, contractType);
    return response(result);
  }
});
