export type SosStatus = 'active' | 'acknowledged' | 'resolved';

export interface SosReport {
  mapId: string;
  propertyId: string;
  floor: number;
  areaId: string;
  areaName: string;
  latitude?: number;
  longitude?: number;
  reportedBy: string;
  status: SosStatus;
  createdAt: FirebaseFirestore.Timestamp;
}