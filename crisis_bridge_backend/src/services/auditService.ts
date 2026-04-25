import { db } from '../config/firebase';
import { admin } from '../config/firebase';

export interface AuditEntry {
  event: string;
  entityType: string;
  entityId: string;
  propertyId: string;
  payload: Record<string, unknown>;
  createdAt: FirebaseFirestore.FieldValue;
}

export async function writeAudit(entry: Omit<AuditEntry, 'createdAt'>): Promise<void> {
  await db.collection('audit_log').add({
    ...entry,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}