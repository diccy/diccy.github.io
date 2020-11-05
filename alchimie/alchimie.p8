pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- main

function _init()
	next_gamestate=start_gamestate
end

function _update60()
	if next_gamestate!=game_state then
		game_state=next_gamestate
		gs[game_state].enter()
	end
	add_debug("gs", game_state)
	gs[game_state].update()
end

function _draw()
	cls()
	gs[game_state].draw()
	--debug_draw()
	debug_flush()
end


-- game states

start_gamestate=1
play_gamestate=2
gameover_gamestate=3
game_state=0
next_gamestate=0

-- start
function gs_start_enter()
	zero_score()
	pieces_init()
end

function gs_start_update()
	--if (btnp(❎)) next_gamestate=play_gamestate
	next_gamestate=play_gamestate
end

function gs_start_draw()
	layout_draw()
	pieces_draw()
end

-- play
function gs_play_enter()
	next_playstate=newnext_playstate
end

function gs_play_update()
	if next_playstate!=play_state then
		play_state=next_playstate
		ps[play_state].enter()
	end
	add_debug("ps", play_state)
	ps[play_state].update()
end

function gs_play_draw()
	layout_draw()
	pieces_draw()
end

-- game over
function gs_gameover_enter()
	save_score()
end

function gs_gameover_update()
	if (btnp(❎)) next_gamestate=start_gamestate
end

function gs_gameover_draw()
	layout_draw()
	pieces_draw()
	rectfill(32,59,88,68,1)
	rect(32-1,59-1,88,68,2)
	print("game over",42,61,8)
end

gs={
	-- start
	{
		enter=  gs_start_enter,
		update= gs_start_update,
		draw=   gs_start_draw
	},
	-- play
	{
		enter=  gs_play_enter,
		update= gs_play_update,
		draw=   gs_play_draw
	},
	-- game over
	{
		enter=  gs_gameover_enter,
		update= gs_gameover_update,
		draw=   gs_gameover_draw
	}
}

-->8
-- play states

newnext_playstate=1
nexttocurrent_playstate=2
currentcontrol_playstate=3
gridfall_playstate=4
explosion_playstate=5
play_state=0
next_playstate=0

-- new next
function ps_newnext_enter()
	npg_new()
end

function ps_newnext_update()
	foreach(npg,apply_piece_move)
	if is_piecegroup_still(npg) then
		next_playstate=nexttocurrent_playstate
	end
end

-- next to current
function ps_nexttocurrent_enter()
	cpg_set(npg)
	npg_new()
end

function ps_nexttocurrent_update()
	foreach(npg,apply_piece_move)
	foreach(cpg,apply_piece_move)
	if is_piecegroup_still(npg) and is_piecegroup_still(cpg) then
		next_playstate=currentcontrol_playstate
	end
end

-- current control
function ps_currentcontrol_enter()
end

function ps_currentcontrol_update()
	if is_piecegroup_still(cpg) then
		if (btnp(⬅️)) move_cpg(-1)
		if (btnp(➡️)) move_cpg(1)
		if (btnp(⬆️)) rotate_cpg()
		if btnp(⬇️) then
			drop_cpg_to_grid()
			next_playstate=gridfall_playstate
		end
	end
	foreach(cpg,apply_piece_move)
	grid_debug_print()
end

-- grid pieces falling
function ps_gridfall_enter()
	grid_fall_init()
end

function ps_gridfall_update()
	for p in all(grid_fallingpieces) do
		apply_piece_move(p)
		if (p.speed==nil) del(grid_fallingpieces, p)
	end
	if #grid_fallingpieces==0 then
		grid_count_score()
		next_playstate=explosion_playstate
	end
end

-- explosion
function ps_explosion_enter()
	grid_find_explosions()
end

function ps_explosion_update()
	if #grid_exp_groups>0 then
		for eg in all(grid_exp_groups) do
			eg.anchor.p+=1
			biggest_piece=max(biggest_piece,eg.anchor.p)
			for p in all(eg.pieces) do
				if p!=eg.anchor then
					grid[p.gx][p.gy]=nil
					del(grid_pieces,p)
				end
			end
		end
		grid_exp_groups={}
		next_playstate=gridfall_playstate
	else
		if is_grid_loose() then
			next_gamestate=gameover_gamestate
		else
			next_playstate=nexttocurrent_playstate
		end
	end
end

ps={
	-- new next
	{
		enter=  ps_newnext_enter,
		update= ps_newnext_update,
	},
	-- next to current
	{
		enter=  ps_nexttocurrent_enter,
		update= ps_nexttocurrent_update,
	},
	-- current control
	{
		enter=  ps_currentcontrol_enter,
		update= ps_currentcontrol_update,
	},
	-- grid pieces falling
	{
		enter=  ps_gridfall_enter,
		update= ps_gridfall_update,
	},
	-- explosion
	{
		enter=  ps_explosion_enter,
		update= ps_explosion_update,
	}
}

