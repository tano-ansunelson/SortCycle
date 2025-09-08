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

    // Check if this is an emergency pickup
    const isEmergency = data.isEmergency === true;
    
    const message = {
      notification: {
        title: isEmergency ? "🚨 EMERGENCY Pickup Assigned" : "📦 New Pickup Assigned",
        body: isEmergency 
          ? `🚨 EMERGENCY: ${data.userName} needs urgent pickup in ${data.userTown}!`
          : `You have a new pickup request from ${data.userName} in ${data.userTown}.`,
      },
      token: fcmToken,
      android: {
        priority: isEmergency ? "high" : "normal",
        notification: {
          priority: isEmergency ? "high" : "normal",
          sound: isEmergency ? "default" : "default",
          channelId: isEmergency ? "emergency_channel" : "default_channel",
        },
      },
      apns: {
        headers: {
          "apns-priority": isEmergency ? "10" : "5",
        },
        payload: {
          aps: {
            sound: isEmergency ? "default" : "default",
            badge: 1,
          },
        },
      },
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
        .where("town", "==", requestData.userTown)
        .where("isActive", "==", true)
        .where(admin.firestore.FieldPath.documentId(), "!=", requestData.collectorId)
        .get();

      if (collectorsSnapshot.empty) {
        console.log(`No active collector found for request ${doc.id}`);
        continue;
      }

      // Randomly select a collector instead of always picking the first one
      const randomIndex = Math.floor(Math.random() * collectorsSnapshot.size);
      const newCollector = collectorsSnapshot.docs[randomIndex];
      const newCollectorId = newCollector.id;

      console.log(`🎯 Randomly selected new collector ${newCollectorId} from ${collectorsSnapshot.size} available collectors for request ${doc.id}`);

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

      console.log(`🔄 Collector ${collectorId} became active in ${collectorTown}`);

      // Debug: Check if collector has town field
      if (!collectorTown) {
        console.log(`❌ Collector ${collectorId} missing town field`);
        return null;
      }

      // Find pending requests in the same town with no assigned collector
      console.log(`🔍 Looking for pending requests in town: "${collectorTown}"`);
      console.log(`🔍 Query: status == "pending" AND userTown == "${collectorTown}" AND collectorId in ["", null]`);
      
      const pendingRequests = await admin.firestore()
        .collection("pickup_requests")
        .where("status", "==", "pending")
        .where("userTown", "==", collectorTown)
        .where("collectorId", "in", ["", null])
        .orderBy("createdAt", "asc") // Assign oldest requests first
        .get();

      console.log(`📊 Found ${pendingRequests.size} pending requests in ${collectorTown}`);

      if (pendingRequests.empty) {
        console.log(`No pending requests to assign for collector ${collectorId} in ${collectorTown}`);
        return null;
      }

      // Assign this collector to each pending request
      const batch = admin.firestore().batch();
      pendingRequests.docs.forEach(doc => {
        const requestData = doc.data();
        console.log(`📝 Assigning request ${doc.id} (${requestData.userName} in ${requestData.userTown}) to collector ${collectorId}`);
        
        batch.update(doc.ref, {
          collectorId: collectorId,
          collectorName: collectorName,
          assignedAt: admin.firestore.Timestamp.now(),
          status: "pending", // Keep as pending until collector accepts
        });
      });

      await batch.commit();
      console.log(`✅ Successfully assigned collector ${collectorId} to ${pendingRequests.size} pending requests in ${collectorTown}`);
    }

    return null;
  });

