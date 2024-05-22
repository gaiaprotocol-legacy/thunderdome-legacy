import { Activatable, ComponentUtil, DomNode, el } from "@common-module/app";
import { LoginRequired, NotificationList, SFSignedUserManager } from "fsesf";
import TitleBarUserButton from "../component/TitleBarUserButton.js";

export default class NotificationsTab extends Activatable {
  private main: DomNode;
  private notificationList: NotificationList | undefined;

  constructor() {
    super(".app-tab.notifications-tab");
    this.append(
      el(
        "header",
        el(".left", new TitleBarUserButton()),
        el("h1", "Notifications"),
      ),
      this.main = el(
        "main",
        SFSignedUserManager.signed
          ? this.notificationList = new NotificationList()
          : new LoginRequired(),
      ),
    );

    ComponentUtil.enablePullToRefresh(this.main, () => this.refresh());
  }

  private refresh() {
    this.notificationList?.loadNotifications();
  }
}
