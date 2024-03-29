//+------------------------------------------------------------------+
//|                                           CodeLocus_VP_Range.mq5 |
//|                           Copyright 2021, Eriks Karlis Sedvalds. |
//|                         https://www.mql5.com/en/users/magiccoder |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Eriks Karlis Sedvalds."
#property link      "https://www.mql5.com/en/users/magiccoder"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

enum vp_level_range //Points
{  
	range_1 = 1,      // 1 Point
	range_2 = 2,      // 2 Points
	range_4 = 4,      // 4 Points
	range_6 = 6,      // 6 Points
	range_8 = 8,      // 8 Points
	range_10 = 10,    // 10 Points
	range_20 = 20,    // 20 Points
	range_30 = 30,    // 30 Points
	range_40 = 40,    // 40 Points
	range_50 = 50,    // 50 Points
	range_60 = 60,    // 60 Points
	range_70 = 70,    // 70 Points
	range_80 = 80,    // 80 Points
	range_90 = 90,    // 90 Points
	range_100 = 100,  // 100 Points
	range_200 = 200,  // 200 Points
	range_300 = 300,  // 300 Points
	range_400 = 400   // 400 Points
	
};

enum vp_input_data
{
	input_data_ticks = 0,   // Tick
	input_data_M1 = 1,      // M1 
	input_data_M5 = 5,      // M5 
	input_data_M15 = 15,    // M15
	input_data_M30 = 30,    // M30
	input_data_H1 = 60      // H1
};

enum vp_position
{
	window_left = 0,    // Window Left
	window_right = 1,   // Window Right
	inside_left = 2,    // Inside Left
	inside_right = 3    // Inside Right
};

input vp_input_data check_refresh_rate = input_data_M1;        //Indicator Refresh Rate
input string check_vp_prefix = "CodeLocus_VP_Range_0";         // Object Name Prefix
input vp_level_range check_vp_level_range = 10;                // VP Level Range (Points)
input vp_input_data check_vp_data = input_data_M1;             // Input Data
input vp_position check_vp_position = window_right;            // VP Visual Positioning
input int check_vp_line_width = 1;                             // Level Line Width
input color check_vp_color = clrMidnightBlue;                  // VP Level Color
input color check_vp_range_color = clrRed;                     // Range Line Color

string prefLevels = check_vp_prefix+"_Levels_";
string prefRange = check_vp_prefix+"_Range_";
ENUM_TIMEFRAMES check_input_tf = 0;
datetime last_range_start, last_range_stop;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   ChartSetInteger(0,CHART_EVENT_OBJECT_DELETE,true);//Enable Delete event to check if vertical range lines have been deleted
   
   //Print(getDataLimitTime());
   
   createDataLimitLine();

   
   //CREATE RANGE LINES AND CALCUALTE VP
   if(check_vp_data!=input_data_ticks)
      {
      setInputDataTimeframe();
      }
   if(PeriodSeconds()/60<check_vp_data)
      {
      Alert("Current timeframe(TF) is smaller than input TF.");
      Alert("Please change TF or input parameter - Input Data.");
      return (INIT_FAILED);
      }
      
      
      
      
      
   bool indicator_initialized= false;
   if(ObjectFind(0,prefRange+"Line_1")>=0&&ObjectFind(0,prefRange+"Line_2")>=0)
      {
      //Print(123123123);
      indicator_initialized=true;
      
      initLastRangeTime(); //after indi removal last range time values are set to 0, we need to update that
      }  
      
   if(!indicator_initialized)
      {
      if(!rangeCreate())return(INIT_FAILED);
      if(!vpCreate())return(INIT_FAILED);
      }
   
   //Print("start time: ",last_range_start);
     // Print("stop time: ",last_range_stop);
   
   //sleepIndicator(1);
   return(INIT_SUCCEEDED);
  }
  
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
   {
 
   if(id==CHARTEVENT_OBJECT_DELETE&&(sparam==prefRange+"Line_1"||sparam==prefRange+"Line_2"))
      {
      
      createNewRangeLine(sparam); 
      ObjectsDeleteAll(0,prefLevels);
      vpCreate();
      ChartRedraw();
      
     // Print("start time: ",last_range_start);
      //Print("stop time: ",last_range_stop);
      }
   else if((id==CHARTEVENT_OBJECT_DRAG ||id==CHARTEVENT_OBJECT_CHANGE)&&
      (sparam==prefRange+"Line_1"||sparam==prefRange+"Line_2"))
      {
      createDataLimitLine();
      ObjectsDeleteAll(0,prefLevels);
      updateRangeLines(sparam);
      vpCreate();
      ChartRedraw();
      
     // Print("start time: ",last_range_start);
     // Print("stop time: ",last_range_stop);
      
      }
   else if(id==CHARTEVENT_CHART_CHANGE)
      {
      createDataLimitLine();
      ObjectsDeleteAll(0,prefLevels);
      updateRangeStart();
      vpCreate();
      ChartRedraw();
      
     // Print("start time: ",last_range_start);
     // Print("stop time: ",last_range_stop);
      }
   
   }
   
void OnTimer()
   {

   }

void OnDeinit(const int reason)
   {
   
   if(reason!=REASON_CHARTCHANGE&&reason!=REASON_PARAMETERS)
      {
      ObjectsDeleteAll(0,prefLevels);
      ObjectsDeleteAll(0,prefRange);
      }
   ChartRedraw();
   } 



int OnCalculate(const int rates_total,     // price[] array size  
                const int prev_calculated, // number of previously handled bars 
                const int begin,           // where significant data start from  
                const double &price[])     // value array for handling 
  { 
   
   if(check_refresh_rate==0)
      {
      
      ObjectsDeleteAll(0,prefLevels);
      vpCreate();
      ChartRedraw();
      }
   else if(newCandle())
      {
      //Print(312312);
      
      ObjectsDeleteAll(0,prefLevels);
      vpCreate();
      ChartRedraw();
      }
   return(rates_total);
  }
