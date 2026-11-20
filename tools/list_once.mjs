// One-time, read-only: lists all groups with their members (names only).
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SA)) });
const db = getFirestore();
for (const g of (await db.collection('groups').get()).docs) {
  const ms = await g.ref.collection('members').get();
  const c = g.get('created')?.toDate?.()?.toISOString?.() ?? '';
  console.log(`GROUP "${g.get('name')}" id=${g.id} created=${c} admin=${g.get('ownerNick') || '-'} members(${ms.size}): ${ms.docs.map((m) => m.get('nick')).join(', ')}`);
}
const us = await db.collection('users').get();
const byG = {};
for (const u of us.docs) byG[u.get('gid') || '(none)'] = [...(byG[u.get('gid') || '(none)'] || []), u.get('nick')];
for (const [g, n] of Object.entries(byG)) console.log(`USERS in ${g}: ${n.join(', ')}`);
