// Sends email via Brevo's HTTPS REST API (not SMTP).
//
// Why: Render's free tier blocks outbound raw SMTP connections (port 25/465/587),
// so nodemailer + Gmail/any SMTP relay will always fail there with
// ETIMEDOUT/ENETUNREACH. An HTTPS API call is not affected by that restriction.
//
// Setup required (see project notes): create a free Brevo account, verify a
// "sender" email address (one-click email confirmation, no DNS needed), then
// set BREVO_API_KEY and EMAIL_FROM (must match the verified sender) as env vars.

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

/**
 * Send an email.
 * @param {{to: string, subject: string, html: string, text?: string}} options
 */
const sendEmail = async ({ to, subject, html, text }) => {
  const { BREVO_API_KEY, EMAIL_FROM } = process.env;

  if (!BREVO_API_KEY || !EMAIL_FROM) {
    throw new Error(
      'Email non configuré: définissez BREVO_API_KEY et EMAIL_FROM dans les variables d\'environnement.'
    );
  }

  const response = await fetch(BREVO_API_URL, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      'api-key': BREVO_API_KEY
    },
    body: JSON.stringify({
      sender: { name: 'Tumai Market', email: EMAIL_FROM },
      to: [{ email: to }],
      subject,
      htmlContent: html,
      textContent: text || html.replace(/<[^>]+>/g, ' ')
    })
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Brevo API error (${response.status}): ${errorBody}`);
  }
};

module.exports = sendEmail;
