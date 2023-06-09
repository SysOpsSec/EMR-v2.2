/////  EMR

// Current Pending Update: Invalid Volume




#property copyright "Copyright 2021, Muso LLC"
#property link      "https://www.musollc.com"
#property version   "2.2"
input string             Expert_Title                  ="Exponetial Mean Revision"; // Document name
//+------------------------------------------------------------------------------------------------------------------------------------
//--- available trailing
//#include <Expert\Trailing\TrailingFixedPips.mqh>
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Expert\Expert.mqh>

CExpert ExtExpert;
CTrade         m_trade;
CPositionInfo  m_position;
CSymbolInfo    m_symbol;

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+

MqlDateTime mdt;
int eaMagic = 14;
string ObvTier;
//+------------------------------------------------------------------+
//| Initiate Global Variable's                                       |
//+------------------------------------------------------------------+

input group "Trading Inputs"
input double PercentageRiskPerTrade = 1.0; // 1.0 == 1% of Risk Per Trade
// Max Position Loss
input string t_tpl         = "TP/SL MANAGEMENT";   // =================================
double TpDist;                 // [0=no_use in Point ] Take Profit
double SlDist;                  // [0=no_use in Point ] Stop Loss
input bool Use_TralingStop=true;
input group "Trailing Stop Exact PIP Value"
double TralingStop_Start;
double TralingStop_Distance;
//
input group "Indicator Inputs"
input ENUM_TIMEFRAMES Ema200TimeFrame = PERIOD_CURRENT;
input string               t_time            = "TIME MANAGEMENT";       // =================================
input datetime             sess1start        = D'1970.01.01 01:00:00';  // [ Only Hour : Minute ] Start Session Time
input datetime             sess1end          = D'1970.01.01 22:00:00';  // [ Only Hour : Minute ] End Session Time
input bool                 Monday            = true;                 // Trade on Monday
input bool                 Tuesday           = true;                 // Trade on Tuesday
input bool                 Wednesday         = true;                 // Trade on Wednesday
input bool                 Thursday          = true;                 // Trade on Thursday
input bool                 Friday            = true;                 // Trade on Friday
bool Day_Trade=false, StartTrade=false;
double AlphaP1 = 1;
double AlphaP2 = AlphaP1*1.3;
double AlphaP3 = AlphaP1*1.6;
double AlphaN1 = -1;
double AlphaN2  = AlphaN1*1.3;
double AlphaN3 = AlphaN1*1.6;

//--------------------------------------------------------------------------------------------------------------------
double handleEMA10, handleEMA200, handleWEMA10, handleATR, handleRSI, handleMACD, handleMacdSignal;
int totalBars;
int numbbertrade=0;
bool MacdShort = false, MacdLong = false;

    // OBV Percentage Tier

//--------------------------------------------------------------
double blots, slots, bprofit, sprofit, tprofit, Buy_BE_Price, Sel_BE_Price, 
   Last_Price_Buy, Last_Price_Sell, Lasts_Lot_Buy, Lasts_Lot_Sell, totallots ;
int bpos, spos, totaltrades ;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------
int OnInit()
  {
//---
   m_trade.SetExpertMagicNumber(eaMagic);
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());


   handleEMA10 = iMA(_Symbol,PERIOD_CURRENT,10,0,MODE_EMA,PRICE_CLOSE);
   handleEMA200   = iMA(_Symbol,PERIOD_CURRENT,200,0,MODE_EMA,PRICE_CLOSE);
   handleWEMA10 = iMA(_Symbol,PERIOD_W1,10,0,MODE_EMA,PRICE_CLOSE);
   handleRSI      = iRSI(_Symbol,PERIOD_H4,14,PRICE_CLOSE);
   handleATR      = iATR(_Symbol,PERIOD_D1,19);
   handleMACD = iMACD(_Symbol,PERIOD_H4,12,26,9,PRICE_CLOSE);
 //handleMacdSignal = iMACD()
   
