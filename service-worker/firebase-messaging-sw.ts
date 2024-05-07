import { initializeApp } from "firebase/app";
import { getMessaging } from "firebase/messaging/sw";

const firebaseApp = initializeApp({
  apiKey: "AIzaSyCIUXHJ8e-Z9V9qjIa6LqPLNth5ACv-BRY",
  authDomain: "thunder-dome.firebaseapp.com",
  projectId: "thunder-dome",
  storageBucket: "thunder-dome.appspot.com",
  messagingSenderId: "1084442345242",
  appId: "1:1084442345242:web:0ced2bb4ef2395588436a3",
  measurementId: "G-1P6VSYWPX8",
});

self.addEventListener("notificationclick", (event: any) => {
  console.log("On notification click: ", event.notification);
  event.notification.close();

  event.waitUntil(
    (self as any).clients
      .matchAll({ type: "window", includeUncontrolled: true })
      .then((clientList: any) => {
        for (const client of clientList) {
          console.log(client);
          if ("focus" in client) {
            client.postMessage({
              action: "notificationclick",
              data: event.notification.data,
            });
            return client.focus();
          }
        }
        if ((self as any).clients.openWindow) {
          const fcmData = event.notification.data?.FCM_MSG?.data;
          return (self as any).clients.openWindow(fcmData.redirectTo);
        }
      }),
  );
});

getMessaging(firebaseApp);

console.log("Firebase messaging service worker loaded");
