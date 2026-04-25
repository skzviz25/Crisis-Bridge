export interface Responder {
  email: string;
  displayName: string;
  role: 'staff' | 'admin';
  propertyId: string;
  fcmToken?: string;
  createdAt: FirebaseFirestore.Timestamp;
}