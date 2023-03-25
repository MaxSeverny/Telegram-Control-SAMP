__version__ = '4.4.3.1' 

--[[
+ после выключение уведомлений - выключаеться AutoReboot;
+ Теперь метод поиска текста(my events) в чате-диалогах,не зависимости от заглавных букв в чате-диалоге;
* fixes

##  ## #####  ####  #####   ####  ##   ##
##  ## ##    ##     ##  ## ##  ## ###  ##
##  ## ####   ####  #####  ###### ## # ##
 ####  ##        ## ##     ##  ## ##  ###
  ##   #####  ####  ##     ##  ## ##   ##


]]

script_name('Telegram Control SAMP (TCS)') 
script_author('Vespan')  
script_version(__version__)
script_url('blast.hk/threads/62811/')

--[[
-Спасибо @FooOoott что ответил на мои тупые вопросы :)
-Автор Сообщений-Телеграма - ronny_evans / ronnyscripts -- https://www.blast.hk/threads/57120/
-Проверку на процент голода взял из скрипта BankHelper.lua
-Fake AFK - Anti AFK взял з AFK TOOLS 

-Большое спасибо k1nterr0 за решение многих проблем в скрипте! 
]]
 
if not doesDirectoryExist('moonloader/config/Telegram Control SAMP') then
    createDirectory('moonloader/config/Telegram Control SAMP')
end
 
-- LIBS

if not doesFileExist('moonloader\\resource\\fonts\\fontawesome-webfont.ttf') then
    error('not found font(..moonloader/resource/fonts/fontawesome-webfont.ttf)')
end

require 'lib.moonloader'
AutoReboot           = nil

ffi                 = require 'ffi'
memory              = require 'memory'
imgui               = require 'imgui'
res_fa,fa           = pcall(require, 'faIcons')
assert(res_fa, 'not found faIcons(../moonloader/lib/faIcons.lua)')
fa_glyph_ranges     = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
res_sampev,sampev   = pcall(require, 'lib.samp.events')
assert(res_sampev, 'not found SAMP.lua(../moonloader/lib/samp/events.lua)')
inicfg              = require 'inicfg'
effil               = require("effil")
encoding            = require("encoding")
encoding.default    = 'CP1251'
u8 = encoding.UTF8

path = 'moonloader\\config\\Telegram Control SAMP'

local Config = inicfg.load({
    Script = {

        AutoReboot = true,
        Cmd = '/tcs'

    },
    Notifications = {

        TimeStamp = true,
        Dialog = true

    },
    Telegram = {

        Bot = true,
        ChatId = '',
        Token = 'who?'

    },
    Events = {
        PayDay = false, 
        KillMe = false,
        Capt = false,

        DoPayDaya = 40,

        NotificationFlood = false,

        Checker = false, 
        CheckerMode = 0

    },

    Cmds = {

        GetStream = '/getstream',
        Send = '/send',
        Chat = '/chat',
        Time = '/time',
        Quit = '/q',
        FakeAFK = '/fakeafk',
        AntiAFK = '/antiafk',
        ScreenShot = '/screen',
        Stats = '/stats',

        Dialog_Input = '/d.input',
        Dialog_List = '/d.list',
        Dialog_Close = '/d.close'


    },

    AutoFood = {
        Bool = false,
        Timer = 15,
        Food = '/cheeps',
        Method = 1,
        After = '',
    },
    AutoHeal = { --#AUTOHEAL
        Bool = false,
        HP = 30,
        Heal = '/smoke'
    },

}, '..\\config\\Telegram Control SAMP\\Config.ini')

local ImguiPage = 0
-- TELEGA
chat_id = Config.Telegram.ChatId
local updateid

-- IMGUI WINDOW
local imgui_window = imgui.ImBool(false)
local PushMessage_imgui = imgui.ImBool(false)
local LoadingScript_imgui = imgui.ImBool(false)

-- INPUT

local Input = {

    MyEvents_MultilineText1 = imgui.ImBuffer(65536),
    MyEvents_Text1 = imgui.ImBuffer(256),
    MyEvents_Text2 = imgui.ImBuffer(256),
    MyEvents_SendClient = imgui.ImBuffer(256),

    CheckerAdd = imgui.ImBuffer(256),

    Cmd = imgui.ImBuffer(tostring(Config.Script.Cmd), 256),
    ChatId = imgui.ImBuffer(tostring(Config.Telegram.ChatId), 256),
    Token = imgui.ImBuffer(tostring(Config.Telegram.Token), 256),

    Cmd_Stats = imgui.ImBuffer(tostring(Config.Cmds.Stats), 256),
    Cmd_ScreenShot = imgui.ImBuffer(tostring(Config.Cmds.ScreenShot), 256),
    Cmd_Send = imgui.ImBuffer(tostring(Config.Cmds.Send), 256),
    Cmd_Time = imgui.ImBuffer(tostring(Config.Cmds.Time), 256),
    Cmd_Quit = imgui.ImBuffer(tostring(Config.Cmds.Quit), 256),
    Cmd_FakeAFK = imgui.ImBuffer(tostring(Config.Cmds.FakeAFK), 256),
    Cmd_AntiAFK = imgui.ImBuffer(tostring(Config.Cmds.AntiAFK), 256),
    Cmd_Chat = imgui.ImBuffer(tostring(Config.Cmds.Chat), 256),
    Cmd_GetStream = imgui.ImBuffer(tostring(Config.Cmds.GetStream), 256),

    Cmd_Dialog_Input = imgui.ImBuffer(tostring(Config.Cmds.Dialog_Input), 256),
    Cmd_Dialog_List = imgui.ImBuffer(tostring(Config.Cmds.Dialog_List), 256),
    Cmd_Dialog_Close = imgui.ImBuffer(tostring(Config.Cmds.Dialog_Close), 256),

    Cmd_Food = imgui.ImBuffer(tostring(Config.AutoFood.Food), 256),
    AfterAutoFood = imgui.ImBuffer(tostring(Config.AutoFood.After), 256),

    Cmd_Health = imgui.ImBuffer(tostring(Config.AutoHeal.Heal), 256)

}

-- IMINT
local ImInt = {

    MethodAutoFood = imgui.ImInt(Config.AutoFood.Method), -- 1=timer,2=arz satiety
    DoPayDaya = imgui.ImInt(Config.Events.DoPayDaya),
    Checker = imgui.ImInt(Config.Events.CheckerMode),
    TimerAutoFood = imgui.ImInt(Config.AutoFood.Timer),
    HP = imgui.ImInt(Config.AutoHeal.HP),

    MyEvents_Slider1 = imgui.ImInt(700),
    MyEvents_Combo1 = imgui.ImInt(0),
    MyEvents_Combo2 = imgui.ImInt(0),

    MyEvents_H = imgui.ImInt(12),
    MyEvents_M = imgui.ImInt(30),
    MyEvents_S = imgui.ImInt(00),

}

-- TOGGLEBUTTON 

local ToggleButton = {

    MyEvents_Screenshot = imgui.ImBool(false),

    AutoReboot = imgui.ImBool(Config.Script.AutoReboot),
    TimeStamp = imgui.ImBool(Config.Notifications.TimeStamp),
    Bot = imgui.ImBool(Config.Telegram.Bot),
    Notf_Dialog = imgui.ImBool(Config.Notifications.Dialog),
    Checker = imgui.ImBool(Config.Events.Checker),
    PayDay = imgui.ImBool(Config.Events.PayDay),
    KillMe = imgui.ImBool(Config.Events.KillMe),
    Capt = imgui.ImBool(Config.Events.Capt),
    NotificationFlood = imgui.ImBool(Config.Events.NotificationFlood),
    AutoFood = imgui.ImBool(Config.AutoFood.Bool),
    AutoHeal = imgui.ImBool(Config.AutoHeal.Bool)

}

-- #TEXT #UPDATELOG #UPDATE LOG
tutorial = [[
Токен:
    Что бы работало всё нормально,необходимо создать бота в телеграмме
    Заходим в телеграмм,и в поиске ищим @BotFather
    Пишем /newbot
    Сначала вводим ник бота,можно любой
    Потом уже username бота,вводим любой
    .. главное шоб была приписка bot в конце или в начале
    Всё,мы создали бота.
    Теперь можно скопировать токен бота,и ввести в скрипт;
chatid:
    Честно,сам не понял шо такое chatid
    Но он необходим для работы скрипта
    Заходим в телеграмм,и ищим бота @my_id_bot
    Необходимо написать /start и он напишет наш chatid
    Копируем,и вставляем в скрипт 
Нажимаем Проверить,и если вы всё сделали правильно,приходит тестовое 
.. сообщение в ваш телеграмм-бот.
]]  

nText, nClock = {}, 0
PushMessageAlpha = 0.00
PushMessageAnimBool = false


-- #BOTLOCALS
BotChat = false
FakeAfk = false
AntiAfk = false

-- #OTHER 
NewBalance = 0 
OldBalance = -999999999999999999999999999999999999999

disconnected = false 
TimerAutoFood_ = 0
idDialog = 0
ShowToken = true
ShowChatId = true
FakeAFKTime = 0

 Raw = {version =nil,info=nil,other=nil}

printToLogBool = false -- если поставить значение true ,то всё сообщение которые посылаются в телеграм,или даже когда уведомление будут выключены
-- сообщение будут записываться в текстовый документ по пути moonloader/config/Telegram Control SAMP/logs/
-- -зачем? Мне так удобно выяснять из-за чего краш игры или скрипта
-- иногда забуду,и запущу игру,не посмотрев moonlaoder.log,или забыв его сохрнить на рабочий стол.

function main() -- #main()

    if not isSampLoaded() and not isSampfuncsLoaded() then return end 
    while not isSampAvailable() do wait(0) end

    GetRaw()

    if doesFileExist('moonloader\\config\\Telegram Control SAMP\\AutoRebootTelegramControlSAMP.lua') then 
        AutoReboot = import 'moonloader\\config\\Telegram Control SAMP\\AutoRebootTelegramControlSAMP.lua'
        AutoReboot.getfilename()
    else
        printToLog('{FF0000}У вас не скачен {00c8ff}AutoRebootTelegramControlSAMP.lua{FF0000}!')
    end  

    if not doesFileExist('moonloader\\config\\Telegram Control SAMP\\My Events.txt') then 
        e = io.open('moonloader\\config\\Telegram Control SAMP\\My Events.txt', 'w')
        e:write('%w+_%w+%[%d+%] говорит')
        e:close()    
    elseif not doesFileExist('moonloader\\config\\Telegram Control SAMP\\Checker.txt') then     
        f = io.open('moonloader\\config\\Telegram Control SAMP\\Checker.txt', 'w')
        f:write('')
        f:close()        
    end


    LoadingScript_imgui.v = true

    afk = os.clock() - gameClock()
    getLastUpdate()
 
    workpaus(AntiAfk)

   lua_thread.create(get_telegram_updates)
   lua_thread.create(AutoFood)
   lua_thread.create(KillMe)
   lua_thread.create(AutoHeal)
   lua_thread.create(other)
   lua_thread.create(loading)
   lua_thread.create(MyEvents_HP_Car)
   lua_thread.create(MyEvents_Time)
    --lua_thread.create(DoPayDaya)
 

    sampfuncsRegisterConsoleCommand('1', function() imgui.Text(1) end)

    while true do wait(0)

    if ToggleButton.PayDay.v and os.date("%M:%S") == ImInt.DoPayDaya.v .. ':00' then 
        --sendTelegramNotificationFlood('[SAMP | PayDay]:\n ' .. ImInt.DoPayDaya.v .. ' Минут До PayDaя!')          
        sendTelegramNotificationFlood("[Samp | PayDay]:\nЩас пейдей будет!\n(таймер выставлен на " .. ImInt.DoPayDaya.v .. ' минут)')
        wait(1000)
    end     

    if OldBalance < getPlayerMoney(player) then -- взял с salary 
        NewBalance = getPlayerMoney(player) - OldBalance
    elseif OldBalance > getPlayerMoney(player) then
        NewBalance = -OldBalance + getPlayerMoney(player)
    end            

        imgui.Process = imgui_window.v or PushMessage_imgui.v or LoadingScript_imgui.v    

    if PushMessageAnimBool then 
        if PushMessageAlpha ~= 0.75 then PushMessageAlpha = PushMessageAlpha + 0.08 end
    else
        if PushMessageAlpha ~= 0.00 then PushMessageAlpha = PushMessageAlpha - 0.05 wait(10) end

    end

    if (PushMessageAlpha > 0.75) then PushMessageAlpha = 0.75 end
    if (PushMessageAlpha < 0.00) then PushMessageAlpha = 0.00 end  

    if (PushMessageAlpha ~= 0.00) then PushMessage_imgui.v = true else PushMessage_imgui.v = false end          

    if nClock ~= 0 then
        if (os.clock() - nClock) < 3 then
            if not PushMessageAnimBool then
                PushMessageAnimBool = true
            end
        else
            PushMessageAnimBool = false
            nText = {}
            nClock = 0
        end
    end


    end
end

function onReceivePacket(id, bs)
    lua_thread.create(function()
        if id == 32 or id == 33 or id == 36 or id == 37 and disconnected == false --[[шоб не флудило~]] then
            --printToLog('{FF0000}DISCONNECT (' .. os.date('%H:%M:%S') .. ')')
            disconnected = true 
            sendTelegramNotification('[SAMP]:\nСоеденение с сервером было разорвано!')
            --LoadingScript_imgui.v = true 
            --wait(15000)
        end
    end)
end

function onSendRpc(id, bitStream, priority, reliability, orderingChannel, shiftTs)
    if id == 25 and disconnected then -- RPC_CLIENTJOIN
        disconnected = false 
        sendTelegramNotification('[SAMP]:\nВы зашли на сервер!')
    end
end  

function onWindowMessage(msg, wparam, lparam) 
    if wparam == VK_ESCAPE and imgui_window.v then -- на ESCAPE закрыть основное имгуи окно(imgui_window) 
        consumeWindowMessage(true, true)
        imgui_window.v = false
    end

    if wparam == VK_Y and LoadingScript_imgui.v then 
        OldBalance = getPlayerMoney(player)
        LoadingScript_imgui.v = false 

            if not ToggleButton.Bot.v then
                PushMessage(u8'Успешно загружен!\n\n  '.. fa.ICON_VOLUME_OFF..u8' Сообщение выключены\nОткрыть имгуи-окно /'..Config.Script.Cmd)
            else
                PushMessage(u8'Успешно загружен!\nОткрыть имгуи-окно /'..Config.Script.Cmd)
            end

            sampRegisterChatCommand(tostring(Config.Script.Cmd), function() imgui_window.v = not imgui_window.v end)

            ip, port = sampGetCurrentServerAddress()
            sendTelegramNotification('[SAMP | Connected] \n' .. sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) .. '\n\n' .. sampGetCurrentServerName() .. ' \n' .. ip .. ':' .. port .. '\nОнлайн:' .. sampGetPlayerCount(false))    
    end

end

