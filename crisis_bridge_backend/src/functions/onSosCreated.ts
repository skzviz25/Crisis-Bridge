import * as functions from 'firebase-functions';
import { SosReport } from '../types/sosReport';
import { notifyStaffForProperty } from '../services/notificationService';
import { writeAudit } from '../services/auditService';
import { sendPmsAlert } from '../services/pmsService';

/**
 * Firestore trigger: fires whenever a new SOS report is created.
 * 1. Push-notifies all staff at the property.
 * 2. Optionally forwards to PMS.
 * 3. Writes an audit log entry.
 */
export const onSosCreated = functions.firestore
  .document('sos_reports/{sosId}')
  .onCreate(async (snap, context) => {
    const sos = snap.data() as SosReport;
    const sosId = context.params.sosId;

    console.log(`[sos] New SOS ${sosId} at property ${sos.propertyId}, floor ${sos.floor}`);

    // 1. Push notification to staff
    await notifyStaffForProperty(
      sos.propertyId,
      '🚨 SOS ALERT',
      `Floor ${sos.floor} · ${sos.areaName}`,
      { sosId, mapId: sos.mapId, floor: String(sos.floor) }
    );

    // 2. PMS escalation (non-blocking — errors logged, not thrown)
    try {
      await sendPmsAlert({
        propertyId: sos.propertyId,
        floor: sos.floor,
        areaName: sos.areaName,
        message: `SOS received from ${sos.reportedBy}`,
        latitude: sos.latitude,
        longitude: sos.longitude,
      });
    } catch (err) {
      console.error('[sos] PMS escalation failed:', err);
    }

    // 3. Audit log
    await writeAudit({
      event: 'sos_created',
      entityType: 'sos_report',
      entityId: sosId,
      propertyId: sos.propertyId,
      payload: { floor: sos.floor, areaName: sos.areaName },
    });
  });