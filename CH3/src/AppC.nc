#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration AppC {}

implementation
{
  components MainC;
  components C;
  components PrintfC;
  // components SerialPrintfC;
  components SerialStartC;
  components LedsC;
  components new TimerMilliC();

  C.Boot -> MainC;
  C.Timer -> TimerMilliC;
  C.Leds -> LedsC;
}

