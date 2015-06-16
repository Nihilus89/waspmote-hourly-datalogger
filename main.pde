  #include <WaspSensorGas.h>
  
  float value, press, hum, temp;
  byte d, M, Y, h, m, even[4] = {4,6,9,11}, i, battery, temper;
  int sum;
  byte ALd=1,ALh=14,ALm=0;
  char pressstr[10], humstr[10], data[20];
  
  void setup(){
    
    // Set SD ON
    SD.ON();
  
    // Powers RTC up, init I2C bus and read initial values
    RTC.ON();   
    
    // Turn on the sensor board
    SensorGas.setBoardMode(SENS_ON);
    
    // Turn on pressure sensor
    SensorGas.setSensorMode(SENS_ON, SENS_PRESSURE);
    delay(100); //waiting for the stabilization of the power supply
    
   // Turn on humidity sensor
    SensorGas.setSensorMode(SENS_ON, SENS_HUMIDITY);
    delay(100); //waiting for the stabilization of the power supply
   
  }
  
  void loop()
  {
    getTime();
    setAlarm();
    
  // Setting Waspmote to Low-Power Consumption Mode
  PWR.sleep(ALL_OFF);
    
     if( intFlag & RTC_INT )
    {
        setup();
        getTime();
        intFlag &= ~(RTC_INT); // Clear flag
        meanPressure();
        meanHumidity();
        meanBattery();
        meanTemper();
        logData();
        Utils.blinkLEDs(200);
           
    }
  }
  
  
  
  void getTime()      //Getting current date & time
  {     
      RTC.getTime();
      
      d = RTC.date,DEC;
  
      M = RTC.month,DEC;
  
      Y = RTC.year,DEC;
  
      h = RTC.hour,DEC;
  
      m = RTC.minute,DEC;
    
  }
  
  void setAlarm()
  {

    
  RTC.setAlarm2(ALd,ALh,ALm,RTC_ABSOLUTE,RTC_ALM2_MODE2);
  USB.print("Alarm2: ");  
  USB.println(RTC.getAlarm2());  
    
    ALh++;
    if (ALh == 24)
    {
      ALh=0;
      ALd++;
      if (ALd == 31)
        {
          for (i=0; i<4; i++)
            {
              if (M == even[i])
              {
               ALd = 1;
              }
            }
        }
     else if (ALd == 32)
       {
         ALd = 1;
       }
     else if (ALd == 28 && M == 2)
       {
         ALd = 1;
       }
    }

  }
  
  
void meanBattery()
  {
  sum=0;
  for (i=0; i<100; i++)
  {
    sum += PWR.getBatteryLevel(),DEC;
  }
  battery = sum/i;
  }
  
void meanTemper()
  {
  sum=0;
  for (i=0; i<100; i++)
  {
    sum += RTC.getTemperature(),DEC;
  }
  temper = sum/i;
  }

void meanHumidity()
{	
	temp=0;
       for (i=0; i<100; i++)
        {
        value = SensorGas.readValue(SENS_HUMIDITY);
        temp += (value - 0.48)/(0.0186);
        }
        hum = temp/i;
        Utils.float2String(hum,humstr,2);
}


void meanPressure()
{
	temp=0;
       for (i=0; i<100; i++)
       {
         temp += ((((SensorGas.readValue(SENS_PRESSURE)) * (0.2/0.12)) / (5*0.009)) + (0.095/0.009)) * 10;
       }
        press = temp/i;
        Utils.float2String(press,pressstr,2);
}

void logData()
{

  sprintf(data,"%d/%d/%d %d:%d%c%s%c%s%c%d%c%d%c",d,M,Y,h,m,'\t',humstr, '\t', pressstr, '\t', battery, '\t', temper, '\n');
  if(!SD.create("datalog.txt")) SD.create("datalog.txt");
  SD.appendln("datalog.txt",data);
}
