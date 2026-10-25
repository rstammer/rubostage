# rubostage

Wunschsong rein, Play-Along raus. Robin steht auf der Straße, jemand wünscht
sich einen Song, die App macht daraus sofort eine Begleitung in Sonic Pi —
**Robin singt und spielt Gitarre selbst dazu.** Die App zeigt Form und Akkorde,
keine Original-Songtexte.

Entstanden als `stage/` im Band-Repo `mcblinded`, 2026-10-20 in ein eigenes
Repo gezogen (Historie mitgenommen). rubostage ist **bandunabhängig**: Was für
Blackminded/mcblinded spezifisch ist, gehört nach `mcblinded`, nicht hierher.
Die einzige Brücke ist der Song-Ordner (Einstellungen).

## Ablauf

Der **Song-Editor** ist das Zentrum: Ein Song ist Gerüst (Tonart, Tempo,
Teile, Akkorde, Ablauf) plus optional Arrangement. Das Gerüst kommt entweder
von der KI (Wunsch, `origin: "wish"`) oder aus dem leeren Editor
(`origin: "manual"`, `/songs/new`). Startseite = Repertoire.

1. Wunsch → `claude -p` → `SongSheet` (Tonart, Tempo, Form, Akkorde) → `Groove`
   spielt sofort in Sonic Pi.
2. `ArrangeSongJob` holt ein JSON-Arrangement (Klänge aus fester Liste,
   16-Step-Patterns, Energie 1–3 je Teil, Drum-Groove, Gitarrenspielweise) und
   tauscht im Laufen nur die Stimmen; der `:conductor`-Loop behält die Position.
   Beim Wunsch automatisch, sonst per „Arrangieren lassen“ / „Neu arrangieren“
   mit optionalem Wunschtext. Scheitert ein neues, bleibt das alte.
3. Sonic Pi meldet jeden Akkord per OSC an UDP 4570 (`STAGE_OSC_PORT`),
   `StepListener` schiebt es per Turbo Stream ins Lead-Sheet.
4. Befehle (Wiederholen/Weiter/Springen/Ende) greifen an Teilgrenzen,
   Tasten P/S/R/N/E/1–9. **Endlos** (Taste L) ist ein rastender Schalter:
   `set :stage_loop` im Sonic-Pi-Zustand, in der App `Player.looping`; jeder
   Start schickt ihn mit. „Schluss“ beendet auch eine Schleife.
5. Songs sind editierbar (`SongEditor`), Riffs als ASCII-Tab (`Tab`, `RiffTrack`).
   **Songtext** (`songs.lyrics`) wird im Editor hineinkopiert und links auf der
   Songseite gezeigt; bleibt bewusst in der App (nicht im Song-Ordner, nicht
   bei der KI). Riffs:
   pro Teil per Häkchen Gitarre (6 Saiten) und/oder Bass (4 Saiten, = tiefste
   vier Gitarrensaiten −12, folgt der Stimmung). Ein Bass-Riff lässt die
   Basslinie in seinem Teil pausieren (`unless bass_riffs[form[pos]]`).
   Häkchen setzen füllt ein leeres Tab-Feld mit Saiten + leerem Takt (`reveal`).
8. **WAV-Export** (`RecordSongJob`): spielt den Song einmal ohne Schleife in
   Echtzeit durch und schneidet mit (Sonic Pi kann nicht schneller rendern),
   Dauer = Einzähler + Form + 4 s Ausklang. Liegt unter
   `storage/recordings/song-<id>.wav`, Download auf der Songseite.
   Ein leerer Takt (`[]` im Sheet, `%` auf dem Chart) hält den Akkord davor;
   alles, was Akkorde zählt, geht über `Section#steps(sheet.beats)`.
   **Takt** pro Song (`sheet["beats"]`, 4 oder 2): bestimmt nur die Akkorddauer;
   die Rhythmusmuster laufen weiter in 16er-Zyklen (`slot % 16`). Echtes 3/4
   bräuchte 12er-Muster — bewusst noch nicht gebaut.
6. **Code eingefroren:** `songs.code` wird gespielt und nur bei Änderungen
   neu gebaut (`Song#rebuild_code!`: Speichern, Arrangieren, „Code neu bauen“).
7. Jeder Code-Bau legt den Song in den **Song-Ordner** (`Setting.songs_root`,
   Einstellungen; Fallback `SONGS_ROOT`, dann `exports/`): `SongExport` schreibt
   `<ordner>/<song.folder>/live.rb` + `NOTES.md`. Ordnername bleibt ab dem
   ersten Export stabil. Nur Dateien mit Export-Markierung in Zeile 1 werden
   überschrieben, handgeschriebene nie. Git fasst die App nicht an. Löschen
   eines Songs nimmt seine markierten Dateien mit.

Oben sitzt die **Kontrollleiste** (`ControlPanel`, `controls/_panel`): Lämpchen
wie an einem Amp für Sonic Pi (aus / blinkt beim Hochfahren / an, mit
Start-Knopf), Song (letzte Takt-Meldung jünger als 3 s) und KI (Job läuft).
Ein Turbo-Frame, der sich per `poll`-Controller alle 2 s neu holt.

