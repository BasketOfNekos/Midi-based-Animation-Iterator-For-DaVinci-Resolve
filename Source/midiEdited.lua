--This is a heavily modified version of https://github.com/Possseidon/lua-midi

--local bit = require "numberlua"
--Avoiding having import numberlua and reducing file clutter.
--If you want to put it back, then replace all instances of "bit_" and "bit32_" with "bit." and "bit32."

local MOD = 2^32
local MODM = MOD-1

local function memoize(f)
  local mt = {}
  local t = setmetatable({}, mt)
  function mt:__index(k)
    local v = f(k); t[k] = v
    return v
  end
  return t
end

local function make_bitop_uncached(t, m)
  local function bitop(a, b)
    local res,p = 0,1
    while a ~= 0 and b ~= 0 do
      local am, bm = a%m, b%m
      res = res + t[am][bm]*p
      a = (a - am) / m
      b = (b - bm) / m
      p = p*m
    end
    res = res + (a+b)*p
    return res
  end
  return bitop
end

local function make_bitop(t)
  local op1 = make_bitop_uncached(t,2^1)
  local op2 = memoize(function(a)
    return memoize(function(b)
      return op1(a, b)
    end)
  end)
  return make_bitop_uncached(op2, 2^(t.n or 1))
end

bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}

function band(a,b) return ((a+b) - bxor(a,b))/2 end

function bor(a,b)  return MODM - band(MODM - a, MODM - b) end

local function bit32_bxor(a, b, c, ...)
  local z
  if b then
    a = a % MOD
    b = b % MOD
    z = bxor(a, b)
    if c then
      z = bit32_bxor(z, c, ...)
    end
    return z
  elseif a then
    return a % MOD
  else
    return 0
  end
end

local function bit32_band(a, b, c, ...)
  local z
  if b then
    a = a % MOD
    b = b % MOD
    z = ((a+b) - bxor(a,b)) / 2
    if c then
      z = bit32_band(z, c, ...)
    end
    return z
  elseif a then
    return a % MOD
  else
    return MODM
  end
end

local function bit32_bor(a, b, c, ...)
  local z
  if b then
    a = a % MOD
    b = b % MOD
    z = MODM - band(MODM - a, MODM - b)
    if c then
      z = bit32_bor(z, c, ...)
    end
    return z
  elseif a then
    return a % MOD
  else
    return 0
  end
end

function bit32_lshift(x,disp)
  if disp > 31 or disp < -31 then return 0 end
  return lshift(x % MOD, disp)
end

function lshift(a,disp) -- Lua5.2 inspired
  if disp < 0 then return rshift(a,-disp) end
  return (a * 2^disp) % 2^32
end

function bit_tobit(x)
  x = x % MOD
  if x >= 0x80000000 then x = x - MOD end
  return x
end

function bit_bnot(x)
  return bit_tobit(bnot(x % MOD))
end

local function bit_bor(a, b, c, ...)
  if c then
    return bit_bor(bit_bor(a, b), c, ...)
  elseif b then
    return bit_tobit(bor(a % MOD, b % MOD))
  else
    return bit_tobit(a)
  end
end

local function bit_band(a, b, c, ...)
  if c then
    return bit_band(bit_band(a, b), c, ...)
  elseif b then
    return bit_tobit(band(a % MOD, b % MOD))
  else
    return bit_tobit(a)
  end
end

local function bit_bxor(a, b, c, ...)
  if c then
    return bit_bxor(bit_bxor(a, b), c, ...)
  elseif b then
    return bit_tobit(bxor(a % MOD, b % MOD))
  else
    return bit_tobit(a)
  end
end

function bit_lshift(x, n)
  return bit_tobit(lshift(x % MOD, n % 32))
end





local midi = {}

