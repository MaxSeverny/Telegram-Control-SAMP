script_name('Telegram Control SAMP')
script_author('vespan')
script_version(5.12)

require 'moonloader'
local libs = {
    ['sampev'] = 'samp.events',
    ['imgui'] =  'imgui',
    ['requests'] =  'requests',
    ['encoding'] = "encoding",
}
for k,v in pairs(libs) do
    local res = pcall(require,v)
    if not res then
        lua_thread.create(function()
            while not isSampAvailable() do wait(0) end
            sampShowDialog(100,
                '{294a7a}[telegram control samp] {8E0700}not found library!',
                ([[
{cccccc}not found {ffffff}%s {cccccc}library in path {ffffff}/lib/%s.lua{cccccc}
write the command {294a7a}/tcs_libs{cccccc} to open the link <SA:MP setup>(library installer)(blast.hk)]]):format(k,v:gsub('%.','/')),
                '=(','',0
            )
            sampRegisterChatCommand('tcs_libs',function() os.execute('explorer "https://www.blast.hk/threads/157157/"') end)
        end)
    else
        _G[k] = require(v)
    end
end

encoding.default = 'CP1251'; u8 = encoding.UTF8  
function json(filePath)
    local class = {}
        function class.save(tbl)
        if tbl then local F = io.open(filePath, 'w');    F:write(encodeJson(tbl) or {});    F:close();    return true, 'ok' end
        return false, 'table = nil'
    end
    function class.load(defaultTable)
        if not doesFileExist(filePath) then;    class.save(defaultTable or {});    end
        local F = io.open(filePath, 'r+');    local TABLE = decodeJson(F:read() or {}); F:close()
        for def_k, def_v in pairs(defaultTable) do;  if TABLE[def_k] == nil then;   TABLE[def_k] = def_v;   end;    end
        return TABLE
    end; return class
end
json = {
    defPath = getWorkingDirectory()..'/config/',
    save = function(t,path) 
        if not path:find('/') or not path:find('\\') then;  path = json.defPath..path end
        t = (t == nil and {} or (type(t) == 'table' and t or {}))
        local f = io.open(path,'w');    f:write(encodeJson(t) or {});   f:close()
    end,
    load = function(t,path) 
        if not path:find('/') or not path:find('\\') then;  path = json.defPath..path end
        if not doesFileExist(path) then;    json.save(t,path);  end
        local f = io.open(path,'r+');   local T = decodeJson(f:read('*a')); f:close()
        return T
    end
}
if not doesDirectoryExist(getWorkingDirectory()..'/config/') then createDirectory(getWorkingDirectory()..'/config/') end
j = json.load({
    notf = false,
    token = '123456789:token',
    id = 'chat_id',
    events = {},
    commands = {
        {
            name = 'send chat',
            cmd = '/send',
            act = [[sampSendChat('{1:+}')]],
        },
        {
            name = 'exit game',
            cmd = '/q',
            act = [[sampProcessChatInput('/q')]],
        },
        {
            name = 'checker',
            cmd = '/check',
            act = [[
local t = {}
local players = {
    'vespa',
    'ARMOR_kypi_mne_syhariki',
}
for k,v in ipairs(players) do
    local id = nil
    local h = nil
    for i = 1,1000 do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == v then
            id = i
            h = select(2,sampGetCharHandleBySampPlayerId(id))
        end
    end
    table.insert(t,
        string.format('%s[%s] %s',v,(id == nil and 'DISCONNECTED' or id),
            (id == nil and '' or (doesCharExist(h) and 'ON ZONE-STREAM' or '') )
        )
    )
end
sendTelegramNotification(table.concat(t,'\n'))]],
        },
        {
            name = 'make screenshot',
            cmd = '/ss',
            act = [[
lua_thread.create(function()
    setVirtualKeyDown(VK_F8,true)
    wait(10)
    setVirtualKeyDown(VK_F8,false)
end)
]],
        },
        {
            name = 'get info',
            cmd = '/ss',
            act = [[
local ip,port = sampGetCurrentServerAddress()
sendTelegramNotification(
    string.format('%s[%s]\nserver %s[%s:%s]\nscore %s,clist(hex) %s\nmoney %s',
        MY_NICK,MY_ID,sampGetCurrentServerName(),ip,port,
        sampGetPlayerScore(MY_ID),bit.tohex(sampGetPlayerColor(MY_ID)),getPlayerMoney(playerPed)
    )
)
]],
        },
        {
            name = 'get players in stream',
            cmd = '/gs',
            act = [[
local p = {}
for k,v in ipairs(getAllChars()) do
    if doesCharExist(v) then
        local _,id = sampGetPlayerIdByCharHandle(v)
        local x,y,z = getCharCoordinates(v)
        table.insert(p,
            string.format('%s[%s] dist %.3f',sampGetPlayerNickname(id),id,getDistanceBetweenCoords3d(x,y,z,unpack(MYPOS)))
        )
    end
end
sendTelegramNotification(table.concat(p,'\n'))
]],
        },
    },
},'Telegram Control SAMP.json')
function s();   json.save(j,'Telegram Control SAMP.json');  end