// 🔄 Handle when collector becomes inactive - reassign their pending requests
exports.handleCollectorInactive = functions.firestore
  .document("collectors/{collectorId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only run if collector just became inactive
    if (before.isActive && !after.isActive) {
      const collectorId = context.params.collectorId;
      const collectorTown = after.town;

      console.log(`🔄 Collector ${collectorId} became inactive in ${collectorTown}`);

      if (!collectorTown) {
        console.log(`❌ Collector ${collectorId} missing town field`);
        return null;
      }

      // Find all pending requests assigned to this collector
      const assignedRequests = await admin.firestore()
        .collection("pickup_requests")
        .where("status", "==", "pending")
        .where("collectorId", "==", collectorId)
        .get();

      if (assignedRequests.empty) {
        console.log(`No pending requests to reassign for inactive collector ${collectorId}`);
        return null;
      }

      console.log(`📋 Found ${assignedRequests.size} requests to reassign from inactive collector ${collectorId}`);

      // Find another active collector in the same town
      const otherCollectors = await admin.firestore()
        .collection("collectors")
        .where("isActive", "==", true)
        .where("town", "==", collectorTown)
        .where(admin.firestore.FieldPath.documentId(), "!=", collectorId)
        .get();

      if (otherCollectors.empty) {
        console.log(`⚠️ No other active collectors found in ${collectorTown}, requests will remain unassigned`);
        // Remove collector assignment but keep requests pending
        const batch = admin.firestore().batch();
        assignedRequests.docs.forEach(doc => {
          batch.update(doc.ref, {
            collectorId: "",
            collectorName: "",
            assignedAt: null,
          });
        });
        await batch.commit();
        console.log(`🔄 Removed collector assignment from ${assignedRequests.size} requests`);
        return null;
      }

      // Randomly select another active collector instead of always picking the first one
      const randomIndex = Math.floor(Math.random() * otherCollectors.size);
      const newCollector = otherCollectors.docs[randomIndex];
      const newCollectorId = newCollector.id;
      const newCollectorName = newCollector.data().name || "Unknown Collector";

      console.log(`🎯 Randomly selected new collector ${newCollectorId} (${newCollectorName}) from ${otherCollectors.size} available collectors in ${collectorTown}`);

      const batch = admin.firestore().batch();
      assignedRequests.docs.forEach(doc => {
        batch.update(doc.ref, {
          collectorId: newCollectorId,
          collectorName: newCollectorName,
          assignedAt: admin.firestore.Timestamp.now(),
          reassignedAt: admin.firestore.Timestamp.now(),
        });
      });

      await batch.commit();
      console.log(`✅ Reassigned ${assignedRequests.size} requests from inactive collector ${collectorId} to active collector ${newCollectorId}`);
    }

    return null;
  });

// 🆕 New function: Auto-assign collector when request is created
exports.autoAssignCollectorOnRequest = functions.firestore
  .document("pickup_requests/{requestId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Only process if no collector is assigned
    if (data.collectorId && data.collectorId !== '' && data.collectorId !== null) {
      console.log(`Request ${context.params.requestId} already has collector assigned`);
      return null;
    }

    const userTown = data.userTown;
    if (!userTown) {
      console.log(`Request ${context.params.requestId} missing userTown`);
      return null;
    }

    try {
      console.log(`🔍 Looking for active collectors in town: "${userTown}"`);
      
      // Find active collectors in the same town
      const collectorsSnapshot = await admin.firestore()
        .collection("collectors")
        .where("isActive", "==", true)
        .where("town", "==", userTown)
        .get();

      // Debug: Log the query details
      console.log(`🔍 Query: isActive == true AND town == "${userTown}"`);

      console.log(`📊 Found ${collectorsSnapshot.size} active collectors in ${userTown}`);

      if (!collectorsSnapshot.empty) {
        // Randomly select a collector instead of always picking the first one
        const randomIndex = Math.floor(Math.random() * collectorsSnapshot.size);
        const collector = collectorsSnapshot.docs[randomIndex];
        const collectorId = collector.id;
        const collectorData = collector.data();

        console.log(`🎯 Randomly selected collector ${collectorId} (${collectorData.name}) from ${collectorsSnapshot.size} available collectors in ${userTown}`);

        // Update the request with the collector
        await snap.ref.update({
          collectorId: collectorId,
          collectorName: collectorData.name || "Unknown Collector",
          assignedAt: admin.firestore.Timestamp.now(),
          status: "pending", // Keep as pending until collector accepts
        });

        console.log(`✅ Auto-assigned collector ${collectorId} to request ${context.params.requestId}`);

        // Send notification to the assigned collector
        const fcmToken = collectorData.fcmToken;
        if (fcmToken) {
          const message = {
            notification: {
            title: "📦 New Pickup Assigned",
            body: `You have a new pickup request from ${data.userName} in ${userTown}.`,
          },
            token: fcmToken,
          };

          await admin.messaging().send(message);
          console.log(`📱 Sent notification to collector ${collectorId}`);
        } else {
          console.log(`⚠️ No FCM token found for collector ${collectorId}`);
        }
      } else {
        console.log(`⏳ No active collectors found in ${userTown} for request ${context.params.requestId}`);
        console.log(`📋 Request will remain pending until a collector becomes active in ${userTown}`);
        // Request will remain pending until a collector becomes active
      }
    } catch (error) {
      console.error(`Error auto-assigning collector to request ${context.params.requestId}:`, error);
    }

    return null;
  });

