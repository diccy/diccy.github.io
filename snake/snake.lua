-- title:   Cypo snake
-- author:  Cypo, djobi
-- desc:    badger badger badger badger oh snaaaaaaake
-- site:    -
-- license: -
-- version: 0.1
-- script:  lua


---------- Constants --------------------------------------

-- Lua
local t_insert = table.insert
local m_floor = math.floor
local m_ceil  = math.ceil
local m_abs   = math.abs
local m_min   = math.min
local m_max   = math.max
local m_fmod  = math.fmod
local m_cos   = math.cos
local m_sin   = math.sin
local m_atan2 = math.atan2
local m_sqrt  = math.sqrt
local m_rand  = math.random
local m_srand = math.randomseed
local m_log   = math.log
local m_log10 = math.log10

local function m_sign(n) -- included in newer lua versions
	return n < 0 and -1 or (n > 0 and 1 or 0)
end
local function m_clamp(min, n, max) -- included in newer lua versions
	return n < min and min or (n > max and max or n)
end

-- Math
local PI    = math.pi
local PIx2  = PI * 2.0
local PI_2  = PI / 2.0
local PI_4  = PI / 4.0
local PI_16 = PI / 16.0
local SQRT2 = m_sqrt(2.0)

--local function DiffAngle(r1, r2)
--	local d = r2 - r1
--	return (m_abs(d) < PI and d or (d - PIx2))
--end

local function Lerp(a, b, t)
    return a + t * (b - a)
end

local function IntersectPointSegment1D(a, b, p)
	local pa, pb = p - a, p - b
	if (m_abs(pa) < m_abs(pb)) then
		return pa > 0.0, pa
	else
		return pb < 0.0, pb
	end
end

-- Context
local BLACK_COLOR = 0
local SW, SH = 240, 136 -- screen size, pix
local SW_2, SH_2 = SW / 2, SH / 2 -- half screen size, pix
local DT = 1.0 / 60.0 -- sec-1

local function PrintShadowed(txt, x, y, c)
	print(txt, x + 1, y + 1, BLACK_COLOR)
	return print(txt, x, y, c)
end

-- Controls
local K_UP    = 58
local K_DOWN  = 59
local K_LEFT  = 60
local K_RIGHT = 61


---------- Debug ------------------------------------------

local DEBUG_KEY_TOGGLE = 7 -- [G]
local d_doPrintDebug = false
local d_persistentDebugTextData = {}
local d_debugTextData = {}

local function AddDebugText(title, data)
	if d_doPrintDebug then
		t_insert(d_debugTextData, { t = title, d = data })
	end
end

local function AddDebugTextP(title, data)
	t_insert(d_persistentDebugTextData, { t = title, d = data })
end

local function DebugTextFlush()
	d_debugTextData = {}
end

local function DebugTextDraw()
	local function _PrintDebug(data, x, y, c)
		local w = nil
		for _, v in pairs(data) do
			w = PrintShadowed(v.t .. ":", x, y, c)
			PrintShadowed(v.d, x + w, y, c)
			y = y + 6
		end
	end
	_PrintDebug(d_persistentDebugTextData, 0, 0, 12)
	_PrintDebug(d_debugTextData, 64, 0, 12)
	DebugTextFlush()
end


---------- Game vars --------------------------------------

-- Common
local RND_COUNT = 1000
local RND = {}

-- Snake head (sh)
local sh_size -- pix

local sh_x, sh_y -- pix
local sh_r -- radians, [-PI,PI] cw, 0 -> right
local sh_max_speed -- pix/sec
local sh_speed_x, sh_speed_y -- pix/sec
local sh_speed -- pix/sec

local SNAKE_CONTROLS = { Snake_ControlDir, Snake_ControlRotate }
local snake_control_i

-- Snake tail
local st_length -- length of all tail tables
local st_size
local st_color
local st_x, st_y
local st_goal_x, st_goal_y

-- Camera
local cam_box_w_2, cam_box_h_2 -- pix
local cam_target_x, cam_target_y -- pix

-- Environment
local env_spr_ids

---------- Game functions ---------------------------------

-- Common
local function Common_Init()
	local p, pp, ppp = PI, PI*PI, PI*PI*PI
	RND = {}
	for i=1, RND_COUNT do
		RND[i] = (m_sin(i*p) + m_sin(i*pp) + m_sin(i*ppp)) / 3.0
	end
