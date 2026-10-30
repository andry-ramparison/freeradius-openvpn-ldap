# P16 - Authentification OpenVPN avec FreeRADIUS et LDAP

## Objectif

Mettre en oeuvre le modèle AAA (Authentication, Authorization, Accounting) avec FreeRADIUS, OpenLDAP et OpenVPN.

## Architecture

- FreeRADIUS : serveur d'authentification RADIUS.
- OpenLDAP : annuaire centralisé des utilisateurs.
- OpenVPN : accès VPN protégé par authentification
- Docker Compose : orchestration des services.

## Parcours d'authentification et accounting

OpenVPN vérifie le nom d'utilisateur et le mot de passe par le plugin PAM. PAM envoie une requête RADIUS à FreeRADIUS, qui recherche l'utilisateur dans LDAP et n'accepte que les membres de `vpn-users`. FreeRADIUS écrit les événements reçus dans le module `detail` sous `/var/log/radius` (volume Docker persistant). OpenVPN envoie un Accounting-Start à la connexion et un Accounting-Stop à la déconnexion.

## Démarrage

1. Copier `.env.example` vers `.env` et remplacer les secrets d'exemple.
2. Générer les certificats du serveur dans le volume `openvpn_pki` (voir ci-dessous).
3. Lancer `docker compose up -d --build`.
4. Préparer `openvpn/config/client.ovpn.example` : remplacer le serveur et intégrer le contenu de `ca.crt` dans le bloc `<ca>`.
5. Importer le profil dans OpenVPN Connect/OpenVPN puis se connecter avec un compte LDAP du groupe `vpn-users`.

### Génération initiale de la PKI

Le volume `openvpn_pki` stocke les clés et certificats; il n'est pas publié dans Git. Exécuter depuis la racine du dépôt :

```sh
docker compose run --rm --entrypoint /bin/sh openvpn -ec '
  cp -a /usr/share/easy-rsa/. /tmp/easy-rsa
  cd /tmp/easy-rsa
  export EASYRSA_PKI=/etc/openvpn/pki EASYRSA_BATCH=1
  ./easyrsa init-pki
  ./easyrsa build-ca nopass
  ./easyrsa gen-req server nopass
  ./easyrsa sign-req server server
  ./easyrsa gen-dh
  ./easyrsa gen-crl
'
```

La clé CA est conservée dans le volume; en production, protéger et sauvegarder la PKI hors du conteneur. Pour modifier `RADIUS_SECRET` après le premier démarrage, redémarrer les deux services (`docker compose up -d --force-recreate freeradius openvpn`).

## Vérifications

FreeRADIUS écoute sur UDP 1812/1813 uniquement sur localhost de l'hôte, et OpenVPN sur UDP 1194. Les tests suivants utilisent `radtest` dans le conteneur FreeRADIUS; remplacer les variables par les identifiants réellement configurés dans LDAP sans les enregistrer dans le dépôt :

```sh
docker compose exec freeradius sh -c 'radtest alice "MOT_DE_PASSE_VALIDE" 127.0.0.1 0 "$RADIUS_SECRET"'
docker compose exec freeradius sh -c 'radtest eve "MOT_DE_PASSE_VALIDE" 127.0.0.1 0 "$RADIUS_SECRET"'
docker compose exec freeradius sh -c 'radtest alice "MAUVAIS_MOT_DE_PASSE" 127.0.0.1 0 "$RADIUS_SECRET"'
docker compose logs -f freeradius openvpn
```

Alice est membre de `vpn-users`; Eve ne l'est pas. Attendu : Access-Accept pour Alice avec le bon mot de passe, Access-Reject pour Eve et pour le mauvais mot de passe. Pour vérifier l'accounting, établir une session VPN puis la fermer et consulter les fichiers `detail` :

```sh
docker compose exec freeradius sh -c 'find /var/log/radius -type f -maxdepth 5 -print'
docker compose exec freeradius sh -c 'grep -R "Acct-Status-Type" /var/log/radius'
```

Les fichiers doivent contenir `Start` et `Stop` pour la session terminée. L'authentification par mot de passe ne chiffre pas les paquets RADIUS; garder le réseau Docker isolé et choisir un secret RADIUS fort. Pour un déploiement exposé, configurer RADIUS sur TLS/IPsec et durcir la PKI.

## Sécurité

Ne jamais publier de mots de passe, clés privées, secrets RADIUS ou fichiers .env contenant des secrets.