// 🐛 Debug function to check data structure
exports.debugDataStructure = functions.https.onRequest(async (req, res) => {
  try {
    console.log("🔍 Debug: Checking data structure...");
    
    // Check collectors
    const collectorsSnapshot = await admin.firestore()
      .collection("collectors")
      .limit(5)
      .get();
    
    console.log("📊 Collectors found:", collectorsSnapshot.size);
    collectorsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`Collector ${doc.id}:`, {
        name: data.name,
        town: data.town,
        isActive: data.isActive,
        hasFCM: !!data.fcmToken
      });
    });

    // Check pickup requests
    const requestsSnapshot = await admin.firestore()
      .collection("pickup_requests")
      .limit(5)
      .get();
    
    console.log("📊 Pickup requests found:", requestsSnapshot.size);
    requestsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`Request ${doc.id}:`, {
        status: data.status,
        userTown: data.userTown,
        collectorId: data.collectorId,
        collectorName: data.collectorName
      });
    });

    res.json({ 
      message: "Debug data logged to console",
      collectors: collectorsSnapshot.size,
      requests: requestsSnapshot.size
    });
  } catch (error) {
    console.error("Debug error:", error);
    res.status(500).json({ error: error.message });
  }
});

// 🚀 Manual trigger function to assign collectors to pending requests
exports.manualAssignCollectors = functions.https.onRequest(async (req, res) => {
  try {
    const { town } = req.query;
    
    if (!town) {
      return res.status(400).json({ error: "Town parameter is required" });
    }

    console.log(`🔧 Manual assignment triggered for town: ${town}`);
    
    // Find pending requests in the specified town
    const pendingRequests = await admin.firestore()
      .collection("pickup_requests")
      .where("status", "==", "pending")
      .where("userTown", "==", town)
      .where("collectorId", "in", ["", null])
      .get();

    if (pendingRequests.empty) {
      console.log(`No pending requests found in ${town}`);
      return res.json({ message: `No pending requests found in ${town}` });
    }

    console.log(`📋 Found ${pendingRequests.size} pending requests in ${town}`);

    // Find active collectors in the town
    const collectorsSnapshot = await admin.firestore()
      .collection("collectors")
      .where("isActive", "==", true)
      .where("town", "==", town)
      .get();

    if (collectorsSnapshot.empty) {
      console.log(`No active collectors found in ${town}`);
      return res.json({ message: `No active collectors found in ${town}` });
    }

    const collectors = collectorsSnapshot.docs;
    console.log(`👥 Found ${collectors.length} active collectors in ${town}`);

    // Assign requests to collectors
    const batch = admin.firestore().batch();
    pendingRequests.docs.forEach((doc, index) => {
      const collector = collectors[index % collectors.length];
      const collectorId = collector.id;
      const collectorData = collector.data();

      console.log(`📝 Assigning request ${doc.id} to collector ${collectorId}`);
      
      batch.update(doc.ref, {
        collectorId: collectorId,
        collectorName: collectorData.name || "Unknown Collector",
        assignedAt: admin.firestore.Timestamp.now(),
        status: "pending",
      });
    });

    await batch.commit();
    console.log(`✅ Successfully assigned ${pendingRequests.size} requests in ${town}`);

    res.json({ 
      message: `Successfully assigned ${pendingRequests.size} requests in ${town}`,
      assigned: pendingRequests.size,
      collectors: collectors.length
    });
  } catch (error) {
    console.error("Manual assignment error:", error);
    res.status(500).json({ error: error.message });
  }
});

