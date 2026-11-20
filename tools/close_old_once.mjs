// One-time (2026-11-20): deletes the old group "vhs-lueneburg" again (old app versions recreated it)
// and puts anyone who was pulled back into it into "VHS Lüneburg 277". Prints names only.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SA)) });
const db = getFirestore();
const old = db.collection('groups').doc('vhs-lueneburg');
const target = db.collection('groups').doc('YUE5TLPU62');
console.log('target:', (await target.get()).get('name'));
const g = await old.get();
console.log('old group doc exists:', g.exists, g.exists ? g.get('name') : '');
for (const m of (await old.collection('members').get()).docs) {
  const t = await target.collection('members').doc(m.id).get();
  if (!t.exists) await target.collection('members').doc(m.id).set(m.data());
  console.log('member moved:', m.get('nick'));
}
const us = await db.collection('users').where('gid', '==', 'vhs-lueneburg').get();
for (const u of us.docs) {
  await u.ref.update({ gid: 'YUE5TLPU62' });
  console.log('user moved:', u.get('nick'));
}
await db.recursiveDelete(old);
console.log('deleted');
