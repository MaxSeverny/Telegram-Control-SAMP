script_name('Telegram Control SAMP')
script_author('vespan')
script_version(5.12)

require 'moonloader'
sampev = require'samp.events'
imgui = require 'imgui'
requests = require 'requests'
encoding = require("encoding"); encoding.default = 'CP1251'; u8 = encoding.UTF8  
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
jPath = getWorkingDirectory() .. '/config/Telegram Control SAMP.json'
j = json(jPath).load({
    token = u8('123:я_хочу_питсы'),
    chat_id = 123123123,
    notf = false,
    events = {
        chat = {},
        dialog = {},
        time = {},
        checker = {},
        codes = {},
    },
    cmds = {
        send = {'/send','Отправить текст/команду к серверу'},
        get = {'/get','Получить информацию о игроке'},
        getstream = {'/getstream','Получить всех игроков в зоне стрима'},
        f8 = {'/f8','Сделать скриншот'},
        fakeafk = {'/ff','Fake-Afk'},
        checker = {'/check','получить инфу об игроках с чекера'},
        custom = {},
    },
})
token = imgui.ImBuffer(j.token,256)
chat_id = imgui.ImBuffer(tostring(j.chat_id),20)

notf = imgui.ImBool(j.notf)
window = imgui.ImBool(false)

active = 'other'
cmds = {
    code = imgui.ImBuffer('sampAddChatMessage("test!")',100000),
    name = imgui.ImBuffer('name',256),
    cmd = imgui.ImBuffer('/cmd',256),
    default = {},
    custom = {},
}
function refreshCmdsCustom()
    cmds.default = {}
    cmds.custom = {}
    for k,v in pairs(j.cmds) do
        if k == 'custom' then
            for kk,vv in ipairs(j.cmds.custom) do
                table.insert(cmds.custom,{imgui.ImBuffer(u8(vv[1]),256), vv[2], vv[3]})
            end
        else
            table.insert(cmds.default,{imgui.ImBuffer(u8(v[1]),256), v[2], k})
        end
    end
end 
refreshCmdsCustom()
update = 0
fakeAfk = false
disconnected = false
function main()
    while not isSampAvailable() do wait(0) end
    wait(500)
    sampRegisterChatCommand('tcs',function() window.v = not window.v end)

    sendTelegramMessage('text')

    lua_thread.create(function()
        while true do wait(500--[[ЗАДЕРЖКА ЧЕКА СООБЩЕНИЯХ(МИЛЛИСЕКУНДЫ)]])
            local invalid_chat_id = false
            local get = false
            local url = 'http://api.telegram.org/bot'..token.v..'/getUpdates?chat_id='..chat_id.v..'&offset=-1' 
            asyncHttpRequest('GET',url,nil,function(r)
                local t = decodeJson(r.text)
                if type(t) == 'table' and t.ok and #t.result > 0 and t.result[1] then 
                    if update == 0 then
                        update = t.result[1].message.date 
                    end
                    if t.result[1].message.date ~= update then
                        update = t.result[1].message.date
                        if t.result[1].message.from.id ~= chat_id.v then
                            invalid_chat_id = true
                        else
                            tg_process_messages(u8:decode(t.result[1].message.text))
                        end
                    end
                    
                    get = true
                end
            end,nil)
            while not get do wait(0) end
            if invalid_chat_id then
                sampAddChatMessage("{D21C1C}Получено сообщение не от вашего чат-айди! {cccccc}Получение следующего сообщения через минуту..")
                wait(60000)
            end

        end
    end)

    while true do wait(0)
        imgui.Process = window.v
        MY_ID = select(2,sampGetPlayerIdByCharHandle(PLAYER_PED))
        MY_NICK = sampGetPlayerNickname(MY_ID)
        MYPOS = {getCharCoordinates(PLAYER_PED)}
        sw,sh = getScreenResolution()

        for k,v in ipairs(j.events.time) do
            if v.time:find('^%S+%:%S+%:%S+$') and os.date("%H:%M:%S") == os.date(v.time) then
                eventsCode('time',v.code,os.date(v.time))
                wait(1000)
            end 
        end

    end
end

function save()
    j.token = token.v
    j.chat_id = chat_id.v
    j.notf = notf.v
    for k,v in ipairs(cmds.default) do
        j.cmds[v[3]] = {u8:decode(v[1].v),v[2]}
    end
    json(jPath).save(j)
end


