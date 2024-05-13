import {
  AppInitializer,
  AuthUtil,
  BodyNode,
  BrowserInfo,
  Confirm,
  el,
  PolyfillUtil,
  Router,
  SplashLoader,
  Store,
} from "@common-module/app";
import {
  AndroidFcmNotification,
  FCM,
  PWAInstallOverlay,
} from "@common-module/social";
import {
  BlockTimeManager,
  BuyCreatorPopup,
  CoinbaseWalletManager,
  inject_fsesf_msg,
  LinkWalletPopup,
  MetaMaskManager,
  RealtimeActivityManager,
  SFEnv,
  SFOnlineUserManager,
  SFSignedUserManager,
  SignedUserAssetManager,
  WalletConnectManager,
} from "fsesf";
import { PMEnv } from "point-module";
import App from "./App.js";
import AppConfig from "./AppConfig.js";

export default async function initialize(config: AppConfig) {
  inject_fsesf_msg();

  SFEnv.init({
    dev: config.dev,
    serviceName: "Thunder Dome",
    serviceUrl: "https://thunderdome.so",

    overviewUrl: "https://x.com/ThunderDomeFTM", //TODO:
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
    hashtagOptions: { unit: "ticket", baseUri: "/topic" },
    additionalFeatures: ["follow"],
  });

  PMEnv.init({
    pointWeightPerPrice: 10,
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

  MetaMaskManager.init({
    name: "Thunder Dome",
    icon: "https://thunderdome.so/images/icon-192x192.png",
  }, config.chains);

  CoinbaseWalletManager.init({
    name: "Thunder Dome",
    icon: "https://thunderdome.so/images/icon-192x192.png",
  }, config.chains);

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
      SFSignedUserManager.init(),
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

  if (params.has("fcm_data")) {
    const fcmData = JSON.parse(params.get("fcm_data")!);
    if (fcmData.redirectTo) {
      if (BrowserInfo.isAndroid) {
        new AndroidFcmNotification(
          fcmData.title,
          fcmData.body,
          fcmData.redirectTo,
        );
      } else Router.go(fcmData.redirectTo);
    }
  }

  if (BrowserInfo.isWindows) BodyNode.addClass("windows");
  PolyfillUtil.fixMSWindowsEmojiDisplay();

  SFSignedUserManager.on("walletLinked", () => {
    const walletAddress = SFSignedUserManager.user?.wallet_address;
    if (walletAddress) {
      new Confirm({
        title: "Purchase Your Tickets",
        message:
          "Your wallet is now linked and your tickets are ready for purchase. Would you like to buy your tickets now?",
      }, () => {
        new BuyCreatorPopup(walletAddress, undefined);
      });
    }
  });
}
