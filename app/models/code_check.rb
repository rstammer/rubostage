# Catches what would make Sonic Pi throw a whole run away before it is sent:
# syntax errors, and built-in fn names used as variables (Sonic Pi refuses the
# buffer with a PreParseError, see CLAUDE.md).
module CodeCheck
  BUILT_INS = %w[
    beat choose chord cue dice knit line look note play range rand ring sample
    scale sleep spread stop sync tick
  ].freeze

  ASSIGNMENT = /(?:^|[\s;(])(#{BUILT_INS.join("|")})\s*=(?!=)/
  BLOCK_PARAMS = /\|([^|]*)\|/

  module_function

  def problems(code)
    found = Prism.parse(code).errors.map { |e| "syntax: #{e.message} (line #{e.location.start_line})" }
    code.scan(ASSIGNMENT).flatten.uniq.each { |name| found << "#{name} is a built-in fn, not a variable name" }
    code.scan(BLOCK_PARAMS).flatten.flat_map { |params| params.scan(/\w+/) }.uniq.each do |name|
      found << "#{name} is a built-in fn, not a block parameter" if BUILT_INS.include?(name)
    end
    found
  end
end
