const Module = require('./woff2_to_ttf')

module.exports = {
  convert: function(woff2ByteArray) {
    var buf = Module._malloc(woff2ByteArray.length*woff2ByteArray.BYTES_PER_ELEMENT);
    Module.HEAPU8.set(woff2ByteArray, buf);
    var result = Module.ccall('woff2_to_TTF', 'bool', ['number', 'number'], [buf, woff2ByteArray.length]);
    Module._free(buf);
    if (!result) {
      throw new Error("Failed to convert from woff2");
    }
    var offset = Module._output_bytes()
    var length = Module._output_length()
    return new Uint8Array(Module.HEAP8.subarray(offset, offset+length))
  }
}