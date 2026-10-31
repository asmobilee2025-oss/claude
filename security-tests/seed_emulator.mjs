// Seeds the LOCAL Firebase emulators with demo data (users, admin, categories,
// ads, a chat and a report). Never point this at production.
//
//   firebase emulators:start --config ../firebase.json --project demo-souqna
//   node seed_emulator.mjs [imagesDir]
//
// Demo logins (password: Test12345):
//   admin@souqna.test (admin) · sara@souqna.test · omar@souqna.test
import { readdirSync, readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const PROJECT = 'demo-souqna';
const BUCKET = 'demo-souqna.appspot.com';
const HOST = process.env.EMULATOR_HOST ?? '127.0.0.1';
const AUTH = `http://${HOST}:9099`;
const FS = `http://${HOST}:8080/v1/projects/${PROJECT}/databases/(default)/documents`;
const ST = `http://${HOST}:9199`;
const owner = { Authorization: 'Bearer owner' };
const imagesDir = process.argv[2];

if (!['127.0.0.1', 'localhost'].includes(HOST)) throw new Error('Refusing to seed a non-local host');

const toValue = (v) => {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'object') return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
  return { stringValue: String(v) };
};

async function put(path, data) {
  const res = await fetch(`${FS}/${path}`, {
    method: 'PATCH',
    headers: { ...owner, 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, toValue(v)])) }),
  });
  if (!res.ok) throw new Error(`${path}: ${res.status} ${await res.text()}`);
}

