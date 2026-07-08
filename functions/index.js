// Import Firebase Functions and the Prerender.io middleware.
const functions = require('firebase-functions');
const prerender = require('prerender-node');

// Set your Prerender.io token here. You get this from your Prerender.io account.
prerender.set('AGNS4a2cjodv1tdObDTE', 'AGNS4a2cjodv1tdObDTE');

// The main cloud function that handles all incoming HTTP requests.
exports.prerender = functions.https.onRequest((req, res) => {
  // Check if the request is from a known bot.
  if (prerender.shouldShowPrerenderedPage(req)) {
    // If it's a bot, proxy the request to Prerender.io and send the
    // pre-rendered HTML back to the bot.
    prerender(req, res);
  } else {
    // If it's not a bot (e.g., a regular user), serve the main index.html file.
    // This is the standard Flutter web app.
    res.sendFile('index.html', { root: 'public' });
  }
});