-->8
-- layout

-- grid
l_gx,l_gy=2,7
l_gw,l_gh=6,7
-- controlled piece group zone
l_zy=2
l_zh=l_gy-l_zy
-- next piece
l_nx,l_ny=12,3
l_nw,l_nh=2,1
-- unlocked pieces
l_ux,l_uy=12,6
-- scores
l_sx,l_sy=1,0.8
l_bsx,l_bsy=1,15

function layout_draw()
	rect(l_gx*8-2,l_gy*8,  (l_gx+l_gw)*8+1,(l_gy+l_gh)*8+1,3)
	rect(l_gx*8-2,l_zy*8-2,(l_gx+l_gw)*8+1,(l_zy+l_zh)*8,  3)
	rect(l_nx*8-2,l_ny*8-2,(l_nx+l_nw)*8+1,(l_ny+l_nh)*8+1,3)
	local p=0
	for i=1,12 do
		p=i
		if (p>biggest_piece) p+=16
		spr(p,(l_ux+((i+1)%2))*8+(i+1)%2,l_uy*8+i*4.5)
	end
	print_score("score",current_score,l_sx*8,l_sy*8,12)
	print_score("best",best_score,l_bsx*8,l_bsy*8,9)
end

-->8
-- piece

function pieces_init()
	npg_init()
	cpg_init()
	grid_init()
end

function pieces_draw()
	npg_draw()
	cpg_draw()
	grid_draw()
end

function new_piece()
	return {
		-- mandatory
		x=0,y=0, -- screen position
		p=flr(rnd(biggest_piece))+1, -- piece type
		-- facultative
		--dx=0,dy=0, -- destination position (screen)
		--gx=0,gy=0, -- grid position
		--speed=0 -- move speed
	}
end

function new_piecegroup(n)
	local pg={}
	for i=1,n do
		add(pg,new_piece())
	end
	return pg
end

function is_piecegroup_still(pg)
	for p in all(pg) do
		if (not is_piece_still(p)) return false
	end
	return true
end

function is_piece_still(p)
	return p.speed==nil
end

function apply_piece_move(p)
	if p.dx!=nil then
		local d=p.dx-p.x
		if abs(d)<=p.speed then
			p.x=p.dx
			p.dx=nil
		else
			p.x+=sgn(d)*p.speed
		end
	end
	if p.dy!=nil then
		local d=p.dy-p.y
		if abs(d)<=p.speed then
			p.y=p.dy
			p.dy=nil
		else
			p.y+=sgn(d)*p.speed
		end
	end
	if p.dx==nil and p.dy==nil then
		p.speed=nil
	end
end

function draw_piece(p)
	spr(p.p,p.x,p.y)
end

function draw_piecegroup(pg)
	foreach(pg, draw_piece)
end

-->8
-- pieces groups

-- new pieces group

npg=nil

function npg_init()
	npg=nil
end

function npg_draw()
	if (npg!=nil) draw_piecegroup(npg)
end

function npg_new()
	npg=new_piecegroup(2)
	npg[1].x,npg[1].y=l_nx*8,    l_ny*8
	npg[2].x,npg[2].y=(l_nx+1)*8,l_ny*8
end

-- current pieces group

cpg=nil
last_cpg_gx=0

function cpg_init()
	cpg=nil
	last_cpg_gx=flr(l_gw/2)
end

function cpg_draw()
	if (cpg!=nil) draw_piecegroup(cpg)
end

function cpg_set(pg)
	cpg=pg
	cpg[1].gx,cpg[1].gy=last_cpg_gx,l_gy+3
	cpg[2].gx,cpg[2].gy=last_cpg_gx+1,l_gy+3
	keep_cpg_in_zone()
	for p in all(cpg) do
		p.dx,p.dy=from_grid_coord(p.gx,p.gy)
		p.speed=20
	end
end

function move_cpg(n)
	for p in all(cpg) do
		p.gx+=n
	end
	keep_cpg_in_zone()
	for p in all(cpg) do
		p.dx,p.dy=from_grid_coord(p.gx,p.gy)
		p.speed=1
	end
end

function rotate_cpg()
	if #cpg==2 then
		if cpg[1].gy==cpg[2].gy then
			-- horizontal to vertical
			cpg[1].gy+=1
			cpg[2].gx-=1
		else
			-- vertical to horizontal
			cpg[1].gx+=1
			cpg[1].gy-=1
			local tmp=cpg[1]
			cpg[1]=cpg[2]
			cpg[2]=tmp
		end
	end
	keep_cpg_in_zone()
	for p in all(cpg) do
		p.dx,p.dy=from_grid_coord(p.gx,p.gy)
		p.speed=2
	end
