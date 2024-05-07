import {
  AppInitializer,
  AuthUtil,
  BodyNode,
  BrowserInfo,
  el,
  PolyfillUtil,
  Router,
  SplashLoader,
  Store,
} from "@common-module/app";
import { FCM, PWAInstallOverlay } from "@common-module/social";
import {
  BlockTimeManager,
  HashtagSubscribeManager,
  inject_fsesf_msg,
  LinkWalletPopup,
  RealtimeActivityManager,
  SFEnv,
  SFOnlineUserManager,
  SFSignedUserManager,
  SignedUserAssetManager,
  WalletConnectManager,
} from "fsesf";
import App from "./App.js";
import AppConfig from "./AppConfig.js";
import WelcomePopup from "./WelcomePopup.js";

export default async function initialize(config: AppConfig) {
  inject_fsesf_msg();

  SFEnv.init({
    dev: config.dev,
    serviceName: "Thunder Dome",
    serviceUrl: "https://thunderdome.so",
    overviewUrl: "", //TODO:
    socialUrls: {
      x: "https://x.com/ThunderDomeFTM",
    },
    messageForWalletLinking: "Link Wallet to Thunder Dome",

    chains: config.chains,
    defaultChain: config.defaultChain,
    contractAddresses: config.contractAddresses,

    assetName: "ticket",
    userBaseUri: "",
    creatorOptions: { unit: "ticket", baseUri: "/creator" },
    hashtagOptions: { unit: "topic", baseUri: "/topic" },
  });

  AppInitializer.initialize(
    config.dev,
    config.supabaseUrl,
    config.supabaseAnonKey,
  );

  if (
    BrowserInfo.isMobileDevice && !BrowserInfo.installed &&
    !(window as any).ethereum && location.pathname === "/"
  ) {
    new PWAInstallOverlay(SFEnv.serviceName, SFEnv.overviewUrl).appendTo(
      BodyNode,
    );
  } else {
    //TODO: 메시지 변경하고 열기 WelcomePopup.launch();
  }

  WalletConnectManager.init({
    projectId: config.walletConnectProjectId,
    name: "Thunder Dome",
    description: "Social Fi on Fantom",
    icon: "https://thunderdome.so/images/icon-192x192.png",
  }, config.chains);

  FCM.init(
    {
      apiKey: "AIzaSyCIUXHJ8e-Z9V9qjIa6LqPLNth5ACv-BRY",
      authDomain: "thunder-dome.firebaseapp.com",
      projectId: "thunder-dome",
      storageBucket: "thunder-dome.appspot.com",
      messagingSenderId: "1084442345242",
      appId: "1:1084442345242:web:0ced2bb4ef2395588436a3",
      measurementId: "G-1P6VSYWPX8",
    },
    "BMN8rlpisL71SRy6EgCO1bGwldNs471mpvPqxzPm0icl2KIe5W-Qf8iHTnWurO5m3sVPWzxyMOfVW2K22DTQW3E",
  );

  await SplashLoader.load(
    el("img", { src: "/images/logo-transparent.png" }),
    [
      BlockTimeManager.init(),
      SFSignedUserManager.init((userId) =>
        HashtagSubscribeManager.loadSignedUserSubscribedHashtags(
          userId,
        )
      ),
    ],
  );

  SFOnlineUserManager.init();
  SignedUserAssetManager.init();
  RealtimeActivityManager.init();

  const params = new URLSearchParams(location.search);
  if (params.has("from")) new Store("referral").set("from", params.get("from"));

  Router.route(
    ["", "topic/{topic}", "creator/{creatorAddress}", "{xUsername}"],
    App,
  );

  AuthUtil.checkEmailAccess();

  if (SFSignedUserManager.signed && !SFSignedUserManager.walletLinked) {
    new LinkWalletPopup();
  }

  navigator.serviceWorker.addEventListener("message", (event) => {
    if (event.data.action === "notificationclick") {
      const fcmData = event.data.data?.FCM_MSG?.data;
      if (fcmData?.redirectTo) Router.go(fcmData.redirectTo);
    }
  });

  if (BrowserInfo.isWindows) BodyNode.addClass("windows");
  PolyfillUtil.fixMSWindowsEmojiDisplay();
}