// 🔄 Periodic function to handle unassigned requests
exports.handleUnassignedRequests = onSchedule("every 2 minutes", async () => {
  try {
    console.log("🔍 Checking for unassigned pickup requests...");
    
    // Find all pending requests without a collector
    const unassignedRequests = await admin.firestore()
      .collection("pickup_requests")
      .where("status", "==", "pending")
      .where("collectorId", "in", ["", null])
      .get();

    if (unassignedRequests.empty) {
      console.log("✅ No unassigned requests found");
      return null;
    }

    console.log(`📋 Found ${unassignedRequests.size} unassigned requests`);

    // Group requests by town
    const requestsByTown = {};
    unassignedRequests.docs.forEach(doc => {
      const data = doc.data();
      const town = data.userTown;
      if (town) {
        if (!requestsByTown[town]) {
          requestsByTown[town] = [];
        }
        requestsByTown[town].push({ doc, data });
      }
    });

    // Process each town
    for (const [town, requests] of Object.entries(requestsByTown)) {
      console.log(`🏘️ Processing ${requests.length} requests in ${town}`);
      
      // Find active collectors in this town
      const collectorsSnapshot = await admin.firestore()
        .collection("collectors")
        .where("isActive", "==", true)
        .where("town", "==", town)
        .get();

      if (collectorsSnapshot.empty) {
        console.log(`⚠️ No active collectors found in ${town}`);
        continue;
      }

      const collectors = collectorsSnapshot.docs;
      console.log(`👥 Found ${collectors.length} active collectors in ${town}`);

      // Assign requests to collectors (round-robin style)
      const batch = admin.firestore().batch();
      requests.forEach((request, index) => {
        const collector = collectors[index % collectors.length];
        const collectorId = collector.id;
        const collectorData = collector.data();

        console.log(`📝 Assigning request ${request.doc.id} to collector ${collectorId} in ${town}`);
        
        batch.update(request.doc.ref, {
          collectorId: collectorId,
          collectorName: collectorData.name || "Unknown Collector",
          assignedAt: admin.firestore.Timestamp.now(),
          status: "pending",
        });
      });

      await batch.commit();
      console.log(`✅ Assigned ${requests.length} requests in ${town} to active collectors`);
    }

    return null;
  } catch (error) {
    console.error("Error handling unassigned requests:", error);
    return null;
  }
});

// 🔐 Admin Management Functions
exports.createAdminUser = functions.https.onRequest(async (req, res) => {
  try {
    // This should be protected with proper authentication in production
    const { email, password, name, role = 'admin' } = req.body;
    
    if (!email || !password || !name) {
      return res.status(400).json({ 
        error: "Email, password, and name are required" 
      });
    }

    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // Add admin data to Firestore
    await admin.firestore().collection('admins').doc(userRecord.uid).set({
      email: email,
      name: name,
      role: role,
      createdAt: admin.firestore.Timestamp.now(),
      isActive: true,
      permissions: ['read', 'write', 'delete'], // Default permissions
    });

    console.log(`✅ Admin user created: ${email} (${userRecord.uid})`);
    
    res.json({ 
      message: "Admin user created successfully",
      uid: userRecord.uid,
      email: email
    });
  } catch (error) {
    console.error("Error creating admin user:", error);
    res.status(500).json({ error: error.message });
  }
});

exports.listAdminUsers = functions.https.onRequest(async (req, res) => {
  try {
    const adminsSnapshot = await admin.firestore()
      .collection('admins')
      .orderBy('createdAt', 'desc')
      .get();

    const admins = adminsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ admins });
  } catch (error) {
    console.error("Error listing admin users:", error);
    res.status(500).json({ error: error.message });
  }
});

// 🚨 Mark missed pickup requests daily
exports.markMissedPickupRequests = onSchedule("0 1 * * *", async (event) => {
  console.log("🔄 Starting daily check for missed pickup requests...");
  
  try {
    const now = admin.firestore.Timestamp.now();
    const yesterday = new Date(now.toDate());
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(23, 59, 59, 999); // End of yesterday
    
    console.log(`📅 Checking for requests before: ${yesterday.toISOString()}`);
    
    // Find all pending requests that were scheduled before yesterday
    const missedRequestsQuery = await admin.firestore()
      .collection("pickup_requests")
      .where("status", "in", ["pending", "accepted", "in_progress"])
      .where("pickupDate", "<", admin.firestore.Timestamp.fromDate(yesterday))
      .get();
    
    console.log(`🔍 Found ${missedRequestsQuery.size} potentially missed requests`);
    
    const batch = admin.firestore().batch();
    let missedCount = 0;
    
    for (const doc of missedRequestsQuery.docs) {
      const requestData = doc.data();
      const requestId = doc.id;
      
      // Skip if already marked as missed
      if (requestData.status === "missed") {
        continue;
      }
      
      // Mark as missed
      batch.update(doc.ref, {
        status: "missed",
        missedAt: admin.firestore.Timestamp.now(),
        missedReason: "Pickup day has passed without completion"
      });
      
      missedCount++;
      
      // Create notifications for both user and collector
      await createMissedRequestNotifications(requestData, requestId);
    }
    
    if (missedCount > 0) {
      await batch.commit();
      console.log(`✅ Marked ${missedCount} requests as missed`);
    } else {
      console.log("✅ No missed requests found");
    }
    
    return { success: true, missedCount };
  } catch (error) {
    console.error("❌ Error marking missed requests:", error);
    throw error;
  }
});

