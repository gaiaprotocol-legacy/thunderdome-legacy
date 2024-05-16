import { Activatable, el, Tabs } from "@common-module/app";
import {
  Post,
  PostForm,
  PostListFollowing,
  PostListForYou,
  PostThread,
} from "fsesf";

export default class FeedTab extends Activatable {
  private mode: "feed" | "thread" | undefined;

  constructor() {
    super(".app-tab.feed-tab");
  }

  public loadFeed() {
    if (this.mode === "feed") return;
    this.mode = "feed";

    let tabs: Tabs;
    let postListForYou: PostListForYou;
    let postListFollowing: PostListFollowing;

    this.empty().append(
      el("header", el("h1", el("img", { src: "/images/logo-navbar.png" }))),
      tabs = new Tabs("thunder-dome-feed-tab", [
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
        postListForYou = new PostListForYou(),
        postListFollowing = new PostListFollowing(),
      ),
    );

    tabs.on("select", (id: string) => {
      [postListForYou, postListFollowing].forEach((l) => l.hide());
      if (id === "for-you") postListForYou.show();
      else if (id === "following") postListFollowing.show();
    }).init();
  }

  public loadThread(postId: number, post?: Post) {
    if (this.mode === "thread") return;
    this.mode = "thread";

    this.empty().append(new PostThread(postId, post ? [post] : undefined));
  }
}
