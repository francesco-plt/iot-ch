configuration AppC
{
}
implementation
{
  components MainC, Ch3C, LedsC, SerialPrintfC;
  components new TimerMilliC() as Timer0;


  Ch3C -> MainC.Boot;
  Ch3C.Timer0 -> Timer0;
  Ch3C.Leds -> LedsC;
}

