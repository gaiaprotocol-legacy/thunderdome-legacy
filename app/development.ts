import { ContractType } from "fsesf";
import initialize from "./initialize.js";

await initialize({
  dev: true,

  supabaseUrl: "https://dwzrduviqvesskxhtcbu.supabase.co",
  supabaseAnonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc",

  chains: {
    fantom: {
      id: 64165,
      symbol: "FTM",
      blockTime: 0.3,

      rpc: "https://rpcapi.sonic.fantom.network/",
      explorerUrl: "https://public-sonic.fantom.network",

      assetBaseDivider: 4n,
      assetFeePercent: 100000000000000000n,
    },
  },
  defaultChain: "fantom",
  contractAddresses: {
    fantom: { // fantom testnet
      [ContractType.CreatorTrade]: "0x14a4D7e4E3DF2AEF1464D84Bac9d27605eC78725",
      [ContractType.HashtagTrade]: "0x736239bDcc4A8C6fd1582EdEEada9857AAb4C0Bd",
    },
  },

  walletConnectProjectId: "f74f4ee05b268eaa4496e031ee339a75",
});
