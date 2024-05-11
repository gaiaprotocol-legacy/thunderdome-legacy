import {
  Activatable,
  Button,
  ButtonType,
  el,
  MaterialIcon,
} from "@common-module/app";
import { HashtagLeaderboardModal, HashtagList, HashtagSearchBar } from "fsesf";

export default class TopicsTab extends Activatable {
  private hashtagList: HashtagList;

  constructor() {
    super(".app-tab.topics-tab");
    this.append(
      el(
        "header",
        el("h1", "Topics"),
        el(
          ".right",
          new Button({
            type: ButtonType.Circle,
            icon: new MaterialIcon("leaderboard"),
            click: () => new HashtagLeaderboardModal(),
          }),
        ),
      ),
      new HashtagSearchBar(),
      el("main", this.hashtagList = new HashtagList()),
    );
  }

  public activeAsset(chain: string | undefined, assetId: string) {
    this.hashtagList.activeHashtag(assetId);
  }

  public deactiveAsset() {
    this.hashtagList.deactiveHashtag();
  }
}
