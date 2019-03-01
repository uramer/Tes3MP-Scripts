local CMDa
local CMDb
if tes3mp.GetOperatingSystemType() == "Windows" then
	CMDa = 'dir "'
	--CMDb = '" /b /ad'
	CMDb = '"'
else
	CMDa = 'ls -a "'
	CMDb = '"'
end

function scandir(directory)

    local i, t, popen = 0, {}, io.popen
    local pfile = io.popen(CMDa..directory..CMDb)
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

return scandir