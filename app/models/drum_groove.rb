# Drum grooves by style: the genre basics a drummer reaches for, written as
# [step, velocity] over the sixteen sixteenths of a bar. Velocities carry the
# feel — accents on the beat, ghost notes between — which plain on/off
# patterns cannot.
module DrumGroove
  EIGHTHS = (0..14).step(2).to_a.freeze

  def self.hats(accented: [0, 4, 8, 12], steps: EIGHTHS, loud: 0.8, soft: 0.5)
    steps.map { |s| [s, accented.include?(s) ? loud : soft] }
  end

  GROOVES = {
    rock: {
      kick: [[0, 1.0], [8, 0.95], [10, 0.7]],
      snare: [[4, 1.0], [12, 1.0]],
      hat: hats,
      open_hat: []
    },
    halftime: {
      kick: [[0, 1.0], [10, 0.75], [14, 0.6]],
      snare: [[8, 1.0]],
      hat: hats(accented: [0, 8]),
      open_hat: []
    },
    shuffle: {
      kick: [[0, 1.0], [6, 0.6], [8, 0.9]],
      snare: [[4, 1.0], [12, 1.0], [14, 0.3]],
      hat: hats(loud: 0.75, soft: 0.45),
      open_hat: []
    },
    funk: {
      kick: [[0, 1.0], [3, 0.6], [10, 0.85]],
      snare: [[4, 1.0], [7, 0.25], [9, 0.3], [12, 1.0], [15, 0.25]],
      hat: hats(accented: [0, 4, 8, 12], steps: (0..15).to_a, loud: 0.7, soft: 0.35),
      open_hat: [[14, 0.5]]
    },
    four_floor: {
      kick: [[0, 1.0], [4, 1.0], [8, 1.0], [12, 1.0]],
      snare: [[4, 0.8], [12, 0.8]],
      hat: [],
      open_hat: [[2, 0.6], [6, 0.6], [10, 0.6], [14, 0.6]]
    },
    punk: {
      kick: [[0, 1.0], [6, 0.8], [8, 1.0]],
      snare: [[4, 1.0], [12, 1.0]],
      hat: hats(loud: 0.9, soft: 0.8),
      open_hat: []
    },
    ballad: {
      kick: [[0, 0.8], [10, 0.5]],
      snare: [[12, 0.7]],
      hat: hats(loud: 0.45, soft: 0.3),
      open_hat: []
    }
  }.freeze

  NAMES = GROOVES.keys.freeze

  SWING = {shuffle: 0.3}.freeze

  module_function

  def fetch(name) = GROOVES.fetch(name)

  def default_swing(name) = SWING.fetch(name, 0)
end
