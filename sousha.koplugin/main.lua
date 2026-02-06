local Device = require("device")
local LuaSettings = require("luasettings")
local Input = Device.Input
local Screen = require("device").screen
local UIManager = require("ui/uimanager")
local DataStorage = require("datastorage")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local ScrollableContainer = require("ui/widget/container/scrollablecontainer")
local Geom = require("ui/geometry")
local KeyValuePage = require("ui/widget/keyvaluepage")
local TitleBar = require("ui/widget/titlebar")
local Button = require("ui/widget/button")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local VerticalSpan = require("ui/widget/verticalspan")
local LineWidget = require("ui/widget/linewidget")
local Size = require("ui/size")
local Blitbuffer = require("ffi/blitbuffer")
local ConfirmBox = require("ui/widget/confirmbox")
local InfoMessage = require("ui/widget/infomessage")
local TextWidget = require("ui/widget/textwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local MultiInputDialog = require("ui/widget/multiinputdialog")
local CheckButton = require("ui/widget/checkbutton")
local Font = require("ui/font")
local InputDialog = require("ui/widget/inputdialog")
local VerticalGroup = require("ui/widget/verticalgroup")
local FrameContainer = require("ui/widget/container/framecontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local _ = require("gettext")
local json = require("json")
local http = require("socket.http")
local util = require("util")
local NetworkMgr = require("ui/network/manager")
local ApiCalls = require("apicalls")
local ffiutil = require("ffi/util")
local T = ffiutil.template
local CloseMe = require("volumen")

local Sousha = WidgetContainer:new{
    name = "sousha",
    settings_file  =DataStorage:getSettingsDir().."/sousha.lua",
    settings = nil,
    default_ip = "music.com",
    default_port = "6680",
    composer = nil,
    kv = {}
}

function Sousha:onDispatcherRegisterActions()
    --
end

function Sousha:init()
    self:onDispatcherRegisterActions()
    self.api = ApiCalls
    self.ui.menu:registerToMainMenu(self)
end

function Sousha:loadSettings()
    if self.settings then
        return
    end
    self.settings = LuaSettings:open(self.settings_file)
    self.default_ip = "music.com"
    self.default_port = "6680"
end

function Sousha:addToMainMenu(menu_items)
    menu_items.sousha = {
        sorting_hint = "search",
        text = _("Sousha"),
        sub_item_table_func = function()
            return self:getSubMenuItems()
        end,
    }
end
function Sousha:getSubMenuItems()
    self:loadSettings()
    self.whenDoneFunc = nil
    local sub_item_table
    sub_item_table = {
        {text = _("Pausa/Reproducir"),
        callback = function()
            self.api:cambiarestado()
    end},
    {text = _("Siguiente Canción"),
        callback = function()
            self.api:backfrw("forw")
    end},
    {text = _("Canción Anterior"),
        callback = function()
            self.api:backfrw("a")
    end},
    {
        text = _("Prueba"),
        callback = function()
            local instancia = CloseMe:new{}
            UIManager:show(instancia)
    end
    },
    {
        text = _("Buscar Canción"),
        keep_menu_open = true,
        callback = function(touchmenu_instance)
            local busqueda
            local input
            input = InputDialog:new{
                title = _("Búsqueda"),
                input = busqueda,
                input_hint = _("Nombre,Artista o albúm"),
                input_type = "string",
                description = _(""),
                buttons = {
                    {
                        {
                            text = _("Realizar Búsqueda"),
                            callback = function()
                                self.busqueda=input:getInputValue()
                                local res = ApiCalls.buscartest(self,self.busqueda)
                                self.swh = KeyValuePage:new{kv_pairs=
                                    res
                                }
                                UIManager:close(input)
                                UIManager:show(self.swh)
                            end
                        },
                        {
                            text = _("Cancelar"),
                            callback = function()
                                UIManager:close(input)
                            end
                        }

                    
                    }
                }
                
            }
            UIManager:show(input)
            input:onShowKeyboard()


        end
    }
    }
     return sub_item_table
end


return Sousha