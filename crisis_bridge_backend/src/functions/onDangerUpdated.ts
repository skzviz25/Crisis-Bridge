import * as functions from 'firebase-functions';
import { notifyStaffForProperty } from '../services/notificationService';
import { writeAudit } from '../services/auditService';

/**
 * Fires when a danger_state document is written.
 * Notifies staff in realtime when a zone becomes active/cleared.
 */
export const onDangerUpdated = functions.firestore
  .document('danger_states/{dangerStateId}')
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    const before = change.before.exists ? change.before.data() : null;

    if (!after) return; // Document deleted

    const wasActive = before?.active === true;
    const isActive = after.active === true;

    // Only act on actual state changes
    if (wasActive === isActive) return;

    const mapId: string = after.mapId;
    const areaName: string = after.areaName;

    // Resolve propertyId from the map doc
    const { db } = await import('../config/firebase');
    const mapDoc = await db.collection('floor_maps').doc(mapId).get();
    if (!mapDoc.exists) return;
    const propertyId: string = mapDoc.data()?.propertyId ?? '';

    if (isActive) {
      await notifyStaffForProperty(
        propertyId,
        '⚠ DANGER ZONE ACTIVE',
        `${areaName} is now a danger zone`,
        { mapId, areaName }
      );
    } else {
      await notifyStaffForProperty(
        propertyId,
        '✓ DANGER ZONE CLEARED',
        `${areaName} has been cleared`,
        { mapId, areaName }
      );
    }

    await writeAudit({
      event: isActive ? 'danger_activated' : 'danger_cleared',
      entityType: 'danger_state',
      entityId: context.params.dangerStateId,
      propertyId,
      payload: { areaName, mapId },
    });
  });