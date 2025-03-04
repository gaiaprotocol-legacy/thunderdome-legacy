import { ethers } from "https://esm.sh/ethers@6.7.0";
import CreatorTradeContract from "../_shared/contracts/CreatorTradeContract.ts";
import CreatorTradeForSonicContract from "../_shared/contracts/CreatorTradeForSonicContract.ts";
import HashtagTradeContract from "../_shared/contracts/HashtagTradeContract.ts";
import HashtagTradeWithReferralContract from "../_shared/contracts/HashtagTradeWithReferralContract.ts";
import PointsMarketplaceContract from "../_shared/contracts/PointsMarketplaceContract.ts";
import TicketsContract from "../_shared/contracts/TicketsContract.ts";
import { serveWithOptions } from "../_shared/cors.ts";
import supabase from "../_shared/supabase.ts";

serveWithOptions(async (req) => {
  let { chain, contractType, blockPeriod } = await req.json();
  if (contractType === undefined) throw new Error("Missing contractType");
  if (!blockPeriod) {
    if (chain === "base") blockPeriod = 500;
    else if (chain === "arbitrum") blockPeriod = 2500;
    else blockPeriod = 750;
  }

  const referralEnabled = Deno.env.get("REFERRAL_ENABLED") === "true";
  const sonicEnabled = Deno.env.get("SONIC_ENABLED") === "true";

  const provider = new ethers.JsonRpcProvider(
    Deno.env.get(`${chain.toUpperCase()}_RPC_URL`),
  );
  const signer = new ethers.JsonRpcSigner(provider, ethers.ZeroAddress);

  let contract:
    | CreatorTradeContract
    | CreatorTradeForSonicContract
    | HashtagTradeContract
    | HashtagTradeWithReferralContract
    | TicketsContract
    | PointsMarketplaceContract;

  if (contractType === "creator-trade") {
    contract = sonicEnabled
      ? new CreatorTradeForSonicContract(signer)
      : new CreatorTradeContract(signer);
  } else if (contractType === "hashtag-trade") {
    contract = referralEnabled
      ? new HashtagTradeWithReferralContract(signer)
      : new HashtagTradeContract(signer);
  } else if (contractType === "tickets") {
    contract = new TicketsContract(chain, signer);
  } else if (contractType === "points-marketplace") {
    contract = new PointsMarketplaceContract(signer);
  } else throw new Error("Invalid contractType");

  const { data, error: fetchEventBlockError } = await supabase.from(
    "tracked_event_blocks",
  ).select().eq("chain", chain).eq("contract_type", contractType);
  if (fetchEventBlockError) throw fetchEventBlockError;

  let toBlock = (data?.[0]?.block_number ?? (contract.deployBlockNumber ?? 0)) +
    blockPeriod;

  const currentBlock = await provider.getBlockNumber();
  if (toBlock > currentBlock) toBlock = currentBlock;

  const { data: savedEvents, error: savedEventError } = await supabase
    .from("contract_events")
    .select("chain, contract_type, block_number, log_index")
    .eq("chain", chain)
    .eq("contract_type", contractType)
    .order("created_at", { ascending: false });
  if (savedEventError) throw savedEventError;

  const events = await contract.getEvents(toBlock - blockPeriod * 2, toBlock);
  for (const event of events) {
    const eventName = Object.keys(contract.eventTopicFilters).find((key) =>
      contract.eventTopicFilters[key][0] === event.topics[0]
    );
    const args = event.args.map((arg) => arg.toString());
    const data: any = {
      chain,
      contract_type: contractType,
      block_number: event.blockNumber,
      log_index: event.index,
      tx: event.transactionHash,
      event_name: eventName,
      args,
    };

    if (eventName === "TicketCreated") {
      data.wallet_address = args[1];
      data.asset_id = args[0];
    } else if (eventName === "TicketDeleted") {
      data.asset_id = args[0];
    } else if (eventName === "Trade" || eventName === "ClaimHolderFee") {
      data.wallet_address = args[0];
      data.asset_id = contractType === "hashtag-trade"
        ? ethers.decodeBytes32String(args[1])
        : args[1];
    } else if (eventName === "ProductPurchased") {
      data.wallet_address = args[0];
    }

    if (
      !savedEvents.find((savedEvent) =>
        savedEvent.chain === data.chain &&
        savedEvent.contract_type === data.contract_type &&
        savedEvent.block_number === data.block_number &&
        savedEvent.log_index === data.log_index
      )
    ) {
      const { error: saveEventError } = await supabase
        .from("contract_events")
        .upsert(data);
      if (saveEventError) {
        console.error(data);
        throw saveEventError;
      }
    }
  }

  const { error: saveEventBlockError } = await supabase.from(
    "tracked_event_blocks",
  ).upsert({
    chain,
    contract_type: contractType,
    block_number: toBlock,
    updated_at: new Date().toISOString(),
  });
  if (saveEventBlockError) throw saveEventBlockError;
});
