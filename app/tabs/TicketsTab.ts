import {
  Activatable,
  Button,
  ButtonType,
  el,
  InfoMessageBox,
  msg,
  Store,
  Supabase,
  Tabs,
} from "@common-module/app";
import {
  ActivityList,
  NewAssetList,
  openUserOrCreatorModal,
  SFSignedUserManager,
  SFUserService,
  SignedUserChatRoomList,
  TopAssetList,
  TrendingAssetList,
  UserAvatar,
} from "fsesf";

export default class TicketsTab extends Activatable {
  private referrelStore = new Store("referral");

  private tabs: Tabs;
  private chatRoomList: SignedUserChatRoomList;
  private trendingAssetList: TrendingAssetList;
  private topAssetList: TopAssetList;
  private newAssetList: NewAssetList;
  private activityList: ActivityList;

  constructor() {
    super(".app-tab.tickets-tab");
    this.append(
      el("header", el("h1", "Tickets")),
      this.tabs = new Tabs(undefined, [
        {
          id: "your-tickets",
          label: "Your Tickets",
        },
        {
          id: "trending",
          label: "Trending",
        },
        {
          id: "top",
          label: "Top",
        },
        {
          id: "new",
          label: "New",
        },
        {
          id: "activity",
          label: "Activity",
        },
      ]),
      el(
        "main",
        this.chatRoomList = new SignedUserChatRoomList(),
        this.trendingAssetList = new TrendingAssetList(),
        this.topAssetList = new TopAssetList(),
        this.newAssetList = new NewAssetList(),
        this.activityList = new ActivityList(),
      ),
    );

    this.tabs.on("select", (id: string) => {
      [
        this.chatRoomList,
        this.trendingAssetList,
        this.topAssetList,
        this.newAssetList,
        this.activityList,
      ].forEach((
        list,
      ) => list?.hide());
      if (id === "your-tickets") this.chatRoomList.show();
      else if (id === "trending") this.trendingAssetList.show();
      else if (id === "top") this.topAssetList.show();
      else if (id === "new") this.newAssetList.show();
      else if (id === "activity") this.activityList.show();
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
  }

  private async loadReferrer() {
    const from = this.referrelStore.get<string>("from");
    if (from) {
      const user = await SFUserService.fetchByXUsername(from);
      console.log(user);
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

  public activeAsset(chain: string | undefined, assetId: string) {
    this.chatRoomList.activeAsset(chain, assetId);
    this.trendingAssetList.activeAsset(chain, assetId);
    this.topAssetList.activeAsset(chain, assetId);
    this.newAssetList.activeAsset(chain, assetId);
  }

  public deactiveAsset() {
    this.chatRoomList.deactiveAsset();
    this.trendingAssetList.deactiveAsset();
    this.topAssetList.deactiveAsset();
    this.newAssetList.deactiveAsset();
  }

  public activate(): void {
    super.activate();
    this.tabs.emit("visible");
  }
}
