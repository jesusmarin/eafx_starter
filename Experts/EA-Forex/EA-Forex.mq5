#property copyright "EA-Forex project"
#property version   "0.3"
#property strict

input string InpSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;
input double InpRiskPercent = 0.5;
input bool InpEnableTrading = false; // Reserved; no orders in H2

datetime g_lastClosedBarTime = 0;

bool ValidateConfiguration()
{
   if(StringLen(InpSymbol) == 0 || InpRiskPercent <= 0.0 || InpRiskPercent > 0.5)
      return false;
   if(!SymbolSelect(InpSymbol, true))
      return false;
   return true;
}


bool ValidateMarketDataIntegrity(const MqlRates &bar,
                                 const MqlTick &tick)
{
   if(bar.time <= 0 ||
      !MathIsValidNumber(bar.open) ||
      !MathIsValidNumber(bar.high) ||
      !MathIsValidNumber(bar.low) ||
      !MathIsValidNumber(bar.close) ||
      bar.open <= 0 ||
      bar.high <= 0 ||
      bar.low <= 0 ||
      bar.close <= 0 ||
      bar.high < MathMax(bar.open, bar.close) ||
      bar.low > MathMin(bar.open, bar.close) ||
      !MathIsValidNumber(tick.bid) ||
      !MathIsValidNumber(tick.ask) ||
      tick.bid <= 0 ||
      tick.ask <= 0 ||
      tick.ask < tick.bid ||
      tick.time <= 0)
   {
      return false;
   }

   return true;
}


bool ValidateTickFreshness(const MqlTick &tick,
                           const datetime referenceTime,
                           const int maxAgeSeconds = 120,
                           const int maxFutureSkewSeconds = 5)
{
   if(referenceTime <= 0 || tick.time <= 0 ||
      maxAgeSeconds < 0 || maxFutureSkewSeconds < 0)
      return false;

   long ageSeconds = (long)referenceTime - (long)tick.time;

   return ageSeconds <= maxAgeSeconds &&
          ageSeconds >= -maxFutureSkewSeconds;
}


bool ValidateClosedBarFreshness(
   const MqlRates &bar,
   const datetime referenceTime,
   const int periodSeconds,
   const int toleranceSeconds = 120)
{
   if(bar.time <= 0 ||
      referenceTime <= 0 ||
      periodSeconds <= 0 ||
      toleranceSeconds < 0)
      return false;

   long barAge = (long)referenceTime - (long)bar.time;

   return barAge >= periodSeconds &&
          barAge <= 2 * (long)periodSeconds + toleranceSeconds;
}


// H2-MD01: obtain one complete candle (shift 1) and current quote.
// No trading decisions or orders are allowed in this increment.
//H2-MD03: validate the market data for integrity, recency, and consistency.
bool ReadMarketData(MqlRates &closedBar, MqlTick &tick)
{
   const int maxTickAgeSeconds = 120;
   const int maxFutureSkewSeconds = 5;

   MqlRates bars[];
   ArraySetAsSeries(bars, true);

   ResetLastError();
   if(CopyRates(InpSymbol, InpTimeframe, 1, 1, bars) != 1)
   {
      PrintFormat("EA-FX H2 DATA_UNAVAILABLE | CopyRates error=%d",
                  GetLastError());
      return false;
   }

   ResetLastError();
   if(!SymbolInfoTick(InpSymbol, tick))
   {
      PrintFormat("EA-FX H2 DATA_UNAVAILABLE | SymbolInfoTick error=%d",
                  GetLastError());
      return false;
   }

   closedBar = bars[0];

   // MD02-01: integridad OHLC y Bid/Ask.   
   closedBar = bars[0];

   if(!ValidateMarketDataIntegrity(closedBar, tick))
   {
      Print("EA-FX H2 DATA_INVALID | OHLC or tick invariant failed");
      return false;
   }


   // MD02-02: referencia temporal del servidor.
   datetime now = TimeTradeServer();

   if(now <= 0)
      now = TimeCurrent();

   if(now <= 0)
   {
      Print("EA-FX H2 TIME_UNAVAILABLE");
      return false;
   }

   // MD02-03: vigencia del tick.   
   if(!ValidateTickFreshness(tick, now, maxTickAgeSeconds, maxFutureSkewSeconds))
   {
         long tickAge = (long)now - (long)tick.time;
         PrintFormat("EA-FX H2 TICK_STALE | age_seconds=%I64d", tickAge);
         return false;
   }


   // MD02-04: última vela cerrada y antigüedad.
   int periodSeconds = PeriodSeconds(InpTimeframe);

   if(periodSeconds <= 0)
   {
      Print("EA-FX H2 TIMEFRAME_INVALID");
      return false;
   }

   if(!ValidateClosedBarFreshness( closedBar,  now,  periodSeconds, maxTickAgeSeconds))
   {
      long barAge = (long)now - (long)closedBar.time;

      PrintFormat( "EA-FX H2 BAR_STALE | age_seconds=%I64d",  barAge );

      return false;
   }

   return true;
}