function imgui.OnDrawFrame() -----------------------------------------------------------------------

    sw, sh = getScreenResolution()

    imgui.ShowCursor = imgui_window.v

    if imgui_window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(750, 500), imgui.Cond.FirstUseEver)
        local function GetTextUpdate()
            if __version__ ~= Raw.version and Raw.version ~= nil then 
                return u8' | Вышла обнова > '..Raw.version..'!'
            else
                return ''
            end
        end
        imgui.Begin(fa.ICON_TELEGRAM .. ' Telegram Control SAMP | ' .. __version__ .. '' .. GetTextUpdate(), imgui_window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoFocusOnAppearing)
            imgui.BeginChild('#a', imgui.ImVec2(220, 465), true)
                imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(0.26, 0.59, 0.98, 0.20))
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.26, 0.59, 0.98, 0.40))
                imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 10)
                    if imgui.Button('reload', imgui.ImVec2(100,20)) then thisScript():reload() end
                    imgui.SameLine()
                    if imgui.Button('unload', imgui.ImVec2(100,20)) then thisScript():unload() end
                imgui.PopStyleColor(2)
                imgui.PopStyleVar()

                if imgui.ToggleButton(u8'Anti-AFK', imgui.ImBool(AntiAfk)) then 
                    AntiAfk = not AntiAfk 
                    workpaus(AntiAfk)
                    PushMessage(AntiAfk and u8'AntiAFK:Включено!\nМожете свернуть игру!' or u8'AntiAFK:Выключено!')
                    --printStringNow(AntiAfk and '1' or '0', 1500)
                end
                if imgui.ToggleButton(u8'Включить Уведомления ' .. fa.ICON_COMMENTS, ToggleButton.Bot) then 
                    PushMessage(ToggleButton.Bot.v and fa.ICON_VOLUME_UP..u8' Уведомления на ваш Телеграмм-Аккаунт будут присылатся' or fa.ICON_VOLUME_OFF .. u8' Уведомления на ваш телеграмм-аккаунт не будут присылатся!')
                    if ToggleButton.Bot.v then 
                        sendTelegramNotification('[SAMP | Script]:\nУведомления - Включены!')
                    else
                        ToggleButton.AutoReboot.v = false
                    end
                end
                imgui.TextQuestion(u8'Когда функция выключена - уведомления не будут присылатся в телеграмм')
                if ToggleButton.AutoReboot.v and not ToggleButton.Bot.v then
                    ToggleButton.AutoReboot.v = false
                end 
                if ToggleButton.Bot.v then
                    if not doesFileExist('moonloader\\config\\Telegram Control SAMP\\AutoRebootTelegramControlSAMP.lua') then 
                        imgui.Separator()

                        imgui.ButtonHex(u8'                   У вас нет\nAutoRebootTelegramControlSAMP.lua', 0x00A72C2C, imgui.ImVec2(-1,40)) if imgui.IsItemHovered() then imgui.OpenPopup('not found nAutoRebootTelegramControlSAMP.lua') end
                    
                    else
                        imgui.ToggleButton(u8'Auto Reboot', ToggleButton.AutoReboot) 
                        imgui.TextQuestion(u8'Если включить функцию\nПосле краша скрипта,он заново загрузится\nСпециально добавил что можно включить/выключить\nПотому что,если вы перезагрузите через другой скрипт (CONTROL + R reload_all.lua)\nТо...как бы скрипт раздвоится,если ещё раз повторить,скрипт разтроится и так до бесконечности')
                    end
                end

                imgui.Separator()

                if imgui.ButtonHex(fa.ICON_FLOPPY_O .. u8' Сохранить всё Настройки', 0x00fbff00, imgui.ImVec2(-1, 25)) then save() end       
                if imgui.Button(fa.ICON_INFO, imgui.ImVec2(-1,30)) then ImguiPage = 0 end
                imgui.Separator()              
                if imgui.Button(fa.ICON_TERMINAL ..  u8' Команды', imgui.ImVec2(-1, 30)) then ImguiPage = 1 end
                if imgui.Button(fa.ICON_TELEGRAM ..  u8' Бот', imgui.ImVec2(-1, 30)) then ImguiPage = 2 end
                if imgui.Button(fa.ICON_COGS .. u8' Настройка Бота', imgui.ImVec2(-1, 30)) then  ImguiPage = 3 end
                if imgui.Button(fa.ICON_LIST_OL .. ' My Events', imgui.ImVec2(-1,30)) then
                    if not doesFileExist('moonloader/config/Telegram Control SAMP/My Events.txt') then
                        file = io.open(path..'\\My Events.txt', 'w')
                        file:write('')
                        file:close()
                    end
                    ImguiPage = 4 
                end

                --PopupText()

                if imgui.BeginPopup('not found nAutoRebootTelegramControlSAMP.lua') then 
                    imgui.TextColored(imgui.ImVec4(1,0,0,1), u8'                          У вас нет AutoRebootTelegramControlSAMP.lua!')
                    imgui.Separator()

                    if imgui.ButtonHex('download', 0x0000ff00, imgui.ImVec2(-1,20)) then 
                        download('https://raw.githubusercontent.com/Vespan/Telegram-Control-SAMP/main/AutoRebootTelegramControlSAMP.lua',
                        'moonloader\\config\\Telegram Control SAMP\\AutoRebootTelegramControlSAMP.lua', 
                        'AutoRebootTelegramControlSAMP.lua')
                    end

                    imgui.CenterText(u8'Файл прикреплен к теме на бластхаке!\nУстановить файл по пути..')
                    imgui.Text(u8' moonloader/config/Telegram Control SAMP/AutoRebootTelegramControlSAMP.lua')
                    if imgui.CollapsingHeader(u8'                                           Зачем он мне?') then 
                        imgui.CenterText(u8([[
Скрипт любит часто крашится
Если скрипт в пару секунд отправит вам несколько сообщений
То он крашнится
Хз из-за чего :*

Когда Telegram Control SAMP крашнется 
То этот скрипт перезагрузит его]]))
                    end
                    imgui.EndPopup()
                end

                imgui.Separator()

                imgui.CenterText(u8('Автор:Vespan'))
                imgui.CenterText('blast.hk/threads/62811/')   

                imgui.Separator()

            imgui.EndChild()

        imgui.SameLine(235)
        imgui.BeginChild('#okno', imgui.ImVec2(525, 450))
            if ImguiPage == 0 then ----------------------------------------------------------------

                imgui.FontSize(1.3)
                imgui.CenterText(u8'!Просьба особым одаренным!\nНе писать мне в телеграм по всякой хуйне', imgui.ImVec4(255.0,0.0,0.0,1.0))
                imgui.FontSize(1.0)

                imgui.Separator()
 
                if Raw.info ~= nil and Raw.other ~= nil then
                    imgui.CenterText((Raw.info))
                    imgui.CenterText((Raw.other))
                end

                elseif ImguiPage == 1 then  -----#CMDS-----------------------------------------------------------   

                imgui.PushItemWidth(150)
                if imgui.InputText(fa.ICON_TERMINAL .. u8' Открыть imgui окно', Input.Cmd, imgui.InputTextFlagsEnterReturnsTrue) then     
                    sampUnregisterChatCommand(Config.Script.Cmd)
                    sampRegisterChatCommand(tostring(Input.Cmd.v), function() imgui_window.v = not imgui_window.v end)
                    Config.Script.Cmd = Input.Cmd.v  
                    save()
                end  imgui.TextDisabled(u8'Нажмите ENTER для регистрации новой команды')
                imgui.Separator()
                    imgui.FontSize(1.2) imgui.Text(u8'Настройка команд для Телеграмм-Бота') imgui.FontSize(1.0)
                imgui.Separator()

                -- Checker [Telega Conltrol].txt
                imgui.PushItemWidth(150)
                imgui.InputText(u8'Отправить сообщение/команду в чат', Input.Cmd_Send)
                imgui.InputText(u8'Чат из сампа в > телеграмм чат', Input.Cmd_Chat) 
                imgui.InputText(u8'AntiAFK', Input.Cmd_AntiAFK)
                imgui.InputText(u8'FakeAFK', Input.Cmd_FakeAFK)
                imgui.InputText(u8'Сделать скриншот + /time', Input.Cmd_ScreenShot)
                imgui.InputText(u8'Посмореть сколько время я отыграл БЕЗ AFK/С AFK', Input.Cmd_Time) 
                imgui.InputText(u8'Выход из gta_sa.exe', Input.Cmd_Quit)
                imgui.InputText(u8'Получить информацию об игроке', Input.Cmd_Stats)
                imgui.InputText(u8'Получить информацию об игроков в зоне стрима', Input.Cmd_GetStream)

                imgui.Separator()
                    imgui.FontSize(1.2) imgui.Text(u8'Команды для взаимодействий Диалоговых Окон') imgui.FontSize(1.0)
                imgui.Separator()
                --Input.Cmd_Dialog_Input

                imgui.InputText(u8'Отправить в поле(input) текст', Input.Cmd_Dialog_Input)
                imgui.InputText(u8'Выбрать пункт в диалоге', Input.Cmd_Dialog_List)
                imgui.InputText(u8'Закрыть Диалог', Input.Cmd_Dialog_Close)
                imgui.PopItemWidth()

                imgui.Separator()
            elseif ImguiPage == 2 then -----#BOT-----------------------------------------------------------       
                if imgui.Button(u8'Показать##chat_id') then ShowChatId = not ShowChatId end
                    imgui.SameLine()
                    imgui.PushItemWidth(100)
                    imgui.InputText(fa.ICON_ID_CARD_O .. u8' chatid', Input.ChatId, ShowChatId and imgui.InputTextFlags.Password) 
                    --imgui.TextQuestion(u8'Как узнать свой chat id?\nПишите в поиск или в канал/группу - @my_id_bot\nР у вас будет написано:\nYour ID is .....\nЦифры нужно вставить в поле и нажать Сохранить!')
                    if imgui.Button(u8'Показать##token') then ShowToken = not ShowToken end
                    imgui.SameLine()
                    imgui.PushItemWidth(250)
                    imgui.InputText(fa.ICON_USER_SECRET .. u8' Токен', Input.Token, ShowToken and imgui.InputTextFlags.Password) 
                    if #Input.Token.v > 10 and #Input.ChatId.v > 5 then
                        imgui.TextColored(imgui.ImVec4(1,0,0,1),u8'Обезательно сохраните настройки!')
                    end
                    imgui.TextDisabled(u8'Если команды не работают в телеграмме - перезайдите в игру!')
                    if imgui.Button(u8'Проверить', imgui.ImVec2(-1, 30)) then 
                        if ToggleButton.Bot.v then
                            PushMessage(u8'Тестовое сообщение отправленно в телеграмм!')
                            sendTelegramNotification('[Script]:\nПроверка Скрипта!\n\n' .. sampGetCurrentServerName() .. '\n' .. sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) .. '[' .. select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)) .. ']')
                        else 
                            PushMessage(u8'Уведомления выключены!\nДля проверки включите уведомления*')
                        end
                    end
                    imgui.Separator()
                    if imgui.CollapsingHeader(u8('Кавооо')) then                      
                        imgui.Text(u8(tutorial))    
                        imgui.Separator()      
                    end

            elseif ImguiPage == 3 then ---------#BOTSETTINGS #SETTINGSBOT-------------------------------------------------------

                imgui.ToggleButton(u8'Авто-Еда', ToggleButton.AutoFood)
                if ToggleButton.AutoFood.v then 
                    imgui.Text(u8'Метод:') imgui.SameLine()
                    imgui.RadioButton(u8'Через Таймер', ImInt.MethodAutoFood, 1) imgui.SameLine() imgui.Text(' | ') imgui.SameLine()
                    imgui.RadioButton(u8'Через Textdraw(only arz)', ImInt.MethodAutoFood, 2) imgui.TextQuestion(u8'Работает только на аризоне,и если у вас включен старый индикатор голода(textdraw)\n\nЕсли ваш голод будет меньше 35%,то будет принимать еду по команде.')
                    --imgui.TextQuestion(u8'Таймер через какое время вы поедите еду на заданную команду')
                    if ImInt.MethodAutoFood.v == 1 then 
                        imgui.PushItemWidth(150)
                        imgui.InputText(u8'Команда еды', Input.Cmd_Food)                        
                        imgui.SameLine()
                        imgui.SliderInt(u8'Таймер##AutoFood', ImInt.TimerAutoFood, 10, 120) imgui.TextQuestion(u8'Таймер через какое время вы поедите еду на заданную команду')
                       -- imgui.Text('' .. TimerAutoFood_)
                        if imgui.Button(u8'Сбросить таймер(' .. TimerAutoFood_ ..')') then TimerAutoFood_ = 0 end
                    elseif ImInt.MethodAutoFood.v == 2 then 
                        imgui.PushItemWidth(150)
                        imgui.InputText(u8'Команда еды', Input.Cmd_Food)
                    end
                    imgui.InputText(u8'После еды,писать командy..', Input.AfterAutoFood) imgui.TextQuestion(u8'Если вы напишите тут команду/текст\nТо после еды - будет написана та команда или текст\nК премеру /anim 31(после еды,напишет в чат /anim 31)\n(ARZ>после еды,нажимается ENTER и пишет команду/чат)\n\nОставьте поле пустым для отключение функции')
                    imgui.Separator()
                   -- imgui.RadioButton(u8'По /satiety(BETA)', ImInt.AutoFoodMethod, 2) imgui.TextQuestion(u8'Каждые 10 минут,будет вводится /satiety(но диалог не будет виден)\nЕсли будет меньше 30,то принимается еда на заданную команду')
                    --imgui.SameLine()
                end
                imgui.ToggleButton(u8'Авто-Хил', ToggleButton.AutoHeal)
                if ToggleButton.AutoHeal.v then 
                    imgui.PushItemWidth(150)
                    imgui.InputText(u8'Команда хилки', Input.Cmd_Health)   
                    if Input.Cmd_Health.v == '/smoke' then 
                        imgui.TextQuestion(u8'Вы хотите использовать в качестве хилки сигареты\nСкрипт будет флудить /smoke 5 раз!')
                    end                 
                    imgui.SameLine()
                    imgui.SliderInt(u8'##HP', ImInt.HP, 99, 1)
                    imgui.TextQuestion(u8'Если вы поставите 30,то у вашего персонажа будет ХП ниже 30\nТо он будет принимать хилку(по команде)')
                end
                imgui.Separator()
                    imgui.Text(u8'Евенты-Оповещение когда..')
                    imgui.ToggleButton(u8'PayDay', ToggleButton.PayDay)
                    if ToggleButton.PayDay.v then 
                        imgui.SameLine(75)
                        imgui.SliderInt(u8"До PayDay", ImInt.DoPayDaya, 30, 59)
                        imgui.TextQuestion(u8'Когда будет ' .. ImInt.DoPayDaya.v .. u8'минут до ПейДея до прийдет оповещение в телеграме!')
                    end
                    imgui.ToggleButton(u8'Я умер', ToggleButton.KillMe) imgui.TextQuestion(u8'Когда вы умрёте то прийдет оповещение в телеграме\nКто вас убил и с какого оружия')
                    imgui.ToggleButton(u8'Капт', ToggleButton.Capt)
                    imgui.ToggleButton(u8'Открыт Диалог(можно /showdialog в чат-бота)', ToggleButton.Notf_Dialog) imgui.TextQuestion(u8'Когда будет открыт диалоговое окно - вам напишет:\nЗАГОЛОВОК [ID ДРАЛОГА]\nСТИЛЬ ДРАЛОГА:\n\nTEXT\n')                            

                    imgui.Separator()

                    imgui.ToggleButton(u8'Дополнительный TimeStamp', ToggleButton.TimeStamp)
                    imgui.ToggleButton(u8'3 Раза прислать сообщение когда происходит  событие', ToggleButton.NotificationFlood) 

                imgui.Separator()
                imgui.ToggleButton(u8'Чекер Игроков:', ToggleButton.Checker)
                if ToggleButton.Checker.v then 
                    --imgui.Text(u8('Игрок зайдёт на сервер.'))

                    imgui.InputTextMultiline(u8'##Checker', Input.CheckerAdd, imgui.ImVec2(150, 150))
                    imgui.SameLine()
                    if imgui.Button(u8'Сохранить Чекер', imgui.ImVec2(125, 150)) then 
                        f = io.open('moonloader\\config\\Telegram Control SAMP\\Checker.txt', 'w')
                        f:write(Input.CheckerAdd.v)
                        f:close()
                    end
                    if imgui.Button(u8'Загрузить##Checker') then 
                        if doesFileExist('moonloader\\config\\Telegram Control SAMP\\Checker.txt') then 
                            for line in io.lines('moonloader\\config\\Telegram Control SAMP\\Checker.txt') do
                                Input.CheckerAdd.v = Input.CheckerAdd.v .. line .. '\n'
                            end                             
                        end 
                    end
                    --#ImInt_Checker
                    imgui.FontSize(1.2) imgui.Text(u8'Когда игрок зайдет в игру ..') imgui.FontSize(1.0)
                    imgui.RadioButton(u8'Написать мне в Телеграмм', ImInt.Checker, 0)
                    imgui.RadioButton(u8'Выйти из игры', ImInt.Checker, 1) imgui.SameLine() imgui.TextDisabled(u8'и оповестить')

                    imgui.Separator()
                end

            elseif ImguiPage == 4 then --------- #EVENTS #MYEVENTS ------------------------------

                imgui.BeginChild('##MyEvents', imgui.ImVec2(500, 440), true)

                tbl_MyEvents = {}
                for line in io.lines('moonloader\\config\\Telegram Control SAMP\\My Events.txt') do
                    table.insert(tbl_MyEvents,line)
                end         
                for k,v in pairs(tbl_MyEvents) do
                    imgui.Selectable((v), false) 
                end
                imgui.CenterText(u8'Сохраняется по пути moonloader/config/Telegram Control SAMP/My Events.txt')
                imgui.Separator()

                if imgui.ButtonHex(u8'Очистить ' .. fa.ICON_TIMES_CIRCLE, 0x00FF629b, imgui.ImVec2(-1,25)) then imgui.OpenPopup('clear events?') end
                if imgui.ButtonHex(u8'Редактировать Add Events.txt '.. fa.ICON_COG, 0x00ffaa00, imgui.ImVec2(-1,35) ) then imgui.OpenPopup('Edit Add Events.txt') end 
                if imgui.ButtonHex(u8'Добавить ' .. fa.ICON_PLUS, 0x006FF253, imgui.ImVec2(-1,50) ) then imgui.OpenPopup('Add Events') end 
                ---------------------------------------------------------------------------------------------------------------------

                if imgui.BeginPopup('clear events?') then 
                    imgui.TextColored(imgui.ImVec4(1,0,0,1), u8'Очистить My Events.txt?')
                    if imgui.Button(u8'Да',  imgui.ImVec2(-1, 30)) then 
                        file = io.open(path..'\\My Events.txt', 'w')
                        file:write('')
                        file:close()
                        imgui.CloseCurrentPopup()
                    end 
                    if imgui.Button(u8'Нет', imgui.ImVec2(-1,30)) then imgui.CloseCurrentPopup() end
                    imgui.EndPopup()
                end

                imgui.SetNextWindowSize(imgui.ImVec2(650, 400), imgui.Cond.FirstUseEver)
                if imgui.BeginPopupModal('Edit Add Events.txt', nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar) then 
                    if imgui.ButtonHex(u8'Закрыть ' .. fa.ICON_TIMES, 0x00FF0000, imgui.ImVec2(-1, 30), 5) then imgui.CloseCurrentPopup() end
                    imgui.Separator()
                    if imgui.ButtonHex(u8'Обновить '..fa.ICON_REFRESH, 0x008a968b, imgui.ImVec2(-1,25)) then
                        Input.MyEvents_MultilineText1.v = ''
                        tbl_MyEvents = {}
                        for line in io.lines('moonloader\\config\\Telegram Control SAMP\\My Events.txt') do
                            table.insert(tbl_MyEvents,line)
                        end         
                        for k,v in pairs(tbl_MyEvents) do
                            Input.MyEvents_MultilineText1.v = Input.MyEvents_MultilineText1.v .. v .. '\n'
                        end                        
                    end
                    imgui.InputTextMultiline('##edit_my_events', Input.MyEvents_MultilineText1, imgui.ImVec2(-1,295))

                    if imgui.ButtonHex(u8'Сохранить '..fa.ICON_FLOPPY_O, 0x0000FF00, imgui.ImVec2(-1,20), 5) then 
                        f = io.open('moonloader\\config\\Telegram Control SAMP\\My Events.txt', 'w')
                        f:write(Input.MyEvents_MultilineText1.v)
                        f:close()
                        imgui.CloseCurrentPopup()
                    end
                    imgui.EndPopup()
                end

                imgui.SetNextWindowSize(imgui.ImVec2(500, 350), imgui.Cond.FirstUseEver)
                if imgui.BeginPopupModal('Add Events', nil, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar) then 
                    if imgui.ButtonHex(u8'Закрыть ' .. fa.ICON_TIMES, 0x00FF0000, imgui.ImVec2(-1, 30), 5) then imgui.CloseCurrentPopup() end
                        imgui.Separator()

                        imgui.Text(u8'Если скрипт..') imgui.SameLine() 
                        imgui.PushItemWidth(200)
                        imgui.Combo('##1', ImInt.MyEvents_Combo1, 
                            {'',u8'найдет в чате текст..', u8'увидит что у машины меньше..', u8'увидит в диалоге..', u8'увидит по времени..' })
                        imgui.PopItemWidth()
                        
                        if ImInt.MyEvents_Combo1.v == 1 then -- chat
                            --imgui.SameLine()
                            imgui.PushItemWidth(-1)
                            imgui.InputText('##text1', Input.MyEvents_Text1) 
                            imgui.PopItemWidth()

                        elseif ImInt.MyEvents_Combo1.v == 2 then -- CAR HP
                            imgui.SliderInt('##hp_car', ImInt.MyEvents_Slider1, 100, 1500)
                            imgui.SameLine() imgui.Text('HP') imgui.TextQuestion(u8'Если у машины будет меньше ' .. ImInt.MyEvents_Slider1.v .. u8' ХП,тоо..')
                        
                        elseif ImInt.MyEvents_Combo1.v == 3 then -- Dialog

                            imgui.PushItemWidth(200)
                            imgui.Combo('##dialogs', ImInt.MyEvents_Combo2, {'ID', u8'В заголовке Текст', u8'В самому диалоге текст'})
                            imgui.PopItemWidth()

                            imgui.PushItemWidth(-1)
                            imgui.NewInputText('##text1', Input.MyEvents_Text1, 460, 'vespanwho?')
                            imgui.PopItemWidth()
                            elseif ImInt.MyEvents_Combo1.v == 4 then -- время os.date

                            -- imgui.InputText('##time', Input.MyEvents_Text1)--
                            imgui.PushItemWidth(30)
                            imgui.InputInt('##h', ImInt.MyEvents_H,0,0) 
                            imgui.SameLine() imgui.Text(':') imgui.SameLine()
                            imgui.InputInt('##m',ImInt.MyEvents_M,0,0)
                            imgui.SameLine() imgui.Text(':') imgui.SameLine()
                            imgui.InputInt('##s',ImInt.MyEvents_S,0,0)
                            imgui.PopItemWidth(3)
                            --

                            imgui.TextDisabled(u8'Указывать время ЧЧ:ММ:СС(>12:30:00) | 24формат часов!('..os.date('%H:%M:%S')..')')

                        end

                        if ImInt.MyEvents_Combo1.v > 0 then 
                            imgui.Text(u8'То..')
                            imgui.PushItemWidth(200) imgui.InputText('##sendclient', Input.MyEvents_SendClient) 
                            imgui.TextQuestion(u8'Отправит команду клиенту(к премеру /rec что бы перезайти или /q)\nЧто бы отключить функцию - оставьте поле пустым.\nЕсли вы напишите не команду а ТЕКСТ(без /) то - краш\nЕсли напишите команду к премеру /repcar /mm(СЕРВЕРНЫЕ КОМАНДЫ) то - краш')
                            imgui.ToggleButton(u8'Делаем скриншот(F8)',ToggleButton.MyEvents_Screenshot)
                        end                        

                        if ImInt.MyEvents_Combo1.v > 0 then 

                            imgui.Separator()

                                if imgui.ButtonHex(u8'Сохранить '..fa.ICON_FLOPPY_O, 0x0000FF00, imgui.ImVec2(-1,20), 5) then 
                                    
                                    file = io.open(path..'\\My Events.txt', 'r+')
                                    file:seek("end", 0);

                                    -- '%[(.+)-(%d+)]% (%d+) | (.+)
                                    local function SendClient()
                                        if #Input.MyEvents_SendClient.v > 0 then 
                                            return Input.MyEvents_SendClient.v 
                                        else
                                            return 'nil'
                                        end 
                                    end     

                                    local function Screenshot()
                                        if ToggleButton.MyEvents_Screenshot.v then
                                            return 'true'
                                        else
                                            return 'false'
                                        end
                                    end                    

                                    if ImInt.MyEvents_Combo1.v == 1 then -- чат 

                                        file:write(string.format('[Chat-0] SendClient:%s Screenshot:%s | %s\n', SendClient(), Screenshot(), Input.MyEvents_Text1.v))
                                    elseif ImInt.MyEvents_Combo1.v == 2 then -- кар хп

                                        file:write(string.format('[HP Car-0] SendClient:%s Screenshot:%s | %s\n',SendClient(), Screenshot(), ImInt.MyEvents_Slider1.v))                                   
                                    elseif ImInt.MyEvents_Combo1.v == 3 then -- диалоги

                                        a = {'ID', u8'Title', u8'Text'}
                                        file:write(string.format('[Dialog-%s] SendClient:%s Screenshot:%s | %s\n',a[ImInt.MyEvents_Combo2.v+1], SendClient(), Screenshot(), Input.MyEvents_Text1.v))                  
                                    elseif ImInt.MyEvents_Combo1.v == 4 then -- время

                                        file:write(string.format('[Time-0] SendClient:%s Screenshot:%s | %s:%s:%s\n',SendClient(), Screenshot(), ImInt.MyEvents_H.v,ImInt.MyEvents_M.v,ImInt.MyEvents_S.v))
                                    end

                                    file:flush()
                                    file:close()

                                    imgui.CloseCurrentPopup()

                                    ImInt.MyEvents_Combo2.v = 0 

                                end --
                        end

                    imgui.EndPopup()
                end  --------ADD EVENTS----------------------------------------------------------------

                imgui.EndChild()                   

            end -- end ImguiPage   

        imgui.EndChild()   

        imgui.End() 

    end

    if PushMessage_imgui.v then 

        imgui.PushStyleVar(imgui.StyleVar.Alpha, PushMessageAlpha) 
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 10)  

        local ToScreen = convertGameScreenCoordsToWindowScreenCoords
        local sX, sY = ToScreen(535, 0)

        --imgui.SetNextWindowPos(imgui.ImVec2((sw-imgui.GetWindowWidth()/2)/2 , sh / 1.25 ), imgui.Cond.Once)

        imgui.Begin(u8'##notf', imgui_window,
            imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize + 
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + 
            imgui.WindowFlags.NoMove
        )

        imgui.SetWindowPos(imgui.ImVec2((sw-imgui.GetWindowWidth()/2.15)/2.15 , sh / 1.25), imgui.Cond.Always)
        
        imgui.SetWindowFontScale(1.3)
            imgui.CenterText((fa.ICON_TELEGRAM .. ' Telegram Control SAMP'))
        imgui.SetWindowFontScale(1.0)
        imgui.Separator()

        imgui.CenterText(table.concat(nText,'\n'))

        imgui.End()
        imgui.PopStyleVar(2)


    end

    if LoadingScript_imgui.v then

        server = sampGetCurrentServerName()

        imgui.PushStyleVar(imgui.StyleVar.Alpha, 0.5) 
        imgui.PushStyleVar(imgui.StyleVar.WindowRounding, 5)
        -- imgui.SetNextWindowPos(imgui.ImVec2(sw / 2.3, sh / 1.2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))

        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2 - imgui.CalcTextSize(u8'   Нажмите на Y,если вы на сервере   ').x / 2, sh / 1.25), imgui.Cond.FirstUseEver)
        imgui.Begin(u8'##LoadingScript_imgui', imgui_window, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar)
        

        imgui.SetWindowFontScale(1.3)
            imgui.CenterText((fa.ICON_TELEGRAM .. ' Telegram Control SAMP\n' .. table.concat(nText,'\n'))) 
        imgui.SetWindowFontScale(1.0)
        imgui.CenterText(u8'Загрузка ..') 
        imgui.TextDisabled(u8' Нажмите на Y,если вы на сервере')

        imgui.Separator()

        imgui.CenterText(server)        

        -- imgui.Text('') 

        imgui.SetCursorPosX(imgui.GetWindowWidth()/2-30/2)
        imgui.Spinner(15, 2)

        imgui.End()
        imgui.PopStyleVar(2)
    end              

