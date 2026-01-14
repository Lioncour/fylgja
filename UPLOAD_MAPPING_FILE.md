# Hvordan laste opp Mapping-fil til Google Play Console

## Hva er mapping.txt?

`mapping.txt` er en deobfuscering-fil som mapper obfuskert kode tilbake til original kode. Den er essensiell for å kunne lese stack traces når appen krasjer i produksjon.

## Hvor finner jeg mapping.txt?

Etter å ha bygget AAB med R8/ProGuard aktivert, finner du mapping-filen her:

```
build\app\outputs\mapping\release\mapping.txt
```

## Hvordan laste opp til Play Console:

1. **Gå til Google Play Console**
2. **Velg appen din** (Fylgja)
3. **Gå til:** Release → Setup → App bundle explorer
4. **Velg versjonen** du nettopp lastet opp (versjonskode 83)
5. **Klikk på "Upload"** ved siden av "Deobfuscation file"
6. **Last opp:** `build\app\outputs\mapping\release\mapping.txt`

## Viktig:

- **Last opp mapping.txt for hver versjon** du publiserer
- **Behold mapping.txt-filene** - du trenger dem for å debugge krasjer
- **Ikke commit mapping.txt til git** (den er allerede i .gitignore)

## Symbolfiler (Native Debug Symbols):

For Flutter-apps er symbolfiler mindre kritiske, men hvis du vil laste dem opp:

1. Gå til samme sted i Play Console
2. Last opp symbolfiler fra: `build\app\intermediates\merged_native_libs\release\out\lib\`

**Merk:** For de fleste Flutter-apps er mapping.txt nok. Symbolfiler er primært for native C/C++ kode.

## Nåværende status:

✅ R8/ProGuard aktivert
✅ Appstørrelse redusert (fra 22.2MB til 21.3MB)
✅ Mapping-fil generert
📤 Klar for opplasting til Play Console
