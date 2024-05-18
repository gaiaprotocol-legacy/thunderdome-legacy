import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class SettingsTab extends Activatable {
  constructor() {
    super(".app-tab.settings-tab");
    this.append(
      el(
        "header",
        new TitleBarUserButton(),
        el("h1", "Settings"),
      ),
      el("main"),
    );
  }
}
