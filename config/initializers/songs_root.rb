# Where "Ins Repo" writes songs. Point SONGS_ROOT at a band's songs folder,
# e.g. ../mcblinded/songs; without it, songs land in exports/ inside the app.
Rails.application.config.x.songs_root = Pathname(ENV.fetch("SONGS_ROOT") { Rails.root.join("exports") })
