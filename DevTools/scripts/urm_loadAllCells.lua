cells = require("urm_listOfAllCells")
maxID = #cells

LoadAllCells = function(pid,start,stop)
	if(stop == -1) then
		stop = maxID
	end
	if(stop > maxID) then
		stop = maxID
	end
	if(start == 1) then
		tes3mp.SendMessage(pid, "Loading all " .. (stop-start+1) .. " cells!\n")
	end
	if(start<=stop) then
		tes3mp.SendMessage(pid, "Loading  " .. start .. "th " .. cells[start] .. "!\n")
		tes3mp.SetCell(pid, cells[start])
        tes3mp.SendCell(pid)
		start = start + 1
		tes3mp.StartTimer(tes3mp.CreateTimerEx("LoadAllCells",1000,"iii",pid,start,stop))
	end
end

return LoadAllCells