# Detaljert guide: Hvordan fjerne versjonskode 83 fra alle aktive releases

## Oversikt
Denne guiden viser deg nøyaktig hvordan du fjerner versjonskode 83 (den med policy-problemet) fra alle tracks i Google Play Console.

---

## Steg 1: Identifiser hvor versjonskode 83 er aktiv

Først må du finne ut hvor versjonskode 83 er aktiv.

### 1a. Sjekk App bundle explorer

1. **Logg inn på Google Play Console**
2. **Velg appen din** (Fylgja)
3. I venstre meny, gå til: **Release** → **Setup** → **App bundle explorer**
4. **Søk etter "83"** i søkefeltet (eller scroll ned til versjonskode 83)
5. **Klikk på versjonskode 83** for å se detaljer
6. **Se på "Releases"**-seksjonen - her ser du alle tracks hvor versjonskode 83 er aktiv

**Eksempel på hva du kan se:**
- Closed testing: 1 release
- Open testing: 0 releases
- Production: 0 releases

Dette forteller deg hvor du må fjerne versjonskode 83.

---

## Steg 2: Fjern versjonskode 83 fra Closed testing

Hvis versjonskode 83 er i Closed testing, følg disse stegene:

### 2a. Gå til Closed testing

1. I venstre meny, gå til: **Testing** → **Closed testing**
2. **Klikk på testgruppen din** (f.eks. "Internal testing" eller navnet på din lukkede testgruppe)
3. Du vil se en liste over releases

### 2b. Finn den aktive releasen med versjonskode 83

1. **Se gjennom listen** over releases
2. **Finn den releasen** som inneholder versjonskode 83
   - Den kan ha navn som "Version 1.0.24 (83)" eller lignende
   - Eller den kan være den eneste aktive releasen
3. **Klikk på "Edit release"** (eller "Rediger utgivelse") ved siden av den releasen

### 2c. Fjern versjonskode 83 og legg til versjonskode 84

Når du er inne i release-editoren, vil du se to seksjoner:

**Seksjon 1: "Included in this release"** (eller "Inkludert i denne utgivelsen")
- Her ser du alle app bundles som er inkludert i denne releasen
- Versjonskode 83 vil være her

**Seksjon 2: "Not included in this release"** (eller "Ikke inkludert i denne utgivelsen")
- Her ser du app bundles som ikke er inkludert

**Handlinger:**

1. **Finn versjonskode 83** i "Included in this release"
2. **Klikk på "Remove"** (eller "Fjern") ved siden av versjonskode 83
   - Dette flytter versjonskode 83 til "Not included in this release"
3. **Sjekk at versjonskode 84 er inkludert:**
   - Hvis versjonskode 84 ikke er i "Included", klikk på "Add from library" (eller "Legg til fra bibliotek")
   - Søk etter versjonskode 84 og legg den til
4. **Verifiser at du nå har:**
   - ✅ Versjonskode 84 i "Included in this release"
   - ✅ Versjonskode 83 i "Not included in this release"

### 2d. Lagre og publiser

1. **Scroll ned** til bunnen av siden
2. **Fyll ut release notes** hvis nødvendig:
   ```
   Norsk:
   - Oppdatert til versjonskode 84
   - Fikset policy-problem med USE_FULL_SCREEN_INTENT
   
   English:
   - Updated to version code 84
   - Fixed policy issue with USE_FULL_SCREEN_INTENT
   ```
3. **Klikk "Save"** (eller "Lagre")
4. **Klikk "Review release"** (eller "Gjennomgå utgivelse")
5. **Gjennomgå informasjonen:**
   - Sjekk at versjonskode 84 er inkludert
   - Sjekk at versjonskode 83 er under "Not included"
6. **Klikk "Start rollout to Closed testing"** (eller "Start utrulling til lukket testing")
7. **Velg "Rollout to 100%"** (eller "Utrull til 100%")
8. **Bekreft** at du vil publisere

---

## Steg 3: Fjern versjonskode 83 fra Open testing (hvis den er der)

Hvis versjonskode 83 også er i Open testing, gjør det samme:

1. I venstre meny, gå til: **Testing** → **Open testing**
2. **Klikk på "Create new release"** (eller "Opprett ny utgivelse")
3. **Legg til versjonskode 84** (hvis den ikke allerede er der)
4. **Fjern versjonskode 83** (flytt den til "Not included")
5. **Lagre og publiser** som beskrevet i steg 2d

---

## Steg 4: Fjern versjonskode 83 fra Production (hvis den er der)

**VIKTIG:** Hvis versjonskode 83 er i Production, må du være ekstra forsiktig!

1. I venstre meny, gå til: **Release** → **Production**
2. **Sjekk om versjonskode 83 er aktiv:**
   - Hvis den er i en draft-release, kan du enkelt fjerne den
   - Hvis den er i en publisert release, må du opprette en ny release

### Hvis versjonskode 83 er i en draft-release:

