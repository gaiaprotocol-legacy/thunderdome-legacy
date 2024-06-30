import { ethers } from "https://esm.sh/ethers@6.7.0";
import Contract from "./Contract.ts";
import CreatorTradeForSonicArtifact from "./abi/CreatorTradeForSonic.json" assert {
  type: "json",
};
import { CreatorTradeForSonic } from "./abi/CreatorTradeForSonic.ts";

export default class CreatorTradeForSonicContract
  extends Contract<CreatorTradeForSonic> {
  constructor(signer: ethers.Signer) {
    super(
      Deno.env.get("CREATOR_TRADE_ADDRESS")!,
      CreatorTradeForSonicArtifact.abi,
      signer,
      parseInt(Deno.env.get("CREATOR_TRADE_DEPLOY_BLOCK")!),
    );
    this.eventFilters = {
      Trade: this.ethersContract.filters.Trade(),
    };
  }

  public async referralFeePercent() {
    return await this.ethersContract.referralFeePercent();
  }

  public async signingNonce() {
    return await this.ethersContract.signingNonce();
  }
}