menu = ''

window = imgui.ImBool(true)
token,id,notf = imgui.ImBuffer(j.token,256), imgui.ImBuffer(j.id,15), imgui.ImBool(j.notf)

hooks = {}
events = {
    rpcs = {
        {
            namerpc = 'CUSTOM',
            rpc = 0,
            type = 'sendRpc&receiveRpc',
            bs = {
                {
                    ['IF'] = 'OFF',
                    desc = '1',
                    bs = 'string256',
                },
            },
        }
    },
    combo = imgui.ImInt(0),
    search = imgui.ImBuffer(256),
    imguiInt = imgui.ImInt(0),
}
for INTERFACE,_ in pairs(sampev.INTERFACE) do
    if INTERFACE == 'OUTCOMING_RPCS' or INTERFACE == 'INCOMING_RPCS' then
        for RPC,v in pairs(sampev.INTERFACE[INTERFACE]) do
            local n = v[1]
            if type(n) ~= 'string' or type(v[2]) == 'function' then goto skip end
            table.insert(events.rpcs,{
                namerpc = n,
                rpc = RPC,
                type = (INTERFACE == 'OUTCOMING_RPCS' and 'sendRpc' or 'receiveRpc'),
                bs = {}
            })
            for kk,vv in pairs(v) do
                if type(vv) == 'table' then
                    for k,v in pairs(vv) do
                        table.insert(events.rpcs[#events.rpcs].bs,{['IF'] = 'OFF',desc=k,bs=v,content=nil})
                    end
                end
            end
            ::skip::
        end
    end
end
regulars = {
    ['.'] = 'Any character',
    ['%a'] = 'A letter (English only!)',
    ['%A'] = 'Any letter (Russian), symbol or number except an English letter',
    ['%c'] = 'Control character',
    ['%d'] = 'Digit',
    ['%D'] = 'Any letter or symbol but a number',
    ['%l'] = 'A lowercase letter (English only!)',
    ['%L'] = 'Any letter, symbol or number but a lowercase English letter',
    ['%p'] = 'Punctuation',
    ['%P'] = 'Any letter, symbol or number except punctuation marks',
    ['%s'] = 'A space character',
    ['%S'] = 'Any letter, symbol or number other than a space character',
    ['%u'] = 'Uppercase letter (English only!)',
    ['%U'] = 'Any letter, symbol or number except a capital English letter',
    ['%w'] = 'Any letter, symbol or number (English only!)',
    ['%W'] = 'Any letter or symbol (Russian), but not an uppercase English letter or number',
    ['%x'] = 'Hexadecimal number',
    ['%X'] = 'Any letter or symbol but a digit or letter, used to represent a hexadecimal number',
    ['%z'] = 'String parameters containing characters with the code 0',
}
moonloader_reference = {
    search = imgui.ImBuffer(256),
    reference = {},
}

function main()
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand('tcs',function() window.v = not window.v end)

    downloadUrlToFile(
        'https://raw.githubusercontent.com/v3sp4n/Lua/master/moonloader_reference.txt',
        getWorkingDirectory()..'/lib/moonloader_reference.txt',
        function(_,s)
            if s == 58 then
                local f = io.open(getWorkingDirectory()..'/lib/moonloader_reference.txt','r+')
                for l in f:read('*a'):gmatch('[^\n]+') do
                    if (l:find('^%S+%(') or l:find('^.+%s+%=%s+%S+%(')) then
                        table.insert(moonloader_reference.reference,l)
                    end
                end
                f:close()
                table.insert(moonloader_reference.reference,'sendTelegramNotification(str)')
            end
        end
    )

    lua_thread.create(function()
        local update = 0
        while true do wait(500)
            local invalid_chat_id,get = false,false
            local url = 'https://api.telegram.org/bot'..token.v..'/getUpdates?chat_id='..id.v..'&offset=-1' 
            asyncHttpRequest('GET',url,nil,function(r)
                local t = decodeJson(r.text)
                if type(t) == 'table' and t.ok and #t.result > 0 and t.result[1] then 
                    if update == 0 then
                        update = t.result[1].message.date 
                    end
                    if t.result[1].message.date ~= update then
                        update = t.result[1].message.date
                        if tostring(t.result[1].message.from.id) ~= id.v then
                            invalid_chat_id = true
                        else
                            process_messages(u8:decode(t.result[1].message.text))
                        end
                    end
                    
                    get = true
                end
            end,nil)
            while not get do wait(0) end
            if invalid_chat_id then
                sampAddChatMessage("{D21C1C}ѕолучено сообщение не от вашего чат-айди! {cccccc}ѕолучение следующего сообщени€ через минуту..")
                wait(60000)
            end

        end
    end)

    local b = (50 >= 70 and true or false)
    print(b)

    wait(-1)
end

function onD3DPresent()
    if isSampAvailable() then
        imgui.Process = window.v
        MY_ID = select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))
        MY_NICK = sampGetPlayerNickname(MY_ID)
        MYPOS = {getCharCoordinates(PLAYER_PED)}
        sw,sh = getScreenResolution()
    end
