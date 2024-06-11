import { ethers } from "https://esm.sh/ethers@6.7.0";
import PointsMarketplaceContract from "../_shared/contracts/PointsMarketplaceContract.ts";
import { response, serveWithOptions } from "../_shared/cors.ts";
import supabase, { getSignedUser } from "../_shared/supabase.ts";

serveWithOptions(async (req) => {
  const { chain, productId, amount } = await req.json();
  if (!chain || productId === undefined || !amount) {
    throw new Error("Missing required fields");
  }

  const user = await getSignedUser(req);
  if (!user) throw new Error("Unauthorized");

  const { data: usersPublicData, error: usersPublicError } = await supabase
    .from("users_public").select("wallet_address").eq(
      "user_id",
      user.id,
    );
  if (usersPublicError) throw usersPublicError;
  const userPublic = usersPublicData?.[0];

  if (!userPublic) throw new Error("User public data not found");
  if (!userPublic.wallet_address) throw new Error("Wallet address not found");

  const { data: productData, error: productError } = await supabase
    .from("points_marketplace_products").select().eq(
      "product_id",
      productId,
    );
  if (productError) throw productError;

  const points = Math.ceil(
    productData[0].price_points_per_unit *
      Number(BigInt(amount) / ethers.parseEther("1")),
  );
  if (points < 1) throw new Error("Invalid points amount");

  // Add data to the purchase pending table
  const { error: purchasePendingError } = await supabase
    .from("points_marketplace_purchase_pending").insert([
      {
        user_id: user.id,
        wallet_address: userPublic.wallet_address,
        chain,
        product_id: productId,
        amount,
        points,
      },
    ]);
  if (purchasePendingError) throw purchasePendingError;

  // Sign the message
  const provider = new ethers.JsonRpcProvider(
    Deno.env.get(`${chain.toUpperCase()}_RPC_URL`),
  );
  const signer = new ethers.JsonRpcSigner(provider, ethers.ZeroAddress);
  const signingNonce = await new PointsMarketplaceContract(signer)
    .getSingingNonce();

  const timestamp = Math.floor(Date.now() / 1000);

  const wallet = new ethers.Wallet(
    Deno.env.get("POINTS_MARKETPLACE_SIGNER_KEY")!,
  );
  const hash = ethers.getBytes(ethers.solidityPackedKeccak256(
    [
      "address",
      "uint256",
      "uint256",
    ],
    [
      userPublic.wallet_address,
      timestamp,
      signingNonce,
    ],
  ));
  const signature = await wallet.signMessage(hash);

  return response({ timestamp, points, signature });
});
