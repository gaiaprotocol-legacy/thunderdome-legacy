import { ethers } from "https://esm.sh/ethers@6.7.0";
import Contract from "./Contract.ts";
import TopicKeysArtifact from "./abi/TopicKeys.json" assert {
  type: "json",
};
import { TopicKeys } from "./abi/TopicKeys.ts";

export default class TopicKeysContract extends Contract<TopicKeys> {
  constructor(signer: ethers.Signer) {
    super(
      Deno.env.get("TOPIC_KEYS_CONTRACT_ADDRESS")!,
      TopicKeysArtifact.abi,
      signer,
      parseInt(Deno.env.get("TOPIC_KEYS_CONTRACT_DEPLOY_BLOCK_NUMBER")!),
    );
    this.eventFilters = {
      SetProtocolFeeDestination: this.ethersContract.filters
        .SetProtocolFeeDestination(),
      SetProtocolFeePercent: this.ethersContract.filters
        .SetProtocolFeePercent(),
      SetHolderFeePercent: this.ethersContract.filters
        .SetHolderFeePercent(),
      Trade: this.ethersContract.filters.Trade(),
      ClaimHolderFee: this.ethersContract.filters.ClaimHolderFee(),
    };
  }
}
