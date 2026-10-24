# P16 - Authentification RADIUS avec FreeRADIUS

## Objectif

Mettre en oeuvre le modèle AAA (Authentication, Authorization, Accounting) avec FreeRADIUS, OpenLDAP et OpenVPN.

## Architecture

- FreeRADIUS : serveur d'authentification RADIUS.
- OpenLDAP : annuaire centralisé des utilisateurs.
- OpenVPN : accès VPN protégé par authentification
- Docker Compose : orchestration des services.

## Structure du dépôt

- freeradius/config/ : configuration FreeRADIUS.
- openldap/config/ : configuration LDAP.
- openvpn/config/ : configuration OpenVPN.
- scripts/ : scripts d'installation et d'administration.
- tests/ : tests d'authentification et résultats.
- captures/ : preuves du fonctionnement.
- rapport/ : rapport du projet

## État du projet

En cours de préparation.

## Sécurité

Ne jamais publier de mots de passe, clés privées, secrets RADIUS ou fichiers .env contenant des secrets.