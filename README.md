# EA-Forex — H0/H1

Initial MQL5 skeleton. No orders are sent. Only demo accounts are accepted.

1. Install MetaTrader 5 and open MetaEditor.
2. Copy `Experts/EA-Forex/EA-Forex.mq5` to the terminal's `MQL5/Experts/EA-Forex/` directory.
3. Compile in MetaEditor (F7), record errors/warnings and build details.
4. Attach EA to a demo chart; confirm READY and STOPPED messages.
5. Repeat with invalid risk and a non-demo account to confirm fail-closed behavior (never place orders).
6. Record evidence and Git commit hash. Do not mark H1 complete until local verification.

Note: Symbol naming varies by broker (e.g. EURUSD suffixes). Configure InpSymbol accordingly.
