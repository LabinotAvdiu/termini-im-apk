# `.well-known/` — App Links + Universal Links

Ce dossier est servi tel quel à `https://www.termini-im.com/.well-known/` par
le `rsync` du workflow `deploy.yml`. Toute modif ici part en prod au prochain
push sur `main`.

## Fichiers

- **`assetlinks.json`** — Android App Links. Contient le SHA-256 du
  certificat Play App Signing. Si l'empreinte est vide ou incorrecte,
  Android n'ouvrira PAS l'app directement quand l'utilisateur clique un
  lien `https://www.termini-im.com/company/{id}` — il montrera le picker.
- **`apple-app-site-association`** (sans extension !) — iOS Universal
  Links. Contient le Team ID Apple + Bundle ID. Si le fichier est mal
  formé ou pas en `application/json`, iOS rejettera silencieusement.

## Comment remplir les placeholders

### Android — `REPLACE_WITH_PLAY_APP_SIGNING_SHA256`

Récupère le SHA-256 dans Play Console :
> App → Setup → App integrity → App signing key certificate → SHA-256

Format : 64 hex chars uppercase séparés par `:`. Exemple :
`14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5`

⚠️ Utilise le **App signing key**, pas l'**Upload key**. Google re-signe
ton APK avec le App signing key au moment de la distribution Play.

### iOS — `REPLACE_WITH_TEAM_ID`

Apple Developer Portal → Membership → Team ID (10 chars alphanumériques).

Final `appIDs` : `ABC1234DEF.com.terminiim.app`.

## Apache (déjà configuré sur le VPS)

Le vhost HTTPS `www.termini-im.com` force `Content-Type: application/json`
sur les 2 fichiers (sans ça iOS rejette le AASA même bien formé). Si jamais
il faut le réinstaller, le snippet est :

```apache
<Location "/.well-known/assetlinks.json">
    ForceType application/json
    Header set Cache-Control "public, max-age=3600"
</Location>

<Location "/.well-known/apple-app-site-association">
    ForceType application/json
    Header set Cache-Control "public, max-age=3600"
</Location>
```

⚠️ Si un `<Location "/.well-known/acme-challenge">` Let's Encrypt existe,
place les 2 blocs ci-dessus APRÈS lui pour ne pas casser le renouvellement
de certificat.

## Validation post-déploiement

```bash
# Android — JSON, status 200, content-type application/json
curl -i https://www.termini-im.com/.well-known/assetlinks.json

# iOS — JSON, status 200, content-type application/json, AUCUN redirect
curl -i https://www.termini-im.com/.well-known/apple-app-site-association

# Validateur Apple officiel
# https://search.developer.apple.com/appsearch-validation-tool/

# Côté Android, après réinstall de l'app sur un device
adb shell pm get-app-links com.terminiim.app
# expect: "verified" pour www.termini-im.com
```