end

-- Snake
local function Snake_Init()
	sh_x, sh_y = 0.0, 0.0
	sh_r = 0.0
	sh_size = 3.0
	sh_max_speed = 60.0
	sh_speed_x, sh_speed_y = 0.0, 0.0

	snake_control_i = 1

	st_length = 40 + m_rand(40)
	st_size = {}
	st_color = {}
	st_x, st_y = {}, {}
	st_goal_x, st_goal_y = {}, {}
	for i=1, st_length do
		st_size[i] = 1 + m_rand(4)
		st_color[i] = 2 + m_rand(4)
		st_x[i], st_y[i] = 0.0, 0.0
		st_goal_x[i], st_goal_y[i] = 0.0, 0.0
	end
end

-- Snake controls
local function IsUpPressed()
	return key(K_UP)
end
local function IsDownPressed()
	return key(K_DOWN)
end
local function IsLeftPressed()
	return key(K_LEFT)
end
local function IsRightPressed()
	return key(K_RIGHT)
end

local function Snake_ApplySpeedAndRot()
	sh_speed = m_sqrt(sh_speed_x * sh_speed_x + sh_speed_y * sh_speed_y)
	sh_x = sh_x + sh_speed_x * DT
	sh_y = sh_y + sh_speed_y * DT
end

local function Snake_ControlDir()
	-- left goes to left, right goes to right,
	-- relative to screen
	local up = IsUpPressed() and 1.0 or 0.0
	local down = IsDownPressed() and 1.0 or 0.0
	local left = IsLeftPressed() and 1.0 or 0.0
	local right = IsRightPressed() and 1.0 or 0.0
	local forward = down - up
	local side = right - left
	if (forward ~= 0.0 or side ~= 0.0) then
		if (forward ~= 0.0 and side ~= 0.0) then
			forward = forward / SQRT2
			side = side / SQRT2
		end
		sh_speed_x = side * sh_max_speed
		sh_speed_y = forward * sh_max_speed
	else
		sh_speed_x, sh_speed_y = 0.0, 0.0
	end
	Snake_ApplySpeedAndRot()
end

local function Snake_ControlRotate()
	-- left apply a rotation to the left of the head,
	-- relative to forward direction
	Snake_ApplySpeedAndRot()
end

local function Snake_UpdateTail()
	-- update goals
	if (sh_speed > 0.01) then
		local px, py, ps = sh_x, sh_y, sh_size
		for i=1, st_length do
			local x, y, s = st_x[i], st_y[i], st_size[i]
			local dx, dy, ss = px-x, py-y, ps+s
			local sqdist = dx*dx + dy*dy
			if (sqdist > ss*ss) then
				st_goal_x[i], st_goal_y[i] = px, py
			end
			dx, dy = st_goal_x[i]-x, st_goal_y[i]-y
			local dist = m_sqrt(dx*dx + dy*dy)
			if (dist > 0.01) then
				dx = (dx / dist) * sh_speed * DT
				dy = (dy / dist) * sh_speed * DT
				st_x[i], st_y[i] = x + dx, y + dy
			end
			px, py, ps = x, y, s
		end
	end
	AddDebugText("st_x", st_x[1])
	AddDebugText("st_y", st_y[1])
end

local function Snake_Update()
	Snake_ControlDir()
	Snake_UpdateTail()
end

local SH_COLOR = 7
local function Snake_Draw()
	local cam_offset_x = SW_2 - cam_target_x
	local cam_offset_y = SH_2 - cam_target_y
	local x, y
	
	for i=st_length, 1, -1 do
		x = st_x[i] + cam_offset_x
		y = st_y[i] + cam_offset_y
		circ(x, y, st_size[i], st_color[i])
	end

	x = sh_x + cam_offset_x
	y = sh_y + cam_offset_y
	circ(x, y, sh_size, SH_COLOR)
end

local function Snake_Draw_Debug()
end


-- Camera
local function Camera_Init()
	cam_box_w_2 = m_max(SW_2 / 3.0, 8)
	cam_box_h_2 = m_max(SH_2 - (SW_2 - cam_box_w_2), 8)
	cam_target_x, cam_target_y = sh_x, sh_y
end

