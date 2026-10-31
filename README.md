# Souqna · سوقنا

A bilingual (Arabic / English) classifieds marketplace built with **Flutter + Firebase**.
It runs on Android, iOS and web from one codebase, and it includes a full **user dashboard**
and **admin dashboard**.

## Features

**Buyers and sellers**
- Email sign-up and login, with email verification, password reset and password change.
- Arabic (RTL) and English, switchable at any time. Light, dark and system themes.
- Home: search, category strip, featured ads, latest ads, and an admin announcement banner.
- Browse: search, category chips, filters (city, price range, condition), sort options, infinite scroll.
- Ad page: photo gallery with full-screen zoom, details, seller card, chat, call, WhatsApp,
  share, favorite, report, more ads from the same seller, and safety tips.
- Post and edit ads: up to N photos (N is set by the admin), choose the cover photo, client-side validation,
  upload progress. Editing an ad sends it back for review.
- Real-time chat with unread badges.
- User dashboard: stats (active ads, pending ads, total views), my ads grouped by status
  (edit, mark as sold, delete), favorites, profile with avatar, and settings.
- Public seller profile page.

**Admins** (`/admin`, responsive: side rail on desktop, drawer on mobile)
- Overview: live counts and a breakdown of ads by status.
- Ad moderation: approve, reject with a reason, feature or unfeature, delete, search.
- Users: search and filter, ban or unban, grant or revoke admin, view private contact details.
- Categories: create, edit, enable or disable, delete. One tap loads 12 starter categories in both languages.
- Reports: take down the reported ad, resolve, dismiss or reopen.
- App settings: auto-approve on or off, maximum photos per ad, support WhatsApp number and email,
  home announcement in both languages.

## Security model

Firebase security rules enforce everything on the server. The app itself is never trusted, and
**`security-tests/` contains 29 automated attack tests, all passing** against the Firebase emulator.

- Admin rights come only from `admins/{uid}`, which only an existing admin can create. Users cannot make themselves admin, and an admin cannot remove themselves.
- Email and phone live in `users/{uid}/private/info`, which only the owner and admins can read.
  Public profiles never expose contact details.
- Posting ads and chatting require a **verified email** and an account that is **not banned**.
- Ads: an owner cannot approve or feature their own ad, change its view count or owner, or post under someone else's name. Every field is validated for type and size, and the category must exist.
  Pending and rejected ads are visible only to their owner and admins.
- Chats: only the two participants can read or write, the sender cannot be spoofed, messages cannot be edited, and a chat can only be opened on an active ad with its real owner.
- Storage: images only (under 5 MB), uploaded only into the user's own folder, and files cannot be overwritten.
- Web hosting adds security headers: HSTS, nosniff, frame-deny and a referrer policy.

## Project structure

```
lib/
  core/        theme, responsive helpers, validators, formatters, cities
  models/      AppUser, Listing, Category, Chat/Message, Report, AppSettings
  services/    Firebase repositories (auth, listings, users, catalog, chat, storage)
  providers/   Riverpod providers (session, catalog, preferences)
  features/    auth · home · listings · chat · profile (user dashboard) · admin
  l10n/        generated localizations (edit tool/gen_arb.py)
firestore.rules · storage.rules · firestore.indexes.json · firebase.json
security-tests/  rules tests, emulator demo-data seeder, local static server
```

## Go live: setup steps

1. **Create a Firebase project** at console.firebase.google.com. Then:
   - Authentication → Sign-in method → turn on **Email/Password**.
   - Create a **Firestore** database (production mode) and turn on **Storage**.
2. **Connect the app** (this replaces the placeholder `lib/firebase_options.dart`):
   ```bash
   dart pub global activate flutterfire_cli
   ```
   ```bash
   flutterfire configure
   ```
3. **Deploy the rules and indexes:**
   ```bash
   npm i -g firebase-tools && firebase login
   ```
   ```bash
   firebase use --add
   ```
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```
4. **Create the first admin.** Register in the app and verify your email. Then in the Firestore console,
   create the document `admins/<your-uid>` with the fields `grantedBy: "console"` and `createdAt: <timestamp>`.
   After that, add further admins from inside the admin dashboard.
5. **Load the categories.** Go to Admin → Categories → *Load default categories*. Then set
   auto-approve, the support contacts and the announcement in Admin → Settings.
6. **Build and release:**
   ```bash
   flutter build web --release && firebase deploy --only hosting
   ```
   ```bash
   flutter build appbundle --release
   ```
   ```bash
   flutter build ipa --release
   ```

Recommended before launch: turn on **Firebase App Check** (blocks scripted abuse), set budget alerts,
replace the app icons in `android/`, `ios/` and `web/`, and publish Terms of Use and Privacy Policy pages.

## Run locally (no Firebase project needed)

Requires the Flutter SDK, Node 18+ and Java 11+.
```bash
cd security-tests && npm install
```
```bash
npx firebase emulators:start --config ../firebase.json --project demo-souqna
```
In a second terminal, load the demo data: 3 users, 12 categories, 13 ads, a chat and a report.
```bash
cd security-tests && node seed_emulator.mjs
```
```bash
flutter run -d chrome --dart-define=USE_EMULATOR=true
```
Demo logins (password `Test12345`): `admin@souqna.test` (admin), `sara@souqna.test`, `omar@souqna.test`.

## Tests

```bash
flutter analyze && flutter test
```
```bash
cd security-tests && npm test
```
The first command runs the analyzer and the unit tests. The second runs the 29 security-rule attack tests in the emulator.

## Possible next steps

- Push notifications for new messages and ad approvals (Firebase Cloud Messaging plus Cloud Functions).
- Phone OTP login, and Google / Apple sign-in.
- Paid "featured" ads with an online payment provider.
- A Cloud Function that also disables the Firebase Auth account when an admin bans a user.
  Today a ban blocks every write through the security rules.
- Algolia or Typesense for full-text search at large scale.
