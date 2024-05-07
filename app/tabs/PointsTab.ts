import {
  Activatable,
  Button,
  ButtonType,
  el,
  MaterialIcon,
} from "@common-module/app";
import { PointLeaderboardModal, PointSection } from "point-module";

export default class PointsTab extends Activatable {
  constructor() {
    super(".app-tab.points-tab");
    this.append(
      el(
        "header",
        el("h1", "Points"),
        el(
          ".right",
          new Button({
            type: ButtonType.Circle,
            icon: new MaterialIcon("leaderboard"),
            click: () => new PointLeaderboardModal(),
          }),
        ),
      ),
      el("main", new PointSection()),
    );
  }
}