end



function processing_telegram_messages(result) -- #CMDS
    if result then
        local proc_table = decodeJson(result)
        if proc_table.ok then
            if #proc_table.result > 0 then
                local res_table = proc_table.result[1]
                if res_table then
                    if res_table.update_id ~= updateid then
                        updateid = res_table.update_id
                        local message_from_user = res_table.message.text 
                        if message_from_user and not LoadingScript_imgui.v then
                                local text = u8:decode(message_from_user)

                                -- res_table.message.chat.id 
--[[
{"ok":true,"result":[{"update_id":294713511,"message":{"message_id":3562,"from":{"id":620180223,"is_bot":false,"first_name":"vesp","last_name":"vespan","username":"V3sp4n","language_code":"en"},"chat":{"id":620180223,"first_name":"vesp","last_name":"vespan","username":"V3sp4n","type":"private"},"date":1649856314,"text":"/test","entities":[{"offset":0,"length":5,"type":"bot_command"}]}}]}
]]
                                -------------------------------------------------------------------------------------------------------------------------------------
                            --print(tostring(result))
                            if res_table.message.chat.id == tonumber(Input.ChatId.v) then
                                if text == Input.Cmd_Chat.v then -- CHAT
                                    BotChat = not BotChat 
                                    sendTelegramNotification(BotChat and '[SAMP | Chat] Включен' or '[SAMP | Chat] Выключен')
                                elseif text == '/crash' then -- CRASH 
                                    sendTelegramNotification('crash!')
                                    callFunction(0x823BDB , 3, 3, 0, 0, 0)
                                elseif text == Input.Cmd_AntiAFK.v then -- ANTI AFK
                                    AntiAfk = not AntiAfk 
                                    sendTelegramNotification(AntiAfk and '[SAMP | Anti-AFK] Включено' or '[SAMP | Anti-AFK] Выключено')
                                    workpaus(AntiAfk)
                                elseif text == Input.Cmd_Quit.v then -- /Q
                                    sendTelegramNotification('[SAMP | Quit] ' .. sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) .. ' Вышел из игры(/q)')
                                    sampProcessChatInput('/q')
                                elseif text == Input.Cmd_FakeAFK.v then -- FAKE AFK    
                                    FakeAfk = not FakeAfk 
                                    sendTelegramNotification(FakeAfk and '[SAMP | Fake-AFK] Включен' or '[SAMP | Fake-AFK] Выключен')
                                elseif text == Input.Cmd_Time.v then  -- TIME 
                                    sendTelegramNotification('[SAMP | Time]\nСистемное время:'..os.date('%H:%M:%S')..'\nВы отыграли:\nВ AFK(esc):' .. getafk() .. '\nВ Fake-AFK:' .. FakeAFKTime ..'\nБЕЗ AFK:' .. (FormatTime(os.clock(), os.time() )) )   
                                elseif text == '/отвязать' then -- F 
                                    sendTelegramNotification('Вы успешно отвязали Telegram Control.lua от своего телеграм аккаунта!\nВаш chat-id был удален')
                                    Config.Telegram.ChatId = ''
                                    Input.ChatId.v = ''
                                    save()
                                    PushMessage(u8'Вы отвязали свой телеграм аккаунт от бота!\nВаш chat-id был удален с .ini файла!')
                                elseif text == Input.Cmd_ScreenShot.v then -- F8 + /TIME 
                                    --sampTakeScreenshot()
                                    setVirtualKeyDown(VK_F8, true) wait(50) setVirtualKeyDown(VK_F8, false) 
                                    sendTelegramNotification('[SAMP | ScreenShot]:\nБыл сделан скриншот')
                            -- old elseif text:match(~~~) then 
                                elseif text == Input.Cmd_Stats.v then -- #GETSTATS #STATS                                     
                                    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
                                    local animid = sampGetPlayerAnimationId(id)
                                    local animname, animfile = sampGetAnimationNameAndFile(animid)                                    
                                    local x, y, z = getCharCoordinates(PLAYER_PED)

                                        local function city(int)
                                            if int == 0 then
                                                return 'Вне города'
                                            elseif int == 1 then 
                                                return 'Los-Santos'
                                            elseif int == 2 then 
                                                return 'San-Fierro'
                                            elseif int == 3 then 
                                                return 'Lav-Venturas'
                                            end
                                        end
                                        local function CheckArizona()
                                            if sampGetCurrentServerName():find('Arizona Role Play') or sampGetCurrentServerName():find('Arizona RP') then
                                                if sampTextdrawIsExists(2061) then --голод textdraw
                                                    _, _, eat, _ = sampTextdrawGetBoxEnabledColorAndSize(2061)
                                                    eat = (eat - imgui.ImVec2(sampTextdrawGetPos(2061)).x) * 1.83
                                                    return math.floor(eat)
                                                else 
                                                    return '-'
                                                end     
                                            else
                                                return '-'
                                            end 
                                        end
                                        local function CheckStatusConnect()
                                            if disconnected then 
                                                return 'Вы отключены от сервера!'
                                            else
                                                return ''
                                            end
                                        end
                                        local function fNewBalance()
                                            if NewBalance > 0 then 
                                                return 'Заработано:' .. money_separator(NewBalance) .. '$'
                                            elseif NewBalance < 0 then 
                                                return 'Потрачено:' .. money_separator(NewBalance) .. '$'
                                            else  
                                                return 'Вы не заработали и не потратили :*'
                                            end
                                        end 
                                    sendTelegramNotification(string.format(
                                        '[SAMP | Get Player Info]:\n>%s[ %d ]<\n%s - %s\n\nБроня:%d+ | ХП:%d+\nПинг:%d+ | Уровень:%d+' 
                                        .. '\nГолод(ARZ):%s\nДеньги:%s$(%s)\nАнимация:%s[%d+]\nВ руках:%s\n\nВ Зоне-Стрима:%d+\nОнлайн Сервера:%d+\n%s', ---------------[[]]
                                        sampGetPlayerNickname(id), id, city(getCityPlayerIsIn(PLAYER_PED)), calculateZone(x, y, z),
                                        sampGetPlayerArmor(id), sampGetPlayerHealth(id), sampGetPlayerPing(id), sampGetPlayerScore(id), CheckArizona(), 
                                        money_separator(getPlayerMoney(player)),fNewBalance(), animfile, animid,
                                        getweaponname(getCurrentCharWeapon(PLAYER_PED)), sampGetPlayerCount(true), sampGetPlayerCount(false), CheckStatusConnect()--[[sampGetPlayerCount(false)]] ) )

                                elseif text:find(Input.Cmd_Send.v) and not text:find('/sendclient') then -- #SEND
                                    if text:find(Input.Cmd_Send.v.. ' (.+)') then 
                                    arg = text:match(Input.Cmd_Send.v..' (.+)')
                                        if #arg > 0 then 
                                            sampSendChat(arg)
                                            sendTelegramNotification('[SAMP | Send]:\n' .. arg)
                                        else
                                            sendTelegramNotification('(?) Введите /send [text/cmd]')
                                        end
                                    else
                                        sendTelegramNotification('(?) Введите /send [text/cmd]')
                                    end                                    

                                elseif text:find('/sendclient') and not text:find(Input.Cmd_Send.v..' ') then -- #SENDCLIENT
                                    if text:find('/sendclient (.+)') then 
                                    arg = text:match('/sendclient (.+)')
                                        if #arg > 0 then 
                                            sampProcessChatInput(arg)
                                            sendTelegramNotification('[SAMP | SendClient]:\n' .. arg)
                                        else
                                            sendTelegramNotification('(?) Введите /sendclient [cmd]')
                                        end
                                    else
                                        sendTelegramNotification('(?) Введите /sendclient [cmd].')
                                    end

                                elseif text == '/уведомления' or text == '/notifications' then -- #NOTIFICATIONS
                                    if ToggleButton.Bot.v then 
                                        sendTelegramNotification('[Script]:\nВыключаю уведомления!')
                                        ToggleButton.Bot.v = false 
                                        ToggleButton.AutoReboot.v = false
                                    else
                                        ToggleButton.AutoReboot.v = true
                                        ToggleButton.Bot.v = true   
                                        sendTelegramNotification('[Script]:\nВключаю уведомления!')
                                    end                           
                                    save()           
                                elseif text == Input.Cmd_GetStream.v then 
                                    stream = ''
                                    for k, v in pairs(getAllChars()) do
                                        ped, id = sampGetPlayerIdByCharHandle(v)
                                        if id > -1 then 
                                            nick = sampGetPlayerNickname(id)
                                            if sampIsPlayerPaused(v) then afk = 'Да' else afk = 'Нет' end
                                            stream = stream .. nick .. '[' .. id ..']' .. ':LVL' .. sampGetPlayerScore(id) .. '.AFK:' .. afk ..'.\n'
                                        end
                                    end
                                    sendTelegramNotification('[SAMP | GetStream]:\n'..stream)
                                elseif text == '/help' then 
                                    sendTelegramNotification('(?) Всё Команды:\n '
                                    .. Input.Cmd_Send.v .. ' - Отправить сообщение/команду в чат\n' 
                                    .. Input.Cmd_Chat.v .. ' - Чат из сампа в > телеграмм чат\n'
                                    .. Input.Cmd_AntiAFK.v .. ' - AntiAFK\n'
                                    .. Input.Cmd_FakeAFK.v .. ' - FakeAFK\n'
                                    .. Input.Cmd_ScreenShot.v .. ' - Сделать скриншот + /time \n'
                                    .. Input.Cmd_Time.v .. ' - Посмореть системное время/сколько время я отыграл БЕЗ AFK/С AFK\n'
                                    .. Input.Cmd_Quit.v .. ' - Выход из gta_sa.exe(/q)\n'
                                    .. Input.Cmd_GetStream.v .. ' - Узнать информацию об игроков в зоне-стрима\n'
                                                        ..'/sendclient - Отправить команду в клиент самп(к примеру /q /rec и тд)\n'
                                                        ..'/уведомления /notifications - Включить/Выключить уведомления\n'
                                    .. Input.Cmd_Dialog_Input.v .. ' - Отправить в поле(input) текст\n'
                                    .. Input.Cmd_Dialog_List.v .. ' - Выбрать пункт в диалоге\n'
                                    .. Input.Cmd_Dialog_Close.v .. ' - Закрыть Диалог')
                                --------------------------------------------------------------------------------------------------------------------------------------------
                                -----------------------------------------------------#DIALOG MENU----------------------------------------------------------------------------
                                --------------------------------------------------------------------------------------------------------------------------------------------
                                elseif text == '/showdialog' then 
                                    ToggleButton.Notf_Dialog.v = not ToggleButton.Notf_Dialog.v
                                    save()
                                    sendTelegramNotification(ToggleButton.Notf_Dialog.v and '[SAMP | Dialog]:\nДиалоговые Окна включены!' or '[SAMP | Dialog]:\nДиалоговые Окна выключены!')
                                
                                elseif text:find(Input.Cmd_Dialog_List.v) then 
                                    if text:find(Input.Cmd_Dialog_List.v.. ' (%d+)') then 
                                        arg = text:match(Input.Cmd_Dialog_List.v..' (%d+)')

                                        if sampIsDialogActive() then 
                                           if #arg > 0 then 
                                                sampSendDialogResponse(idDialog, 1, arg - 1, -1)
                                                sendTelegramNotification('[SAMP | Dialog]:\nВы Выбрали Пункт: ' .. arg)
                                            else
                                                sendTelegramNotification('(?) ' .. Input.Cmd_Dialog_List.v .. ' [пункт(НАЧИНАТЬ C 1)] - Что бы выбрать пункт')
                                            end
                                        else
                                            sendTelegramNotification('(?) ' .. Input.Cmd_Dialog_List.v .. ' [пункт(НАЧИНАТЬ C 1)] - Что бы выбрать пункт')
                                        end
                                    else
                                        sendTelegramNotification('(?) ' .. Input.Cmd_Dialog_List.v .. ' [пункт(НАЧИНАТЬ C 1)] - Что бы выбрать пункт')
                                    end

                                elseif text == Input.Cmd_Dialog_Close.v then 
                                    if sampIsDialogActive() then 
                                        setVirtualKeyDown(VK_ESCAPE,true) wait(50) setVirtualKeyDown(VK_ESCAPE,false)
                                            if sampIsDialogActive() then 
                                                sendTelegramNotification('[SAMP | Dialog]:\nДиалог был закрыт!\nНо есть ещё один диалог*')
                                            end
                                        sendTelegramNotification('[SAMP | Dialog]:\nДиалог был закрыт!')
                                    else
                                        sendTelegramNotification('[SAMP | Dialog]:\nДиалоговое окно не найдено!')
                                    end

                                elseif text:find(Input.Cmd_Dialog_Input.v) then 
                                    if text:find(Input.Cmd_Dialog_Input.v.. ' (.+)') then 
                                        arg = text:match(Input.Cmd_Dialog_Input.v..' (.+)')

                                        if sampIsDialogActive() then 
                                           if #arg > 0 then 
                                                sampSendDialogResponse(idDialog, 1, -1, arg)
                                                sendTelegramNotification('[SAMP | Dialog]:\nВы написали в диалоговое окно:\n' .. arg)
                                            else
                                                sendTelegramNotification('(?) ' .. Input.Cmd_Dialog_Input.v .. ' [text] - Что бы написать в диалоговое окно с полем')
                                            end
                                        else
                                            sendTelegramNotification('(?) ' .. Input.Cmd_Dialog_Input.v .. ' [text] - Что бы написать в диалоговое окно с полем')
                                        end
                                    end

                                elseif text == '/d.help' then 
                                    sendTelegramNotification(string.format('[SAMP | Dialog]:\n%s - Выбрать пункт в диалоге(стиль list);\n%s - Написать в диалог(стиль input/password);' 
                                        .. '\n%s - Закрыть диалог;\n/showdialog - Будут приходит уведомление,при открытом диалоге,или нет;', 
                                        Input.Cmd_Dialog_List.v, Input.Cmd_Dialog_Input.v, Input.Cmd_Dialog_Close.v))
                                else sendTelegramNotification('(?) Команда < ' .. text .. ' > Не была найдена!\nПомощь:/help')                                  
                                end  
                                -------------------------------------------------------------------------------------------------------------------------------------    
                            else
                            PushMessage(u8'Внимание!\nНеверный Chat-Id!\nЛибо вы неверно указали Chat-Id\nЛибо кто-то зашел в ваш телеграмм-бот!') 
                            end             
                        end
                    end
                end
            end
        end
    end