//+------------------------------------------------------------------+

datetime last;
bool newCandle()
   {
   datetime tim = iTime(_Symbol,check_input_tf,0);
   if(TimeCurrent()>=datetime(tim)+13)
      {
      if(tim!=last)
      {
      last=tim;
      return true;
      }
      else return false;
      }
   return false;
   }
   
bool rangeCreate()
   {
   
   string name0 = prefRange+"Line_1";
   string name1 = prefRange+"Line_2";
   if(ObjectFind(0,name0)<0||ObjectFind(0,name1)<0)//check if objects are created, if they are then there is no need to redraw them
      {
      datetime limitLineTime = ObjectGetInteger(0,prefRange+"Limit_Line",OBJPROP_TIME);
      int limitBar = iBarShift(_Symbol,PERIOD_CURRENT,limitLineTime);
      
      int firstBar = int(ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR));
      int widthBars = int(ChartGetInteger(0,CHART_WIDTH_IN_BARS));
      
      int start_bar = firstBar-(widthBars/3);
      int stop_bar = start_bar-(widthBars/3);
 
      
      //use bars rather than time to shift line(to skip weekend time)
      //use limit line bar so there are no errors when indicator is attached (0 data selected error)
      
      if(limitBar<3)
         {
         start_bar=0;
         stop_bar =0;
         }
      else if(start_bar>=limitBar)
         {
         start_bar=limitBar-1;
         if(stop_bar>=limitBar)  
            {
            stop_bar=limitBar-2;
            }
         }
     //making adjustments so range lines can appear into the future as well    
     if(start_bar<0)
         {
         start_bar=0;
         }
      
      
      datetime time0 = iTime(_Symbol,PERIOD_CURRENT,start_bar);
      datetime time1;// = iTime(_Symbol,PERIOD_CURRENT,stop_bar)+PeriodSeconds()-1;
      
       //making adjustments so range lines can appear into the future as well -------------------- 
      if(stop_bar<0)
         {
         time1 = iTime(_Symbol,PERIOD_CURRENT,0)-stop_bar*PeriodSeconds()+PeriodSeconds()-1;
         }
      else 
         {
         time1 = iTime(_Symbol,PERIOD_CURRENT,stop_bar)+PeriodSeconds()-1;
         }
      //---------------------------------------------------------------------------------------------

      if(vLineCreate(0,name0,0,time0,check_vp_range_color)&&vLineCreate(0,name1,0,time1,check_vp_range_color))
         {
         last_range_start=time0;
         last_range_stop=time1;
         return true;
         }
      else
         {
         ObjectsDeleteAll(0,prefRange);
         return false;
         }
      }
   else 
      {
      return true;
      }
      
   
   } 
void  createNewRangeLine(string name)
   {

   datetime time;
   
   string nameCheck = prefRange+"Line_1";
   if(name==nameCheck)nameCheck=prefRange+"Line_2";
   datetime timeCheck = ObjectGetInteger(0,nameCheck,OBJPROP_TIME);
   
   
   if(timeCheck<last_range_stop)
      {
      //time = time+PeriodSeconds()-1;
      //timeCheck = iTime(_Symbol,PERIOD_CURRENT,iBarShift(_Symbol,PERIOD_CURRENT,timeCheck));
      time=last_range_stop;
      //last_range_start = timeCheck;
      //last_range_stop =  time;
      }
   else
      {
      //timeCheck = iTime(_Symbol,PERIOD_CURRENT,iBarShift(_Symbol,PERIOD_CURRENT,timeCheck))+PeriodSeconds()-1;
      time=last_range_start;
      //last_range_start = time;
      //last_range_stop =  timeCheck;
      }
   
   if(!vLineCreate(0,name,0,time,check_vp_range_color))
      {
      Print("Failed to replace deleted object: "+name);
      }
   else if(!ObjectSetInteger(0,nameCheck,OBJPROP_TIME,timeCheck))
      {
      Print("Failed to adjust range line after range line was deleted.");
      }
      
   

   }
   
bool vpCreate()
   {
   double volumeData[];
   double rangeLow,rangeHigh;
   
   
   if(check_vp_data==input_data_ticks)
      {
      if(!getVpTickData(volumeData,rangeLow,rangeHigh))
         {
         return false;
         }
      else
         {
         if(!drawVp(volumeData,rangeLow,rangeHigh))
            {
            return false;
            }
         }
      }
   else
      {
      if(!getVpData(volumeData,rangeLow,rangeHigh))
         {
         return false;
         }
      else 
         {
         if(!drawVp(volumeData,rangeLow,rangeHigh))
            {
            return false;
            }
         }
      
      }
      
   
   return true;
   } 
   
