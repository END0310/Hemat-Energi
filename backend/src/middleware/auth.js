const jwt = require('jsonwebtoken');

/**
 * Middleware Autentikasi JWT (NFR-02 & Lampiran C).
 * Membaca header "Authorization: Bearer <token>", memverifikasi tanda tangan token,
 * lalu menyimpan identitas pengguna ke `req.user` agar setiap query difilter per akun.
 */
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Akses ditolak. Token login tidak ditemukan.',
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = {
      id: decoded.id,
      email_username: decoded.email_username,
    };
    return next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Sesi login telah berakhir atau token tidak valid. Silakan login kembali.',
    });
  }
}

module.exports = authenticateToken;
