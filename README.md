# rubostage

Name a song, get a play-along. rubostage asks an AI for key, tempo, form and
chords, starts a groove in Sonic Pi right away, then swaps in a full
arrangement while it plays. The lead sheet follows the music: current chord
big, next one small, current section marked.

Built for busking: someone calls out a song, the app plays the band, you sing
and play guitar on top.

## Requirements

- Ruby (see `.ruby-version`), SQLite
- [Sonic Pi](https://sonic-pi.net) 5 — the app must be running, it brings the server
- `claude` CLI, logged in (used via `claude -p`, no API key)

## Running

```bash
bundle install
bin/rails db:prepare
tail -f /dev/null | PORT=4567 bin/dev
```

Open http://localhost:4567. `tail -f /dev/null` keeps stdin open; without it
`tailwindcss:watch` exits and foreman takes everything down with it.

## Exporting songs

"⤓ Ins Repo" writes a song as `<songs>/<song>/live.rb` plus `NOTES.md`. The
`live.rb` plays without the app. Point `SONGS_ROOT` at a band's songs folder:

```bash
SONGS_ROOT=../mcblinded/songs PORT=4567 bin/dev
```

Without it, songs land in `exports/` (gitignored). Files without the export
mark in their first line count as hand-written and are never overwritten.

## Playing without the app

`bin/play` sends a file straight to Sonic Pi, using the same client as the app:

```bash
bin/play examples/starlight/live.rb
bin/play -e 'set :section, :verse'
bin/play --stop
bin/play --record examples/starlight/live.rb -o take.wav -t 30
```

`examples/starlight/` is the hand-written play-along the generated grooves
are modelled on.

## Tests

```bash
bundle exec rspec
bundle exec standardrb
```
