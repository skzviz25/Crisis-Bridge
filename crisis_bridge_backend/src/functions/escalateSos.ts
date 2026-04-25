import * as functions from 'firebase-functions';
import { sendPmsAlert } from '../services/pmsService';

/**
 * Callable function — staff can manually trigger external escalation
 * for an existing SOS (e.g. contact emergency services).
 */
export const escalateSos = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Must be authenticated to escalate'
    );
  }

  const { sosId, propertyId, floor, areaName, latitude, longitude } = data as {
    sosId: string;
    propertyId: string;
    floor: number;
    areaName: string;
    latitude?: number;
    longitude?: number;
  };

  if (!sosId || !propertyId) {
    throw new functions.https.HttpsError('invalid-argument', 'sosId and propertyId required');
  }

  await sendPmsAlert({
    propertyId,
    floor,
    areaName,
    message: `Manual escalation of SOS ${sosId}`,
    latitude,
    longitude,
  });

  return { success: true, sosId };
});