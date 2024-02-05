import {
  AppInitializer,
  AuthUtil,
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
  MyCreatorsView,
  MyGroupsView,
  PointsView,
  TopicChatRoomView,
  TopicsView,
  WalletManager,
} from "fsesf";
import { fantom, fantomSonicTestnet, fantomTestnet } from "viem/chains";
import AboutView from "./AboutView.js";
import Config from "./Config.js";

inject_fsesf_msg();

MaterialIconSystem.launch();

export default async function initialize(config: Config) {
  Env.blockchain = {
    ...config.blockchain,
    symbolDisplay: "FTM",
  };
  Env.messageForWalletLinking = "Link Wallet to Thunder Dome";
  Env.defaultTopic = "thunderdome";

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

  Router.route(["", "about"], AboutView);

  Router.route([
    "creators",
    "creator/{creatorXUsername}",
    "creators/trending",
    "creators/top",
    "creators/new",
  ], CreatorsView);
  Router.route("creators", MyCreatorsView);

  Router.route(
    [
      "groups",
      "group/{groupId}",
      "groups/trending",
      "groups/top",
      "groups/new",
    ],
    GroupsView,
  );
  Router.route("groups", MyGroupsView);

  Router.route(["topics", "topic/{topic}"], TopicsView);
  Router.route(["topics", "topic/{topic}"], TopicChatRoomView);
  Router.route(["points", "points/leaderboard"], PointsView);

  AuthUtil.checkEmailAccess();
}