-- This format function does the inverse of write_format. It unpacks a binary
-- string into a list of integers of specified size, supporting big and little 
-- endian ordering. Example:
--   read_format(true, "421", "xV4.1)a") returns 0x12345678, 0x2931 and 0x61.
function read_format(little_endian, format, str)
  local idx = 0
  local res = {}
  for i=1,#format do
    local size = tonumber(format:sub(i,i))
    local val = str:sub(idx+1,idx+size)
    local value = 0
    idx = idx + size
    if little_endian then
      val = string.reverse(val)
    end
    for j=1,size do
      value = value * 256 + val:byte(j)
    end
    res[i] = value
  end
  return unpack(res)
end

---Reads exactly count bytes from the given stream, raising an error if it can't.
---@param stream file* The stream to read from.
---@param count integer The count of bytes to read.
---@return string data The read bytes.
local function read(stream, count)
  local result = ""
  while #result ~= count do
    result = result .. assert(stream:read(count), "missing value")
  end
  return result
end

---Reads a variable length quantity from the given stream, raising an error if it can't.
---@param stream file* The stream to read from.
---@return integer value The read value.
---@return integer length How many bytes were read in total.
local function readVLQ(stream)
  local value = 0
  local length = 0
  repeat
    local byte = assert(stream:read(1), "incomplete or missing variable length quantity"):byte()
--    value = value << 7
--    value = value | byte & 0x7F
    value = bit_lshift(value, 7)
    value = bit_bor(value, bit_band(byte, 0x7F))
    length = length + 1
  until byte < 0x80
  return value, length
end

local midiEvent = {
  [0x80] = function(stream, channel, fb)
    local key, velocity = read_format(true, "11", fb .. stream:read(1))
    --print("noteOff", channel, key, velocity / 0x7F)
    return 2, false, channel, key, velocity / 0x7F
  end,
  [0x90] = function(stream, channel, fb)
    local key, velocity = read_format(true, "11", fb .. stream:read(1))
    --print("noteOn", channel, key, velocity / 0x7F)
    return 2, true, channel, key, velocity / 0x7F
  end,
  [0xA0] = function(stream, channel, fb)
    local key, pressure = read_format(true, "11", fb .. stream:read(1))
    --print("keyPressure", channel, key, pressure / 0x7F)
    return 2, true, channel, key, pressure / 0x7F
  end,
  [0xB0] = function(stream, channel, fb)
    local number, value = read_format(true, "11", fb .. stream:read(1))
    if number < 120 then
      --print("controller", channel, number, value)
    else
      --print("modeMessage", channel, number, value)
    end
    return 2
  end,
  [0xC0] = function(stream, channel, fb)
    local program = fb:byte()
    --print("program", channel, program)
    return 1
  end,
  [0xD0] = function(stream, channel, fb)
    local pressure = fb:byte()
    --print("channelPressure", channel, pressure / 0x7F)
    return 1
  end,
  [0xE0] = function(stream, channel, fb)
    local lsb, msb = read_format(true, "11", fb .. stream:read(1))
    --print("pitch", channel, bit32_bor(lsb, bit32_lshift(msb, 7)) / 0x2000 - 1)
    return 2
  end
}

---Processes a manufacturer specific SysEx event.
---@param stream file* The stream, pointing to one byte after the start of the SysEx event.
---@param fb string The first already read byte, representing the manufacturer id.
---@return integer length The total length of the read SysEx event in bytes (including fb).
local function sysexEvent(stream, fb)
  local manufacturer = fb:byte()
  local data = {}
  repeat
    local char = stream:read(1)
    table.insert(data, char)
  until char:byte() == 0xF7
  print("sysexEvent", data, manufacturer, table.concat(data))
  return 1 + #data
end

---Creates a simple function, forwarding the provided name and read data to a callback function.
---@param name string The name of the event, which is passed to the callback function.
---@return function function The function, calling the provided callback function with name and read data.
local function makeForwarder(name)
  return function(data)
    print(name, data)
  end
end

