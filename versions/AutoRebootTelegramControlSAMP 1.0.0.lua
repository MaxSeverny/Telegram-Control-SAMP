script_name('Auto Reboot Telegram Control SAMP')
script_version('1.0')
script_author("Vespan")
script_url('blast.hk/threads/62811/')  

name = nil

function main()
    if not isSampLoaded() and not isSampfuncsLoaded() then return end 
    while not isSampAvailable() do wait(0) end

	sampRegisterChatCommand('12', function() script.load('moonloader/' .. name) end)

	while true do wait(0)

	end
end

function EXPORTS.crash()

	script.load('moonloader/' .. name)
	--dofile('moonloader/' .. name)
	print('{00c8ff}<[Auto Reboot Telegram Control SAMP]{FFFFFF}:\n{FF0000}Произошел краш скрипта {9e9e9e}(' .. name .. '){FF0000}!\n{FFFFFF}'..os.date('%H:%M:%S') .. '{00c8ff}>')

end

function EXPORTS.getfilename() 

	for i, s in pairs(script.list()) do
		if s.name == 'Telegram Control SAMP (TCS)' then 
			name = s.filename -- получаем название скрипта.lua,даже если название будет изменено
			print('{00c8ff}<[Auto Reboot Telegram Control SAMP]{FFFFFF}:\nПолучено название скрипта {00FF00}' .. name .. '{00c8ff}>')
		end
	end

end