// Helper function to create notifications for missed requests
async function createMissedRequestNotifications(requestData, requestId) {
  try {
    const { userId, collectorId, collectorName, userName, userTown, pickupDate } = requestData;
    
    // Notify user
    if (userId) {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userFcmToken = userDoc.data()?.fcmToken;
      
      if (userFcmToken) {
        const userMessage = {
          notification: {
            title: "⚠️ Pickup Missed",
            body: `Your pickup request scheduled for ${pickupDate.toDate().toLocaleDateString()} was not completed. You can reschedule or request a refund.`,
          },
          token: userFcmToken,
          data: {
            type: "missed_pickup",
            requestId: requestId,
            action: "reschedule"
          }
        };
        
        await admin.messaging().send(userMessage);
        console.log(`📱 Notified user ${userId} about missed pickup`);
      }
      
      // Create in-app notification for user
      await admin.firestore().collection("notifications").add({
        userId: userId,
        type: "missed_pickup",
        title: "⚠️ Pickup Request Missed",
        message: `Your pickup request scheduled for ${pickupDate.toDate().toLocaleDateString()} was not completed. You can reschedule or request a refund.`,
        data: {
          pickupRequestId: requestId,
          collectorId: collectorId,
          collectorName: collectorName,
          userTown: userTown,
          pickupDate: pickupDate,
          action: "reschedule"
        },
        isRead: false,
        createdAt: admin.firestore.Timestamp.now()
      });
    }
    
    // Notify collector
    if (collectorId) {
      const collectorDoc = await admin.firestore().collection("collectors").doc(collectorId).get();
      const collectorFcmToken = collectorDoc.data()?.fcmToken;
      
      if (collectorFcmToken) {
        const collectorMessage = {
          notification: {
            title: "⚠️ Missed Pickup Alert",
            body: `You missed a pickup request from ${userName} in ${userTown} scheduled for ${pickupDate.toDate().toLocaleDateString()}. Please contact the user to reschedule.`,
          },
          token: collectorFcmToken,
          data: {
            type: "missed_pickup_collector",
            requestId: requestId,
            action: "contact_user"
          }
        };
        
        await admin.messaging().send(collectorMessage);
        console.log(`📱 Notified collector ${collectorId} about missed pickup`);
      }
      
      // Create in-app notification for collector
      await admin.firestore().collection("notifications").add({
        collectorId: collectorId,
        type: "missed_pickup_collector",
        title: "⚠️ Missed Pickup Alert",
        message: `You missed a pickup request from ${userName} in ${userTown} scheduled for ${pickupDate.toDate().toLocaleDateString()}. Please contact the user to reschedule.`,
        data: {
          pickupRequestId: requestId,
          userId: userId,
          userName: userName,
          userTown: userTown,
          pickupDate: pickupDate,
          action: "contact_user"
        },
        isRead: false,
        createdAt: admin.firestore.Timestamp.now()
      });
    }
  } catch (error) {
    console.error("❌ Error creating missed request notifications:", error);
  }
}

