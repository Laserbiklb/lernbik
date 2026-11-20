// One-time cleanup (2026-11-20): moves everyone from all other groups into "VHS 277" and deletes
// the other groups. MODE=dry only prints the plan; MODE=apply does it. Prints names, never keys.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SA)) });
const db = getFirestore();
const apply = process.env.MODE === 'apply';
const norm = (s) => String(s || '').toLowerCase().replace(/[^a-z0-9а-яё]/g, '').replace(/^вхс/, 'vhs');

const groups = (await db.collection('groups').get()).docs;
const targets = groups.filter((g) => norm(g.get('name')).includes('277'));
if (targets.length !== 1) {
  console.log('Expected exactly one group with 277 in the name, found:', targets.map((g) => `${g.get('name')} (${g.id})`));
  for (const g of groups) console.log(`- ${g.get('name')} (${g.id})`);
  process.exit(1);
}
const target = targets[0];
const tm = db.collection('groups').doc(target.id).collection('members');
const num = (x) => (typeof x === 'number' ? x : 0);

async function show(g) {
  const ms = await g.ref.collection('members').get();
  const hw = await g.ref.collection('hw').get();
  const news = await g.ref.collection('news').get();
  console.log(`\n${g.id === target.id ? 'TARGET' : 'MOVE+DELETE'}: "${g.get('name')}" (${g.id}), admin: ${g.get('ownerNick') || (g.id === 'vhs-lueneburg' ? 'Laserbik' : '?')}`);
  console.log(`  members ${ms.size}: ${ms.docs.map((m) => `${m.get('nick') || '—'} (${num(m.get('words'))} w, ${num(m.get('xp'))} xp)`).join(', ')}`);
  console.log(`  tasks ${hw.size}: ${hw.docs.map((h) => h.get('text') ? String(h.get('text')).slice(0, 40) : h.id).join(' | ')}`);
  console.log(`  notices ${news.size}`);
  return ms;
}

await show(target);
let moved = 0;
for (const g of groups) {
  if (g.id === target.id) continue;
  const ms = await show(g);
  if (!apply) continue;
  for (const m of ms.docs) {
    const t = await tm.doc(m.id).get();
    const d = m.data();
    if (!t.exists) await tm.doc(m.id).set(d);
    else {
      const o = t.data();
      await tm.doc(m.id).set({ ...d, ...o, words: Math.max(num(d.words), num(o.words)), topics: Math.max(num(d.topics), num(o.topics)), xp: Math.max(num(d.xp), num(o.xp)), streak: Math.max(num(d.streak), num(o.streak)) });
    }
    moved++;
  }
  // Only the homework of the old course group comes along (same ids, so "done" ticks stay).
  if (g.id === 'vhs-lueneburg') {
    for (const h of (await g.ref.collection('hw').get()).docs) {
      if (h.get('deleted') === true) continue;
      await db.collection('groups').doc(target.id).collection('hw').doc(h.id).set(h.data());
      console.log('  task copied:', String(h.get('text') || '').slice(0, 40));
    }
  }
  const us = await db.collection('users').where('gid', '==', g.id).get();
  for (const u of us.docs) await u.ref.update({ gid: target.id });
  console.log(`  users switched: ${us.size}`);
  await db.recursiveDelete(g.ref);
  console.log('  deleted');
}

// Same name twice → one entry: keep the member whose account was seen last, with the best stats.
const users = (await db.collection('users').get()).docs;
const seenOf = new Map();
for (const u of users) {
  const m = u.get('mid');
  if (!m) continue;
  const t = u.get('seen')?.toMillis?.() ?? 0;
  seenOf.set(m, Math.max(seenOf.get(m) ?? -1, t));
}
const all = (await tm.get()).docs;
const byNick = new Map();
for (const m of all) {
  const k = String(m.get('nick') || '').trim().toLowerCase();
  if (!k) continue;
  byNick.set(k, [...(byNick.get(k) || []), m]);
}
let owner = null;
for (const [k, ms] of byNick) {
  ms.sort((a, b) => (seenOf.get(b.id) ?? -1) - (seenOf.get(a.id) ?? -1));
  const keep = ms[0];
  if (k === 'laserbik') owner = keep;
  if (ms.length < 2) continue;
  const best = (f) => Math.max(...ms.map((m) => num(m.get(f))));
  console.log(`duplicate "${keep.get('nick')}": ${ms.length} → 1 (words ${best('words')}, xp ${best('xp')})`);
  if (!apply) continue;
  await keep.ref.set({ words: best('words'), topics: best('topics'), xp: best('xp'), streak: best('streak') }, { merge: true });
  for (const m of ms.slice(1)) await m.ref.delete();
}
if (owner) {
  console.log(`admin of "${target.get('name')}": ${owner.get('nick')}`);
  if (apply) await target.ref.set({ ownerMid: owner.id, ownerNick: owner.get('nick') }, { merge: true });
}
console.log(apply ? `\nDone, members moved: ${moved}` : '\nDry run only (MODE=apply to do it).');
