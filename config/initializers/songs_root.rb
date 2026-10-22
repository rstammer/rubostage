# Where songs land until a folder is chosen in the settings. Point SONGS_ROOT
# at a songs folder, e.g. ../mcblinded/songs; without it, songs land in
# exports/ inside the app.
Rails.application.config.x.songs_root = Pathname(ENV.fetch("SONGS_ROOT") { Rails.root.join("exports") })
