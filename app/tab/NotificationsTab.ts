import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class NotificationsTab extends Activatable {
  constructor() {
    super(".app-tab.notifications-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Notifications"),
      ),
      el("main"),
    );
  }
}
