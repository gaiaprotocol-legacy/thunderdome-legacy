import { ethers } from "https://esm.sh/ethers@6.7.0";
import Contract from "./Contract.ts";
import PointsMarketplaceArtifact from "./abi/PointsMarketplace.json" assert {
  type: "json",
};
import { PointsMarketplace } from "./abi/PointsMarketplace.ts";

export default class PointsMarketplaceContract
  extends Contract<PointsMarketplace> {
  constructor(signer: ethers.Signer) {
    super(
      Deno.env.get("POINT_MARKETPLACE_ADDRESS")!,
      PointsMarketplaceArtifact.abi,
      signer,
      parseInt(Deno.env.get("POINT_MARKETPLACE_DEPLOY_BLOCK")!),
    );
    this.eventFilters = {
      ProductPurchased: this.ethersContract.filters.ProductPurchased(),
    };
  }

  public async getSingingNonce(): Promise<bigint> {
    return await this.ethersContract.signingNonce();
  }
}