async function createUser(email, name) {
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'Test12345', displayName: name, returnSecureToken: true }),
  });
  const j = await res.json();
  if (!j.localId) throw new Error(JSON.stringify(j));
  await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/projects/${PROJECT}/accounts:update`, {
    method: 'POST',
    headers: { ...owner, 'Content-Type': 'application/json' },
    body: JSON.stringify({ localId: j.localId, emailVerified: true }),
  });
  return j.localId;
}

const PIXEL = Buffer.from('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==', 'base64');

async function upload(uid, file) {
  const bytes = file ? readFileSync(join(imagesDir, file)) : PIXEL;
  const name = `listings/${uid}/${file ?? 'placeholder.jpg'}`;
  const res = await fetch(`${ST}/v0/b/${BUCKET}/o?name=${encodeURIComponent(name)}`, {
    method: 'POST',
    headers: { ...owner, 'Content-Type': 'image/jpeg' },
    body: bytes,
  });
  if (!res.ok) throw new Error(`upload ${name}: ${res.status}`);
  return `${ST}/v0/b/${BUCKET}/o/${encodeURIComponent(name)}?alt=media`;
}

const keywords = (t) => {
  const out = new Set();
  for (const w of t.toLowerCase().replace(/[^\p{L}\p{N}\s]/gu, ' ').split(/\s+/).filter(Boolean)) {
    if (w.length === 1) out.add(w);
    for (let i = 2; i <= Math.min(w.length, 15); i++) out.add(w.slice(0, i));
  }
  return [...out].slice(0, 80);
};

const categories = [
  ['vehicles', 'Vehicles', 'سيارات ومركبات', 'car'], ['real-estate', 'Real Estate', 'عقارات', 'home'],
  ['mobiles', 'Mobiles & Tablets', 'موبايلات وتابلت', 'phone'], ['computers', 'Computers & Laptops', 'كمبيوتر ولابتوب', 'laptop'],
  ['electronics', 'Electronics', 'إلكترونيات', 'electronics'], ['furniture', 'Home & Furniture', 'أثاث ومنزل', 'furniture'],
  ['fashion', 'Fashion', 'أزياء وموضة', 'fashion'], ['jobs', 'Jobs', 'وظائف', 'jobs'], ['services', 'Services', 'خدمات', 'services'],
  ['pets', 'Pets', 'حيوانات أليفة', 'pets'], ['kids', 'Kids & Babies', 'أطفال ومستلزمات', 'kids'], ['sports', 'Sports & Hobbies', 'رياضة وهوايات', 'sports'],
];

const files = imagesDir && existsSync(imagesDir) ? readdirSync(imagesDir).filter((f) => f.endsWith('.jpg')) : [];
const imgs = (key) => files.filter((f) => f.startsWith(`${key}_`)).sort();

const now = Date.now();
const ago = (h) => new Date(now - h * 3600 * 1000);

const admin = await createUser('admin@souqna.test', 'Souqna Admin');
const sara = await createUser('sara@souqna.test', 'Sara Haddad');
const omar = await createUser('omar@souqna.test', 'Omar Khalil');
const people = { [admin]: ['Souqna Admin', 'admin@souqna.test', '+962790000001'], [sara]: ['Sara Haddad', 'sara@souqna.test', '+962790000002'], [omar]: ['Omar Khalil', 'omar@souqna.test', '+962790000003'] };
for (const [uid, [name, email, phone]] of Object.entries(people)) {
  await put(`users/${uid}`, { name, photoUrl: '', city: 'amman', bio: '', status: 'active', createdAt: ago(24 * 90) });
  await put(`users/${uid}/private/info`, { email, phone });
}
await put(`admins/${admin}`, { grantedBy: 'seed', createdAt: new Date() });
for (const [i, [id, en, ar, icon]] of categories.entries()) await put(`categories/${id}`, { nameEn: en, nameAr: ar, icon, order: i + 1, active: true });
await put('settings/app', {
  autoApprove: false, maxImages: 8, supportPhone: '+962790000000', supportEmail: 'support@souqna.test',
  announcementEn: 'Welcome to Souqna — post your first ad for free!', announcementAr: 'أهلاً بك في سوقنا — انشر إعلانك الأول مجاناً!', updatedAt: new Date(),
});

const ads = [
  [sara, 'iphone', 'iPhone 15 Pro 256GB – Natural Titanium', 'Like new, battery 96%, with original box and cable. No scratches.', 640, 'mobiles', 'amman', 'used', 'active', true, 2],
  [omar, 'galaxy', 'Samsung Galaxy S24 Ultra 512GB', 'Brand new sealed, international version, 1 year warranty.', 720, 'mobiles', 'irbid', 'new', 'active', false, 5],
  [sara, 'macbook', 'MacBook Air M3 13" 16GB/512GB', 'Used for 3 months, perfect condition, AppleCare until 2027.', 1050, 'computers', 'amman', 'used', 'active', true, 8],
  [omar, 'car', 'Toyota Camry 2021 Hybrid', 'Single owner, full service history, 48,000 km, inspection report available.', 21500, 'vehicles', 'zarqa', 'used', 'active', true, 12],
  [sara, 'car2', 'Hyundai Elantra 2019', 'Excellent condition, automatic, new tires.', 11200, 'vehicles', 'amman', 'used', 'active', false, 20],
  [omar, 'apartment', 'شقة للإيجار في عبدون 3 غرف', 'شقة مفروشة بالكامل، طابق ثالث، مصعد، موقف خاص، قريبة من الخدمات.', 650, 'real-estate', 'amman', 'used', 'active', false, 26],
  [sara, 'sofa', 'كنب زاوية مودرن بحالة ممتازة', 'كنب 7 مقاعد، قماش قابل للتنظيف، استعمال سنة واحدة فقط.', 380, 'furniture', 'salt', 'used', 'active', false, 30],
  [omar, 'ps5', 'PlayStation 5 Slim + 2 controllers', 'With 3 games: FC 25, Spider-Man 2, GT7.', 420, 'electronics', 'aqaba', 'used', 'active', true, 36],
  [sara, 'watch', 'Apple Watch Series 9 45mm', 'Midnight aluminium, all accessories included.', 260, 'electronics', 'amman', 'used', 'active', false, 40],
  [omar, 'bike', 'Mountain bike 29" – Shimano', '21 speed, aluminium frame, disc brakes.', 180, 'sports', 'madaba', 'used', 'active', false, 50],
  [sara, 'camera', 'Canon EOS R50 with 18-45mm lens', 'Shutter count 2,100. Perfect for content creators.', 590, 'electronics', 'amman', 'used', 'pending', false, 1],
  [omar, 'cat', 'Persian kitten, 3 months', 'Vaccinated, litter trained, very playful.', 150, 'pets', 'irbid', 'used', 'pending', false, 3],
  [sara, 'tv', 'Samsung 65" QLED 4K Smart TV', 'Sold to a happy buyer.', 499, 'electronics', 'amman', 'used', 'sold', false, 70],
];
const ids = [];
for (const [i, [uid, key, title, description, price, categoryId, city, condition, status, featured, h]] of ads.entries()) {
  const list = imgs(key);
  const images = list.length ? await Promise.all(list.map((f) => upload(uid, f))) : [await upload(uid)];
  const id = `demo${String(i + 1).padStart(2, '0')}`;
  ids.push(id);
  await put(`listings/${id}`, {
    title, description, price, currency: 'JOD', negotiable: i % 2 === 0, categoryId, city, condition, images,
    contactPhone: people[uid][2], showPhone: true, ownerName: people[uid][0], searchKeywords: keywords(title),
    ownerId: uid, status, rejectionReason: '', featured, views: 15 + i * 23, createdAt: ago(h), updatedAt: ago(h),
  });
}

const chatId = `${ids[0]}_${omar}`;
await put(`chats/${chatId}`, {
  participants: [omar, sara], buyerId: omar, sellerId: sara, listingId: ids[0], listingTitle: ads[0][2],
  listingImage: '', names: { [omar]: 'Omar Khalil', [sara]: 'Sara Haddad' }, lastMessage: 'Sure, tomorrow at 5pm works.',
  lastSenderId: sara, lastMessageAt: ago(0.2), unread: { [omar]: 1, [sara]: 0 }, createdAt: ago(1),
});
const msgs = [[omar, 'Hi, is the iPhone still available?', 1], [sara, 'Yes it is! Battery is 96%.', 0.9], [omar, 'Would you take 600 JOD? Can we meet in Abdoun?', 0.5], [sara, 'Sure, tomorrow at 5pm works.', 0.2]];
for (const [i, [s, text, h]] of msgs.entries()) await put(`chats/${chatId}/messages/m${i}`, { senderId: s, text, createdAt: ago(h) });

await put('reports/demo-report', { reporterId: omar, listingId: ids[4], listingTitle: ads[4][2], reason: 'wrongCategory', details: 'Price seems wrong.', status: 'open', createdAt: ago(2) });

console.log(`Seeded: 3 users (admin ${admin}), ${categories.length} categories, ${ads.length} ads, 1 chat, 1 report.`);
