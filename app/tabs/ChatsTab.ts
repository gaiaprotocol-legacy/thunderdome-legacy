import { Activatable, el } from "@common-module/app";
import { SignedUserChatRoomList } from "fsesf";

export default class ChatsTab extends Activatable {
  constructor() {
    super(".app-tab.chats-tab");
    this.append(
      el("header", el("h1", "Chats")),
      el("main", new SignedUserChatRoomList()),
    );
  }

  public activeCreator(creatorAddress: string) {
  }

  public deactiveCreator() {
  }
}