function imgui.OnDrawFrame()

    if window.v then
        -- imgui.SetNextWindowSize(imgui.ImVec2(500,500),1)
        imgui.SetNextWindowPos(imgui.ImVec2(sw/2-650/2,sh/2-350/2), imgui.Cond.FirstUseEver)
        imgui.Begin('Telegram Control SA-MP',window,32+64)
        local b = {
            'other',
            'token/chat_id',
            'events',
            'cmds',
        }

        imgui.BeginChild('buttons',imgui.ImVec2(150,350),false)
        imgui.Checkbox('notf',notf)
        imgui.TextQuestion(u8'Отправка уведомлений от скрипта к телеграм боту\n/notf для включения уведомлений через бота')
        if imgui.Button('save config',imgui.ImVec2(-1,0)) then
            save()
        end
        for k,v in ipairs(b) do;    if imgui.ActiveButton((v),imgui.ImVec2(-1,30),active==v) then active = v end end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild('active',imgui.ImVec2(500,350),false)

        if active == b[1] then
            imgui.Text(u8([[
author Vespan www.blast.hk/members/295413/
official theme www.blast.hk/threads/62811/
]]):format())

        elseif active == b[2] then
            imgui.InputText('token',token)
            imgui.InputText('chat_id',chat_id,0,0)
            if imgui.Button('test message',imgui.ImVec2(-1,30)) then
                asyncHttpRequest('GET','http://api.telegram.org/bot' .. token.v .. '/sendMessage?chat_id=' .. chat_id.v .. '&text='..'test_message',nil,function(r)
                    local rj = decodeJson(r.text)
                    if rj.ok then
                        sampAddChatMessage('{13E01D}successfull sending!')
                    else
                        sampAddChatMessage('{D21C1C}error code %s - %s',rj.error_code,rj.description)
                    end
                end)
            end
            if imgui.Button(u8'я тупой и не знаю пользоватся гуглом :^)') then
                imgui.OpenPopup('tutorial')
            end
        elseif active == b[3] then

                for n,t in pairs(j.events) do
                    if imgui.Button(u8(n),imgui.ImVec2(-1,350/5-5)) then
                        events.add.codes = {
                            'tgmessage',
                            '/q',
                        }
                        for k,v in ipairs(j.events.codes) do
                            table.insert(events.add.codes,u8(v.name))
                        end
                        events.add.text.v = ''
                        events.add.comboIntCodes.v = 0
                        imgui.OpenPopup(n)
                    end
                    if imgui.BeginPopupModal(n,nil,64) then
                        imgui.Text(u8(events[n].text ))
                        events[n].add()
                        if n ~= 'codes' then
                            imgui.Combo('<code?',events.add.comboIntCodes,events.add.codes)
                        end
                        if imgui.Button('add##'..n,imgui.ImVec2(-1,0)) then
                            imgui.CloseCurrentPopup()
                            events[n].save(j.events[n])
                            if n ~= 'codes' then
                                j.events[n][#j.events[n]].code = events.add.codes[events.add.comboIntCodes.v+1]
                            end
                            json(jPath).save(j)
                        end
                        imgui.Separator()
                        for k,v in ipairs(j.events[n]) do
                            events[n].show(k,v)
                            imgui.SameLine()
                            if imgui.Button('remove##'..k) then
                                table.remove(j.events[n],k)
                                json(jPath).save(j)
                            end
                        end

                        imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()-25,25))
                        if imgui.Button('X') then imgui.CloseCurrentPopup() end

                        imgui.EndPopup()
                    end
                end
        elseif active == b[4] then
            if imgui.Button('custom',imgui.ImVec2(-1,30)) then
                imgui.OpenPopup('add custom cmd')
            end
            imgui.PushItemWidth(150)
            for k,v in ipairs(cmds.default) do
                imgui.InputText(u8(v[2]),v[1])
            end
            imgui.PopItemWidth(#cmds.default)
            imgui.Separator()
            imgui.PushItemWidth(150)
            for k,v in ipairs(cmds.custom) do
                imgui.InputText(u8(v[2]),v[1])
                imgui.TextQuestion(u8(v[3]))
                imgui.SameLine()
                if imgui.Button('copy code##'..k) then
                    setClipboardText(v[3])
                end
                imgui.SameLine()
                if imgui.Button('remove##'..k) then
                    table.remove(j.cmds.custom,k)
                    json(jPath).save(j)
                    refreshCmdsCustom()
                end
            end
            imgui.PopItemWidth(#cmds.custom)


            imgui.TextDisabled(u8'(!)Команды чуствительны к регистру')
            imgui.TextDisabled(u8'(?)Можно использовать команды на русском языке')
        end

        --popup's

        if imgui.BeginPopupModal('add custom cmd',nil,2+64) then
            imgui.NewLine()
            if imgui.BeginMenu('example code') then
                for k,v in ipairs(exampleCodes) do
                    if imgui.BeginMenu('example #'..k) then
                        imgui.Text(u8(v))
                        if imgui.Button('paste') then
                            cmds.code.v = u8(v)
                        end
                        imgui.EndMenu()
                    end
                end
                imgui.EndMenu()
            end
            imgui.InputText('NAME CMD',cmds.name)
            imgui.InputTextMultiline('CODE',cmds.code,imgui.ImVec2(500,300))
            imgui.InputText('CMD',cmds.cmd)
            if imgui.Button("add",imgui.ImVec2(-1,30)) then
                imgui.CloseCurrentPopup()
                table.insert(j.cmds.custom,{
                    u8:decode(cmds.cmd.v),
                    u8:decode(cmds.name.v),
                    u8:decode(cmds.code.v),
                })
                json(jPath).save(j)
                refreshCmdsCustom()
            end

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()-25,25))
            if imgui.Button('X') then imgui.CloseCurrentPopup() end
            imgui.EndPopup()
        end
        if imgui.BeginPopupModal('tutorial',nil,2+64) then
            imgui.Text(u8(tutorial.text[tutorial.int]) .. '       ')
            if imgui.Button(u8'чавоо') then
                tutorial.int = tutorial.int - 1 
                if tutorial.int <= 1 then tutorial.int = 1 end
                imgui.SetWindowPos(imgui.ImVec2(sw/2-(imgui.GetWindowSize().x/2),sh/2-(imgui.GetWindowSize().y/2)),1)
            end
            imgui.SameLine()
            if imgui.Button(u8'идем по некселю') then 
                tutorial.int = tutorial.int + 1 
                if tutorial.int > #tutorial.text then tutorial.int = #tutorial.text end
                imgui.SetWindowPos(imgui.ImVec2(sw/2-(imgui.GetWindowSize().x/2),sh/2-(imgui.GetWindowSize().y/2)),1)
            end

            imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth()-25,25))
            if imgui.Button('X') then imgui.CloseCurrentPopup() end
            imgui.EndPopup()
        end
        imgui.EndChild()



        imgui.End()
    end

