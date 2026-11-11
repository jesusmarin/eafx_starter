# EA-Forex — H0/H1

Initial MQL5 skeleton. No orders are sent. Only demo accounts are accepted.

1. Install MetaTrader 5 and open MetaEditor.
2. Copy `Experts/EA-Forex/EA-Forex.mq5` to the terminal's `MQL5/Experts/EA-Forex/` directory.
3. Compile in MetaEditor (F7), record errors/warnings and build details.
4. Attach EA to a demo chart; confirm READY and STOPPED messages.
5. Repeat with invalid risk and a non-demo account to confirm fail-closed behavior (never place orders).
6. Record evidence and Git commit hash. Do not mark H1 complete until local verification.

Note: Symbol naming varies by broker (e.g. EURUSD suffixes). Configure InpSymbol accordingly.

# EA-Forex H2-MD01 (propuesta, no compilada aquí)

Reemplazar temporalmente `Experts/EA-Forex/EA-Forex.mq5` en una rama de trabajo, tras guardar el archivo original. Compilar en MetaEditor (F7) y registrar errores y advertencias. Probar en Strategy Tester con cuenta demo, EURUSD/H1, `InpRiskPercent=0.5`, `InpEnableTrading=false`. Confirmar `EA-FX H2 READY`, al menos un `EA-FX H2 MARKET_DATA`, ausencia de órdenes y cierre normal. No habilitar trading real.

Precaución: los logs solo muestran una observación por vela cerrada, no todos los ticks. La precisión de precios depende del símbolo del broker; los valores se registran con `_Digits` del gráfico, por lo que H2-MD02 deberá sustituirlo por los dígitos propios de `InpSymbol` cuando se soporte otro símbolo. No subir credenciales ni logs sensibles.