bool getVpData(double &volumes[], double &rangeLow, double &rangeHigh)
   {
   MqlRates rates[];
   datetime start_time, stop_time;//used to get rates
   setRangeTime(start_time,stop_time);
   
	int rateCount;// = CopyRates(_Symbol,check_input_tf, start_time, stop_time, rates);
	
	int i=0;
	while(i<9)
	   { 
	   rateCount = CopyRates(_Symbol,check_input_tf, start_time, stop_time, rates);
	   if(rateCount<0)
	      {
	      i++;
	      sleepIndicatorMilisec(333);
	      }
	   else break;
	   
	   }
	
	if (rateCount < 0)
	   {
	   Print("Failed to copy rates from "+TimeToString(start_time)+" to "+TimeToString(stop_time));
	   Print("Error: ",errorMeaning(GetLastError()));
		return false;
	   }
	else if(rateCount==0)
	   {
	   Print("Failed to copy rates from "+TimeToString(start_time)+" to "+TimeToString(stop_time));
	   Print("Please adjust range lines, 0 data selected.");
	   return false;
	   }
	/*if(rateCount<0)
	   {
	   Print("Failed to copy rates");
	   return false;
	   }
	else if(rateCount==0)
	   {
	   Print("Failed to copy rates");
	   Print("Please adjust range lines, 0 data selected.");
	   return false;
	   }*/
	
	   
   int start_bar = iBarShift(_Symbol,check_input_tf,stop_time);
	rangeLow = iLow(_Symbol,check_input_tf,iLowest(_Symbol,check_input_tf,MODE_LOW,rateCount,start_bar));
	rangeHigh = iHigh(_Symbol,check_input_tf,iHighest(_Symbol,check_input_tf,MODE_HIGH,rateCount,start_bar));
   //Print(iTime(_Symbol,check_input_tf,iHighest(_Symbol,check_input_tf,MODE_HIGH,rateCount,start_bar)));
	double rangeSize = MathRound((rangeHigh-rangeLow+_Point)/_Point);//Adding +1 point so the point count is correct 123-123=0 but candle range is 1 Point

	if(rangeSize<int(check_vp_level_range))
	   {
	   Print("Range size is smaller than level range. Please adjust range lines or change level range input parameter.");
	   return false;
	   }

	ArrayResize(volumes,int(rangeSize));
	ArrayInitialize(volumes, 0);
   //Print(rangeLow);
   //Print(rangeHigh);
	for(int i=0;i<rateCount;i++)
	   {
	   double candlePointCount = MathRound((rates[i].high-rates[i].low+_Point)/_Point);//Adding +1 point so the point count is correct 123-123=0 but candle range is 1 Point
	   int pointVol = int(MathRound(rates[i].tick_volume/candlePointCount));
	   
	   int levelLow = MathRound((rates[i].low - rangeLow)/_Point);
	   int levelHigh = MathRound((rates[i].high - rangeLow)/_Point);
	   //Print((rangeHigh-rangeLow)/_Point);
	   //Print(ArraySize(volumes));
	   //Print(rangeLow);
	   //Print(rates[0].time);
	   for(int j=levelLow;j<=levelHigh;j++)//Give each point level in candle the same amount of volume
	      {
	      volumes[j]+=pointVol;
	      }
	   }
   return true;
   }
   
bool getVpTickData(double &volumes[], double &rangeLow, double &rangeHigh)
   {
   datetime start_time, stop_time;//used to get rates
   setRangeTime(start_time,stop_time);
   //if(start_time)
   
   MqlTick ticks[];
	int tickCount;// = CopyTicksRange(_Symbol,ticks,COPY_TICKS_ALL,start_time*1000,stop_time*1000);
	
	int i=0;
	while(i<9)
	   { 
	   tickCount = CopyTicksRange(_Symbol,ticks,COPY_TICKS_ALL,start_time*1000,stop_time*1000);
	   if(tickCount<0)
	      {
	      i++;
	      sleepIndicatorMilisec(333);
	      }
	   else break;
	   
	   }
	
	if (tickCount < 0)
	   {
	   Print("Failed to copy ticks from "+TimeToString(start_time)+" to "+TimeToString(stop_time));
	   Print("Error: ",errorMeaning(GetLastError()));
		return false;
	   }
	else if(tickCount==0)
	   {
	   Print("Failed to copy ticks from "+TimeToString(start_time)+" to "+TimeToString(stop_time));
	   Print("Please adjust range lines, 0 data selected.");
	   return false;
	   }
	
	rangeHigh=ticks[0].bid;
	rangeLow=ticks[0].bid;
	for(int i=0;i<tickCount;i++)
	   {
	   if(ticks[i].bid>rangeHigh)
	      {
	      rangeHigh= ticks[i].bid;
	      }
	   else if(ticks[i].bid<rangeLow)
	      {
	      rangeLow = ticks[i].bid;
	      }
	   }
	double rangeSize = MathRound((rangeHigh-rangeLow+_Point)/_Point);

	
	
	
	//Print(rates[0].time);
	//Print(rates[rateCount-1].time);
  //Print(rangeLow);
  // Print(rangeHigh);
   //Print(rateCount);//iTime(_Symbol,PERIOD_CURRENT,iBarShift(_Symbol,PERIOD_CURRENT,stop_time)));
	if(rangeSize<=int(check_vp_level_range))
	   {
	   Print("Range size is smaller than level range. Please adjust range lines or change level range input parameter.");
	   return false;
	   }
	   
	ArrayResize(volumes,int(rangeSize));
	ArrayInitialize(volumes, 0);
	
	//Print(rangeHigh);
	//Print(rangeLow);
	 //Print(ticks[0].time);
	//int aboveHigh =0;
	//int belowLow = 0;
	//Print(ticks[0].time);
	//Print(ticks[tickCount-1].time);
	int levelHigh  = MathRound((rangeHigh - rangeLow)/_Point);
	//Print(ticks[tickCount-1].time);
	for(int i=0;i<tickCount;i++)
	   {
	   int levelBid;
	   
      levelBid = MathRound((ticks[i].bid - rangeLow)/_Point);

	   volumes[levelBid]++;

	   }
	   
   return true;
   }   
   
bool vLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="VLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 datetime              time=0,            // line time 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_DOT, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            ray=false,          // line's continuation down 
                 const bool            hidden=false,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  { 
//--- if the line time is not set, draw it via the last bar 
   if(!time) 
      time=TimeCurrent(); 
//--- reset the error value 
   ResetLastError(); 
//--- create a vertical line 
   if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a vertical line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- enable (true) or disable (false) the mode of displaying the line in the chart subwindows 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY,ray); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  }
  
void setInputDataTimeframe() 
   {
   switch (check_vp_data)
	   {
		case input_data_M1:    
	      check_input_tf = PERIOD_M1;
		   break;
		case input_data_M5:
		   check_input_tf = PERIOD_M5;
		   break;
		case input_data_M15:   
		   check_input_tf = PERIOD_M15;
		   break;
		case input_data_M30:   
		   check_input_tf = PERIOD_M30;
		   break;
		case input_data_H1:   
		   check_input_tf = PERIOD_H1;
		   break;
		default:              
		   check_input_tf = PERIOD_M1;
		   break;
	   }
   }
   