end


-- SAMP.lua #SAMP #SAMP.LUA #sampev ------------------------------------------------------------------------------------------------------

--[[function sampev.onDisplayGameText(style, time, text) -- #AutoFood #АвтоЕда
    if ToggleButton.AutoFood.v and sampGetCurrentServerName():find('Arizona Role Play') then
        if text:find('You are hungry!') or text:find('You are very hungry!') or text:find('hungry!') then
            sendTelegramNotification(string.format('[SAMP | Hungry]:\nВы проголодались!\nРспользую команду %s для едь!', Input.Cmd_Food))
            sampSendChat(Input.Cmd_Food)
        end
    end
end]]

function sampev.onShowDialog(id, style, caption, b1, b2, text) 
    if ToggleButton.Notf_Dialog.v then 
        StyleText = {
            'Информативный Диалог', 
            'Диалог с полем', 
            'Диалог с пунктами', 
            'Диалог с полем(password)',
            'Диалог с пунктами', 
            'Диалог с пунктами'
        }
        idDialog = id
        sendTelegramNotification('[SAMP | Dialog]:\n___________________________\n' .. caption .. ' [' .. id .. ']' .. '\nСтиль:' .. StyleText[style+1] .. '\n\n' .. text .. '\n___________________________')
    end

    if doesFileExist(path..'\\My Events.txt') and ToggleButton.Bot.v then 
        for line in io.lines(path..'\\My Events.txt') do 
            if line:find('%[Dialog%-(.+)]% SendClient:(.+) Screenshot:(.+) | (.+)') then 
                local arg2, sendclient, Screenshot, arg_text = line:match('%[Dialog%-(.+)]% SendClient:(.+) Screenshot:(.+) | (.+)')


                    if arg2 == 'Title' then 
                        if stringToLower(caption):find(stringToLower(u8:decode(arg_text))) then 
                            sendTelegramNotification('[SAMP | Events Dialog(title)]:\nБыл открыт диалог!\n'..caption ..'['..id..']\n'..text)
                            sampShowDialog(id+1, '{0082ff}[TCS]'..caption, text, b1, b2, style)

                            fMyEvents(sendclient,Screenshot)              
                        end

                    elseif arg2 == 'ID' then 
                        if id == tonumber(arg_text) then 
                            sendTelegramNotification('[SAMP | Events Dialog(id)]:\nБыл открыт диалог!\n'..caption ..'['..id..']\n'..text)
                            sampShowDialog(id+1, '{0082ff}[TCS]'..caption, text, b1, b2, style)

                            fMyEvents(sendclient,Screenshot)
                        end

                    elseif arg2 == 'Text' then 
                        if stringToLower(text):find(stringToLower(u8:decode(arg_text))) then 
                            sendTelegramNotification('[SAMP | Events Dialog(text)]:\nБыл открыт диалог!\n'..caption ..'['..id..']\n'..text)
                            sampShowDialog(id+1, '{0082ff}[TCS]'..caption, text, b1, b2, style)

                            fMyEvents(sendclient,Screenshot)                        
                        end


                end
            end
        end 
    end     

end
 
function sampev.onServerMessage(color, text)
    if BotChat then 
        sendTelegramNotification('[SAMP | Chat]:\n ' .. text)
    end

    if doesFileExist(path..'\\My Events.txt') and ToggleButton.Bot.v then 
        for line in io.lines(path..'\\My Events.txt') do 
            if line:find('%[Chat%-(.+)]% SendClient:(.+) Screenshot:(.+) | (.+)') then 
                local arg2, sendclient, Screenshot, arg_text = line:match('%[Chat%-(.+)]% SendClient:(.+) Screenshot:(.+) | (.+)')

                if stringToLower(text):find(stringToLower(u8:decode(arg_text))) then 
                    sendTelegramNotification('[SAMP | Events Chat]:\n' .. text .. ' !!!')
                    sampAddChatMessage('{0082ff}[TCS]{FFFFFF}'..text)--если текст пропадёт
                    fMyEvents(sendclient,Screenshot)

                end

            end
        end
    end

end 

function sampev.onSendTakeDamage(dmgid, damage, weapon, bodypart)
    if ToggleButton.KillMe.v then 
        if getCharHealth(PLAYER_PED) == 0 and not disconnected then 
            if sampIsPlayerConnected(dmgid) then 
                sendTelegramNotification('[SAMP | Player]:\n Вас убил - ' .. sampGetPlayerNickname(dmgid) .. '[' .. dmgid .. ']\nC оружия ' .. getweaponname(weapon))
            --else
                --sendTelegramNotification('[SAMP | Player]:\n Вас убил - ' .. '-' .. '[' .. 'dmgid' .. ']\nC оружия ' .. '-\n(игрок вышел с сервера)')
            end
        end
    end
end

function sampev.onGangZoneFlash(zoneId, color)
    if ToggleButton.Capt.v then 
        sendTelegramNotificationFlood('[SAMP] КАПТ!')
        sendTelegramNotification('5 последних строк с чата')
        for i = 95, 99 do 
            text, prefix, color, pcolor = sampGetChatString(i)
            sendTelegramNotification('[SAMP | ' .. i .. '] ' .. text)
        end
    end
end

function sampev.onPlayerJoin(id, color, isNpc, nickname)

    if ToggleButton.Checker.v and doesFileExist('moonloader\\config\\Telegram Control SAMP\\Checker.txt') then
            tbl = {}
            for line in io.lines('moonloader\\config\\Telegram Control SAMP\\Checker.txt') do
                table.insert(tbl,line)
            end
            for k,v in pairs(tbl) do
                --id = sampGetPlayerIdByNickname(v)
                    if nickname == v then
                        if ImInt.Checker.v == 0 then 
                            sendTelegramNotification('[SAMP | Checker - Connected]\n ' .. v .. '[' .. id ..'] Зашел на сервер!') 
                        else
                            sendTelegramNotification('[SAMP | Checker - Connected]\n ' .. v .. '[' .. id ..'] Зашел на сервер!\nВы вышли из сервера!\n(/q)') 
                            sampProcessChatInput('/q')
                        end
                    end
            end    --sampIsPlayerConnected
    end  

end

function sampev.onPlayerQuit(id, reason)

    local QuitReason = { 
        "Краш",
        "/q",
        "Сервер Кикнул"
    }    

    if ToggleButton.Checker.v and doesFileExist('moonloader\\config\\Telegram Control SAMP\\Checker.txt') then
            tbl = {}
            for line in io.lines('moonloader\\config\\Telegram Control SAMP\\Checker.txt') do
                table.insert(tbl,line)
            end
            for k,v in pairs(tbl) do
                --id = sampGetPlayerIdByNickname(v)
                   if id == sampGetPlayerIdByNickname(v) then sendTelegramNotification('[SAMP | Checker - Disconected]\n ' .. v .. '[' .. sampGetPlayerIdByNickname(v) ..'] Вышел из сервера\nПричина:' .. QuitReason[reason+1]) end
            end    --sampIsPlayerConnected
    end       

end

-- #OTHER# ------------------------------------------------------------------------------------------------------

function fMyEvents(argSendClient,boolScreenshot)

    lua_thread.create(function()

        if boolScreenshot == 'true' then
            wait(500)
            setVirtualKeyDown(VK_F8,true) wait(50) setVirtualKeyDown(VK_F8,false)
            wait(500)
        end

        if argSendClient ~= 'nil' then 
           -- sampAddChatMessage(argSendClient, -1)
            sampProcessChatInput(argSendClient)
        end   

    -- return true

    end)

end

function DoPayDaya()
    while true do wait(100)

        if ToggleButton.PayDay.v and os.date("%M:%S") == ImInt.DoPayDaya.v .. ':00' then 
           -- lua_thread.create(function()
            --sendTelegramNotificationFlood('[SAMP | PayDay]:\n ' .. ImInt.DoPayDaya.v .. ' Минут До PayDaя!')          
                sendTelegramNotificationFlood("[Samp | PayDay]:\nЩас пейдей будет!\n(таймер выставлен на " .. ImInt.DoPayDaya.v .. ' минут)')
                wait(1000)
           -- end)
        end

    end
end

function MyEvents_Time()
    while true do wait(0)

    if doesFileExist(path..'\\My Events.txt') and ToggleButton.Bot.v then 
        for line in io.lines(path..'\\My Events.txt') do 
            if line:find('%[Time%-(.+)]% SendClient:(.+) Screenshot:(.+) | (%d+)%:(%d+)%:(%d+)') then 
                local arg2, sendclient, Screenshot, h, m, s = line:match('%[Time%-(.+)]% SendClient:(.+) Screenshot:(.+) | (%d+)%:(%d+)%:(%d+)')

                --if arg1 == 'Time' then 
                    if os.date('%H:%M:%S') == h .. ':' .. m .. ':' .. s then 
                        sendTelegramNotification('[SAMP | Events Time]:\nВремя ' .. os.date('%H:%M:%S') .. '!')
                        fMyEvents(sendclient,Screenshot)
                        wait(1000)
                    end
               -- end

            end
        end
    end

    end
end

function MyEvents_HP_Car()

    while true do wait(500)

    if doesFileExist(path..'\\My Events.txt') and ToggleButton.Bot.v then 
        for line in io.lines(path..'\\My Events.txt') do 
            if line:find('%[HP Car%-(.+)]% SendClient:(.+) Screenshot:(.+) | (%d+)') then 
                local arg2, sendclient, Screenshot, arg_text = line:match('%[HP Car%-(.+)]% SendClient:(.+) Screenshot:(.+) | (%d+)')

                --if arg1 == 'HP Car' then  

                    if isCharInAnyCar(PLAYER_PED) then

                    if getCarHealth(storeCarCharIsInNoSave(PLAYER_PED)) <= tonumber(arg_text) then

                            sendTelegramNotification('[SAMP | Events HP Car]:\nХП Транспорта ' .. getCarHealth(storeCarCharIsInNoSave(PLAYER_PED)) .. '!\nХП Транспорта меньше назначенного (' .. arg_text..')!')

                        fMyEvents(sendclient,Screenshot)

                        wait(25000)

                    --end
                    end
                end
            end
        end
    end
