import { Activatable, el, Tabs } from "@common-module/app";
import {
  ActivityList,
  NewAssetList,
  SignedUserChatRoomList,
  TopAssetList,
  TrendingAssetList,
} from "fsesf";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class TicketsTab extends Activatable {
  private tabs: Tabs;

  private holdingList: SignedUserChatRoomList;
  private trendingAssetList: TrendingAssetList;
  private topAssetList: TopAssetList;
  private newAssetList: NewAssetList;
  private activityList: ActivityList;

  constructor() {
    super(".app-tab.tickets-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Tickets"),
      ),
      this.tabs = new Tabs(undefined, [
        { id: "holding", label: "Holding" },
        { id: "trending", label: "Trending" },
        { id: "top", label: "Top" },
        { id: "new", label: "New" },
        { id: "activity", label: "Activity" },
      ]),
      el(
        "main",
        this.holdingList = new SignedUserChatRoomList(),
        this.trendingAssetList = new TrendingAssetList(),
        this.topAssetList = new TopAssetList(),
        this.newAssetList = new NewAssetList(),
        this.activityList = new ActivityList(),
      ),
    );

    this.tabs.on("select", (id: string) => {
      [
        this.holdingList,
        this.trendingAssetList,
        this.topAssetList,
        this.newAssetList,
        this.activityList,
      ].forEach((list) => list.hide());
      if (id === "holding") this.holdingList.show();
      else if (id === "trending") this.trendingAssetList.show();
      else if (id === "top") this.topAssetList.show();
      else if (id === "new") this.newAssetList.show();
      else if (id === "activity") this.activityList.show();
    }).init();
  }

  public activeAsset(chain: string | undefined, assetId: string) {
    this.holdingList.activeAsset(chain, assetId);
    this.trendingAssetList.activeAsset(chain, assetId);
    this.topAssetList.activeAsset(chain, assetId);
    this.newAssetList.activeAsset(chain, assetId);
  }

  public deactiveAsset() {
    this.holdingList.deactiveAsset();
    this.trendingAssetList.deactiveAsset();
    this.topAssetList.deactiveAsset();
    this.newAssetList.deactiveAsset();
  }

  public activate(): void {
    super.activate();
    this.tabs.emit("visible");
  }
}