void setRangeTime(datetime &start_time, datetime &stop_time)
   {
   string name0 = prefRange+"Line_1";
   string name1 = prefRange+"Line_2";
   
   start_time=datetime(ObjectGetInteger(0,name0,OBJPROP_TIME));
   stop_time=datetime(ObjectGetInteger(0,name1,OBJPROP_TIME));
   
   if(ObjectFind(0,name0)<0||ObjectFind(0,name1)<0)
      {
      Print("range line does not exists");
      }
   
   if(int(start_time)<1)
      {
      Print("Failed to get range line "+name0+" time.");
      }
   if(int(stop_time)<1)
      {
      Print("Failed to get range line "+name1+" time.");
      }
 
  
   if(start_time>stop_time)
      {
      datetime temptime = start_time;
      start_time=stop_time;
      stop_time=temptime;
      }
      
   }
   
   
void drawLevel(string name, double level, datetime timeFrom, datetime timeTo, color clr)
   {
   bool back=false;
   trendCreate(0,name,0,timeFrom,level,timeTo,level,clr,STYLE_SOLID,check_vp_line_width,back);
   }
   
bool trendCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="TrendLine",  // line name 
                 const int             sub_window=0,      // subwindow index 
                 datetime              time1=0,           // first point time 
                 double                price1=0,          // first point price 
                 datetime              time2=0,           // second point time 
                 double                price2=0,          // second point price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=false,    // highlight to move 
                 const bool            ray_left=false,    // line's continuation to the left 
                 const bool            ray_right=false,   // line's continuation to the right 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  { 
//--- set anchor points' coordinates if they are not set 
   //ChangeTrendEmptyPoints(time1,price1,time2,price2); 
//--- reset the error value 
   ResetLastError(); 
//--- create a trend line by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_TREND,sub_window,time1,price1,time2,price2)) 
     { 
      Print(__FUNCTION__, 
            ": failed to create a trend line! Error code = ",GetLastError()); 
      return(false); 
     } 
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr); 
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style); 
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width); 
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back); 
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection); 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection); 
//--- enable (true) or disable (false) the mode of continuation of the line's display to the left 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_LEFT,ray_left); 
//--- enable (true) or disable (false) the mode of continuation of the line's display to the right 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY_RIGHT,ray_right); 
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden); 
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order); 
//--- successful execution 
   return(true); 
  } 
//+------------------------------------------------------------------+
  
double levelRound(double level)
   {
   if(int(check_vp_level_range)>1)
      {
      level = MathRound(level/_Point/int(check_vp_level_range));
      level = level*int(check_vp_level_range)*_Point;
      return(NormalizeDouble(level,_Digits));
      }
   else
      {
      return(NormalizeDouble(level,_Digits));
      }
   }
   
bool drawVp(double &volumes[], const double rangeLow, const double rangeHigh)
   {
   color col_Line = check_vp_color;
   datetime timeFrom,timeTo;
   int volSize = ArraySize(volumes);
   int chartWidthBars = int(ChartGetInteger(0,CHART_WIDTH_IN_BARS));
   int profileWidth;
   int barFrom;
   //TimeFrom TimeTo later will be used to calulated range in time and set direction 
   //positive time = draw left to right
   //negative time = draw right to left
   //Thats why vaues in variables must be correctly assigned
   if(check_vp_position==window_right)
      {
      int chartFirstBar = int(ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR));
      barFrom=chartFirstBar-chartWidthBars;
      profileWidth = chartWidthBars/-5;
      }
   else if(check_vp_position==window_left)
      {
      barFrom = int(ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR));
      profileWidth = chartWidthBars/5;
      }
   else if(check_vp_position==inside_left)
      {
      setRangeTime(timeFrom,timeTo);//range start end times
      barFrom= iBarShift(_Symbol,PERIOD_CURRENT,timeFrom);
      int bTo;
      datetime time0 = iTime(_Symbol,PERIOD_CURRENT,0);
      if(timeTo>time0)
         {
         bTo= -MathRound((int(timeTo)-int(time0))/PeriodSeconds());
         
         }
      else
         {
         bTo= iBarShift(_Symbol,PERIOD_CURRENT,timeTo);
         }
      profileWidth=barFrom-bTo;
      }
   else if(check_vp_position==inside_right)
      {
      setRangeTime(timeTo,timeFrom);//range start end times
      int bTo;
      datetime time0 = iTime(_Symbol,PERIOD_CURRENT,0);
      if(timeFrom>time0)
         {
         barFrom= -MathRound((int(timeFrom)-int(time0))/PeriodSeconds());
         
         }
      else
         {
         barFrom= iBarShift(_Symbol,PERIOD_CURRENT,timeFrom);
         }
      /*if(timeTo>time0)
         {
         bTo = int((timeFrom-time0)/PeriodSeconds()/60);
         }
      else
         {
         bTo = iBarShift(_Symbol,PERIOD_CURRENT,timeTo);
         }*/
      bTo = iBarShift(_Symbol,PERIOD_CURRENT,timeTo);
      profileWidth=barFrom-bTo;
      }
   
      
      
   //Print(timeFrom);
   //Print(timeTo);
       

   if(int(check_vp_level_range)>1)
      {
      for(int i=0;i<volSize;i++)//loop for profile level width resizing
         {
         double rangeLevel = levelRound(rangeLow+i*_Point);
         
         if(rangeLevel<rangeLow)//check if rounded price is not lower than range low point
            {
            rangeLevel+=int(check_vp_level_range)*_Point;
            }
         else if(rangeLevel>rangeHigh) //check if rounded price is not higher than range high point
            {
            rangeLevel-=int(check_vp_level_range)*_Point;
            }
         
         int lvl = int(MathRound((rangeLevel-rangeLow)/_Point));

         
         if(i!=lvl)//check if they dont match else lvl will be == 0
            {
            volumes[lvl]+=volumes[i];
            volumes[i]=0;
            }
            
         

         }
      }
   
   
   double maxVol = volumes[ArrayMaximum(volumes)];
   double volumeBars = profileWidth/maxVol;
   int barTo=0;
   for(int i=0;i<volSize;i++)
      {
      
      if(volumes[i]==0)continue;
      
      double rangeLevel=rangeLow+i*_Point;
      barTo = int(barFrom-MathRound(volumeBars*volumes[i]));
  
      if(barFrom<0)
         {
         timeFrom = iTime(_Symbol,PERIOD_CURRENT,0)-PeriodSeconds()*barFrom;// - perSec because bar from is negative and we want a + sign
         }
      else
         {
         timeFrom = iTime(_Symbol,PERIOD_CURRENT,barFrom);
         }
      if(barTo<0)
         {
         timeTo = iTime(_Symbol,PERIOD_CURRENT,0)-PeriodSeconds()*barTo;// - perSec because bar from is negative and we want a + sign
         }
      else 
         {
         timeTo = iTime(_Symbol,PERIOD_CURRENT,barTo);
         }
         
      string nameLvl = prefLevels+DoubleToString(rangeLevel,_Digits)+"_volume_"+IntegerToString(int(volumes[i]));
      drawLevel(nameLvl,rangeLevel,timeFrom,timeTo,check_vp_color);
      
      }
      
   return true;
   }
   

