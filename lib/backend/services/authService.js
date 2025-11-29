const User = require('../models/User');

async function ensureUserService(phone) {
  if (!phone) {
    throw new Error("Phone number is required");
  }

  let user = await User.findOne({ phone }).populate("objects");

  if (!user) {
    user = await User.create({
      phone,
      role: "worker",
      objects: [],
    });

    await user.populate("objects");
  }

  return user;
}

module.exports = { ensureUserService };
