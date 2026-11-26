// Sends homework and word-review reminders. Needs FIREBASE_SA (service account JSON).
// GitHub starts scheduled runs only a few times a day, so the workflow keeps this script running
// for hours (LOOP_MIN) and it checks every TICK_MIN minutes; then the workflow starts itself again.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SA)) });
const db = getFirestore();
const msg = getMessaging();

const T = {
  de: { hw: (n) => n === 1 ? '1 Hausaufgabe ist noch offen' : `${n} Hausaufgaben sind noch offen`,
        rev: (n) => `📚 ${n} Wörter warten aufs Wiederholen`,
        streak: (s) => `🔥 Serie: ${s} Tage – lerne heute ein paar Wörter!`,
        learn: '🌱 Heute noch nichts gelernt – lerne ein paar neue Wörter!', title: 'Lernbik',
        newHw: '📝 Neue Hausaufgabe', till: 'bis' },
  ru: { hw: (n) => `Несделанных заданий: ${n}`,
        rev: (n) => `📚 Пора повторить слов: ${n}`,
        streak: (s) => `🔥 Серия ${s} дн. — не прерывай, повтори пару слов!`,
        learn: '🌱 Сегодня ты ещё не учил — выучи пару новых слов!', title: 'Lernbik',
        newHw: '📝 Новое домашнее задание', till: 'до' },
  en: { hw: (n) => n === 1 ? '1 homework task is still open' : `${n} homework tasks are still open`,
        rev: (n) => `📚 ${n} words are due for review`,
        streak: (s) => `🔥 Streak: ${s} days – learn a few words today!`,
        learn: '🌱 Nothing learned yet today – learn a few new words!', title: 'Lernbik',
        newHw: '📝 New homework', till: 'due' },
};
const pad = (n) => String(n).padStart(2, '0');
const ymd = (d) => `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;

let now = Date.now();
let groups = new Map();
async function groupInfo(gid) {
  if (!groups.has(gid)) {
    const hw = await db.collection('groups').doc(gid).collection('hw').where('deleted', '==', false).get();
    groups.set(gid, hw.docs.map((d) => ({ id: d.id, due: d.get('due') || '' })));
  }
  return groups.get(gid);
}

// Words due for review (seen words whose next repetition time has passed), from the learning progress wk/{key}.
const MIN_DUE = 5;
async function dueWords(key) {
  try {
    const w = await db.collection('wk').doc(key).get();
    const o = JSON.parse(w.get('json') || '{}');
    return Object.values(o.prog || {}).filter((b) => b && typeof b.due === 'number' && b.due <= now).length;
  } catch {
    return 0;
  }
}

const WINDOW = 180;
const LOOP_MIN = Number(process.env.LOOP_MIN) || 0;
const TICK_MIN = Number(process.env.TICK_MIN) || 3;

// Bad tokens (app removed, browser data cleared) are dropped from the user.
async function push(u, tokens, title, body) {
  const r = await msg.sendEachForMulticast({
    tokens,
    notification: { title, body },
    android: { priority: 'high' },
    webpush: { fcmOptions: { link: 'https://lernbik.web.app/' } },
  });
  const bad = tokens.filter((_, i) => {
    const e = r.responses[i].error;
    return e && /registration-token-not-registered|invalid-argument|invalid-registration-token/.test(e.code);
  });
  return { ok: r.successCount, bad };
}

// New homework: pushed once to everyone in the group who has reminders on (except its author).
// meta/remind.hwSince remembers up to which creation time homework was already announced.
const metaRef = db.collection('meta').doc('remind');
let hwSince = null;
async function newHomework(users) {
  if (!hwSince) {
    const m = await metaRef.get();
    hwSince = m.get('hwSince') || Timestamp.now();
    if (!m.exists) await metaRef.set({ hwSince });
  }
  const byGroup = new Map();
  for (const u of users.docs) {
    const d = u.data();
    if (!d.gid || !(Array.isArray(d.tokens) && d.tokens.length)) continue;
    if (!byGroup.has(d.gid)) byGroup.set(d.gid, []);
    byGroup.get(d.gid).push(u);
  }
  let max = hwSince, sent = 0;
  for (const [gid, us] of byGroup) {
    const q = await db.collection('groups').doc(gid).collection('hw').where('created', '>', hwSince).get();
    for (const h of q.docs) {
      const c = h.get('created');
      if (c && c.toMillis() > max.toMillis()) max = c;
      if (h.get('deleted')) continue;
      const text = String(h.get('text') || '').replace(/\s+/g, ' ').slice(0, 140);
      const due = String(h.get('due') || '');
      const dueDe = due.length === 10 ? `${due.slice(8, 10)}.${due.slice(5, 7)}.` : '';
      for (const u of us) {
        const d = u.data();
        if (d.nick && d.nick === h.get('by')) continue;
        const t = T[d.lang] || T.de;
        const r = await push(u, d.tokens, dueDe ? `${t.newHw} (${t.till} ${dueDe})` : t.newHw, text);
        if (r.bad.length) await u.ref.update({ tokens: FieldValue.arrayRemove(...r.bad) });
        sent += r.ok;
      }
    }
  }
  if (max !== hwSince) {
    hwSince = max;
    await metaRef.set({ hwSince }, { merge: true });
  }
  return sent;
}

async function tick(verbose) {
  now = Date.now();
  groups = new Map();
  const users = await db.collection('users').where('remindOn', '==', true).get();
  let sent = 0;
  try {
    const n = await newHomework(users);
    if (n) console.log(`${new Date(now).toISOString().slice(0, 16)} new homework pushes: ${n}`);
  } catch (e) {
    console.log('new homework failed:', e.message);
  }
  for (const u of users.docs) {
    const d = u.data();
    const tokens = Array.isArray(d.tokens) ? d.tokens : [];
    if (!tokens.length || !d.gid) continue;
    const local = new Date(now + (Number(d.tz) || 60) * 60000);
    const times = Array.isArray(d.remind) ? d.remind : ['10:00', '22:00'];
    const today = ymd(local);
    // GitHub starts scheduled runs late or skips some, so a reminder goes out at the first run after
    // its time (up to WINDOW minutes late), once a day.
    const mins = local.getUTCHours() * 60 + local.getUTCMinutes();
    const toMin = (t) => Number(t.slice(0, 2)) * 60 + Number(t.slice(3, 5));
    const dueSlots = times.filter((t) => mins >= toMin(t) && mins - toMin(t) <= WINDOW && !(d.sent && d.sent[t] === today)).sort();
    if (!dueSlots.length) continue;
    const slot = dueSlots.at(-1);

    const hw = await groupInfo(d.gid);
    const done = d.done || {};
    const open = hw.filter((h) => !done[h.id] && (!h.due || h.due >= today)).length;

    let streak = 0, learnedToday = true;
    if (d.mid) {
      const m = await db.collection('groups').doc(d.gid).collection('members').doc(d.mid).get();
      streak = m.get('streak') || 0;
      const y = new Date(local.getTime() - 86400000);
      learnedToday = m.get('day') === today;
      if (m.get('day') !== today && m.get('day') !== ymd(y)) streak = 0;
    }
    const lastSlot = [...times].sort().at(-1) === slot;
    const atRisk = streak > 0 && !learnedToday;
    const due = await dueWords(u.id);
    const review = due >= MIN_DUE ? due : 0;
    // Nothing open and nothing to review, but nothing learned today either: suggest a few new words.
    const nudge = !open && !review && !learnedToday;
    if (!open && !review && !nudge) continue;

    const t = T[d.lang] || T.de;
    const body = [
      open ? t.hw(open) : null,
      review ? t.rev(review) : null,
      atRisk && (lastSlot || nudge) ? t.streak(streak) : nudge ? t.learn : null,
    ].filter(Boolean).join('\n');
    const r = await push(u, tokens, t.title, body);
    const bad = r.bad;
    const upd = Object.fromEntries(dueSlots.map((t) => [`sent.${t}`, today]));
    if (bad.length) upd.tokens = FieldValue.arrayRemove(...bad);
    await u.ref.update(upd);
    sent += r.ok;
  }
  const withTokens = users.docs.filter((u) => (u.get('tokens') || []).length).length;
  if (sent || verbose) console.log(`${new Date(now).toISOString().slice(0, 16)} users with reminders: ${users.size}, of them with a device for push: ${withTokens}, notifications sent: ${sent}`);
}

const start = Date.now();
await tick(true);
while (Date.now() - start < LOOP_MIN * 60000) {
  await new Promise((r) => setTimeout(r, TICK_MIN * 60000));
  try {
    await tick(false);
  } catch (e) {
    console.log('tick failed:', e.message);
  }
}
console.log('done');
