import { ethers } from "https://esm.sh/ethers@6.7.0";
import CreatorKeysContract from "../_shared/contracts/CreatorKeysContract.ts";
import GroupKeysContract from "../_shared/contracts/GroupKeysContract.ts";
import TopicKeysContract from "../_shared/contracts/TopicKeysContract.ts";
import { serveWithOptions } from "../_shared/cors.ts";
import supabase from "../_shared/supabase.ts";

serveWithOptions(async (req) => {
  let { contractType, blockPeriod } = await req.json();
  if (contractType === undefined) throw new Error("Missing contractType");
  if (!blockPeriod) {
    blockPeriod = parseInt(Deno.env.get("DEFAULT_BLOCK_PERIOD")!);
  }

  const provider = new ethers.JsonRpcProvider(Deno.env.get("RPC_URL"));
  const signer = new ethers.JsonRpcSigner(provider, ethers.ZeroAddress);

  let contract: CreatorKeysContract | GroupKeysContract | TopicKeysContract;
  if (contractType === 0) contract = new CreatorKeysContract(signer);
  else if (contractType === 1) contract = new GroupKeysContract(signer);
  else if (contractType === 2) contract = new TopicKeysContract(signer);
  else throw new Error("Invalid contractType");

  const { data, error: fetchEventBlockError } = await supabase.from(
    "tracked_event_blocks",
  ).select().eq("contract_type", contractType);
  if (fetchEventBlockError) throw fetchEventBlockError;

  let toBlock = (data?.[0]?.block_number ?? contract.deployBlockNumber) +
    blockPeriod;

  const currentBlock = await provider.getBlockNumber();
  if (toBlock > currentBlock) toBlock = currentBlock;

  const events = await contract.getEvents(toBlock - blockPeriod * 2, toBlock);
  for (const event of events) {
    const eventName = Object.keys(contract.eventTopicFilters).find((key) =>
      contract.eventTopicFilters[key][0] === event.topics[0]
    );

    const args = event.args.map((arg) => arg.toString());
    const data: any = {
      block_number: event.blockNumber,
      log_index: event.index,
      tx: event.transactionHash,
      event_name: eventName,
      args,
      key_type: contractType,
    };

    if (eventName === "GroupCreated") {
      data.wallet_address = args[1];
      data.reference_key = args[0];
    } else if (eventName === "Trade" || eventName === "ClaimHolderFee") {
      data.wallet_address = args[0];
      data.reference_key = contractType === 2
        ? ethers.decodeBytes32String(args[1])
        : args[1];
    }

    const { error: saveEventError } = await supabase
      .from("contract_events")
      .upsert(data);
    if (saveEventError) {
      console.log(data);
      throw saveEventError;
    }
  }

  const { error: saveEventBlockError } = await supabase.from(
    "tracked_event_blocks",
  ).upsert({
    contract_type: contractType,
    block_number: toBlock,
    updated_at: new Date().toISOString(),
  });
  if (saveEventBlockError) throw saveEventBlockError;
});
