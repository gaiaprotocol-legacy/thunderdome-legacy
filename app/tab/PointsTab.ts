import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class PointsTab extends Activatable {
  constructor() {
    super(".app-tab.points-tab");
    this.append(
      el(
        "header",
        new TitleBarUserButton(),
        el("h1", "Points"),
      ),
      el("main"),
    );
  }
}
