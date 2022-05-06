#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration AppCh3C {}

implementation {
  components MainC, Ch3C, LedsC;
  components new TimerMilliC();
  components SerialPrintfC;
  components SerialStartC;

  Ch3C.Boot -> MainC;
  Ch3C.Timer -> TimerMilliC;
  Ch3C.Leds -> LedsC;
}