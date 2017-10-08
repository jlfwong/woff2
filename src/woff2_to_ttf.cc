#include <string>
#include <woff2/decode.h>

static std::string output;

extern "C" const char *output_bytes() {
  return reinterpret_cast<const char*>(output.data());
}

extern "C" int output_length() {
  return output.length();
}

extern "C" bool woff2_to_TTF(char* woff2contents, int length) {
  const uint8_t* raw_input = reinterpret_cast<const uint8_t*>(woff2contents);
  output.reserve(std::min(woff2::ComputeWOFF2FinalSize(raw_input, length), woff2::kDefaultMaxSize));
  woff2::WOFF2StringOut out(&output);
  return woff2::ConvertWOFF2ToTTF(raw_input, length, &out);
}
