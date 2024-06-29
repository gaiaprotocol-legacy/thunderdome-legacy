import supabase from "../_shared/supabase.ts";

export async function getReferralUser(
  userId: string,
): Promise<
  {
    user_id: string;
    wallet_address: string;
  } | undefined
> {
  const { data, error } = await supabase
    .from("referral_used")
    .select()
    .eq("user_id", userId);
  if (error) throw error;
  const referrerUserId = data.length > 0 ? data[0].referrer_user_id : undefined;
  if (!referrerUserId) return undefined;

  const { data: referrerData, error: referrerError } = await supabase
    .from("users_public")
    .select("user_id, wallet_address")
    .eq("user_id", referrerUserId);
  if (referrerError) throw referrerError;
  return referrerData[0];
}
