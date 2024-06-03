import { Activatable, Button, el } from "@common-module/app";
import { CommunityApplicationModal, CommunityList } from "fsesf";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class CommunitiesTab extends Activatable {
  private communityList: CommunityList;

  constructor() {
    super(".app-tab.communities-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Communities"),
      ),
      el(
        "main",
        this.communityList = new CommunityList(),
        el(
          "footer",
          new Button({
            title: "Apply for Community Channel",
            click: () => new CommunityApplicationModal(),
          }),
        ),
      ),
    );
  }

  public activeCommunity(communitySlug: string) {
    this.communityList.activeCommunity(communitySlug);
  }

  public deactiveCommunity() {
    this.communityList.deactiveCommunity();
  }
}