end
end

function KillMe()
    while true do wait(0)
        if ToggleButton.KillMe.v then 
            if getCharHealth(PLAYER_PED) == 0 and not disconnected and sampIsLocalPlayerSpawned() then 
                sendTelegramNotificationFlood('[SAMP | Player] Вы умерли!')
                wait(60000)
            end
        end
    end
end

function other()
    while true do wait(0)
        if FakeAfk then 
            FakeAFKTime = FakeAFKTime + 1
            wait(1000)
        end
    end
end

function AutoFood()  
    while true do wait(0)

    if ToggleButton.AutoFood.v and ImInt.MethodAutoFood.v == 1 then -- #AUTOFOOD 
        if TimerAutoFood_ == ImInt.TimerAutoFood.v then
            sendTelegramNotification(string.format('[SAMP | AutoFood]:\nТаймер на %d минуты вышел!\nПора кушать!(%s)', ImInt.TimerAutoFood.v, Input.Cmd_Food.v))
            sampSendChat(Input.Cmd_Food.v)
            if #Input.AfterAutoFood.v > 1 then 
                if sampGetCurrentServerName():find('Arizona RP') or sampGetCurrentServerName():find('Arizona Role Play') then
                    --print('1')
                    setVirtualKeyDown(VK_RETURN, true) wait(100) setVirtualKeyDown(VK_RETURN, false)
                    wait(1500)  
                end             
                sampSendChat(Input.AfterAutoFood.v)
            end
            TimerAutoFood_ = 0
        else
            TimerAutoFood_ = TimerAutoFood_ + 1
            --printToLog(TimerAutoFood_)
            if TimerAutoFood_ ~= ImInt.TimerAutoFood.v then 
                wait(60000) 
            end
        end
    end

    if ToggleButton.AutoFood.v and ImInt.MethodAutoFood.v == 2 and sampTextdrawIsExists(2061) then

        _, _, eat, _ = sampTextdrawGetBoxEnabledColorAndSize(2061)
        eat = (eat - imgui.ImVec2(sampTextdrawGetPos(2061)).x) * 1.83
        if math.floor(eat) < 20 then
            sampSendChat(Input.Cmd_Food.v)
            sendTelegramNotification('[SAMP | AutoFood]:\nГолод меньше 20%!\nПора кушать!(' .. Input.Cmd_Food.v .. ')')

            if #Input.AfterAutoFood.v > 1 then 
                if sampGetCurrentServerName():find('Arizona RP') or sampGetCurrentServerName():find('Arizona Role Play') then
                    setVirtualKeyDown(VK_RETURN, true) wait(100) setVirtualKeyDown(VK_RETURN, false)
                    wait(1500)  
                end             
                sampSendChat(Input.AfterAutoFood.v)
            end    

            wait(1000)
        end 

        wait(30000)

    end
end

end

function AutoHeal()
    while true do wait(0)

        if ToggleButton.AutoHeal.v then -- #AUTOHEAL #AUTOHP
            if not disconnected and getCharHealth(PLAYER_PED) > 0 and  getCharHealth(PLAYER_PED) < ImInt.HP.v then
                sendTelegramNotification('[SAMP | AutoHeal]:\nУ вас ' .. getCharHealth(PLAYER_PED) .. ' ХП!\nРспользую ' .. Input.Cmd_Health.v) 
                if Input.Cmd_Health.v == '/smoke' then 
                    for i = 0, 5 do --флуд 5 сообщений /smoke 
                        sampSendChat('/smoke')
                        wait(750)
                    end
                    wait(60000)
                else
                    sampSendChat(Input.Cmd_Health.v)
                    wait(60000)
                end
                --print('123')
            end 
        end
    end
end

function loading()
    while true do wait(0)

    if sampIsLocalPlayerSpawned() then  
        wait(5000) -- Скрипт должен получить название сервера,или отправит в телеграмм что вы зашли на сервер SA-MP с онлайном:1
    if sampGetCurrentServerName() ~= 'SA-MP' and LoadingScript_imgui.v then 
        OldBalance = getPlayerMoney(player)

        if not ToggleButton.Bot.v then
            PushMessage(u8'Успешно загружен!\n\n  '.. fa.ICON_VOLUME_OFF..u8' Сообщение выключены\nОткрыть имгуи-окно /'..Config.Script.Cmd)
        else
            PushMessage(u8'Успешно загружен!\nОткрыть имгуи-окно /'..Config.Script.Cmd)
        end

        sampRegisterChatCommand(tostring(Config.Script.Cmd), function() imgui_window.v = not imgui_window.v end)

        ip, port = sampGetCurrentServerAddress()
            sendTelegramNotification('[SAMP | Connected] \n' .. sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))) .. '\n\n' .. sampGetCurrentServerName() .. ' \n' .. ip .. ':' .. port .. '\nОнлайн:' .. sampGetPlayerCount(false))    

        LoadingScript_imgui.v = false
    end   
    end  

    end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function stringToLower(s)
  for i = 192, 223 do
    s = s:gsub(_G.string.char(i), _G.string.char(i + 32))
  end
  s = s:gsub(_G.string.char(168), _G.string.char(184))
  return s:lower()
end

function download(link,path,msg)
    lua_thread.create(function()
        downloadUrlToFile(link,
        path, function (id, status, p1, p2)
            if status == 58 and msg ~= nil then
                PushMessage(fa.ICON_DOWNLOAD.. u8' Успешно скачан файл '..msg)
            end
        end)
    wait(250)
        PushMessage(fa.ICON_REFRESH.. u8' Перезагружаю скрипт через 5секунд!..')
    wait(5000)
        thisScript():reload()
    end)
end

function printToLog(text)
    print(tostring(text))

    if printToLogBool then 
        if not doesDirectoryExist('moonloader\\config\\Telegram Control SAMP\\Logs') then 
            createDirectory('moonloader\\config\\Telegram Control SAMP\\Logs')
        elseif doesDirectoryExist('moonloader\\config\\Telegram Control SAMP\\Logs') then 
            log = io.open(getFileName(), "r+")
            log:seek("end", 0);
            log:write("["..os.date('%H:%M:%S') .. "] " .. text .. ".\n")
            log:flush()
            log:close()
        end
    end

end

function GetRaw() --who??????????????????????????????? 
    requests = require('requests')
    response = requests.get("https://raw.githubusercontent.com/Vespan/Telegram-Control-SAMP/main/who%3F.json")
    if response.status_code == 200 then
        Raw = {version = response.json().version,info=response.json().info,other=response.json().other}
    else
        Raw = {version =nil,info=nil,other=nil}
    end
end

function  getFileName() --- взял с ChatLog Saver UPD.lua
    if not doesFileExist("moonloader\\config\\Telegram Control SAMP\\Logs\\"..os.date('%d.%m.%y')..".txt") then
        f = io.open("moonloader\\config\\Telegram Control SAMP\\Logs\\"..os.date('%d.%m.%y')..".txt","w")
        f:close()
        file = string.format("moonloader\\config\\Telegram Control SAMP\\Logs\\"..os.date('%d.%m.%y')..".txt")
        return file
    else
        file = string.format("moonloader\\config\\Telegram Control SAMP\\Logs\\"..os.date('%d.%m.%y')..".txt")
        return file  
    end
end

function sampGetPlayerIdByNickname(nick) -- by Imring
    local _, myid = sampGetPlayerIdByCharHandle(playerPed)
    if tostring(nick) == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1000 do if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then return i end end
end

function workpaus(bool) -- ВЗЯЛ С AFK-TOOLS
    if bool then
        memory.setuint8(7634870, 1, false)
        memory.setuint8(7635034, 1, false)
        memory.fill(7623723, 144, 8, false)
        memory.fill(5499528, 144, 6, false)
    else
        memory.setuint8(7634870, 0, false)
        memory.setuint8(7635034, 0, false)
        memory.hex2bin('0F 84 7B 01 00 00', 7623723, 8)
        memory.hex2bin('50 51 FF 15 00 83 85 00', 5499528, 6)
    end
end

function sendTelegramNotificationFlood(text)
    lua_thread.create(function()
        if not ToggleButton.NotificationFlood.v then 
            sendTelegramNotification(text)
        else
            sendTelegramNotification(text)
        wait(1000)
            sendTelegramNotification(text)
        wait(1000)
            sendTelegramNotification(text)
        end
    end)
end

function getafk() -- GET AFK
    return math.modf((os.clock() - afk) - gameClock())
end

function FormatTime(time) -- TIME
    local timezone_offset = 86400 - os.date('%H', 0) * 3600
    local time = time + timezone_offset
    return  os.date((os.date("%H",time) == "00" and '%M:%S' or '%H:%M:%S'), time)
end

function onSendPacket(id, bitStream, priority, reliability, orderingChannel)
    if FakeAfk then
        if id == 207 then
            return false
        end
        return true
    end
end

function onScriptTerminate(script, quitGame) -- 

    if script == thisScript() then
        if not quitGame and ToggleButton.AutoReboot.v and doesFileExist('moonloader\\config\\Telegram Control SAMP\\AutoRebootTelegramControlSAMP.lua') then 
            AutoReboot.crash()
        end
        --sampAddChatMessage('{00c8ff}TCS:{FF0000}CRASH{00c8ff}.', 0x00c8ff)
        save()
        sendTelegramNotification('[SAMP | Disconected]:\nВы вышли из игры')

        if printToLogBool then 
            if not doesDirectoryExist('moonloader\\config\\Telegram Control SAMP\\Logs') then 
                createDirectory('moonloader\\config\\Telegram Control SAMP\\Logs')
            elseif doesDirectoryExist('moonloader\\config\\Telegram Control SAMP\\Logs') then 
                log = io.open(getFileName(), "r+")
                log:seek("end", 0);
                log:write('----==============================================----\n')
                log:flush()
                log:close()
            end
        end

    end
end

function save() -- #save
    Config.Script.AutoReboot = ToggleButton.AutoReboot.v
    Config.Script.Cmd = Input.Cmd.v

    --Telegram
    Config.Telegram.Token = Input.Token.v
    Config.Telegram.ChatId = Input.ChatId.v
    Config.Telegram.Bot = ToggleButton.Bot.v

    --ToggleButton

    --ImInt

    --Events
        --ImInt
        Config.Events.DoPayDaya = ImInt.DoPayDaya.v
        Config.Events.CheckerMode = ImInt.Checker.v 
        --ToggleButton
        Config.Notifications.TimeStamp = ToggleButton.TimeStamp.v
        Config.Notifications.Dialog = ToggleButton.Notf_Dialog.v
        Config.Events.NotificationFlood = ToggleButton.NotificationFlood.v
        Config.Events.PayDay = ToggleButton.PayDay.v
        Config.Events.KillMe = ToggleButton.KillMe.v
        Config.Events.Capt = ToggleButton.Capt.v
        Config.Events.Checker = ToggleButton.Checker.v 
        --Input

    --Cmds
    Config.Cmds.GetStream = Input.Cmd_GetStream.v
    Config.Cmds.Send = Input.Cmd_Send.v
    Config.Cmds.Chat = Input.Cmd_Chat.v
    Config.Cmds.Time = Input.Cmd_Time.v
    Config.Cmds.Quit = Input.Cmd_Quit.v
    Config.Cmds.FakeAFK = Input.Cmd_FakeAFK.v
    Config.Cmds.AntiAFK = Input.Cmd_AntiAFK.v
    Config.Cmds.ScreenShot = Input.Cmd_ScreenShot.v
    Config.Cmds.Stats = Input.Cmd_Stats.v 

    --AutoFood
    Config.AutoFood.Food = Input.Cmd_Food.v 
    Config.AutoFood.Bool = ToggleButton.AutoFood.v 
    Config.AutoFood.Timer = ImInt.TimerAutoFood.v 
    Config.AutoFood.Method = ImInt.MethodAutoFood.v
    Config.AutoFood.After = Input.AfterAutoFood.v

    --AutoHeal
    Config.AutoHeal.Bool = ToggleButton.AutoHeal.v  
    Config.AutoHeal.HP = ImInt.HP.v 
    Config.AutoHeal.Heal = Input.Cmd_Health.v 

    --dialog
    Config.Cmds.Dialog_Input = Input.Cmd_Dialog_Input.v
    Config.Cmds.Dialog_List = Input.Cmd_Dialog_List.v
    Config.Cmds.Dialog_Close = Input.Cmd_Dialog_Close.v            

    if inicfg.save(Config, '..\\config\\Telegram Control SAMP\\Config.ini') then 
        PushMessage(fa.ICON_FLOPPY_O .. u8' Настройки - успешно сохранены! ' .. fa.ICON_FLOPPY_O)
    else
        PushMessage(fa.ICON_EXCLAMATION_TRIANGLE .. u8' Настройки - ошибка при сохранении ' .. fa.ICON_EXCLAMATION_TRIANGLE)
    end
end

-- IMGUI ------------------------------------------------------------------------------------------------------

function imgui.Spinner(radius, thickness) -- ВЗЯЛ С imgui_addons.lua || АВТОР:DonHomka

    local style = imgui.GetStyle()
    local pos = imgui.GetCursorScreenPos()
    local size = imgui.ImVec2(radius * 2, (radius + style.FramePadding.y) * 2)
    
    imgui.Dummy(imgui.ImVec2(size.x + style.ItemSpacing.x, size.y))

    local DrawList = imgui.GetWindowDrawList()
    DrawList:PathClear()
    
    local num_segments = 30
    local start = math.abs(math.sin(imgui.GetTime() * 1.8) * (num_segments - 5))
    
    local a_min = 3.14 * 2.0 * start / num_segments
    local a_max = 3.14 * 2.0 * (num_segments - 3) / num_segments

    local centre = imgui.ImVec2(pos.x + radius, pos.y + radius + style.FramePadding.y)
    
    for i = 0, num_segments do
        local a = a_min + (i / num_segments) * (a_max - a_min)
        DrawList:PathLineTo(imgui.ImVec2(centre.x + math.cos(a + imgui.GetTime() * 8) * radius, centre.y + math.sin(a + imgui.GetTime() * 8) * radius))
    end

    DrawList:PathStroke(imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]), false, thickness)
    return true
end

function imgui.ToggleButton(str_id, bool) -- ВЗЯЛ С imgui_addons.lua || АВТОР:DonHomka
    local rBool = false

    if LastActiveTime == nil then
        LastActiveTime = {}
    end
    if LastActive == nil then
        LastActive = {}
    end
    
    if (string.sub(str_id, 1, 2) ~= "##") then
        imgui.Text(str_id)
        imgui.SameLine()
    end
    

    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end
    
    local p = imgui.GetCursorScreenPos()
    local draw_list = imgui.GetWindowDrawList()

    local height = imgui.GetTextLineHeightWithSpacing()
    local width = height * 1.55
    local radius = height * 0.50
    local ANIM_SPEED = 0.15

    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        bool.v = not bool.v
        rBool = true
        LastActiveTime[tostring(str_id)] = os.clock()
        LastActive[tostring(str_id)] = true
    end

    local t = bool.v and 1.0 or 0.0

    if LastActive[tostring(str_id)] then
        local time = os.clock() - LastActiveTime[tostring(str_id)]
        if time <= ANIM_SPEED then
            local t_anim = ImSaturate(time / ANIM_SPEED)
            t = bool.v and t_anim or 1.0 - t_anim
        else
            LastActive[tostring(str_id)] = false
        end
    end

    local col_bg
    if bool.v then
        col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBgHovered])
    else
        col_bg = imgui.ImColor(100, 100, 100, 180):GetU32()
    end

    draw_list:AddRectFilled(imgui.ImVec2(p.x, p.y + (height / 6)), imgui.ImVec2(p.x + width - 1.0, p.y + (height - (height / 6))), col_bg, 5.0)
    draw_list:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 0.75, imgui.GetColorU32(bool.v and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.ImColor(150, 150, 150, 255):GetVec4()))

    return rBool
end

function money_separator(n) -- money_separator.lua
    local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function imgui.NewInputText(lable, val, width, hint, hintpos) -- https://www.blast.hk/threads/64892/post-585642
    local hint = hint and hint or ''
    local hintpos = tonumber(hintpos) and tonumber(hintpos) or 1
    local cPos = imgui.GetCursorPos()
    imgui.PushItemWidth(width)
    local result = imgui.InputText(lable, val)
    if #val.v == 0 then
        local hintSize = imgui.CalcTextSize(hint)
        if hintpos == 2 then imgui.SameLine(cPos.x + (width - hintSize.x) / 2)
        elseif hintpos == 3 then imgui.SameLine(cPos.x + (width - hintSize.x - 5))
        else imgui.SameLine(cPos.x + 5) end
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 0.40), tostring(hint))
    end
    imgui.PopItemWidth()
    return result
