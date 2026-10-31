// Security tests for firestore.rules and storage.rules.
// Run:  cd security-tests && npm install && npm test   (needs Java for the emulator)
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc, arrayUnion, collection, deleteDoc, doc, getDoc, getDocs, increment, query, serverTimestamp,
  setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let env;

const verified = (uid, email) => ({ email: email ?? `${uid}@test.com`, email_verified: true });

const listingData = (ownerId, extra = {}) => ({
  title: 'iPhone 15 Pro 256GB',
  description: 'Like new, with box and charger.',
  price: 650,
  currency: 'JOD',
  negotiable: true,
  categoryId: 'mobiles',
  city: 'amman',
  condition: 'used',
  images: ['https://example.com/a.jpg'],
  contactPhone: '+962790000000',
  showPhone: true,
  ownerName: 'Alice',
  searchKeywords: ['ip', 'iph', 'iphone'],
  ownerId,
  status: 'pending',
  rejectionReason: '',
  featured: false,
  views: 0,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...extra,
});

const as = (uid, token) => env.authenticatedContext(uid, token ?? verified(uid)).firestore();
const guest = () => env.unauthenticatedContext().firestore();

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-souqna',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync('../storage.rules', 'utf8'), host: '127.0.0.1', port: 9199 },
  });
});

after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (db) => {
    await setDoc(doc(db, 'categories/mobiles'), { nameEn: 'Mobiles', nameAr: 'موبايلات', icon: 'phone', order: 1, active: true });
    for (const [uid, status] of [['alice', 'active'], ['bob', 'active'], ['admin', 'active'], ['banned', 'banned']]) {
      await setDoc(doc(db, `users/${uid}`), { name: uid, photoUrl: '', city: '', bio: '', status, createdAt: new Date() });
      await setDoc(doc(db, `users/${uid}/private/info`), { email: `${uid}@test.com`, phone: '+962700000000' });
    }
    await setDoc(doc(db, 'admins/admin'), { grantedBy: 'console', createdAt: new Date() });
    await setDoc(doc(db, 'listings/active1'), { ...listingData('alice'), status: 'active', createdAt: new Date(), updatedAt: new Date() });
    await setDoc(doc(db, 'listings/pending1'), { ...listingData('alice'), status: 'pending', createdAt: new Date(), updatedAt: new Date() });
  });
});

describe('users & privacy', () => {
  test('public profile is readable by anyone', async () => {
    await assertSucceeds(getDoc(doc(guest(), 'users/alice')));
  });

  test('private contact info is hidden from other users and guests', async () => {
    await assertFails(getDoc(doc(guest(), 'users/alice/private/info')));
    await assertFails(getDoc(doc(as('bob'), 'users/alice/private/info')));
    await assertSucceeds(getDoc(doc(as('alice'), 'users/alice/private/info')));
    await assertSucceeds(getDoc(doc(as('admin'), 'users/alice/private/info')));
  });

  test('registration creates a clean profile; cannot self-assign status or extra fields', async () => {
    const db = as('carol', { email: 'carol@test.com', email_verified: false });
    await assertFails(setDoc(doc(db, 'users/carol'), { name: 'Carol', photoUrl: '', city: '', bio: '', status: 'active', createdAt: serverTimestamp(), role: 'admin' }));
    await assertFails(setDoc(doc(db, 'users/carol'), { name: 'Carol', photoUrl: '', city: '', bio: '', status: 'banned', createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db, 'users/carol'), { name: 'Carol', photoUrl: '', city: '', bio: '', status: 'active', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db, 'users/carol/private/info'), { email: 'someone-else@test.com', phone: '' }));
    await assertSucceeds(setDoc(doc(db, 'users/carol/private/info'), { email: 'carol@test.com', phone: '' }));
  });

  test('cannot create a profile for someone else', async () => {
    await assertFails(setDoc(doc(as('bob'), 'users/mallory'), { name: 'Mallory', photoUrl: '', city: '', bio: '', status: 'active', createdAt: serverTimestamp() }));
  });

  test('user can edit own public fields but not status', async () => {
    await assertSucceeds(updateDoc(doc(as('alice'), 'users/alice'), { name: 'Alice B', city: 'amman' }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { status: 'banned', name: 'x2' }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { createdAt: new Date(0) }));
    await assertFails(updateDoc(doc(as('alice'), 'users/alice'), { name: 'x'.repeat(61) }));
    await assertFails(updateDoc(doc(as('bob'), 'users/alice'), { name: 'Hacked' }));
  });

  test('banned user cannot unban themselves or edit profile', async () => {
    await assertFails(updateDoc(doc(as('banned'), 'users/banned'), { status: 'active' }));
    await assertFails(updateDoc(doc(as('banned'), 'users/banned'), { name: 'New name' }));
  });

  test('only admins can ban, and not themselves', async () => {
    await assertFails(updateDoc(doc(as('bob'), 'users/alice'), { status: 'banned' }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'users/alice'), { status: 'banned', statusChangedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('admin'), 'users/admin'), { status: 'banned' }));
  });

  test('favorites are private to the owner', async () => {
    await assertSucceeds(setDoc(doc(as('bob'), 'users/bob/favorites/active1'), { createdAt: serverTimestamp() }));
    await assertFails(getDocs(collection(as('alice'), 'users/bob/favorites')));
    await assertFails(setDoc(doc(as('alice'), 'users/bob/favorites/x'), { createdAt: serverTimestamp() }));
  });
});

