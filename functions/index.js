const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");

admin.initializeApp();

const firestore = admin.firestore();
const fieldValue = admin.firestore.FieldValue;

exports.processNotificationJob = onDocumentCreated(
  {
    document: "schools/{schoolId}/notificationJobs/{jobId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const job = snapshot.data();
    if (!job || job.status !== "queued" || !job.audienceTopic) {
      return;
    }

    try {
      await admin.messaging().send({
        topic: job.audienceTopic,
        notification: {
          title: job.title,
          body: job.body,
        },
        data: stringifyPayload(job.payload),
      });

      await snapshot.ref.update({
        status: "sent",
        attemptCount: fieldValue.increment(1),
        lastAttemptAt: fieldValue.serverTimestamp(),
        deliveredAt: fieldValue.serverTimestamp(),
        lastError: fieldValue.delete(),
      });
    } catch (error) {
      await snapshot.ref.update({
        status: "failed",
        attemptCount: fieldValue.increment(1),
        lastAttemptAt: fieldValue.serverTimestamp(),
        lastError: serializeError(error),
      });
    }
  },
);

exports.syncOfficeApprovalProjection = onDocumentWritten(
  {
    document: "schools/{schoolId}/officeApprovals/{approvalId}",
    region: "us-central1",
  },
  async (event) => {
    const after = event.data.after;
    if (!after.exists) {
      return;
    }

    const approval = after.data();
    if (!approval || !approval.schoolId || !approval.queueEntryId) {
      return;
    }

    const queueRef = firestore.doc(
      `schools/${approval.schoolId}/queue/${approval.queueEntryId}`,
    );
    const queueSnapshot = await queueRef.get();
    if (!queueSnapshot.exists) {
      return;
    }

    const queue = queueSnapshot.data();
    const batch = firestore.batch();
    const auditRef = firestore
      .collection("schools")
      .doc(approval.schoolId)
      .collection("auditTrail")
      .doc();

    const queueUpdate = {};
    let auditAction = "Office approval synchronized";
    let auditNotes = approval.reasonMessage;

    if (approval.status === "pending") {
      queueUpdate.exceptionFlag = approval.reasonMessage;
      queueUpdate.exceptionCode =
        approval.reasonCode || "officeApprovalRequired";
      queueUpdate.officeApprovalRequired = true;
      auditAction = "Office approval requested";
      auditNotes = approval.reasonMessage;
    } else if (approval.status === "approved") {
      queueUpdate.exceptionFlag = null;
      queueUpdate.exceptionCode = null;
      queueUpdate.officeApprovalRequired = false;
      auditAction = "Office approval approved";
      auditNotes =
        approval.reviewNotes ||
        `Office approval granted for ${approval.studentName}.`;
    } else if (approval.status === "denied") {
      queueUpdate.exceptionFlag =
        approval.reviewNotes || "Office approval denied. Release remains blocked.";
      queueUpdate.exceptionCode = "officeApprovalDenied";
      queueUpdate.officeApprovalRequired = true;
      auditAction = "Office approval denied";
      auditNotes =
        approval.reviewNotes ||
        `Office approval denied for ${approval.studentName}.`;
    }

    if (Object.keys(queueUpdate).length > 0) {
      batch.update(queueRef, queueUpdate);
    }

    batch.set(auditRef, {
      schoolId: approval.schoolId,
      studentName: queue.studentName || approval.studentName,
      action: auditAction,
      actorName:
        approval.reviewedByName ||
        approval.requestedByName ||
        "GeoTap Guardian backend",
      occurredAt: fieldValue.serverTimestamp(),
      notes: auditNotes,
    });

    await batch.commit();
  },
);

exports.resolveOfficeApprovalOnRelease = onDocumentCreated(
  {
    document: "schools/{schoolId}/releaseEvents/{releaseEventId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const release = snapshot.data();
    if (!release || !release.schoolId || !release.queueEntryId) {
      return;
    }

    const approvalRef = firestore.doc(
      `schools/${release.schoolId}/officeApprovals/${release.queueEntryId}`,
    );
    const approvalSnapshot = await approvalRef.get();
    if (!approvalSnapshot.exists) {
      return;
    }

    await approvalRef.update({
      status: "resolved",
      resolvedAt: fieldValue.serverTimestamp(),
      resolvedByUid: release.staffId,
      resolvedByName: release.staffName,
    });
  },
);

function stringifyPayload(payload) {
  const source = payload && typeof payload === "object" ? payload : {};
  return Object.fromEntries(
    Object.entries(source).map(([key, value]) => [key, String(value)]),
  );
}

function serializeError(error) {
  if (!error) {
    return "Unknown notification delivery failure.";
  }

  if (typeof error === "string") {
    return error;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return JSON.stringify(error);
}