end

function onReceivePacket(id, bs)
    if id == 32 or id == 33 or id == 36 or id == 37 and disconnected == false then
        disconnected = true
        sendTelegramMessage('disconnected from the server!')
    end
end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
    if id == 25 and disconnected then
        disconnected = false 
        sendTelegramMessage('connected to server!')
    end
end 

function onSendPacket()
    if fakeAfk then
        return fakeAfk
    end
end 

function sampev.onPlayerJoin(id, color, isNpc, nick)
    for k,v in ipairs(j.events.checker) do
        if v.nick == nick then
            eventsCode('checker',v.code,v.nick)
        end
    end 
end

function sampev.onServerMessage(color,text)
    for k,v in ipairs(j.events.chat) do
        if text:find(v.textfind) then
            eventsCode('chat',v.code,text)
        end
    end 
end
function sampev.onShowDialog(id, style, title, b1, b2, text)
    for k,v in ipairs(j.events.dialog) do
        if (v.style == 0 and text:find(v.textfind) or title:find(v.textfind)) then
            eventsCode('dialog',v.code,text)
        end
    end 
end

function tg_process_messages(text)
    -- sampAddChatMessage(text)
    for k,v in ipairs(cmds.default) do
        if #u8:decode(v[1].v) > 2 and text:find(u8:decode(v[1].v)) then
            notf.v = true
            cmds.help[v[3]](text,u8:decode(v[1].v))
            return 
        end
    end
    for k,v in ipairs(cmds.custom) do
        if #u8:decode(v[1].v) > 2 and text:find(u8:decode(v[1].v)) then
            notf.v = true
            local f,e = load(v[3])
            if e ~= nil then
                sampAddChatMessage(e)
                sendTelegramMessage('error code(%s)\n%s',u8:decode(v[2]),e)
            else
                f()
            end
            return 
        end
    end
    if text:find('^/help') then
        local t = {}
        for k,v in ipairs(cmds.default) do
            table.insert(t,v[1].v..'-'..u8(v[2])..';')
        end
        table.insert(t,'---------')
        for k,v in ipairs(cmds.custom) do
            table.insert(t,v[1].v..'-'..u8(v[2])..','..u8(v[3])..';')
        end

        sendTelegramMessage(table.concat(t,'\n'))
        return
    end
    sendTelegramMessage('(?)help cmds /help')