end

function imgui.OnDrawFrame()

    if window.v then
        imgui.SetNextWindowSize(imgui.ImVec2(650,400),1)
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2-650/2,sh/2-400/2), imgui.Cond.FirstUseEver)
        imgui.Begin('Telegram Control SAMP / by vespan',window,32+2)

        local menus = {'information','bot','commands','events'}
        if #menu == 0 then menu = menus[1] end

        imgui.BeginChild('menu',imgui.ImVec2(170,-1),true)
        imgui.SetCursorPosX(37)
        if imgui.Checkbox('notifications',notf) then j.notf = notf.v s() end
        for k,v in ipairs(menus) do
            if imgui.AnimButton(u8(v),imgui.ImVec2(170,78),imgui.ImVec4(0.06, 0.53, 0.98, 1.00),2.3) then menu = v end
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('menu active',imgui.ImVec2(-1,-1),true,(menu == menus[4] and 32768 or 0))

        if menu == menus[1] then

            imgui.SetCursorPosY(imgui.GetWindowHeight()/2-90)

            imgui.CenterText(nil,'author vespan')
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('blasthack profile').x/2 - 5, imgui.GetCursorPosY()))
            if imgui.Button('blasthack profile') then os.execute('explorer "https://www.blast.hk/members/295413/"') end
        
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('blasthack theme script').x/2 - 5, imgui.GetCursorPosY()))
            if imgui.Button('blasthack theme script') then os.execute('explorer "https://www.blast.hk/threads/62811/"') end

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('github script repository').x/2 - 5, imgui.GetCursorPosY()))
            if imgui.Button('github script repository') then os.execute('explorer "https://github.com/v3sp4n/Telegram-Control-SAMP"') end

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('RPC descriptions').x/2 - 5, imgui.GetCursorPosY()+15))
            if imgui.Button('RPC descriptions') then os.execute('explorer "https://github.com/Brunoo16/samp-packet-list/wiki/RPC-List"') end

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('list regular expressions').x/2 - 5, imgui.GetCursorPosY()))
            if imgui.Button('list regular expressions') then imgui.OpenPopup('regular expressions') end

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('lua functions()').x/2 - 5, imgui.GetCursorPosY()))
            if imgui.Button('lua functions()') then os.execute('explorer "https://wiki.blast.hk/moonloader/events"') end

            if imgui.BeginPopupModal('regular expressions',nil,64) then
                if imgui.Button('close popup') then imgui.CloseCurrentPopup() end
                local text = ''
                for k,v in pairs(regulars) do
                    text = text .. ('%s\t\t%s\n'):format(k,v)
                end
                text = text .. [[

* Single character class, which corresponds to any single character from the given class;
* Single character class, followed by '*', which corresponds to 0 or more repetitions of characters from the given class. These repetition elements will always correspond to the longest possible sequence.
* Single character class followed by '+', which corresponds to 1 or more repetitions of characters from a given class. These repetition elements will always correspond to the longest possible sequence.
]]
                local i = imgui.ImBuffer(text,0xffff)
                imgui.InputTextMultiline('##r',i,imgui.ImVec2(700,300),16384)
                if imgui.Button('regular expressions RU') then os.execute('explorer "https://www.blast.hk/threads/62661/"') end

                imgui.EndPopup()
            end

        elseif menu == menus[2] then

            imgui.SetCursorPosY(imgui.GetWindowHeight()/2-50)

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('bot token').x/2 - 150, imgui.GetCursorPosY()))
            imgui.PushItemWidth(300)
            if imgui.InputText('bot token',token,32768) then j.token = token.v s() end
            imgui.TextQuestion(token.v)
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('user id').x/2 - 150, imgui.GetCursorPosY()))
            if imgui.InputText('user id',id,32768) then j.id = id.v s() end
            imgui.TextQuestion(id.v)
            imgui.PopItemWidth()
            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('test message').x/2 - 5, imgui.GetCursorPosY()))
            if imgui.Button('test message') then
                local res,r,rr = sendTelegramNotification('test message')
                if res then
                    sampAddChatMessage(r.ok and ('{118E00}successfull{cccccc} sending message! Bot name %s'):format(r.result.from.first_name) or ('{8E0700}error{cccccc} sending message, error_code %s, description %s.'):format(r.error_code,r.description))
                else
                    sampAddChatMessage('{8E0700}decodeJson() ~= table!')
                    print(rr.text)
                end
            end

        elseif menu == menus[3] then
            if imgui.Button('add new command') then
                table.insert(j.commands,{
                    name = ('new command #%s'):format(#j.commands+1),
                    cmd = '/command'..#j.commands+1,
                    act = ([[
-- sampSendChat(string) -- send text to server
-- sampProcessChatInput(string) -- send text to client
--[[%s%s%s
]]):format(
    [[
    arguments = 
    in string paste = {LABEL_CHAR:REGULAR(+/*)}
    examples:
    {1:S+} (Any letter, symbol or number other than a space character)
    {1:+} (Any character)
    sampSendChat('/report {1:S+} {2:+}')
    -
    symbol : replaces . and %
    if there are two regular expressions and you wrote a command with one expression,
    ..the script will give an error that there is one more expression missing]
]],']',']'
),
                })
            end
            for k,v in pairs(j.commands) do
                if imgui.CollapsingHeader(u8(v.name)) then
                    local cmd = imgui.ImBuffer(u8(v.cmd),20)

                    if imgui.Button('rename command##'..k) then imgui.OpenPopup('rename command '..k) end
                    imgui.SameLine(nil,123)
                    if imgui.Button('act##'..k) then imgui.OpenPopup('act '..k) end
                    -- imgui.SetCursorPosX(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('act').x/2 - 5)
                    imgui.SameLine(nil,70)
                    if imgui.Button('remove command##'..k) then table.remove(j.commands,k) s() end

                    imgui.PushItemWidth(150)
                    if imgui.InputText('command##'..k,cmd) then v.cmd = u8:decode(cmd.v) s() end
                    imgui.PopItemWidth()

                    imgui.Separator()
                end
------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
                if imgui.BeginPopup('act '..k) then
                    local act = imgui.ImBuffer(u8(v.act),0xffff)
                    imgui.SetCursorPosX(30)
                    if imgui.InputTextMultiline('##'..k,act,imgui.ImVec2(imgui.CalcTextSize(v.act).x+100,imgui.CalcTextSize(v.act).y+35)) then v.act = u8:decode(act.v) s() end
                    local _,err = load(u8:decode(act.v)) 
                    imgui.Text('error code = %s',err)

                    local y = 0
                    for i = 1,imgui.CalcTextSize(v.act).y/14 do
                        imgui.SetCursorPos(imgui.ImVec2(10,10+y))
                        imgui.Text(tostring(i))
                        y = y + 15
                    end
                    moonloader_reference_imgui(y)

                    imgui.EndPopup()
                end
                if imgui.BeginPopup('rename command '..k) then

                    local name = imgui.ImBuffer(u8(v.name),256)
                    if imgui.InputText('rename command',name) then v.name = u8:decode(name.v) s() end

                    imgui.EndPopup()
                end

            end

        elseif menu == menus[4] then

            imgui.BeginChild('list rpcs',imgui.ImVec2(-1,150),true)
            imgui.InputText('search rpc',events.search)
            imgui.BeginChild('list rpcs2',imgui.ImVec2(-1,-1),true)
            imgui.Columns(3,'list rpcs ADD',false)
            for k,v in pairs(events.rpcs) do
                if (v.namerpc):lower():find((events.search.v):lower()) or tostring(v.rpc):find(events.search.v) then
                    imgui.SetColumnWidth(imgui.GetColumnIndex(),250)
                    imgui.Text('[%s]%s(#%s bs)',v.rpc,v.namerpc,getn(v.bs))
                    imgui.NextColumn()
                    imgui.Text(v.type)
                    imgui.SetColumnWidth(imgui.GetColumnIndex(),105)
                    imgui.NextColumn()
                    if imgui.Button('add##'..k) then
                        local bss = ''
                        for k,bs in pairs(v.bs) do
                            bss = bss .. ('{%s} '):format(bs.desc)
                        end
                        table.insert(j.events,{
                            name = 'new event '..v.namerpc..'#'..#j.events+1,
                            namerpc = v.namerpc,
                            rpc = v.rpc,
                            bs = v.bs,
                            act = ([[
--returns information about %s
local res, r = sendTelegramNotification(
    "%s"
    -- "TRIGGER! > {regular}"
)
lua_thread.create(function()
    while not r do wait(0) end --wait successfull sending message..
    -- sampProcessChatInput('/q') -- exit game by /q
    -- callFunction(0x823BDB , 3, 3, 0, 0, 0) -- crash game
end)
-- if {regular} == false/.. then ..
-- MY_NICK return your nick_name
-- MY_ID return your server id
-- MYPOS return your coordinates {x,y,z} (MYPOS[1] return x)
]]):format(bss,bss:gsub('%s+',','):gsub(',$',''))
                        })
                        s()
                    end
                    imgui.NextColumn()
                end
            end
            imgui.Columns(1)
            imgui.EndChild()
            imgui.EndChild()

            for k,v in ipairs({'Input','Slider','Drag'}) do
                imgui.RadioButton(v,events.imguiInt,k-1) 
                if k ~= 3 then imgui.SameLine() end
            end

            for k,v in ipairs(j.events) do
                if imgui.CollapsingHeader(('%s [%s]%s##%s'):format(u8(v.name),v.rpc,v.namerpc,k)) then
                    if imgui.Button('rename event##'..k) then imgui.OpenPopup('rename event '..k) end
                    imgui.SameLine(nil,123)
                    if imgui.Button('act##'..k) then imgui.OpenPopup('act '..k) end
                    -- imgui.SetCursorPosX(imgui.GetWindowWidth()/2 - imgui.CalcTextSize('act').x/2 - 5)
                    imgui.SameLine(nil,50)
                    if imgui.Button('remove rpc current event##'..k) then table.remove(j.events,k) s() end
                    
                    if v.namerpc == 'CUSTOM' then
                        if imgui.Button('settings rpc##'..k) then imgui.OpenPopup('settings rpc '..k) end
                    end 

                    imgui.Spacing()
                    --
                    for kk,vv in pairs(v.bs) do
                        local desc = ('%s(%s)##'):format(vv.desc,vv.bs,kk)
                        local function IF()
                            local combo = {'OFF','find','==','<=','>='}
                            local int = imgui.ImInt(0)
                            for k,v in ipairs(combo) do
                                if vv['IF'] == v then int.v = k-1 end
                            end
                            if (vv.bs:find('^vector%d+d$')) then
                                imgui.Text('-')
                            else
                                imgui.PushItemWidth(50)
                                if imgui.Combo('if##'..kk,int,combo) then vv['IF'] = combo[int.v+1] s() end
                                imgui.PopItemWidth(1)
                            end
                        end
                        local function typeImgui(n,var)
                            local int = events.imguiInt
                            local ints = ((vv.bs:find('int32') or vv.bs:find('float') or vv.bs:find('vector')) and 3000 or ( vv.bs:find('int16') and 32767 or (vv.bs:find('int8')) and 256 or -1 ))
                            return (int.v == 0 and imgui['Input'..n](desc,var) or ( int.v == 1 and imgui['Slider'..n](desc,var,-ints,ints) or ( int.v == 2 and imgui['Drag'..n](desc,var,0.5,-ints,ints) ) ))
                        end
                        if vv.bs:find('^string%d+$') or vv.bs == 'encodedString4096' then
                            local i = imgui.ImBuffer(vv.content == nil and 'text' or u8(vv.content),256)
                            if imgui.InputText(desc,i) then vv.content = u8:decode(i.v) s() end
                        elseif vv.bs:find('^bool%d+$') then
                            local b = false
                            local tbl = {(vv.content == nil and b or vv.content)}
                            local i = imgui.ImBool(unpack(tbl)--[[imgui.ImBool(tbl): sol: no matching function call takes this number of arguments and the specified types
stack traceback:
    [C]: in function 'ImBool']])
                            if imgui.Checkbox(desc,i) then vv.content = i.v s() end
                        elseif vv.bs:find('^int%d+$') then
                            local i = imgui.ImInt(vv.content == nil and 0 or vv.content)
                            if typeImgui('Int',i) then vv.content = i.v s() end
                        elseif vv.bs:find('^float$') then
                            local i = imgui.ImFloat(vv.content == nil and 0.00 or vv.content)
                            if typeImgui('Float',i) then vv.content = i.v s() end
                        elseif vv.bs:find('^vector%d+d$') then
                            local n = tonumber(vv.bs:match('^vector(%d+)d$'))
                            local et = {}
                            for i = 1,n do table.insert(et,i) end
                            local tbl = (vv.content == nil and et or vv.content)
                            local i = imgui['ImFloat'..n](unpack(tbl))
                            if typeImgui('Float'..n,i) then
                                if vv.content == nil or type(vv.content) ~= 'table' then vv.content = {} end
                                for I = 1,n do
                                    vv.content[I] = i.v[I]
                                end
                                s()
                            end
                        end
                        imgui.SameLine()
                        IF()
                        if v.namerpc == 'CUSTOM' then 
                            imgui.SameLine()
                            if imgui.SmallButton('remove##'..k..'##'..kk) then
                                table.remove(v.bs,kk)
                                s()
                            end
                        end
                    end

                    imgui.Separator()
                end

------------------------------------------------------------------------
------------------------------------------------------------------------
------------------------------------------------------------------------
                if imgui.BeginPopup('act '..k) then
                    local act = imgui.ImBuffer(u8(v.act),0xffff)
                    imgui.SetCursorPosX(30)
                    if imgui.InputTextMultiline('##'..k,act,imgui.ImVec2(imgui.CalcTextSize(v.act).x+100,imgui.CalcTextSize(v.act).y+35)) then v.act = u8:decode(act.v) s() end
                    local _,err = load(u8:decode(act.v)) 
                    imgui.Text('error code = %s',err)

                    local y = 0
                    for i = 1,imgui.CalcTextSize(v.act).y/14 do
                        imgui.SetCursorPos(imgui.ImVec2(10,10+y))
                        imgui.Text(tostring(i))
                        y = y + 15
                    end
                    moonloader_reference_imgui(y)
                    imgui.EndPopup()
                end
                if imgui.BeginPopup('rename event '..k) then

                    local name = imgui.ImBuffer(u8(v.name),256)
                    if imgui.InputText('rename events',name) then v.name = u8:decode(name.v) s() end

                    imgui.EndPopup()
                end
                if imgui.BeginPopup('settings rpc '..k) then

                    local rpc = imgui.ImInt(v.rpc)
                    imgui.PushItemWidth(100)
                    if imgui.InputInt('rpc',rpc) then v.rpc = rpc.v s() end
                    imgui.PopItemWidth()

                    local find = 'not find rpc/packet in /lib/samp/events.lua'
                    for INTERFACE,_ in pairs(sampev.INTERFACE) do
                        if INTERFACE ~= 'BitStreamIO' then
                            for RPC,v in pairs(sampev.INTERFACE[INTERFACE]) do
                                if rpc.v == RPC then
                                    find = (type(v[1]) == 'string' and ( type(v[2]) == 'table' and INTERFACE .. ' - '..v[1] or find ) )
                                end
                            end
                        end
                    end
                    imgui.Text(find)

                    imgui.Separator()
                    for kk,vv in pairs(sampev.INTERFACE.BitStreamIO) do
                        for _,f in pairs({'float','string%d+','encodedString4096','bool%d+','int%d+','vector%d+'}) do
                            if kk:find('^'..f..'$') then
                                if imgui.SmallButton('add bs ' .. tostring(kk)) then
                                    table.insert(v.bs,{
                                        ['IF'] = 'OFF',
                                        desc = tostring(#v.bs+1),
                                        bs = kk,
                                    })
                                    s()
                                end
                            end
                        end
                    end

                    imgui.EndPopup()
                end


            end

        end

        imgui.EndChild()

        imgui.End()
    end

end
function EXPORTS.hook(s,f)
    hooks[s] = {c=f}
end
function process_messages(text)
    for k,v in pairs(hooks) do
        v.c(text)
    end
    print('process_messages(return text)',text)
    local cmd,args = text:match('^(%S+)%s*(.*)')
    if cmd == nil then return end
    if cmd == '/notf' then
        notf.v = not notf.v
        s()
        sendTelegramNotification('notifications ' .. (notf.v and 'on' or 'off'))
    end
    if not notf.v then sendTelegramNotification('notifications are turned off..') return end
    if cmd == '/help' then
        local cmds = {['/notf'] = 'notf on/off'}
        for k,v in ipairs(j.commands) do
            table.insert(cmds,v.cmd .. ' - '..v.name)
        end
        sendTelegramNotification(table.concat(cmds, "\n"))
    end
    for k,v in ipairs(j.commands) do
        if cmd == v.cmd then
            local res,errorAct,act = gsubTextByRegulars(v.act,args)
            if res and errorAct == nil then
                local f,errF = load(act)
                if errF == nil then
                    f()
                else
                    sendTelegramNotification('error load lua code\n'..v.name..' ['..v.rpc..']'..v.namerpc..'\n'..errF)
                end
            else
                sendTelegramNotification(errorAct)
            end--errorAct
            return
        end
    end
    sendTelegramNotification('(?)/help')
end

addEventHandler('onReceiveRpc',function(id,bs) events.process(id,bs) end)
addEventHandler('onSendRpc',function(id,bs) events.process(id,bs) end)
events.process = function(id,bs)
    if not notf.v then return {id,bs} end
    local function IF(IF,v1,v2)
        -- {'OFF','find','==','<=','>='}
        if IF == nil then return true end
        return (IF == 'OFF' and true or ( IF == 'find' and tostring(v2):find(tostring(v1)) or ( IF == '==' and v1 == v2 or ( IF == '<=' and v1 <= v2 or ( IF == '>=' and v1 >= v2 or false ) ) ) ) )
    end
    local read = {}
    for _,V in ipairs(j.events) do
        if (V.rpc == id) then
            for kk,vv in pairs(V.bs) do
                read[vv.desc] = sampev.INTERFACE.BitStreamIO.bs_read[vv.bs](bs)
            end
            --
            local bool,act = true,V.act
            for _,bs in pairs(V.bs) do
                act = act:gsub('%{'..bs.desc..'%}',read[bs.desc])
                if not select(1,pcall(function() return IF(bs['IF'],bs.content,read[bs.desc]) end)) then
                    print(V.rpc,V.namerpc,'error if ',err)
                    bool = false
                else
                    if IF(bs['IF'],bs.content,read[bs.desc]) == false then
                        bool = false
                    end
                end
            end
            if bool then
                local f,err = load(act)
                if err == nil then
                    f()
                else
                    print(V.rpc,V.namerpc,'error load lua act ',err)
                end
            end
       end
    end
end

function EXPORTS.sendTelegramNotification(text,...);    sendTelegramNotification(text,...); end
function sendTelegramNotification(text)
    -- text = ((text):format(...))
    print('sendTelegramNotification',text)
    text = text:gsub(' ', '%+'):gsub('\n', '%%0A')
    text = u8:encode(text, 'CP1251')
    local r = requests.get(('https://api.telegram.org/bot%s/sendMessage?chat_id=%s&text=%s'):format(token.v,id.v,text))
    return type(decodeJson(r.text)) == 'table', type(decodeJson(r.text)) == 'table' and decodeJson(r.text) or {}, r
end

function gsubTextByRegulars(args,text)
    if #args == 0 or args:find('^%s+$') then return false,'string nil',args end
    local regular = {}
    for n in args:gmatch('[^\n]+') do
        for l in n:gmatch('{(%S+)}') do
            local orig = l
            l = l:gsub('%d+%:','%.')
            for k,v in pairs(regulars) do
                if k == k:sub(1,1) .. ((l):sub(2,(l:sub(#l,#l):find('%p') and #l-1 or #l ))) then
                    table.insert(regular,{desc=v,orig=orig,reg='('..(k:sub(1,1) .. ((l):sub(2,#l)))..')',result=nil})
                end
            end
        end
    end
    if #regular == 0 then return true,nil,args end
    local prev = '^%s*'
    for k,v in ipairs(regular) do
        prev = prev .. (k == 1 and '' or '%s+') .. v.reg .. (k == #regular and '%s*$' or '')
        local r = {text:match(prev)}
        if r[k] == nil then
            sampAddChatMessage('nil!')
            return false,("regular expression %s({%s}) #%s\n%s"):format(v.reg,v.orig,k,v.desc),args
        end
        v.result = r[k]
    end
    for k,v in ipairs(regular) do
        args = args:gsub('%{'..v.orig..'%p*%}',v.result)
    end
    return true,nil,args
end

function moonloader_reference_imgui(y)
    imgui.SetCursorPos(imgui.ImVec2(10,y+70))
    if imgui.CollapsingHeader('moonader reference') then
        local t = imgui.ImBuffer(0xffff)
        imgui.InputText('search##moonloader_reference.search',moonloader_reference.search)
        if #moonloader_reference.search.v > 0 and not moonloader_reference.search.v:find('^%s+$') then
            for k,v in ipairs(moonloader_reference.reference) do
                if ((v):lower()):find((moonloader_reference.search.v):lower()) then
                    t.v = t.v .. v .. '\n'
                end
            end
            imgui.InputTextMultiline('##moonloader_reference.buffer',t,imgui.ImVec2(400,200),16384)
        end
    end
end

function getn(t); local i = 0;    for k,v in pairs(t) do i = i + 1 end return i;  end
local origsampImguiText = imgui.Text
function imgui.Text(text,...);  origsampImguiText((tostring(text)):format(...));    end

function imgui.AnimButton(name,size,colorLine,duration,thickness)
    local function limit(var,min,max)
        return var < min and min or (var > max and max or var)
    end
    if IMGUI_ANIMBUTTON == nil then IMGUI_ANIMBUTTON = {} end
    if IMGUI_ANIMBUTTON[name] == nil then IMGUI_ANIMBUTTON[name] = {
        clock = -1,
        hovered = false
    } end
    local t,clicked,size,colorLine,duration = IMGUI_ANIMBUTTON[name],false,(size or imgui.ImVec2(0,0)),(colorLine ~= nil and imgui.ColorConvertFloat4ToU32(colorLine) or 0xffffffff),(duration or 1.8)
    imgui.PushStyleColor(23,imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(24,imgui.ImVec4(0,0,0,0))
    imgui.PushStyleColor(25,imgui.ImVec4(0,0,0,0))
    if imgui.Button(name,size) then clicked = true end
    imgui.PopStyleColor(3)
    local dl,p = imgui.GetWindowDrawList(),imgui.GetCursorScreenPos()
    local h = imgui.IsItemHovered()
    if t.hovered ~= h then
        t.clock = os.clock() - (t.clock == -1 and 0 or (os.clock()-t.clock >= 0.5 and 0 or (os.clock()-t.clock <= 0 and 0 or os.clock()-t.clock)))
        t.hovered = h
    end
    size.x = (size.x == 0 and imgui.CalcTextSize(name).x+8 or size.x)
    dl:AddLine(imgui.ImVec2(p.x,p.y-5),
        imgui.ImVec2(p.x+ (
            t.hovered and limit(((os.clock()-t.clock)*size.x)*duration,0,size.x) or limit((size.x-((os.clock()-t.clock)*size.x)*duration),0,size.x)
        ),p.y-5),
        colorLine,thickness or 3)
    local l = (t.hovered and limit(((os.clock()-t.clock)*size.x)*duration,0,size.x) or limit((size.x-((os.clock()-t.clock)*size.x)*duration),0,size.x))
    return clicked
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 5.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 16.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0

    colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end
apply_custom_style()

local origsampAddChatMessage = sampAddChatMessage
function sampAddChatMessage(text,...); origsampAddChatMessage('[TCS]{cccccc}' .. (tostring(text)):format(...),0x294a7a); end

function imgui.CenterText(color,text)
    color = color or imgui.GetStyle().Colors[imgui.Col.Text]
    local width = imgui.GetWindowWidth()
    for line in text:gmatch('[^\n]+') do
        local lenght = imgui.CalcTextSize(line).x
        imgui.SetCursorPosX((width - lenght) / 2)
        imgui.TextColored(color, line)
    end
end

function imgui.TextQuestion(text)
    imgui.SameLine()
    imgui.TextDisabled('(?)')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.Text(text)
        imgui.EndTooltip()
    end
end




function asyncHttpRequest(method, url, args, resolve, reject)
    local request_thread = (require'effil').thread(function (method, url, args)
    local requests = require 'requests'
    local result, response = pcall(requests.request, method, url, args)
    if result then
        response.json, response.xml = nil, nil
        return true, response
    else
        return false, response
    end
    end)(method, url, args)
    if not resolve then resolve = function() end end
    if not reject then reject = function() end end
    lua_thread.create(function()
        local runner = request_thread
        while true do
            local status, err = runner:status()
            if not err then
                if status == 'completed' then
                    local result, response = runner:get()
                    if result then; resolve(response)
                    else;   reject(response)   
                    end
                    return
                elseif status == 'canceled' then
                    return reject(status)
                end
            else
                return reject(err)
            end
        wait(0)
        end
    end)
end