# Termini Im — Architecture & working context

> **Key fact**: this repo (`hairspot_mobile`) is the user-facing product. The
> internal codename is `hairspot` but the real name, everywhere user-facing, is
> **Termini Im**.

## Two-repo setup

| Concern        | Repo                              | Stack                                    |
| -------------- | --------------------------------- | ---------------------------------------- |
| App (client)   | `C:\Users\avdiu\Projetcs\hairspot_mobile` | Flutter (iOS, Android, Web) — **THIS repo** |
| API (backend)  | `C:\Users\avdiu\Projetcs\Lagedi\backend`  | Laravel 11/12 + MySQL + Sanctum           |

The `Lagedi/frontend` Vue project **is not used** — ignore it unless the user
explicitly asks. All user-facing UX lives in this Flutter app; Vue was an early
prototype that was superseded.

## Where the design lives

The canonical design system (colors, fonts, logos) is in this repo under
`lib/core/theme/` and `assets/branding/`. When producing any visual output for
Termini Im — including **emails sent by the Laravel backend** — source the
palette, typography and logo from here, not from `Lagedi/frontend`.

### Palette (from `lib/core/theme/app_colors.dart`)

- **Primary / bourgogne** : `#7A2232` (light `#9E3D4F`, dark `#511522`)
- **Secondary / or** : `#C89B47` (light `#D9B46A`, dark `#A07A2C`)
- Background : `#F7F2EA` — sand
- Surface : `#FCF7EE` — ivory
- Ink (text) : `#171311`, secondary `#332C29`, hint `#716059`
- Divider `#E8DCC8`, Border `#D9CAB3`, Ivory alt `#EFE6D5`

### Typography (Google Fonts)

- **Fraunces** — serif, used for h1/h2/h3 (headings)
- **Instrument Sans** — sans-serif, used for body, buttons, captions
- **Instrument Serif** (italic) — used for the "im" wordmark and italic emphasis

### Logo

- Wordmark: "Termini" in Fraunces ink + "im" in Instrument Serif italic bourgogne
- Signature bourgogne dot above (`.`) — see `assets/branding/logo-primary.svg`
- Tagline format: `PRISHTINË · 2026` in Instrument Sans, letter-spacing `0.28em`

Never use "TERMINI IM" in all-caps spaced characters — that was a prototype
style that is no longer current.

## Backend pointers

- API base URL (dev): `http://localhost:8080/api`
- Mail testing: Mailpit at `http://localhost:8025` (SMTP on port `1025`)
- Auth flow: Sanctum bearer tokens + custom refresh-token table
- Email verification + password reset both use **6-character OTP codes**
  (no clickable links — the Flutter app has a dedicated "enter the code" screen)
- Email localization: the user's `locale` column (one of `fr`, `en`, `sq`) is
  captured at `/auth/register` and honoured via `Mail::to()->locale()->send()`;
  translation strings live in `backend/resources/lang/{fr,en,sq}/emails.php`

## Language notes

- UI supports `fr`, `en`, `sq` (Albanian, ISO code — **not** `sh`)
- User prefers French-language communication
