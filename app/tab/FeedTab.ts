import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class FeedTab extends Activatable {
  constructor() {
    super(".app-tab.feed-tab");
    this.append(
      el(
        "header",
        new TitleBarUserButton(),
        el("h1", "Feed"),
        el("h1.mobile", el("img", { src: "/images/logo-navbar.png" })),
      ),
      el("main"),
    );
  }
}
