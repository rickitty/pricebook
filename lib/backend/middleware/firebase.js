const admin = require('firebase-admin');

async function firebaseAuth(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ')
    ? authHeader.slice(7)
    : null;

  if (!token) {
    return res.status(401).json({ message: 'No token' });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.firebaseUser = decoded;
    next();
  } catch (e) {
    console.error(e);
    res.status(401).json({ message: 'Invalid token' });
  }
}

module.exports = firebaseAuth;
