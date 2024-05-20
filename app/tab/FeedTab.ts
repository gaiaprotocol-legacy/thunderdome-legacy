import { Activatable, el, Tabs } from "@common-module/app";
import {
  Post,
  PostForm,
  PostListFollowing,
  PostListForYou,
  PostSingle,
} from "fsesf";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class FeedTab extends Activatable {
  private tabs: Tabs;

  private postForm: PostForm;
  private postListForYou: PostListForYou;
  private postListFollowing: PostListFollowing;

  constructor() {
    super(".app-tab.feed-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Feed"),
        el("h1.mobile", el("img", { src: "/images/logo-navbar.png" })),
      ),
      this.tabs = new Tabs("thunder-dome-feed-tab", [
        { id: "for-you", label: "For You" },
        { id: "following", label: "Following" },
      ]),
      el(
        "main",
        this.postForm = new PostForm(),
        this.postListForYou = new PostListForYou(),
        this.postListFollowing = new PostListFollowing(),
      ),
    );

    this.postForm.on("post", (post: Post) => {
      this.postListForYou.prepend(
        new PostSingle(post, { hasChild: false, main: false }),
      );
      this.postListFollowing.prepend(
        new PostSingle(post, { hasChild: false, main: false }),
      );
    });

    this.tabs.on("select", (id: string) => {
      [this.postListForYou, this.postListFollowing].forEach((l) => l.hide());
      if (id === "for-you") this.postListForYou.show();
      else if (id === "following") this.postListFollowing.show();
    }).init();
  }
}
