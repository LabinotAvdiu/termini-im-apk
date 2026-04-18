// firebase-messaging-sw.js — Service Worker pour les notifications push web (FCM)
//
// TODO: Remplace les valeurs PLACEHOLDER ci-dessous par celles de ta Firebase Console.
//   1. Va sur https://console.firebase.google.com → Paramètres du projet → Général → Tes applications web
//   2. Copie l'objet firebaseConfig de ton app web
//   3. Remplace chaque PLACEHOLDER par la vraie valeur

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'PLACEHOLDER_API_KEY',
  authDomain:        'termini-im-placeholder.firebaseapp.com',
  projectId:         'termini-im-placeholder',
  storageBucket:     'termini-im-placeholder.appspot.com',
  messagingSenderId: '000000000000',
  appId:             'PLACEHOLDER_APP_ID',
});

const messaging = firebase.messaging();

// Gestion des messages reçus en arrière-plan (background / tab inactive)
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title ?? 'Termini im';
  const notificationOptions = {
    body: payload.notification?.body ?? '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data ?? {},
    // Regroupe les notifications par type pour éviter le spam
    tag: payload.data?.type ?? 'termini-general',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Tap sur la notification en arrière-plan → ouvre ou focus l'onglet
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const appointmentId = event.notification.data?.appointmentId;
  const url = appointmentId
    ? `${self.location.origin}/#/appointments/${appointmentId}`
    : self.location.origin;

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        for (const client of clientList) {
          if (client.url.startsWith(self.location.origin) && 'focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow(url);
        }
      }),
  );
});
