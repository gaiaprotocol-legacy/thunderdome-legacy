import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class TopicsTab extends Activatable {
  constructor() {
    super(".app-tab.topics-tab");
    this.append(
      el(
        "header",
        new TitleBarUserButton(),
        el("h1", "Topics"),
      ),
      el("main"),
    );
  }
}
