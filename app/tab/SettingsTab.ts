import { Activatable, el } from "@common-module/app";
import { MePanel } from "fsesf";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class SettingsTab extends Activatable {
  private mePanel: MePanel;

  constructor() {
    super(".app-tab.settings-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Settings"),
      ),
      el("main", this.mePanel = new MePanel()),
    );
  }

  public activeAsset(chain: string | undefined, assetId: string) {
    this.mePanel.activeAsset(chain, assetId);
  }

  public deactiveAsset() {
    this.mePanel.deactiveAsset();
  }
}
