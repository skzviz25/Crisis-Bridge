import * as functions from 'firebase-functions';
import { FloorMap } from '../types/floorMap';
import { writeAudit } from '../services/auditService';

/**
 * Fires when a new floor map is created.
 * Writes an audit entry — extend here for PMS room mapping sync.
 */
export const onMapCreated = functions.firestore
  .document('floor_maps/{mapId}')
  .onCreate(async (snap, context) => {
    const map = snap.data() as FloorMap;
    const mapId = context.params.mapId;

    await writeAudit({
      event: 'map_created',
      entityType: 'floor_map',
      entityId: mapId,
      propertyId: map.propertyId,
      payload: { propertyName: map.propertyName, floor: map.floor },
    });

    console.log(`[map] Created floor map ${mapId} for ${map.propertyName} floor ${map.floor}`);
  });