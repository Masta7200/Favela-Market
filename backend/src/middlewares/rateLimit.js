// Small in-memory rate limiter (one server instance, no extra dependency).
// Slows down password / reset-code guessing.
//
// Mobile users often share one IP (carrier NAT), so by default the limit is
// per account (phone / email in the body) and only failed attempts count.
const rateLimit = ({ windowMs, max, message, keyFn, failuresOnly = true }) => {
  const hits = new Map(); // key -> { count, resetAt }

  // Drop expired entries now and then so the map doesn't grow forever
  setInterval(() => {
    const now = Date.now();
    for (const [key, entry] of hits) if (entry.resetAt <= now) hits.delete(key);
  }, windowMs).unref();

  return (req, res, next) => {
    const key = `${req.baseUrl}${req.path}:${keyFn(req)}`;
    const now = Date.now();
    let entry = hits.get(key);
    if (!entry || entry.resetAt <= now) {
      entry = { count: 0, resetAt: now + windowMs };
      hits.set(key, entry);
    }

    if (entry.count >= max) {
      res.set('Retry-After', String(Math.ceil((entry.resetAt - now) / 1000)));
      return res.status(429).json({ success: false, message });
    }

    if (failuresOnly) {
      res.on('finish', () => {
        if (res.statusCode >= 400 && res.statusCode !== 429) entry.count += 1;
      });
    } else {
      entry.count += 1;
    }
    next();
  };
};

const accountKey = (req) =>
  String(req.body?.phone || req.body?.email || req.ip).trim().toLowerCase();

const TOO_MANY = 'Trop de tentatives. Veuillez réessayer dans quelques minutes.';

// Login / reset: 8 failed attempts per account every 15 minutes
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 8, message: TOO_MANY, keyFn: accountKey });

// Reset-code emails: 5 per account per hour (successful or not)
const resetRequestLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, max: 5, message: TOO_MANY, keyFn: accountKey, failuresOnly: false
});

module.exports = { rateLimit, authLimiter, resetRequestLimiter };
