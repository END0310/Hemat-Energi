const fs = require('fs');
const path = require('path');
const multer = require('multer');

// Pastikan folder backend/uploads tersedia
const uploadsDir = path.join(__dirname, '..', '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

/**
 * Konfigurasi penyimpanan foto bukti meter ke folder backend/uploads (FR-03).
 */
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const userId = req.user ? req.user.id : 'anon';
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    const uniqueName = `meter_${userId}_${Date.now()}${ext}`;
    cb(null, uniqueName);
  },
});

const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

function fileFilter(_req, file, cb) {
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Format file tidak didukung. Gunakan foto JPG, PNG, atau WEBP.'));
  }
}

const uploadMeterPhoto = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // Maksimal 5 MB
  },
});

module.exports = {
  uploadMeterPhoto,
  uploadsDir,
};
