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



exports.reassignCollectorOnDuePickup = functions.pubsub.schedule("every 5 minutes").onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();

  try {
    // 1️⃣ Get pending requests whose pickupDate is due or past
    const pickupRequestsSnapshot = await admin.firestore()
      .collection("pickup_requests")
      .where("status", "==", "pending")
      .where("pickupDate", "<=", now)
      .get();

    if (pickupRequestsSnapshot.empty) {
      console.log("No due pickup requests found");
      return null;
    }

    for (const doc of pickupRequestsSnapshot.docs) {
      const requestData = doc.data();
      const oldPickupDate = requestData.pickupDate;

      // 2️⃣ Find a different active collector in the same town
      const collectorsSnapshot = await admin.firestore()
        .collection("collectors")
        .where("town", "==", requestData.town)
        .where("isActive", "==", true)
        .where(admin.firestore.FieldPath.documentId(), "!=", requestData.collectorId)
        .limit(1)
        .get();

      if (collectorsSnapshot.empty) {
        console.log(`No active collector found for request ${doc.id}`);
        continue;
      }

      const newCollector = collectorsSnapshot.docs[0];
      const newCollectorId = newCollector.id;

      // 3️⃣ Update request with new collector and extend pickupDate by 2 hours
      const newPickupDate = admin.firestore.Timestamp.fromDate(
        oldPickupDate.toDate().addHours(2)
      );

      await doc.ref.update({
        collectorId: newCollectorId,
        pickupDate: newPickupDate,
        reassignedAt: admin.firestore.Timestamp.now(),
      });

      console.log(`Pickup request ${doc.id} reassigned to collector ${newCollectorId}`);
    }

    return null;
  } catch (error) {
    console.error("Error reassigning collector:", error);
    return null;
  }
});

// 🔹 Helper to add hours to Date object
Date.prototype.addHours = function (h) {
  this.setHours(this.getHours() + h);
  return this;
};

exports.notifyUserOnInProgress = functions.firestore
  .document("pickup_requests/{requestId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== "in_progress" && after.status === "in_progress") {
      const userId = after.userId;
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) return null;

      const message = {
        notification: {
          title: "🚛 Pickup In Progress",
          body: "Your pickup is on the way! You can now track your collector.",
        },
        token: fcmToken,
      };

      await admin.messaging().send(message);
      console.log(`🚛 Notified user ${userId} - pickup in progress`);
    }

    return null;
  });
exports.assignCollectorToPendingRequests = functions.firestore
  .document("collectors/{collectorId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only run if collector just became active
    if (!before.isActive && after.isActive) {
      const collectorId = context.params.collectorId;
      const collectorName = after.name || "Unknown Collector";
      const collectorTown = after.town;

      // Find pending requests in the same town with no assigned collector
      const pendingRequests = await admin.firestore()
        .collection("pickup_requests")
        .where("status", "==", "pending")
        .where("userTown", "==", collectorTown)
        .where("collectorId", "==", "")
        .get();

      if (pendingRequests.empty) {
        console.log(`No pending requests to assign for collector ${collectorId}`);
        return null;
      }

      // Assign this collector to each pending request
      const batch = admin.firestore().batch();
      pendingRequests.docs.forEach(doc => {
        batch.update(doc.ref, {
          collectorId: collectorId,
          collectorName: collectorName,
          assignedAt: admin.firestore.Timestamp.now(),
        });
      });

      await batch.commit();
      console.log(`Assigned collector ${collectorId} to ${pendingRequests.size} pending requests.`);
    }

    return null;
  });