bool Test_MD02_P02_InvalidOHLC()
{
   MqlRates bar = {};
   MqlTick tick = {};

   bar.time  = D'2026.11.11 12:00';
   bar.open  = 1.11000;
   bar.high  = 1.10900; // Inválido: menor que apertura
   bar.low   = 1.10800;
   bar.close = 1.10950;

   tick.time = D'2026.11.11 12:00';
   tick.bid  = 1.10940;
   tick.ask  = 1.10948;

   bool accepted = ValidateMarketDataIntegrity(bar, tick);

   if(accepted)
   {
      Print("EA-FX TEST MD02-P02 FAIL | invalid OHLC accepted");
      return false;
   }

   Print("EA-FX TEST MD02-P02 PASS | invalid OHLC rejected");
   return true;
}


bool Test_MD02_P03_StaleTick()
{
   datetime referenceTime = D'2026.11.11 14:00:00';

   MqlTick tick = {};
   tick.time = referenceTime - 180;

   bool staleRejected =
      !ValidateTickFreshness(tick, referenceTime);

   tick.time = referenceTime - 30;

   bool freshAccepted =
      ValidateTickFreshness(tick, referenceTime);

   tick.time = referenceTime + 10;

   bool futureRejected =
      !ValidateTickFreshness(tick, referenceTime);

   if(staleRejected && freshAccepted && futureRejected)
   {
      Print("EA-FX TEST MD02-P03 PASS | stale/fresh/future ticks validated");
      return true;
   }

   PrintFormat(
      "EA-FX TEST MD02-P03 FAIL | stale=%d fresh=%d future=%d",
      (int)staleRejected,
      (int)freshAccepted,
      (int)futureRejected
   );

   return false;
}


bool Test_MD02_P04_ClosedBarFreshness()
{
   const datetime referenceTime = D'2026.11.11 14:30:00';
   const int periodSeconds = 3600;

   MqlRates bar = {};

   // Caso 1: vela H1 cerrada y vigente.
   bar.time = referenceTime - 5400;

   bool validAccepted = ValidateClosedBarFreshness(
      bar, referenceTime, periodSeconds);

   // Caso 2: vela demasiado antigua.
   bar.time = referenceTime - 10800;

   bool staleRejected = !ValidateClosedBarFreshness(
      bar, referenceTime, periodSeconds);

   // Caso 3: vela todavía en formación.
   bar.time = referenceTime - 1800;

   bool openRejected = !ValidateClosedBarFreshness(
      bar, referenceTime, periodSeconds);

   // Caso 4: marca temporal futura.
   bar.time = referenceTime + 3600;

   bool futureRejected = !ValidateClosedBarFreshness(
      bar, referenceTime, periodSeconds);

   if(validAccepted && staleRejected &&
      openRejected && futureRejected)
   {
      Print("EA-FX TEST MD02-P04 PASS | closed/stale/open/future bars validated");
      return true;
   }

   PrintFormat(
      "EA-FX TEST MD02-P04 FAIL | valid=%d stale=%d open=%d future=%d",
      (int)validAccepted,
      (int)staleRejected,
      (int)openRejected,
      (int)futureRejected
   );

   return false;
}


int OnInit()
{
   if(!ValidateConfiguration())
   {
      Print("EA-FX H1: invalid configuration or unavailable symbol");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(AccountInfoInteger(ACCOUNT_TRADE_MODE) != ACCOUNT_TRADE_MODE_DEMO)
   {
      Print("EA-FX H1: demo account required");
      return INIT_FAILED;
   }


   if(InpEnableTrading)
   {
      Print("EA-FX H2: InpEnableTrading must remain false");
      return INIT_PARAMETERS_INCORRECT;
   }
   PrintFormat("EA-FX H2 READY | symbol=%s | timeframe=%s | trading disabled", InpSymbol, EnumToString(InpTimeframe));
   
   
   return INIT_SUCCEEDED;
}


void OnTick()
{
   MqlRates closedBar;
   MqlTick tick;
   if(!ReadMarketData(closedBar, tick))
      return;
   // At most one observation per closed candle, even with many ticks.
   if(closedBar.time == g_lastClosedBarTime)
      return;
   g_lastClosedBarTime = closedBar.time;
   PrintFormat("EA-FX H2 MARKET_DATA | bar=%s | O=%s H=%s L=%s C=%s | bid=%s ask=%s | spread_points=%.1f",
      TimeToString(closedBar.time, TIME_DATE|TIME_MINUTES),
      DoubleToString(closedBar.open, _Digits), DoubleToString(closedBar.high, _Digits),
      DoubleToString(closedBar.low, _Digits), DoubleToString(closedBar.close, _Digits),
      DoubleToString(tick.bid, _Digits), DoubleToString(tick.ask, _Digits),
      (tick.ask - tick.bid) / SymbolInfoDouble(InpSymbol, SYMBOL_POINT));
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   // Reserved for a future increment. No order logic.
}

void OnDeinit(const int reason)
{
   PrintFormat("EA-FX H2 STOPPED | reason=%d", reason);
}
