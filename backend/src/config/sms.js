import axios from "axios";

const SMS_BASE_URL = process.env.SMS_ETHIOPIA_BASE_URL;
const SMS_API_KEY = process.env.SMS_ETHIOPIA_API_KEY;

export async function sendSMS({ to, message }) {
  if (!SMS_API_KEY) {
    throw new Error("SMS Ethiopia API key missing");
  }

  let formattedPhone = to.replace(/\s+/g, "");

  // Convert 09XXXXXXXX -> 2519XXXXXXXX
  if (formattedPhone.startsWith("09")) {
    formattedPhone = "251" + formattedPhone.substring(1);
  }

  // Convert +251XXXXXXXXX -> 251XXXXXXXXX
  if (formattedPhone.startsWith("+251")) {
    formattedPhone = formattedPhone.substring(1);
  }

  const payload = {
    msisdn: formattedPhone,
    text: message,
  };

  console.log("Sending SMS payload:", payload);

  try {
    const response = await axios.post(`${SMS_BASE_URL}/sms/send`, payload, {
      headers: {
        KEY: SMS_API_KEY,
        "Content-Type": "application/json",
      },
    });

    console.log("SMS Ethiopia response:", response.data);

    return response.data;
  } catch (error) {
    console.error("SMS STATUS:", error.response?.status);
    console.error(
      "SMS RESPONSE DATA:",
      JSON.stringify(error.response?.data, null, 2),
    );
    console.error("SMS ERROR:", error.message);

    throw new Error("Failed to send SMS");
  }
}
