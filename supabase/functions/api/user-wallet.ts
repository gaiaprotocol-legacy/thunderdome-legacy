import { ethers } from "https://esm.sh/ethers@6.7.0";
import supabase from "../_shared/supabase.ts";

export async function generateWalletLinkingNonce(
  userId: string,
  walletAddress: string,
) {
  // delete old nonce
  const { error: deleteError } = await supabase.from("wallet_linking_nonces")
    .delete().eq("user_id", userId);
  if (deleteError) throw deleteError;

  const { data, error: insertError } = await supabase.from(
    "wallet_linking_nonces",
  ).insert({
    user_id: userId,
    wallet_address: walletAddress,
  }).select().single();

  if (insertError) throw insertError;
  return data.nonce;
}

export async function linkWalletToUser(
  userId: string,
  walletType: string,
  walletAddress: string,
  signedMessage: string,
) {
  const { data: nonceDataSet, error: nonceError } = await supabase.from(
    "wallet_linking_nonces",
  ).select().eq("user_id", userId);
  if (nonceError) throw nonceError;

  const nonceData = nonceDataSet?.[0];
  if (!nonceData) throw new Error("Nonce not found");
  if (nonceData.wallet_address !== walletAddress) {
    throw new Error("Invalid wallet address");
  }

  const verifiedAddress = ethers.verifyMessage(
    `${
      Deno.env.get("MESSAGE_FOR_WALLET_LINKING")
    }\n\nNonce: ${nonceData.nonce}`,
    signedMessage,
  );
  if (walletAddress !== verifiedAddress) throw new Error("Invalid signature");

  // delete old nonce
  await supabase.from("wallet_linking_nonces").delete().eq("user_id", userId);

  const { error: deleteWalletAddressError } = await supabase.from(
    "users_public",
  ).update(
    { wallet_address: null },
  ).eq("wallet_address", walletAddress);
  if (deleteWalletAddressError) throw deleteWalletAddressError;

  const { error: setWalletAddressError } = await supabase.from("users_public")
    .update({ wallet_address: walletAddress, wallet_type: walletType }).eq(
      "user_id",
      userId,
    );
  if (setWalletAddressError) throw setWalletAddressError;
}
