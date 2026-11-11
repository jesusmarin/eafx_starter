#property copyright "EA-Forex project"
#property version   "0.1"
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
bool ReadMarketData(MqlRates &closedBar, MqlTick &tick)
{
   MqlRates bars[];
   ArraySetAsSeries(bars, true);
   ResetLastError();
   if(CopyRates(InpSymbol, InpTimeframe, 1, 1, bars) != 1)
   {
      PrintFormat("EA-FX H2 DATA_UNAVAILABLE | CopyRates error=%d", GetLastError());
      return false;
   }
   if(!SymbolInfoTick(InpSymbol, tick))
   {
      PrintFormat("EA-FX H2 DATA_UNAVAILABLE | SymbolInfoTick error=%d", GetLastError());
      return false;
   }
   closedBar = bars[0];
   if(closedBar.time <= 0 || closedBar.high < closedBar.low ||
      closedBar.open <= 0 || closedBar.high <= 0 || closedBar.low <= 0 ||
      closedBar.close <= 0 || tick.bid <= 0 || tick.ask <= 0 ||
      tick.ask < tick.bid || tick.time <= 0)
   {
      Print("EA-FX H2 DATA_INVALID | OHLC or tick invariant failed");
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
