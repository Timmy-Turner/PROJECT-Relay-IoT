function onboardserver()
    print('Run Server')
    print('changing wifi mode to station')
    print('wifi config')
    cfg={}
    cfg.ssid="Timson's NodeMCU"
    cfg.pwd="password"
 wifi.ap.config(cfg)
 
    dofile("onboardserver.lc")
end


print('Wifi Mode:')
print(wifi.getmode())
count=0

tmr.alarm(1,1000, 1, function() 
    print('.')
     if wifi.sta.getip()==nil then 
         if count == 5 then
             print('onboard server to request WIFI details in 3 secs')
             ipfail = true
             tmr.stop(1) 
             if(wifi.getmode() ~= 3) then
                 print('set mode to stationap')
                 wifi.setmode(wifi.STATIONAP);
             end
             
             tmr.alarm(0,3000,0,onboardserver)
            else
                count = count + 1 
            end
      else 
         print(wifi.sta.getip())
         if(wifi.getmode() ~= 1) then
             print('Changing WiFi Mode to Station Only')             
             wifi.setmode(wifi.STATION);
         end
         tmr.stop(1) 
         print("Initializing")
         dofile("mqtt1.lc")
         
     end 
end)
