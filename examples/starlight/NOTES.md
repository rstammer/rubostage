# starlight

Cover von **Muse — „Starlight"** (Black Holes and Revelations, 2006). Kein
Blackminded-Song, sondern ein Play-Along zum Draufspielen.

## Quellen

| Was | Wo |
|---|---|
| Akkorde | Ultimate Guitar, `tabs.ultimate-guitar.com/tab/muse/starlight-chords-411547` — die Seite ließ sich nicht automatisch auslesen. Laut Suchergebnis notiert UG mit **Kapo 2** als `A – Bm – F#m – D`, klingend also `B – C#m – G#m – E` |
| Form, Tempo, Harmonik | Analyse von Daniel Compton, `danielcompton.net/muse-starlight` |
| Songtext | **liegt bewusst nicht im Repo** — fremder Text, Robin kennt ihn |

## Eckdaten

- **Tempo:** 121,5 BPM, im C-Teil 122,5. Gerundet auf **122**.
- **Tonart:** H-Dur.
- **Hauptprogression:** `I – ii – vi – IV` = `| B | C#m | G#m | E |`, je ein Takt.
  Ohne Dominante; endet plagal (IV → I).

## Form (laut Analyse)

| Teil | Takte | Harmonik | Was passiert |
|---|---|---|---|
| Intro | 12 | I–ii–vi–IV | verzerrter Bass + Drums, Piano-Gegenstimme ab Takt 5 (leise Glocke verdoppelt) |
| Strophe 1 | 16 | dieselbe | Piano raus, Drum-Pattern auf doppelte Länge gestreckt |
| B-Teil | 8 | dieselbe | wie Intro, mit Gesang — der eigentliche Refrain |
| Strophe 2 | 8 | dieselbe | gepickte Gitarrenlinie |
| C-Teil | 8 + 24 | Paralleltonart gis-Moll | Powerchords, Wechsel auf der „und" von 4 jedes zweiten Takts; Arpeggiator-Sechzehntel; Drums gerade und treibend |
| B-Teil | – | dieselbe | |
| Strophe 3 | – | wie Strophe 2 | Gitarrenlinie eine Oktave tiefer |
| C-Teil | – | wie oben | lautester Teil |
| B-Teil | – | dieselbe | Schluss |

**Der Snare-Schlag ist der Haken:** laut, über dem Rest des Kits, und leicht
**hinter** 2 und 4. In `live.rb` per `time_warp` um 0,04 Schläge (≈ 20 ms)
verschoben — Wert `behind` ganz oben.

## live.rb

Drei Teile, alle exakt vier Takte, umschaltbar wie bei traveller:

| Sektion | Harmonik | Drums | Bass | dazu |
|---|---|---|---|---|
| `:intro` | I–ii–vi–IV | Kick 1, 3, 3+, Snare + Snap auf 2/4 | Achtel | Keys-Figur + Glocke, Fläche |
| `:verse` | I–ii–vi–IV | Halftime: Snare nur auf 3 | Viertel | nur Fläche |
| `:bridge` | gis–E–H–Fis | gerade Viertel-Kick, Hi-Hat Sechzehntel | Achtel, Vorzieher auf 4+ in Takt 2/4 | Sägezahn-Arpeggio |

`:intro` deckt auch den B-Teil ab — gleiche Harmonik, gleiche Besetzung.

```bash
bin/play examples/starlight/live.rb
bin/play -e 'set :section, :verse'
bin/play -e 'set :section, :bridge'
bin/play --stop
```

### Bewusst nicht nachgebaut

**Das Piano-Riff des Originals.** Die Keys-Stimme in `:intro` ist eine eigene
Achtelfigur durch die Akkordtöne, keine Transkription. Das passt auch zur
Leitidee — erkennbar über Harmonik, Tempo und den Snare-Groove, nicht als
Nachbau. Wer das Original-Riff will, spielt es live drüber.

## Offen

- [ ] **C-Teil-Akkorde bestätigen.** `G#m – E – B – F#` ist eine Annahme
      (Paralleltonart, aus der Analyse nicht ausbuchstabiert). Robin hört ab.
- [ ] Strophen-Drums: ist „doppelte Länge" als Halftime richtig gedeutet?
- [ ] Kick-Pattern im Intro gegen das Original hören
- [x] Erster Durchlauf mit `--record` — läuft, alle drei Teile umschaltbar
