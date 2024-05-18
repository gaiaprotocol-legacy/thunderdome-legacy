import {
  AvatarUtil,
  Button,
  ButtonType,
  DomNode,
  el,
  MaterialIcon,
} from "@common-module/app";
import { SFSignedUserManager } from "fsesf";
import UserSidePanel from "./UserSidePanel.js";

export default class TitleBarUserButton extends DomNode {
  constructor() {
    super(".title-bar-user-button");

    if (SFSignedUserManager.user) {
      const avatar = el(".avatar").appendTo(this);

      AvatarUtil.selectLoadable(avatar, [
        SFSignedUserManager.user.avatar_thumb,
        SFSignedUserManager.user.stored_avatar_thumb,
      ]);

      this.onDom("click", () => new UserSidePanel());
    } else {
      this.append(
        new Button({
          type: ButtonType.Circle,
          icon: new MaterialIcon("login"),
          click: () => SFSignedUserManager.signIn(),
        }),
      );
    }
  }
}
