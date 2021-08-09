require "set"
require "chip8/byte_array"

module Chip8
  class CPU
    FONT = "\xF0\x90\x90\x90\xF0" \
    "\x20\x60\x20\x20\x70" \
    "\xF0\x10\xF0\x80\xF0" \
    "\xF0\x10\xF0\x10\xF0" \
    "\x90\x90\xF0\x10\x10" \
    "\xF0\x80\xF0\x10\xF0" \
    "\xF0\x80\xF0\x90\xF0" \
    "\xF0\x10\x20\x40\x40" \
    "\xF0\x90\xF0\x90\xF0" \
    "\xF0\x90\xF0\x10\xF0" \
    "\xF0\x90\xF0\x90\x90" \
    "\xE0\x90\xE0\x90\xE0" \
    "\xF0\x80\x80\x80\xF0" \
    "\xE0\x90\x90\x90\xE0" \
    "\xF0\x80\xF0\x80\xF0" \
    "\xF0\x80\xF0\x80\x80"
    MEMORY_START = 0x200

    Error = Class.new(StandardError)

    attr_reader :program_counter, :stack_pointer, :i_register, :delay_timer, :sound_timer

    def memory; @memory.dup.freeze; end
    def registers; @registers.dup.freeze; end
    def stack; @stack.dup.freeze; end
    def frame_buffer; @frame_buffer.dup.freeze; end
    def pressed_keys; @pressed_keys.dup.freeze; end

    def initialize(**kwargs)
      reset(**kwargs)
    end

    def reset(
      memory: ByteArray.new(4096),
      program_counter: MEMORY_START,
      frame_buffer: Array.new(SCREEN_WIDTH * SCREEN_HEIGHT, 0),
      stack: Array.new,
      registers: Array.new(16, 0),
      i_register: 0x000,
      delay_timer: 0x00,
      sound_timer: 0x00,
      pressed_keys: Set.new,
      beep: -> { }
    )
      @memory = memory
      @program_counter = program_counter
      @frame_buffer = frame_buffer
      @stack = stack
      @registers = registers
      @i_register = i_register
      @delay_timer = delay_timer
      @sound_timer = sound_timer
      @pressed_keys = pressed_keys
      @beep = beep

      load(FONT, start_addr: 0x000)
    end

    def load(bytes, start_addr: MEMORY_START)
      bytes.each_byte.with_index do |byte, index|
        @memory[start_addr + index] = byte
      end
    end

    def execute_instruction
      instruction, *operands = decode_opcode(fetch_opcode)
      send(instruction, *operands)
    end

    def timer_interrupt
      @delay_timer -= 1 unless @delay_timer.zero?
      @sound_timer -= 1 unless @sound_timer.zero?
    end

    def key_pressed(key)
      @pressed_keys.add(key)
    end

    def key_released(key)
      @pressed_keys.delete(key)
    end

    private

    def fetch_opcode
      @memory[@program_counter] << 8 | @memory[@program_counter + 1]
    end

    def decode_opcode(opcode)
      case opcode & 0xF000
      when 0x0000
        case opcode & 0x00FF
        when 0x00E0 then [:cls]
        when 0x00EE then [:ret]
        else raise Error, "Unrecognized opcode: 0x#{opcode.to_s(16).rjust(4, "0")}"
        end
      when 0x1000 then [:jp_addr, opcode & 0x0FFF]
      when 0x2000 then [:call_addr, opcode & 0x0FFF]
      when 0x3000 then [:se_vx_byte, (opcode & 0x0F00) >> 8, opcode & 0x00FF]
      when 0x4000 then [:sne_vx_byte, (opcode & 0x0F00) >> 8, opcode & 0x00FF]
      when 0x5000 then [:se_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
      when 0x6000 then [:ld_vx_byte, (opcode & 0x0F00) >> 8, opcode & 0x00FF]
      when 0x7000 then [:add_vx_byte, (opcode & 0x0F00) >> 8, opcode & 0x00FF]
      when 0x8000
        case opcode & 0x000F
        when 0x0000 then [:ld_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x0001 then [:or_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x0002 then [:and_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x0003 then [:xor_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x0004 then [:add_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x0005 then [:sub_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x0006 then [:shr_vx_vy, (opcode & 0x0F00) >> 8]
        when 0x0007 then [:subn_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
        when 0x000e then [:shl_vx_vy, (opcode & 0x0F00) >> 8]
        else raise Error, "Unrecognized opcode: #{opcode.to_s(16)}"
        end
      when 0x9000 then [:sne_vx_vy, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4]
      when 0xA000 then [:ld_i_addr, opcode & 0x0FFF]
      when 0xB000 then [:jp_v0_addr, opcode & 0x0FFF]
      when 0xC000 then [:rnd_vx_byte, (opcode & 0x0F00) >> 8, opcode & 0x00FF]
      when 0xD000 then [:drw_vx_vy_nibble, (opcode & 0x0F00) >> 8, (opcode & 0x00F0) >> 4, opcode & 0x000F]
      when 0xE000
        case opcode & 0x00FF
        when 0x009E then [:skp_vx, (opcode & 0x0F00) >> 8]
        when 0x00A1 then [:sknp_vx, (opcode & 0x0F00) >> 8]
        else raise Error, "Unrecognized opcode: #{opcode.to_s(16)}"
        end
      when 0xF000
        case opcode & 0x00FF
        when 0x0007 then [:ld_vx_dt, (opcode & 0x0F00) >> 8]
        when 0x000A then [:ld_vx_k, (opcode & 0x0F00) >> 8]
        when 0x0015 then [:ld_dt_vx, (opcode & 0x0F00) >> 8]
        when 0x0018 then [:ld_st_vx, (opcode & 0x0F00) >> 8]
        when 0x001E then [:add_i_vx, (opcode & 0x0F00) >> 8]
        when 0x0029 then [:ld_f_vx, (opcode & 0x0F00) >> 8]
        when 0x0033 then [:ld_b_vx, (opcode & 0x0F00) >> 8]
        when 0x0055 then [:ld_i_vx, (opcode & 0x0F00) >> 8]
        when 0x0065 then [:ld_vx_i, (opcode & 0x0F00) >> 8]
        else raise Error, "Unrecognized opcode: #{opcode.to_s(16)}"
        end
      else raise Error, "Unrecognized opcode: #{opcode.to_s(16)}"
      end
    end

    def next_instruction
      @program_counter += 2
    end

    def skip_instruction
      2.times { next_instruction }
    end

    def cls
      @frame_buffer.map! { 0 }
      next_instruction
    end

    def ret
      @program_counter = @stack.pop
    end

    def jp_addr(addr)
      @program_counter = addr
    end

    def call_addr(addr)
      @stack.push(next_instruction)
      @program_counter = addr
    end

    def se_vx_byte(vx, byte)
      if @registers[vx] == byte
        skip_instruction
      else
        next_instruction
      end
    end

    def sne_vx_byte(vx, byte)
      if @registers[vx] != byte
        skip_instruction
      else
        next_instruction
      end
    end

    def se_vx_vy(vx, vy)
      if @registers[vx] == @registers[vy]
        skip_instruction
      else
        next_instruction
      end
    end

    def ld_vx_byte(vx, byte)
      @registers[vx] = byte
      next_instruction
    end

    def add_vx_byte(vx, byte)
      @registers[vx] = (@registers[vx] + byte) & 0xFF
      next_instruction
    end

    def ld_vx_vy(vx, vy)
      @registers[vx] = @registers[vy]
      next_instruction
    end

    def or_vx_vy(vx, vy)
      @registers[vx] |= @registers[vy]
      next_instruction
    end

    def and_vx_vy(vx, vy)
      @registers[vx] &= @registers[vy]
      next_instruction
    end

    def xor_vx_vy(vx, vy)
      @registers[vx] ^= @registers[vy]
      next_instruction
    end

    def add_vx_vy(vx, vy)
      sum = @registers[vx] + @registers[vy]
      @registers[0xF] = sum > 0xFF ? 1 : 0
      @registers[vx] = sum & 0xFF
      next_instruction
    end

    def sub_vx_vy(vx, vy)
      difference = @registers[vx] - @registers[vy]
      @registers[0xF] = @registers[vx] > @registers[vy] ? 1 : 0
      @registers[vx] = difference & 0xFF
      next_instruction
    end

    def shr_vx_vy(vx)
      @registers[0xF] = @registers[vx] & 1
      @registers[vx] >>= 1
      next_instruction
    end

    def subn_vx_vy(vx, vy)
      difference = @registers[vy] - @registers[vx]
      @registers[0xF] = @registers[vy] > @registers[vx] ? 1 : 0
      @registers[vx] = difference & 0xFF
      next_instruction
    end

    def shl_vx_vy(vx)
      @registers[0xF] = (@registers[vx] >> 7) & 1
      @registers[vx] = (@registers[vx] << 1) & 0xFF
      next_instruction
    end

    def sne_vx_vy(vx, vy)
      if @registers[vx] != @registers[vy]
        skip_instruction
      else
        next_instruction
      end
    end

    def ld_i_addr(addr)
      @i_register = addr
      next_instruction
    end

    def jp_v0_addr(addr)
      @program_counter = @registers[0] + addr
    end

    def rnd_vx_byte(vx, byte)
      @registers[vx] = rand(0xFF) & byte
      next_instruction
    end

    def drw_vx_vy_nibble(vx, vy, nibble)
      @registers[0xF] = 0
      nibble.times do |row_index|
        byte = @memory[@i_register + row_index]
        y = (@registers[vy] + row_index) % SCREEN_HEIGHT
        8.times do |column_index|
          x = (@registers[vx] + column_index) % SCREEN_WIDTH
          bit = (byte >> (8 - 1 - column_index)) & 1
          addr = y * SCREEN_WIDTH + x
          @registers[0xF] |= @frame_buffer[addr] & bit
          @frame_buffer[addr] ^= bit
        end
      end
      next_instruction
    end

    def skp_vx(vx)
      if @pressed_keys.include?(@registers[vx])
        skip_instruction
      else
        next_instruction
      end
    end

    def sknp_vx(vx)
      if @pressed_keys.include?(@registers[vx])
        next_instruction
      else
        skip_instruction
      end
    end

    def ld_vx_dt(vx)
      @registers[vx] = @delay_timer
      next_instruction
    end

    def ld_vx_k(vx)
      return if @pressed_keys.empty?
      @registers[vx] = @pressed_keys.first
      next_instruction
    end

    def ld_dt_vx(vx)
      @delay_timer = @registers[vx]
      next_instruction
    end

    def ld_st_vx(vx)
      @beep.call
      next_instruction
    end

    def add_i_vx(vx)
      @i_register += @registers[vx]
      next_instruction
    end

    def ld_f_vx(vx)
      @i_register = @registers[vx] * 5
      next_instruction
    end

    def ld_b_vx(vx)
      ones, tens, hundreds = @registers[vx].digits
      @memory[@i_register] = hundreds || 0
      @memory[@i_register + 1] = tens || 0
      @memory[@i_register + 2] = ones
      next_instruction
    end

    def ld_i_vx(vx)
      (0..vx).each do |v|
        @memory[@i_register + v] = @registers[v]
      end
      next_instruction
    end

    def ld_vx_i(vx)
      (0..vx).each do |v|
        @registers[v] = @memory[@i_register + v]
      end
      next_instruction
    end
  end
end
