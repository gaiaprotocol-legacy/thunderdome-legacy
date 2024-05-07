import { serveWithOptions } from "../_shared/cors.ts";
import supabase, { getSignedUser } from "../_shared/supabase.ts";

serveWithOptions(async (req) => {
  const { referrer } = await req.json();
  if (!referrer) throw new Error("Missing referrer");

  const user = await getSignedUser(req);
  if (!user) throw new Error("Unauthorized");

  const { data: referrerData, error: referrerError } = await supabase
    .from("users_public").select().eq(
      "x_username",
      referrer,
    );
  if (referrerError) throw referrerError;

  if (referrerData && referrerData.length > 0) {
    const referrerUserId = referrerData[0].user_id;
    if (referrerUserId === user.id) throw new Error("Cannot refer yourself");

    const { error: insertError } = await supabase.from(
      "referral_used",
    ).insert(
      {
        user_id: user.id,
        referrer_user_id: referrerUserId,
      },
    );
    if (insertError) throw insertError;
  }
});
