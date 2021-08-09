module Chip8
  class ByteArray < String
    def initialize(size, default_vaule = 0)
      super [default_vaule].pack("C*") * size
    end

    alias :[] :getbyte
    alias :[]= :setbyte
  end
end
