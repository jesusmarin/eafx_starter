
#ifndef EA_FOREX_INDICATOR_ENGINE_MQH
#define EA_FOREX_INDICATOR_ENGINE_MQH

class CIndicatorEngine
{
private:
   int m_fastEMA;
   int m_slowEMA;
   int m_atr;

public:
   CIndicatorEngine()
   {
      m_fastEMA = INVALID_HANDLE;
      m_slowEMA = INVALID_HANDLE;
      m_atr = INVALID_HANDLE;
   }

   ~CIndicatorEngine()
   {
      Release();
   }

   bool Initialize(
      const string symbol,
      const ENUM_TIMEFRAMES timeframe,
      const int fastPeriod = 20,
      const int slowPeriod = 50,
      const int atrPeriod = 14)
   {
      Release();

      if(StringLen(symbol) == 0 ||
         PeriodSeconds(timeframe) <= 0 ||
         fastPeriod <= 0 ||
         slowPeriod <= fastPeriod ||
         atrPeriod <= 0)
         return false;

      m_fastEMA = iMA(
         symbol, timeframe, fastPeriod, 0,
         MODE_EMA, PRICE_CLOSE);

      m_slowEMA = iMA(
         symbol, timeframe, slowPeriod, 0,
         MODE_EMA, PRICE_CLOSE);

      m_atr = iATR(symbol, timeframe, atrPeriod);

      if(m_fastEMA == INVALID_HANDLE ||
         m_slowEMA == INVALID_HANDLE ||
         m_atr == INVALID_HANDLE)
      {
         Release();
         return false;
      }

      return true;
   }

   bool ReadClosedBar(
      double &fastEMA,
      double &slowEMA,
      double &atr)
   {
      if(m_fastEMA == INVALID_HANDLE ||
         m_slowEMA == INVALID_HANDLE ||
         m_atr == INVALID_HANDLE)
         return false;

      double fast[];
      double slow[];
      double volatility[];

      if(CopyBuffer(m_fastEMA, 0, 1, 1, fast) != 1 ||
         CopyBuffer(m_slowEMA, 0, 1, 1, slow) != 1 ||
         CopyBuffer(m_atr, 0, 1, 1, volatility) != 1)
         return false;

      if(!MathIsValidNumber(fast[0]) ||
         !MathIsValidNumber(slow[0]) ||
         !MathIsValidNumber(volatility[0]) ||
         fast[0] <= 0.0 ||
         slow[0] <= 0.0 ||
         volatility[0] <= 0.0 ||
         fast[0] == EMPTY_VALUE ||
         slow[0] == EMPTY_VALUE ||
         volatility[0] == EMPTY_VALUE)
         return false;

      fastEMA = fast[0];
      slowEMA = slow[0];
      atr = volatility[0];

      return true;
   }

   void Release()
   {
      if(m_fastEMA != INVALID_HANDLE)
      {
         IndicatorRelease(m_fastEMA);
         m_fastEMA = INVALID_HANDLE;
      }

      if(m_slowEMA != INVALID_HANDLE)
      {
         IndicatorRelease(m_slowEMA);
         m_slowEMA = INVALID_HANDLE;
      }

      if(m_atr != INVALID_HANDLE)
      {
         IndicatorRelease(m_atr);
         m_atr = INVALID_HANDLE;
      }
   }
};

#endif
