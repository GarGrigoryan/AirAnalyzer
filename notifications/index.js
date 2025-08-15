const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.database();

exports.sendNotificationIfOffline = functions.pubsub
    .schedule("every 1 minutes") // check every minute
    .onRun(async (context) => {
      console.log("🔔 Running notification check...");

      try {
        const devicesSnapshot = await db.ref("devices").get();
        if (!devicesSnapshot.exists()) {
          console.log("No devices found.");
          return null;
        }

        const now = Math.floor(Date.now() / 1000);

        devicesSnapshot.forEach((deviceSnap) => {
          const deviceId = deviceSnap.key;
          const sensors = deviceSnap.child("sensors");
          const fcmToken = deviceSnap.child("fcmToken").val();

          if (!fcmToken) {
            console.log(`No FCM token for device ${deviceId}`);
            return;
          }

          const timestamp = sensors.child("timestamp").val();
          if (!timestamp) {
            console.log(`No timestamp for device ${deviceId}`);
            return;
          }

          const diff = now - timestamp;
          if (diff > 5 * 60) {
            const message = {
              token: fcmToken,
              notification: {
                title: "Device Offline",
                body: `Device ${deviceId} is offline for more than 5 minutes.`,
              },
            };

            admin
                .messaging()
                .send(message)
                .then((resp) => console.log("✅ Notification sent:", resp))
                .catch((err) => console.error("Error", err));
          }
        });
      } catch (err) {
        console.error("❌ Error checking devices:", err);
      }

      return null;
    });