end

function imgui.ButtonHex(lable, rgb, size, rounding)
    if rounding == nil then
        rounding = 1
    end
    local r = bit.band(bit.rshift(rgb, 16), 0xFF) / 255
    local g = bit.band(bit.rshift(rgb, 8), 0xFF) / 255
    local b = bit.band(rgb, 0xFF) / 255

    imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, 0.6))
    imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, 0.8))
    imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, 1.0))
    imgui.PushStyleVar(imgui.StyleVar.FrameRounding,rounding)
    local button = imgui.Button(lable, size)
    imgui.PopStyleVar(1)
    imgui.PopStyleColor(3) 
    return button
end

function imgui.FontSize(size)
    imgui.SetWindowFontScale(size)
end

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig() -- to use 'imgui.ImFontConfig.new()' on error
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0, font_config, fa_glyph_ranges)
    end
end

function imgui.CenterText(text, color)
    color = color or imgui.GetStyle().Colors[imgui.Col.Text]
    local width = imgui.GetWindowWidth()
    for line in text:gmatch('[^\n]+') do
        local lenght = imgui.CalcTextSize(line).x
        imgui.SetCursorPosX((width - lenght) / 2)
        imgui.TextColored(color, line)
    end
end

function PushMessage(text)
    if nClock == 0 then 
        nClock = os.clock()
    else
        nClock = nClock + 3
    end
    table.insert(nText,text)
    PushMessageAnimBool = true 
end

function imgui.Link(url)
    imgui.SameLine()
    imgui.TextDisabled(fa.ICON_LINK)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 6 -- скорость появления
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(u8'*Кликабельная Ссылка*')
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end    
    if imgui.IsItemClicked() then
        os.execute('explorer '..url)
    end
end

function imgui.TextQuestion(text, delay) --https://www.blast.hk/threads/13380/post-551583
    imgui.SameLine()
    imgui.TextDisabled(fa.ICON_QUESTION_CIRCLE)
    if imgui.IsItemHovered() then
        if go_hint == nil then go_hint = os.clock() + (delay and delay or 0.0) end
        local alpha = (os.clock() - go_hint) * 6 -- скорость появления
        if os.clock() >= go_hint then
            imgui.PushStyleVar(imgui.StyleVar.Alpha, (alpha <= 1.0 and alpha or 1.0))
                imgui.PushStyleColor(imgui.Col.PopupBg, imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(450)
                    imgui.TextUnformatted(text)
                    if not imgui.IsItemVisible() and imgui.GetStyle().Alpha == 1.0 then go_hint = nil end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                imgui.PopStyleColor()
            imgui.PopStyleVar()
        end
    end
end

function apply_custom_style()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
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

-- TELEGRAM

function threadHandle(runner, url, args, resolve, reject)
    local t = runner(url, args)
    local r = t:get(0)
    while not r do
        r = t:get(0)
        wait(0)
    end
    local status = t:status()
    if status == 'completed' then
        local ok, result = r[1], r[2]
        if ok then resolve(result) else reject(result) end
    elseif err then
        reject(err)
    elseif status == 'canceled' then
        reject(status)
    end
    t:cancel(0)
end

function requestRunner()
    return effil.thread(function(u, a)
        local https = require 'ssl.https'
        local ok, result = pcall(https.request, u, a)
        if ok then
            return {true, result}
        else
            return {false, result}
        end
    end)
end

function async_http_request(url, args, resolve, reject)
    local runner = requestRunner()
    if not reject then reject = function() end end
    lua_thread.create(function()
        threadHandle(runner, url, args, resolve, reject)
    end)
end

function encodeUrl(str)
    str = str:gsub(' ', '%+')
    str = str:gsub('\n', '%%0A')
    return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg) -- функция для отправки сообщения юзеру
    if ToggleButton.TimeStamp.v then 
        msg = os.date('[%H:%M:%S]') .. msg 
    end
    printToLog('{00c8ff}<[Telegram Control SAMP]{FFFFFF}:'..msg .. '{00c8ff}>')
    msg = msg:gsub('{......}', '') --тут типо убираем цвет
    msg = encodeUrl(msg) -- ну тут мы закодируем строку
    if ToggleButton.Bot.v then 
        async_http_request('https://api.telegram.org/bot' .. Config.Telegram.Token .. '/sendMessage?chat_id=' .. Config.Telegram.ChatId .. '&text='..msg,'', function(result) end) -- а тут уже отправка
    -- https://api.telegram.org/bot5112445152:AAEQxZoLs5hq-D8gFZ6BDBYPprX8XrMwsNA/sendMessage?chat_id=620180223&text=test
    -- https://api.telegram.org/bot5112445152:AAEQxZoLs5hq-D8gFZ6BDBYPprX8XrMwsNA/sendPhoto?chat_id=620180223&photo=
    else 
        addOneOffSound(0, 0, 0, 1084)
    end
end

function get_telegram_updates() -- функция получения сообщений от юзера
    while not updateid do wait(1) end -- ждем пока не узнаем последний ID
    local runner = requestRunner()
    local reject = function() end
    local args = ''
    while true do wait(100)
        url = 'https://api.telegram.org/bot' .. Config.Telegram.Token .. '/getUpdates?chat_id='..Config.Telegram.ChatId..'&offset=-1' -- создаем ссылку
        threadHandle(runner, url, args, processing_telegram_messages, reject)
       -- wait(0)
    end
end

function getLastUpdate() -- тут мы получаем последний ID сообщения, если же у вас в коде будет настройка токена и chat_id, вызовите эту функцию для того чтоб получить последнее сообщение
    async_http_request('https://api.telegram.org/bot' .. Config.Telegram.Token .. '/getUpdates?chat_id='..Config.Telegram.ChatId..'&offset=-1','',function(result)
        if result then
            local proc_table = decodeJson(result)
            if proc_table.ok then
                if #proc_table.result > 0 then
                    local res_table = proc_table.result[1]
                    if res_table then
                        updateid = res_table.update_id
                    end
                else
                    updateid = 1 -- тут зададим значение 1, если таблица будет пустая
                end
            end
        end
    end)
end

-------------- не важно ----------------------
function getweaponname(weapon)
  local names = {
  [0] = "Nothing",
  [1] = "Brass Knuckles",
  [2] = "Golf Club",
  [3] = "Nightstick",
  [4] = "Knife",
  [5] = "Baseball Bat",
  [6] = "Shovel",
  [7] = "Pool Cue",
  [8] = "Katana",
  [9] = "Chainsaw",
  [10] = "Purple Dildo",
  [11] = "Dildo",
  [12] = "Vibrator",
  [13] = "Silver Vibrator",
  [14] = "Flowers",
  [15] = "Cane",
  [16] = "Grenade",
  [17] = "Tear Gas",
  [18] = "Molotov Cocktail",
  [22] = "9mm",
  [23] = "Silenced 9mm",
  [24] = "Desert Eagle",
  [25] = "Shotgun",
  [26] = "Sawnoff Shotgun",
  [27] = "Combat Shotgun",
  [28] = "Micro SMG/Uzi",
  [29] = "MP5",
  [30] = "AK-47",
  [31] = "M4",
  [32] = "Tec-9",
  [33] = "Country Rifle",
  [34] = "Sniper Rifle",
  [35] = "RPG",
  [36] = "HS Rocket",
  [37] = "Flamethrower",
  [38] = "Minigun",
  [39] = "Satchel Charge",
  [40] = "Detonator",
  [41] = "Spraycan",
  [42] = "Fire Extinguisher",
  [43] = "Camera",
  [44] = "Night Vis Goggles",
  [45] = "Thermal Goggles",
  [46] = "Parachute" }
  return names[weapon]
end

function calc(str) 
    return assert(load("return "..str))()
end