1. **Klikk på "Edit release"** ved siden av draft-releasen
2. **Fjern versjonskode 83** (flytt til "Not included")
3. **Legg til versjonskode 84** (hvis den ikke allerede er der)
4. **Lagre** (du trenger ikke publisere draft-releases)

### Hvis versjonskode 83 er i en publisert release:

1. **Klikk på "Create new release"** (eller "Opprett ny utgivelse")
2. **Legg til versjonskode 84** fra biblioteket
3. **Sørg for at versjonskode 83 IKKE er inkludert** (den skal være under "Not included")
4. **Fyll ut release notes:**
   ```
   Norsk:
   - Oppdatert til versjonskode 84
   - Fikset policy-problem med USE_FULL_SCREEN_INTENT
   - Varsler fungerer fortsatt med lyd og vibrasjon
   
   English:
   - Updated to version code 84
   - Fixed policy issue with USE_FULL_SCREEN_INTENT
   - Notifications still work with sound and vibration
   ```
5. **Lagre og gjennomgå**
6. **Publiser til produksjon** (kun hvis du er klar for det!)

---

## Steg 5: Verifiser at versjonskode 83 er inaktiv

Etter at du har fjernet versjonskode 83 fra alle tracks:

1. **Gå til:** Release → Setup → **App bundle explorer**
2. **Søk etter versjonskode 83**
3. **Klikk på versjonskode 83** for å se detaljer
4. **Verifiser at den viser:**
   - **Status:** "Inactive" (eller "Inaktiv")
   - **Releases:** "0 releases" (eller "0 utgivelser")
   - **Tracks:** Ingen tracks listet

Hvis versjonskode 83 fortsatt viser aktive releases:
- Gå tilbake til den tracken
- Sjekk at versjonskode 83 er under "Not included" i den siste releasen
- Hvis den fortsatt er aktiv, må du opprette en ny release uten den

---

## Steg 6: Sjekk policy-status

1. **Gå til:** Policy → **App content**
2. **Sjekk om policy-problemet med USE_FULL_SCREEN_INTENT er borte**
3. Det kan ta noen minutter før Google Play oppdaterer statusen

---

## Feilsøking

### Problem: Jeg kan ikke finne versjonskode 83 i "Included"

**Mulige årsaker:**
- Versjonskode 83 kan allerede være inaktiv
- Den kan være i en annen track
- Sjekk App bundle explorer for å se hvor den er aktiv

**Løsning:**
1. Gå til App bundle explorer
2. Klikk på versjonskode 83
3. Se hvilke tracks den er aktiv i
4. Gå til hver track og fjern den

### Problem: Versjonskode 83 er fortsatt aktiv etter at jeg fjernet den

**Mulige årsaker:**
- Du har ikke publisert den nye releasen
- Versjonskode 83 er i flere tracks
- Det er en cache-issue

**Løsning:**
1. Sjekk at du har publisert den nye releasen (ikke bare lagret den)
2. Sjekk alle tracks (Closed testing, Open testing, Production)
3. Vent noen minutter og sjekk igjen

### Problem: Jeg kan ikke fjerne versjonskode 83 fra Production

**Mulige årsaker:**
- Versjonskode 83 er den eneste versjonen i produksjon
- Du må ha minst én versjon i produksjon

**Løsning:**
1. Opprett en ny release med versjonskode 84
2. Publiser versjonskode 84 til produksjon
3. Når versjonskode 84 er aktiv, vil versjonskode 83 automatisk bli inaktiv

---

## Visuell guide: Hva du skal se

### Før (versjonskode 83 aktiv):
```
Included in this release:
  ✅ app-release.aab (version code 83)

Not included in this release:
  (tom)
```

### Etter (versjonskode 83 inaktiv):
```
Included in this release:
  ✅ app-release.aab (version code 84)

Not included in this release:
  ❌ app-release.aab (version code 83)
```

---

## Oppsummering

1. ✅ **Identifiser** hvor versjonskode 83 er aktiv (App bundle explorer)
2. ✅ **Gå til hver track** hvor versjonskode 83 er aktiv
3. ✅ **Opprett ny release** eller rediger eksisterende release
4. ✅ **Fjern versjonskode 83** (flytt til "Not included")
5. ✅ **Legg til versjonskode 84** (hvis den ikke allerede er der)
6. ✅ **Publiser** den nye releasen
7. ✅ **Verifiser** at versjonskode 83 er inaktiv (App bundle explorer)

---

## Tidslinje

- **Nå:** Versjonskode 83 er aktiv i en eller flere tracks
- **Etter steg 1-4:** Versjonskode 83 er fjernet fra alle tracks
- **Etter steg 5:** Versjonskode 83 viser "Inactive" i App bundle explorer
- **Etter steg 6:** Policy-problemet er løst

---

## Viktige punkter

⚠️ **Ikke slett app bundles** - de forblir i biblioteket  
✅ **Flytt versjonskode 83 til "Not included"** i alle nye releases  
✅ **Publiser den nye releasen** - ikke bare lagre den  
✅ **Verifiser** at versjonskode 83 er inaktiv etter publisering  
