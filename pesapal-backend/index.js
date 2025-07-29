const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Load environment variables
const CONSUMER_KEY = process.env.PESAPAL_CONSUMER_KEY;
const CONSUMER_SECRET = process.env.PESAPAL_CONSUMER_SECRET;
const BASE_URL = process.env.PESAPAL_BASE_URL;

if (!CONSUMER_KEY || !CONSUMER_SECRET || !BASE_URL) {
  console.error('❌ Missing required environment variables in .env');
  process.exit(1);
}

// Debug logs to confirm .env values are loaded
console.log('🔑 Consumer Key:', CONSUMER_KEY);
console.log('🔐 Consumer Secret:', CONSUMER_SECRET);
console.log('🌐 Base URL:', BASE_URL);

let accessToken = '';

async function getAccessToken() {
  const credentials = Buffer.from(`${CONSUMER_KEY}:${CONSUMER_SECRET}`).toString('base64');

  try {
    const response = await axios.post(
      `${BASE_URL}/v3/api/Auth/RequestToken`, // Correct endpoint for Pesapal auth
      {},
      {
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('🔍 Full Pesapal Auth Response:', response.data);

    accessToken = response.data.token;
    if (accessToken) {
      console.log('✅ Access token received:', accessToken);
    } else {
      console.warn('⚠️ No access token in response.');
    }

  } catch (error) {
    console.error('❌ Failed to get access token:');
    if (error.response) {
      console.error(error.response.data);
    } else {
      console.error(error.message);
    }
  }
}

app.get('/auth', async (req, res) => {
  await getAccessToken();
  if (accessToken) {
    res.json({ token: accessToken });
  } else {
    res.status(500).json({ error: 'Failed to retrieve access token from Pesapal' });
  }
});

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
