/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// const {onRequest} = require("firebase-functions/v2/https");
// const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteUserMessagesOnStatusChange = functions.firestore
    .document("users/{userId}")
    .onUpdate(async (change, context) => {
      const before = change.before.data();
      const after = change.after.data();

      // Check if the banned status has changed
      if (before.banned !== after.banned) {
        const userId = context.params.userId;

        // Call a function to delete all messages for this user
        return await deleteAllMessagesForUser(userId);
      }

      return null;
    });

/**
 * Deletes all messages for a specified user across all chats.
 * This function queries the Firestore database for messages by a specific user
 * to be called when a user is banned, to ensure their messages are removed from
 * all chats in the database.
 *
 * @async
 * @function deleteAllMessagesForUser
 * @param {string} userId - The ID of the user whose messages are to be deleted.
 * @return {Promise<void>}
 */
async function deleteAllMessagesForUser(userId) {
  const db = admin.firestore();
  const chatsRef = db.collection("chats");
  const chatsSnapshot = await chatsRef.get();

  // Iterate over each chat
  for (const chatDoc of chatsSnapshot.docs) {
    const messagesRef =
    chatDoc.ref.collection("messages").where("userId", "==", userId);
    const messagesSnapshot = await messagesRef.get();

    // Check if there are messages to delete
    if (!messagesSnapshot.empty) {
      // Batch delete to handle large number of documents
      const batch = db.batch();
      messagesSnapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit().then(() => {
        console.log(`Deleted ${userId} in chat ${chatDoc.id}`);
      }).catch((error) => {
        console.error("Error deleting messages: ", error);
      });
    }
  }

  console.log("All messages have been deleted");
}

exports.deleteOldMessages = functions.pubsub.schedule("51 13 * * *")
    .timeZone("America/Chicago")
    .onRun(async (context) => {
      const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - 30 * 24 * 60 * 60 * 1000));
      const chatsRef = admin.firestore().collection("chats");

      const chatsSnapshot = await chatsRef.get();
      const promises = [];

      chatsSnapshot.forEach((chatDoc) => {
        const messagesRef = chatDoc.ref.collection("messages");
        promises.push(
            messagesRef.where("timestamp", "<", thirtyDaysAgo).get()
                .then((snapshot) => {
                  const deletePromises = [];
                  snapshot.forEach((doc) => {
                    deletePromises.push(doc.ref.delete());
                  });
                  return Promise.all(deletePromises);
                }),
        );
      });

      await Promise.all(promises);
      console.log("Old messages deleted successfully.");
      return null;
    });


exports.sendReplyNotification = functions.firestore
    .document("chats/{chatRoomId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const newValue = snap.data();
      if (!newValue.replyToMessageId) return null;
      try {
        const chatRoomDoc = await admin.firestore()
            .collection("chats")
            .doc(context.params.chatRoomId)
            .get();
        if (!chatRoomDoc.exists) {
          console.log(`Chat room not found`);
          return null;
        }
        const chatRoomName = chatRoomDoc.data().name;
        const origMsgDoc = await admin.firestore()
            .collection(`chats/${context.params.chatRoomId}/messages`)
            .doc(newValue.replyToMessageId)
            .get();

        if (!origMsgDoc.exists) {
          console.log("Original message not found!");
          return null;
        }

        const origUserId = origMsgDoc.data().userId;
        const origUserDoc = await admin.firestore()
            .collection("users")
            .doc(origUserId)
            .get();

        if (!origUserDoc.exists) {
          console.log("User being replied to does not exist!");
          return null;
        }

        const token = origUserDoc.data().fcmToken;

        await admin.firestore().collection("users")
            .doc(origUserId).update({badgeCount: 1});

        const replierUserDoc = await admin.firestore()
            .collection("users")
            .doc(newValue.userId)
            .get();

        if (!replierUserDoc.exists) {
          console.log("Replier user does not exist!");
          return null;
        }

        const firstName = replierUserDoc.data().first_name || "Someone";
        const lastName = replierUserDoc.data().last_name || "";
        const message = {
          notification: {
            title: `New reply in ${chatRoomName}:`,
            body: `${firstName} ${lastName} replied: ${newValue.text}`,
          },
          token: token,
          apns: {
            payload: {
              aps: {
                badge: 1,
              },
            },
          },
        };

        return admin.messaging().send(message);
      } catch (error) {
        console.log("Error", error);
        return null;
      }
    });


exports.sendLikeNotification = functions.firestore
    .document("chats/{chatRoomId}/messages/{messageId}")
    .onUpdate(async (change, context) => {
      const newValue = change.after.data();
      const oldValue = change.before.data();

      const likeMilestones = [2, 5, 10, 25, 50];

      if (likeMilestones.includes(newValue.likes.length) &&
          newValue.likes.length > oldValue.likes.length) {
        const notifiedMilestones = newValue.notifiedMilestones || [];
        if (notifiedMilestones.includes(newValue.likes.length)) {
          console.log("Milestone already notified");
          return null;
        }

        const userId = newValue.userId;
        try {
          const userDoc = await admin.firestore()
              .collection("users").doc(userId).get();

          if (!userDoc.exists) {
            console.log("No such user!");
            return null;
          }

          const token = userDoc.data().fcmToken;
          await admin.firestore().collection("users")
              .doc(userId).update({badgeCount: 1});
          const updatedNotifiedMilestones =
          [...notifiedMilestones, newValue.likes.length];

          await admin.firestore()
              .collection(`chats/${context.params.chatRoomId}/messages`)
              .doc(context.params.messageId)
              .update({notifiedMilestones: updatedNotifiedMilestones});

          const message = {
            notification: {
              title: "Milestone Achieved!",
              body: `Your message now has ${newValue.likes.length} likes!`,
            },
            token: token,
            apns: {
              payload: {
                aps: {
                  badge: 1,
                },
              },
            },
          };

          return admin.messaging().send(message);
        } catch (error) {
          console.log("Error", error);
          return null;
        }
      } else {
        return null;
      }
    });


exports.sendIndividualNotifications = functions.firestore
    .document("chats/{chatRoomId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const newValue = snap.data();
      const superAdminId = "5Do2GHW4MgZ6NoqS8SG2gKx48Po1";

      if (newValue.userId !== superAdminId) {
        return null;
      }

      const usersSnapshot = await admin.firestore().collection("users").get();
      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.fcmToken) {
          tokens.push(user.fcmToken);
        }
      });

      const batchSize = 500;
      let batch = 0;

      while (batch * batchSize < tokens.length) {
        const batchTokens = tokens.slice(batch *
          batchSize, (batch + 1) * batchSize);
        const sendPromises = batchTokens.map((token) => {
          const message = {
            notification: {
              title: "📢 IPN Team Announcement",
              body: newValue.text,
            },
            token: token,
          };

          return admin.messaging().send(message, false)
              .catch((error) => {
                console.error("Failed to send notification to", token, error);
                return null;
              });
        });

        await Promise.all(sendPromises);
        console.log(`Batch ${batch + 1} sent.`);
        batch++;
      }

      console.log("All messages sent.");
      return null;
    });