void updateRangeLines(string nameMoved)
   {   
   
   string name0 = prefRange+"Line_1";
   string name1 = prefRange+"Line_2";
   string nameLimit = prefRange+"Limit_Line";
   
   
   string nameCheck = prefRange+"Line_1";
   if(nameMoved==nameCheck)nameCheck=prefRange+"Line_2";
   datetime timeCheck = datetime(ObjectGetInteger(0,nameCheck,OBJPROP_TIME));
   datetime timeMoved = datetime(ObjectGetInteger(0,nameMoved,OBJPROP_TIME));
   
   datetime timeLimit = datetime(ObjectGetInteger(0,nameLimit,OBJPROP_TIME));
   
   
  
   if(int(timeCheck)<1)
      {
      Print("range update:Failed to get range line "+nameCheck+" time.");
      }
   if(int(timeMoved)<1)
      {
      Print("range update:Failed to get range line "+nameMoved+" time.");
      }
   if(int(timeLimit)<1)
      {
      Print("range update:Failed to get range line "+nameLimit+" time.");
      }
   
   
   //check if moved line is not moved past limit line
   if(timeMoved<=timeLimit)
      {
      timeMoved=iTime(_Symbol,PERIOD_CURRENT,iBarShift(_Symbol,PERIOD_CURRENT,timeLimit)-1);
      }
   //Print(timeMoved);
      
   if(timeCheck==last_range_start)
      {
      if(timeCheck<=timeMoved)
         {
         //adjust time moved
         timeMoved=timeMoved+PeriodSeconds()-1;
         }
      else
         {
         //adjust only time check
         timeCheck=timeCheck+PeriodSeconds()-1;
         }
      }   
   else if(timeCheck==last_range_stop)
      {
      if(timeCheck<timeMoved)
         {
         timeMoved = timeMoved+PeriodSeconds()-1;
         timeCheck = iTime(_Symbol,PERIOD_CURRENT,iBarShift(_Symbol,PERIOD_CURRENT,timeCheck));
         //adjust both
         }
      //else do nothing
      }
   else
      {
      Print("range time check was not verified");
      }
         
    
   if(!(ObjectSetInteger(0,nameCheck,OBJPROP_TIME,timeCheck)&&ObjectSetInteger(0,nameMoved,OBJPROP_TIME,timeMoved)))
      {
      Print("Failed to adjust range lines");
      }
   
   if(timeCheck>timeMoved)
      {
      last_range_start = timeMoved;
      last_range_stop = timeCheck; 
      }
   else
      {
      last_range_start = timeCheck;
      last_range_stop = timeMoved;
      }

   }
   
void initLastRangeTime()
   {
   string name0 = prefRange+"Line_1";
   string name1 = prefRange+"Line_2";
   
   datetime start_time=datetime(ObjectGetInteger(0,name0,OBJPROP_TIME));
   datetime stop_time=datetime(ObjectGetInteger(0,name1,OBJPROP_TIME));
   
   if(start_time>stop_time)
      {
      last_range_start = stop_time;
      last_range_stop = start_time;
      }
   else 
      {
      last_range_start = start_time;
      last_range_stop = stop_time;
      }
   }
   
   
void updateRangeStart()
   {
      //--------------------------------------------------------------------------
   
   //   SPECIAL CASE -  Adjust range start time incase it is out of market active hours
   //   this happens when range start is set on higher time frame like H1( start time = 00:00)
   //   but the market opens only at 00:05 (hh:mm), so in special case scenarios this can end in start time 
   //   adjusting to previous week.
   //   in order to fix this time must be corrected before special case scenario is executed.
   
   //--------------------------------------------------------------------------------------
   ENUM_TIMEFRAMES tf;
   if(check_vp_data==input_data_ticks)// in case user wants to work with input data larger than M1 we need to adjust 
      {
      tf = PERIOD_M1;
      }
   else
      {
      tf=check_input_tf;
      }
   
   
   string name0 = prefRange+"Line_1";
   string name1 = prefRange+"Line_2";
   
   datetime time0=datetime(ObjectGetInteger(0,name0,OBJPROP_TIME));
   datetime time1=datetime(ObjectGetInteger(0,name1,OBJPROP_TIME));
   
   if(time0<time1)//time0== start time
      {
      int shift = iBarShift(_Symbol,tf,time0);
      datetime timeCheck = iTime(_Symbol,tf,shift);
      if(time0!=timeCheck && shift>0)
         {
         time0=iTime(_Symbol,tf,iBarShift(_Symbol,tf,time0)-1);
         if(!ObjectSetInteger(0,name0,OBJPROP_TIME,time0))
            {
            Print("Failed to adjust range start time while changing time frames");
            }
         else
            {
            last_range_start=time0;
            }
         }
      }
   else //time1 = start time
      {
      int shift = iBarShift(_Symbol,tf,time1);
      datetime timeCheck = iTime(_Symbol,tf,shift);
      if(time1!=timeCheck && shift>1)
         {
         time1=iTime(_Symbol,tf,iBarShift(_Symbol,tf,time1)-1);
         if(!ObjectSetInteger(0,name1,OBJPROP_TIME,time1))
            {
            Print("Failed to adjust range start time while changing time frames");
            }
         else
            {
            last_range_start=time1;
            }
         }
      }
   
   }
   
