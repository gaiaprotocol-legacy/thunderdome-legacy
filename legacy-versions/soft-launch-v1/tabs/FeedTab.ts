import {
  Activatable,
  Button,
  ButtonType,
  el,
  MaterialIcon,
  Tabs,
} from "@common-module/app";
import {
  Post,
  PostForm,
  PostListFollowing,
  PostListForYou,
  PostSingle,
  PostThread,
} from "fsesf";

export default class FeedTab extends Activatable {
  private _mode: "feed" | "thread" | undefined;
  private currentPostId: number | undefined;

  constructor() {
    super(".app-tab.feed-tab");
  }

  private set mode(mode: "feed" | "thread") {
    this._mode = mode;
    this.deleteClass("feed", "thread").addClass(mode);
  }

  public loadFeed() {
    if (this._mode === "feed") return;
    this.mode = "feed";
    this.currentPostId = undefined;

    let tabs: Tabs;
    let postForm: PostForm;
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
        postForm = new PostForm(),
        postListForYou = new PostListForYou(),
        postListFollowing = new PostListFollowing(),
      ),
    );

    postForm.on("post", (post: Post) => {
      postListForYou.prepend(new PostSingle(post));
      postListFollowing.prepend(new PostSingle(post));
    });

    tabs.on("select", (id: string) => {
      [postListForYou, postListFollowing].forEach((l) => l.hide());
      if (id === "for-you") postListForYou.show();
      else if (id === "following") postListFollowing.show();
    }).init();
  }

  public loadThread(postId: number, post?: Post) {
    if (this._mode === "thread" && this.currentPostId === postId) return;
    this.mode = "thread";
    this.currentPostId = postId;

    this.empty().append(
      el(
        "header",
        new Button({
          type: ButtonType.Circle,
          icon: new MaterialIcon("arrow_back"),
          click: () => history.back(),
        }),
        el("h1", "Post"),
      ),
      el("main", new PostThread(postId, post ? [post] : undefined)),
    );
  }
}
