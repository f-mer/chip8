require "sdl2"

module Chip8
  class Peripheral
    COLOR_WHITE = [0xff, 0xff, 0xff].freeze
    COLOR_BLACK = [0x00, 0x00, 0x00].freeze

    def initialize(frame_buffer:, scale: 16, keydown:, keyup:)
      SDL2.init(SDL2::INIT_VIDEO | SDL2::INIT_EVENTS)
      @frame_buffer = frame_buffer
      @keydown = keydown
      @keyup = keyup
      @window = SDL2::Window.create("chip8", SDL2::Window::POS_CENTERED, SDL2::Window::POS_CENTERED, 64 * scale, 32 * scale, 0)
      @renderer = @window.create_renderer(-1, 0)
      @renderer.scale = [scale, scale]
    end

    def [](x, y)
      @frame_buffer[y * 64 + x]
    end

    def draw
      @renderer.draw_color = COLOR_WHITE
      @renderer.clear
      Chip8::SCREEN_HEIGHT.times do |y|
        Chip8::SCREEN_WIDTH.times do |x|
          @renderer.draw_color = self[x, y] == 0 ? COLOR_WHITE : COLOR_BLACK
          @renderer.draw_point(x, y)
        end
      end
      @renderer.present
    end

    def update
      while event = SDL2::Event.poll
        case event
        when SDL2::Event::KeyDown
          @keydown.call(SDL2::Key::Scan.name_of(event.scancode).hex)
          exit if event.scancode == SDL2::Key::Scan::ESCAPE
        when SDL2::Event::KeyUp
          @keyup.call(SDL2::Key::Scan.name_of(event.scancode).hex)
        end
      end
    end
  end
end
