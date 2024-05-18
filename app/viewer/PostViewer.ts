import { DomNode } from "@common-module/app";
import { Post } from "fsesf";

export default class PostViewer extends DomNode {
  constructor(postId: number, post?: Post) {
    super(".post-viewer");
  }

  public async loadThread(postId: number, post?: Post) {
  }
}
