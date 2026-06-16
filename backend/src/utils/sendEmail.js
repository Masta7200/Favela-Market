const nodemailer = require('nodemailer');

let transporter = null;

// Lazily build the transporter from env vars so the app doesn't crash on boot
// if email isn't configured yet (it will just fail when actually sending).
const getTransporter = () => {
  if (transporter) return transporter;

  const { EMAIL_HOST, EMAIL_PORT, EMAIL_USER, EMAIL_PASS } = process.env;

  if (!EMAIL_USER || !EMAIL_PASS) {
    throw new Error(
      'Email non configuré: définissez EMAIL_USER et EMAIL_PASS (et EMAIL_HOST/EMAIL_PORT si besoin) dans les variables d\'environnement.'
    );
  }

  transporter = nodemailer.createTransport({
    host: EMAIL_HOST || 'smtp.gmail.com',
    port: Number(EMAIL_PORT) || 465,
    secure: Number(EMAIL_PORT) !== 587, // true for 465, false for 587 (STARTTLS)
    auth: {
      user: EMAIL_USER,
      pass: EMAIL_PASS
    }
  });

  return transporter;
};

/**
 * Send an email.
 * @param {{to: string, subject: string, html: string, text?: string}} options
 */
const sendEmail = async ({ to, subject, html, text }) => {
  const t = getTransporter();
  const from = process.env.EMAIL_FROM || process.env.EMAIL_USER;

  await t.sendMail({
    from: `Tumai Market <${from}>`,
    to,
    subject,
    text: text || html.replace(/<[^>]+>/g, ' '),
    html
  });
};

module.exports = sendEmail;
