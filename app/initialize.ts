import {
  AppInitializer,
  el,
  MaterialIconSystem,
  Router,
  SplashLoader,
} from "@common-module/app";
import {
  CreatorsView,
  Env,
  FSESFLayout,
  FSESFSignedUserManager,
  GroupsView,
  inject_fsesf_msg,
  TopicsView,
  WalletManager,
} from "fsesf";
import { fantom, fantomSonicTestnet, fantomTestnet } from "viem/chains";
import Config from "./Config.js";

inject_fsesf_msg();

MaterialIconSystem.launch();

export default async function initialize(config: Config) {
  Env.blockchain = config.blockchain;
  Env.messageForWalletLinking = "Link Wallet to Thunder Dome";

  AppInitializer.initialize(
    config.supabaseUrl,
    config.supabaseAnonKey,
    config.dev,
  );

  WalletManager.init(config.walletConnectProjectId, [
    fantom,
    fantomTestnet,
    fantomSonicTestnet,
  ]);

  await SplashLoader.load(el("img", { src: "/images/logo-transparent.png" }), [
    FSESFSignedUserManager.fetchUserOnInit(),
  ]);

  Router.route("**", FSESFLayout);
  Router.route([
    "creators",
    "creators/trending",
    "creators/top",
    "creators/new",
  ], CreatorsView);
  Router.route(
    ["groups", "groups/trending", "groups/top", "groups/new"],
    GroupsView,
  );
  Router.route("topics", TopicsView);
}
