import { Activatable, el } from "@common-module/app";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class TicketsTab extends Activatable {
  constructor() {
    super(".app-tab.tickets-tab");
    this.append(
      el(
        "header",
        new TitleBarUserButton(),
        el("h1", "Tickets"),
      ),
      el("main"),
    );
  }
}