end

function eventsCode(ev,n,text)
    ev = '['..ev..']\n'
    if n == 'tgmessage' then
        sendTelegramMessage(ev..text)
    elseif n == '/q' then
        sendTelegramMessage(ev..text..'\n/q!')
        sampProcessChatInput('/q')
    else
        for k,v in ipairs(j.events.codes) do
            if v.name == n then
                local f,e = load(v.code)
                if e ~= nil then
                    sampAddChatMessage(e)
                    sendTelegramMessage('error event code(%s)\n%s\n \n%s%s',v.name,e,ev,text)
                else
                    f()
                    sendTelegramMessage(ev..text..'\n \n'..v.code)
                end
            end
        end
    end
end

function EXPORTS.send(text,...)
    sendTelegramMessage(text,...)
end

function sendTelegramMessage(text,...)
    if not notf.v then return end
    text = (tostring(text)):format(...)
    text = text:gsub('{......}', '')
    text = text:gsub(' ', '%+')
    text = text:gsub('\n', '%%0A')
    text = u8:encode(text, 'CP1251')
    requests.get('http://api.telegram.org/bot' .. token.v .. '/sendMessage?chat_id=' .. chat_id.v .. '&text='..text)
    -- asyncHttpRequest('GET','http://api.telegram.org/bot' .. token.v .. '/sendMessage?chat_id=' .. chat_id.v .. '&text='..text, nil,function(result) end)
end

exampleCodes = {
    [[local text = 'Раз!\nДва!\nтри!\nхочу питсу'
        lua_thread.create(function()
            for l in text:gmatch('[^\n]+') do
                sampSendChat(l)
                wait(1000)
            end
        end)
    ]],
    [[setCharHealth(PLAYER_PED,0)]],
    [[sendTelegramMessage('text!')]],
    [[setCharCoordinates(PLAYER_PED,0,0,0)]]
}
cmds.help = {
    ['checker'] = 
        function(text,var) 
            local t = {}
            for k,v in ipairs(j.events.checker) do
                local id = nil
                local h = nil
                for i = 1,1000 do
                    if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == v.nick then
                        id = i
                        h = select(2,sampGetCharHandleBySampPlayerId(id))
                    end
                end
                table.insert(t,
                    string.format('%s[%s] %s',v.nick,(id == nil and 'DISCONNECTED' or id),
                        (id == nil and '' or (doesCharExist(h) and 'ON ZONE-STREAM' or '') )
                    )
                )
            end
            sendTelegramMessage(table.concat(t,'\n'))
        end,
    ['send'] = 
        function(text,var) 
            local t = text:match('^'..var..' (.+)')
            if t == nil then sendTelegramMessage('argument nil!') return end
            sampSendChat(t) 
        end,
    ['get'] = 
        function(text,var) 
            local ip,port = sampGetCurrentServerAddress()
            sendTelegramMessage(
                string.format('%s[%s]\nserver %s[%s:%s]\nscore %s,clist(hex) %s\nmoney %s',
                    MY_NICK,MY_ID,sampGetCurrentServerName(),ip,port,
                    sampGetPlayerScore(MY_ID),bit.tohex(sampGetPlayerColor(MY_ID)),getPlayerMoney(playerPed)
                )
            )
        end,
    ['getstream'] = 
        function(text,var) 
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
            sendTelegramMessage(table.concat(p,'\n'))
        end, 
    ['f8'] = 
        function(text,var) 
            setVirtualKeyDown(VK_F8,true)
            wait(5)
            setVirtualKeyDown(VK_F8,false)
        end, 
    ['fakeafk'] = 
        function(text,var) 
            fakeAfk = not fakeAfk
            sendTelegramMessage('fakeafk %s',fakeafk)
        end, 
}

