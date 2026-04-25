/**
 * Property Management System integration stub.
 * Replace the fetch call with your PMS vendor's API.
 */
export interface PmsAlertPayload {
  propertyId: string;
  floor: number;
  areaName: string;
  message: string;
  latitude?: number;
  longitude?: number;
}

export async function sendPmsAlert(payload: PmsAlertPayload): Promise<void> {
  const pmsUrl = process.env.PMS_WEBHOOK_URL;
  if (!pmsUrl) {
    console.warn('[pms] PMS_WEBHOOK_URL not configured — skipping alert');
    return;
  }

  const response = await fetch(pmsUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${process.env.PMS_API_KEY ?? ''}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`PMS alert failed: ${response.status} ${response.statusText}`);
  }
  console.log('[pms] Alert sent successfully');
}