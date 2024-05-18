import { SidePanel } from "@common-module/app";
import { MePanel } from "fsesf";

export default class UserSidePanel extends SidePanel {
  constructor() {
    super(".user-side-panel", { toLeft: true, hasHidingAnimation: true });
    this.container.append(new MePanel());
  }
}
