import {
  AppInitializer,
  el,
  MaterialIconSystem,
  Router,
  SplashLoader,
} from "@common-module/app";
import {
  Env,
  FSESFLayout,
  FSESFSignedUserManager,
  inject_fsesf_msg,
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
}
