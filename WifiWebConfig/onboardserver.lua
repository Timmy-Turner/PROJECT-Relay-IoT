function restart()
print('Change Mode')
 wifi.setmode(wifi.STATION);
end


function extractvalues()


 ssid = string.sub(tgtfile,string.find(tgtfile,"ssid=")+5,string.find(tgtfile,"&password")-1)
 pw = string.sub(tgtfile,string.find(tgtfile,"password=")+9)
 
 print('Now Connect to WiFi')
 print(ssid)
 print(pw) 
 wifi.sta.config(ssid,pw)
 
end

wificount = 0 
print('Create Server')
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
conn:on("receive", function(client,payload)
 
 
 tgtfile = string.sub(payload,string.find(payload,"GET /")
 +5,string.find(payload,"HTTP/")-2)
 print(tgtfile)
 if string.match(tgtfile, 'ssid', 0) then
 
 extractvalues()
 
 

 tmr.alarm(1,1000, 1, function() 
 if wifi.sta.getip()==nil then 
 		if wificount == 10 then
 			print("Abort, no IP Address")
 			tmr.stop(1)
 			tgtfile = "error.html"
 			local f = file.open(tgtfile,"r")
 				client:send(file.read())
 				file.close()
 				client:close();
 				collectgarbage();
 				f = nil
	 			tgtfile = nil
 				ssid = nil
 				email = nil
 				pw = nil
 				access = nil
 				wificount = nil 
 	else
 			print(".") 
 			wificount = wificount + 1
 		end
 	else 
 		print("WIFI ready...New IP address is "..wifi.sta.getip()) 
 		tmr.stop(1) 
 		print("output done file")
 		tgtfile = "done.html"
 
 		local f = file.open(tgtfile,"r")
 			print('client send the file')
 			client:send(file.read())
 			print('file close')
		 	file.close()
 			print('client close') 
 -- client:close();
 			print('client closed') 
 			collectgarbage();
 			f = nil
 			tgtfile = nil
 			tmr.alarm(0,15000,0,restart)
 
 		end 
 end)
 
 
 
 	else
 		if tgtfile == "" then tgtfile = "index.html" end 

 			print('file')
 			print(tgtfile) 
 			local f = file.open(tgtfile,"r")
 
 			if f ~= nil then
 				print('client send 2') 
 				client:send(file.read())
 				file.close()
 				else
					print('conn send 2') 
 					conn:send("HTTP/1.1 404 file not found")
 				return
 			end
 			print('client close 2') 
 			client:close();
 			collectgarbage();
 			f = nil
 			tgtfile = nil
 
 		end

 end)
end)
