import { response, serveWithOptions } from "../_shared/api.ts";
import { getSignedUser } from "../_shared/supabase.ts";
import { generateWalletLinkingNonce, linkWalletToUser } from "./user-wallet.ts";

serveWithOptions(async (req) => {
  const url = new URL(req.url);
  const uri = url.pathname.replace("/api/", "");
  const data = await req.json();

  if (uri === "new-wallet-linking-nonce") {
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    const nonce = await generateWalletLinkingNonce(user.id, data.walletAddress);
    return response({ nonce });
  }

  if (uri === "link-wallet-to-user") {
    const user = await getSignedUser(req);
    if (!user) throw new Error("Unauthorized");
    const { walletType, walletAddress, signedMessage } = data;
    if (!walletAddress || !signedMessage) {
      throw new Error("Missing wallet address or signed message");
    }
    await linkWalletToUser(user.id, walletType, walletAddress, signedMessage);
  }
});
