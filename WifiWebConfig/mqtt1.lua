sda = 1 
scl = 2 

pin = 5

relaypin = 7
relaystatus = false

mqttBroker="mqtt.quanta-camp.com"
mqttPort=1883
deviceID = "TimsonNodeMCU"
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
        monitorData = monitorData .. "{\"DataAPIKey\": \"337741dacfe441d1b91911e85ee09d6a\",\"esptemp\":".. temp ..",\"esphumi\":".. humi .."}";   
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
        monitorData = monitorData .. "{\"esptemp\":".. temp ..",\"esphumi\":".. humi .."}";   

        local length = string.len(monitorData);
        
        connout:send("POST /v1/data/devices/TimsonNodeMCU/ HTTP/1.1\r\n"
          .. "Host: iot.quanta-camp.com\r\n"
          .. "Content-Type: application/json\r\n"
          .. "Accept:application/json\r\n"
          .. "Content-Length: ".. length .. "\r\n"
          .. "x-data-key: 337741dacfe441d1b91911e85ee09d6a\r\n"
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


m = mqtt.Client(deviceID, 10, "739e76875c884c2e9ed5109417695148", "739e76875c884c2e9ed5109417695148")


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
   local str7=ip
   local str3="IP:"
   disp:firstPage()
   repeat
     disp:drawStr(6, 2, str2)
     disp:drawStr(21, 12, string.sub(str7, 1, 7))
     disp:drawStr(1, 22, string.sub(str7, 8))
     disp:drawStr(1, 12, str3)
   until disp:nextPage() == false
   
end  

function write_OLED_Old() -- Write Display
   local str1=humi
   local str2=temp.."/"..humi
   local str3="Temp:"
   local str4="C"
   local str5="Humi:"
   local str6="%"
   local str7=ip
   disp:firstPage()
   repeat
     --disp:drawFrame(2,2,126,62)
     disp:drawStr(5, 22, str7)
     disp:setScale2x2()
     disp:drawStr(36, 2, str2)
     disp:drawStr(5, 2, str3)
     disp:drawStr(49, 2, str4)
     -- disp:drawStr(40, 30,  string.format("%02d:%02d:%02d",h,m,s))
     disp:drawStr(36, 12, str1) 
     disp:drawStr(49, 12, str6)
     disp:drawStr(5, 12, str5)
     --disp:setFont(u8g.font_chikita)
     
     --disp:drawCircle(18, 47, 14)
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
