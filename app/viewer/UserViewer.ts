import { DomNode } from "@common-module/app";
import { SFUserPublic } from "fsesf";

export default class UserViewer extends DomNode {
  constructor(xUsername: string, user?: SFUserPublic) {
    super(".user-viewer");
  }

  public async loadUser(xUsername: string, user?: SFUserPublic) {
  }
}
