#property copyright "EA-Forex project"
#property version   "0.1"
#property strict

input string InpSymbol = "EURUSD";
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_H1;
input double InpRiskPercent = 0.5;
input bool InpEnableTrading = false; // H1 never sends orders

bool ValidateConfiguration()
{
   if(StringLen(InpSymbol) == 0 || InpRiskPercent <= 0.0 || InpRiskPercent > 0.5)
      return false;
   if(!SymbolSelect(InpSymbol, true))
      return false;
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
   PrintFormat("EA-FX H1 READY | symbol=%s | timeframe=%s | trading disabled", InpSymbol, EnumToString(InpTimeframe));
   return INIT_SUCCEEDED;
}

void OnTick()
{
   // H1: intentional no-op. No order placement in this milestone.
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   // H1: reserved for later reconciliation; no trading logic.
}

void OnDeinit(const int reason)
{
   PrintFormat("EA-FX H1 STOPPED | reason=%d", reason);
}
