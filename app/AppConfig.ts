import { ChainInfo } from "fsesf";

export default interface AppConfig {
  dev: boolean;

  supabaseUrl: string;
  supabaseAnonKey: string;
}
