// Background web push for Lernbik (Firebase Cloud Messaging).
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');
firebase.initializeApp({
  apiKey: 'AIzaSyD7WoWLVItq8IPPmpiIDps3Qrb68vqE-Dw',
  authDomain: 'lernbik.firebaseapp.com',
  projectId: 'lernbik',
  storageBucket: 'lernbik.firebasestorage.app',
  messagingSenderId: '479974594776',
  appId: '1:479974594776:web:3bd2945763f650c247dfad',
});
firebase.messaging();
