const { ensureUserService } = require('../services/authService');

exports.ensureUser = async (req, res) => {
  try {
    const user = await ensureUserService(req.firebaseUser);

    res.json({
      id: user._id,
      phone: user.phone,
      role: user.role,
      objects: user.objects?.map(obj => ({
        id: obj._id,
        name: obj.name,
        type: obj.type,
        coords: obj.coords,
        status: obj.status,
      })) || [],
    });

  } catch (e) {
    console.error(e);
    res.status(500).json({ message: e.message });
  }
};

