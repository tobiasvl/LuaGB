describe("Audio", function()
  describe("Registers", function()
    setup(function()
      -- Create a mock audio module with stubbed out external modules
      Audio = require("gameboy/audio/init")
      Io = require("gameboy/io")
      Memory = require("gameboy/memory")
      Timers = require("gameboy/timers")
      bit32 = require("bit")
    end)
    before_each(function()
      local modules = {}
      modules.memory = Memory.new()
      modules.io = Io.new(modules)
      modules.timers = Timers.new(modules)
      audio = Audio.new(modules)
      audio:initialize()
      -- create a non-local io reference, to mock writes in tests
      io = modules.io
      ports = io.ports
    end)
    it("mock audio module can be created", function()
      assert.not_same(audio, nil)
    end)
    describe("Control Registers", function()
      it("Writes to NR50 should set the volume for left and right channels", function()
        io.write_logic[ports.NR50](0x77)
        assert.are_same(0x7, audio.master_volume_left)
        assert.are_same(0x7, audio.master_volume_right)
        io.write_logic[ports.NR50](0x52)
        assert.are_same(0x5, audio.master_volume_left)
        assert.are_same(0x2, audio.master_volume_right)
      end)
      it("Bit 0 of NR51 enables Tone1 on the right channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.tone1.master_enable_right)
        io.write_logic[ports.NR51](0x01)
        assert.truthy(audio.tone1.master_enable_right)
      end)
      it("Bit 1 of NR51 enables Tone2 on the right channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.tone2.master_enable_right)
        io.write_logic[ports.NR51](0x02)
        assert.truthy(audio.tone2.master_enable_right)
      end)
      it("Bit 2 of NR51 enables Wave3 on the right channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.wave3.master_enable_right)
        io.write_logic[ports.NR51](0x04)
        assert.truthy(audio.wave3.master_enable_right)
      end)
      it("Bit 3 of NR51 enables Noise4 on the right channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.noise4.master_enable_right)
        io.write_logic[ports.NR51](0x08)
        assert.truthy(audio.noise4.master_enable_right)
      end)
      it("Bit 4 of NR51 enables Tone1 on the left channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.tone1.master_enable_left)
        io.write_logic[ports.NR51](0x10)
        assert.truthy(audio.tone1.master_enable_left)
      end)
      it("Bit 5 of NR51 enables Tone2 on the left channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.tone2.master_enable_left)
        io.write_logic[ports.NR51](0x20)
        assert.truthy(audio.tone2.master_enable_left)
      end)
      it("Bit 6 of NR51 enables Wave3 on the left channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.wave3.master_enable_left)
        io.write_logic[ports.NR51](0x40)
        assert.truthy(audio.wave3.master_enable_left)
      end)
      it("Bit 7 of NR51 enables Noise4 on the left channel", function()
        io.write_logic[ports.NR51](0x00)
        assert.falsy(audio.noise4.master_enable_left)
        io.write_logic[ports.NR51](0x80)
        assert.truthy(audio.noise4.master_enable_left)
      end)
      it("Bit 0 of NR52 is clear when Tone1's length counter disables the channel", function()
        -- firstly, make sure the volume / sweep units are NOT disabling the channel
        audio.tone1.generator.channel_enabled = true
        io.write_logic[ports.NR12](0xF8)

        audio.tone1.length_counter.channel_enabled = false
        assert.are_same(0, bit32.band(0x01, io.read_logic[ports.NR52]()))
        audio.tone1.length_counter.channel_enabled = true
        assert.not_same(0, bit32.band(0x01, io.read_logic[ports.NR52]()))
      end)
      it("Bit 0 of NR52 is clear when Tone1's sweep unit disables the channel", function()
        -- firstly, make sure the volume / sweep units are NOT disabling the channel
        audio.tone1.generator.channel_enabled = true
        io.write_logic[ports.NR12](0xF8)

        audio.tone1.generator.channel_enabled = false
        assert.are_same(0, bit32.band(0x01, io.read_logic[ports.NR52]()))
        audio.tone1.generator.channel_enabled = true
        assert.not_same(0, bit32.band(0x01, io.read_logic[ports.NR52]()))
      end)
      it("Bit 1 of NR52 is clear when Tone2's length counter disables the channel", function()
        -- firstly, make sure the volume unit is NOT disabling the channel
        io.write_logic[ports.NR22](0xF8)

        audio.tone2.length_counter.channel_enabled = false
        assert.are_same(0, bit32.band(0x02, io.read_logic[ports.NR52]()))
        audio.tone2.length_counter.channel_enabled = true
        assert.not_same(0, bit32.band(0x02, io.read_logic[ports.NR52]()))
      end)
      it("Bit 2 of NR52 is clear when Wave3's length counter disables the channel", function()
        -- firstly, make sure the DAC is NOT disabling the channel
        io.write_logic[ports.NR30](0x80)

        audio.wave3.length_counter.channel_enabled = false
        assert.are_same(0, bit32.band(0x04, io.read_logic[ports.NR52]()))
        audio.wave3.length_counter.channel_enabled = true
        assert.not_same(0, bit32.band(0x04, io.read_logic[ports.NR52]()))
      end)
      it("Bit 2 of NR52 is off if Wave3 is disabled via NR30", function()
        -- length enabled would normally signal the channel as active:
        audio.wave3.length_counter.channel_enabled = true
        -- but if the whole channel is off, it suppresses the length flag:
        audio.wave3.sampler.channel_enabled = false
        assert.are_same(0, bit32.band(0x04, io.read_logic[ports.NR52]()))
      end)
      it("Bit 3 of NR52 is clear when Noise4's length counter disables the channel", function()
        -- firstly, make sure the volume unit is NOT disabling the channel
        io.write_logic[ports.NR42](0xF8)

        audio.noise4.length_counter.channel_enabled = false
        assert.are_same(0, bit32.band(0x08, io.read_logic[ports.NR52]()))
        audio.noise4.length_counter.channel_enabled = true
        assert.not_same(0, bit32.band(0x08, io.read_logic[ports.NR52]()))
      end)
      it("Bit 7 of NR52 controls master power", function()
        -- note: crazy power not available until GBA
        io.write_logic[ports.NR52](0x00)
        assert.falsy(audio.master_enable)
        io.write_logic[ports.NR52](0x80)
        assert.truthy(audio.master_enable)
      end)
    end)
  end)
end)