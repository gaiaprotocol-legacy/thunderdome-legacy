import { Activatable, el, Tabs } from "@common-module/app";
import { PostForm, PostListFollowing, PostListForYou } from "fsesf";

export default class HomeTab extends Activatable {
  private tabs: Tabs;
  private postListForYou: PostListForYou;
  private postListFollowing: PostListFollowing;

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
        new PostForm(),
        this.postListForYou = new PostListForYou(),
        this.postListFollowing = new PostListFollowing(),
      ),
    );

    this.tabs.on("select", (id: string) => {
      [this.postListForYou, this.postListFollowing].forEach((l) => l.hide());
      if (id === "for-you") this.postListForYou.show();
      else if (id === "following") this.postListFollowing.show();
    }).init();
  }
}
