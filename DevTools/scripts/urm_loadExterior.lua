LoadExterior = function(pid,start,stop)
	local i = 0
	if(stop>1512) then stop = 1512 end
	for x=-15,20,1 do
		for y = -16,25,1 do
			i = i + 1
			if((i>=start) and (i<=stop)) then
				tes3mp.StartTimer(tes3mp.CreateTimerEx("load",2000*(i-start),"iqq",pid,x,y))
			end
		end
	end
end

load = function(pid,x,y)
	tes3mp.SendMessage(pid,"Teleporting to "..(x)..","..(y).."\n")
	tes3mp.SetCell(pid, x..","..y)
	tes3mp.SendCell(pid)
end

return LoadExterior