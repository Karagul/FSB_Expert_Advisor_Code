//+--------------------------------------------------------------------+
//| Copyright:  (C) 2014 Forex Software Ltd.                           |
//| Website:    http://forexsb.com/                                    |
//| Support:    http://forexsb.com/forum/                              |
//| License:    Proprietary under the following circumstances:         |
//|                                                                    |
//| This code is a part of Forex Strategy Builder. It is free for      |
//| use as an integral part of Forex Strategy Builder.                 |
//| One can modify it in order to improve the code or to fit it for    |
//| personal use. This code or any part of it cannot be used in        |
//| other applications without a permission.                           |
//| The contact information cannot be changed.                         |
//|                                                                    |
//| NO LIABILITY FOR CONSEQUENTIAL DAMAGES                             |
//|                                                                    |
//| In no event shall the author be liable for any damages whatsoever  |
//| (including, without limitation, incidental, direct, indirect and   |
//| consequential damages, damages for loss of business profits,       |
//| business interruption, loss of business information, or other      |
//| pecuniary loss) arising out of the use or inability to use this    |
//| product, even if advised of the possibility of such damages.       |
//+--------------------------------------------------------------------+

#property copyright "Copyright (C) 2014 Forex Software Ltd."
#property link      "http://forexsb.com"
#property version   "3.00"
#property strict

#include <Forexsb.com\ActionTrade5.mqh>

// -----------------------    External variables   ----------------------- //

extern double Entry_Amount    = 77701; // Entry amount for a new position #TRADEUNIT#
extern double Maximum_Amount  = 77702; // Maximum position amount [lot]
extern double Adding_Amount   = 77703; // Amount to add on addition #TRADEUNIT#
extern double Reducing_Amount = 77704; // Amount to close on reduction #TRADEUNIT#

// If account equity drops below this value, the expert will close out all positions and stop automatic trade.
// The value must be set in account currency. Example:
// Protection_Min_Account = 700 will close positions if the equity drops below 700 USD (EUR if you account is in EUR).
extern int Protection_Min_Account=0; // Stop trading at min account

// The expert checks the open positions at every tick and if found no SL or SL lower (higher for short) than selected,
// It sets SL to the defined value. The value is in points. Example:
// Protection_Max_StopLoss = 200 means 200 pips for 4 digit broker and 20 pips for 5 digit broker.
extern int Protection_Max_StopLoss=0; // Ensure maximum Stop Loss [point]

// How many seconds before the expected bar closing to rise a Bar Closing event.
extern int Bar_Close_Advance=15; // Bar closing advance [sec]

// Expert writes a log file when Write_Log_File = true.
extern bool Write_Log_File=false; // Write a log file

// ----------------------------    Options   ---------------------------- //

// Data bars for calculating the indicator values with the necessary precission.
int Max_Data_Bars=0; 

// Have to be set to true for STP brokers that cannot set SL and TP together with the position (with OrderSend()).
// When Separate_SL_TP = true, the expert first opens the position and after that sets StopLoss and TakeProfit.
bool Separate_SL_TP=false; // Separate SL and TP orders

// The expert loads this XML file form MetaTrader "Files" folder if no XML string is provided.
string Strategy_File_Name="Strategy.xml"; // FSB Strategy Name 

// The strategy as an XML string. If XML is provide, the expert loads it instead of a file.
string Strategy_XML="##STRATEGY##"; // XML String

// TrailingStop_Moving_Step determines the step of changing the Trailing Stop.
// 0 <= TrailingStop_Moving_Step <= 2000
// If TrailingStop_Moving_Step = 0, the Trailing Stop trails at every new extreme price in the position's direction.
// If TrailingStop_Moving_Step > 0, the Trailing Stop moves at steps equal to the number of pips chosen.
// This prevents sending multiple order modifications. 
int TrailingStop_Moving_Step=10;

// FIFO (First In First Out) forces the expert to close positions starting from
// the oldest one. This rule complies with the new NFA regulations.
// If you want to close the positions from the newest one (FILO), change the variable to "false".
// This doesn't change the normal work of Forex Strategy Builder.
bool FIFO_order=true;

// When the log file reaches number of lines, the expert starts a new file.
int MaxLogLinesInFile=2000;

// Used to detect a chart change
string __symbol = "";
int    __period = -1;

//##IMPORT Enumerations.mqh
//##IMPORT Helpers.mqh
//##IMPORT MQ5Conv.mqh
//##IMPORT DataSet.mqh
//##IMPORT DataMarket.mqh
//##IMPORT IndicatorComp.mqh
//##IMPORT IndicatorParam.mqh
//##IMPORT Indicator.mqh
//##IMPORT IndicatorManager.mqh
//##IMPORT IndicatorSlot.mqh
//##IMPORT Strategy.mqh
//##IMPORT EasyXml.mqh
//##IMPORT StrategyManager.mqh
//##IMPORT Logger.mqh
//##IMPORT ActionTrade5.mqh

// The Forex Strategy Builder Expert
ActionTrade5* actionsTrade;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   actionsTrade = new ActionTrade5();
   
   actionsTrade.Entry_Amount    = (Entry_Amount   >77700)?0.1:Entry_Amount;
   actionsTrade.Maximum_Amount  = (Maximum_Amount >77700)?0.1:Maximum_Amount;
   actionsTrade.Adding_Amount   = (Adding_Amount  >77700)?0.1:Adding_Amount;
   actionsTrade.Reducing_Amount = (Reducing_Amount>77700)?0.1:Reducing_Amount;

   actionsTrade.Strategy_File_Name       = Strategy_File_Name;
   actionsTrade.Strategy_XML             = Strategy_XML;
   actionsTrade.Max_Data_Bars            = Max_Data_Bars;
   actionsTrade.Protection_Min_Account   = Protection_Min_Account;
   actionsTrade.Protection_Max_StopLoss  = Protection_Max_StopLoss;
   actionsTrade.Separate_SL_TP           = Separate_SL_TP;
   actionsTrade.Write_Log_File           = Write_Log_File;
   actionsTrade.TrailingStop_Moving_Step = TrailingStop_Moving_Step;
   actionsTrade.FIFO_order               = FIFO_order;
   actionsTrade.MaxLogLinesInFile        = MaxLogLinesInFile;
   actionsTrade.Bar_Close_Advance        = Bar_Close_Advance;

   int result=actionsTrade.OnInit();

   if(result==INIT_SUCCEEDED)
      actionsTrade.OnTick();

   return (result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(__symbol!=_Symbol || __period!=_Period)
     {
      if(__period > 0)
      {
         actionsTrade.OnDeinit(-1);
         actionsTrade.OnInit();
      }
      __symbol=_Symbol;
      __period=_Period;
     }

   actionsTrade.OnTick();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTrade()
{
   actionsTrade.OnTrade();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   actionsTrade.OnDeinit(reason);
   
   if(CheckPointer(actionsTrade)==POINTER_DYNAMIC)
      delete actionsTrade;
  }
//+------------------------------------------------------------------+
