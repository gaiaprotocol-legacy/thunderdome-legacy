import { ContractType } from "fsesf";
import initialize from "./initialize.js";

await initialize({
  dev: true,

  supabaseUrl: "https://dwzrduviqvesskxhtcbu.supabase.co",
  supabaseAnonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc",

  chains: {
    fantom: {
      id: 250,
      symbol: "FTM",
      blockTime: 2,

      rpc: "https://rpcapi.fantom.network",
      explorerUrl: "https://ftmscan.com",

      assetBaseDivider: 4n,
      assetFeePercent: 100000000000000000n,
    },
  },
  defaultChain: "fantom",
  contractAddresses: {
    fantom: { // fantom mainnet
      [ContractType.CreatorTrade]: "0xE949e6b48123C52A1294d09E856A5d9b335cbac3",
      [ContractType.HashtagTrade]: "0xEf92f2611Aa4730e31496DFaE40519d70a07185E",
    },
  },

  walletConnectProjectId: "f74f4ee05b268eaa4496e031ee339a75",
});
