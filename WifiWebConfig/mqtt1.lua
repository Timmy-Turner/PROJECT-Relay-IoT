sda = 1 
scl = 2 

pin = 5

relaypin = 7
relaystatus = false

mqttBroker="mqtt.quanta-camp.com"
mqttPort=1883
deviceID = "TH_Notice_Action"
ip=wifi.sta.getip()

function ctrlPower(status)
    gpio.mode(relaypin, gpio.OUTPUT)
    if status == true then
        print("Power ON")
        gpio.write(relaypin, gpio.HIGH)
        
    else 
        print("Power OFF")
        gpio.write(relaypin, gpio.LOW)
    end

end


function getDHT11()
    status, temp, humi, temp_dec, humi_dec = dht.read(pin)
    if status == dht.OK then
        -- Integer firmware using this example
    print(string.format("DHT Temperature:%d.%03d;Humidity:%d.%03d\r\n",
              math.floor(temp),
              temp_dec,
              math.floor(humi),
              humi_dec
        ))
    print("DHT Temperature:"..temp..";".."Humidity:"..humi)
        -- Float firmware using this example
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    end
end

function mqttPublish(temp, humi)

        local monitorData = "";
        monitorData = monitorData .. "{\"DataAPIKey\": \"478f1e9862b14b1b8eb97300a6117c5a\",\"TempSensor\":".. temp ..",\"HumiSensor\":".. humi .."}";   
        m:publish("Device/".. deviceID, monitorData,0,0,function() 
         print("Successfully published.") 
     end) 
end
 
function postIoTPlatform(temp, humi)
    connout = nil
    connout = net.createConnection(net.TCP, 0)
 
    connout:on("receive", function(connout, payloadout)
        if (string.find(payloadout, "201 Created") ~= nil) then
            --print(payloadout);
            print("Posted OK");
        end
    end)
 
    connout:on("connection", function(connout, payloadout)
 
        print ("Posting...");
  

        local monitorData = "";
        monitorData = monitorData .. "{\"TempSensor\":".. temp ..",\"HumiSensor\":".. humi .."}";   

        local length = string.len(monitorData);
        
        connout:send("POST /v1/data/devices/TH_Notice_Action/ HTTP/1.1\r\n"
          .. "Host: iot.quanta-camp.com\r\n"
          .. "Content-Type: application/json\r\n"
          .. "Accept:application/json\r\n"
          .. "Content-Length: ".. length .. "\r\n"
          .. "x-data-key: 478f1e9862b14b1b8eb97300a6117c5a\r\n"
          .. "\r\n"
          .. monitorData)
    end)
 
    connout:on("disconnection", function(connout, payloadout)
        connout:close();
        collectgarbage();
    end)
 
    connout:connect(80,'iot.quanta-camp.com')
end
 


   


function mqttSubscribe() 
     m:subscribe("DeviceReturn/".. deviceID,0,function(conn) 
         print("Successfully subscribed to data endpoint") 
     end) 
end 


m = mqtt.Client(deviceID, 10, "5558e0c246024f8fa430b493735cdefe", "5558e0c246024f8fa430b493735cdefe")


m:on("message", function(conn, topic, data) 
  print(topic .. ":" ) 
  if data ~= nil then
    print(data)
    local t = cjson.decode(data)
    ctrlPower(t.esprelay)
  end
end)


function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     disp:setScale2x2()
     --disp:setRot180()           -- Rotate Display if needed
end

function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
     disp:setScale2x2()
     --disp:setRot180()           -- Rotate Display if needed
end

function write_OLED() -- Write Display

   local str2=temp.."C | "..humi.."%"
   local str3="IP:"
   local str7=""
   if ip == nil then
       str7 = "No IP Found." 
   else
       str7 = ip
   end
   disp:firstPage()
   repeat
     disp:drawStr(6, 2, str2)
     disp:drawStr(1, 12, str3)
     disp:drawStr(21, 12, string.sub(str7, 1, 7))
     disp:drawStr(1, 22, string.sub(str7, 8))
   until disp:nextPage() == false
   
end 


tmr.alarm(1, 20000, 1, function()
    if wifi.sta.status() == 5 and wifi.sta.getip() ~= nil then
        tmr.stop(1)
        m:connect(mqttBroker, mqttPort, 0, 1, function(conn)
            print("MQTT Connected to:" .. mqttBroker)
            mqttSubscribe()
            tmr.alarm(1, 20000, 1, function() 
                --postIoTPlatform(temp, humi) 
                mqttPublish(temp, humi) 
            end)
        end)
        
    end
end)

tmr.alarm(0, 3000, 1, function()
    getDHT11()
    -- Main Program 
    
    init_OLED(sda, scl)
    write_OLED()
    end)
