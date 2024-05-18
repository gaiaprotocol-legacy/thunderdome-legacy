import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class CommunitiesTab extends Activatable {
  constructor() {
    super(".app-tab.communities-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Communities"),
      ),
      el("main", el("p.wip", "No communities yet. Stay tuned!")),
    );
  }
}