//--------------------------------------------------------------------------------------------------------------
//---
//EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------------------------------------------------------------------------
void OnDeinit(const int reason) {}
datetime itimees=0;
//+------------------------------------------------------------------------------------------------------------------------------------
void OnTick()   // OnTick
  {
  
   
   Manage_order() ;

   if(Use_TralingStop==true)
      Trail(TralingStop_Start,TralingStop_Distance);
       
  }//Completion of Ontick
//----------------------------------------------------------------------------------------------------------------------------------
void Manage_order(){
 
 
   double EMA10[], EMA200[], WEMA10[], RSI[], MACD[], ATR[], Delta, SignalBuffer[];
   CopyBuffer(handleEMA10,MAIN_LINE,0,6,EMA10);
   CopyBuffer(handleEMA200,MAIN_LINE,0,4,EMA200);
   CopyBuffer(handleATR,MAIN_LINE,0,2,ATR);
   CopyBuffer(handleWEMA10,MAIN_LINE,0,4,WEMA10);
   CopyBuffer(handleRSI,MAIN_LINE,0,4,RSI);
   CopyBuffer(handleMACD, MAIN_LINE, 0, 4, MACD);
   CopyBuffer(handleMACD,1,0,3,SignalBuffer);
   bool EmrLong = false, EmrShort = false, WeeklyEmrLong = false, 
      WeeklyEmrShort = false, WeeklyEmrNeutral = false;
   bool ObvT1 = false, ObvT2 = false, ObvT3 = false; 
   bool RsiShort = false,RsiLong = false;
   bool MacdLong = false, MacdShort = false;
   bool EmaLong = false, EmaShort = false;
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   TpDist = ATR[0]*10;
   SlDist = ATR[0]*2;
   TralingStop_Start = (ATR[0]*2)*10000;
   TralingStop_Distance = (ATR[0]*1)*10000;   
   double TradePercentage = ((Balance/101)*PercentageRiskPerTrade);   
   double TickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double TickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double PipValue = (TickValue/TickSize);   
   Delta = ((EMA10[4] - EMA200[2]) / EMA200[2]) * 100;
   double SlDnTs = SlDist/TickSize;
 
   double Lotsv2 = NormalizeDouble((TradePercentage/SlDnTs),2);
   
   Lotsv2 = MathMin(Lotsv2, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   Lotsv2 = MathMax(Lotsv2, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   
 //Print("EMA10[4],EMA200[2], and Delta is: ",EMA10[4],EMA200[2], Delta);  
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   if(WEMA10[0] < WEMA10[1] && WEMA10[1] < WEMA10[2]){
      WeeklyEmrLong = true;
   }else if(WEMA10[0] > WEMA10[1] && WEMA10[1] > WEMA10[2]){
      WeeklyEmrShort = true;
   }else{
      WeeklyEmrNeutral = true;
   }           
   
// For Loops for MACD[], RSI[],EMA[] ------------------------------------------------------
  int MACDArrSize = ArraySize(MACD);
  for(int i = 0; i < (MACDArrSize-1) ; i++){
            if(MACD[i] < MACD[i+1] ){
               MacdLong = true;
            }else if(MACD[i] > MACD[i+1]){
               MacdShort = true;
            }      
         } 
         
   int RSIArrSize = ArraySize(RSI);
   for(int i = 0; i < (RSIArrSize-1) ; i++){
            if(RSI[i] < RSI[i+1] ){
               RsiLong = true;
            }else if(RSI[i] > RSI[i+1]){
               RsiShort = true;
            }
         } 
         
   int EmaArrSize = ArraySize(EMA10);
   for(int i = 0; i < (EmaArrSize-1) ; i++){
            if(EMA10[i] < EMA10[i+1] ){
               EmaLong = true;
            }else if(EMA10[i] > EMA10[i+1]){
               EmaShort = true;
            }
         }        
// End of For Loops-------------------------------------------------------------------------------

// Percentage Trsde Functions ---------------------------------------------------------

string CurrentSymbol = _Symbol;
if(CheckVolumeValue(Lotsv2, CurrentSymbol)){

// Check for Equity Making Trades
   if(CheckMoneyForTrade(_Symbol,Lotsv2,ORDER_TYPE_BUY)||CheckMoneyForTrade(_Symbol,Lotsv2,ORDER_TYPE_SELL)){
   
// Long Trade +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      
      if(WeeklyEmrLong && pos_account() == 0){
       
            if(Delta > (AlphaP1+AlphaP1)){
               EmrShort = true;
            }else if(Delta < (AlphaN1+AlphaP1)){
               EmrLong = true;
               }
                        if(EmrShort){
               if(Delta > AlphaP3+AlphaP1){
                  ObvT3 = true;
               }else if(Delta > AlphaP2+AlphaP1){
                  ObvT2 = true;
               }else if(Delta > AlphaP1+AlphaP1){
                  ObvT1 = true;
                  }
              }// if EmrShort
            if(EmrLong){
               if(Delta < AlphaN3+AlphaP1){
                  ObvT3 = true;
               }else if(Delta < AlphaN2+AlphaP1){
                  ObvT2 = true;
               }else if(Delta < AlphaN1+AlphaP1){
                  ObvT1 = true;
               }
              }//if Emr Long
            //Long Trade
            if(EmrLong && EmaLong && RsiLong && MacdLong){
               Print(__FUNCTION__," Buy Signal...");
               Print("Weekly Long Buy Trade");
               
               if(ObvT3){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Long, ObvT3");
               }else if(ObvT2){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Long, ObvT2");
               }else if(ObvT1){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Long, ObvT1");
               }else{
                  Print("No Long Trade Taken, Delta is: ", Delta);
               }// If Emr Long Statement
            }      
            // Short Trade --------------------------------------------------------------------------------------
            if(EmrShort && EmaShort && RsiShort && MacdShort){
               Print(__FUNCTION__," > Sell Signal...");
               
               if(ObvT3){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                   Print("Sell Trade made on Weekly Long, ObvT3");
               }else if(ObvT2){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                   Print("Sell Trade made on Weekly Long, ObvT2");
               }else if(ObvT1){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                   Print("Sell Trade made on Weekly Long, ObvT1");
               }else{
                  Print("No Short Trade Taken, Delta is: ", Delta);
               }
            }// If Emr Short Statement
            
      }
   // Weekly EMR Neutral Buy and Sell Trade
   
      if(WeeklyEmrNeutral && pos_account() == 0){
            // EMR Positive or Negative
         if(Delta > AlphaP1){
            EmrShort = true;
         }else if(Delta < AlphaN1){
            EmrLong = true;
            }
         
         if(EmrShort){
            if(Delta > AlphaP3){
               ObvT3 = true;
            }else if(Delta > AlphaP2){
               ObvT2 = true;
            }else if(Delta > AlphaP1){
               ObvT1 = true;
               }
           }// if EmrShort
         if(EmrLong){
            if(Delta < AlphaN3){
               ObvT3 = true;
            }else if(Delta < AlphaN2){
               ObvT2 = true;
            }else if(Delta < AlphaN1){
               ObvT1 = true;
            }
           }//if Emr Long
         
         if(EmrLong && EmaLong && RsiLong && MacdLong){
         
               Print(__FUNCTION__," Buy Signal...");
               Print("Weekly Neutral Buy Trade");
         
               if(ObvT3){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Neutral, ObvT3");
               }else if(ObvT2){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Neutral, ObvT2");
               }else if(ObvT1){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Neutral, ObvT1");
               }else{
                  Print("No Long Trade Taken, Delta is: ", Delta);
               }// If Emr Long Statement
            }      
            // Short Trade --------------------------------------------------------------------------------------
            if(EmrShort && EmaShort && RsiShort && MacdShort ){
            
               Print(__FUNCTION__," > Sell Signal...");
            
               if(ObvT3){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                  Print("Sell Trade made on Weekly Neutral, ObvT3");
               }else if(ObvT2){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                  Print("Sell Trade made on Weekly Neutral, ObvT2");
               }else if(ObvT1){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                  Print("Sell Trade made on Weekly Neutral, ObvT1");
               }else{
                  Print("No Short Trade Taken, Delta is: ", Delta);
               }
            }// If Emr Short Statement      
      }
      //If Weekly Short Function  
      if(WeeklyEmrShort&& pos_account() == 0){
         
         if(Delta > (AlphaP1-AlphaP1)){
               EmrShort = true;
            }else if(Delta < (AlphaN1-AlphaP1)){
               EmrLong = true;
               }
            
            if(EmrShort){
               if(Delta > AlphaP3-AlphaP1){
                  ObvT3 = true;
               }else if(Delta > AlphaP2-AlphaP1){
                  ObvT2 = true;
               }else if(Delta > AlphaP1-AlphaP1){
                  ObvT1 = true;
                  }
              }// if EmrShort
            if(EmrLong){
               if(Delta < AlphaN3-AlphaP1){
                  ObvT3 = true;
               }else if(Delta < AlphaN2-AlphaP1){
                  ObvT2 = true;
               }else if(Delta < AlphaN1-AlphaP1){
                  ObvT1 = true;
               }
              }//if Emr Long
         
         //Long Trade
         if(EmrLong && EmaLong && RsiLong && MacdLong){
               Print(__FUNCTION__," Buy Signal...");
               Print("Weekly Short Buy Trade");
               if(ObvT3){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Short, ObvT3");
               }else if(ObvT2){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Short, ObvT2");
               }else if(ObvT1){
                  m_trade.Buy(Lotsv2,_Symbol,ask,ask-(SlDist),ask+TpDist,"This is a Long Trade");
                  Print("Buy Trade made on Weekly Short, ObvT1");
               }else{
                  Print("No Long Trade Taken, Delta is: ", Delta);
               }// If Emr Long Statement
            }      // Short Trade --------------------------------------------------------------------------------------
            
            //Short Trade
            if(EmrShort && EmaShort && RsiShort && MacdShort){
               Print(__FUNCTION__," > Sell Signal...");
               if(ObvT3){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                  Print("Sell Trade made on Weekly Short, ObvT3");
               }else if(ObvT2){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                  Print("Sell Trade made on Weekly Short, ObvT2");
               }else if(ObvT1){
                  m_trade.Sell(Lotsv2,_Symbol,bid,bid+SlDist,bid-TpDist,"This is a Sell Trade");
                  Print("Sell Trade made on Weekly Short, ObvT1");
               }else{
                  Print("No Short Trade Taken, Delta is: ", Delta);
               }
            }// If Emr Short Statement
         }
         
               
      // Comment Section
         if(ObvT3){
            ObvTier = "Current OBV Tier is 3";
         }else if(ObvT2){
            ObvTier = "Current OBV Tier is 2";
         }else if(ObvT1){
            ObvTier = "Current OBV Tier is 1";
         }
         string WeeklyEmrStatus;
         if(WeeklyEmrLong){
            WeeklyEmrStatus = "Weekly Emr is Long";
         }else if(WeeklyEmrShort){
            WeeklyEmrStatus = "Weekly Emr is Short";
         }else if(WeeklyEmrNeutral){
            WeeklyEmrStatus = "Weekly Emr is Neutral";
         }
         string HourlyEmr;
         if(EmrLong){
            HourlyEmr =  "Hourly EMR is Long";
         }else if(EmrShort){
            HourlyEmr = "Hourly EMR is Short";
         }
      
         Comment("\nWEMA10: ", WeeklyEmrStatus,
                 "\nOBV: ", ObvTier,
                 "\nCurrent Delta: ", Delta,
                 "\n1H: ", HourlyEmr,
                 "\nMACD[1]: ", MACD[1],
                 "\nMACD Signal[1]: ", SignalBuffer[1],
                 "\n","EMA10:  "+DoubleToString(EMA10[4],_Digits),
                 "\n","EMA200:  "+DoubleToString(EMA200[2],_Digits),
                 "\n","Delta :  "+DoubleToString(Delta,2)
                );
                
         WeeklyEmrLong = false;
         WeeklyEmrShort = false;
         WeeklyEmrNeutral = false;
         EmrShort=false;
         EmrLong=false;      
       }// Manage Order Function
   }
} 
 

//+------------------------------------------------------------------+

void CheckTime(){
   MqlDateTime currTime;
   TimeToStruct(TimeCurrent(),currTime);
   int time_current=currTime.hour*3600+currTime.min*60+currTime.sec;
   if(Monday      ==true && currTime.day_of_week==1){
      Day_Trade=true;
   }else if(Tuesday     ==true && currTime.day_of_week==2){
      Day_Trade=true;
   }else if(Wednesday   ==true && currTime.day_of_week==3){
      Day_Trade=true;
   }else if(Thursday    ==true && currTime.day_of_week==4){
      Day_Trade=true;
   }else if(Friday      ==true && currTime.day_of_week==5){
      Day_Trade=true;
   }else{
      Day_Trade=false;
   }
//---
   MqlDateTime OpenOne;
   TimeToStruct(sess1start,OpenOne);
   int start_one  = OpenOne.hour*3600+OpenOne.min*60;
   MqlDateTime EndOne;
   TimeToStruct(sess1end,EndOne);
   int end_one    = EndOne.hour*3600+EndOne.min*60;
   if(time_current >= start_one && time_current <= end_one){
      StartTrade=true;
   }else{
      StartTrade=false;
   }
  }
  
//================================================

//==================================
/*
bool isNewBar(string sym)
  {
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCur rent;
   dtBarCurrent=(datetime) SeriesInfoInteger(sym,PERIOD_H1,SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
      return(true);
   else
      return (false);
   return (false);
  }
  */
//+----------------------------------------------------------------------------------------------------------------------------------

//+------------------------------------------------------------------+
void Trail(double break0,double break1)
  {
   CTrade *Mymodifytr;
   Mymodifytr=new CTrade;

   int pos=PositionsTotal();
   int num=0;
   for(int i=0; i < pos; i++)
     {
      ulong tiket=PositionGetTicket(i);
      string symbol=PositionGetString(POSITION_SYMBOL);
      long Macik=PositionGetInteger(POSITION_MAGIC);
      double volume=PositionGetDouble(POSITION_VOLUME);
      double profit=PositionGetDouble(POSITION_PROFIT);
      long typee=PositionGetInteger(POSITION_TYPE);
      double openprice=PositionGetDouble(POSITION_PRICE_OPEN);
      double stoploss=PositionGetDouble(POSITION_SL);
      double takepro=PositionGetDouble(POSITION_TP);
      if(symbol == Symbol() && Macik == eaMagic)
        {
         if(typee == POSITION_TYPE_BUY)
           {
            if(SymbolInfoDouble(Symbol(),SYMBOL_BID) > openprice+(10*break0*Point()))
              {
               if(NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID)-(10*break1*Point()),Digits()) > stoploss || stoploss == 0)
                 {
                  Mymodifytr.PositionModify(tiket,NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID)-(10*break1*Point()),Digits()),takepro);
                 }
              }
           }
         /////
         if(typee == POSITION_TYPE_SELL)
           {
            if(SymbolInfoDouble(Symbol(),SYMBOL_ASK) < openprice-(10*break0*Point()))
              {
               if(NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK)+(10*break1*Point()),Digits()) < stoploss || stoploss == 0)
                 {
                  Mymodifytr.PositionModify(tiket,NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK)+(10*break1*Point()),Digits()),takepro);}}}}}
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int pos_account(){
   int pos=PositionsTotal();
   int num=0;
   for(int i=0; i < pos; i++)
     {
      ulong tiket=PositionGetTicket(i);
      string symbol=PositionGetString(POSITION_SYMBOL);
      long Macik=PositionGetInteger(POSITION_MAGIC);
      if(symbol == Symbol()){
         num++;
         break;
        }
     }
   return(num);
  }
//+------------------------------------------------------------------+
//|   spread filter                                                  |
//+------------------------------------------------------------------+


bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
//--- checking successful
   return(true);
  } // Check Money for Trade Function Complete


//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                               volume_step,ratio*volume_step);
      return(false);
     }
   description="Correct volume value";
   return(true);
  }