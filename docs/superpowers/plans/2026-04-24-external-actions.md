# Actions externes — Ferizaj pivot (2026-04-24)

Ce document liste les actions que l'utilisateur doit exécuter manuellement dans des consoles SaaS ou des repos tiers. Complément du plan principal `2026-04-24-ferizaj-first-pivot.md`.

## 1. Typeform / Tally — salon candidature

**Objectif :** que le formulaire salon capture la ville et la fenêtre d'activation souhaitée.

**Champs à ajouter / modifier :**

| Champ | Type | Obligatoire | Options |
|---|---|---|---|
| `qyteti` | Dropdown | Oui | Ferizaj, Prishtinë, Prizren, Pejë, Gjakovë, Mitrovicë, Gjilan, Tjetër (préciser) |
| `kur_dëshiron_të_fillosh` | Radio | Oui | « Tash — sa më shpejt » (maintenant, flag pilote fondateur) / « Te lansimi i majit » (au launch public) |
| `si_dëgjove_për_ne` | Text court | Non | Optional, pour tracking organic/referral |

**Logic côté Airtable / Google Sheets :**
- Si `qyteti = Ferizaj` ET `kur = Tash` → tag « PILOTE_FONDATEUR_CANDIDATE », alerter fondateur par email immédiat
- Si `qyteti = Ferizaj` ET `kur = Mai` → tag « WAVE_1 »
- Si `qyteti != Ferizaj` → tag `WAVE_<Prishtinë|Prizren|...>` + email auto de wave 2+

**Email auto à envoyer si ville != Ferizaj** (via Zapier ou natif Typeform) :

```
Sujet : Faleminderit — të shohim në wave 2

Salloni yt është regjistruar. Ne lansojmë me 15 sallone
pilot në Ferizaj në maj. Prishtinën e hapim në korrik.

Do të të shkruajmë drejtpërdrejt kur të vijë radha e qytetit tënd.

— Labinot, Termini im
```

## 2. TestFlight + Google Play Internal Testing

**Objectif :** avoir une track bêta privée disponible pour les pilotes fondateurs avant le launch public J30.

**iOS (TestFlight) :**
1. Build iOS de test prêt (avec Apple Sign-In déjà câblé — cf. Task 2 du doc app-gaps-notifications)
2. Dans App Store Connect → TestFlight → créer un groupe **« Pilot Themelues »**
3. Ajouter les emails des pilotes fondateurs à ce groupe (manuellement au fil des signatures)
4. Envoyer l'invitation TestFlight ; chaque pilote installe via le lien TestFlight

**Android (Internal Testing) :**
1. Dans Google Play Console → Release → Testing → Internal testing → créer une track
2. Uploader le même AAB que la prod future
3. Ajouter une liste de testeurs (email Gmail obligatoire pour Play Store)
4. Partager le lien d'opt-in : `https://play.google.com/apps/internaltest/…`

**Communication à l'owner signant :**

> « Tu vas recevoir un email TestFlight dans 10 min (ou un lien Google Play si tu es sur Android). Tu installes, tu te connectes avec ton email, tu reçois un code de vérification par email, et tu es dans. Si quelque chose cloche, tu m'écris direct sur WhatsApp. »

## 3. Email template pilote fondateur (backend Laravel)

**Localisation :** repo `C:\Users\avdiu\Projetcs\Lagedi\backend`

**Fichier à créer :** `resources/views/emails/salon/pilot-themelues-welcome.blade.php`

**Différences avec le template welcome owner standard :**
- Ton plus personnel (« Hey, c'est Labi »)
- Mention explicite du statut « Pilot Themelues » et de ses privilèges à vie
- Numéro WhatsApp fondateur visible, avec CTA « WhatsApp-më direkt »
- Pas de "Contact support team" générique
- Checklist 5 étapes avec un timing serré (« dans les 48h »)

**Structure suggérée (SQ, à traduire aussi FR/EN via `Mail::to()->locale()->send()`) :**

```
Sujet : Mirë se erdhe te pilotët themelues — Termini im

Hej [name],

Jam Labi. Po të shkruaj personalisht sepse je ndër 5-8 sallonet e parë
që besojnë te ne para të tjerëve. Kjo nuk harrohet — kështu që ja
çka kam për ty :

1. Badge « Pilot Themelues » — për gjithë jetën në galerinë kryesore
2. Linjë direkte me mua në WhatsApp: +383 XX XXX XXX — për 6 muajt e parë
3. Përparësi në features të reja — para se ti vijnë publikut
4. Vendi i parë në kërkime Ferizaj për 3 muajt e parë pas lansimit

Tani : hap aplikacionin, shto shërbimet, shto 3 fotografi.
Bëje në 48 orë — unë të ndihmoj nëse ngecesh.

— Labi
```

**Trigger côté Laravel :** quand un salon est marqué `is_pilot_themelues = true` dans la DB, envoyer ce template au lieu du welcome owner standard. Flag à ajouter au model `Salon` (migration simple).

**Déclenchement :** le fondateur flag manuellement `is_pilot_themelues = true` dans Nova/Telescope/admin custom après la signature terrain — ce n'est pas un opt-in utilisateur.
