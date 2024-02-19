import {
  AppInitializer,
  AuthUtil,
  el,
  MaterialIconSystem,
  Router,
  SplashLoader,
} from "@common-module/app";
import {
  ESFEnv,
  ESFSignedUserManager,
  PointLeaderboardView,
  PointsView,
  SettingsView,
  WalletConnectManager
} from "esf-module";
import {
  BlockTimeManager,
  ContractType,
  CreatorChatRoomView,
  CreatorsView,
  FSESFEnv,
  FSESFLayout,
  GroupChatRoomView,
  GroupsView,
  HashtagChatRoomView,
  HashtagsView,
  inject_fsesf_msg,
  MyCreatorsView,
  MyGroupsView,
  NewCreatorsView,
  NewGroupsView,
  TopCreatorsView,
  TopGroupsView,
  TrendingCreatorsView,
  TrendingGroupsView,
} from "fsesf";
import { fantom, fantomSonicTestnet, fantomTestnet } from "viem/chains";
import AboutView from "./AboutView.js";
import Config from "./Config.js";
import TDMyPointsView from "./TDMyPointsView.js";

inject_fsesf_msg();

MaterialIconSystem.launch();

export default async function initialize(config: Config) {
  ESFEnv.domain = "thunderdome.so";
  ESFEnv.keyName = "ticket";
  ESFEnv.messageForWalletLinking = "Link Wallet to Thunder Dome";
  ESFEnv.Layout = FSESFLayout;

  FSESFEnv.blockchain = {
    ...config.blockchain,
    symbolDisplay: "FTM",
  };
  FSESFEnv.contractAddresses = {
    [ContractType.CreatorKeys]: "0x298c92D5af8eEFA02b55dE45cb2337704af1b894",
    [ContractType.GroupKeys]: "0xe741b5DF37FB86eaB58F616dA0f4BfF10251C37a",
    [ContractType.HashtagKeys]: "0x23e0035F44cB5Bb4fb83e3F4CA413DB39c6f7BF0",
  };
  FSESFEnv.defaultHashtag = "thunderdome";

  AppInitializer.initialize(
    config.supabaseUrl,
    config.supabaseAnonKey,
    config.dev,
  );

  WalletConnectManager.init(config.walletConnectProjectId, [
    fantom,
    fantomTestnet,
    fantomSonicTestnet,
  ]);

  await SplashLoader.load(el("img", { src: "/images/logo-transparent.png" }), [
    ESFSignedUserManager.fetchUserOnInit(),
    BlockTimeManager.init(0.3),
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
  Router.route("creators/trending", TrendingCreatorsView);
  Router.route("creators/top", TopCreatorsView);
  Router.route("creators/new", NewCreatorsView);

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
  Router.route("groups/trending", TrendingGroupsView);
  Router.route("groups/top", TopGroupsView);
  Router.route("groups/new", NewGroupsView);

  Router.route(["hashtags", "hashtag/{hashtag}"], HashtagsView);
  Router.route(["hashtags", "hashtag/{hashtag}"], HashtagChatRoomView);

  Router.route(["points", "points/leaderboard"], PointsView);
  Router.route("points", TDMyPointsView);
  Router.route("points/leaderboard", PointLeaderboardView);

  Router.route("settings", SettingsView);

  AuthUtil.checkEmailAccess();
}