function calculateZone(x, y, z) -- https://www.blast.hk/threads/40484/
    local streets = {
        {"Загородный клуб «Ависпа»", -2667.810, -302.135, -28.831, -2646.400, -262.320, 71.169},
        {"Международный аэропорт Рстер-Бэй", -1315.420, -405.388, 15.406, -1264.400, -209.543, 25.406},
        {"Загородный клуб «Ависпа»", -2550.040, -355.493, 0.000, -2470.040, -318.493, 39.700},
        {"Международный аэропорт Рстер-Бэй", -1490.330, -209.543, 15.406, -1264.400, -148.388, 25.406},
        {"Гарсия", -2395.140, -222.589, -5.3, -2354.090, -204.792, 200.000},
        {"Шейди-Кэбин", -1632.830, -2263.440, -3.0, -1601.330, -2231.790, 200.000},
        {"Восточный Лос-Сантос", 2381.680, -1494.030, -89.084, 2421.030, -1454.350, 110.916},
        {"Грузовое депо Лас-Вентураса", 1236.630, 1163.410, -89.084, 1277.050, 1203.280, 110.916},
        {"Пересечение Блэкфилд", 1277.050, 1044.690, -89.084, 1315.350, 1087.630, 110.916},
        {"Загородный клуб «Ависпа»", -2470.040, -355.493, 0.000, -2270.040, -318.493, 46.100},
        {"Темпл", 1252.330, -926.999, -89.084, 1357.000, -910.170, 110.916},
        {"Станция «Юнити»", 1692.620, -1971.800, -20.492, 1812.620, -1932.800, 79.508},
        {"Грузовое депо Лас-Вентураса", 1315.350, 1044.690, -89.084, 1375.600, 1087.630, 110.916},
        {"Лос-Флорес", 2581.730, -1454.350, -89.084, 2632.830, -1393.420, 110.916},
        {"Казино «Морская звезда»", 2437.390, 1858.100, -39.084, 2495.090, 1970.850, 60.916},
        {"Химзавод Рстер-Бэй", -1132.820, -787.391, 0.000, -956.476, -768.027, 200.000},
        {"Деловой район", 1370.850, -1170.870, -89.084, 1463.900, -1130.850, 110.916},
        {"Восточная Эспаланда", -1620.300, 1176.520, -4.5, -1580.010, 1274.260, 200.000},
        {"Станция «Маркет»", 787.461, -1410.930, -34.126, 866.009, -1310.210, 65.874},
        {"Станция «Линден»", 2811.250, 1229.590, -39.594, 2861.250, 1407.590, 60.406},
        {"Пересечение Монтгомери", 1582.440, 347.457, 0.000, 1664.620, 401.750, 200.000},
        {"Мост «Фредерик»", 2759.250, 296.501, 0.000, 2774.250, 594.757, 200.000},
        {"Станция «Йеллоу-Белл»", 1377.480, 2600.430, -21.926, 1492.450, 2687.360, 78.074},
        {"Деловой район", 1507.510, -1385.210, 110.916, 1582.550, -1325.310, 335.916},
        {"Джефферсон", 2185.330, -1210.740, -89.084, 2281.450, -1154.590, 110.916},
        {"Малхолланд", 1318.130, -910.170, -89.084, 1357.000, -768.027, 110.916},
        {"Загородный клуб «Ависпа»", -2361.510, -417.199, 0.000, -2270.040, -355.493, 200.000},
        {"Джефферсон", 1996.910, -1449.670, -89.084, 2056.860, -1350.720, 110.916},
        {"Западаная автострада Джулиус", 1236.630, 2142.860, -89.084, 1297.470, 2243.230, 110.916},
        {"Джефферсон", 2124.660, -1494.030, -89.084, 2266.210, -1449.670, 110.916},
        {"Северная автострада Джулиус", 1848.400, 2478.490, -89.084, 1938.800, 2553.490, 110.916},
        {"Родео", 422.680, -1570.200, -89.084, 466.223, -1406.050, 110.916},
        {"Станция «Крэнберри»", -2007.830, 56.306, 0.000, -1922.000, 224.782, 100.000},
        {"Деловой район", 1391.050, -1026.330, -89.084, 1463.900, -926.999, 110.916},
        {"Западный Рэдсэндс", 1704.590, 2243.230, -89.084, 1777.390, 2342.830, 110.916},
        {"Маленькая Мексика", 1758.900, -1722.260, -89.084, 1812.620, -1577.590, 110.916},
        {"Пересечение Блэкфилд", 1375.600, 823.228, -89.084, 1457.390, 919.447, 110.916},
        {"Международный аэропорт Лос-Сантос", 1974.630, -2394.330, -39.084, 2089.000, -2256.590, 60.916},
        {"Бекон-Хилл", -399.633, -1075.520, -1.489, -319.033, -977.516, 198.511},
        {"Родео", 334.503, -1501.950, -89.084, 422.680, -1406.050, 110.916},
        {"Ричман", 225.165, -1369.620, -89.084, 334.503, -1292.070, 110.916},
        {"Деловой район", 1724.760, -1250.900, -89.084, 1812.620, -1150.870, 110.916},
        {"Стрип", 2027.400, 1703.230, -89.084, 2137.400, 1783.230, 110.916},
        {"Деловой район", 1378.330, -1130.850, -89.084, 1463.900, -1026.330, 110.916},
        {"Пересечение Блэкфилд", 1197.390, 1044.690, -89.084, 1277.050, 1163.390, 110.916},
        {"Конференц Центр", 1073.220, -1842.270, -89.084, 1323.900, -1804.210, 110.916},
        {"Монтгомери", 1451.400, 347.457, -6.1, 1582.440, 420.802, 200.000},
        {"Долина Фостер", -2270.040, -430.276, -1.2, -2178.690, -324.114, 200.000},
        {"Часовня Блэкфилд", 1325.600, 596.349, -89.084, 1375.600, 795.010, 110.916},
        {"Международный аэропорт Лос-Сантос", 2051.630, -2597.260, -39.084, 2152.450, -2394.330, 60.916},
        {"Малхолланд", 1096.470, -910.170, -89.084, 1169.130, -768.027, 110.916},
        {"Поле для гольфа «Йеллоу-Белл»", 1457.460, 2723.230, -89.084, 1534.560, 2863.230, 110.916},
        {"Стрип", 2027.400, 1783.230, -89.084, 2162.390, 1863.230, 110.916},
        {"Джефферсон", 2056.860, -1210.740, -89.084, 2185.330, -1126.320, 110.916},
        {"Малхолланд", 952.604, -937.184, -89.084, 1096.470, -860.619, 110.916},
        {"Альдеа-Мальвада", -1372.140, 2498.520, 0.000, -1277.590, 2615.350, 200.000},
        {"Лас-Колинас", 2126.860, -1126.320, -89.084, 2185.330, -934.489, 110.916},
        {"Лас-Колинас", 1994.330, -1100.820, -89.084, 2056.860, -920.815, 110.916},
        {"Ричман", 647.557, -954.662, -89.084, 768.694, -860.619, 110.916},
        {"Грузовое депо Лас-Вентураса", 1277.050, 1087.630, -89.084, 1375.600, 1203.280, 110.916},
        {"Северная автострада Джулиус", 1377.390, 2433.230, -89.084, 1534.560, 2507.230, 110.916},
        {"Уиллоуфилд", 2201.820, -2095.000, -89.084, 2324.000, -1989.900, 110.916},
        {"Северная автострада Джулиус", 1704.590, 2342.830, -89.084, 1848.400, 2433.230, 110.916},
        {"Темпл", 1252.330, -1130.850, -89.084, 1378.330, -1026.330, 110.916},
        {"Маленькая Мексика", 1701.900, -1842.270, -89.084, 1812.620, -1722.260, 110.916},
        {"Квинс", -2411.220, 373.539, 0.000, -2253.540, 458.411, 200.000},
        {"Аэропорт Лас-Вентурас", 1515.810, 1586.400, -12.500, 1729.950, 1714.560, 87.500},
        {"Ричман", 225.165, -1292.070, -89.084, 466.223, -1235.070, 110.916},
        {"Темпл", 1252.330, -1026.330, -89.084, 1391.050, -926.999, 110.916},
        {"Восточный Лос-Сантос", 2266.260, -1494.030, -89.084, 2381.680, -1372.040, 110.916},
        {"Восточная автострада Джулиус", 2623.180, 943.235, -89.084, 2749.900, 1055.960, 110.916},
        {"Уиллоуфилд", 2541.700, -1941.400, -89.084, 2703.580, -1852.870, 110.916},
        {"Лас-Колинас", 2056.860, -1126.320, -89.084, 2126.860, -920.815, 110.916},
        {"Восточная автострада Джулиус", 2625.160, 2202.760, -89.084, 2685.160, 2442.550, 110.916},
        {"Родео", 225.165, -1501.950, -89.084, 334.503, -1369.620, 110.916},
        {"Лас-Брухас", -365.167, 2123.010, -3.0, -208.570, 2217.680, 200.000},
        {"Восточная автострада Джулиус", 2536.430, 2442.550, -89.084, 2685.160, 2542.550, 110.916},
        {"Родео", 334.503, -1406.050, -89.084, 466.223, -1292.070, 110.916},
        {"Вайнвуд", 647.557, -1227.280, -89.084, 787.461, -1118.280, 110.916},
        {"Родео", 422.680, -1684.650, -89.084, 558.099, -1570.200, 110.916},
        {"Северная автострада Джулиус", 2498.210, 2542.550, -89.084, 2685.160, 2626.550, 110.916},
        {"Деловой район", 1724.760, -1430.870, -89.084, 1812.620, -1250.900, 110.916},
        {"Родео", 225.165, -1684.650, -89.084, 312.803, -1501.950, 110.916},
        {"Джефферсон", 2056.860, -1449.670, -89.084, 2266.210, -1372.040, 110.916},
        {"Хэмптон-Барнс", 603.035, 264.312, 0.000, 761.994, 366.572, 200.000},
        {"Темпл", 1096.470, -1130.840, -89.084, 1252.330, -1026.330, 110.916},
        {"Мост «Кинкейд»", -1087.930, 855.370, -89.084, -961.950, 986.281, 110.916},
        {"Пляж «Верона»", 1046.150, -1722.260, -89.084, 1161.520, -1577.590, 110.916},
        {"Коммерческий район", 1323.900, -1722.260, -89.084, 1440.900, -1577.590, 110.916},
        {"Малхолланд", 1357.000, -926.999, -89.084, 1463.900, -768.027, 110.916},
        {"Родео", 466.223, -1570.200, -89.084, 558.099, -1385.070, 110.916},
        {"Малхолланд", 911.802, -860.619, -89.084, 1096.470, -768.027, 110.916},
        {"Малхолланд", 768.694, -954.662, -89.084, 952.604, -860.619, 110.916},
        {"Южная автострада Джулиус", 2377.390, 788.894, -89.084, 2537.390, 897.901, 110.916},
        {"Айдлвуд", 1812.620, -1852.870, -89.084, 1971.660, -1742.310, 110.916},
        {"Океанские доки", 2089.000, -2394.330, -89.084, 2201.820, -2235.840, 110.916},
        {"Коммерческий район", 1370.850, -1577.590, -89.084, 1463.900, -1384.950, 110.916},
        {"Северная автострада Джулиус", 2121.400, 2508.230, -89.084, 2237.400, 2663.170, 110.916},
        {"Темпл", 1096.470, -1026.330, -89.084, 1252.330, -910.170, 110.916},
        {"Глен Парк", 1812.620, -1449.670, -89.084, 1996.910, -1350.720, 110.916},
        {"Международный аэропорт Рстер-Бэй", -1242.980, -50.096, 0.000, -1213.910, 578.396, 200.000},
        {"Мост «Мартин»", -222.179, 293.324, 0.000, -122.126, 476.465, 200.000},
        {"Стрип", 2106.700, 1863.230, -89.084, 2162.390, 2202.760, 110.916},
        {"Уиллоуфилд", 2541.700, -2059.230, -89.084, 2703.580, -1941.400, 110.916},
        {"Марина", 807.922, -1577.590, -89.084, 926.922, -1416.250, 110.916},
        {"Аэропорт Лас-Вентурас", 1457.370, 1143.210, -89.084, 1777.400, 1203.280, 110.916},
        {"Айдлвуд", 1812.620, -1742.310, -89.084, 1951.660, -1602.310, 110.916},
        {"Восточная Эспаланда", -1580.010, 1025.980, -6.1, -1499.890, 1274.260, 200.000},
        {"Деловой район", 1370.850, -1384.950, -89.084, 1463.900, -1170.870, 110.916},
        {"Мост «Мако»", 1664.620, 401.750, 0.000, 1785.140, 567.203, 200.000},
        {"Родео", 312.803, -1684.650, -89.084, 422.680, -1501.950, 110.916},
        {"Площадь «Першинг»", 1440.900, -1722.260, -89.084, 1583.500, -1577.590, 110.916},
        {"Малхолланд", 687.802, -860.619, -89.084, 911.802, -768.027, 110.916},
        {"Мост «Гант»", -2741.070, 1490.470, -6.1, -2616.400, 1659.680, 200.000},
        {"Лас-Колинас", 2185.330, -1154.590, -89.084, 2281.450, -934.489, 110.916},
        {"Малхолланд", 1169.130, -910.170, -89.084, 1318.130, -768.027, 110.916},
        {"Северная автострада Джулиус", 1938.800, 2508.230, -89.084, 2121.400, 2624.230, 110.916},
        {"Коммерческий район", 1667.960, -1577.590, -89.084, 1812.620, -1430.870, 110.916},
        {"Родео", 72.648, -1544.170, -89.084, 225.165, -1404.970, 110.916},
        {"Рока-Эскаланте", 2536.430, 2202.760, -89.084, 2625.160, 2442.550, 110.916},
        {"Родео", 72.648, -1684.650, -89.084, 225.165, -1544.170, 110.916},
        {"Маркет", 952.663, -1310.210, -89.084, 1072.660, -1130.850, 110.916},
        {"Лас-Колинас", 2632.740, -1135.040, -89.084, 2747.740, -945.035, 110.916},
        {"Малхолланд", 861.085, -674.885, -89.084, 1156.550, -600.896, 110.916},
        {"Кингс", -2253.540, 373.539, -9.1, -1993.280, 458.411, 200.000},
        {"Восточный Рэдсэндс", 1848.400, 2342.830, -89.084, 2011.940, 2478.490, 110.916},
        {"Деловой район", -1580.010, 744.267, -6.1, -1499.890, 1025.980, 200.000},
        {"Конференц Центр", 1046.150, -1804.210, -89.084, 1323.900, -1722.260, 110.916},
        {"Ричман", 647.557, -1118.280, -89.084, 787.461, -954.662, 110.916},
        {"Оушен-Флэтс", -2994.490, 277.411, -9.1, -2867.850, 458.411, 200.000},
        {"Колледж Грингласс", 964.391, 930.890, -89.084, 1166.530, 1044.690, 110.916},
        {"Глен Парк", 1812.620, -1100.820, -89.084, 1994.330, -973.380, 110.916},
        {"Грузовое депо Лас-Вентураса", 1375.600, 919.447, -89.084, 1457.370, 1203.280, 110.916},
        {"Регьюлар-Том", -405.770, 1712.860, -3.0, -276.719, 1892.750, 200.000},
        {"Пляж «Верона»", 1161.520, -1722.260, -89.084, 1323.900, -1577.590, 110.916},
        {"Восточный Лос-Сантос", 2281.450, -1372.040, -89.084, 2381.680, -1135.040, 110.916},
        {"Дворец Калигулы", 2137.400, 1703.230, -89.084, 2437.390, 1783.230, 110.916},
        {"Айдлвуд", 1951.660, -1742.310, -89.084, 2124.660, -1602.310, 110.916},
        {"Пилигрим", 2624.400, 1383.230, -89.084, 2685.160, 1783.230, 110.916},
        {"Айдлвуд", 2124.660, -1742.310, -89.084, 2222.560, -1494.030, 110.916},
        {"Квинс", -2533.040, 458.411, 0.000, -2329.310, 578.396, 200.000},
        {"Деловой район", -1871.720, 1176.420, -4.5, -1620.300, 1274.260, 200.000},
        {"Коммерческий район", 1583.500, -1722.260, -89.084, 1758.900, -1577.590, 110.916},
        {"Восточный Лос-Сантос", 2381.680, -1454.350, -89.084, 2462.130, -1135.040, 110.916},
        {"Марина", 647.712, -1577.590, -89.084, 807.922, -1416.250, 110.916},
        {"Ричман", 72.648, -1404.970, -89.084, 225.165, -1235.070, 110.916},
        {"Вайнвуд", 647.712, -1416.250, -89.084, 787.461, -1227.280, 110.916},
        {"Восточный Лос-Сантос", 2222.560, -1628.530, -89.084, 2421.030, -1494.030, 110.916},
        {"Родео", 558.099, -1684.650, -89.084, 647.522, -1384.930, 110.916},
        {"Рстерский Тоннель", -1709.710, -833.034, -1.5, -1446.010, -730.118, 200.000},
        {"Родео", 466.223, -1385.070, -89.084, 647.522, -1235.070, 110.916},
        {"Восточный Рэдсэндс", 1817.390, 2202.760, -89.084, 2011.940, 2342.830, 110.916},
        {"Казино «Карман клоуна»", 2162.390, 1783.230, -89.084, 2437.390, 1883.230, 110.916},
        {"Айдлвуд", 1971.660, -1852.870, -89.084, 2222.560, -1742.310, 110.916},
        {"Пересечение Монтгомери", 1546.650, 208.164, 0.000, 1745.830, 347.457, 200.000},
        {"Уиллоуфилд", 2089.000, -2235.840, -89.084, 2201.820, -1989.900, 110.916},
        {"Темпл", 952.663, -1130.840, -89.084, 1096.470, -937.184, 110.916},
        {"Прикл-Пайн", 1848.400, 2553.490, -89.084, 1938.800, 2863.230, 110.916},
        {"Международный аэропорт Лос-Сантос", 1400.970, -2669.260, -39.084, 2189.820, -2597.260, 60.916},
        {"Мост «Гарвер»", -1213.910, 950.022, -89.084, -1087.930, 1178.930, 110.916},
        {"Мост «Гарвер»", -1339.890, 828.129, -89.084, -1213.910, 1057.040, 110.916},
        {"Мост «Кинкейд»", -1339.890, 599.218, -89.084, -1213.910, 828.129, 110.916},
        {"Мост «Кинкейд»", -1213.910, 721.111, -89.084, -1087.930, 950.022, 110.916},
        {"Пляж «Верона»", 930.221, -2006.780, -89.084, 1073.220, -1804.210, 110.916},
        {"Обсерватория «Зелёный утёс»", 1073.220, -2006.780, -89.084, 1249.620, -1842.270, 110.916},
        {"Вайнвуд", 787.461, -1130.840, -89.084, 952.604, -954.662, 110.916},
        {"Вайнвуд", 787.461, -1310.210, -89.084, 952.663, -1130.840, 110.916},
        {"Коммерческий район", 1463.900, -1577.590, -89.084, 1667.960, -1430.870, 110.916},
        {"Маркет", 787.461, -1416.250, -89.084, 1072.660, -1310.210, 110.916},
        {"Западный Рокшор", 2377.390, 596.349, -89.084, 2537.390, 788.894, 110.916},
        {"Северная автострада Джулиус", 2237.400, 2542.550, -89.084, 2498.210, 2663.170, 110.916},
        {"Восточный пляж", 2632.830, -1668.130, -89.084, 2747.740, -1393.420, 110.916},
        {"Мост «Фаллоу»", 434.341, 366.572, 0.000, 603.035, 555.680, 200.000},
        {"Уиллоуфилд", 2089.000, -1989.900, -89.084, 2324.000, -1852.870, 110.916},
        {"Чайнатаун", -2274.170, 578.396, -7.6, -2078.670, 744.170, 200.000},
        {"Эль-Кастильо-дель-Дьябло", -208.570, 2337.180, 0.000, 8.430, 2487.180, 200.000},
        {"Океанские доки", 2324.000, -2145.100, -89.084, 2703.580, -2059.230, 110.916},
        {"Химзавод Рстер-Бэй", -1132.820, -768.027, 0.000, -956.476, -578.118, 200.000},
        {"Казино «Визаж»", 1817.390, 1703.230, -89.084, 2027.400, 1863.230, 110.916},
        {"Оушен-Флэтс", -2994.490, -430.276, -1.2, -2831.890, -222.589, 200.000},
        {"Ричман", 321.356, -860.619, -89.084, 687.802, -768.027, 110.916},
        {"Нефтяной комплекс «Зеленый оазис»", 176.581, 1305.450, -3.0, 338.658, 1520.720, 200.000},
        {"Ричман", 321.356, -768.027, -89.084, 700.794, -674.885, 110.916},
        {"Казино «Морская звезда»", 2162.390, 1883.230, -89.084, 2437.390, 2012.180, 110.916},
        {"Восточный пляж", 2747.740, -1668.130, -89.084, 2959.350, -1498.620, 110.916},
        {"Джефферсон", 2056.860, -1372.040, -89.084, 2281.450, -1210.740, 110.916},
        {"Деловой район", 1463.900, -1290.870, -89.084, 1724.760, -1150.870, 110.916},
        {"Деловой район", 1463.900, -1430.870, -89.084, 1724.760, -1290.870, 110.916},
        {"Мост «Гарвер»", -1499.890, 696.442, -179.615, -1339.890, 925.353, 20.385},
        {"Южная автострада Джулиус", 1457.390, 823.228, -89.084, 2377.390, 863.229, 110.916},
        {"Восточный Лос-Сантос", 2421.030, -1628.530, -89.084, 2632.830, -1454.350, 110.916},
        {"Колледж «Грингласс»", 964.391, 1044.690, -89.084, 1197.390, 1203.220, 110.916},
        {"Лас-Колинас", 2747.740, -1120.040, -89.084, 2959.350, -945.035, 110.916},
        {"Малхолланд", 737.573, -768.027, -89.084, 1142.290, -674.885, 110.916},
        {"Океанские доки", 2201.820, -2730.880, -89.084, 2324.000, -2418.330, 110.916},
        {"Восточный Лос-Сантос", 2462.130, -1454.350, -89.084, 2581.730, -1135.040, 110.916},
        {"Гантон", 2222.560, -1722.330, -89.084, 2632.830, -1628.530, 110.916},
        {"Загородный клуб «Ависпа»", -2831.890, -430.276, -6.1, -2646.400, -222.589, 200.000},
        {"Уиллоуфилд", 1970.620, -2179.250, -89.084, 2089.000, -1852.870, 110.916},
        {"Северная Эспланада", -1982.320, 1274.260, -4.5, -1524.240, 1358.900, 200.000},
        {"Казино «Хай-Роллер»", 1817.390, 1283.230, -89.084, 2027.390, 1469.230, 110.916},
        {"Океанские доки", 2201.820, -2418.330, -89.084, 2324.000, -2095.000, 110.916},
        {"Мотель «Последний цент»", 1823.080, 596.349, -89.084, 1997.220, 823.228, 110.916},
        {"Бэйсайнд-Марина", -2353.170, 2275.790, 0.000, -2153.170, 2475.790, 200.000},
        {"Кингс", -2329.310, 458.411, -7.6, -1993.280, 578.396, 200.000},
        {"Эль-Корона", 1692.620, -2179.250, -89.084, 1812.620, -1842.270, 110.916},
        {"Часовня Блэкфилд", 1375.600, 596.349, -89.084, 1558.090, 823.228, 110.916},
        {"«Розовый лебедь»", 1817.390, 1083.230, -89.084, 2027.390, 1283.230, 110.916},
        {"Западаная автострада Джулиус", 1197.390, 1163.390, -89.084, 1236.630, 2243.230, 110.916},
        {"Лос-Флорес", 2581.730, -1393.420, -89.084, 2747.740, -1135.040, 110.916},
        {"Казино «Визаж»", 1817.390, 1863.230, -89.084, 2106.700, 2011.830, 110.916},
        {"Прикл-Пайн", 1938.800, 2624.230, -89.084, 2121.400, 2861.550, 110.916},
        {"Пляж «Верона»", 851.449, -1804.210, -89.084, 1046.150, -1577.590, 110.916},
        {"Пересечение Робада", -1119.010, 1178.930, -89.084, -862.025, 1351.450, 110.916},
        {"Линден-Сайд", 2749.900, 943.235, -89.084, 2923.390, 1198.990, 110.916},
        {"Океанские доки", 2703.580, -2302.330, -89.084, 2959.350, -2126.900, 110.916},
        {"Уиллоуфилд", 2324.000, -2059.230, -89.084, 2541.700, -1852.870, 110.916},
        {"Кингс", -2411.220, 265.243, -9.1, -1993.280, 373.539, 200.000},
        {"Коммерческий район", 1323.900, -1842.270, -89.084, 1701.900, -1722.260, 110.916},
        {"Малхолланд", 1269.130, -768.027, -89.084, 1414.070, -452.425, 110.916},
        {"Марина", 647.712, -1804.210, -89.084, 851.449, -1577.590, 110.916},
        {"Бэттери-Пойнт", -2741.070, 1268.410, -4.5, -2533.040, 1490.470, 200.000},
        {"Казино «4 Дракона»", 1817.390, 863.232, -89.084, 2027.390, 1083.230, 110.916},
        {"Блэкфилд", 964.391, 1203.220, -89.084, 1197.390, 1403.220, 110.916},
        {"Северная автострада Джулиус", 1534.560, 2433.230, -89.084, 1848.400, 2583.230, 110.916},
        {"Поле для гольфа «Йеллоу-Белл»", 1117.400, 2723.230, -89.084, 1457.460, 2863.230, 110.916},
        {"Айдлвуд", 1812.620, -1602.310, -89.084, 2124.660, -1449.670, 110.916},
        {"Западный Рэдсэндс", 1297.470, 2142.860, -89.084, 1777.390, 2243.230, 110.916},
        {"Доэрти", -2270.040, -324.114, -1.2, -1794.920, -222.589, 200.000},
        {"Ферма Хиллтоп", 967.383, -450.390, -3.0, 1176.780, -217.900, 200.000},
        {"Лас-Барранкас", -926.130, 1398.730, -3.0, -719.234, 1634.690, 200.000},
        {"Казино «Пираты в мужских штанах»", 1817.390, 1469.230, -89.084, 2027.400, 1703.230, 110.916},
        {"Сити Холл", -2867.850, 277.411, -9.1, -2593.440, 458.411, 200.000},
        {"Загородный клуб «Ависпа»", -2646.400, -355.493, 0.000, -2270.040, -222.589, 200.000},
        {"Стрип", 2027.400, 863.229, -89.084, 2087.390, 1703.230, 110.916},
        {"Хашбери", -2593.440, -222.589, -1.0, -2411.220, 54.722, 200.000},
        {"Международный аэропорт Лос-Сантос", 1852.000, -2394.330, -89.084, 2089.000, -2179.250, 110.916},
        {"Уайтвуд-Рстейтс", 1098.310, 1726.220, -89.084, 1197.390, 2243.230, 110.916},
        {"Водохранилище Шермана", -789.737, 1659.680, -89.084, -599.505, 1929.410, 110.916},
        {"Эль-Корона", 1812.620, -2179.250, -89.084, 1970.620, -1852.870, 110.916},
        {"Деловой район", -1700.010, 744.267, -6.1, -1580.010, 1176.520, 200.000},
        {"Долина Фостер", -2178.690, -1250.970, 0.000, -1794.920, -1115.580, 200.000},
        {"Лас-Паясадас", -354.332, 2580.360, 2.0, -133.625, 2816.820, 200.000},
        {"Долина Окультадо", -936.668, 2611.440, 2.0, -715.961, 2847.900, 200.000},
        {"Пересечение Блэкфилд", 1166.530, 795.010, -89.084, 1375.600, 1044.690, 110.916},
        {"Гантон", 2222.560, -1852.870, -89.084, 2632.830, -1722.330, 110.916},
        {"Международный аэропорт Рстер-Бэй", -1213.910, -730.118, 0.000, -1132.820, -50.096, 200.000},
        {"Восточный Рэдсэндс", 1817.390, 2011.830, -89.084, 2106.700, 2202.760, 110.916},
        {"Восточная Эспаланда", -1499.890, 578.396, -79.615, -1339.890, 1274.260, 20.385},
        {"Дворец Калигулы", 2087.390, 1543.230, -89.084, 2437.390, 1703.230, 110.916},
        {"Казино «Рояль»", 2087.390, 1383.230, -89.084, 2437.390, 1543.230, 110.916},
        {"Ричман", 72.648, -1235.070, -89.084, 321.356, -1008.150, 110.916},
        {"Казино «Морская звезда»", 2437.390, 1783.230, -89.084, 2685.160, 2012.180, 110.916},
        {"Малхолланд", 1281.130, -452.425, -89.084, 1641.130, -290.913, 110.916},
        {"Деловой район", -1982.320, 744.170, -6.1, -1871.720, 1274.260, 200.000},
        {"Ханки-Панки-Пойнт", 2576.920, 62.158, 0.000, 2759.250, 385.503, 200.000},
        {"Военный склад топлива К.А.С.С.", 2498.210, 2626.550, -89.084, 2749.900, 2861.550, 110.916},
        {"Автострада «Гарри-Голд»", 1777.390, 863.232, -89.084, 1817.390, 2342.830, 110.916},
        {"Тоннель Бэйсайд", -2290.190, 2548.290, -89.084, -1950.190, 2723.290, 110.916},
        {"Океанские доки", 2324.000, -2302.330, -89.084, 2703.580, -2145.100, 110.916},
        {"Ричман", 321.356, -1044.070, -89.084, 647.557, -860.619, 110.916},
        {"Промсклад имени Рэндольфа", 1558.090, 596.349, -89.084, 1823.080, 823.235, 110.916},
        {"Восточный пляж", 2632.830, -1852.870, -89.084, 2959.350, -1668.130, 110.916},
        {"Флинт-Уотер", -314.426, -753.874, -89.084, -106.339, -463.073, 110.916},
        {"Блуберри", 19.607, -404.136, 3.8, 349.607, -220.137, 200.000},
        {"Станция «Линден»", 2749.900, 1198.990, -89.084, 2923.390, 1548.990, 110.916},
        {"Глен Парк", 1812.620, -1350.720, -89.084, 2056.860, -1100.820, 110.916},
        {"Деловой район", -1993.280, 265.243, -9.1, -1794.920, 578.396, 200.000},
        {"Западный Рэдсэндс", 1377.390, 2243.230, -89.084, 1704.590, 2433.230, 110.916},
        {"Ричман", 321.356, -1235.070, -89.084, 647.522, -1044.070, 110.916},
        {"Мост «Гант»", -2741.450, 1659.680, -6.1, -2616.400, 2175.150, 200.000},
        {"Бар «Probe Inn»", -90.218, 1286.850, -3.0, 153.859, 1554.120, 200.000},
        {"Пересечение Флинт", -187.700, -1596.760, -89.084, 17.063, -1276.600, 110.916},
        {"Лас-Колинас", 2281.450, -1135.040, -89.084, 2632.740, -945.035, 110.916},
        {"Собелл-Рейл-Ярдс", 2749.900, 1548.990, -89.084, 2923.390, 1937.250, 110.916},
        {"Рзумрудный остров", 2011.940, 2202.760, -89.084, 2237.400, 2508.230, 110.916},
        {"Эль-Кастильо-дель-Дьябло", -208.570, 2123.010, -7.6, 114.033, 2337.180, 200.000},
        {"Санта-Флора", -2741.070, 458.411, -7.6, -2533.040, 793.411, 200.000},
        {"Плайя-дель-Севиль", 2703.580, -2126.900, -89.084, 2959.350, -1852.870, 110.916},
        {"Маркет", 926.922, -1577.590, -89.084, 1370.850, -1416.250, 110.916},
        {"Квинс", -2593.440, 54.722, 0.000, -2411.220, 458.411, 200.000},
        {"Пересечение Пилсон", 1098.390, 2243.230, -89.084, 1377.390, 2507.230, 110.916},
        {"Спинибед", 2121.400, 2663.170, -89.084, 2498.210, 2861.550, 110.916},
        {"Пилигрим", 2437.390, 1383.230, -89.084, 2624.400, 1783.230, 110.916},
        {"Блэкфилд", 964.391, 1403.220, -89.084, 1197.390, 1726.220, 110.916},
        {"«Большое ухо»", -410.020, 1403.340, -3.0, -137.969, 1681.230, 200.000},
        {"Диллимор", 580.794, -674.885, -9.5, 861.085, -404.790, 200.000},
        {"Эль-Кебрадос", -1645.230, 2498.520, 0.000, -1372.140, 2777.850, 200.000},
        {"Северная Эспланада", -2533.040, 1358.900, -4.5, -1996.660, 1501.210, 200.000},
        {"Международный аэропорт Рстер-Бэй", -1499.890, -50.096, -1.0, -1242.980, 249.904, 200.000},
        {"Рыбацкая лагуна", 1916.990, -233.323, -100.000, 2131.720, 13.800, 200.000},
        {"Малхолланд", 1414.070, -768.027, -89.084, 1667.610, -452.425, 110.916},
        {"Восточный пляж", 2747.740, -1498.620, -89.084, 2959.350, -1120.040, 110.916},
        {"Сан-Андреас Саунд", 2450.390, 385.503, -100.000, 2759.250, 562.349, 200.000},
        {"Тенистые ручьи", -2030.120, -2174.890, -6.1, -1820.640, -1771.660, 200.000},
        {"Маркет", 1072.660, -1416.250, -89.084, 1370.850, -1130.850, 110.916},
        {"Западный Рокшор", 1997.220, 596.349, -89.084, 2377.390, 823.228, 110.916},
        {"Прикл-Пайн", 1534.560, 2583.230, -89.084, 1848.400, 2863.230, 110.916},
        {"«Бухта Пасхи»", -1794.920, -50.096, -1.04, -1499.890, 249.904, 200.000},
        {"Лифи-Холлоу", -1166.970, -1856.030, 0.000, -815.624, -1602.070, 200.000},
        {"Грузовое депо Лас-Вентураса", 1457.390, 863.229, -89.084, 1777.400, 1143.210, 110.916},
        {"Прикл-Пайн", 1117.400, 2507.230, -89.084, 1534.560, 2723.230, 110.916},
        {"Блуберри", 104.534, -220.137, 2.3, 349.607, 152.236, 200.000},
        {"Эль-Кастильо-дель-Дьябло", -464.515, 2217.680, 0.000, -208.570, 2580.360, 200.000},
        {"Деловой район", -2078.670, 578.396, -7.6, -1499.890, 744.267, 200.000},
        {"Восточный Рокшор", 2537.390, 676.549, -89.084, 2902.350, 943.235, 110.916},
        {"Залив Сан-Фиерро", -2616.400, 1501.210, -3.0, -1996.660, 1659.680, 200.000},
        {"Парадизо", -2741.070, 793.411, -6.1, -2533.040, 1268.410, 200.000},
        {"Казино «Носок верблюда»", 2087.390, 1203.230, -89.084, 2640.400, 1383.230, 110.916},
        {"Олд-Вентурас-Стрип", 2162.390, 2012.180, -89.084, 2685.160, 2202.760, 110.916},
        {"Джанипер-Хилл", -2533.040, 578.396, -7.6, -2274.170, 968.369, 200.000},
        {"Джанипер-Холлоу", -2533.040, 968.369, -6.1, -2274.170, 1358.900, 200.000},
        {"Рока-Эскаланте", 2237.400, 2202.760, -89.084, 2536.430, 2542.550, 110.916},
        {"Восточная автострада Джулиус", 2685.160, 1055.960, -89.084, 2749.900, 2626.550, 110.916},
        {"Пляж «Верона»", 647.712, -2173.290, -89.084, 930.221, -1804.210, 110.916},
        {"Долина Фостер", -2178.690, -599.884, -1.2, -1794.920, -324.114, 200.000},
        {"Арко-дель-Оэсте", -901.129, 2221.860, 0.000, -592.090, 2571.970, 200.000},
        {"«Упавшее дерево»", -792.254, -698.555, -5.3, -452.404, -380.043, 200.000},
        {"Ферма", -1209.670, -1317.100, 114.981, -908.161, -787.391, 251.981},
        {"Дамба Шермана", -968.772, 1929.410, -3.0, -481.126, 2155.260, 200.000},
        {"Северная Эспланада", -1996.660, 1358.900, -4.5, -1524.240, 1592.510, 200.000},
        {"Финансовый район", -1871.720, 744.170, -6.1, -1701.300, 1176.420, 300.000},
        {"Гарсия", -2411.220, -222.589, -1.14, -2173.040, 265.243, 200.000},
        {"Монтгомери", 1119.510, 119.526, -3.0, 1451.400, 493.323, 200.000},
        {"Крик", 2749.900, 1937.250, -89.084, 2921.620, 2669.790, 110.916},
        {"Международный аэропорт Лос-Сантос", 1249.620, -2394.330, -89.084, 1852.000, -2179.250, 110.916},
        {"Пляж «Санта-Мария»", 72.648, -2173.290, -89.084, 342.648, -1684.650, 110.916},
        {"Пересечение Малхолланд", 1463.900, -1150.870, -89.084, 1812.620, -768.027, 110.916},
        {"Эйнджел-Пайн", -2324.940, -2584.290, -6.1, -1964.220, -2212.110, 200.000},
        {"Вёрдант-Медоус", 37.032, 2337.180, -3.0, 435.988, 2677.900, 200.000},
        {"Октан-Спрингс", 338.658, 1228.510, 0.000, 664.308, 1655.050, 200.000},
        {"Казино Кам-э-Лот", 2087.390, 943.235, -89.084, 2623.180, 1203.230, 110.916},
        {"Западный Рэдсэндс", 1236.630, 1883.110, -89.084, 1777.390, 2142.860, 110.916},
        {"Пляж «Санта-Мария»", 342.648, -2173.290, -89.084, 647.712, -1684.650, 110.916},
        {"Обсерватория «Зелёный утёс", 1249.620, -2179.250, -89.084, 1692.620, -1842.270, 110.916},
        {"Аэропорт Лас-Вентурас", 1236.630, 1203.280, -89.084, 1457.370, 1883.110, 110.916},
        {"Округ Флинт", -594.191, -1648.550, 0.000, -187.700, -1276.600, 200.000},
        {"Обсерватория «Зелёный утёс", 930.221, -2488.420, -89.084, 1249.620, -2006.780, 110.916},
        {"Паломино Крик", 2160.220, -149.004, 0.000, 2576.920, 228.322, 200.000},
        {"Океанские доки", 2373.770, -2697.090, -89.084, 2809.220, -2330.460, 110.916},
        {"Международный аэропорт Рстер-Бэй", -1213.910, -50.096, -4.5, -947.980, 578.396, 200.000},
        {"Уайтвуд-Рстейтс", 883.308, 1726.220, -89.084, 1098.310, 2507.230, 110.916},
        {"Калтон-Хайтс", -2274.170, 744.170, -6.1, -1982.320, 1358.900, 200.000},
        {"«Бухта Пасхи»", -1794.920, 249.904, -9.1, -1242.980, 578.396, 200.000},
        {"Залив Лос-Сантос", -321.744, -2224.430, -89.084, 44.615, -1724.430, 110.916},
        {"Доэрти", -2173.040, -222.589, -1.0, -1794.920, 265.243, 200.000},
        {"Гора Чилиад", -2178.690, -2189.910, -47.917, -2030.120, -1771.660, 576.083},
        {"Форт-Карсон", -376.233, 826.326, -3.0, 123.717, 1220.440, 200.000},
        {"Долина Фостер", -2178.690, -1115.580, 0.000, -1794.920, -599.884, 200.000},
        {"Оушен-Флэтс", -2994.490, -222.589, -1.0, -2593.440, 277.411, 200.000},
        {"Ферн-Ридж", 508.189, -139.259, 0.000, 1306.660, 119.526, 200.000},
        {"Бэйсайд", -2741.070, 2175.150, 0.000, -2353.170, 2722.790, 200.000},
        {"Аэропорт Лас-Вентурас", 1457.370, 1203.280, -89.084, 1777.390, 1883.110, 110.916},
        {"Поместье Блуберри", -319.676, -220.137, 0.000, 104.534, 293.324, 200.000},
        {"Пэлисейдс", -2994.490, 458.411, -6.1, -2741.070, 1339.610, 200.000},
        {"Норт-Рок", 2285.370, -768.027, 0.000, 2770.590, -269.740, 200.000},
        {"Карьер «Хантер»", 337.244, 710.840, -115.239, 860.554, 1031.710, 203.761},
        {"Международный аэропорт Лос-Сантос", 1382.730, -2730.880, -89.084, 2201.820, -2394.330, 110.916},
        {"Миссионер-Хилл", -2994.490, -811.276, 0.000, -2178.690, -430.276, 200.000},
        {"Залив Сан-Фиерро", -2616.400, 1659.680, -3.0, -1996.660, 2175.150, 200.000},
        {"Запретная Зона", -91.586, 1655.050, -50.000, 421.234, 2123.010, 250.000},
        {"Гора «Чилиад»", -2997.470, -1115.580, -47.917, -2178.690, -971.913, 576.083},
        {"Гора «Чилиад»", -2178.690, -1771.660, -47.917, -1936.120, -1250.970, 576.083},
        {"Международный аэропорт Рстер-Бэй", -1794.920, -730.118, -3.0, -1213.910, -50.096, 200.000},
        {"Паноптикум", -947.980, -304.320, -1.1, -319.676, 327.071, 200.000},
        {"Тенистые ручьи", -1820.640, -2643.680, -8.0, -1226.780, -1771.660, 200.000},
        {"Бэк-о-Бейонд", -1166.970, -2641.190, 0.000, -321.744, -1856.030, 200.000},
        {"Гора «Чилиад»", -2994.490, -2189.910, -47.917, -2178.690, -1115.580, 576.083},
        {"Тьерра Робада", -1213.910, 596.349, -242.990, -480.539, 1659.680, 900.000},
        {"Округ Флинт", -1213.910, -2892.970, -242.990, 44.615, -768.027, 900.000},
        {"Уэтстоун", -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000},
        {"Пустынный округ", -480.539, 596.349, -242.990, 869.461, 2993.870, 900.000},
        {"Тьерра Робада", -2997.470, 1659.680, -242.990, -480.539, 2993.870, 900.000},
        {"Сан Фиерро", -2997.470, -1115.580, -242.990, -1213.910, 1659.680, 900.000},
        {"Лас Вентурас", 869.461, 596.349, -242.990, 2997.060, 2993.870, 900.000},
        {"Туманный округ", -1213.910, -768.027, -242.990, 2997.060, 596.349, 900.000},
        {"Лос Сантос", 44.615, -2892.970, -242.990, 2997.060, -768.027, 900.000}
    }
    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
    return "Пригород"
end