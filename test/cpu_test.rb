require "test_helper"

class CPUTest < Minitest::Test
  def test_cls
    frame_buffer = Array.new(Chip8::SCREEN_WIDTH * Chip8::SCREEN_HEIGHT, 1)
    cpu = Chip8::CPU.new(frame_buffer: frame_buffer)
    cpu.load("\x00\xE0")

    cpu.execute_instruction

    assert cpu.frame_buffer.all?(&:zero?)
    assert_equal 0x202, cpu.program_counter
  end

  def test_ret
    stack = [0xFFF]
    cpu = Chip8::CPU.new(stack: stack)
    cpu.load("\x00\xEE")

    cpu.execute_instruction

    assert_equal 0xFFF, cpu.program_counter
    assert_equal 0, cpu.stack.size
  end

  def test_jp_addr
    cpu = Chip8::CPU.new
    cpu.load("\x12\x22")

    cpu.execute_instruction

    assert_equal 0x222, cpu.program_counter
  end

  def test_call_addr
    cpu = Chip8::CPU.new
    cpu.load("\x20\x95")

    cpu.execute_instruction

    assert_equal 0x95, cpu.program_counter
    assert_equal [0x202], cpu.stack
  end

  def test_se_vx_byte_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x3A\x07")

    cpu.execute_instruction

    assert_equal 0x204, cpu.program_counter
  end

  def test_se_vx_byte_not_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x3A\x06")

    cpu.execute_instruction

    assert_equal 0x202, cpu.program_counter
  end

  def test_sne_vx_byte_not_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x4A\x06")

    cpu.execute_instruction

    assert_equal 0x204, cpu.program_counter
  end

  def test_sne_vx_byte_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x4A\x07")

    cpu.execute_instruction

    assert_equal 0x202, cpu.program_counter
  end

  def test_se_vx_vy_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    registers[0xB] = 7
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x5A\xB0")

    cpu.execute_instruction

    assert_equal 0x204, cpu.program_counter
  end

  def test_se_vx_vy_not_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    registers[0xB] = 6
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x5A\xb0")

    cpu.execute_instruction

    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_vx_byte
    cpu = Chip8::CPU.new
    cpu.load("\x6A\xFF")

    cpu.execute_instruction

    assert_equal 0xFF, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_add_vx_byte_without_carry
    registers = Array.new(16, 0)
    registers[0xA] = 3
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x7A\x04")

    cpu.execute_instruction

    assert_equal 7, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_add_vx_byte_with_carry
    registers = Array.new(16, 0)
    registers[0xA] = 3
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x7A\xFF")

    cpu.execute_instruction

    assert_equal 2, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_vx_vy
    registers = Array.new(16, 0)
    registers[0xA] = 7
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8B\xA0")

    cpu.execute_instruction

    assert_equal 0x07, cpu.registers[0xB]
    assert_equal 0x202, cpu.program_counter
  end

  def test_or_vx_vy
    registers = Array.new(16, 0)
    registers[0xA] = 0b0000_1010
    registers[0xB] = 0b0000_1100
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB1")

    cpu.execute_instruction

    assert_equal 0b0000_1110, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_and_vx_vy
    registers = Array.new(16, 0)
    registers[0xA] = 0b0000_1010
    registers[0xB] = 0b0000_1100
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB2")

    cpu.execute_instruction

    assert_equal 0b0000_1000, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_xor_vx_vy
    registers = Array.new(16, 0)
    registers[0xA] = 0b0000_1010
    registers[0xB] = 0b0000_1100
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB3")

    cpu.execute_instruction

    assert_equal 0b0000_0110, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_add_vx_vy_without_carry
    registers = Array.new(16, 0)
    registers[0xA] = 3
    registers[0xB] = 4
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB4")

    cpu.execute_instruction

    assert_equal 7, cpu.registers[0xA]
    assert_equal 0, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_add_vx_vy_with_carry
    registers = Array.new(16, 0)
    registers[0xA] = 0xFF
    registers[0xB] = 1
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB4")

    cpu.execute_instruction

    assert_equal 0, cpu.registers[0xA]
    assert_equal 1, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_sub_vx_vy_without_carry
    registers = Array.new(16, 0)
    registers[0xA] = 3
    registers[0xB] = 4
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB5")

    cpu.execute_instruction

    assert_equal 255, cpu.registers[0xA]
    assert_equal 0, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_sub_vx_vy_with_carry
    registers = Array.new(16, 0)
    registers[0xA] = 4
    registers[0xB] = 3
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB5")

    cpu.execute_instruction

    assert_equal 1, cpu.registers[0xA]
    assert_equal 1, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_shr_vx_vy_without_carry
    registers = Array.new(16, 0)
    registers[0xA] = 0b10
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB6")

    cpu.execute_instruction

    assert_equal 1, cpu.registers[0xA]
    assert_equal 0, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_shr_vx_vy_with_carry
    registers = Array.new(16, 0)
    registers[0xA] = 0b11
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB6")

    cpu.execute_instruction

    assert_equal 1, cpu.registers[0xA]
    assert_equal 1, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_subn_vx_vy_without_carry
    registers = Array.new(16, 0)
    registers[0xA] = 4
    registers[0xB] = 3
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB7")

    cpu.execute_instruction

    assert_equal 255, cpu.registers[0xA]
    assert_equal 0, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_subn_vx_vy_with_carry
    registers = Array.new(16, 0)
    registers[0xA] = 3
    registers[0xB] = 4
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xB7")

    cpu.execute_instruction

    assert_equal 1, cpu.registers[0xA]
    assert_equal 1, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_shl_vx_vy_without_carry
    registers = Array.new(16, 0)
    registers[0xA] = 0b0100_0000
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xBE")

    cpu.execute_instruction

    assert_equal 0b1000_0000, cpu.registers[0xA]
    assert_equal 0, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_shl_vx_vy_with_carry
    registers = Array.new(16, 0)
    registers[0xA] = 0b1000_0000
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x8A\xBE")

    cpu.execute_instruction

    assert_equal 0, cpu.registers[0xA]
    assert_equal 1, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_sne_vx_vy_not_equal
    registers = Array.new(16, 0)
    registers[0xA] = 7
    registers[0xB] = 3
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x9A\xB0")

    cpu.execute_instruction

    assert_equal 0x204, cpu.program_counter
  end

  def test_sne_vx_vy_equal
    registers = Array.new(16, 0)
    registers[0xA] = 3
    registers[0xB] = 3
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\x9A\xB0")

    cpu.execute_instruction

    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_i_addr
    cpu = Chip8::CPU.new
    cpu.load("\xAF\xAB")

    cpu.execute_instruction

    assert_equal 0xFAB, cpu.i_register
    assert_equal 0x202, cpu.program_counter
  end

  def test_jp_v0_addr
    registers = Array.new(16, 0)
    registers[0] = 40
    cpu = Chip8::CPU.new(registers: registers)
    cpu.load("\xB0\x02")

    cpu.execute_instruction

    assert_equal 42, cpu.program_counter
  end

  def test_rnd_vx_byte
    cpu = Chip8::CPU.new
    cpu.load("\xCA\x0F")

    cpu.execute_instruction

    assert_equal 0, cpu.registers[0xA] & 0xF0
    assert_equal 0x202, cpu.program_counter
  end

  def test_drw_vx_vy_nibble
    registers = Array.new(16, 0)
    registers[0xA] = 1
    registers[0xB] = 1
    cpu = Chip8::CPU.new(registers: registers, i_register: 75)
    cpu.load("\xDA\xB5")

    cpu.execute_instruction

    [
      [0, 0, 0, 0, 0, 0],
      [0, 1, 1, 1, 1, 0],
      [0, 1, 0, 0, 0, 0],
      [0, 1, 1, 1, 1, 0],
      [0, 1, 0, 0, 0, 0],
      [0, 1, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
    ].each_with_index do |expected, row|
      start_addr = row * Chip8::SCREEN_WIDTH
      assert_equal expected, cpu.frame_buffer[start_addr...start_addr + expected.size]
    end
    assert_equal 0, cpu.registers[0xF]
    assert_equal 0x202, cpu.program_counter
  end

  def test_skp_vx_key_pressed
    cpu = Chip8::CPU.new(registers: [0xA])
    cpu.load("\xE0\x9E")

    cpu.key_pressed(0xA)
    cpu.execute_instruction

    assert_equal 0x204, cpu.program_counter
  end

  def test_skp_vx_kye_not_pressed
    cpu = Chip8::CPU.new(registers: [0xA])
    cpu.load("\xE0\x9E")

    cpu.execute_instruction

    assert_equal 0x202, cpu.program_counter
  end

  def test_sknp_vx_key_pressed
    cpu = Chip8::CPU.new(registers: [0xA])
    cpu.load("\xE0\xA1")

    cpu.key_pressed(0xA)
    cpu.execute_instruction

    assert_equal 0x202, cpu.program_counter
  end

  def test_sknp_vx_kye_not_pressed
    cpu = Chip8::CPU.new(registers: [0xA])
    cpu.load("\xE0\xA1")

    cpu.execute_instruction

    assert_equal 0x204, cpu.program_counter
  end

  def test_drw_vx_vy_nibble_vf
    cpu = Chip8::CPU.new
    cpu.load("\xDA\xB5\xDA\xB5")

    cpu.execute_instruction
    cpu.execute_instruction

    assert_equal 1, cpu.registers[0xF]
  end

  def test_ld_vx_dt
    cpu = Chip8::CPU.new(delay_timer: 3)
    cpu.load("\xFA\x07")

    cpu.execute_instruction

    assert_equal 3, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_vx_k_key_pressed
    cpu = Chip8::CPU.new
    cpu.load("\xFA\x0A")

    cpu.key_pressed(0xB)
    cpu.execute_instruction

    assert_equal 0xB, cpu.registers[0xA]
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_vx_k_no_key_pressed
    cpu = Chip8::CPU.new
    cpu.load("\xFA\x0A")

    cpu.execute_instruction

    assert_equal 0, cpu.registers[0xA]
    assert_equal 0x200, cpu.program_counter
  end

  def test_ld_dt_vx
    cpu = Chip8::CPU.new(registers: [500])
    cpu.load("\xF0\x15")

    cpu.execute_instruction

    assert_equal 500, cpu.delay_timer
    assert_equal 0x202, cpu.program_counter
  end

  def test_add_i_vx
    cpu = Chip8::CPU.new(i_register: 1000, registers: [500])
    cpu.load("\xF0\x1E")

    cpu.execute_instruction

    assert_equal 1500, cpu.i_register
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_f_vx
    cpu = Chip8::CPU.new(registers: [0xF])
    cpu.load("\xF0\x29")

    cpu.execute_instruction

    assert_equal 75, cpu.i_register
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_b_vx
    cpu = Chip8::CPU.new(registers: [213], i_register: 0x300)
    cpu.load("\xF0\x33")

    cpu.execute_instruction

    assert_equal 2, cpu.memory[0x300]
    assert_equal 1, cpu.memory[0x301]
    assert_equal 3, cpu.memory[0x302]
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_i_vx
    cpu = Chip8::CPU.new(registers: [1, 2, 3, 4, 5, 4], i_register: 0x300)
    cpu.load("\xF5\x55")

    cpu.execute_instruction

    assert_equal 1, cpu.memory[0x300]
    assert_equal 2, cpu.memory[0x301]
    assert_equal 3, cpu.memory[0x302]
    assert_equal 4, cpu.memory[0x303]
    assert_equal 5, cpu.memory[0x304]
    assert_equal 0x202, cpu.program_counter
  end

  def test_ld_vx_i
    cpu = Chip8::CPU.new(registers: [0, 0, 0, 0, 0, 4], i_register: 0x300)
    cpu.load("\x01\x02\x03\x04\x05", start_addr: 0x300)
    cpu.load("\xF5\x65")

    cpu.execute_instruction

    assert_equal 1, cpu.registers[0x0]
    assert_equal 2, cpu.registers[0x1]
    assert_equal 3, cpu.registers[0x2]
    assert_equal 4, cpu.registers[0x3]
    assert_equal 5, cpu.registers[0x4]
    assert_equal 0x202, cpu.program_counter
  end

  def test_key_pressed
    cpu = Chip8::CPU.new

    cpu.key_pressed 0xA

    assert cpu.pressed_keys.include?(0xA)
  end

  def test_key_released
    cpu = Chip8::CPU.new(pressed_keys: Set[0xA])

    cpu.key_released 0xA

    assert cpu.pressed_keys.empty?
  end

  def test_timer_interrupt_delay_timer_is_0
    cpu = Chip8::CPU.new(delay_timer: 0)

    cpu.timer_interrupt

    assert_equal 0, cpu.delay_timer
  end

  def test_timer_interrupt_delay_timer_greater_0
    cpu = Chip8::CPU.new(delay_timer: 3)

    cpu.timer_interrupt

    assert_equal 2, cpu.delay_timer
  end
end