local function Camera_Update()
	local sh_rel_cam_x = sh_x - cam_target_x
	local sh_rel_cam_y = sh_y - cam_target_y

	local inside, offset = IntersectPointSegment1D(-cam_box_w_2, cam_box_w_2, sh_rel_cam_x)
	if (not inside) then
		cam_target_x = Lerp(cam_target_x, cam_target_x + offset, 0.2)
	end
	inside, offset = IntersectPointSegment1D(-cam_box_h_2, cam_box_h_2, sh_rel_cam_y)
	if (not inside) then
		cam_target_y = Lerp(cam_target_y, cam_target_y + offset, 0.2)
	end
end

local function Camera_Draw_Debug()
	rectb(SW_2 - cam_box_w_2, SH_2 - cam_box_h_2, cam_box_w_2 + cam_box_w_2, cam_box_h_2 + cam_box_h_2, 11)
end


-- Environment
local ENV_SPRITE_FIRST = 0
local ENV_SPRITE_COUNT = 4
local ENV_SPRITE_SIZE = 1 * 8
local ENV_W, ENV_H = (SW / ENV_SPRITE_SIZE) + 1, (SH / ENV_SPRITE_SIZE) + 1

local function Env_Init()
end

local function Env_Update()
end

local function Env_Draw()
	local seed = m_floor(cam_target_x / ENV_SPRITE_SIZE) + m_floor(cam_target_y / ENV_SPRITE_SIZE) * ENV_W
	local offset_x, offset_y = -(cam_target_x % ENV_SPRITE_SIZE), -(cam_target_y % ENV_SPRITE_SIZE)
	local iy, rnd, sprite, flip, rot
	for y=0, ENV_H do
		iy = y * ENV_W
		for x=0, ENV_W do
			sprite = ENV_SPRITE_FIRST + m_abs(m_floor(RND[(x + iy + seed) % RND_COUNT + 1] * ENV_SPRITE_COUNT))
			flip = m_abs(m_floor(RND[(x + iy + seed + 40) % RND_COUNT + 1] * 4))
			rot = m_abs(m_floor(RND[(x + iy + seed + 80) % RND_COUNT + 1] * 4))
			spr(sprite, x * ENV_SPRITE_SIZE + offset_x, y * ENV_SPRITE_SIZE + offset_y, -1, 1, flip, rot)
		end
	end
end

-- UI
local function UI_Init()
end

local function UI_Update()
end

local function UI_Draw()
	local y = 0
	PrintShadowed("Fleches pour bouger", 0, y, 9); y = y + 6
	PrintShadowed("[T] pour grandir", 0, y, 9); y = y + 6
	PrintShadowed("[G] pour debug", 0, y, 9); y = y + 6
end



---------- Main -------------------------------------------

local function Init()
	Common_Init()
	Snake_Init()
	Camera_Init()
	Env_Init()
	UI_Init()
end

local function Update()
	-- temp --
	if keyp(20) then -- [T]
		st_length = st_length + 1
		st_size[st_length] = 1 + m_rand(4)
		st_color[st_length] = 2 + m_rand(4)
		st_x[st_length] = st_x[st_length - 1]
		st_y[st_length] = st_y[st_length - 1]
		st_goal_x[st_length] = st_goal_x[st_length - 1]
		st_goal_y[st_length] = st_goal_y[st_length - 1]
	end
	----------
	Snake_Update()
	Camera_Update()
	Env_Update()
	UI_Update()
end

local function Draw()
	cls(1)
	Env_Draw()
	Snake_Draw()
	UI_Draw()
end

local function Draw_Debug()
	Camera_Draw_Debug()
	Snake_Draw_Debug()
	DebugTextDraw()
end


---------- TIC --------------------------------------------

m_srand(time())
Init()
function TIC()
	if keyp(DEBUG_KEY_TOGGLE) then
		d_doPrintDebug = not d_doPrintDebug
	end
	Update()
	Draw()
	if d_doPrintDebug then
		Draw_Debug()
	end
end


---------- ! DON'T EDIT BELOW ! ---------------------------

-- <TILES>
-- 000:1111111111111111111111111111111111111111111111111111111111111111
-- 001:111111111111111f1111111111111121111f1111111111111111111111111f11
-- 002:1111111111111111111111f11111f11111111111112111111111111111111111
-- 003:111111111211111111111111111f111111111111111112111121111111111111
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

