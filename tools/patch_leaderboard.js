/**
 * Admin script — patches all users' users_points documents with name/photo
 * from Firebase Auth, and creates the document if it doesn't exist yet.
 *
 * Setup:
 *   1. Go to Firebase Console → Project Settings → Service Accounts
 *      → Generate new private key → save as tools/service-account.json
 *   2. npm install firebase-admin   (run once from project root or tools/)
 *   3. node tools/patch_leaderboard.js
 */

const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.join(__dirname, 'service-account.json');

let serviceAccount;
try {
  serviceAccount = require(serviceAccountPath);
} catch {
  console.error('❌  service-account.json not found.');
  console.error('    Download it from Firebase Console → Project Settings → Service Accounts.');
  console.error(`    Save it at: ${serviceAccountPath}`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const auth = admin.auth();

async function main() {
  console.log('=== Leaderboard Patch Script ===\n');

  // 1. List all Firebase Auth users (handles pagination)
  const allUsers = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    allUsers.push(...result.users);
    pageToken = result.pageToken;
  } while (pageToken);

  console.log(`Found ${allUsers.length} user(s) in Firebase Auth.\n`);

  for (const user of allUsers) {
    const uid = user.uid;
    const name = user.displayName || '';
    const email = user.email || '';
    const photoUrl = user.photoURL || '';

    process.stdout.write(`Processing: ${name || email || uid}  `);

    const pointsRef = db.collection('users_points').doc(uid);
    const pointsDoc = await pointsRef.get();

    if (!pointsDoc.exists) {
      // Create full document for users who have never earned points
      await pointsRef.set({
        userId: uid,
        name,
        email,
        photoUrl,
        country: '',
        totalPoints: 0,
        todayPoints: 0,
        weekPoints: 0,
        monthPoints: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastActiveDate: new Date().toISOString(),
      });
      console.log('→ created users_points doc');
    } else {
      const data = pointsDoc.data();
      const needsPatch = !data.name || data.name === '';
      if (needsPatch) {
        await pointsRef.update({ name, email, photoUrl });
        console.log(`→ patched name: "${name}"`);
      } else {
        console.log(`→ already has name: "${data.name}" ✅`);
      }
    }
  }

  console.log('\n=== Done ===');
}

main().catch((err) => {
  console.error('❌ Error:', err.message);
  process.exit(1);
});
