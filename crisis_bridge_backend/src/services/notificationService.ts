import { messaging, db } from '../config/firebase';
import { Responder } from '../types/responder';

/**
 * Fetch all FCM tokens for staff at a given property
 * and send a push notification to each.
 */
export async function notifyStaffForProperty(
  propertyId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  const snapshot = await db
    .collection('responders')
    .where('propertyId', '==', propertyId)
    .get();

  const tokens: string[] = [];
  snapshot.forEach((doc) => {
    const responder = doc.data() as Responder;
    if (responder.fcmToken) {
      tokens.push(responder.fcmToken);
    }
  });

  if (tokens.length === 0) {
    console.log(`[notify] No FCM tokens for property ${propertyId}`);
    return;
  }

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: data ?? {},
    android: {
      priority: 'high',
      notification: { channelId: 'crisis_bridge_sos', sound: 'default' },
    },
    apns: {
      payload: {
        aps: { sound: 'default', badge: 1, contentAvailable: true },
      },
    },
  });

  console.log(
    `[notify] Sent to ${response.successCount}/${tokens.length} devices`
  );
}