datetime getDataLimitTime()
   {
   
   if(check_vp_data==input_data_ticks)
      {
      int i=0;
      
      MqlTick ticks[];
      int tickCount;
      while(i<10)
         {
   		tickCount = CopyTicks(_Symbol, ticks, COPY_TICKS_ALL, datetime(3), 1);

   		if (tickCount > 0)
   		   {
   		   break;
   		   }
         
         sleepIndicator(1);// sleep 1 sec
         i++;
         }
      
      if(tickCount<=0)// failed to get time 10 times 
         {
         Print("Failed to get tick data limit time.");
         Print("Make sure tick data is available.");
         return TimeCurrent();
         }
         
      return ticks[0].time;
      
      }
   else
      {
      return (datetime(iTime(_Symbol, check_input_tf, iBars(_Symbol, check_input_tf) - 1)));// iTime always returns actual data
      }
   }
   
void sleepIndicator(int seconds)
   {
   ulong timeLast = GetMicrosecondCount()+1000000*seconds;
   while(GetMicrosecondCount()<timeLast)
      {
      }
   }
   
void sleepIndicatorMilisec(int miliseconds)
   {
   ulong timeLast = GetMicrosecondCount()+1000*miliseconds;
   while(GetMicrosecondCount()<timeLast)
      {
      }
   }
   
   
void createDataLimitLine()
   {
   datetime limitTime = getDataLimitTime();
   
   //now draw limit line
   string name = prefRange+"Limit_Line";
   
   if(ObjectFind(0,name)>=0)
      {
      ObjectDelete(0,name);
      }
      
   if(!vLineCreate(0,name,0,limitTime,check_vp_range_color,STYLE_SOLID,3,false,false,false,true))
      {
      Print("Failed to create data limit time line");
      }
   
   }
   