exports.updateAdminUser = functions.https.onRequest(async (req, res) => {
  try {
    const { adminId } = req.params;
    const { name, role, isActive, permissions } = req.body;
    
    if (!adminId) {
      return res.status(400).json({ error: "Admin ID is required" });
    }

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (role !== undefined) updateData.role = role;
    if (isActive !== undefined) updateData.isActive = isActive;
    if (permissions !== undefined) updateData.permissions = permissions;

    updateData.updatedAt = admin.firestore.Timestamp.now();

    await admin.firestore()
      .collection('admins')
      .doc(adminId)
      .update(updateData);

    console.log(`✅ Admin user updated: ${adminId}`);
    
    res.json({ message: "Admin user updated successfully" });
  } catch (error) {
    console.error("Error updating admin user:", error);
    res.status(500).json({ error: error.message });
  }
});

exports.deleteAdminUser = functions.https.onRequest(async (req, res) => {
  try {
    const { adminId } = req.params;
    
    if (!adminId) {
      return res.status(400).json({ error: "Admin ID is required" });
    }

    // Delete from Firestore
    await admin.firestore()
      .collection('admins')
      .doc(adminId)
      .delete();

    // Note: In production, you might want to also delete the Firebase Auth user
    // await admin.auth().deleteUser(adminId);

    console.log(`✅ Admin user deleted: ${adminId}`);
    
    res.json({ message: "Admin user deleted successfully" });
  } catch (error) {
    console.error("Error deleting admin user:", error);
    res.status(500).json({ error: error.message });
  }
});

// 🗑️ Auto-delete sold marketplace items after 24 hours
exports.autoDeleteSoldMarketplaceItems = onSchedule("every 1 hours", async () => {
  console.log("🔄 Starting auto-deletion of sold marketplace items...");
  
  try {
    const now = admin.firestore.Timestamp.now();
    
    console.log(`📅 Current time: ${now.toDate().toISOString()}`);
    
    // Find all sold items where deleteAfter time has passed
    const soldItemsQuery = await admin.firestore()
      .collection("marketplace_items")
      .where("status", "in", ["sold", "claimed"])
      .where("deleteAfter", "<=", now)
      .get();
    
    console.log(`🔍 Found ${soldItemsQuery.size} sold items ready for deletion`);
    
    if (soldItemsQuery.empty) {
      console.log("✅ No sold items found for deletion");
      return null;
    }
    
    const batch = admin.firestore().batch();
    let deletedCount = 0;
    
    for (const doc of soldItemsQuery.docs) {
      const itemData = doc.data();
      const itemId = doc.id;
      const soldAt = itemData.soldAt?.toDate();
      const deleteAfter = itemData.deleteAfter?.toDate();
      
      console.log(`🗑️ Deleting sold item: ${itemData.name} (ID: ${itemId})`);
      console.log(`   Sold at: ${soldAt?.toISOString()}`);
      console.log(`   Delete after: ${deleteAfter?.toISOString()}`);
      
      // Delete the item
      batch.delete(doc.ref);
      deletedCount++;
      
      // Create notification for seller about item deletion
      await createItemDeletionNotification(itemData, itemId);
    }
    
    await batch.commit();
    console.log(`✅ Successfully deleted ${deletedCount} sold marketplace items`);
    
    return { success: true, deletedCount };
  } catch (error) {
    console.error("❌ Error auto-deleting sold marketplace items:", error);
    throw error;
  }
});