Darunter, sobald ein Song gestartet wurde, die **Transportleiste** als eigener
Streifen (`.transport-bar`, Pedalboard-schwarz, Frame `transport`): Spielen,
Stopp, Nochmal, Weiter, Schluss, Endlos für `NowPlaying.started_song_id` —
bleibt nach Stopp stehen, auf jeder Seite. Knöpfe antworten im Frame; Spielen/
Stopp leiten bei `Turbo-Frame: transport` auf `transport_path` um, denn Frame-
Requests bekommen kein Layout und die Leiste wäre sonst leer.

Unter den Leisten **immer drei Bereiche** (`layouts/application`): links
`_sidebar_left` (Reiter Songs = Repertoire, Text = Songtext), Mitte die Seite,
rechts `_sidebar_right` mit dem **Claude-Chat** (`SongChat`, `SongChatJob`,
`song_messages`). Beide Seiten fahren ein (Schiene mit Griff, `sidebars`-
Controller); Zustand und Reiter liegen in Cookies (`sidebar_left`,
`sidebar_right`, `sidebar_tab`), damit der Server gleich richtig zeichnet.
Worum es geht, sagt `sidebar_song`: der Song der Seite, sonst der zuletzt
gestartete. Das Chat-Formular ist `data-turbo-permanent` mit Song-Id in der
`id` und wird per JS geleert, nicht per Stream ersetzt.

**Claude ändert Songs direkt** (Chat rechts). Schichten, damit der Wechsel auf
RubyLLM nur einen Adapter kostet:
- `SongTools::*` (`get_song`, `edit_sheet`, `edit_band`, `edit_riffs`,
  `rearrange`, `play`, `stop`) — reines Ruby (Name, Beschreibung, JSON-Schema,
  `call(song, args)`), kennt weder MCP noch RubyLLM. `edit_sheet`/`edit_riffs`
  gehen über `ThroughEditor` durch `SongEditor`, also dieselben Prüfungen wie
  im Editor. `rearrange` startet `ArrangeSongJob(summary:)`: Ergebnis kommt
  als Änderung mit Rückgängig, Fehlschlag als Chat-Nachricht. `play`/`stop`
  ändern nichts am Song und sind nicht rückgängig zu machen.
- `SongChange.record(song, summary) { … }` — Schnappschuss vorher, Code neu
  bauen, `LiveSwap` (gemeinsam mit dem Editor). `undo!` nimmt die Änderung
  und alle danach zurück. Assoziation heißt `changes_made` (`changes` ist AR).
- `SongChat` → `client.call(prompt, toolbox:)`. Heute
  `SongTools::ClaudeCliClient` (`claude -p --mcp-config … --strict-mcp-config
  --allowedTools mcp__rubostage__*`, Subscription). **Wechselstelle:** ein
  `RubyLlmClient`, der je Tool ein `RubyLLM::Tool` baut und `toolbox.run` ruft.
- **Streaming:** `client.call(prompt, toolbox:, on_tool:) { |text| … }` — Block
  für Textstücke, `on_tool` für Werkzeug-Namen (wie RubyLLMs Block und
  `on_tool_call`). `ClaudeCli` nutzt dafür `stream-json --include-partial-
  messages`; `ChatDraft` zeigt den wachsenden Entwurf (`draft_<job_id>`) und
  die `activity` des Werkzeugs. Die meiste Wartezeit ist Start + Werkzeuge,
  nicht Schreiben.
- MCP-Endpunkt `POST /songs/:id/mcp` (`McpController`, `SongTools::Mcp`,
  handgeschriebenes JSON-RPC) **muss in Puma laufen**: `NowPlaying` und der
  `async`-Cable-Adapter leben nur im Server-Prozess. Token in `tmp/mcp_token`
  (geteilt von Server, Jobs, Konsole), URL aus `PORT` bzw. `APP_URL`.

`examples/starlight/` ist die handgeschriebene Vorlage, nach der `Groove`
gebaut wurde (4-Takt-Sektionen, `get[:section]`, `:clock` zuletzt definieren).
Kam am 2026-10-20 aus mcblinded herüber, weil es ein Muse-Cover ist.

**Die KI-Anbindung über `claude -p` ist vorläufig** (`ClaudeCli`) — austauschbar
halten. **Offline-fähig bleiben:** alles schon Erzeugte spielt ohne Netz.

## Design

**Die Seite ist ein alter Röhren-Amp** (Robin: „soll an Oldschool-Amp erinnern",
nicht nach Literatur aussehen). Hell = **Blonde** (Creme-Tolex, ochsenblutrote
Bespannung, gebürstete Goldplatte), dunkel = **Blackface** (schwarzes Tolex,
silberne Bespannung, schwarze Platte); der Hell/Dunkel-Schalter ist ein
Kippschalter „Blonde / Black". Kontrollleiste = Frontplatte mit Typenschild
und roten Pilotlampen; „Jetzt"-Anzeige und Wunschfeld = Bespannung mit Keder
(`.grille`); Transport = Fußschalter (`.footswitch`, SVG-Symbole aus
`footswitch_cap`); sonst Chrom-Taster (`ring-button`, rot: `button-go`).

- **Schrift: DIN Condensed** (Titel, Akkorde) + **DIN Alternate** (Text) —
  Systemschriften, weil offline. Robin hat Futura, Gill Sans und Rockwell
  ausprobiert und A gewählt. Keine Webfonts.
- **Tonarten und Akkorde nie in Versalien** (`silk`, `uppercase`): aus „Gm"
  wird sonst „GM", Moll wird Dur.

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
