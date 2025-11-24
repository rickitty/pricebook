const User = require('../models/User');

async function ensureUserService(firebaseUser) {
  const { uid, phone_number } = firebaseUser;
  const phone = phone_number;

  if (!phone) {
    throw new Error("No phone in token");
  }

  let user = await User.findOne({ firebaseUid: uid }).populate("objects");

  if (!user) {
    user = await User.findOne({ phone }).populate("objects");

    if (user) {
      user.firebaseUid = uid;
      await user.save();
    }
  }

  if (!user) {
    user = await User.create({
      firebaseUid: uid,
      phone,
      role: "worker",
      objects: [], 
    });

    await user.populate("objects");
  }

  return user;
}

module.exports = { ensureUserService };
