import { response, serveWithOptions } from "../_shared/api.ts";
import supabase from "../_shared/supabase.ts";

async function getAllCreators() {
  const { data, error } = await supabase.from("creators").select(
    "creator_address",
  );
  if (error) throw error;
  return data.map((row) => row.creator_address);
}

async function getAllHolders(creatorAddress: string) {
  const { data, error } = await supabase
    .from("creator_holders")
    .select("wallet_address, last_fetched_balance")
    .eq("creator_address", creatorAddress);
  if (error) throw error;
  return data;
}

serveWithOptions(async () => {
  const creators = await getAllCreators();
  if (creators.length >= 1000) {
    throw new Error("Too many creators");
  }

  const result: any = {
    creators: [],
    allHolders: [],
    allAmounts: [],
  };

  await Promise.all(creators.map(async (creatorAddress) => {
    const _holders = await getAllHolders(creatorAddress);
    if (_holders.length >= 1000) {
      throw new Error(`Too many holders for creator ${creatorAddress}`);
    }
    if (_holders.length > 0) {
      result.creators.push(creatorAddress);

      const creatorAsHolder = _holders.find((holder) =>
        holder.wallet_address === creatorAddress
      );
      if (creatorAsHolder) creatorAsHolder.last_fetched_balance += 1;
      else {
        _holders.push({
          wallet_address: creatorAddress,
          last_fetched_balance: 1,
        });
      }

      result.allHolders.push(_holders.map((holder) => holder.wallet_address));
      result.allAmounts.push(
        _holders.map((holder) => holder.last_fetched_balance),
      );
    }
  }));

  return response(result);
});
