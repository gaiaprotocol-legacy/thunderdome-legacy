import {
  Button,
  ButtonType,
  DomNode,
  el,
  MaterialIcon,
  Router,
} from "@common-module/app";
import { Post, PostThread } from "fsesf";

export default class PostViewer extends DomNode {
  private main: DomNode;

  constructor(postId: number, post?: Post) {
    super(".post-viewer");
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
    this.main.domElement.setAttribute("data-empty-message", "No post found");
    this.loadThread(postId, post);
  }

  public async loadThread(postId: number, post?: Post) {
    this.main.empty().append(new PostThread(postId, post ? [post] : undefined));
  }
}