end

function keep_cpg_in_zone()
	local offset=0
	for p in all(cpg) do
		local off=mid(p.gx,1,l_gw)-p.gx
		if (abs(off)>abs(offset)) offset=off
	end
	if offset!=0 then
		for p in all(cpg) do
			p.gx+=offset
		end
	end
end

function drop_cpg_to_grid()
	last_cpg_gx=cpg[1].gx
	add_to_grid(cpg)
	cpg=nil
end

-->8
-- grid

grid_pieces={} -- pieces list
grid_fallingpieces={} -- list
grid_exp_groups={} -- list
grid={} -- 2d array
biggest_piece=0

function grid_init()
	biggest_piece=4
	grid_pieces={}
	grid_fallingpieces={}
	grid_exp_groups={}
	grid={}
	for i=0,l_gw do
		add(grid,{})
	end
end

function grid_draw()
	foreach(grid_pieces, draw_piece)
end

-- grid zero as bottom left
function to_grid_coord(x,y)
	return flr(x/8)-l_gx+1,flr((l_gy+l_gh*8)-y)/8
end
function from_grid_coord(gx,gy)
	return (gx+l_gx-1)*8,(l_gy+l_gh-gy)*8
end

function add_to_grid(pieces)
	for p in all(pieces) do
		add(grid_pieces,p)
		grid[p.gx][p.gy]=p
	end
end

function grid_debug_print()
	for x=1,l_gw do
		for y=1,l_gy+l_gh do
			p=grid[x][y]
			if p!=nil then
				add_debug("["..x.."]["..y.."]",p.p)
			end
		end
	end
end

function grid_fall_init()
	grid_fallingpieces={}
	local p=nil
	local empty=nil
	for x=1,l_gw do
		empty=nil
		for y=1,l_gy+l_gh do
			p=grid[x][y]
			if p==nil then
				if (empty==nil) empty=y
			elseif empty!=nil then
				p.gy=empty
				p.dx,p.dy=from_grid_coord(p.gx,p.gy)
				p.speed=5
				grid[x][empty]=p
				add(grid_fallingpieces,p)
				grid[x][y]=nil
				empty+=1
			end
		end
	end
end

function is_grid_loose()
	for x=1,l_gw do
		if grid[x][l_gy+1]!=nil then
			return true
		end
	end
	return false
end

function grid_count_score()
	zero_score()
	for p in all(grid_pieces) do
		add_score(3^p.p)
	end
end

function grid_find_explosions()
	grid_exp_groups={}
	local grid_exp_set={}
	for p in all(grid_pieces) do
		if grid_exp_set[p]==nil then
			if grid_similar_neighbours_count(p) >= 2 then
				local eg=create_exp_group(grid_similar_set(p))
				for e in all(eg.pieces) do
					grid_exp_set[e]=true
				end
				add(grid_exp_groups,eg)
			end
		end
	end
end

function grid_similar_neighbours_count(p)
	local scnt=0
	local gx,gy=p.gx,p.gy
	local pp=p.p
	local n
	if gx-1>=1 then
		n=grid[gx-1][gy]
		if (n!=nil and n.p==pp) scnt+=1
	end
	if gy-1>=1 then
		n=grid[gx][gy-1]
		if (n!=nil and n.p==pp) scnt+=1
	end
	if gx+1<=l_gw then
		n=grid[gx+1][gy]
		if (n!=nil and n.p==pp) scnt+=1
	end
	if gy+1<=l_gy+l_gh then
		n=grid[gx][gy+1]
		if (n!=nil and n.p==pp) scnt+=1
	end
	return scnt
end

function grid_similar_set(p)
	local similar_set={}
	local function rec(piece)
		local gx,gy=piece.gx,piece.gy
		local pp=piece.p
		local function check_neighbour(n)
			if n!=nil and n.p==pp and similar_set[n]==nil then
				similar_set[n]=n
				rec(n)
			end
		end
		if gx-1>=1 then
			check_neighbour(grid[gx-1][gy])
		end
		if gy-1>=1 then
			check_neighbour(grid[gx][gy-1])
		end
		if gx+1<=l_gw then
			check_neighbour(grid[gx+1][gy])
		end
		if gy+1<=l_gy+l_gh then
			check_neighbour(grid[gx][gy+1])
		end
	end
	rec(p)
	return similar_set
end

