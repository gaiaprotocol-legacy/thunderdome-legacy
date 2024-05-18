import { AppInitializer, Router } from "@common-module/app";
import App from "./App.js";
import AppConfig from "./AppConfig.js";

export default async function initialize(config: AppConfig) {
  AppInitializer.initialize(
    config.dev,
    config.supabaseUrl,
    config.supabaseAnonKey,
  );

  Router.route([
    "",
    "{xUsername}",
    "creator/{creatorAddress}",
    "post/{postId}",
    "topic/{topic}",
  ], App);
}