local metaEvents = {
  [0x00] = makeForwarder("sequenceNumber"),
  [0x01] = makeForwarder("text"),
  [0x02] = makeForwarder("copyright"),
  [0x03] = makeForwarder("sequencerOrTrackName"),
  [0x04] = makeForwarder("instrumentName"),
  [0x05] = makeForwarder("lyric"),
  [0x06] = makeForwarder("marker"),
  [0x07] = makeForwarder("cuePoint"),
  [0x20] = makeForwarder("channelPrefix"),
  [0x2F] = makeForwarder("endOfTrack"),
  [0x51] = function(data)
    local rawTempo = read_format(false, "3", data)
    print("setTempo", 6e7 / rawTempo)
    return "setTempo", rawTempo
  end,
  [0x54] = makeForwarder("smpteOffset"),
  [0x58] = function(data)
    local numerator, denominator, metronome, dotted = read_format(false, "1111", data)
    print("timeSignature", numerator, bit_lshift(1, denominator), metronome, dotted)
  end,
  [0x59] = function(data)
    local count, minor = read_format(false, "11", data)
    print("keySignature", math.abs(count), count < 0 and "flat" or count > 0 and "sharp" or "C", minor == 0 and "major" or "minor")
  end,
  [0x7F] = makeForwarder("sequenceEvent")
}

---Processes a midi meta event.
---@param stream file* A stream pointing one byte after the meta event.
---@param fb string The first already read byte, representing the meta event type.
---@return integer length The total length of the read meta event in bytes (including fb).
local function metaEvent(stream, fb)
  local event = fb:byte()
  local length, vlqLength = readVLQ(stream)
  local data = read(stream, length)
  local handler = metaEvents[event]
  if handler then
    eventType, eventInfo = handler(data)
  end
  return 1 + vlqLength + length, eventType, eventInfo
end

