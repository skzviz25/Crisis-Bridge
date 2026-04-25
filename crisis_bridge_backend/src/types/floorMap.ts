export interface FloorMap {
  propertyId: string;
  propertyName: string;
  floor: number;
  createdBy: string;
  qrPayload: string;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}