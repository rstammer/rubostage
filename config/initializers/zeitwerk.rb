# lib/osc.rb defines OSC, not Osc.
Rails.autoloaders.each { |loader| loader.inflector.inflect("osc" => "OSC") }
