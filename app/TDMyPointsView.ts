import { el, WarningMessageBox } from "@common-module/app";
import { MyPointsView } from "../../esf/lib/index.js";

export default class TDMyPointsView extends MyPointsView {
  constructor() {
    super();
    this.container.append(
      new WarningMessageBox({
        message: [
          "Thunder Dome is currently operating on the ",
          el("a", "Fantom Sonic Testnet", {
            href:
              "https://fantom.foundation/blog/fantom-foundation-launches-testnet-for-fantom-sonic",
            target: "_blank",
          }),
          ". It is planned to launch on the mainnet in alignment with the release of the Sonic mainnet. Please note that all points currently accumulated may be reset upon the launch of the mainnet.",
        ],
      }),
    );
  }
}
