# frozen_string_literal: true

module OSC
  class Malformed < StandardError; end

  module_function

  # Everything is built as binary. Packed integers contain bytes above 127, and
  # song files may contain non-ASCII characters — mixing those with a UTF-8
  # string raises Encoding::CompatibilityError.
  def pad(str)
    terminated = str.b + "\0".b
    terminated + ("\0".b * ((4 - terminated.bytesize % 4) % 4))
  end

  # Builds an OSC message. Only the two argument types Sonic Pi needs here.
  def message(path, *args)
    tags = +","
    body = +"".b

    args.each do |arg|
      case arg
      when Integer
        tags << "i"
        body << [arg].pack("N")
      when String
        tags << "s"
        body << pad(arg)
      else
        raise ArgumentError, "unsupported OSC argument: #{arg.class}"
      end
    end

    pad(path) + pad(tags) + body
  end

  # Reads an OSC message back into [address, args]. Knows the types Sonic Pi's
  # `osc` sends: int32, float32 and string.
  def parse(data)
    data = data.b
    address, offset = read_string(data, 0)
    tags, offset = read_string(data, offset)
    raise Malformed, "no type tags" unless address.start_with?("/") && tags.start_with?(",")

    args = tags[1..].each_char.map do |tag|
      case tag
      when "i"
        value = data.byteslice(offset, 4).unpack1("l>")
        offset += 4
      when "f"
        value = data.byteslice(offset, 4).unpack1("g")
        offset += 4
      when "s"
        value, offset = read_string(data, offset)
      else
        raise Malformed, "unsupported OSC type: #{tag}"
      end
      raise Malformed, "message ends early" if value.nil?

      value
    end
    [address, args]
  end

  def read_string(data, offset)
    finish = data.index("\0".b, offset) or raise Malformed, "unterminated string"
    text = data.byteslice(offset, finish - offset).force_encoding(Encoding::UTF_8)
    [text, finish + 1 + ((4 - (finish + 1) % 4) % 4)]
  end
end