---Reads the four magic bytes and length of a midi chunk.
---@param stream file* A stream, pointing to the start of a midi chunk.
---@return string type The four magic bytes the chunk type (usually `MThd` or `MTrk`).
---@return integer length The length of the chunk in bytes.
local function readChunkInfo(stream)
    local c4 = stream:read(4)
    if not c4 then
      return false
    end
    assert(#c4 == 4, "incomplete c4")
    local I4 = read_format(false, "4", stream:read(4))
    if not I4 then
      return false
    end
    return c4, I4
end

---Reads the content in a header chunk of a midi file.
---@param stream file* A stream, pointing to the data part of a header chunk.
---@param chunkLength integer The length of the chunk in bytes.
---@return integer format The format of the midi file (0, 1 or 2).
---@return integer tracks The total number of tracks in the midi file.
local function readHeader(stream, chunkLength)
  local header = read(stream, chunkLength)
  assert(header and #header == 6, "incomplete or missing header")
  local format, tracks, division = read_format(false, "222", header)
  print("header", format, tracks, division)
  return format, tracks, division
end

---Reads the content of a track chunk of a midi file.
---@param stream file* A stream, pointing to the data part of a track chunk.
---@param chunkLength number The length of the chunk in bytes.
---@param track integer The one-based index of the track, used in the "track" callback.
local function readTrack(stream, chunkLength, track, tempo)
  print("track", track)
  local trackNotes = {}
  local tick = 0
  local runningStatus

  while chunkLength > 0 do
    local deltatime, vlqLength = readVLQ(stream)
    --if deltatime > 0 then print("deltatime", deltatime) end
    tick = tick + deltatime

    local firstByte = assert(stream:read(1), "missing event")
    local status = firstByte:byte()
    local length = 0

    if status < 0x80 then
      status = assert(runningStatus, "no running status")
    else
      firstByte = stream:read(1)
      length = 1
      runningStatus = status
    end

    if status >= 0x80 and status < 0xF0 then
      local newlen, noteon, channel, note, velocity = midiEvent[bit_band(status, 0xF0)](stream, bit_band(status, 0x0F) + 1, firstByte) -- note is the "key" being pressed
      if noteon == true then
        table.insert(trackNotes, {note = note, tick = tick, tempo = tempo, channel = channel, velocity = velocity})
      end
      length = length + newlen
    elseif status == 0xF0 then
      length = length + sysexEvent(stream, firstByte)
    elseif status == 0xF2 then
      length = length + 2
    elseif status == 0xF3 then
      length = length + 1
    elseif status == 0xFF then
      local metaOffset, eventType, eventInfo = metaEvent(stream, firstByte) -- If you want to track any extra meta events, do it here
      length = length + metaOffset

      if eventType == "setTempo" then
        tempo = eventInfo
      end

    else
      print("ignore", status)
    end

    local readChunkLength
    readChunkLength = length
    --readChunkLength, runningStatus = processEvent(stream, runningStatus)
    chunkLength = chunkLength - readChunkLength - vlqLength
  end

  return trackNotes, tempo
end

---Processes a midi file.
---@param stream file* A stream, pointing to the start of a midi file.
---@param frame_rate frame rate is used to calculate the frame offset of a note.
---@param onlyHeader? boolean Wether processing should stop after the header chunk.
---@param onlyTrack? integer If specified, only this single track (one-based) will be processed.
---@return returns a table of tables. Each midi track is a table and each of those tables has:
  ---note, the note thats playing
  ---tick, the tick a note plays on
  ---frame, the frame the note plays on given the tick and fps values
  ---velocity, how hard a note is being pushed
  ---channel,
  ---tempo, if the tempo of the files changes, this will reflect that (may be done incorrectly)
function midi.process(stream, frame_rate, onlyHeader, onlyTrack)
  local allTracks = {}
  local format, tracks, devision -- Header information
  local track = 0
  local tempo = 500000  -- Default tempo (120 BPM)

  -- Convert ticks to frames
  local function ticks_to_frames(tick, tempo, division)
    local ticks_per_frame
    if division > 0 then
      -- Calculate ticks per frame using frame rate, TPQN, and BPM
      local TPQN = division
      local BPM = 6e7 / tempo  -- Convert tempo to BPM
      local ticks_per_second = (BPM * TPQN) / 60 --60 seconds in a min
      --print("ticks_per_second ", ticks_per_second)
      ticks_per_frame = ticks_per_second / frame_rate
      --print("ticks_per_frame ", ticks_per_frame)
    else
      -- Ticks per frame is directly stored in division
      ticks_per_frame = -division
    end
    return tick / ticks_per_frame
  end

  while true do
    local chunkType, chunkLength = readChunkInfo(stream)

    if not chunkType then break end

    if chunkType == "MThd" then -- Process Header
      assert(not format, "only a single header chunk is allowed")
      format, tracks, devision = readHeader(stream, chunkLength)
      assert(tracks == 1 or format ~= 0, "midi format 0 can only contain a single track")
      assert(not onlyTrack or onlyTrack >= 1 and onlyTrack <= tracks, "track out of range")
      if onlyHeader then
        break
      end
    elseif chunkType == "MTrk" then -- MTrk == Begginning of a track
      track = track + 1

      assert(format, "no header chunk before the first track chunk")
      assert(track <= tracks, "found more tracks than specified in the header")
      assert(track == 1 or format ~= 0, "midi format 0 can only contain a single track")

      if not onlyTrack or track == onlyTrack then


        local trackNotes, tempoSetter = readTrack(stream, chunkLength, track, tempo) -- Read track
        tempo = tempoSetter

        if #trackNotes > 0 and devision ~= nil and tempo ~= nil then
          -- Convert tick values to frames
          for j, event in ipairs(trackNotes) do
            event.frame = ticks_to_frames(event.tick, tempo, devision)
          end
        end

        -- Insert information into the returned
        table.insert(allTracks, trackNotes)

        if onlyTrack then
          break
        end

      else
        stream:seek("cur", chunkLength)
      end

    else
      local data = read(chunkLength)
      print("unknownChunk", chunkType, data)
    end

  end

  if not onlyHeader and not onlyTrack then
    assert(track == tracks, "found less tracks than specified in the header")
  end

  return allTracks
end

return midi
