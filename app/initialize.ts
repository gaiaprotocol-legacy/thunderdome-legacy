import { AppInitializer, MaterialIconSystem, Router } from "@common-module/app";
import { FSESFLayout, inject_fsesf_msg } from "fsesf";
import Config from "./Config.js";

inject_fsesf_msg();

MaterialIconSystem.launch();

export default async function initialize(config: Config) {
  AppInitializer.initialize(
    config.supabaseUrl,
    config.supabaseAnonKey,
    config.dev,
  );

  Router.route("**", FSESFLayout);
}
