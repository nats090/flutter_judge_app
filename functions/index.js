const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.deleteUserAccount = functions.https.onCall(
    async (data, context) => {
    // Ensure the request is authenticated.
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Request must be authenticated.",
        );
      }

      // Check that the requester is an admin.
      const requesterUID = context.auth.uid;
      const requesterDoc = await admin
          .firestore()
          .collection("users")
          .doc(requesterUID)
          .get();

      if (!requesterDoc.exists ||
        requesterDoc.data().role !== "admin") {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only admins can delete users.",
        );
      }

      // Retrieve the UID of the user to be deleted.
      const uidToDelete = data.uid;
      if (!uidToDelete) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "UID not provided.",
        );
      }

      try {
      // Delete the user from Firebase Authentication.
        await admin.auth().deleteUser(uidToDelete);
        // Optionally, delete the Firestore document.
        await admin.firestore()
            .collection("users")
            .doc(uidToDelete)
            .delete();
        return {message: "Successfully deleted user " + uidToDelete};
      } catch (error) {
        console.error("Error deleting user:", error);
        throw new functions.https.HttpsError(
            "unknown",
            error.message,
            error,
        );
      }
    },
);
