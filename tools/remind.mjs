// Sends homework and word-review reminders. Runs every 30 minutes from GitHub Actions.
// Needs FIREBASE_SA (service account JSON) in the environment.
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

initializeApp({ credential: cert(JSON.parse(process.env.FIREBASE_SA)) });
const db = getFirestore();
const msg = getMessaging();

const T = {
  de: { hw: (n) => n === 1 ? '1 Hausaufgabe ist noch offen' : `${n} Hausaufgaben sind noch offen`,
        rev: (n) => `📚 ${n} Wörter warten aufs Wiederholen`,
        streak: (s) => `🔥 Serie: ${s} Tage – lerne heute ein paar Wörter!`, title: 'Lernbik' },
  ru: { hw: (n) => `Несделанных заданий: ${n}`,
        rev: (n) => `📚 Пора повторить слов: ${n}`,
        streak: (s) => `🔥 Серия ${s} дн. — не прерывай, повтори пару слов!`, title: 'Lernbik' },
  en: { hw: (n) => n === 1 ? '1 homework task is still open' : `${n} homework tasks are still open`,
        rev: (n) => `📚 ${n} words are due for review`,
        streak: (s) => `🔥 Streak: ${s} days – learn a few words today!`, title: 'Lernbik' },
};
const pad = (n) => String(n).padStart(2, '0');
const ymd = (d) => `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;

const now = Date.now();
const groups = new Map();
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

const users = await db.collection('users').where('remindOn', '==', true).get();
let sent = 0;
for (const u of users.docs) {
  const d = u.data();
  const tokens = Array.isArray(d.tokens) ? d.tokens : [];
  if (!tokens.length || !d.gid) continue;
  const local = new Date(now + (Number(d.tz) || 60) * 60000);
  const slot = `${pad(local.getUTCHours())}:${local.getUTCMinutes() < 30 ? '00' : '30'}`;
  const times = Array.isArray(d.remind) ? d.remind : ['10:00', '22:00'];
  const today = ymd(local);
  if (!times.includes(slot) || (d.sent && d.sent[slot] === today)) continue;

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
  if (!open && !review && !(atRisk && lastSlot)) continue;

  const t = T[d.lang] || T.de;
  const body = [open ? t.hw(open) : null, review ? t.rev(review) : null, atRisk ? t.streak(streak) : null].filter(Boolean).join('\n');
  const r = await msg.sendEachForMulticast({
    tokens,
    notification: { title: t.title, body },
    android: { priority: 'high' },
    webpush: { fcmOptions: { link: 'https://lernbik.web.app/' } },
  });
  const bad = tokens.filter((_, i) => {
    const e = r.responses[i].error;
    return e && /registration-token-not-registered|invalid-argument|invalid-registration-token/.test(e.code);
  });
  const upd = { [`sent.${slot}`]: today };
  if (bad.length) upd.tokens = FieldValue.arrayRemove(...bad);
  await u.ref.update(upd);
  sent += r.successCount;
}
console.log(`users checked: ${users.size}, notifications sent: ${sent}`);
