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
	--add_debug("gs", game_state)
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
	score_init()
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
	--add_debug("ps", play_state)
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
	fillp(0) -- solid
	rectfill(32,59,88,68,1)
	rect(32-1,59-1,88,68,2)
	print("game over",42,61,8)
	rectfill(32,99,88,108,1)
	rect(32-1,99-1,88,108,3)
	print("press [x]",42,101,6)
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
	foreach(npg,apply_move)
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
	foreach(npg,apply_move)
	foreach(cpg,apply_move)
	if is_piecegroup_still(npg) and is_piecegroup_still(cpg) then
		next_playstate=currentcontrol_playstate
	end
end

-- current control
function ps_currentcontrol_enter()
end

function ps_currentcontrol_update()
	if is_piecegroup_still(cpg) then
		if (btn(⬅️)) move_cpg(-1)
		if (btn(➡️)) move_cpg(1)
		if (btn(⬆️)) rotate_cpg()
		if btn(⬇️) then
			drop_cpg_to_grid()
			next_playstate=gridfall_playstate
		end
	end
	foreach(cpg,apply_move)
	--grid_debug_print()
end

-- grid pieces falling
function ps_gridfall_enter()
	grid_fall_init()
end

function ps_gridfall_update()
	for p in all(grid_fallingpieces) do
		apply_move(p)
		if (p.speed==nil) del(grid_fallingpieces, p)
	end
	if #grid_fallingpieces==0 then
		grid_count_score()
		next_playstate=explosion_playstate
	end
end

-- explosion
function ps_explosion_enter()
	explosion_init()
	grid_find_explosions()
end

function ps_explosion_update()
	if #grid_exp_groups>0 then
		explosion_update()
		if #grid_exp_groups==0 then
			next_playstate=gridfall_playstate
		end
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
		if (p>biggest_piece) p+=12
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
	explosion_draw()
end