events = {
    ['add'] = {
        text = imgui.ImBuffer(256),
        text2 = imgui.ImBuffer(256),
        code = imgui.ImBuffer(10000),
        comboInt = imgui.ImInt(0),

        comboIntCodes = imgui.ImInt(0),
        codes = {},
    },
    ['codes'] = {
        text = 'Что будет происходит после определенных событий?',
        show = function(k,v)
            imgui.Text(u8(v.name))
            imgui.TextQuestion(u8(v.code))
            imgui.SameLine()
            if imgui.Button('copy code##'..k) then
                setClipboardText(v.code)
            end
        end,
        add = function()
            imgui.NewLine()
            if imgui.BeginMenu('example code') then
                for k,v in ipairs(exampleCodes) do
                    if imgui.BeginMenu('example #'..k) then
                        imgui.Text(u8(v))
                        if imgui.Button('paste') then
                            events.add.code.v = u8(v)
                        end
                        imgui.EndMenu()
                    end
                end
                imgui.EndMenu()
            end

            imgui.InputText('name',events.add.text)
            imgui.InputTextMultiline('CODE',events.add.code,imgui.ImVec2(500,300))
        end,
        save = function(t)
            table.insert(t,{
                name = u8:decode(events.add.text.v),
                code = u8:decode(events.add.code.v),
            })
        end
    },



    ['checker'] = {
        text = 'Событие когда игрок зайдет в игру',
        show = function(k,v)
            imgui.Text(u8(v.nick))
            imgui.TextQuestion(u8(v.code))
        end,
        add = function()
            imgui.InputText('nick_name',events.add.text)
        end,
        save = function(t)
            table.insert(t,{nick=u8:decode(events.add.text.v)})
        end
    },
    ['chat'] = {
        text = 'Событие по тексту в чате',
        show = function(k,v)
            imgui.Text(u8(v.textfind))
            imgui.TextQuestion(u8(v.code))
        end,
        add = function()
            imgui.InputText('text',events.add.text)
        end,
        save = function(t)
            table.insert(t,{textfind=u8:decode(events.add.text.v)})
        end
    },

    ['dialog'] = {
        text = 'Событие по тексту диалоге',
        show = function(k,v)
            imgui.Text(u8(v.textfind) .. (v.style == 0 and u8'(поиск по тексту)' or u8'(поиск по заголовку)'))
            imgui.TextQuestion(u8(v.code))
        end,
        add = function()
            imgui.Combo('',events.add.comboInt,{u8'Поиск по тексту',u8'Поиск по заголовку'})
            imgui.InputText('text',events.add.text)
        end,
        save = function(t)
            table.insert(t,{
                textfind=u8:decode(events.add.text.v),
                style=events.add.comboInt.v,
            })
        end
    },

    ['time'] = {
        text = [[Событие по времени на ПК
(?)присуствуют регулярные выражения:
%H - возвращает текущий чат,
%M - возвращает текущую минуту,
%S - возвращает текущую секунду,
можно так сделать уведомление за 5 минут по пейдея(%H:55:00)]],
        show = function(k,v)
            imgui.Text(u8(v.time))
        end,
        add = function()
            imgui.InputText('time(format H:M:S)',events.add.text)
        end,
        save = function(t)
            table.insert(t,{time=u8:decode(events.add.text.v)})
        end
    },
}
tutorial = {
    int = 1,
    text = {  
        'заказать мне питсу',
        'поставить лайк на тему telegram control samp и под подушкой найдете iphone 2g',
        'открыть телеграм',
        'навестить курсором на поиск',
        'написать через клавиатуру',
        '@BotFather (http://t.me/BotFather)',
        'создать бота /newbot',
        'ввести название бота(любое)',
        'ввести username бота с окончание/началом на bot(пример HochyPitsybot)',
        'после создания BotFather сразу вам дает токен бота(214241421:asfljsafpjpadsaghr)',
        'копируете токен бота после чего вставляете в скрипт(поле token)',
        'для чат айди заходим в телеграм,наводим курсором на поиск',
        'и пишет через клавиатуру',
        '@my_id_bot (http://t.me/my_id_bot)',
        'стартуем бота, если надо то пишем ему /start и он сразу дает нам - наш чат ид',
        'копируем чат айди и вставляем в скрипт(поле chat_id)',
        'заработало?',
        'и че блять в этом сложного?дохуя мне писали "где-как взять токен-чатид" пиздец..',
        'с вам деньгу мне на питсу',
    }
}

function imgui.ActiveButton(label,size,bool)
    local b = false
    if bool then
        imgui.PushStyleColor(23,imgui.GetStyle().Colors[25])
    end
    if imgui.Button(label,(size and size or imgui.ImVec2(0,0))) then b = true end
    if bool then imgui.PopStyleColor() end
    return b
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
    style.ScrollbarSize = 13.0
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
-- rgb(66.30, 150.45, 249.90,255)
local origsampAddChatMessage = sampAddChatMessage
function sampAddChatMessage(text,...); origsampAddChatMessage('[TCS]{cccccc}' .. (tostring(text)):format(...),0x4296fa); end

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