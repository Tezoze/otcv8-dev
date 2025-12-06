# Fixed Packet Decompression Implementation

## Issue Found
The original implementation was incorrectly treating the compression header byte (0x01 or 0x00).

### The Problem:
- **Error:** `unhandled opcode 1` - The client was trying to parse the 0x01 compression header byte as a game opcode!
- **Root Cause:** When compression was enabled but the packet was NOT compressed (packets < 100 bytes), the header byte (0x00) was still in the buffer and being parsed as data.

## How Server Compression Works

Server behavior (from your description):
- Packets > 100 bytes: `0x01 + compressed_zlib_data`
- Packets ≤ 100 bytes: `0x00 + uncompressed_data`

## The Fix

### Before (Broken):
```cpp
if (dataBuffer[0] == 0x01) {
    // Decompress
    m_inputMessage->fillBuffer(zbuffer, decompressedSize);
}
// If 0x00, do nothing - WRONG! The 0x00 byte stays in buffer!
```

### After (Fixed):
```cpp
if (dataBuffer[0] == 0x01) {
    // Decompress and replace buffer with decompressed data
    m_inputMessage->fillBuffer(zbuffer, decompressedSize);
} else {
    // NOT compressed - skip the 0x00 header byte!
    m_inputMessage->fillBuffer(dataBuffer + 1, originalUnreadSize - 1);
}
```

## Key Changes

1. **Always skip the compression header byte** - whether it's 0x01 (compressed) or 0x00 (uncompressed)
2. **Three paths for compressed packets:**
   - Success: Use decompressed data
   - Validation fail: Skip header, use original data
   - Decompression fail: Skip header, use original data
3. **One path for uncompressed packets:**
   - Skip the 0x00 header byte, use the rest

## Technical Details

The compression system in protocol version >= 1098:
- **Byte 0:** Compression flag (0x01 = compressed, 0x00 = not compressed)  
- **Byte 1+:** Either compressed zlib data OR uncompressed game data

The client MUST skip byte 0 in ALL cases to avoid parsing it as an opcode.

## Files Modified
- `src/framework/net/protocol.cpp` - Fixed decompression logic to skip header byte

## Testing
✅ Compilation successful
⏳ Needs runtime testing with server

## Server Requirements
Server must send ALL packets with a compression header byte:
- Large packets (>100 bytes): 0x01 + zlib_compressed_data
- Small packets (≤100 bytes): 0x00 + raw_data

The XTEA encryption happens BEFORE adding the compression header.


