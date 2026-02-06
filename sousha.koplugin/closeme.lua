local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local VerticalGroup = require("ui/widget/verticalgroup") -- Cambiado de Horizontal a Vertical
local VerticalSpan = require("ui/widget/verticalspan")   -- Espaciado vertical
local Button = require("ui/widget/button")               -- Nuevo componente
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local InputContainer = require("ui/widget/container/inputcontainer")
local MovableContainer = require("ui/widget/container/movablecontainer")
local Size = require("ui/size")
local _ = require("gettext")

local Screen = Device.screen

-- Heredamos de InputContainer para gestión de foco y eventos, igual que InfoMessage
local CloseMe = InputContainer:extend{
    modal = true,
    text = "",
    width = nil,
    title = nil,
    padding = Size.padding.default,
}

function CloseMe:init()
    -- 1. Inicialización de Fuentes
    if not self.face then
        self.face = Font:getFace("infofont")
    end
    
    -- Calculamos ancho: Default 2/3 de la pantalla
    local window_width = self.width or math.floor(Screen:getWidth() * 2/3)
    
    -- 2. Construcción de Widgets Internos
    
    -- Widget de Texto (Mensaje)
    local text_widget = TextBoxWidget:new{
        text = self.text,
        face = self.face,
        width = window_width - (self.padding * 2),
        alignment = "center",
    }

    -- Botón de Cierre
    -- La callback invoca UIManager:close(self) explícitamente.
    local close_button = Button:new{
        text = _("Cerrar"),
        width = window_width * 0.6, -- Botón ligeramente más estrecho que la ventana
        callback = function()
            UIManager:close(self)
        end,
        bordersize = 1,
    }

    -- 3. Layout (VerticalGroup)
    -- Apilamos: Texto -> Espacio -> Botón
    local content_group = VerticalGroup:new{
        align = "center",
        text_widget,
        VerticalSpan:new{ width = Size.span.vertical_large }, -- Espacio entre texto y botón
        close_button,
    }

    -- 4. Contenedor de Marco (FrameContainer)
    -- Dibuja el fondo blanco y los bordes redondeados
    local frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        radius = Size.radius.window,
        padding = self.padding,
        content_group, 
    }

    -- 5. Contenedor Movible (MovableContainer)
    -- Crucial: InfoMessage usa esto para exponer la propiedad .dimen correcta al UIManager
    self.movable = MovableContainer:new{
        frame,
    }

    -- 6. Contenedor de Centrado (CenterContainer)
    -- Posiciona el widget en el centro de la pantalla
    self[1] = CenterContainer:new{
        dimen = Screen:getSize(),
        self.movable,
    }
    
    -- NOTA: Se han eliminado los listeners key_events y ges_events (TapClose) 
    -- presentes en InfoMessage para evitar cierres accidentales.
end

-- Gestión de renderizado (Dirty Flags)
-- Se utiliza self.movable.dimen para obtener el rectángulo exacto de la ventana flotante

function CloseMe:onShow()
    UIManager:setDirty(self, function()
        return "ui", self.movable.dimen
    end)
    return true
end

function CloseMe:onCloseWidget()
    UIManager:setDirty(nil, function()
        return "ui", self.movable.dimen
    end)
end

function CloseMe:getVisibleArea()
    return self.movable.dimen
end

return CloseMe