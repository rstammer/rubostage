# rubostage

Wunschsong rein, Play-Along raus. Robin steht auf der Straße, jemand wünscht
sich einen Song, die App macht daraus sofort eine Begleitung in Sonic Pi —
**Robin singt und spielt Gitarre selbst dazu.** Die App zeigt Form und Akkorde,
keine Original-Songtexte.

Entstanden als `stage/` im Band-Repo `mcblinded`, 2026-10-20 in ein eigenes
Repo gezogen (Historie mitgenommen). rubostage ist **bandunabhängig**: Was für
Blackminded/mcblinded spezifisch ist, gehört nach `mcblinded`, nicht hierher.
Die einzige Brücke ist der Export (`SONGS_ROOT`).

## Ablauf

1. Wunsch → `claude -p` → `SongSheet` (Tonart, Tempo, Form, Akkorde) → `Groove`
   spielt sofort in Sonic Pi.
2. `ArrangeSongJob` holt ein JSON-Arrangement (Klänge aus fester Liste,
   16-Step-Patterns, Energie 1–3 je Teil, Drum-Groove, Gitarrenspielweise) und
   tauscht im Laufen nur die Stimmen; der `:conductor`-Loop behält die Position.
3. Sonic Pi meldet jeden Akkord per OSC an UDP 4570 (`STAGE_OSC_PORT`),
   `StepListener` schiebt es per Turbo Stream ins Lead-Sheet.
4. Befehle (Wiederholen/Weiter/Springen/Ende) greifen an Teilgrenzen,
   Tasten P/S/R/N/E/1–9.
5. Songs sind editierbar (`SongEditor`), Riffs als ASCII-Tab (`Tab`, `RiffTrack`).
6. „⤓ Ins Repo" → `SongExport` schreibt `<SONGS_ROOT>/<song>/live.rb` +
   `NOTES.md`. Nur Dateien mit Export-Markierung in Zeile 1 werden
   überschrieben, handgeschriebene nie.

Oben sitzt die **Kontrollleiste** (`ControlPanel`, `controls/_panel`): Lämpchen
wie an einem Amp für Sonic Pi (aus / blinkt beim Hochfahren / an, mit
Start-Knopf), Song (letzte Takt-Meldung jünger als 3 s) und KI (Job läuft).
Ein Turbo-Frame, der sich per `poll`-Controller alle 2 s neu holt.

`examples/starlight/` ist die handgeschriebene Vorlage, nach der `Groove`
gebaut wurde (4-Takt-Sektionen, `get[:section]`, `:clock` zuletzt definieren).
Kam am 2026-10-20 aus mcblinded herüber, weil es ein Muse-Cover ist.

**Die KI-Anbindung über `claude -p` ist vorläufig** (`ClaudeCli`) — austauschbar
halten. **Offline-fähig bleiben:** alles schon Erzeugte spielt ohne Netz.

## Starten

```bash
tail -f /dev/null | SONGS_ROOT=../mcblinded/songs PORT=4567 bin/dev
```

- Port 3000 ist oft von Robins trendence-Puma belegt → **4567**.
- Ohne offenes stdin beendet sich `tailwindcss:watch`, foreman reißt alles mit.
- Tailwind wird nur über `bin/dev` neu gebaut, nicht über `rails server`.
- Alter Puma hält den Port; `pkill -f "rails server"` trifft ihn nicht.

## Sonic Pi

Sonic Pi 5.0 (`brew install --cask sonic-pi`), die App muss laufen. Der Client
steckt in `lib/sonic_pi.rb` + `lib/osc.rb` (kopiert aus `mcblinded/bin/play`).
`bin/play` nutzt ihn ohne Rails: `bin/play <datei>`, `-e <code>`, `--stop`,
`--status`, `--record <datei> -o <wav> -t <s>`.

- **Nicht auf das Gem `spx` umstellen** — gegen 4.5 geschrieben. Port und Token
  stehen in Sonic Pi 5 in den Prozessargumenten des Spider-Servers (`ARGV[1]`,
  `ARGV[6]`) und ändern sich bei jedem Neustart. Senden an `127.0.0.1`, nicht
  `localhost` (löst auf macOS zuerst nach `::1` auf, Pakete verschwinden lautlos).
- **Sonic Pi aus der App starten nur ohne unsere Ruby-Umgebung.** `open -a`
  reicht das Environment weiter, und Sonic Pis eigenes Ruby stirbt beim Boot
  an `RUBYOPT=-rbundler/setup`/`GEM_HOME`/`BUNDLE_GEMFILE` — die GUI meldet dann
  „Error reading ports via Boot Daemon", `daemon.log` bleibt leer.
  `SonicPiApp.launch` räumt `RUBY*`/`BUNDLE*`/`GEM_*` vorher ab.
- **Code > 8 KB über `run_file`**, nicht per UDP (macOS-Limit 9216 B).
- **Eingebaute Funktionsnamen dürfen keine Variablennamen sein** (`ring`,
  `spread`, `line`, `range`, `knit`, `scale`, `chord`, `tick` …) — sonst
  verwirft Sonic Pi den ganzen Puffer mit `PreParseError`. `CodeCheck` prüft das.
- **Erfolgreiche Läufe werden nicht protokolliert**, Fehler nur in
  `~/.sonic-pi/log/spider.log`. Objektiv prüfen per Aufnahme (WAV ist 24 Bit).
- **Überlast:** zu viele Synths pro Sechzehntel lassen Sonic Pi nach Sekunden
  verstummen. Ein `:dsaw` pro Note, keine Dopplung.
- **Kein Ton, aber Akkorde laufen mit** = Sonic Pi spielt aufs falsche Gerät.
  Sonic Pi → Einstellungen → Audio → Gerät fest wählen.
  Diagnose in `~/.sonic-pi/log/supersonic.log`.

## Fallen in der App

- `data-turbo-permanent` **nie** auf `#now_playing` selbst (Turbo ignoriert dann
  Stream-Replaces) — es sitzt auf der Hülle `#now_playing_frame`.
- `config.x.<unset>` liefert ein leeres `OrderedOptions`, nicht `nil`.
- Headless Chrome trennt den WebSocket sofort; Mitlaufen nur per CDP-Skript prüfbar.

## Konventionen

- **Sprache:** Kommunikation auf Deutsch, Code und Commits auf Englisch
- **Commits:** ohne jede AI-Referenz — kein `Co-Authored-By`, kein „Generated
  with", keine Werkzeugnennung.
- **Stil:** StandardRB (`bundle exec standardrb`)
- **TDD:** RSpec, Failing Test zuerst. Kein Testzwang für Klang.
- **Musikalische Urteile trifft Robin.**
