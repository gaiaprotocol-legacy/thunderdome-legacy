import { ContractType } from "fsesf";
import initialize from "./initialize.js";

await initialize({
  dev: false,

  supabaseUrl: "https://dwzrduviqvesskxhtcbu.supabase.co",
  supabaseAnonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc",

  chains: {
    fantom: {
      id: 250,
      symbol: "FTM",
      blockTime: 2,

      rpc: "https://rpc.ankr.com/fantom/",
      explorerUrl: "https://ftmscan.com",

      assetBaseDivider: 4n,
      assetFeePercent: 100000000000000000n,
    },
  },
  defaultChain: "fantom",
  contractAddresses: {
    fantom: { // fantom mainnet
      [ContractType.CreatorTrade]: "0x92f0B3c9542F48E1c01E5c7fd1020fF7683a4a69",
      [ContractType.HashtagTrade]: "0xEf92f2611Aa4730e31496DFaE40519d70a07185E",
    },
  },

  walletConnectProjectId: "f74f4ee05b268eaa4496e031ee339a75",
});