// Helper function to create notifications for item deletion
async function createItemDeletionNotification(itemData, itemId) {
  try {
    const { ownerId, name, price, buyerId } = itemData;
    
    // Notify seller about item deletion
    if (ownerId) {
      // Try users collection first, then collectors
      let sellerDoc = await admin.firestore().collection("users").doc(ownerId).get();
      let sellerCollection = "users";
      
      if (!sellerDoc.exists) {
        sellerDoc = await admin.firestore().collection("collectors").doc(ownerId).get();
        sellerCollection = "collectors";
      }
      
      if (sellerDoc.exists) {
        const sellerData = sellerDoc.data();
        const fcmToken = sellerData.fcmToken;
        
        if (fcmToken) {
          const message = {
            notification: {
              title: "🗑️ Item Deleted",
              body: `Your sold item "${name}" has been automatically removed from the marketplace after 24 hours.`,
            },
            token: fcmToken,
            data: {
              type: "item_deleted",
              itemId: itemId,
              itemName: name,
              action: "view_sales_history"
            }
          };
          
          await admin.messaging().send(message);
          console.log(`📱 Notified seller ${ownerId} about item deletion`);
        }
        
        // Create in-app notification for seller
        await admin.firestore().collection("notifications").add({
          userId: ownerId,
          type: "item_deleted",
          title: "🗑️ Item Automatically Deleted",
          message: `Your sold item "${name}" (GHS ${price}) has been automatically removed from the marketplace after 24 hours.`,
          data: {
            itemId: itemId,
            itemName: name,
            itemPrice: price,
            buyerId: buyerId,
            action: "view_sales_history"
          },
          isRead: false,
          createdAt: admin.firestore.Timestamp.now()
        });
      }
    }
    
    // Notify buyer about item deletion (optional - for their purchase history)
    if (buyerId) {
      const buyerDoc = await admin.firestore().collection("users").doc(buyerId).get();
      
      if (buyerDoc.exists) {
        const buyerData = buyerDoc.data();
        const fcmToken = buyerData.fcmToken;
        
        if (fcmToken) {
          const message = {
            notification: {
              title: "📦 Purchase Item Removed",
              body: `The item "${name}" you purchased has been removed from the marketplace.`,
            },
            token: fcmToken,
            data: {
              type: "purchased_item_removed",
              itemId: itemId,
              itemName: name,
              action: "view_purchase_history"
            }
          };
          
          await admin.messaging().send(message);
          console.log(`📱 Notified buyer ${buyerId} about item removal`);
        }
        
        // Create in-app notification for buyer
        await admin.firestore().collection("notifications").add({
          userId: buyerId,
          type: "purchased_item_removed",
          title: "📦 Purchased Item Removed",
          message: `The item "${name}" (GHS ${price}) you purchased has been removed from the marketplace.`,
          data: {
            itemId: itemId,
            itemName: name,
            itemPrice: price,
            sellerId: ownerId,
            action: "view_purchase_history"
          },
          isRead: false,
          createdAt: admin.firestore.Timestamp.now()
        });
      }
    }
  } catch (error) {
    console.error("❌ Error creating item deletion notifications:", error);
  }
}

// 🧪 Manual trigger function for testing auto-deletion (for development/testing)
exports.manualDeleteSoldItems = functions.https.onRequest(async (req, res) => {
  try {
    console.log("🧪 Manual trigger: Starting auto-deletion of sold marketplace items...");
    
    const now = admin.firestore.Timestamp.now();
    
    console.log(`📅 Current time: ${now.toDate().toISOString()}`);
    
    // Find all sold items where deleteAfter time has passed
    const soldItemsQuery = await admin.firestore()
      .collection("marketplace_items")
      .where("status", "in", ["sold", "claimed"])
      .where("deleteAfter", "<=", now)
      .get();
    
    console.log(`🔍 Found ${soldItemsQuery.size} sold items ready for deletion`);
    
    if (soldItemsQuery.empty) {
      console.log("✅ No sold items found for deletion");
      return res.json({ 
        message: "No sold items found for deletion",
        deletedCount: 0 
      });
    }
    
    const batch = admin.firestore().batch();
    let deletedCount = 0;
    const deletedItems = [];
    
    for (const doc of soldItemsQuery.docs) {
      const itemData = doc.data();
      const itemId = doc.id;
      const soldAt = itemData.soldAt?.toDate();
      const deleteAfter = itemData.deleteAfter?.toDate();
      
      console.log(`🗑️ Deleting sold item: ${itemData.name} (ID: ${itemId})`);
      console.log(`   Sold at: ${soldAt?.toISOString()}`);
      console.log(`   Delete after: ${deleteAfter?.toISOString()}`);
      
      // Delete the item
      batch.delete(doc.ref);
      deletedCount++;
      deletedItems.push({
        id: itemId,
        name: itemData.name,
        price: itemData.price,
        soldAt: soldAt?.toISOString(),
        deleteAfter: deleteAfter?.toISOString()
      });
      
      // Create notification for seller about item deletion
      await createItemDeletionNotification(itemData, itemId);
    }
    
    await batch.commit();
    console.log(`✅ Successfully deleted ${deletedCount} sold marketplace items`);
    
    res.json({ 
      success: true, 
      deletedCount,
      deletedItems,
      message: `Successfully deleted ${deletedCount} sold marketplace items`
    });
  } catch (error) {
    console.error("❌ Error manually deleting sold marketplace items:", error);
    res.status(500).json({ 
      error: error.message,
      success: false 
    });
  }
});