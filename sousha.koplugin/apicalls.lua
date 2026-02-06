local socket = require("socket")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local ApiCalls = {}
local util = require("util")
local _ = require("gettext")
local NetworkMgr = require("ui/network/manager")
http.TIMEOUT = 3
local function rpcCommand(method, params)
    -- Construcción de URL Hardcodeada
    local url = "http://music.com:6680/mopidy/rpc"
    
    local payload = {
        jsonrpc = "2.0",
        method = method,
        params = params or {},
        id = 1
    }
    
    local request_body = json.encode(payload)
    local response_body = {}
    local response_table = {}
    -- Logger para depuración (puedes verlo en crash.log de koreader)

    NetworkMgr:turnOnWifiAndWaitForConnection()
    local res, code, response_headers = http.request{
        url = url,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = #request_body,
            ["Connection"] = "close"
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_table)
    }

    if code == 200 then
        local response_text = table.concat(response_table)
        return json.decode(response_text)
    else
        local err_msg = "Error " .. (code or "red") .. " conectando a "
        UIManager:show(InfoMessage:new{
            text = err_msg,
            timeout = 3
        })
    end
end
function ApiCalls:cambiarestado()
    local res = rpcCommand("core.playback.get_state",{})
    local estareproduciendo = res.result
    if estareproduciendo == "playing" then
        rpcCommand("core.playback.pause")
    else 
        rpcCommand("core.playback.play")
    end
end
function ApiCalls:prueba()
    UIManager:show(InfoMessage:new{
        text = "aaaaaaaaa",
        timeout = 3
    })
end
function ApiCalls:anadiracontinuacion(uri)
    local dondeva =rpcCommand("core.tracklist.index").result
    local dondeira = dondeva+1
    local param = {
        uris = {uri},
        at_position = dondeira
    }
    local res = rpcCommand("core.tracklist.add",param)
    UIManager:show(InfoMessage:new{text=_("Añadida Exitosamente?"),timeout=5})
    if res.code == 200 then
        UIManager:show(InfoMessage:new{text=_("Añadida Exitosamente"),timeout=5})
        return
    end
    UIManager.show(InfoMessage:new{text=_("Ocurrio un error"),timeout=5})

end
function ApiCalls:buscar(busqueda)
local param = {
    query = {any=busqueda}
}
local res = rpcCommand("core.library.search",param)
res = res.result[1].tracks
return res
end
function ApiCalls:buscartest(busqueda)
local param = {
    query = {any=busqueda}
}
local res = rpcCommand("core.library.search",param)
local tabladeresultados = {}
res = res.result[1].tracks
for _, i in ipairs(res) do
    table.insert(tabladeresultados,{"Título" , tostring(i.name)})
    table.insert(tabladeresultados,{"Artista-Albúm" , tostring(i.artists[1].name) .. " - " .. tostring(i.album.name)})
    table.insert(tabladeresultados,{"Reproducir a continuación","Presionar aquí",callback = function()ApiCalls:anadiracontinuacion(i.uri)end})
    table.insert(tabladeresultados,"---")
end
return tabladeresultados
end

function ApiCalls:backfrw(func)
    if func == "forw" then
        rpcCommand("core.playback.next")
        return
    end
    rpcCommand("core.playback.previous")
end
function ApiCalls:GetVol()
    local res = rpcCommand("core.mixer.get_volume")
    local vol = tonumber(res.result)
    return vol

end
function ApiCalls:SetVolume(how)
    local vol_act = tonumber(rpcCommand("core.mixer.get_volume").result)
    if how =="plus" then
        local param = {
            volume = vol_act+2
        }
        rpcCommand("core.mixer.set_volume",param)
    end
    if how =="less" then
        local param = {
            volume = vol_act-2
        }
        rpcCommand("core.mixer.set_volume",param)
    end
end
return ApiCalls

