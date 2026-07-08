'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"097945cdc1806e637205cad4c153e834.html": "07f4cd53b530ff8bc60369c6d94d851d",
"ably_wrapper.js": "61556e07554f0a9476a1f63f3bbefc9b",
"An-known_-_ADAM__Official_Lyrics_Video_(256k).mp3": "d41d8cd98f00b204e9800998ecf8427e",
"assets/animations/loader_animation.json": "8a0b66f75bae16e15460996e0bee802d",
"assets/animations/loading_animation.json": "337cb963a94bc3d514a7ec8dd1e9f411",
"assets/animations/premium.svg": "3f5087595e987b1e2afebdbe78682ae7",
"assets/animations/waves.json": "ca49e3a406a72cada4e6dc54fd5c6411",
"assets/animations/your_splash_loader.json": "c7599e5883f70438c27f9adcfba2aa84",
"assets/AssetManifest.bin": "474950b523b5a4a1665546c7bd0c0dc4",
"assets/AssetManifest.bin.json": "332475708b8d470eb87b8a0ea21bc26c",
"assets/AssetManifest.json": "8c051f7855f3caef377f1729160b9855",
"assets/assets/animations/loader_animation.json": "8a0b66f75bae16e15460996e0bee802d",
"assets/assets/animations/loading_animation6.json": "307d61b6bd848a443e291430ae7c661f",
"assets/assets/animations/your_splash_loader.json": "c7599e5883f70438c27f9adcfba2aa84",
"assets/assets/audio/Burna.mp3": "b3bf28242ff2c8696bdb984714100b1f",
"assets/assets/audio/calling.mp3": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/audio/energy.mp3": "4b1f542ff7a84c43b8b7f493853d47a2",
"assets/assets/audio/fameica.mp3": "d44a93ce86ae3abf68b19cfcc146915d",
"assets/assets/audio/feelings.mp3": "c2f2ff776b4f07e5b32b9504a3bd53e6",
"assets/assets/audio/message-pop-alert.mp3": "15b0efd7b20ecc3b05183915349b9fb5",
"assets/assets/audio/ringtone.mp3": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/audio/Vyroota.mp3": "2c1a37e85dcdc82c7232c6c18f5ec44d",
"assets/assets/images/20250803_1643_Yellow%2520Logo%2520Glow_remix_01k1r2nhkbfaft6qxhgt51j25d.png": "ac7d64ed68466a360fe07fc1df46b585",
"assets/assets/images/a.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/afro_beats.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/amplify_logo.png": "21101253ee0563ea9152035474e01775",
"assets/assets/images/amplify_logo6.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/app_icon%2520(2).png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/app_icon.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/app_icon7.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/app_icon_foreground.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/bigwa.jpg": "c6faf55ab2dcfdc604ce52077e997c7d",
"assets/assets/images/burna.jpg": "aa95b0a3319b25051489a04669b557eb",
"assets/assets/images/burna.webp": "4d11db852c8410643d5c487ecf908b79",
"assets/assets/images/chill_vibes.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/default_cover.jpg": "178545c6cb0429e0462e33c39ffafe94",
"assets/assets/images/fameica.jpg": "ac816c481d559c7628ab28d0f460d834",
"assets/assets/images/focus.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/google.png": "ca2f7db280e9c773e341589a81c15082",
"assets/assets/images/google_icon.png.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/kelly.jpg": "5298ca68f51e5b4d37b5b3292ec02239",
"assets/assets/images/loader.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/logo.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/logo5.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/people.jpg": "6ecc808150270d059cb45faefe1c2fe8",
"assets/assets/images/premium.svg": "3f5087595e987b1e2afebdbe78682ae7",
"assets/assets/images/rush.jpg": "36ef2e7ad22a03a84e6945d4be06635c",
"assets/assets/images/s.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/sability.jpg": "a0280a65a15cc5341c10fd6c0577657f",
"assets/assets/images/t.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/vyroota.jpg": "65f49dd2ddf0e45806abc66e115af880",
"assets/assets/images/wave_pattern.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/workout_mix.png": "d41d8cd98f00b204e9800998ecf8427e",
"assets/audio/calling.mp3": "d41d8cd98f00b204e9800998ecf8427e",
"assets/audio/message-pop-alert.mp3": "15b0efd7b20ecc3b05183915349b9fb5",
"assets/audio/ringtone.mp3": "d41d8cd98f00b204e9800998ecf8427e",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "bbe0108f9ef130b4858886552c9b7efe",
"assets/NOTICES": "21eab870b009b371080334590ffd4749",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "d7d83bd9ee909f8a9b348f56ca7b68c6",
"assets/packages/flutter_sound_web/howler/howler.js": "3030c6101d2f8078546711db0d1a24e9",
"assets/packages/flutter_sound_web/src/flutter_sound.js": "7e17a336e64c7aaf2ab0fd4fe1e6cf0f",
"assets/packages/flutter_sound_web/src/flutter_sound_player.js": "b4ab3574b00feb9165fefd08634da145",
"assets/packages/flutter_sound_web/src/flutter_sound_recorder.js": "b37654208f2ab2461a0f66424a20335a",
"assets/packages/flutter_sound_web/src/flutter_sound_stream_processor.js": "d466fda2e806ef7abe69ca33ef278c97",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/packages/wakelock_plus/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"firebase-messaging-sw.js": "e26bb87996adae25e544665f6351886f",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "f1f416714afe70396f5d15341eeedafe",
"google.png": "ca2f7db280e9c773e341589a81c15082",
"google8118611a8a4eae87.html": "4549bd1924d0798f93cf16d4cab723e3",
"google_icon.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/android-chrome-192x192.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/android-chrome-512x512.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/apple-touch-icon.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/app_icon.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/favicon-16x16.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/favicon-32x32.png": "d41d8cd98f00b204e9800998ecf8427e",
"icons/favicon.ico": "d41d8cd98f00b204e9800998ecf8427e",
"icons/site.webmanifest": "053100cb84a50d2ae7f5492f7dd7f25e",
"index.html": "0c575dd8a5b878bbe2eb948721746b2d",
"/": "0c575dd8a5b878bbe2eb948721746b2d",
"main.dart.js": "beed701e8e6d4e042de350230eaa88a8",
"manifest.json": "c524990d8bb343f27075009bca47fe1e",
"night%20of%2010%20jr%20lash%20tech%20vidz.mp4": "d41d8cd98f00b204e9800998ecf8427e",
"robots.txt.txt": "4f2c45a931fa69651136a79d5f7f0942",
"sitemap.xml": "431792b9193c51abc17740513c01c679",
"supabase-config.js": "a75f115634bcd9bfce34e63e8acaab26",
"test_ably.html": "c81bdfe75e9fb21e772a8a786fa91833",
"version.json": "6ae661e37365713aae7e188198bfb43e",
"w.png": "d41d8cd98f00b204e9800998ecf8427e"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
