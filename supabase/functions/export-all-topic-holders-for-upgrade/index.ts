import { response, serveWithOptions } from "../_shared/api.ts";
import supabase from "../_shared/supabase.ts";

async function getAllHashtags() {
  const { data, error } = await supabase.from("hashtags").select("hashtag");
  if (error) throw error;
  return data.map((row) => row.hashtag);
}

async function getAllHolders(hashtag: string) {
  const { data, error } = await supabase
    .from("hashtag_holders")
    .select("wallet_address, last_fetched_balance")
    .eq("hashtag", hashtag);
  if (error) throw error;
  return data;
}

serveWithOptions(async () => {
  const hashtags = await getAllHashtags();
  if (hashtags.length >= 1000) {
    throw new Error("Too many hashtags");
  }

  const result: any = {
    _hashtags: [],
    allHolders: [],
    allAmounts: [],
  };

  await Promise.all(hashtags.map(async (hashtag) => {
    const _holders = await getAllHolders(hashtag);
    if (_holders.length >= 1000) {
      throw new Error(`Too many holders for hashtag ${hashtag}`);
    }
    if (_holders.length > 0) {
      result._hashtags.push(hashtag);
      result.allHolders.push(_holders.map((holder) => holder.wallet_address));
      result.allAmounts.push(
        _holders.map((holder) => holder.last_fetched_balance),
      );
    }
  }));

  return response(result);
});
