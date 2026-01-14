# Hvordan fjerne gammel versjon fra Intern testing (basert på skjermbilde)

## Hva jeg ser på skjermbildet ditt

Du er i **"Intern testing"** tracken og har:
- ✅ Versjonskode **82** (1.0.24) aktiv
- 📦 Under "Nye appsamlinger" (New app bundles)

## Steg-for-steg: Fjerne versjonskode 82 og legge til versjonskode 84

### Steg 1: Klikk på "Endre utgavedetaljene" (Edit release details)

1. **Scroll ned** til **"Versjonsnotater"** (Release Notes) seksjonen
2. **Klikk på "Endre utgavedetaljene"** (Edit release details) linken
   - Dette åpner release-editoren hvor du kan endre app bundles

### Alternativ: Opprett ny release

Hvis du ikke ser "Endre utgavedetaljene", kan du:

1. **Se etter en knapp** som sier **"Opprett ny utgivelse"** (Create new release) eller **"Ny utgivelse"** (New release)
   - Den kan være øverst på siden, eller i en dropdown-meny
2. **Klikk på den** for å opprette en ny release

---

## Steg 2: I release-editoren

Når du er inne i release-editoren, vil du se to seksjoner:

### Seksjon A: "Nye appsamlinger" eller "Included in this release"
- Her ser du versjonskode 82 som er aktiv nå

### Seksjon B: "Ikke inkludert" eller "Not included in this release"
- Her vil gamle versjoner vises når de er fjernet

---

## Steg 3: Fjern versjonskode 82

1. **Finn versjonskode 82** i "Nye appsamlinger" (eller "Included in this release")
2. **Se etter en "Fjern"** (Remove) knapp eller **tre prikker (⋮)** ved siden av versjonskode 82
3. **Klikk på "Fjern"** eller **tre prikkene** → **"Fjern"**
4. Versjonskode 82 vil nå flyttes til "Ikke inkludert" (Not included) seksjonen

---

## Steg 4: Legg til versjonskode 84

1. **Se etter en knapp** som sier:
   - **"Legg til fra bibliotek"** (Add from library)
   - **"Add from library"**
   - Eller et **"+"** ikon
2. **Klikk på den**
3. **Søk etter versjonskode 84** i listen
4. **Klikk på versjonskode 84** for å velge den
5. **Klikk "Legg til"** (Add) eller "Add"

---

## Steg 5: Verifiser

Etter at du har gjort endringene, skal du se:

**Nye appsamlinger (New app bundles):**
- ✅ Versjonskode **84** (1.0.24)

**Ikke inkludert (Not included):**
- ❌ Versjonskode **82** (1.0.24)
- ❌ Versjonskode **83** (hvis den var der)

---

## Steg 6: Lagre og publiser

1. **Scroll ned** til bunnen av release-editoren
2. **Fyll ut "Versjonsnotater"** (Release notes) hvis du vil:
   ```
   Oppdatert til versjonskode 84
   - Fikset policy-problem med USE_FULL_SCREEN_INTENT
   - Varsler fungerer fortsatt med lyd og vibrasjon
   ```
3. **Klikk "Lagre"** (Save)
4. **Klikk "Gjennomgå utgivelse"** (Review release)
5. **Gjennomgå** at versjonskode 84 er inkludert og versjonskode 82 er fjernet
6. **Klikk "Start utrulling til Intern testing"** (Start rollout to Internal testing)
7. **Velg "Utrull til 100%"** (Rollout to 100%)

---

## Hvis du ikke ser "Endre utgavedetaljene"

Hvis du ikke ser "Endre utgavedetaljene" linken, prøv dette:

### Alternativ 1: Se etter en dropdown-meny
1. **Se etter en dropdown** ved siden av "Intern testing" overskriften
2. **Klikk på den** for å se flere alternativer
3. **Velg "Opprett ny utgivelse"** (Create new release)

### Alternativ 2: Se etter en knapp øverst
1. **Se øverst på siden** etter en knapp som sier:
   - **"Ny utgivelse"** (New release)
   - **"Opprett utgivelse"** (Create release)
   - Eller et **"+"** ikon
2. **Klikk på den**

### Alternativ 3: Se på tre prikkene (⋮) ved versjonskode 82
1. **Se på høyre side** av versjonskode 82 i tabellen
2. **Klikk på tre prikkene (⋮)**
3. **Se etter "Fjern"** (Remove) eller lignende i dropdown-menyen

---

## Viktig: Sjekk også andre tracks

Versjonskode 83 (den med policy-problemet) kan være i andre tracks:

1. **Gå til "Lukket testing"** (Closed testing) i venstre meny
2. **Sjekk om versjonskode 83 er der**
3. Hvis den er der, gjør det samme der:
   - Opprett ny release
   - Fjern versjonskode 83
   - Legg til versjonskode 84

---

## Visuell guide: Hva du skal se

### Før endring:
```
Nye appsamlinger:
  ✅ Versjonskode 82 (1.0.24)

Ikke inkludert:
  (tom)
```

### Etter endring:
```
Nye appsamlinger:
  ✅ Versjonskode 84 (1.0.24)

Ikke inkludert:
  ❌ Versjonskode 82 (1.0.24)
  ❌ Versjonskode 83 (1.0.24) - hvis den var der
```

---

## Hvis du fortsatt ikke finner det

1. **Ta et nytt skjermbilde** av hele siden
2. **Eller beskriv** hva du ser når du klikker på "Endre utgavedetaljene"
3. Jeg kan hjelpe deg videre basert på det!