describe('admin privilege escalation', () => {
  test('a user cannot make themselves admin', async () => {
    await assertFails(setDoc(doc(as('bob'), 'admins/bob'), { grantedBy: 'bob', createdAt: serverTimestamp() }));
  });

  test('an admin can grant admin; cannot remove themselves', async () => {
    await assertSucceeds(setDoc(doc(as('admin'), 'admins/bob'), { grantedBy: 'admin', createdAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(as('admin'), 'admins/admin')));
  });

  test('non-admins cannot list admins', async () => {
    await assertFails(getDocs(collection(as('bob'), 'admins')));
    await assertSucceeds(getDoc(doc(as('bob'), 'admins/bob'))); // own (non-existent) admin doc check
  });

  test('settings and categories are admin-only writes', async () => {
    const s = { autoApprove: true, maxImages: 8, supportPhone: '', supportEmail: '', announcementEn: '', announcementAr: '', updatedAt: serverTimestamp() };
    await assertFails(setDoc(doc(as('bob'), 'settings/app'), s));
    await assertSucceeds(setDoc(doc(as('admin'), 'settings/app'), s));
    await assertFails(setDoc(doc(as('bob'), 'categories/x1'), { nameEn: 'X', nameAr: 'س', icon: 'car', order: 1, active: true }));
    await assertSucceeds(setDoc(doc(as('admin'), 'categories/x1'), { nameEn: 'X', nameAr: 'س', icon: 'car', order: 1, active: true }));
    await assertSucceeds(getDoc(doc(guest(), 'settings/app')));
  });
});

describe('listings', () => {
  test('guests see active ads but not pending ones', async () => {
    await assertSucceeds(getDoc(doc(guest(), 'listings/active1')));
    await assertFails(getDoc(doc(guest(), 'listings/pending1')));
    await assertFails(getDoc(doc(as('bob'), 'listings/pending1')));
    await assertSucceeds(getDoc(doc(as('alice'), 'listings/pending1')));
    await assertSucceeds(getDoc(doc(as('admin'), 'listings/pending1')));
  });

  test('public browse query must be restricted to active ads', async () => {
    await assertSucceeds(getDocs(query(collection(guest(), 'listings'), where('status', '==', 'active'))));
    await assertFails(getDocs(collection(guest(), 'listings')));
  });

  test('verified user can post a pending ad', async () => {
    await assertSucceeds(setDoc(doc(as('bob'), 'listings/new1'), listingData('bob')));
  });

  test('unverified, banned and guest users cannot post', async () => {
    await assertFails(setDoc(doc(as('bob', { email: 'bob@test.com', email_verified: false }), 'listings/n1'), listingData('bob')));
    await assertFails(setDoc(doc(as('banned'), 'listings/n2'), listingData('banned')));
    await assertFails(setDoc(doc(guest(), 'listings/n3'), listingData('nobody')));
  });

  test('cannot post as someone else, self-approve, self-feature or fake views', async () => {
    await assertFails(setDoc(doc(as('bob'), 'listings/n1'), listingData('alice')));
    await assertFails(setDoc(doc(as('bob'), 'listings/n2'), listingData('bob', { status: 'active' })));
    await assertFails(setDoc(doc(as('bob'), 'listings/n3'), listingData('bob', { featured: true })));
    await assertFails(setDoc(doc(as('bob'), 'listings/n4'), listingData('bob', { views: 9999 })));
  });

  test('self-approve is allowed only when admin enabled auto-approve', async () => {
    await seed((db) => setDoc(doc(db, 'settings/app'), { autoApprove: true }));
    await assertSucceeds(setDoc(doc(as('bob'), 'listings/n1'), listingData('bob', { status: 'active' })));
  });

  test('validation: bad price, unknown category, oversized title, missing images, hidden phone leak', async () => {
    await assertFails(setDoc(doc(as('bob'), 'listings/v1'), listingData('bob', { price: -5 })));
    await assertFails(setDoc(doc(as('bob'), 'listings/v2'), listingData('bob', { categoryId: 'nope' })));
    await assertFails(setDoc(doc(as('bob'), 'listings/v3'), listingData('bob', { title: 'x'.repeat(101) })));
    await assertFails(setDoc(doc(as('bob'), 'listings/v4'), listingData('bob', { images: [] })));
    await assertFails(setDoc(doc(as('bob'), 'listings/v5'), listingData('bob', { showPhone: false, contactPhone: '+962700000000' })));
    await assertFails(setDoc(doc(as('bob'), 'listings/v6'), listingData('bob', { hacked: true })));
  });

  test('owner edit sends ad back to pending and cannot touch moderation fields', async () => {
    const db = as('alice');
    await assertFails(updateDoc(doc(db, 'listings/active1'), { title: 'iPhone 15 Pro Max', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(db, 'listings/active1'), { title: 'iPhone 15 Pro Max', status: 'pending', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'listings/active1'), { featured: true }));
    await assertFails(updateDoc(doc(db, 'listings/active1'), { status: 'active', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(db, 'listings/active1'), { ownerId: 'bob' }));
  });

  test('owner can mark an active ad as sold; others cannot', async () => {
    await assertFails(updateDoc(doc(as('bob'), 'listings/active1'), { status: 'sold', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(as('alice'), 'listings/active1'), { status: 'sold', updatedAt: serverTimestamp() }));
  });

  test('views can only be incremented by one, by non-owners', async () => {
    await assertSucceeds(updateDoc(doc(as('bob'), 'listings/active1'), { views: increment(1) }));
    await assertFails(updateDoc(doc(as('bob'), 'listings/active1'), { views: 500 }));
    await assertFails(updateDoc(doc(as('alice'), 'listings/active1'), { views: increment(1) }));
    await assertFails(updateDoc(doc(guest(), 'listings/active1'), { views: increment(1) }));
  });

  test('admin can approve, reject and feature; users cannot', async () => {
    await assertFails(updateDoc(doc(as('bob'), 'listings/pending1'), { status: 'active' }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'listings/pending1'), { status: 'active', rejectionReason: '', moderatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'listings/pending1'), { featured: true }));
    await assertSucceeds(updateDoc(doc(as('admin'), 'listings/pending1'), { status: 'rejected', rejectionReason: 'Blurry photos' }));
    await assertFails(updateDoc(doc(as('admin'), 'listings/pending1'), { title: 'Admin rewrote it' }));
  });

  test('only owner or admin can delete', async () => {
    await assertFails(deleteDoc(doc(as('bob'), 'listings/active1')));
    await assertSucceeds(deleteDoc(doc(as('alice'), 'listings/pending1')));
    await assertSucceeds(deleteDoc(doc(as('admin'), 'listings/active1')));
  });
});

describe('reports', () => {
  const report = (uid) => ({ reporterId: uid, listingId: 'active1', listingTitle: 'iPhone', reason: 'fraud', details: '', status: 'open', createdAt: serverTimestamp() });

  test('signed-in users can report; only admins can read or resolve', async () => {
    await assertFails(addDoc(collection(guest(), 'reports'), report('x')));
    await assertFails(addDoc(collection(as('bob'), 'reports'), report('alice')));
    await assertFails(addDoc(collection(as('bob'), 'reports'), { ...report('bob'), status: 'resolved' }));
    const r = await assertSucceeds(addDoc(collection(as('bob'), 'reports'), report('bob')));
    await assertFails(getDoc(doc(as('bob'), `reports/${r.id}`)));
    await assertSucceeds(getDoc(doc(as('admin'), `reports/${r.id}`)));
    await assertSucceeds(updateDoc(doc(as('admin'), `reports/${r.id}`), { status: 'resolved', handledAt: serverTimestamp() }));
  });
});

describe('chats', () => {
  const chat = (buyer, seller, listing = 'active1') => ({
    participants: [buyer, seller], buyerId: buyer, sellerId: seller, listingId: listing,
    listingTitle: 'iPhone', listingImage: '', names: { [buyer]: buyer, [seller]: seller },
    lastMessage: '', lastSenderId: '', lastMessageAt: serverTimestamp(), unread: { [buyer]: 0, [seller]: 0 }, createdAt: serverTimestamp(),
  });

  test('buyer opens a chat on an active listing with the real owner', async () => {
    await assertSucceeds(getDoc(doc(as('bob'), 'chats/active1_bob')));
    await assertSucceeds(setDoc(doc(as('bob'), 'chats/active1_bob'), chat('bob', 'alice')));
  });

  test('cannot spoof chat id, seller, or chat on pending ads / own ads', async () => {
    await assertFails(setDoc(doc(as('bob'), 'chats/active1_carol'), chat('bob', 'alice')));
    await assertFails(setDoc(doc(as('bob'), 'chats/active1_bob'), chat('bob', 'admin')));
    await assertFails(setDoc(doc(as('bob'), 'chats/pending1_bob'), chat('bob', 'alice', 'pending1')));
    await assertFails(setDoc(doc(as('alice'), 'chats/active1_alice'), chat('alice', 'alice')));
    await assertFails(setDoc(doc(as('bob', { email: 'bob@test.com', email_verified: false }), 'chats/active1_bob'), chat('bob', 'alice')));
  });

  test('only participants read and send messages; sender cannot be spoofed', async () => {
    await seed((db) => setDoc(doc(db, 'chats/active1_bob'), { ...chat('bob', 'alice'), lastMessageAt: new Date(), createdAt: new Date() }));
    const bob = as('bob');
    const batch = writeBatch(bob);
    batch.set(doc(bob, 'chats/active1_bob/messages/m1'), { senderId: 'bob', text: 'Is it available?', createdAt: serverTimestamp() });
    batch.update(doc(bob, 'chats/active1_bob'), { lastMessage: 'Is it available?', lastSenderId: 'bob', lastMessageAt: serverTimestamp(), 'unread.alice': increment(1) });
    await assertSucceeds(batch.commit());

    await assertSucceeds(getDocs(collection(as('alice'), 'chats/active1_bob/messages')));
    await assertFails(getDocs(collection(as('admin2'), 'chats/active1_bob/messages')));
    await assertFails(getDoc(doc(as('carol'), 'chats/active1_bob')));
    await assertFails(setDoc(doc(as('bob'), 'chats/active1_bob/messages/m2'), { senderId: 'alice', text: 'fake', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(as('carol'), 'chats/active1_bob/messages/m3'), { senderId: 'carol', text: 'hi', createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as('bob'), 'chats/active1_bob/messages/m1'), { text: 'edited' }));
    await assertFails(updateDoc(doc(as('bob'), 'chats/active1_bob'), { participants: arrayUnion('carol') }));
    await assertSucceeds(getDocs(query(collection(as('alice'), 'chats'), where('participants', 'array-contains', 'alice'))));
    await assertFails(getDocs(collection(as('alice'), 'chats')));
  });
});

describe('storage', () => {
  const img = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

  test('users upload images only to their own folder', async () => {
    const st = (uid, token) => env.authenticatedContext(uid, token ?? verified(uid)).storage();
    await assertSucceeds(uploadBytes(ref(st('bob'), 'listings/bob/a.jpg'), img, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st('bob'), 'listings/alice/a.jpg'), img, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st('bob'), 'listings/bob/a.html'), img, { contentType: 'text/html' }));
    await assertFails(uploadBytes(ref(st('bob', { email: 'b@t.com', email_verified: false }), 'listings/bob/b.jpg'), img, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), 'listings/x/a.jpg'), img, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st('bob'), 'listings/bob/big.jpg'), new Uint8Array(5 * 1024 * 1024 + 1), { contentType: 'image/jpeg' }));
  });
});
