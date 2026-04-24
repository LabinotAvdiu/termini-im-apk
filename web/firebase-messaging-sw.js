// firebase-messaging-sw.js — Service Worker pour les notifications push web (FCM)
//
// Config synchronisée depuis la Firebase Console du projet termini-im-cd5ff.
// La VAPID key correspondante vit côté app Flutter (notification_service.dart).

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            'AIzaSyCofTfimS6Rw1JPUTOuQYwlGYoYMpzox4k',
  authDomain:        'termini-im-cd5ff.firebaseapp.com',
  projectId:         'termini-im-cd5ff',
  storageBucket:     'termini-im-cd5ff.firebasestorage.app',
  messagingSenderId: '759517993388',
  appId:             '1:759517993388:web:f57c6cd9ce6f7c688d8209',
  measurementId:     'G-BWV621VQYZ',
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
