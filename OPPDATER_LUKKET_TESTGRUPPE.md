# Hvordan oppdatere lukket testgruppe i Google Play Console

## Oversikt
Denne guiden forklarer hvordan du oppdaterer din lukkede testgruppe med versjonskode 84 (uten USE_FULL_SCREEN_INTENT) og fjerner versjonskode 83 som har policy-problemet.

---

## Steg 1: Gå til Testing-seksjonen

1. **Logg inn på Google Play Console**
2. **Velg appen din** (Fylgja)
3. I venstre meny, gå til: **Testing** → **Closed testing**
4. **Klikk på testgruppen din** (f.eks. "Internal testing" eller navnet på din lukkede testgruppe)

---

## Steg 2: Opprett ny release

1. **Klikk på "Create new release"** (eller "Opprett ny utgivelse")
2. Du vil se en side med "App bundles and APKs"

---

## Steg 3: Legg til ny versjon (84) og fjern gammel versjon (83)

### 3a. Legg til ny AAB:
1. **Klikk på "Add from library"** (eller "Legg til fra bibliotek")
2. **Velg versjonskode 84** fra listen
   - Dette er den nye versjonen uten USE_FULL_SCREEN_INTENT
   - Fil: `app-release.aab` (versjonskode 84)
3. **Klikk "Add"** (eller "Legg til")

### 3b. Fjern gammel versjon (83):
1. **Finn versjonskode 83** i listen over "Included in this release"
2. **Klikk på "Remove"** (eller "Fjern") ved siden av versjonskode 83
3. Versjonskode 83 skal nå vises under **"Not included in this release"** (eller "Ikke inkludert i denne utgivelsen")

**VIKTIG:** Versjonskode 83 må være under "Not included" for å fikse policy-problemet!

---

## Steg 4: Fyll ut release-informasjon

1. **Release name** (Utgivelsesnavn):
   - F.eks: "Version 1.0.24 (84) - Policy fix"
   - Eller: "Versjon 1.0.24 (84) - Policy-fiks"

2. **Release notes** (Utgivelsesnotater):
   - Skriv på norsk og engelsk:
   ```
   Norsk:
   - Fikset policy-problem med USE_FULL_SCREEN_INTENT
   - Varsler fungerer fortsatt med lyd og vibrasjon
   
   English:
   - Fixed policy issue with USE_FULL_SCREEN_INTENT
   - Notifications still work with sound and vibration
   ```

---

## Steg 5: Lagre og gjennomgå

1. **Scroll ned** og klikk **"Save"** (eller "Lagre")
2. **Klikk "Review release"** (eller "Gjennomgå utgivelse")
3. **Gjennomgå informasjonen** for å bekrefte:
   - ✅ Versjonskode 84 er inkludert
   - ✅ Versjonskode 83 er IKKE inkludert (under "Not included")
   - ✅ Release notes er fylt ut

---

## Steg 6: Publiser til testgruppen

1. **Klikk "Start rollout to Closed testing"** (eller "Start utrulling til lukket testing")
2. **Velg "Rollout to 100%"** (eller "Utrull til 100%")
3. **Bekreft** at du vil publisere

---

## Steg 7: Verifiser at versjonskode 83 er deaktivert

1. **Gå til:** Release → Setup → **App bundle explorer**
2. **Søk etter versjonskode 83**
3. **Klikk på versjonskode 83** for å se detaljer
4. **Verifiser at den viser:**
   - Status: **"Inactive"** (eller "Inaktiv")
   - Releases: **"0 releases"** (eller "0 utgivelser")

**VIKTIG:** Du trenger IKKE slette app bundlene - de forblir i biblioteket, men blir automatisk ignorert når de er inaktive.

Hvis versjonskode 83 fortsatt viser aktive releases, må du:
- Gå tilbake til testgruppen
- Sjekk at versjonskode 83 er under "Not included"
- Hvis den fortsatt er aktiv, må du opprette en ny release uten den

---

## Steg 8: Last opp mapping-fil (valgfritt, men anbefalt)

1. **Gå til:** Release → Setup → **App bundle explorer**
2. **Klikk på versjonskode 84**
3. **Klikk "Upload"** ved siden av "Deobfuscation file"
4. **Last opp:** `build\app\outputs\mapping\release\mapping.txt`

---

## Feilsøking

### Problem: Versjonskode 83 er fortsatt aktiv
**Løsning:**
- Sjekk at versjonskode 83 er under "Not included" i den nye releasen
- Hvis den fortsatt er aktiv i en annen track, må du også fjerne den derfra

### Problem: Kan ikke fjerne versjonskode 83
**Løsning:**
- Versjonskode 83 må være under "Not included" i alle aktive releases
- Hvis den er i produksjon, må du opprette en ny produksjonsrelease uten den

### Problem: Testgruppen får ikke oppdateringen
**Løsning:**
- Sjekk at releasen er publisert (ikke bare lagret)
- Sjekk at versjonskode 84 er inkludert
- Det kan ta noen minutter før oppdateringen er tilgjengelig

---

## Viktige punkter

✅ **Versjonskode 84** er den nye versjonen uten USE_FULL_SCREEN_INTENT  
✅ **Versjonskode 83** må være under "Not included" i alle tracks  
✅ **Mapping-fil** bør lastes opp for bedre feilsøking  
✅ **Release notes** hjelper testere forstå endringene  

---

## Når dette er gjort

Etter at du har publisert versjonskode 84 og fjernet versjonskode 83 fra alle aktive releases:

1. **Google Play vil automatisk oppdatere policy-statusen**
2. **Policy-problemet vil forsvinne** når versjonskode 83 er inaktiv
3. **Testerne vil få oppdateringen** automatisk eller kan laste den ned manuelt

---

## Tidslinje

- **Nå:** Bygget versjonskode 84 (uten USE_FULL_SCREEN_INTENT)
- **Neste:** Last opp til Play Console og publiser til testgruppe
- **Resultat:** Policy-problemet løses automatisk når versjonskode 83 er deaktivert
