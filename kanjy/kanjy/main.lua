-- main kanjy module

-- Utils

local t_insert = table.insert
local m_floor = math.floor
local m_ceil = math.ceil
local m_abs = math.abs
local m_min = math.min
local m_max = math.max
local m_fmod = math.fmod
local m_cos = math.cos
local m_sin = math.sin
local function m_sign(n)
	return n < 0 and -1 or (n > 0 and 1 or 0)
end
local PI = math.pi


-- Debug

local doPrintDebug = true
local persistentDebugTextData = {}
local debugTextData = {}

local function AddDebugText(title, data)
	t_insert(debugTextData, { t = title, d = data })
end

local function AddDebugTextP(title, data)
	t_insert(persistentDebugTextData, { t = title, d = data })
end

local function DebugTextFlush()
	debugTextData = {}
end

local function DebugTextDraw()
	local function _PrintDebug(data, x, y, c)
		for _, v in pairs(data) do
			local str = v.t .. ":"
			local w = print(v.t .. ":", x + 1, y + 1, 15)
			print(v.d, x + w + 1, y + 1, 15)
			print(v.t .. ":", x, y, c)
			print(v.d, x + w, y, c)
			y = y + 6
		end
	end
	_PrintDebug(persistentDebugTextData, 0, 0, 12)
	_PrintDebug(debugTextData, 64, 0, 12)
	DebugTextFlush()
end


-- Constants

local PIx2 = PI * 2.0
local PI_2 = PI / 2.0
local PI_4 = PI / 4.0
local PI_16 = PI / 16.0
local SW = 240 -- screen width
local SH = 136 -- screen height
local DT = 1.0 / 60.0 -- delta time


-- Variables

local t = 0.0 -- elapsed time


-- Game constants

local G_X = 0
local G_W = 136
local G_Y = 0
local G_H = 136
local G_FLOOR_Y = 127

local function DebugGameContantsDraw()
    rectb(G_X, G_Y, G_W, G_H, 2)
    line(G_X, G_FLOOR_Y, G_X + G_W - 1, G_FLOOR_Y, 2)
end


-- Kanjy

local kj_x = 0.0
local kj_y = 0.0
local KJ_SPR_OFFSET_X = -4
local KJ_SPR_OFFSET_Y = -16

local function DrawKanjy()
    spr(256, kj_x + KJ_SPR_OFFSET_X, kj_y + KJ_SPR_OFFSET_Y, 0, 1, 0, 0, 1, 2)
end


-- Score

-- Main module

local main = {}

function main.Init()
    kj_x = G_X + (G_H / 2)
    kj_y = G_FLOOR_Y
end

function main.Update()
    
end

function main.Draw()
    cls(6)
    map()
    DrawKanjy()
    if doPrintDebug then
        DebugGameContantsDraw()
        DebugTextDraw()
    end
end

return main