string errorMeaning(int errorNR)
   {
   string error;
   switch(errorNR)
      {
      case 0:error= "The operation completed successfully";       break;
      case 4001:error="Unexpected internal error";   break;
      case 4002:error="Wrong parameter in the inner call of the client terminal function";   break;
      case 4003:error="Wrong parameter when calling the system function";   break;
      case 4004:error="Not enough memory to perform the system function";   break;
      case 4005:error="The structure contains objects of strings and/or dynamic arrays and/or structure of such objects and/or classes";   break;
      case 4006:error="Array of a wrong type, wrong size, or a damaged object of a dynamic array";   break;
      case 4007:error="Not enough memory for the relocation of an array, or an attempt to change the size of a static array";   break;
      case 4008:error="Not enough memory for the relocation of string";   break;
      case 4009:error="Not initialized string";   break;
      case 4010:error="Invalid date and/or time";   break;
      case 4011:error="Total amount of elements in the array cannot exceed 2147483647";   break;
      case 4012:error="Wrong pointer";   break;
      case 4013:error="Wrong type of pointer";   break;
      case 4014:error="Function is not allowed for call";   break;
      case 4015:error="The names of the dynamic and the static resource match";   break;
      case 4016:error="Resource with this name has not been found in EX5";   break;
      case 4017:error="Unsupported resource type or its size exceeds 16 Mb";   break;
      case 4018:error="The resource name exceeds 63 characters";   break;
      case 4019:error="Overflow occurred when calculating math function ";   break;
      case 4020:error="Out of test end date after calling Sleep()";   break;
      case 4022:error="Test forcibly stopped from the outside. For example, optimization interrupted, visual testing window closed or testing agent stopped";   break;
      
      //Charts
      case 4101:error="Wrong chart ID";   break;
      case 4102:error="Chart does not respond";   break;
      case 4103:error="Chart not found";   break;
      case 4104:error="No Expert Advisor in the chart that could handle the event";   break;
      case 4105:error="Chart opening error";   break;
      case 4106:error="Failed to change chart symbol and period";   break;
      case 4107:error="Error value of the parameter for the function of working with charts";   break;
      case 4108:error="Failed to create timer";   break;
      case 4109:error="Wrong chart property ID";   break;
      case 4110:error="Error creating screenshots";   break;
      case 4111:error="Error navigating through chart";   break;
      case 4112:error="Error applying template";   break;
      case 4113:error="Subwindow containing the indicator was not found";   break;
      case 4114:error="Error adding an indicator to chart";   break;
      case 4115:error="Error deleting an indicator from the chart";   break;
      case 4116:error="Indicator not found on the specified chart";   break;
      
      //Graphical Objects
      case 4201:error="Error working with a graphical object";   break;
      case 4202:error="Graphical object was not found";   break;
      case 4203:error="Wrong ID of a graphical object property";   break;
      case 4204:error="Unable to get date corresponding to the value";   break;
      case 4205:error="Unable to get value corresponding to the date";   break;
      
      //MarketInfo 
      case 4301:error="Unknown symbol";   break;
      case 4302:error="Symbol is not selected in MarketWatch";   break;
      case 4303:error="Wrong identifier of a symbol property";   break;
      case 4304:error="Time of the last tick is not known (no ticks)";   break;
      case 4305:error="Error adding or deleting a symbol in MarketWatch";   break;
      
      //History Access 
      case 4401:error="Requested history not found";   break;
      case 4402:error="Wrong ID of the history property";   break;
      case 4403:error="Exceeded history request timeout";   break;
      case 4404:error="Number of requested bars limited by terminal settings";   break;
      case 4405:error="Multiple errors when loading history";   break;
      case 4407:error="Receiving array is too small to store all requested data";   break;
      
      //Global_Variables
      case 4501:error="Global variable of the client terminal is not found";   break;
      case 4502:error="Global variable of the client terminal with the same name already exists";   break;
      case 4503:error="Global variables were not modified";   break;
      case 4504:error="Cannot read file with global variable values";   break;
      case 4505:error="Cannot write file with global variable values";   break;
      case 4510:error="Email sending failed";   break;
      case 4511:error="Sound playing failed";   break;
      case 4512:error="Wrong identifier of the program property";   break;
      case 4513:error="Wrong identifier of the terminal property";   break;
      case 4514:error="File sending via ftp failed";   break;
      case 4515:error="Failed to send a notification";   break;
      case 4516:error="Invalid parameter for sending a notification – an empty string or NULL has been passed to the SendNotification() function";   break;
      case 4517:error="Wrong settings of notifications in the terminal (ID is not specified or permission is not set)";   break;
      case 4518:error="Too frequent sending of notifications";   break;
      case 4519:error="FTP server is not specified";   break;
      case 4520:error="FTP login is not specified";   break;
      case 4521:error="File not found in the MQL5 Files directory to send on FTP server";   break;
      case 4522:error="FTP connection failed";   break;
      case 4523:error="FTP path not found on server";   break;
      case 4524:error="FTP connection closed";   break;
      
      //Custom Indicator Buffers
      case 4601:error="Not enough memory for the distribution of indicator buffers";   break;
      case 4602:error="Wrong indicator buffer index";   break;
      
      //Custom Indicator Properties
      case 4603:error="Wrong ID of the custom indicator property";   break;
      
      //Account
      case 4701:error="Wrong account property ID";   break;
      case 4751:error="Wrong trade property ID";   break;
      case 4752:error="Trading by Expert Advisors prohibited";   break;
      case 4753:error="Position not found";   break;
      case 4754:error="Order not found";   break;
      case 4755:error="Deal not found";   break;
      case 4756:error="Trade request sending failed";   break;
      case 4758:error="Failed to calculate profit or margin";   break;
      
      //Indicators
      case 4801:error="Unknown symbol";   break;
      case 4802:error="Indicator cannot be created";   break;
      case 4803:error="Not enough memory to add the indicator";   break;
      case 4804:error="The indicator cannot be applied to another indicator";   break;
      case 4805:error="Error applying an indicator to chart";   break;
      case 4806:error="Requested data not found";   break;
      case 4807:error="Wrong indicator handle";   break;
      case 4808:error="Wrong number of parameters when creating an indicator";   break;
      case 4809:error="No parameters when creating an indicator";   break;
      case 4810:error="The first parameter in the array must be the name of the custom indicator";   break;
      case 4811:error="Invalid parameter type in the array when creating an indicator";   break;
      case 4812:error="Wrong index of the requested indicator buffer";   break;
      
      //Depth of Market
      case 4901:error="Depth Of Market can not be added";   break;
      case 4902:error="Depth Of Market can not be removed";   break;
      case 4903:error="The data from Depth Of Market can not be obtained";   break;
      case 4904:error="Error in subscribing to receive new data from Depth Of Market";   break;
      
      //File Operations
      case 5001:error="More than 64 files cannot be opened at the same time";   break;
      case 5002:error="Invalid file name";   break;
      case 5003:error="Too long file name";   break;
      case 5004:error="File opening error";   break;
      case 5005:error="Not enough memory for cache to read";   break;
      case 5006:error="File deleting error";   break;
      case 5007:error="A file with this handle was closed, or was not opening at all";   break;
      case 5008:error="Wrong file handle";   break;
      case 5009:error="The file must be opened for writing";   break;
      case 5010:error="The file must be opened for reading";   break;
      case 5011:error="The file must be opened as a binary one";   break;
      case 5012:error="The file must be opened as a text";   break;
      case 5013:error="The file must be opened as a text or CSV";   break;
      case 5014:error="The file must be opened as CSV";   break;
      case 5015:error="File reading error";   break;
      case 5016:error="String size must be specified, because the file is opened as binary";   break;
      case 5017:error="A text file must be for string arrays, for other arrays - binary";   break;
      case 5018:error="This is not a file, this is a directory";   break;
      case 5019:error="File does not exist";   break;
      case 5020:error="File can not be rewritten";   break;
      case 5021:error="Wrong directory name";   break;
      case 5022:error="Directory does not exist";   break;
      case 5023:error="This is a file, not a directory";   break;
      case 5024:error="The directory cannot be removed";   break;
      case 5025:error="Failed to clear the directory (probably one or more files are blocked and removal operation failed)";   break;
      case 5026:error="Failed to write a resource to a file";   break;
      case 5027:error="Unable to read the next piece of data from a CSV file (FileReadString, FileReadNumber, FileReadDatetime, FileReadBool), since the end of file is reached";   break;
      
      //String Casting
      case 5030: error="No date in the string";   break;
      case 5031: error="Wrong date in the string";   break;
      case 5032: error="Wrong time in the string";   break;
      case 5033: error="Error converting string to date";   break;
      case 5034: error="Not enough memory for the string";   break;
      case 5035: error="The string length is less than expected";   break;
      case 5036: error="Too large number, more than ULONG_MAX";   break;
      case 5037: error="Invalid format string";   break;
      case 5038: error="Amount of format specifiers more than the parameters";   break;
      case 5039: error="Amount of parameters more than the format specifiers";   break;
      case 5040: error="Damaged parameter of string type";   break;
      case 5041: error="Position outside the string";   break;
      case 5042: error="0 added to the string end, a useless operation";   break;
      case 5043: error="Unknown data type when converting to a string";   break;
      case 5044: error="Damaged string object";   break;
      
      //Operations with Arrays
      case 5050: error="Copying incompatible arrays. String array can be copied only to a string array, and a numeric array - in numeric array only";   break;
      case 5051: error="The receiving array is declared as AS_SERIES, and it is of insufficient size";   break;
      case 5052: error="Too small array, the starting position is outside the array";   break;
      case 5053: error="An array of zero length";   break;
      case 5054: error="Must be a numeric array";   break;
      case 5055: error="Must be a one-dimensional array";   break;
      case 5056: error="Timeseries cannot be used";   break;
      case 5057: error="Must be an array of type double";   break;
      case 5058: error="Must be an array of type float";   break;
      case 5059: error="Must be an array of type long";   break;
      case 5060: error="Must be an array of type int";   break;
      case 5061: error="Must be an array of type short";   break;
      case 5062: error="Must be an array of type char";   break;
      case 5063: error="String array only";   break;
      
      //Operations with OpenCL
      case 5100: error="OpenCL functions are not supported on this computer";   break;
      case 5101: error="Internal error occurred when running OpenCL";   break;
      case 5102: error="Invalid OpenCL handle";   break;
      case 5103: error="Error creating the OpenCL context";   break;
      case 5104: error="Failed to create a run queue in OpenCL";   break;
      case 5105: error="Error occurred when compiling an OpenCL program";   break;
      case 5106: error="Too long kernel name (OpenCL kernel)";   break;
      case 5107: error="Error creating an OpenCL kernel";   break;
      case 5108: error="Error occurred when setting parameters for the OpenCL kernel";   break;
      case 5109: error="OpenCL program runtime error";   break;
      case 5110: error="Invalid size of the OpenCL buffer";   break;
      case 5111: error="Invalid offset in the OpenCL buffer";   break;
      case 5112: error="Failed to create an OpenCL buffer";   break;
      case 5113: error="Too many OpenCL objects";   break;
      case 5114: error="OpenCL device selection error";   break;
      
      //Working with databases
      case 5120: error="Internal database error";   break;
      case 5121: error="Invalid database handle";   break;
      case 5122: error="Exceeded the maximum acceptable number of Database objects";   break;
      case 5123: error="Database connection error";   break;
      case 5124: error="Request execution error";   break;
      case 5125: error="Request generation error";   break;
      case 5126: error="No more data to read";   break;
      case 5127: error="Failed to move to the next request entry";   break;
      case 5128: error="Data for reading request results are not ready yet";   break;
      case 5129: error="Failed to auto substitute parameters to an SQL request";   break;
      
      //Operations with WebRequest
      case 5200: error="Invalid URL";   break;
      case 5201: error="Failed to connect to specified URL";   break;
      case 5202: error="Timeout exceeded";   break;
      case 5203: error="HTTP request failed";   break;
      
      //Operations with network (sockets)
      case 5270: error="Invalid socket handle passed to function";   break;
      case 5271: error="Too many open sockets (max 128)";   break;
      case 5272: error="Failed to connect to remote host";   break;
      case 5273: error="Failed to send/receive data from socket";   break;
      case 5274: error="Failed to establish secure connection (TLS Handshake)";   break;
      case 5275: error="No data on certificate protecting the connection";   break;
      
      //Custom Symbols
      case 5300: error="A custom symbol must be specified";   break;
      case 5301: error="The name of the custom symbol is invalid. The symbol name can only contain Latin letters without punctuation, spaces or special characters ";   break;
      case 5302: error="The name of the custom symbol is too long. The length of the symbol name must not exceed 32 characters including the ending 0 character";   break;
      case 5303: error="The path of the custom symbol is too long. The path length should not exceed 128 characters including ""Custom\\"", the symbol name, group separators and the ending 0";   break;
      case 5304: error="A custom symbol with the same name already exists";   break;
      case 5305: error="Error occurred while creating, deleting or changing the custom symbol";   break;
      case 5306: error="You are trying to delete a custom symbol selected in Market Watch";   break;
      case 5307: error="An invalid custom symbol property";   break;
      case 5308: error="A wrong parameter while setting the property of a custom symbol";   break;
      case 5309: error="A too long string parameter while setting the property of a custom symbol";   break;
      case 5310: error="Ticks in the array are not arranged in the order of time";   break;
      
      //Economic Calendar
      case 5400: error="Array size is insufficient for receiving descriptions of all values";   break;
      case 5401: error="Request time limit exceeded";   break;
      case 5402: error="Country is not found";   break;
      
      //Working with databases
      case 5601: error="Generic error";   break;
      case 5602: error="SQLite internal logic error";   break;
      case 5603: error="Access denied";   break;
      case 5604: error="Callback routine requested abort";   break;
      case 5605: error="Database file locked";   break;
      case 5606: error="Database table locked";   break;
      case 5607: error="Insufficient memory for completing operation";   break;
      case 5608: error="Attempt to write to readonly database";   break;
      case 5609: error="Operation terminated by sqlite3_interrupt()";   break;
      case 5610: error="Disk I/O error";   break;
      case 5611: error="Database disk image corrupted";   break;
      case 5612: error="Unknown operation code in sqlite3_file_control()";   break;
      case 5613: error="Insertion failed because database is full";   break;
      case 5614: error="Unable to open the database file";   break;
      case 5615: error="Database lock protocol error";   break;
      case 5616: error="Internal use only";   break;
      case 5617: error="Database schema changed";   break;
      case 5618: error="String or BLOB exceeds size limit";   break;
      case 5619: error="Abort due to constraint violation";   break;
      case 5620: error="Data type mismatch";   break;
      case 5621: error="Library used incorrectly";   break;
      case 5622: error="Uses OS features not supported on host";   break;
      case 5623: error="Authorization denied";   break;
      case 5625: error="Bind parameter error, incorrect index";   break;
      case 5626: error="File opened that is not database file";   break;
      default:   error="unknown error";    break;
      }
   return error;
   }
   