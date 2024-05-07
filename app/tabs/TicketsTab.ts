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
  CreatorInfoModal,
  HorizontalTrendingAssetList,
  NewAssetList,
  SFSignedUserManager,
  SFUserService,
  SignedUserHoldingAssetList,
  TopAssetList,
  UserAvatar,
  UserInfoModal,
} from "fsesf";

export default class TicketsTab extends Activatable {
  private referrelStore = new Store("referral");

  private main;
  private trendingList: HorizontalTrendingAssetList;
  private tabs: Tabs;
  private yourTicketsList: SignedUserHoldingAssetList;
  private topAssetList: TopAssetList;
  private newAssetList: NewAssetList;

  constructor() {
    super(".app-tab.tickets-tab");
    this.append(
      el("header", el("h1", "Tickets")),
      this.main = el(
        "main",
        el("header", el("h2", "Trending")),
        this.trendingList = new HorizontalTrendingAssetList(),
        this.tabs = new Tabs(undefined, [
          {
            id: "your-tickets",
            label: "Your Tickets",
          },
          {
            id: "top",
            label: "Top",
          },
          {
            id: "new",
            label: "New",
          },
        ]),
        this.yourTicketsList = new SignedUserHoldingAssetList(),
        this.topAssetList = new TopAssetList(),
        this.newAssetList = new NewAssetList(),
      ),
    );

    this.tabs.on("select", (id: string) => {
      [this.yourTicketsList, this.topAssetList, this.newAssetList].forEach((
        list,
      ) => list?.hide());
      if (id === "your-tickets") this.yourTicketsList.show();
      else if (id === "top") this.topAssetList.show();
      else if (id === "new") this.newAssetList.show();
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
                {
                  click: () => {
                    user.wallet_address
                      ? new CreatorInfoModal(user.wallet_address, undefined)
                      : new UserInfoModal(user);
                  },
                },
              ),
              ". If you login, ",
              el(
                "a.user",
                new UserAvatar(user.user_id, [
                  user.avatar_thumb,
                  user.stored_avatar_thumb,
                ]),
                el("span.name", user.display_name),
                {
                  click: () => {
                    user.wallet_address
                      ? new CreatorInfoModal(user.wallet_address, undefined)
                      : new UserInfoModal(user);
                  },
                },
              ),
              " will earn ",
              el("b", "5 points"),
              ".",
            ],
            footer: new Button({
              type: ButtonType.Contained,
              title: msg("login-required-login-button"),
              click: () => SFSignedUserManager.signIn(),
            }),
          }),
        ).appendTo(this.main, 0);
      }
    }
  }

  public activeCreator(creatorAddress: string) {
  }

  public deactiveCreator() {
  }

  public activeHashtag(hashtag: string) {
  }

  public deactiveHashtag() {
  }
}
