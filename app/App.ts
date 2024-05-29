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
  Community,
  CommunityRoom,
  CreatorInfo,
  CreatorRoom,
  HashtagInfo,
  HashtagRoom,
  HashtagUtil,
  Post,
  SFSignedUserManager,
  SFUserPublic,
} from "fsesf";
import CommunitiesTab from "./tab/CommunitiesTab.js";
import FeedTab from "./tab/FeedTab.js";
import NotificationsTab from "./tab/NotificationsTab.js";
import PointsTab from "./tab/PointsTab.js";
import SettingsTab from "./tab/SettingsTab.js";
import TicketsTab from "./tab/TicketsTab.js";
import TopicsTab from "./tab/TopicsTab.js";
import PostViewer from "./viewer/PostViewer.js";
import UserViewer from "./viewer/UserViewer.js";

export default class App extends View {
  private navBar: AppNavBar;

  private feedTab: FeedTab;
  private ticketsTab: TicketsTab;
  private topicsTab: TopicsTab;
  private communitiesTab: CommunitiesTab;
  private pointsTab: PointsTab;
  private notificationsTab: NotificationsTab;
  private settingsTab: SettingsTab;

  private viewerSection: DomNode;
  private viewer:
    | UserViewer
    | PostViewer
    | CreatorRoom
    | HashtagRoom
    | CommunityRoom
    | undefined;

  constructor() {
    super();

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
              ? el(".avatar")
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
      this.viewerSection = el("section.viewer", {
        "data-empty-message": "Please select content to view.",
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
      if (id === "feed" && this.feedTab.activated) this.feedTab.refresh();
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
    const assetTabs = [this.ticketsTab, this.topicsTab, this.settingsTab];
    if (params.xUsername) {
      assetTabs.forEach((t) => t.deactiveAsset());
      this.openUserViewer(params.xUsername, data);
    } else if (params.postId) {
      assetTabs.forEach((t) => t.deactiveAsset());
      this.openPostViewer(parseInt(params.postId), data);
    } else if (params.creatorAddress) {
      assetTabs.forEach((t) =>
        t.activeAsset(undefined, params.creatorAddress!)
      );
      this.enterCreatorRoom(params.creatorAddress, data);
    } else if (params.topic) {
      assetTabs.forEach((t) => t.activeAsset(undefined, params.topic!));
      this.enterHashtagRoom(params.topic, data);
    } else if (params.communityId) {
      assetTabs.forEach((t) => t.deactiveAsset());
      this.enterCommunityRoom(parseInt(params.communityId), data);
    } else {
      this.viewer?.delete();
      this.viewer = undefined;
      assetTabs.forEach((t) => t.deactiveAsset());
    }
  }

  private openUserViewer(xUsername: string, user?: SFUserPublic): void {
    if (this.viewer instanceof UserViewer) {
      this.viewer.loadUser(xUsername, user);
    } else {
      this.viewer?.delete();
      this.viewer = new UserViewer(xUsername, user).appendTo(
        this.viewerSection,
      );
    }
  }

  private openPostViewer(postId: number, post?: Post): void {
    if (this.viewer instanceof PostViewer) {
      this.viewer.loadThread(postId, post);
    } else {
      this.viewer?.delete();
      this.viewer = new PostViewer(postId, post).appendTo(this.viewerSection);
    }
  }
  private enterCreatorRoom(
    creatorAddress: string,
    creatorInfo?: CreatorInfo,
  ): void {
    if (this.viewer instanceof CreatorRoom) {
      this.viewer.enter(creatorAddress, creatorInfo);
    } else {
      this.viewer?.delete();
      this.viewer = new CreatorRoom(creatorAddress, creatorInfo).appendTo(
        this.viewerSection,
      );
    }

    FCM.closeAllNotifications(`creator_${creatorAddress}`);
  }

  private enterHashtagRoom(topic: string, hashtagInfo?: HashtagInfo): void {
    if (this.viewer instanceof HashtagRoom) {
      this.viewer.enter(topic, hashtagInfo);
    } else {
      this.viewer?.delete();
      this.viewer = new HashtagRoom(topic, hashtagInfo).appendTo(
        this.viewerSection,
      );
    }

    if (HashtagUtil.available(topic)) {
      FCM.closeAllNotifications(`hashtag_${topic}`);
    } else setTimeout(() => Router.goNoHistory("/"));
  }

  private enterCommunityRoom(
    communityId: number,
    communityInfo?: Community,
  ): void {
    if (this.viewer instanceof CommunityRoom) {
      this.viewer.enter(communityId, communityInfo);
    } else {
      this.viewer?.delete();
      this.viewer = new CommunityRoom(communityId, communityInfo).appendTo(
        this.viewerSection,
      );
    }

    FCM.closeAllNotifications(`community_${communityId}`);
  }
}
