//+--------------------------------------------------------------------+
//| Copyright:  (C) 2016 Forex Software Ltd.                           |
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

#property copyright "Copyright (C) 2016 Forex Software Ltd."
#property link      "http://forexsb.com"
#property version   "3.0"
#property strict

#include <Forexsb.com/Indicator.mqh>
#include <Forexsb.com/Enumerations.mqh>
#include <Forexsb.com/Helpers.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class DayClosing : public Indicator
  {
   int               m_fridayCloseHour;
public:
                     DayClosing(SlotTypes slotType);
   virtual void      Calculate(DataSet &dataSet);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DayClosing::DayClosing(SlotTypes slotType)
  {
   SlotType          = slotType;
   IndicatorName     = "Day Closing";
   WarningMessage    = "";
   IsAllowLTF        = true;
   ExecTime          = ExecutionTime_AtBarClosing;
   IsSeparateChart   = false;
   IsDiscreteValues  = false;
   IsDefaultGroupAll = false;
   m_fridayCloseHour = -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DayClosing::Calculate(DataSet &dataSet)
  {
   Data=GetPointer(dataSet);

   if(m_fridayCloseHour==-1)
      m_fridayCloseHour=GetFridayCloseHour();

   double closePrice[]; ArrayResize(closePrice,Data.Bars); ArrayInitialize(closePrice,0);

   for(int bar=1; bar<Data.Bars; bar++)
     {
      MqlDateTime time0; TimeToStruct(Data.Time[bar - 0], time0);
      MqlDateTime time1; TimeToStruct(Data.Time[bar - 1], time1);
      if(time1.day!=time0.day)
         closePrice[bar-1]=Data.Close[bar-1];
     }

   datetime time        = Data.Time[Data.Bars-1];
   datetime dayOpenTime = (time/86400)*86400;
   MqlDateTime mqlTime; TimeToStruct(time,mqlTime);
   bool isTimeToClose=false;

   if(mqlTime.day_of_week==5)
     {
      datetime fridayCloseTime=(m_fridayCloseHour==-1)
                               ?(dayOpenTime+86400)
                               :(dayOpenTime+m_fridayCloseHour*3600);
      datetime barCloseTime = time+Data.Period*60;
      datetime closeTime    = fridayCloseTime-60;

      isTimeToClose=barCloseTime==fridayCloseTime && Data.ServerTime>closeTime;
     }
   else
     {
      datetime closeTime=dayOpenTime+23*3600+59*60;
      isTimeToClose=Data.ServerTime>closeTime;
     }

   if(isTimeToClose)
      closePrice[Data.Bars-1]=Data.Close[Data.Bars-1];

   Component[0].CompName = "Closing price of the day";
   Component[0].DataType = IndComponentType_ClosePrice;
   Component[0].FirstBar = 2;
   ArrayResize(Component[0].Value,Data.Bars);
   ArrayCopy(Component[0].Value,closePrice);
  }
//+------------------------------------------------------------------+
