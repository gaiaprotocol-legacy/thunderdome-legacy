import {
  Button,
  ButtonType,
  DomNode,
  el,
  LoadingSpinner,
  MaterialIcon,
  Router,
} from "@common-module/app";
import { addUserOrCreatorComponents, SFUserPublic, SFUserService } from "fsesf";

export default class UserDisplay extends DomNode {
  private main: DomNode;

  constructor(xUsername: string, user?: SFUserPublic) {
    super(".user-display");
    this.append(
      el(
        "header",
        new Button({
          tag: ".back",
          type: ButtonType.Circle,
          icon: new MaterialIcon("arrow_back"),
          click: () =>
            history.length === 1 ? Router.goNoHistory("/") : history.back(),
        }),
      ),
      this.main = el("main"),
    );
    this.main.domElement.setAttribute("data-empty-message", "No user found");
    this.loadUser(xUsername, user);
  }

  private renderUser(user: SFUserPublic) {
    this.main.empty();
    const container = el(".user-info-container").appendTo(this.main);
    addUserOrCreatorComponents(container, user);
  }

  public async loadUser(xUsername: string, user?: SFUserPublic) {
    if (user) this.renderUser(user);
    else {
      this.main.empty().append(el(".loading-container", new LoadingSpinner()));
      const user = await SFUserService.fetchByXUsername(xUsername);
      if (user) this.renderUser(user);
      else this.main.empty();
    }
  }
}
