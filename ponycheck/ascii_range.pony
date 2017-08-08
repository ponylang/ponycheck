
primitive ASCIIDigits
  fun apply(): String => "0123456789"

primitive ASCIIWhiteSpace
  fun apply(): String => " \t\n\r\x0b\x0c"

primitive ASCIIPunctuation
  fun apply(): String => "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"

primitive ASCIILettersLower
  fun apply(): String => "abcdefghijklmnopqrstuvwxyz"

primitive ASCIILettersUpper
  fun apply(): String => "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

primitive ASCIILetters
  fun apply(): String => ASCIILettersLower() + ASCIILettersUpper()

primitive ASCIIPrintable
  fun apply(): String =>
    ASCIIDigits()
      + ASCIILetters()
      + ASCIIPunctuation()
      + ASCIIWhiteSpace()

primitive ASCIINonPrintable
  fun apply(): String =>
    "\x00"      // NUL
    + "\x01"    // SOH
    + "\x02"    // STX
    + "\x03"    // ETX
    + "\x04"    // EOT
    + "\x05"    // ENQ
    + "\x06"    // ACK
    + "\x07"    // BEL
    + "\x08"    // BS
    + "\x0e"    // SO
    + "\x0f"    // SI
    + "\x10"    // DLE
    + "\x11"    // DC1
    + "\x12"    // DC2
    + "\x13"    // DC3
    + "\x14"    // DC4
    + "\x15"    // NAK
    + "\x16"    // SYN
    + "\x17"    // ETB
    + "\x18"    // CAN
    + "\x19"    // EM
    + "\x1a"    // SUB
    + "\x1b"    // ESC
    + "\x1c"    // FS
    + "\x1d"    // GS
    + "\x1e"    // RS
    + "\x1f"    // US

primitive ASCIIAll
  fun apply(): String =>
    ASCIIPrintable() + ASCIINonPrintable()

type ASCIIRange is
    ( ASCIIDigits
    | ASCIIWhiteSpace
    | ASCIIPunctuation
    | ASCIILettersLower
    | ASCIILettersUpper
    | ASCIILetters
    | ASCIIPrintable
    | ASCIINonPrintable
    | ASCIIAll)
