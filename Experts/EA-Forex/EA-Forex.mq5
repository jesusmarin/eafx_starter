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
   if(closedBar.time <= 0 ||
      closedBar.open <= 0 ||
      closedBar.high <= 0 ||
      closedBar.low <= 0 ||
      closedBar.close <= 0 ||
      closedBar.high < MathMax(closedBar.open, closedBar.close) ||
      closedBar.low > MathMin(closedBar.open, closedBar.close) ||
      tick.bid <= 0 ||
      tick.ask <= 0 ||
      tick.ask < tick.bid ||
      tick.time <= 0)
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
   long tickAge = (long)now - (long)tick.time;

   if(tickAge > maxTickAgeSeconds ||
      tickAge < -maxFutureSkewSeconds)
   {
      PrintFormat("EA-FX H2 TICK_STALE | age_seconds=%I64d",
                  tickAge);
      return false;
   }

   // MD02-04: última vela cerrada y antigüedad.
   int periodSeconds = PeriodSeconds(InpTimeframe);

   if(periodSeconds <= 0)
   {
      Print("EA-FX H2 TIMEFRAME_INVALID");
      return false;
   }

   long barAge = (long)now - (long)closedBar.time;

   if(barAge < periodSeconds ||
      barAge > 2 * periodSeconds + maxTickAgeSeconds)
   {
      PrintFormat("EA-FX H2 BAR_STALE | age_seconds=%I64d",
                  barAge);
      return false;
   }

   return true;
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
