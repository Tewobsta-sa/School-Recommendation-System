import { sendMail } from "../config/mailer.js";
import { logger } from "../config/logger.js";

const frontendBaseUrl = process.env.FRONTEND_URL;

/**
 * Sent when a moderator approves the ad content — includes amount and pay link.
 */
export async function sendAdPaymentInstructionsEmail({
  to,
  adId,
  title,
  amountEtb,
  durationDays,
  placementType,
}) {
  const payUrl = `${frontendBaseUrl}/advertise/pay/${adId}`;
  const subject = `Your advertisement was approved — payment required`;
  const text = [
    `Your advertisement "${title}" has been approved.`,
    ``,
    `Amount due: ${amountEtb} ETB`,
    `Duration: ${durationDays} days`,
    `Placement: ${placementType}`,
    ``,
    `Complete payment here: ${payUrl}`,
    ``,
    `You will be redirected to Chappa secure payment gateway to complete your payment.`,
    `After successful payment, your ad will go live for the selected period.`,
  ].join("\n");

  const html = `  
    <p>Your advertisement <strong>${title}</strong> has been approved.</p>  
    <ul>  
      <li><strong>Amount due:</strong> ${amountEtb} ETB</li>  
      <li><strong>Duration:</strong> ${durationDays} days</li>  
      <li><strong>Placement:</strong> ${placementType}</li>  
    </ul>  
    <p><a href="${payUrl}">Complete payment via Chappa</a></p>  
    <p>You will be redirected to Chappa secure payment gateway. Your ad goes live after successful payment.</p>  
  `;

  try {
    await sendMail({ to, subject, text, html });
  } catch (err) {
    logger.error({ err, adId, to }, "Failed to send ad payment email");
    throw err;
  }
}
