import initialize from "./initialize.js";
await initialize({
  dev: false,

  supabaseUrl: "https://dwzrduviqvesskxhtcbu.supabase.co",
  supabaseAnonKey:
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc",

  blockchain: {
    chainId: 64165,
    name: "Fantom Sonic Builders Testnet",
    rpc: "https://rpc.sonic.fantom.network/",
  },
  walletConnectProjectId: "2c4277f91efc93ebdb6feedbbc322e91",
});
