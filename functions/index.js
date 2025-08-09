const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { onSchedule } = require("firebase-functions/v2/scheduler");

admin.initializeApp();

// 🚀 Notify the assigned collector when a user submits a pickup request
exports.notifyAssignedCollectorOnPickup = functions.firestore
  .document("pickup_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const collectorId = data.collectorId;

    if (!collectorId) {
      console.log("❌ No collector assigned to this request.");
      return null;
    }

    // Fetch collector's FCM token
    const collectorDoc = await admin
      .firestore()
      .collection("collectors")
      .doc(collectorId)
      .get();
    const fcmToken = collectorDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`❌ No FCM token found for collector ${collectorId}`);
      return null;
    }

    const message = {
      notification: {
        title: "📦 New Pickup Assigned",
        body: `You have a new pickup request from ${data.userName} in ${data.userTown}.`,
      },
      token: fcmToken,
    };

    await admin.messaging().send(message);
    console.log(`✅ Sent pickup request notification to collector ${collectorId}`);
    return null;
  });

// ✅ Notify user when collector accepts the pickup
exports.notifyUserOnAccepted = functions.firestore
  .document("pickup_requests/{requestId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "accepted" && after.status === "accepted") {
      const userId = after.userId;
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) return null;

      const message = {
        notification: {
          title: "✅ Pickup Accepted",
          body: "Your pickup request was accepted by a collector!",
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`✅ Notified user ${userId}`);
    }

    return null;
  });

// 💬 Notify on new chat messages
exports.notifyOnChatMessage = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const { senderId, text } = message;
    const chatId = context.params.chatId;

    // Get chat document to determine receiver
    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    const chat = chatDoc.data();

    if (!chat) {
      console.log(`❌ Chat ${chatId} not found.`);
      return null;
    }

    const userId = chat.userId;
    const collectorId = chat.collectorId;

    let receiverId = null;
    let receiverRole = "";
    if (senderId === userId) {
      receiverId = collectorId;
      receiverRole = "collector";
    } else if (senderId === collectorId) {
      receiverId = userId;
      receiverRole = "user";
    } else {
      console.log("❌ Sender is not part of this chat.");
      return null;
    }

    const receiverCollection = receiverRole === "user" ? "users" : "collectors";
    const receiverDoc = await admin.firestore().collection(receiverCollection).doc(receiverId).get();
    const fcmToken = receiverDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`❌ No FCM token found for ${receiverRole} ${receiverId}`);
      return null;
    }

    const messagePayload = {
      notification: {
        title: "💬 New Message",
        body: text || "You received a new message",
      },
      token: fcmToken,
    };

    await admin.messaging().send(messagePayload);
    console.log(`✅ Chat message notification sent to ${receiverRole} ${receiverId}`);
    return null;
  });

// ⏰ Collector pickup reminder (V2 syntax)
exports.sendCollectorPickupReminder = onSchedule("every 5 minutes", async () => {
  const now = admin.firestore.Timestamp.now();
  const THIRTY_MINUTES = 30 * 60 * 1000;

  const snapshot = await admin.firestore()
    .collection("pickup_requests")
    .where("status", "in", ["pending", "accepted"])
    .get();

  const reminderPromises = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const pickupDate = data.pickupDate?.toDate?.();
    if (!pickupDate) continue;

    const timeUntilPickup = pickupDate.getTime() - now.toDate().getTime();

    if (timeUntilPickup > 25 * 60 * 1000 && timeUntilPickup <= THIRTY_MINUTES) {
      const collectorId = data.collectorId;
      if (!collectorId) continue;

      const collectorDoc = await admin.firestore().collection("collectors").doc(collectorId).get();
      const fcmToken = collectorDoc.data()?.fcmToken;

      if (!fcmToken) continue;

      const message = {
        notification: {
          title: "⏰ Upcoming Pickup Reminder",
          body: `You have a pickup scheduled at ${pickupDate.toLocaleTimeString()} in ${data.userTown}.`,
        },
        token: fcmToken,
      };

      reminderPromises.push(admin.messaging().send(message));
      console.log(`🔔 Reminder scheduled for collector ${collectorId}`);
    }
  }

  await Promise.all(reminderPromises);
  return null;
});
