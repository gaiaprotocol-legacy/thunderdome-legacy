import {
  AppNavBar,
  AvatarUtil,
  BodyNode,
  DomNode,
  el,
  MaterialIcon,
  Router,
  View,
  ViewParams,
} from "@common-module/app";
import { FCM } from "@common-module/social";
import {
  CreatorRoom,
  HashtagRoom,
  HashtagUtil,
  SFSignedUserManager,
} from "fsesf";
import FeedTab from "./tabs/FeedTab.js";
import PointsTab from "./tabs/PointsTab.js";
import SettingsTab from "./tabs/SettingsTab.js";
import TicketsTab from "./tabs/TicketsTab.js";
import TopicsTab from "./tabs/TopicsTab.js";
import UserDisplay from "./UserDisplay.js";

export default class App extends View {
  private currentTab: string | undefined;

  private navBar: AppNavBar;

  private feedTab: FeedTab | undefined;
  private ticketsTab: TicketsTab;
  private topicsTab: TopicsTab;
  private pointsTab: PointsTab;
  private settingsTab: SettingsTab;

  private roomSection: DomNode;
  private room: UserDisplay | HashtagRoom | CreatorRoom | undefined;

  constructor() {
    super();

    BodyNode.append(
      el(
        "section.app",
        this.navBar = new AppNavBar({
          id: "sofia-app-nav-bar",
          logo: el("img", { src: "/images/logo-navbar.png" }),
          menu: [{
            id: "feed",
            title: "Home",
            icon: new MaterialIcon("home"),
          }, {
            id: "tickets",
            title: "Tickets",
            icon: new MaterialIcon("confirmation_number"),
          }, {
            id: "topics",
            title: "Topics",
            icon: new MaterialIcon("tag"),
          }, {
            id: "points",
            title: "Points",
            icon: new MaterialIcon("star"),
          }, {
            id: "settings",
            title: SFSignedUserManager.user ? undefined : "Settings",
            icon: SFSignedUserManager.user
              ? el(".avatar")
              : new MaterialIcon("settings"),
            toFooter: SFSignedUserManager.user !== undefined,
          }],
        }),
        this.feedTab = new FeedTab(),
        this.ticketsTab = new TicketsTab(),
        this.topicsTab = new TopicsTab(),
        this.pointsTab = new PointsTab(),
        this.settingsTab = new SettingsTab(),
      ),
      this.roomSection = el("section.room", {
        "data-empty-message": "Select a ticket to start messaging",
      }),
    );

    if (SFSignedUserManager.user) {
      const icon = this.navBar.findMenu("settings")?.icon;
      if (icon) {
        AvatarUtil.selectLoadable(icon, [
          SFSignedUserManager.user.avatar_thumb,
          SFSignedUserManager.user.stored_avatar_thumb,
        ]);
      }
    }

    this.navBar.on("select", (id: string) => {
      BodyNode.deleteClass("feed", "tickets", "topics", "points", "settings")
        .addClass(id);
      [
        this.feedTab,
        this.ticketsTab,
        this.topicsTab,
        this.pointsTab,
        this.settingsTab,
      ].forEach((list) => list?.deactivate());
      if (id === "feed") {
        this.feedTab?.activate();
        if (this.currentTab === "feed") Router.go("/");
      } else if (id === "tickets") this.ticketsTab.activate();
      else if (id === "topics") this.topicsTab.activate();
      else if (id === "points") this.pointsTab.activate();
      else if (id === "settings") this.settingsTab.activate();
      this.currentTab = id;
    }).init();
  }

  public changeParams(params: ViewParams, uri: string, data?: any): void {
    const assetTabs = [
      this.ticketsTab,
      this.topicsTab,
      this.settingsTab,
    ];

    if (params.postId) {
      if (this.currentTab !== "feed") this.navBar.select("feed");
      this.feedTab?.loadThread(parseInt(params.postId), data);
      assetTabs.forEach((list) => list.deactiveAsset());
    } else {
      this.feedTab?.loadFeed();

      if (params.xUsername) {
        if (!(this.room instanceof UserDisplay)) {
          this.room?.delete();
          this.room = new UserDisplay(params.xUsername).appendTo(
            this.roomSection,
          );
        } else {
          this.room.loadUser(params.xUsername, data);
        }
        assetTabs.forEach((list) => list.deactiveAsset());
      } else if (params.creatorAddress) {
        if (!(this.room instanceof CreatorRoom)) {
          this.room?.delete();
          this.room = new CreatorRoom(params.creatorAddress, data).appendTo(
            this.roomSection,
          );
        } else {
          this.room.enter(params.creatorAddress, data);
        }
        assetTabs.forEach((list) =>
          list.activeAsset(undefined, params.creatorAddress!)
        );
      } else if (params.topic) {
        if (!(this.room instanceof HashtagRoom)) {
          this.room?.delete();
          this.room = new HashtagRoom(params.topic, data).appendTo(
            this.roomSection,
          );
        } else {
          this.room.enter(params.topic, data);
        }
        assetTabs.forEach((list) => list.activeAsset(undefined, params.topic!));
        this.checkAvailableTopic(params.topic);
      } else {
        this.room?.delete();
        this.room = undefined;
        assetTabs.forEach((list) => list.deactiveAsset());
      }
    }
  }

  private checkAvailableTopic(topic: string) {
    if (!HashtagUtil.available(topic)) {
      setTimeout(() => Router.goNoHistory("/"));
    } else {
      FCM.closeAllNotifications(`hashtag_${topic}`);
    }
  }
}
