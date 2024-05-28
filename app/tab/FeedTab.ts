import {
  Activatable,
  Button,
  ButtonType,
  ComponentUtil,
  DomNode,
  el,
  InfoMessageBox,
  msg,
  Store,
  Supabase,
  Tabs,
} from "@common-module/app";
import {
  openUserOrCreatorModal,
  Post,
  PostForm,
  PostListFollowing,
  PostListForYou,
  SFSignedUserManager,
  SFUserService,
  UserAvatar,
} from "fsesf";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class FeedTab extends Activatable {
  private referrelStore = new Store("referral");

  private tabs: Tabs;

  private main: DomNode;
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
      this.main = el(
        "main",
        this.postForm = new PostForm(),
        this.postListForYou = new PostListForYou(),
        this.postListFollowing = new PostListFollowing(),
      ),
    );

    this.postForm.on("post", (post: Post) => {
      this.postListForYou.addPost(post, 0);
      this.postListFollowing.addPost(post, 0);
    });

    this.tabs.on("select", (id: string) => {
      [this.postListForYou, this.postListFollowing].forEach((l) => l.hide());
      if (id === "for-you") this.postListForYou.show();
      else if (id === "following") this.postListFollowing.show();
    }).init();

    if (this.referrelStore.get("from")) {
      if (!SFSignedUserManager.signed) {
        this.loadReferrer();
      } else {
        Supabase.client.functions.invoke(
          "use-referrel-code",
          { body: { referrer: this.referrelStore.get("from") } },
        );
      }
    }

    ComponentUtil.enablePullToRefresh(this.main, () => this.refresh());
  }

  public refresh() {
    this.main.domElement.scrollTo({ top: 0, behavior: "smooth" });
    if (this.postListForYou.loaded) this.postListForYou.load();
    if (this.postListFollowing.loaded) this.postListFollowing.load();
  }

  private async loadReferrer() {
    const from = this.referrelStore.get<string>("from");
    if (from) {
      const user = await SFUserService.fetchByXUsername(from);
      if (user) {
        el(
          ".referral-info-message-container",
          new InfoMessageBox({
            message: [
              "You have been invited by ",
              el(
                "a.user",
                new UserAvatar(user.user_id, [
                  user.avatar_thumb,
                  user.stored_avatar_thumb,
                ]),
                el("span.name", user.display_name),
                { click: () => openUserOrCreatorModal(user) },
              ),
              ". If you login, ",
              el(
                "a.user",
                new UserAvatar(user.user_id, [
                  user.avatar_thumb,
                  user.stored_avatar_thumb,
                ]),
                el("span.name", user.display_name),
                { click: () => openUserOrCreatorModal(user) },
              ),
              " will earn ",
              el("b", "10 points"),
              ".",
            ],
            footer: new Button({
              type: ButtonType.Contained,
              title: msg("login-required-login-button"),
              click: () => SFSignedUserManager.signIn(),
            }),
          }),
        ).appendTo(this, 1);
      }
    }
  }
}
