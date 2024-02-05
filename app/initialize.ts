import {
  AppInitializer,
  AuthUtil,
  el,
  MaterialIconSystem,
  Router,
  SplashLoader,
} from "@common-module/app";
import {
  BlockTimeManager,
  ContractType,
  CreatorChatRoomView,
  CreatorsView,
  Env,
  FSESFLayout,
  FSESFSignedUserManager,
  GroupChatRoomView,
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
  Env.keyName = "ticket";
  Env.blockchain = {
    ...config.blockchain,
    symbolDisplay: "FTM",
  };
  Env.contractAddresses = {
    [ContractType.CreatorKeys]: "0x298c92D5af8eEFA02b55dE45cb2337704af1b894",
    [ContractType.GroupKeys]: "0xe741b5DF37FB86eaB58F616dA0f4BfF10251C37a",
    [ContractType.TopicKeys]: "0xdf98e88944be3bc7C861135dAc617AD562EBB8D0",
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
    BlockTimeManager.init(0.5),
  ]);

  Router.route("**", FSESFLayout);

  Router.route(["", "about"], AboutView);

  Router.route([
    "creators",
    "creator/{creatorAddress}",
    "creators/trending",
    "creators/top",
    "creators/new",
  ], CreatorsView);
  Router.route(["creators", "creator/{creatorAddress}"], MyCreatorsView);
  Router.route(["creators", "creator/{creatorAddress}"], CreatorChatRoomView);

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
  Router.route(["groups", "group/{groupId}"], MyGroupsView);
  Router.route(["groups", "group/{groupId}"], GroupChatRoomView);

  Router.route(["topics", "topic/{topic}"], TopicsView);
  Router.route(["topics", "topic/{topic}"], TopicChatRoomView);
  Router.route(["points", "points/leaderboard"], PointsView);

  AuthUtil.checkEmailAccess();
}
