const User = require('../models/User');

async function makeAdminService(firebaseUser) {
  const user = await User.findOne({ firebaseUid: firebaseUser.uid });

  if (!user) {
    throw new Error("User not found in MongoDB");
  }

  user.role = "admin";
  await user.save();

  return user;
}

async function getWorkersService() {
  return await User.find({ role: 'worker' }).populate('objects');
}

async function assignObjectsToUserService(userId, objectIds) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');

  if (!Array.isArray(objectIds)) {
    return res.status(400).json({ message: "objectIds must be an array" });
  }

  user.objects = objectIds;
  await user.save();
  return user;
}

module.exports = { makeAdminService , getWorkersService, assignObjectsToUserService};
