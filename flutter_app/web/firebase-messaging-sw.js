// Firebase Cloud Messaging Service Worker
// Handles background push notifications (FCM) when the SubInsights tab is
// closed or inactive. Must be served from the root URL, i.e. /web/ folder.
//
// NOTE: Firebase web API keys are project identifiers, not secrets.
// They are intentionally public — security is enforced by Firebase Security
// Rules and Firebase App Check, not by keeping the key private.
// See: https://firebase.google.com/docs/projects/api-keys

importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDoWdw24gMPGGa0zM8WSARGCSsVsCbWUlc',
  authDomain: 'subinsights-df0dc.firebaseapp.com',
  projectId: 'subinsights-df0dc',
  storageBucket: 'subinsights-df0dc.firebasestorage.app',
  messagingSenderId: '982871293951',
  appId: '1:982871293951:web:5f925d8fd453ceb9c5f1ca',
});

const messaging = firebase.messaging();

// Show an OS notification when a push message arrives while the tab is not active.
messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification ?? {};
  const title = notification.title || 'SubInsights';
  const body  = notification.body  || '';

  return self.registration.showNotification(title, {
    body,
    icon:  '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data:  payload.data,
  });
});
