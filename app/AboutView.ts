import { el, View, ViewParams, WarningMessageBox } from "@common-module/app";
import { FSESFLayout } from "fsesf";

export default class AboutView extends View {
  constructor(params: ViewParams, uri: string) {
    super();
    FSESFLayout.append(
      this.container = el(
        ".about-view",
        new WarningMessageBox({
          message: [
            "Thunder Dome is currently operating on the ",
            el("a", "Fantom Sonic Testnet", {
              href:
                "https://fantom.foundation/blog/fantom-foundation-launches-testnet-for-fantom-sonic",
              target: "_blank",
            }),
            ". It is planned to launch on the mainnet in alignment with the release of the Sonic mainnet.",
          ],
        }),
        el(
          "section",
          el("h2", "Introduction to Thunder Dome"),
          el(
            "p",
            el("img", {
              src: "/images/logo-transparent.png",
              alt: "Thunder Dome Logo",
            }),
            "Thunder Dome is a Full-stack Social Fi service built on the Fantom blockchain. It allows users to engage with communities through ",
            el("b", "tickets"),
            ", which are social tokens that can be bought or sold.",
          ),
        ),
        el(
          "section",
          el("h2", "Understanding Full-stack Social Fi"),
          el(
            "p",
            "Full-stack Social Fi represents an expansion from personal-focused social finance to include groups and topics. In Thunder Dome, users can buy tickets to participate in and communicate with communities centered around individuals, groups, or subjects.",
          ),
        ),
        el(
          "section",
          el("h2", "Monetization in Thunder Dome"),
          el(
            "p",
            "Regarding monetization, users can generate revenue through Thunder Dome. For individual tickets, the ticket owner earns ",
            el("b", "5%"),
            " of the transaction amount as profit. For group and topic tickets, holders receive ",
            el("b", "5%"),
            " of the transaction volume, distributed proportionally to their holdings.",
          ),
        ),
      ),
    );
  }
}
