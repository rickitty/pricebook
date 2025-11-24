const { makeAdminService, getWorkersService, assignObjectsToUserService } = require('../services/userService');

exports.makeAdmin = async (req, res) => {
  try {
    await makeAdminService(req.firebaseUser);
    res.json({ message: "Role updated to admin" });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: e.message });
  }
};

exports.getWorkers = async (req, res) => {
  try {
    const workers = await getWorkersService();
    res.json(workers);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: e.message });
  }
};

exports.assignObjectsToUser = async (req, res) => {
  try {
    const { userId, objectIds } = req.body; // массив ID объектов
    const user = await assignObjectsToUserService(userId, objectIds);
    res.json(user);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: e.message });
  }
};
