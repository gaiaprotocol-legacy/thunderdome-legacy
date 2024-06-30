import { ethers } from "https://esm.sh/ethers@6.7.0";
import Contract from "./Contract.ts";
import HashtagTradeWithReferralArtifact from "./abi/HashtagTradeWithReferral.json" assert {
  type: "json",
};
import { HashtagTradeWithReferral } from "./abi/HashtagTradeWithReferral.ts";

export default class HashtagTradeWithReferralContract
  extends Contract<HashtagTradeWithReferral> {
  constructor(signer: ethers.Signer) {
    super(
      Deno.env.get("HASHTAG_TRADE_ADDRESS")!,
      HashtagTradeWithReferralArtifact.abi,
      signer,
      parseInt(Deno.env.get("HASHTAG_TRADE_DEPLOY_BLOCK")!),
    );
    this.eventFilters = {
      Trade: this.ethersContract.filters.Trade(),
      ClaimHolderFee: this.ethersContract.filters.ClaimHolderFee(),
    };
  }

  public async referralFeePercent() {
    return await this.ethersContract.referralFeePercent();
  }

  public async signingNonce() {
    return await this.ethersContract.signingNonce();
  }
}
