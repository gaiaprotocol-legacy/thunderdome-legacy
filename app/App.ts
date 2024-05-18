import {
  AppNavBar,
  AvatarUtil,
  BodyNode,
  el,
  MaterialIcon,
  View,
  ViewParams,
} from "@common-module/app";
import { SFSignedUserManager } from "fsesf";
import CommunitiesTab from "./tab/CommunitiesTab.js";
import FeedTab from "./tab/FeedTab.js";
import NotificationsTab from "./tab/NotificationsTab.js";
import PointsTab from "./tab/PointsTab.js";
import SettingsTab from "./tab/SettingsTab.js";
import TicketsTab from "./tab/TicketsTab.js";
import TopicsTab from "./tab/TopicsTab.js";

export default class App extends View {
  private navBar: AppNavBar;

  private feedTab: FeedTab;
  private ticketsTab: TicketsTab;
  private topicsTab: TopicsTab;
  private communitiesTab: CommunitiesTab;
  private pointsTab: PointsTab;
  private notificationsTab: NotificationsTab;
  private settingsTab: SettingsTab;

  constructor() {
    super();

    let avatar;
    BodyNode.append(
      el(
        "section.app",
        this.navBar = new AppNavBar({
          id: "thunderdome-app-nav-bar",
          logo: el("img", { src: "/images/logo-navbar.png" }),
          menu: [{
            id: "feed",
            icon: new MaterialIcon("home"),
          }, {
            id: "tickets",
            icon: new MaterialIcon("confirmation_number"),
          }, {
            id: "topics",
            icon: new MaterialIcon("tag"),
          }, {
            id: "communities",
            icon: new MaterialIcon("group"),
          }, {
            id: "points",
            icon: new MaterialIcon("star"),
          }, {
            id: "notifications",
            icon: new MaterialIcon("notifications"),
          }, {
            id: "settings",
            icon: SFSignedUserManager.user
              ? avatar = el(".avatar")
              : new MaterialIcon("settings"),
            toFooter: SFSignedUserManager.user !== undefined,
          }],
        }),
        this.feedTab = new FeedTab(),
        this.ticketsTab = new TicketsTab(),
        this.topicsTab = new TopicsTab(),
        this.communitiesTab = new CommunitiesTab(),
        this.pointsTab = new PointsTab(),
        this.notificationsTab = new NotificationsTab(),
        this.settingsTab = new SettingsTab(),
      ),
      el("section.viewer", {
        "data-empty-message": "Please select content to view.",
      }),
    );

    if (avatar && SFSignedUserManager.user) {
      AvatarUtil.selectLoadable(avatar, [
        SFSignedUserManager.user.avatar_thumb,
        SFSignedUserManager.user.stored_avatar_thumb,
      ]);
    }

    this.navBar.on("select", (id: string) => {
      [
        this.feedTab,
        this.ticketsTab,
        this.topicsTab,
        this.communitiesTab,
        this.pointsTab,
        this.notificationsTab,
        this.settingsTab,
      ].forEach((list) => list.deactivate());
      if (id === "feed") this.feedTab.activate();
      else if (id === "tickets") this.ticketsTab.activate();
      else if (id === "topics") this.topicsTab.activate();
      else if (id === "communities") this.communitiesTab.activate();
      else if (id === "points") this.pointsTab.activate();
      else if (id === "notifications") this.notificationsTab.activate();
      else if (id === "settings") this.settingsTab.activate();
    }).init();
  }

  public changeParams(params: ViewParams, uri: string, data?: any): void {
    console.log(params, uri, data);
  }
}
