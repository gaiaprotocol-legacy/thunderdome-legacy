import { Activatable, el, Tabs } from "@common-module/app";

export default class HomeTab extends Activatable {
  private tabs: Tabs;
  constructor() {
    super(".app-tab.home-tab");
    this.append(
      el("header", el("h1", el("img", { src: "/images/logo-navbar.png" }))),
      this.tabs = new Tabs("thunder-dome-home-tab", [
        {
          id: "for-you",
          label: "For You",
        },
        {
          id: "following",
          label: "Following",
        },
      ]),
      el(
        "main",
      ),
    );

    this.tabs.on("select", (id: string) => {
    }).init();
  }
}
