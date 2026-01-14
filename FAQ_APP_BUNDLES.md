# FAQ: Håndtering av gamle app bundles i Google Play Console

## Må jeg slette gamle app bundles?

**Nei, du trenger ikke slette dem - og du kan faktisk ikke slette dem.**

### Hvorfor kan jeg ikke slette dem?

Google Play Console lagrer alle app bundles du har lastet opp i et **bibliotek**. Dette er av flere grunner:
- **Historikk:** Du kan se hvilke versjoner som har vært publisert
- **Rollback:** Du kan gå tilbake til en tidligere versjon hvis nødvendig
- **Sporing:** Google Play trenger dem for å spore versjonshistorikk

### Hva må jeg gjøre i stedet?

Du må sørge for at versjonskode 83 (den med policy-problemet) er **inaktiv** i alle tracks:

1. **Fjern versjonskode 83 fra alle aktive releases**
   - Lukket testing
   - Åpen testing  
   - Produksjon (hvis den er der)

2. **Sørg for at versjonskode 83 er under "Not included"** i alle nye releases

3. **Verifiser at versjonskode 83 viser "Inactive"** i App bundle explorer

### Hva betyr "Inactive"?

Når en app bundle er **inaktiv**, betyr det:
- ✅ Den er ikke inkludert i noen aktive releases
- ✅ Den er ikke tilgjengelig for brukere
- ✅ Google Play ignorerer den for policy-sjekker
- ✅ Den forblir i biblioteket for historikk

### Hvordan sjekker jeg om versjonskode 83 er inaktiv?

1. Gå til **Release → Setup → App bundle explorer**
2. Søk etter **versjonskode 83**
3. Klikk på den for å se detaljer
4. Sjekk at den viser:
   - **Status:** "Inactive" (eller "Inaktiv")
   - **Releases:** "0 releases" (eller "0 utgivelser")

### Hva hvis versjonskode 83 fortsatt er aktiv?

Hvis versjonskode 83 fortsatt viser at den er aktiv i en track:

1. **Gå til den tracken** (f.eks. Closed testing)
2. **Klikk på "Create new release"**
3. **Fjern versjonskode 83** fra "Included in this release"
4. **Legg til versjonskode 84** (eller den versjonen du vil bruke)
5. **Publiser den nye releasen**

### Kan jeg gjenbruke gamle app bundles senere?

Ja, du kan alltid gå tilbake til en tidligere versjon hvis nødvendig:
- App bundles forblir i biblioteket
- Du kan legge dem til i nye releases
- Dette kalles "rollback"

### Oppsummering

✅ **Du trenger IKKE slette app bundles**  
✅ **Du kan IKKE slette app bundles** (de forblir i biblioteket)  
✅ **Du må sørge for at versjonskode 83 er inaktiv**  
✅ **Når en versjon er inaktiv, ignorerer Google Play den automatisk**  

### Eksempel

**Før (versjonskode 83 aktiv):**
- Closed testing: Versjonskode 83 (aktiv) ❌
- Status: Policy-problem

**Etter (versjonskode 83 inaktiv):**
- Closed testing: Versjonskode 84 (aktiv) ✅
- Versjonskode 83: Inaktiv (0 releases) ✅
- Status: Policy-problem løst