function new_piece()
	return {
		-- mandatory
		x=0,y=0, -- screen position
		p=min(flr(rnd(biggest_piece))+1,last_piece-1), -- piece type
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

function apply_move(p)
	-- applies speed on x,y to dx,dy
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
		p.speed=1
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
grid={} -- 2d array
biggest_piece=0
last_piece=12

function grid_init()
	biggest_piece=4
	grid_pieces={}
	grid_fallingpieces={}
	grid={}
	for i=0,l_gw do
		add(grid,{})
	end
	explosion_init()
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
		add_piece_score(p)
	end
end

function grid_find_explosions()
	grid_exp_groups={}
	local exp_pieces_set={}
	for p in all(grid_pieces) do
		if p.p < last_piece then
			if exp_pieces_set[p]==nil then
				if grid_similar_neighbours_count(p) >= 2 then
					local similar_pieces=grid_get_similar(p)
					for s in all(similar_pieces) do
						exp_pieces_set[s]=true
					end
					add(grid_exp_groups,create_exp_group(similar_pieces))
				end
			end
		end
	end
	if #grid_exp_groups>0 then
		add_pdebug("expg",#grid_exp_groups)
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

function grid_get_similar(p)
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
	local similar={} -- convert set to list
	for _,p in pairs(similar_set) do
		add(similar,p)
	end
	return similar
end

-->8
-- explosion

grid_exp_groups={} -- list
growth_expstate=1
move_expstate=2
expanim_expstate=3
expanim_start=32
expanim_end=42

function explosion_init()
	grid_exp_groups={}
end

function explosion_update()
	for eg in all(grid_exp_groups) do
		local finished=false
		for ex in all(eg.ex) do
			if ex.state==growth_expstate then
				apply_radius_growth(ex)
				if ex.rspeed==nil then
					if ex.p!=eg.anchor then
						grid[ex.p.gx][ex.p.gy]=nil
						del(grid_pieces,ex.p)
						ex.p=nil
					end
					ex.r,ex.dr=7,1
					ex.rspeed=0.5
					ex.state=move_expstate
				end
			elseif ex.state==move_expstate then
				apply_move(ex)
				apply_radius_growth(ex)
				if ex.speed==nil and ex.rspeed==nil then
					if ex.p!=eg.anchor then
						del(eg.ex,ex)
					else
						eg.anchor.p+=1
						ex.sa=expanim_start
						ex.state=expanim_expstate
					end
				end
			elseif ex.state==expanim_expstate then
				ex.sa+=ex.aspeed
				if flr(ex.sa)>expanim_end then
					finished=true
				end
			end
		end
		if finished then
			biggest_piece=max(eg.anchor.p,biggest_piece)
			del(grid_exp_groups,eg)
		end
	end
end

function explosion_draw()
	fillp(0) -- solid
	for eg in all(grid_exp_groups) do
		for ex in all(eg.ex) do
			if ex.sa==nil then
				circfill(ex.x,ex.y,ex.r,7)
			else
				local sa=flr(ex.sa)
				sa-=sa%2
				spr(sa,ex.x-8,ex.y-8,2,2,ex.fx)
			end
		end
	end
end

function new_exp_elem(p,dx,dy)
	return {
		p=p,
		x=p.x+4,y=p.y+4,
		dx=dx+4,dy=dy+4,
		speed=1,
		r=1,dr=7,
		rspeed=0.5,
		sa=nil, -- sprite anim
		fx=rnd({true,false}), -- flip
		aspeed=0.8,
		state=growth_expstate
	}
end

function create_exp_group(pieces)
	local eg={
		anchor=nil,
		ex={}
	}
	local a=pieces[1]
	for i=2,#pieces do
		local p=pieces[i]
		if p.gy<a.gy or (p.gy==a.gy and p.gx<a.gx) then
			a=p
		end
	end
	eg.anchor=a
	for p in all(pieces) do
		add(eg.ex,new_exp_elem(p,a.x,a.y))
	end
	return eg
end

function apply_radius_growth(p)
	-- applies rspeed on r to dr
	if p.dr!=nil then
		local d=p.dr-p.r
		if abs(d)<=p.rspeed then
			p.r=p.dr
			p.dr=nil
			p.rspeed=nil
		else
			p.r+=sgn(d)*p.rspeed
		end
	end
end

-->8
-- score

-- mega + kilo + units
function new_score(m,k,u)
	return {m=m,k=k,u=u}
end

piece_values={
	-- powers of 3
	new_score(0,0,3),
	new_score(0,0,9),
	new_score(0,0,27),
	new_score(0,0,81),
	new_score(0,0,243),
	new_score(0,0,729),
	new_score(0,2,187),
	new_score(0,6,561),
	new_score(0,19,683),
	new_score(0,59,049),
	new_score(0,177,147),
	new_score(0,531,441)
}
current_score=new_score(0,0,0)
best_score=new_score(0,0,0)

function score_init()
	zero_score()
end

function zero_score()
	current_score=new_score(0,0,0)
end

function score_compare(s1,s2)
	if s1.m!=s2.m then
		return s1.m-s2.m
	elseif s1.k!=s2.k then
		return s1.k-s2.k
	elseif s1.u!=s2.u then
		return s1.u-s2.u
	else
		return 0
	end
end

function score_add(s1,s2)
	local r=0
	local a=s1.u+s2.u
	s1.u=a%1000
	r=flr(a/1000)
	a=s1.k+s2.k+r
	s1.k=a%1000
	r=flr(a/1000)
	a=s1.m+s2.m+r
	s1.m=a%1000
end

function save_score()
	if score_compare(best_score,current_score)<0 then
		best_score=current_score
	end
end

function add_piece_score(p)
	score_add(current_score,piece_values[p.p])
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
00000000007777000077770000777700007777000000000300666600000000ff00eee0000004400000c000000000000000999900007777000077770000777700
0000000006bbbb7006aaaa700644447006cccc70000003b30622766000000fff00eeee000045a4000cc00000000bb000049a4aa006dddd7006dddd7006dddd70
007007006bbb7bb76aaa7aa7644474476ccc7cc700033b33d221266600000ff5222aa2ee04544a40cc00ccc0003b7b0049999aa06ddd7dd76ddd7dd76ddd7dd7
000770006bbbb7b76aaaa7a7644447476cccc7c7003bb33bd21126660000ff50229aaaee4545a4a4ccccc7cc03bbbb30499449aa6dddd7d76dddd7d76dddd7d7
000770006bbbbbb76aaaaaa7644444476cccccc703b333bbd222666600ff55002299aaee54544949c1cccccc5dd33dd54499aa996dddddd76dddddd76dddddd7
0070070063bbbbb769aaaaa76244444761ccccc7033bbbb0ddddd666fff5000002e9aeee55459494dc1222cc55dddd554444949a65ddddd765ddddd765ddddd7
000000000633336006999960062222600611116033bbb0000dddddd055f000000222ee0055544944ddc11ccc0155555004499990065555600655556006555560
00000000006666000066660000666600006666003000000000dddd000550000000222200055544400dddddc00011110000444400006666000066660000666600
0077770000000005006666000000006600777000000dd00000600000000000000066660000000000000000000000000000000000000000000000000000000000
06dddd700000056506557660000006660077770000d57d0006600000000660000567577000000000000000000000000000000000000000000000000000000000
6ddd7dd700055655d551566600000665555665770d5dd7d06600666000d676005666677000000000000000000000000000000000000000000000000000000000
6dddd7d700566556d51156660000665055666677d5d57d7d666667660d6666d05665567700000000000000000000000000000000000000000000000000000000
6dddddd705655566d555666600665500556666775d5dd6d6666556665dddddd55566776600000000000000000000000000000000000000000000000000000000
65ddddd705566660ddddd666666500000576677755d56d6dd655555655dddd555555656700000000000000000000000000000000000000000000000000000000
06555560556660000dddddd05560000005557700555dd6dddd655666055555500556666000000000000000000000000000000000000000000000000000000000
006666005000000000dddd0005500000005555000555ddd00ddddd60005555000055550000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000070009aa00e000000a000000000000000e00000000000000000000000000000000
000000000000000000000000000000000000000000077770000007777770000709000000000009a000000000000000e000000000000000000000000000000000
00000000000000000000000000000000000007777777777000007eeee00700700900000000000e00000000000000000000000000000000000000000000000000
00000011110000000000000000770000000077777777777000079e00000a77009000000000000000000000000000000000000000000000000000000000000000
00001111111100000000007777770000000777999977770000799000007777009000000000000000000000000000000000000000000000000000000000000000
000011111111000000000777e7770000007779e00777770007990000070000709000000000000000000000000000000000000000000000000000000000000000
000111111111100000007777777700000077ae077777770007900000000000000000000000000000000000000000000000000000000000000000000000000000
000111111111100000007a7777e700000077a777777a77000790000000000a000000000000000000000000000000000000000000000000000000000000000000
000111111111100000007a777777000000777777770a770007900000000000700000000000000000000000000000000000000000000000000000000000000000
0001111111111000000077777777000000777777700a770007900000000eea700000000000000000000000000000000000000000000000000000000000000000
0000111111110000000077799970000000777777ee977700070007000000aa70a000000000000000000000000000000000000000000000000000000000000000
0000111111110000000077777700000007777799997770000000770000eaa7000000000000000000000000000000000000000000000000000000000000000000
000000111100000000000000000000000777777777770000000770000eaa7000000e000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000007777777777000000077700aaaa700000090000000000009000000000000000000000000000000000000000000000000
00000000000000000000000000000000077700000000000000700777777000000aa00000000000000e0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000007700000000000000a00000a00000e900e00000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000770077007707770777000000000000000000c000ccc0ccc00ccc0ccc0ccc00000000000000000000000000000000000000000000000000000000000
000000007000700070707070700000000000000000000c00000c0c0c0000c0c0c000c00000000000000000000000000000000000000000000000000000000000
000000007770700070707700770000000000000000000ccc00cc0c0c0000c0ccc00cc00000000000000000000000000000000000000000000000000000000000
000000000070700070707070700000000000000000000c0c000c0c0c0000c0c0c000c00000000000000000000000000000000000000000000000000000000000
000000007700077077007070777000000000000000000ccc0ccc0ccc0000c0ccc0ccc00000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000333333333333333333333333333333333333333333333333333300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000003333333333333333333300000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000003000000000000000000300000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000300004400000eee0000300000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000300045a40000eeee000300000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000003004544a40222aa2ee0300000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000304545a4a4229aaaee0300000000000000
000000000000003000000000000000000000000000000000000000000000000003000000000000000000000000000030545449492299aaee0300000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000305545949402e9aeee0300000000000000
000000000000003000000000000000000000000000000000000000000000000003000000000000000000000000000030555449440222ee000300000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000003005554440002222000300000000000000
00000000000000300000000000000000000000030077770000000000000000000300000000000000000000000000003000000000000000000300000000000000
00000000000000300000000000000000000003b306cccc7000000000000000000300000000000000000000000000003333333333333333333300000000000000
0000000000000030000000000000000000033b336ccc7cc700000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000003bb33b6cccc7c700000000000000000300000000000000000000000000000000000000000000000000000000000000
0000000000000030000000000000000003b333bb6cccccc700000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000033bbbb061ccccc700000000000000000300000000000000000000000000000000000000000000000000000000000000
0000000000000030000000000000000033bbb0000611116000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000300000000066660000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000777700000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000006bbbb70000000000000000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000006bbb7bb7000000000000000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000006bbbb7b7000000000000000000000000
0000000000000033333333333333333333333333333333333333333333333333330000000000000000000000000000006bbbbbb7000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000063bbbbb7000777700000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000006333360006aaaa70000000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000000066660006aaa7aa7000000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000000000000006aaaa7a7000000000000000
0000000000000030000000000000000000000000000000000000000000000000030000000000000000000000000000000077770006aaaaaa7000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000006444470069aaaaa7000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000064447447006999960000000000000000
000000000000003000000000000000ff000000000000000000000003000000000300000000000000000000000000000064444747000666600000000000000000
00000000000000300000000000000fff0000000000000000000003b3000000000300000000000000000000000000000064444447000000000000000000000000
00000000000000300000000000000ff5000000000000000000033b33000000000300000000000000000000000000000062444447000777700000000000000000
0000000000000030000000000000ff500000000000000000003bb33b000000000300000000000000000000000000000006222260006cccc70000000000000000
00000000000000300000000000ff5500000000000000000003b333bb00000000030000000000000000000000000000000066660006ccc7cc7000000000000000
000000000000003000000000fff500000000000000000000033bbbb000000000030000000000000000000000000000000000000006cccc7c7000000000000000
00000000000000300000000055f00000000000000000000033bbb00000000000030000000000000000000000000000000000000306cccccc7000000000000000
000000000000003000000000055000000000000000000000300000000000000003000000000000000000000000000000000003b3061ccccc7000000000000000
00000000000000300000000000777700000000030000000000c00000000000000300000000000000000000000000000000033b33006111160000000000000000
00000000000000300000000006aaaa70000003b3000000000cc000000000000003000000000000000000000000000000003bb33b000666600000000000000000
0000000000000030000000006aaa7aa700033b3300000000cc00ccc0000000000300000000000000000000000000000003b333bb000000000000000000000000
0000000000000030000000006aaaa7a7003bb33b00000000ccccc7cc0000000003000000000000000000000000000000033bbbb0000666600000000000000000
0000000000000030000000006aaaaaa703b333bb00000000c1cccccc000000000300000000000000000000000000000033bbb000006227660000000000000000
00000000000000300000000069aaaaa7033bbbb000000000dc1222cc0000000003000000000000000000000000000000300000000d2212666000000000000000
0000000000000030000000000699996033bbb00000000000ddc11ccc0000000003000000000000000000000000000000000000000d2112666000000000000000
0000000000000030000000000066660030000000000000000dddddc00000000003000000000000000000000000000000000000ff0d2226666000000000000000
000000000000003000000000007777000000000300000000000000ff00c000000300000000000000000000000000000000000fff0ddddd666000000000000000
0000000000000030000bb00006444470000003b30000000000000fff0cc000000300000000000000000000000000000000000ff500dddddd0000000000000000
0000000000000030003b7b006444744700033b330000000000000ff5cc00ccc0030000000000000000000000000000000000ff50000dddd00000000000000000
000000000000003003bbbb3064444747003bb33b000000000000ff50ccccc7cc0300000000000000000000000000000000ff5500000000000000000000000000
00000000000000305dd33dd56444444703b333bb0000000000ff5500c1cccccc03000000000000000000000000000000fff50000000eee000000000000000000
000000000000003055dddd5562444447033bbbb000000000fff50000dc1222cc0300000000000000000000000000000055f00000000eeee00000000000000000
0000000000000030015555500622226033bbb0000000000055f00000ddc11ccc03000000000000000000000000000000055000000222aa2ee000000000000000
000000000000003000111100006666003000000000000000055000000dddddc003000000000000000000000000000000000000000229aaaee000000000000000
0000000000000030000000000066660000eee000000000000066660000c00000030000000000000000000000000000000004400002299aaee000000000000000
0000000000000030000bb0000622766000eeee0000000000062276600cc00000030000000000000000000000000000000045a400002e9aeee000000000000000
0000000000000030003b7b00d2212666222aa2ee00000000d2212666cc00ccc00300000000000000000000000000000004544a4000222ee00000000000000000
000000000000003003bbbb30d2112666229aaaee00000000d2112666ccccc7cc030000000000000000000000000000004545a4a4000222200000000000000000
00000000000000305dd33dd5d22266662299aaee00000000d2226666c1cccccc0300000000000000000000000000000054544949000000000000000000000000
000000000000003055dddd55ddddd66602e9aeee00000000ddddd666dc1222cc0300000000000000000000000000000055459494000c00000000000000000000
0000000000000030015555500dddddd00222ee00000000000dddddd0ddc11ccc030000000000000000000000000000005554494400cc00000000000000000000
00000000000000300011110000dddd00002222000000000000dddd000dddddc003000000000000000000000000000000055544400cc00ccc0000000000000000
000000000000003000eee000000440000004400000eee00000777700000000ff03000000000000000000000000000000000000000ccccc7cc000000000000000
000000000000003000eeee000045a4000045a40000eeee0006cccc7000000fff03000000000000000000000000000000000000000c1cccccc000000000000000
0000000000000030222aa2ee04544a4004544a40222aa2ee6ccc7cc700000ff503000000000000000000000000000000000bb0000dc1222cc000000000000000
0000000000000030229aaaee4545a4a44545a4a4229aaaee6cccc7c70000ff5003000000000000000000000000000000003b7b000ddc11ccc000000000000000
00000000000000302299aaee54544949545449492299aaee6cccccc700ff55000300000000000000000000000000000003bbbb3000dddddc0000000000000000
000000000000003002e9aeee554594945545949402e9aeee61ccccc7fff50000030000000000000000000000000000005dd33dd5000000000000000000000000
00000000000000300222ee0055544944555449440222ee000611116055f000000300000000000000000000000000000055dddd55000666600000000000000000
00000000000000300022220005554440055544400022220000666600055000000300000000000000000000000000000001555550005675770000000000000000
00000000000000300004400000666600000000ff000000ff0077770000eee0000300000000000000000000000000000000111100056666770000000000000000
00000000000000300045a4000622766000000fff00000fff06cccc7000eeee000300000000000000000000000000000000000000056655677000000000000000
000000000000003004544a40d221266600000ff500000ff56ccc7cc7222aa2ee0300000000000000000000000000000000000000055667766000000000000000
00000000000000304545a4a4d21126660000ff500000ff506cccc7c7229aaaee0300000000000000000000000000000000000000055556567000000000000000
000000000000003054544949d222666600ff550000ff55006cccccc72299aaee0300000000000000000000000000000000000000005566660000000000000000
000000000000003055459494ddddd666fff50000fff5000061ccccc702e9aeee0300000000000000000000000000000000000000000555500000000000000000
0000000000000030555449440dddddd055f0000055f00000061111600222ee000300000000000000000000000000000000000000000000000000000000000000
00000000000000300555444000dddd00055000000550000000666600002222000300000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000
00000000000000333333333333333333333333333333333333333333333333333300000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777077700770777000000000999099909900099909990900009990909099900000000000000000000000000000000000000000000000000000000000
00000000707070007000070000000000909090900900000909090900009090909000900000000000000000000000000000000000000000000000000000000000
00000000770077007770070000000000909090900900009909990999009990999009900000000000000000000000000000000000000000000000000000000000
00000000707070000070070000000000909090900900000909090909009090009000900000000000000000000000000000000000000000000000000000000000
00000000777077707700070000000000999099909990099909990999009990009099900000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
