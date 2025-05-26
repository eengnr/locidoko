import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'SID_AUTH_TITLE': 'Login',
          'SID_AUTH_INSTANCE': 'Instance',
          'SID_AUTH_ENTER_INSTANCE_DOMAIN': 'Enter the instance domain',
          'SID_AUTH_CONNECTING_TO': 'Connecting to https://',
          'SID_AUTH_ERROR_NO_TOKEN':
              'Error during registration.\nCheck the instance domain.',
          'SID_AUTH_ERROR_NO_INSTANCE':
              'Please enter the domain of an instance.',
          'SID_HOME_TITLE': 'Recent Check Ins',
          'SID_HOME_NO_STATUSES_FOUND': 'No recent checkins found.',
          'SID_HOME_FAB_TOOLTIP': 'Check In',
          'SID_HOME_POSTPOPUP_CLOSE': 'Close',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_1': 'Hooray! That was great!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_2': 'Super! Well done!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_3': 'Wonderful! What a success!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_4': 'Great! Keep on going!',
          'SID_HOME_ERROR_STATUSES_LOAD': 'Error loading Check Ins.',
          'SID_LOCATIONS_TITLE': 'Locations nearby',
          'SID_LOCATIONS_NO_LOCATIONS_FOUND': 'No nearby locations found.',
          'SID_LOCATIONS_DETAILPOPUP_NODETAILS': 'No details available',
          'SID_LOCATIONS_DETAILPOPUP_CLOSE': 'Close',
          'SID_LOCATIONS_DETAILPOPUP_OPENOSM': 'Show on OpenStreetMap',
          'SID_LOCATIONS_ERROR_LOCATIONS_LOAD':
              'Error loading nearby locations.',
          'SID_POSTSTATUS_TITLE': 'Check In',
          'SID_POSTSTATUS_TEXT': 'What are you doing?',
          'SID_POSTSTATUS_IMAGEALTTEXT': 'What\'s on the image?',
          'SID_POSTSTATUS_HEADER': 'I\'m currently here:',
          'SID_POSTSTATUS_VISIBILITY': 'Unlisted',
          'SID_POSTSTATUS_BUTTON_CANCEL': 'Cancel',
          'SID_POSTSTATUS_BUTTON_CHECKIN': 'Check In',
          'SID_POSTSTATUS_ERROR': 'An error has happened.',
          'SID_ABOUT_TITLE': 'About',
          'SID_ABOUT_LICENSE': 'This app is free software.',
          'SID_ABOUT_LICENSE_TEXT':
              'Licensed under GNU General Public License 3.0.',
          'SID_ABOUT_OSS_LICENSES': 'Open source licenses',
          'SID_ABOUT_CODE': 'Code on GitHub',
          'SID_ABOUT_OSM_NOTICE':
              'You need an account on Mastodon or a compatible Fediverse service for this app.\nTo find locations nearby, your current location is sent to the Overpass Turbo API of OpenStreetMap.\nYou can then inform your followers about your stay with a public status post.',
          'SID_ABOUT_OSM_CONTRIBUTE':
              'If a location is missing you can register on OpenStreetMap and add the location.',
          'SID_ABOUT_BUTTON_LOGOUT': 'LOGOUT',
          'SID_SETTINGS_OVERPASS_DOMAIN': 'Overpass instance',
          'SID_SETTINGS_ENTER_OVERPASS_DOMAIN':
              'Enter an Overpass instance address',
        },
        'de_DE': {
          'SID_AUTH_TITLE': 'Einloggen',
          'SID_AUTH_INSTANCE': 'Instanz',
          'SID_AUTH_ENTER_INSTANCE_DOMAIN': 'Gib die Domain der Instanz ein',
          'SID_AUTH_CONNECTING_TO': 'Verbinden mit https://',
          'SID_AUTH_ERROR_NO_TOKEN':
              'Fehler bei der Anmeldung.\nÜberprüfe die Domain der Instanz',
          'SID_AUTH_ERROR_NO_INSTANCE':
              'Bitte gib die Domain einer Instanz ein.',
          'SID_HOME_TITLE': 'Kürzliche Check-Ins',
          'SID_HOME_NO_STATUSES_FOUND': 'Keine kürzlichen Checkins gefunden.',
          'SID_HOME_FAB_TOOLTIP': 'Einchecken',
          'SID_HOME_POSTPOPUP_CLOSE': 'Schließen',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_1': 'Hurra! Das war klasse!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_2': 'Super! Gut gemacht!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_3': 'Wunderbar! Ein voller Erfolg!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_4': 'Großartig! Weiter so!',
          'SID_HOME_ERROR_STATUSES_LOAD': 'Fehler beim Laden der Checkins.',
          'SID_LOCATIONS_TITLE': 'Orte in der Nähe',
          'SID_LOCATIONS_NO_LOCATIONS_FOUND':
              'Keine Orte in der Nähe gefunden.',
          'SID_LOCATIONS_DETAILPOPUP_NODETAILS': 'Keine Details vorhanden.',
          'SID_LOCATIONS_DETAILPOPUP_CLOSE': 'Schließen',
          'SID_LOCATIONS_DETAILPOPUP_OPENOSM': 'Auf OpenStreetMap zeigen',
          'SID_LOCATIONS_ERROR_LOCATIONS_LOAD':
              'Fehler beim Laden der Orte in der Nähe.',
          'SID_POSTSTATUS_TITLE': 'Check In',
          'SID_POSTSTATUS_IMAGEALTTEXT': 'Was ist auf dem Bild?',
          'SID_POSTSTATUS_TEXT': 'Was machst du gerade?',
          'SID_POSTSTATUS_HEADER': 'Ich bin gerade hier:',
          'SID_POSTSTATUS_VISIBILITY': 'Nicht gelistet',
          'SID_POSTSTATUS_BUTTON_CANCEL': 'Abbrechen',
          'SID_POSTSTATUS_BUTTON_CHECKIN': 'Check In',
          'SID_POSTSTATUS_ERROR': 'Ein Fehler ist aufgetreten.',
          'SID_ABOUT_TITLE': 'Über',
          'SID_ABOUT_LICENSE': 'Diese App ist freie Software.',
          'SID_ABOUT_LICENSE_TEXT':
              'Lizenziert unter der GNU General Public License 3.0.',
          'SID_ABOUT_OSS_LICENSES': 'Open-Source-Lizenzen',
          'SID_ABOUT_CODE': 'Code auf GitHub',
          'SID_ABOUT_OSM_NOTICE':
              'Für diese App benötigst du ein Konto bei Mastodon oder einem kompatiblen Fediverse-Dienst.\nUm Orte in der Nähe zu finden, wird dein Standort an die Overpass Turbo API von OpenStreetMap geschickt.\nAnschließend kannst du deine Follower mit einem öffentlichen Statusbeitrag über deinen Aufenthalt informieren.',
          'SID_ABOUT_OSM_CONTRIBUTE':
              'Falls ein Ort fehlt, kannst du dich bei OpenStreetMap registrieren und den Ort ergänzen.',
          'SID_ABOUT_BUTTON_LOGOUT': 'ABMELDEN',
          'SID_SETTINGS_OVERPASS_DOMAIN': 'Overpass-Instanz',
          'SID_SETTINGS_ENTER_OVERPASS_DOMAIN':
              'Gib eine Overpass-Instanz-Adresse ein',
        },
        'fr_FR': {
          'SID_AUTH_TITLE': 'Connexion',
          'SID_AUTH_INSTANCE': 'Instance',
          'SID_AUTH_ENTER_INSTANCE_DOMAIN': 'Entre le domaine de l\'instance',
          'SID_AUTH_CONNECTING_TO': 'Connexion à https://',
          'SID_AUTH_ERROR_NO_TOKEN':
              'Erreur lors de l\'inscription.\nVérifie l\'instance domaine.',
          'SID_AUTH_ERROR_NO_INSTANCE':
              'S\'il te plaît, entre le domaine d\'une instance.',
          'SID_HOME_TITLE': 'Derniers Check Ins',
          'SID_HOME_NO_STATUSES_FOUND': 'Aucun checkin récent trouvé.',
          'SID_HOME_FAB_TOOLTIP': 'Check In',
          'SID_HOME_POSTPOPUP_CLOSE': 'Fermer',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_1': 'Hourra! C\'était super!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_2': 'Super! Bien joué!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_3': 'Magnifique! Quel succès!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_4': 'Génial! Continue comme ça!',
          'SID_HOME_ERROR_STATUSES_LOAD':
              'Erreur lors du chargement des Check Ins.',
          'SID_LOCATIONS_TITLE': 'Lieux à proximité',
          'SID_LOCATIONS_NO_LOCATIONS_FOUND': 'Aucun lieu à proximité trouvé.',
          'SID_LOCATIONS_DETAILPOPUP_NODETAILS': 'Aucun détail disponible',
          'SID_LOCATIONS_DETAILPOPUP_CLOSE': 'Fermer',
          'SID_LOCATIONS_DETAILPOPUP_OPENOSM': 'Afficher sur OpenStreetMap',
          'SID_LOCATIONS_ERROR_LOCATIONS_LOAD':
              'Erreur lors du chargement des lieux à proximité.',
          'SID_POSTSTATUS_TITLE': 'Check In',
          'SID_POSTSTATUS_TEXT': 'Qu\'est-ce que tu fais?',
          'SID_POSTSTATUS_IMAGEALTTEXT': 'Qu\'y a-t-il sur l\'image?',
          'SID_POSTSTATUS_HEADER': 'Je suis actuellement ici:',
          'SID_POSTSTATUS_VISIBILITY': 'Non listé',
          'SID_POSTSTATUS_BUTTON_CANCEL': 'Annuler',
          'SID_POSTSTATUS_BUTTON_CHECKIN': 'Check In',
          'SID_POSTSTATUS_ERROR': 'Une erreur s\'est produite.',
          'SID_ABOUT_TITLE': 'À propos',
          'SID_ABOUT_LICENSE': 'Cette application est un logiciel libre.',
          'SID_ABOUT_LICENSE_TEXT':
              'Licencié sous GNU General Public License 3.0.',
          'SID_ABOUT_OSS_LICENSES': 'Licences open source',
          'SID_ABOUT_CODE': 'Code sur GitHub',
          'SID_ABOUT_OSM_NOTICE':
              'Tu as besoin d\'un compte sur Mastodon ou un service Fediverse compatible pour cette application.\nPour trouver des lieux à proximité, ta position actuelle est envoyée à l\'API Overpass Turbo d\'OpenStreetMap.\nEnsuite, tu peux informer tes followers de ton séjour en publiant un statut public.',
          'SID_ABOUT_OSM_CONTRIBUTE':
              'Si un lieu manque, tu peux t\'inscrire sur OpenStreetMap et ajouter le lieu.',
          'SID_ABOUT_BUTTON_LOGOUT': 'DÉCONNEXION',
          'SID_SETTINGS_OVERPASS_DOMAIN': 'Instance Overpass',
          'SID_SETTINGS_ENTER_OVERPASS_DOMAIN': 'Entrez l\'instance Overpass',
        },
        'it_IT': {
          'SID_AUTH_TITLE': 'Accesso',
          'SID_AUTH_INSTANCE': 'Istanza',
          'SID_AUTH_ENTER_INSTANCE_DOMAIN':
              'Inserisci il dominio dell\'istanza',
          'SID_AUTH_CONNECTING_TO': 'Connessione a https://',
          'SID_AUTH_ERROR_NO_TOKEN':
              'Errore durante la registrazione.\nControlla il dominio dell\'istanza.',
          'SID_AUTH_ERROR_NO_INSTANCE':
              'Per favore, inserisci il dominio di un\'istanza.',
          'SID_HOME_TITLE': 'Check Ins recenti',
          'SID_HOME_NO_STATUSES_FOUND': 'Nessun checkin recente trovato.',
          'SID_HOME_FAB_TOOLTIP': 'Check In',
          'SID_HOME_POSTPOPUP_CLOSE': 'Chiudi',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_1': 'Evviva! È stato fantastico!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_2': 'Super! Ben fatto!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_3': 'Meraviglioso! Che successo!',
          'SID_HOME_CHECKEDINPOPUP_SUCCESS_4': 'Grande! Continua così!',
          'SID_HOME_ERROR_STATUSES_LOAD':
              'Errore durante il caricamento dei Check Ins.',
          'SID_LOCATIONS_TITLE': 'Luoghi nelle vicinanze',
          'SID_LOCATIONS_NO_LOCATIONS_FOUND':
              'Nessun luogo nelle vicinanze trovato.',
          'SID_LOCATIONS_DETAILPOPUP_NODETAILS': 'Nessun dettaglio disponibile',
          'SID_LOCATIONS_DETAILPOPUP_CLOSE': 'Chiudi',
          'SID_LOCATIONS_DETAILPOPUP_OPENOSM': 'Mostra su OpenStreetMap',
          'SID_LOCATIONS_ERROR_LOCATIONS_LOAD':
              'Errore durante il caricamento dei luoghi nelle vicinanze.',
          'SID_POSTSTATUS_TITLE': 'Check In',
          'SID_POSTSTATUS_TEXT': 'Cosa stai facendo?',
          'SID_POSTSTATUS_IMAGEALTTEXT': 'Cosa c\'è nell\'immagine?',
          'SID_POSTSTATUS_HEADER': 'Sono attualmente qui:',
          'SID_POSTSTATUS_VISIBILITY': 'Non elencato',
          'SID_POSTSTATUS_BUTTON_CANCEL': 'Annulla',
          'SID_POSTSTATUS_BUTTON_CHECKIN': 'Check In',
          'SID_POSTSTATUS_ERROR': 'Si sono verificati degli errori.',
          'SID_ABOUT_TITLE': 'Informazioni',
          'SID_ABOUT_LICENSE': 'Questa app è un software libero.',
          'SID_ABOUT_LICENSE_TEXT':
              'Licenziato sotto GNU General Public License 3.0.',
          'SID_ABOUT_OSS_LICENSES': 'Licenze open source',
          'SID_ABOUT_CODE': 'Codice su GitHub',
          'SID_ABOUT_OSM_NOTICE':
              'Hai bisogno di un account su Mastodon o un servizio Fediverse compatibile per questa app.\nPer trovare luoghi nelle vicinanze, la tua posizione attuale viene inviata all\'API Overpass Turbo di OpenStreetMap.\nPotrai quindi informare i tuoi follower del tuo soggiorno con un post di stato pubblico.',
          'SID_ABOUT_OSM_CONTRIBUTE':
              'Se manca un luogo, puoi registrarti su OpenStreetMap e aggiungere il luogo.',
          'SID_ABOUT_BUTTON_LOGOUT': 'ESCI',
          'SID_SETTINGS_OVERPASS_DOMAIN': 'Istanza Overpass',
          'SID_SETTINGS_ENTER_OVERPASS_DOMAIN': 'Immettere un istanza Overpass',
        },
      };
}
