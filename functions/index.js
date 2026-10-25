const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

exports.createManagedSaleLedger = onDocumentUpdated("vehicles/{vehicleId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === "sold" || after.status !== "sold") return;

  const price = Number(after.price || 0);
  const rate = after.managedSale === false ? 0 : 0.10;
  const commission = Math.round(price * rate * 100) / 100;
  const sellerNet = Math.round((price - commission) * 100) / 100;

  await getFirestore().collection("transactions").doc(event.params.vehicleId).set({
    vehicleId: event.params.vehicleId,
    vehicleTitle: after.title || "Vehicle",
    sellerId: after.sellerId,
    salePrice: price,
    commissionRate: rate,
    commission,
    sellerNet,
    paymentStatus: "awaiting_confirmation",
    ownershipTransferStatus: "pending",
    createdAt: FieldValue.serverTimestamp(),
  }, { merge: false });
});