function create_exp_group(pieces_set)
	local eg={
		pieces={}, -- list
		anchor=nil
	}
	for _,p in pairs(pieces_set) do
		add(eg.pieces,p)
	end
	local a=eg.pieces[1]
	for i=2,#eg.pieces do
		p=eg.pieces[i]
		if p.gy<a.gy or (p.gy==a.gy and p.gx<a.gx) then
			a=p
		end
	end
	eg.anchor=a
	return eg
end


-->8
-- score

-- mega + kilo + units
current_score={m=0,k=0,u=0}
best_score={m=0,k=0,u=0}

function zero_score()
	current_score={m=0,k=0,u=0}
end

function save_score()
	if current_score.m<best_score.m then
		return
	elseif current_score.m==best_score.m then
		if current_score.k<best_score.k then
			return
		elseif current_score.k==best_score.k then
			if current_score.u<best_score.u then
				return
			end
		end
	end
	best_score=current_score
end

function add_score(n)
	current_score.u+=n
	if current_score.u>=1000 then
		local r=current_score.u%1000
		local a=current_score.u-r
		current_score.u=r
		current_score.k+=flr(a/1000)
		if current_score.k>=1000 then
			r=current_score.k%1000
			a=current_score.k-r
			current_score.k=r
			current_score.m+=flr(a/1000)
		end
	end
end

function print_score(title,score,x,y,c)
	print(title,x,y,7)
	x+=24
	local prev=false -- has print previous number
	local function _print_3_digits(n,x,y)
		if (n>0 or prev) then
			print(flr(n/100),x,y,c)
			print(flr(n/10)%10,x+4,y,c)
			print(n%10,x+8,y,c)
			prev=true
		end
	end
	_print_3_digits(score.m,x,y)
	_print_3_digits(score.k,x+13,y)
	prev=true
	_print_3_digits(score.u,x+26,y)
end


-->8
-- debug

persistent_debug_data={}
debug_data={}

function add_debug(title,data)
	add(debug_data,{t=title,d=data})
end

function add_pdebug(title,data)
	add(persistent_debug_data,{t=title,d=data})
end

function debug_flush()
	debug_data={}
end

function debug_draw()
	local function _print_debug(data,x,y)
		for a in all(data) do
			print(a.t..":",x,y)
			print(a.d,x+(#a.t+1)*4,y)
			y+=6
		end
	end
	color(8)
	_print_debug(persistent_debug_data,0,0)
	color(7)
	_print_debug(debug_data,64,0)
	debug_flush()
end

__gfx__
00000000007777000077770000777700007777000000000300666600000000ff00eee0000004400000c000000000000000999900000000000000000000000000
0000000006bbbb7006aaaa700644447006cccc70000003b30622766000000fff00eeee000045a4000cc00000000bb000049a4aa0000000000000000000000000
007007006bbb7bb76aaa7aa7644474476ccc7cc700033b33d221266600000ff5222aa2ee04544a40cc00ccc0003b7b0049999aa0000000000000000000000000
000770006bbbb7b76aaaa7a7644447476cccc7c7003bb33bd21126660000ff50229aaaee4545a4a4ccccc7cc03bbbb30499449aa000000000000000000000000
000770006bbbbbb76aaaaaa7644444476cccccc703b333bbd222666600ff55002299aaee54544949c1cccccc5dd33dd54499aa99000000000000000000000000
0070070063bbbbb769aaaaa76244444761ccccc7033bbbb0ddddd666fff5000002e9aeee55459494dc1222cc55dddd554444949a000000000000000000000000
000000000633336006999960062222600611116033bbb0000dddddd055f000000222ee0055544944ddc11ccc0155555004499990000000000000000000000000
00000000006666000066660000666600006666003000000000dddd000550000000222200055544400dddddc00011110000444400000000000000000000000000
000000000000000000000000000000000000000000000005006666000000006600777000000dd000006000000000000000666600000000000000000000000000
00000000000000000000000000000000000000000000056506557660000006660077770000d57d00066000000006600005675770000000000000000000000000
000000000000000000000000000000000000000000055655d551566600000665555665770d5dd7d06600666000d6760056666770000000000000000000000000
000000000000000000000000000000000000000000566556d51156660000665055666677d5d57d7d666667660d6666d056655677000000000000000000000000
000000000000000000000000000000000000000005655566d555666600665500556666775d5dd6d6666556665dddddd555667766000000000000000000000000
000000000000000000000000000000000000000005566660ddddd666666500000576677755d56d6dd655555655dddd5555556567000000000000000000000000
0000000000000000000000000000000000000000556660000dddddd05560000005557700555dd6dddd6556660555555005566660000000000000000000000000
00000000000000000000000000000000000000005000000000dddd0005500000005555000555ddd00ddddd600055550000555500000000000000000000000000
