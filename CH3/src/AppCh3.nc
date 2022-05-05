#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration AppCh3 {}

implementation
{
  components MainC, Ch3, LedsC;
  components SerialPrintfC;
  components SerialStartC;
  components new TimerMilliC();

  Ch3.Boot -> MainC;
  Ch3.Timer -> TimerMilliC;
  Ch3.Leds -> LedsC;
}

