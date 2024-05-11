import { Activatable, el } from "@common-module/app";
import { SignedUserChatRoomList } from "fsesf";

export default class ChatsTab extends Activatable {
  private chatRoomList: SignedUserChatRoomList;

  constructor() {
    super(".app-tab.chats-tab");
    this.append(
      el("header", el("h1", "Chats")),
      el("main", this.chatRoomList = new SignedUserChatRoomList()),
    );
  }

  public activeAsset(chain: string | undefined, assetId: string) {
    this.chatRoomList.activeAsset(chain, assetId);
  }

  public deactiveAsset() {
    this.chatRoomList.deactiveAsset();
  }
}
