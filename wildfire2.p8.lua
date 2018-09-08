pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--wildfire
--by @dollarone
--originally made for the 171st onehourgamejam.com
--then extended for lowrezjam 2018

--flags: 
--0: blocked
--1: water
--2: fire
--3: rock/earth
--4: is dude
--5: ignitable
--6: animate!  +1 for odd numbers (lol) -1 for even
--7: fire that spreads


-- test out api call
-- display items
-- pick up items
-- make the player temporary on main grid for a-star (or something else)

-- map is underlying, item is for movables
-- better.
-- level edit

function printo(str,startx,starty,col,col_bg)
	print(str,startx+1,starty,col_bg)
	print(str,startx-1,starty,col_bg)
	print(str,startx,starty+1,col_bg)
	print(str,startx,starty-1,col_bg)
	print(str,startx+1,starty-1,col_bg)
	print(str,startx-1,starty-1,col_bg)
	print(str,startx-1,starty+1,col_bg)
	print(str,startx+1,starty+1,col_bg)
	print(str,startx,starty,col)
end

--print string centered with 
--outline.
function printc(
	str,x,y,
	col,col_bg,
	special_chars)

	local len=(#str*4)+(special_chars*3)
	local startx=x-(len/2)
	local starty=y-2
	printo(str,startx,starty,col,col_bg)
end

function menu()

	finished=true
	main_menu=true
	levelselected=1
	gamestarted=false
	reset()
end
function _init()
	poke(0x5f2c,3)
	intro_init()
	palt(14,true)
	palt(0,false)

	wallid=0
--	start = getspecialtile(11)
	menuitem(1, "restart level", reset)
	menuitem(2, "back to menu", menu)
 	levels = {}
 	add(levels,"water") --most obvious
 	add(levels,"rock") --obvious2
 	add(levels,"fire") --sometimes you may need to think outside the bodx
 	--add(levels,"wind") -- you can spread the fire with wind
 	add(levels,"car") 
  	add(levels,"log")
 	add(levels,"barrel")
 	levelselected=1
 	finished=false
	main_menu=true
	gamestarted=false
	modeselected=1
	modes={}
	add(modes,"tutorial")
	add(modes,"challenges")
	add(modes,"create level")

	createstep=1
	createsteps={}
	add(createsteps,"edit")
	add(createsteps,"play")
	add(createsteps,"name")
	add(createsteps,"author")
	add(createsteps,"code")
	add(createsteps,"save")
	player = {}

	sprites = {}
	add(sprites,32)
	add(sprites,35)
	add(sprites,61)
	add(sprites,24)
	add(sprites,25)
	add(sprites,27)
	add(sprites,29)
	add(sprites,40)
	add(sprites,11)
	add(sprites,68)
	add(sprites,160)
	add(sprites,224)
	add(sprites,54)
	add(sprites,60)
	add(sprites,55)
	add(sprites,56)
	add(sprites,180)
	add(sprites,58)
	add(sprites,59)
	add(sprites,16)
	add(sprites,17)
	add(sprites,51)
	add(sprites,52)
 	reset()
 	no_edit=true
 	dudes=0
 	houses=0

 	chars="abcdefghijklmnopqrstuvwxyz0123456789.! "
 	name={}
 	secret={}
 	author={}
 	for i=1,8 do
 		name[i]=1
 		secret[i]=1
 		author[i]=1
 	end
 	levelname="aaaaaaaa"
 	levelcode="aaaa"
 	levelauthor="aaaaaaaa"
 	levelwon=false
	onehouse=false
	onedude=false
	unsaved=true
end

function reset()

	if modeselected>3 then

		modeselected=3
	end
	
	player.selectedsprite=1
	player.sprite = 98
	player.x = 4
	player.y = 2
	step=0
	player.cargo=116
	winnar=false
	gameover=false
	blasts={}
	restart=0
	calc_sol=false
	path_step=0
	sol_path=nil
	solution=false
	status = {}
	status["level"] = ""
	status["house"] = ""
	status["dude"] = ""
	dudes_tile=11
	under_dude_tile=63
	under_dude_tile_x=-1
	under_dude_tile_y=-1
	under_log_tile=105
	under_log_tile_x=-1
	under_log_tile_y=-1
	under_barrel_tile=122
	under_barrel_tile_x=-1
	under_barrel_tile_y=-1
	cartop_tile=64
	under_cartop_tile=122
	under_cartop_tile_x=-1
	under_cartop_tile_y=-1
	spread_done=false
	level_offset_x=0
	level_offset_y=0
	introscreen=false
	introscreen_text={}
	line=1

	-- level create stuff
	selectedinput=1
	inputsize=4
	code = {}
	for i=0,8 do
		code[i] = 1
	end

	if gamestarted then
		introscreen=true
		no_edit=false
		if modeselected==3 then
			if createsteps[createstep]=="play" then
				add(introscreen_text,"")
				level_offset_x=0
				level_offset_y=0
				player.sprite=98
				modeselected=4
			elseif createsteps[createstep]=="name" then
				add(introscreen_text,"give your")
				add(introscreen_text,"level a name:")
				add(introscreen_text,"")
				level_offset_x=0
				level_offset_y=0
				player.sprite=34
				modeselected=3
				inputsize=8
				player.y = 3
			elseif createsteps[createstep]=="author" then
				add(introscreen_text,"give yourself")
				add(introscreen_text,"a name:")
				add(introscreen_text,"")
				level_offset_x=0
				level_offset_y=0
				player.sprite=34
				modeselected=3
				inputsize=8
				player.y = 3
			elseif createsteps[createstep]=="code" then
				add(introscreen_text,"enter a code for")
				add(introscreen_text,"future updates:")
				add(introscreen_text,"")
				level_offset_x=0
				level_offset_y=0
				player.sprite=34
				modeselected=3
				inputsize=4
				player.y = 3
			elseif createsteps[createstep]=="save" then
				add(introscreen_text,"")
				level_offset_x=0
				level_offset_y=0
				player.sprite=34
				modeselected=3
				inputsize=0
				player.x=9

			elseif createsteps[createstep]=="edit" then
				level_offset_x=0
				level_offset_y=0
				add(introscreen_text,"press \x97 to ")
				add(introscreen_text,"cycle through")
				add(introscreen_text,"the tiles,")
				add(introscreen_text,"and \x8e to ")
				add(introscreen_text,"place one.")
				add(introscreen_text,"")
				add(introscreen_text,"press enter")
				add(introscreen_text,"and save when")
				add(introscreen_text,"you are done.")
				add(introscreen_text,"")
				player.sprite=66
				dudes=0
				houses=0
				levelselected=1
			end
		elseif modeselected==1 then
			if levelselected==1 then
				level_offset_x=0
				level_offset_y=9
				add(introscreen_text,"hi!")
				add(introscreen_text,"welcome to")
				add(introscreen_text,"wildfire!")
				add(introscreen_text,"use the elements")
				add(introscreen_text,"to get mr.bernt")
				add(introscreen_text,"to his cabin")
				add(introscreen_text,"...alive!")
				add(introscreen_text,"also don't let")
				add(introscreen_text,"his cabin burn!")
				add(introscreen_text,"")
				add(introscreen_text,"press \x8b\x91\x94\x83    ")
				add(introscreen_text,"to move, \x8e to ")
				add(introscreen_text,"grab or release,")
				add(introscreen_text,"and \x97 to do")
				add(introscreen_text,"nothing.")
				add(introscreen_text,"each press is")
				add(introscreen_text,"a turn and ")
				add(introscreen_text,"any wildfire")
				add(introscreen_text,"will spread!")
				add(introscreen_text,"")
				add(introscreen_text,"in this first")
				add(introscreen_text,"level, use")
				add(introscreen_text,"the water")
				add(introscreen_text,"to quench")
				add(introscreen_text,"the wildfire.")
				add(introscreen_text,"")
				add(introscreen_text,"good luck!")
				add(introscreen_text,"")

			elseif levelselected==2 then
				level_offset_x=9
				level_offset_y=9
				add(introscreen_text,"what do you")
				add(introscreen_text,"when there's")
				add(introscreen_text,"no water?")
				add(introscreen_text,"")
				add(introscreen_text,"put a rock")
				add(introscreen_text,"on it!")
				add(introscreen_text,"")

			elseif levelselected==3 then
				level_offset_x=0
				level_offset_y=18
				add(introscreen_text,"oops!")
				add(introscreen_text,"looks like")
				add(introscreen_text,"the forest")
				add(introscreen_text,"has expanded")
				add(introscreen_text,"since mr.bernt's")
				add(introscreen_text,"last visit")
				add(introscreen_text,"to the cabin.")
				add(introscreen_text,"")
				add(introscreen_text,"maybe you")
				add(introscreen_text,"can start")
				add(introscreen_text,"a fire?")
				add(introscreen_text,"")

			elseif levelselected==4 then
				level_offset_x=36
				level_offset_y=0
				add(introscreen_text,"ah, the path")
				add(introscreen_text,"is clear!")
				add(introscreen_text,"")
				add(introscreen_text,"that car is")
				add(introscreen_text,"parked a bit")
				add(introscreen_text,"close to the")
				add(introscreen_text,"forest though...")
				add(introscreen_text,"")

			elseif levelselected==5 then
				level_offset_x=18
				level_offset_y=0			
				add(introscreen_text,"sometimes")
				add(introscreen_text,"you need to")
				add(introscreen_text,"clear the path.")
				add(introscreen_text,"")
				add(introscreen_text,"you can grab")
				add(introscreen_text,"small objects")
				add(introscreen_text,"with your")
				add(introscreen_text,"helicopter arm!")
				add(introscreen_text,"")
				
			elseif levelselected==6 then
				level_offset_x=27
				level_offset_y=0			
				add(introscreen_text,"cars and barrels")
				add(introscreen_text,"explode when")
				add(introscreen_text,"ignited. ")
				add(introscreen_text,"")
				add(introscreen_text,"you can use")
				add(introscreen_text,"this in extreme")
				add(introscreen_text,"situations when")
				add(introscreen_text,"you need to")
				add(introscreen_text,"blow up a rock!")
				add(introscreen_text,"")
			end
		end

		for x=0,7 do
			for y=0,7 do
				val=mget(x+level_offset_x,y+level_offset_y)
				
				if(val==164) then
					mset(x,y,105)
					mset(x+9,y,164)
				elseif(val==240) then
					mset(x,y,122)
					mset(x+9,y,240)
				elseif(val==11) then
					mset(x,y,61)
					mset(x+9,y,11)
				else
					mset(x,y,val)
					mset(x+9,y,34)
				end				
			end
		end
		if modeselected==3 then
			for i=1,8 do
				if createsteps[createstep]=="name" then
					code[i]=name[i]
				elseif createsteps[createstep]=="author" then
					code[i]=author[i]
				elseif createsteps[createstep]=="code" then
					code[i]=secret[i]
				end
			end
		end

	end
	dude_tile=11

	goal = getspecialtile(40)
end


--not used:
function has_value(tab,val)
	for index,value in pairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

function update_input_wheel()
		
	if btnp(0) then
		selectedinput-=1
		if selectedinput==0 then
			selectedinput = inputsize
		end
	elseif btnp(1) then
		selectedinput+=1
		if selectedinput>inputsize then
			selectedinput=1
		end
	elseif btnp(2) then
		spin_input_wheel(-1)
	elseif btnp(3) then
		spin_input_wheel(1)
	end
end

function spin_input_wheel(dir)
	cur=code[selectedinput]
	cur+=dir
	if cur<1 then
		cur=#chars
	end
	if cur>#chars then
		cur=1
	end
	code[selectedinput]=cur

	if createsteps[createstep]=="name" then
		name[selectedinput]=cur
	 	levelname=""
	 	for i=1,8 do
	 		levelname=levelname .. sub(chars, name[i], name[i])
	 	end
	elseif createsteps[createstep]=="author" then
		author[selectedinput]=cur
	 	levelauthor=""
	 	for i=1,8 do
	 		levelauthor=levelauthor .. sub(chars,author[i],author[i])
	 	end
	elseif createsteps[createstep]=="code" then
		secret[selectedinput]=cur
	 	levelcode=""
	 	for i=1,4 do
	 		levelcode=levelcode .. sub(chars,secret[i],secret[i])
	 	end
	end
	unsaved=true
end

function draw_input_wheel()
	for x=0,7 do
		for y=2,4 do
			spr(199, x*8, y*8+5)
		end
	end
	startx = 128
	for i=1,inputsize do
		print(sub(chars,code[i],code[i]), startx/inputsize + i*8 - 16-6, 30, 8)
		if (i==selectedinput) then
			spr(218, startx/inputsize + i*8 - 18-6, 28)
			spr(202, startx/inputsize + i*8 - 18-6, 36)
		else
			spr(217, startx/inputsize + i*8 - 18-6, 28)
			spr(201, startx/inputsize + i*8 - 18-6, 36)
		end
	end
	spr(200, startx/inputsize - 18-6, 28)
end


function check_save_level()
	-- was it played?
	-- does it have a name? author? code?
	if levelname=="aaaaaaaa" then
		return false
	end
	if levelauthor=="aaaaaaaa" then 
		return false
	end
	if levelcode=="aaaa" then
		return false
	end
	if not levelwon then
		return false
	end
	return true 
end

function draw_save_level()
	-- was it play4ed?
	-- does it have a name? author? code?
	if not check_save_level() then
		printc("the level needs:",32,4,8,0,0)
		printc("before it can",32,51,8,0,0)
		printc("be saved!",32,59,8,0,0)
	end		
	if levelname=="aaaaaaaa" then
		printc("* a name",32,14,8,0,0)
	end
	if levelauthor=="aaaaaaaa" then
		printc("* an author",32,22,8,0,0)
	end
	if levelcode=="aaaa" then
		printc("* a code",32,30,8,0,0)
	end
	if not levelwon then
		printc("* to be won",32,38,8,0,0)
	end
end

function introscreen_update()
	if (step%120==0 or btnp(4)) then
		line+=1
	end
	if line>#introscreen_text+3 or btnp(5) then
		introscreen=false
	end
end

function introscreen_draw()
	--spr(under_log_tile, under_log_tile_x*8, under_log_tile_y*8)
	--spr(under_barrel_tile, under_barrel_tile_x*8, under_barrel_tile_y*8)
	map(0,0,0,0,8,8)
	map(9,0,0,0,8,8)
	if modeselected==3 then
		printc("create a level",32,4,8,0,0)
	elseif modeselected==4 then
		printc("play your level",32,4,8,0,0)
	else
		printc(levelselected .. ". " .. levels[levelselected],32,4,8,0,0)
	end
	if line>4 and line-4<#introscreen_text then
		printc(introscreen_text[max(1,line-4)],32,15,9,0,0)
	end
	if line>3 and line-3<#introscreen_text then
		printc(introscreen_text[max(1,line-3)],32,25,9,0,0)
	end
	if line>2 and line-2<#introscreen_text then
		printc(introscreen_text[max(1,line-2)],32,35,9,0,0)
	end
	if line>1 and line-1<#introscreen_text then
		printc(introscreen_text[max(1,line-1)],32,45,9,0,0)
	end
	if line<#introscreen_text then
		printc(introscreen_text[line],32,55,9,0,0)
	end
end

function main_menu_update()

	if btnp(0) and modeselected>1 then
		modeselected-=1
	elseif btnp(1) and modeselected<#modes then
		modeselected+=1
	end

	if btnp(4) or btnp(5) then
		main_menu=false
		gamestarted=true
		reset()
	end

	if modeselected==1 then
		if btnp(2) and levelselected>1 then
			levelselected-=1
		elseif btnp(3) and levelselected<#levels then
			levelselected+=1
		end
	elseif modeselected==3 then
		if btnp(2) and createstep>1 then
			createstep-=1
		elseif btnp(3) and createstep<#createsteps then
			createstep+=1
		end
	end
end

function main_menu_draw()
	map(0,0,0,0,8,8)
	map(9,0,0,0,8,8)
	      
	printc(modes[modeselected],32,20,8,0,0)
	if modeselected==1 then

		printo(levelselected .. ". " .. levels[levelselected],16,30,10,0)
		if #levels>=levelselected+1 then
			printo(levelselected+1 .. ". " .. levels[levelselected+1],16,38,9,0)
		end
		if #levels>=levelselected+2 then
			printo(levelselected+2 .. ". " .. levels[levelselected+2],16,46,9,0)
		end
		if #levels>=levelselected+3 then
			printo(levelselected+3 .. ". " .. levels[levelselected+3],16,54,9,0)
		end
	elseif modeselected==3 then

		printo(createstep .. ". " .. createsteps[createstep],16,30,10,0)
		if #createsteps>=createstep+1 then
			printo(createstep+1 .. ". " .. createsteps[createstep+1],16,38,9,0)
		end
		if #createsteps>=createstep+2 then
			printo(createstep+2 .. ". " .. createsteps[createstep+2],16,46,9,0)
		end
		if #createsteps>=createstep+3 then
			printo(createstep+3 .. ". " .. createsteps[createstep+3],16,54,9,0)
		end
	end

	if (no_edit) then
		if step%16==0 then
			mset(9,0,28)
			mset(10,7,12)
		elseif step%16==8 then
			mset(9,0,27)
			mset(10,7,11)
		end
	end


	backg=3	

	step2=flr(step/6)
	if step<60 then
	    pal(2,backg)
	    pal(4,backg)
	    pal(8,backg)
	    pal(9,backg)
	    pal(10,backg)	
	elseif step2%11==0 or step2%11==10 then
	    pal(2,backg)
	    pal(4,backg)
	    pal(8,backg)
	    pal(9,backg)
	    pal(10,backg)
	elseif step2%11==1 or step2%11==9 then
	    pal(2,backg)
	    pal(8,9)
	    pal(4,8)
	    pal(9,backg)
	    pal(10,backg)
	elseif step2%11==2 or step2%11==8 then
	    pal(2,backg)
	    pal(8,9)
	    pal(4,8)
	    pal(9,10)
	    pal(10,backg)
	elseif step2%11==3 or step2%11==7 then
	    pal(10,backg)
	    pal(2,10)
	    pal(4,9)
	elseif step2%11==4 or step2%11==6  then
	    pal(2,9)
	    pal(8,9)
	    pal(4,8)
	else
	    pal(2,10)
	    pal(4,8)
	end
    spr(192,12,5,5,1)

    pal(2,2)
    pal(4,4)
    pal(8,8)
    pal(9,9)
    pal(10,10)
end

function create_level_update()
	if step%8==0 then
		if player.sprite==66 then
			player.sprite=67
		elseif player.sprite==67 then
			player.sprite=66
		end
	end

	if createsteps[createstep]=="name" or 
		createsteps[createstep]=="author" or
		createsteps[createstep]=="code" then
		update_input_wheel()
		if btnp(4) or btnp(5) then
			main_menu=true
		end
		return
	end
	if createsteps[createstep]=="save" then
		if check_save_level() and unsaved then
			unsaved=false
			for x=0,7 do
				for y=0,7 do
					poke(0x5f80 + y*8 + x, mget(x,y))
				end
			end
			for i=0,7 do
				poke(0x5f80 + i, author[i])
			end


			return
		else
			if btnp(4) or btnp(5) then
				main_menu=true
			end
			return
		end
	end 

	if btnp(0) and player.x>0 then
		player.x-=1
	elseif btnp(1) and player.x<7 then
		player.x+=1
	elseif btnp(2) and player.y>0 then
		player.y-=1
	elseif btnp(3) and player.y<7 then
		player.y+=1
	end

	if btnp(4) then
		levelwon=false
		unsaved=true
		mset(player.x,player.y,sprites[player.selectedsprite])
		dudes=0
		houses=0
		for x=0,7 do
			for y=0,7 do
				val=mget(x,y)
				if val==nil then
-- shouldnt happen
				elseif val==11 then
					dudes+=1
				elseif val==40 then
					houses+=1
				end
			end
		end

	elseif btnp(5) then
		player.selectedsprite+=1
		if player.selectedsprite>#sprites then
			player.selectedsprite=1
		end
	end
end

function create_level_draw()
	cls(3)
	map(0,0,0,0,8,8)
	spr(sprites[player.selectedsprite],player.x*8,player.y*8)
	spr(player.sprite,player.x*8,player.y*8)

	if (dudes>1) then
		printc("please, no more", 32, 4,10,0,0)
		printc("than one dude", 32, 14,10,0,0)
	end
	if (houses>1) then
		printc("please, no more", 32, 44,10,0,0)
		printc("than one cabin", 32, 54,10,0,0)
	end

	if createsteps[createstep]=="name" or 
		createsteps[createstep]=="author" or
		createsteps[createstep]=="code" then
		draw_input_wheel()
	end

	if createsteps[createstep]=="save" then
		draw_save_level()
	end

end

function _update60()
	if (intro) then
		intro_update()
		return
	end

	step+=1

	if (introscreen) then
		introscreen_update()
		return
	end

	if main_menu then
		main_menu_update()
		return
	end

	if modeselected==3 then
		create_level_update()
		return
	end

	action=false

	if btnp(5) then
		-- idle
		action=true
		debug=not debug

	end
	delete_blast()

	for i=1,#blasts do
		if blasts[i].time>0 then
			blasts[i].time-=1
		end
		if blasts[i].time==2 then
			sfx(9)
		end

		if blasts[i].time==0 then
			for x=-1,1 do
				for y=-1,1 do
					val=mget(blasts[i].x+x, blasts[i].y+y)
					try_ignite(blasts[i].x+x, blasts[i].y+y)
					val=mget(blasts[i].x+x, blasts[i].y+y)
					if fget(val,0) and not fget(val,1) and not fget(val,2) then
						mset(blasts[i].x+x, blasts[i].y+y,130)
					end
				end
			end
			--del(blasts, blasts[i])
		end
	end

	if (calc_sol) then
		calc_sol=false

		if (not gameover) then
			start=getspecialtile(dude_tile)
			if (start!=nil) then
				sol_path=a_star()
				if (sol_path==nil) then
					solution=false
				else
					solution=true
				end
				if(solution) then
					path_step=1
				end
			end
		end
	end
	something_is_burning=false
	if (step%8==0) then
		for x=0,7 do
			for y=0,7 do
				val=mget(x,y)
				valitem=mget(x+9,y)
				if (valitem==171 or valitem==247) then
					try_ignite(x,y)
				end
				if (val==79) then
					mset(x,y,76)
				elseif (valitem==152 or valitem==172) then
					--mset(x,y,under_log_tile)
				elseif (valitem==216) then
					mset(x+9,y,34)
				elseif (val==76 or val==78) then
					mset(x,y,val+1)
				elseif valitem>82 and valitem<88 then
					mset(x+9,y,valitem+1)
					dude_tile=valitem+1
				elseif valitem==88 then
					mset(x+9,y,83)
					dude_tile=83
				elseif valitem==20 or valitem==21 or valitem==13 or valitem==14 then
					mset(x+9,y,valitem+1)
					dude_tile=valitem+1
				end
				if fget(val,6) and val%2==1 then 
					mset(x,y,val+1)
				elseif fget(val,6) and val%2==0 then 
					mset(x,y,val-1)
				end
				if fget(valitem,6) and valitem%2==1 then 
					mset(x+9,y,valitem+1)
				elseif fget(valitem,6) and valitem%2==0 then 
					mset(x+9,y,valitem-1)
				end

				if val==75 or valitem==231 or valitem==247 then
					--mset(x,y,92)
					explosion={}
					explosion.x=x
					explosion.y=y
					explosion.frame=110
					explosion.time=10
					add(blasts,explosion)
				end
				if valitem==15 then
					status["dude"] = "burnt"
					gameover=true
				end
				if val==47 then
					status["house"] = "burnt"
					gameover=true
				end
				newval=mget(x+9,y)
				if fget(newval,4) then 
					dude_tile=newval
				end
				if fget(newval,2) then
					something_is_burning=true
				end
			end
		end
		if fget(player.cargo,6) then
			player.cargo+=1
		elseif fget(player.cargo,7) then
			player.cargo-=1
		end
		

	end
	if something_is_burning then
		--sfx(7)
	end
	if (step%4==0) then
		if (player.sprite == 98) then
			player.sprite = 100
		else
			player.sprite = 98
		end
	end
	if btnp(1) then
		if player.x<7 then
			player.x+=1
			action=true
		end
		if(winnar and not spread_done and not gameover) then
			levelselected+=1
			if levelselected>#levels then
				finished=true
				main_menu=true
				levelselected=1
				gamestarted=false
			end
			if createsteps[createstep]=="play" then
				levelwon=true
				main_menu=true
				gamestarted=false
			end
			reset()
			return
		end
	end
	if btnp(0) then
		if player.x>0 then
			player.x-=1
			action=true
		end
		if(gameover) then
			reset()
			return
		end
	end
	if btnp(2) and player.y>-1 then
		player.y-=1
		action=true
	end
	if btnp(3) and player.y<6 then
		player.y+=1
		action=true
	end
	skip_fire=true
	if btnp(4) then
		action=true
		val=mget(player.x,player.y+1)
		valitem=mget(player.x+9,player.y+1)
		if player.cargo!=116 then
			sfx(5)
			-- water
			if player.cargo==103 then -- water
				player.cargo=116
				if val==25 or val==26 then
					mset(player.x,player.y+1,80)
				elseif val==24 then
					mset(player.x,player.y+1,23)
				elseif valitem==11 or valitem==12 or valitem==22 then
					mset(player.x+9,player.y+1,20)
					dude_tile=20
				elseif val==41 or val==42 then
					status["house"]="ignited_but_washed"
					mset(player.x,player.y+1,18)
				elseif val==43 or val==44 then
					status["house"]="on_fire_but_washed"
					mset(player.x,player.y+1,18)
				elseif val==45 or val==46 then
					status["house"]="burnt"
					mset(player.x,player.y+1,47)
				elseif valitem==13 or valitem==14 then
					status["dude"] = "burning_but_put_out"
					mset(player.x+9,player.y+1,20)
					dude_tile=20
				end
			elseif player.cargo==113 or player.cargo==112 then -- half a car
				cartop_tile=64
				if player.cargo==112 then
					cartop_tile=65
				end
				player.cargo=116
				--under_cartop_tile=mget(player.x,player.y+1)
				--under_cartop_tile_x=player.x
				--under_cartop_tile_y=player.y+1
				if (fget(valitem,4) or fget(val,4)) then
					gameover=true
					calc_sol=false
					dude_tile=175
					status["dude"]="squished"
					mset(player.x,player.y+1,dude_tile)
				end
				if (fget(val,1)) then
					mset(player.x+9,player.y+1,215)
				else
					mset(player.x+9,player.y+1,cartop_tile)
				end

			elseif player.cargo==115 then -- barrel
				player.cargo=116
				--under_barrel_tile = mget(player.x,player.y+1)
				--under_barrel_tile_x=player.x
				--under_barrel_tile_y=player.y+1
				if (fget(valitem,4) or fget(val,4)) then
					gameover=true
					calc_sol=false
					dude_tile=175
					status["dude"]="squished"
					mset(player.x,player.y+1,dude_tile)
				end

				if (fget(val,1)) then
					mset(player.x+9,player.y+1,225)
				else
					mset(player.x+9,player.y+1,240)
				end
			elseif player.cargo==96 or player.cargo==97 then -- barrel on fire
				skip_fire=false
				--under_barrel_tile = mget(player.x,player.y+1)
				--under_barrel_tile_x=player.x
				--under_barrel_tile_y=player.y+1
				spread_done=false
			elseif player.cargo==104 then -- log
				player.cargo=116
				--if(mget(player.x,player.y+1)==23 or mget(player.x,player.y+1)==24) then
				--	mset(player.x,player.y+1,144)
				--else
				--under_log_tile = mget(player.x,player.y+1)
				--under_log_tile_x=player.x
				--under_log_tile_y=player.y+1

			if (fget(valitem,4) or fget(val,4)) then
				gameover=true
				calc_sol=false
				dude_tile=175
				status["dude"]="squished"
				mset(player.x,player.y+1,dude_tile)
			end
			if (fget(val,1)) then
					mset(player.x+9,player.y+1,145)
				else
					mset(player.x+9,player.y+1,164)
				end
				--end
			elseif player.cargo==106 or player.cargo==107 then -- burning log
				skip_fire=false
				--under_log_tile = mget(player.x,player.y+1)
				--under_log_tile_x=player.x
				--under_log_tile_y=player.y+1
				spread_done=false
			elseif player.cargo==102 then -- rock
				player.cargo=116
				if (not fget(val,0)) then
					solution=false
					calc_sol=true
				end
				--if val==26 or val==27 then
				if (fget(valitem,4) or fget(val,4)) then
					gameover=true
					calc_sol=false
					dude_tile=128
					status["dude"]="squished"
					mset(player.x,player.y+1,dude_tile)
					mset(player.x+9,player.y+1,34)
				else
					mset(player.x,player.y+1,39)
				end
			elseif player.cargo==120 or player.cargo==121 then -- fire
				skip_fire=false
			elseif player.cargo==119 then
				player.cargo=116
			end
		else
			sfx(4)

			if valitem==240 or valitem==225 or valitem==226 then -- barrel
				player.cargo=115
				--mset(player.x,player.y+1,under_barrel_tile) -- todo default to green
				mset(player.x+9,player.y+1,34) -- todo default to green
				calc_sol=true
			elseif (valitem>240 and valitem<247) or (valitem>226 and valitem<231) then -- barrel (on fire)
				player.cargo=96
				mset(player.x+9,player.y+1,34)
				calc_sol=true
			elseif valitem==64 then -- cartop
				player.cargo=113
				cartop_tile=64
				mset(player.x+9,player.y+1,34)
				calc_sol=true
			elseif valitem==65 then -- cartop, burnt
				player.cargo=112
				cartop_tile=65
				mset(player.x+9,player.y+1,34)
				calc_sol=true
			elseif (valitem>164 and valitem<171) or (valitem>146 and valitem<151) then -- log (on fire)
				player.cargo=106
				mset(player.x+9,player.y+1,34)
				calc_sol=true
			elseif valitem==164 or valitem==145 or valitem==146 then -- log
				player.cargo=104
				mset(player.x+9,player.y+1,34)
				calc_sol=true
--			elseif val==144 then -- log from forest
---				player.cargo=104
--				mset(player.x,player.y+1,24)
			elseif fget(val,3) then -- earth (rock)
				player.cargo=102 
				if (val!=39 and val!=128 and val!=129) then
					mset(player.x,player.y+1,val+1) -- make smaller mountain
				end
			elseif fget(val,2) then -- fire
				player.cargo=121
			elseif fget(val,1) then -- water
				player.cargo=103
			elseif fget(valitem,4) then -- oops. dude
				mset(player.x+9,player.y+1,83)
				status["dude"]="decapitated"
				dude_tile=83

				gameover=true
				player.cargo=117
			elseif val==68 then --and val<75 then -- car
				player.cargo=113
				mset(player.x,player.y+1,132)
			elseif val>75 and val<80 then -- burnt car
				player.cargo=119--112
				mset(player.x,player.y+1,141)
			elseif valitem==64 then -- top of car
				player.cargo=113
				mset(player.x+9,player.y+1,34)
				calc_sol=true
			elseif val==65 then -- top of burnt car
				player.cargo=112
				mset(player.x+9,player.y+1,34)
				calc_sol=true
			else
				player.cargo=119 -- air
			end
		end
	end

	if (action) then
		spread_done=spread()--tempmap1, tempmapitem1)
		if not spread_done then
			calc_sol = true
		end

		found=false
		if (solution and not gameover and not fget(dude_tile,2)) then
			if (path_step>#sol_path) then
				--check if dude is on fire or house is on fire or burnt down and display appropriate msg
				
			else
				for x=0,7 do
					for y=0,7 do
						if not found and fget(mget(x+9,y),4) then
							found=true
							--mset(x+9,y,under_dude_tile)
							mset(x+9,y,0)
							sol_pos = sol_path[path_step]
							path_step+=1
							--under_dude_tile=mget(sol_pos[1],sol_pos[2])\\
							if (path_step>#sol_path) then
								winnar=true
								dude_tile=161
							end
							mset(sol_pos[1]+9,sol_pos[2],dude_tile)
						end
					end
				end
			end
		end
	end
	-- ignite things after spread
	if btnp(4) and not skip_fire then
		val=mget(player.x,player.y+1)
		valitem=mget(player.x+9,player.y+1)
		if player.cargo==120 or player.cargo==121 then -- fire
			try_ignite(player.x,player.y+1)
			player.cargo=116
		elseif player.cargo==96 or player.cargo==97 then -- barrel on fire
			player.cargo=116
			--under_barrel_tile = mget(player.x,player.y+1) -- already done
			if (fget(val,1)) then
				mset(player.x+9,player.y+1,227)
			else
				mset(player.x+9,player.y+1,243)
			end
		elseif player.cargo==106 or player.cargo==107 then -- log on fire
			player.cargo=116
			--under_log_tile = mget(player.x,player.y+1) -- already done
--			mset(player.x,player.y+1,167)
			if (fget(val,1)) then
				mset(player.x+9,player.y+1,147)
			else
				mset(player.x+9,player.y+1,167)
			end
		end
	end

  --mset(point[1],point[2],18)
 end

function delete_blast()

	for i=1,#blasts do
		if blasts[i].time==0 then
			del(blasts, blasts[i]) -- delete one because it doesn't matter if we have soem with time==0
			return
		end
	end

end
-- done change spread so that only the tiles next to current fires will be lit. then we can see if its on pickup+drop or just drop
-- done then add a walking algo (a-star) for the little people to run to their cabins or cars
-- done fix kill_fire so that it only kills the fire if there is no use for it (e.g. can't spread it with wind)
-- done main menu / title screen
-- done tutorial map(s)
-- menu key to restart
-- create/edit map
-- save map to the "cloud"
-- download and play maps
-- maps, lots of maps, each
-- algo to read and store maps
function spread() -- tempmap,tempmapitem)
	spreaded=false
	tempmap = {}
	tempmapitem = {}
	for x=0,7 do
		tempmap[x] = {}
		tempmapitem[x] = {}
		for y=0,7 do
			tempmap[x][y] = mget(x,y)
			tempmapitem[x][y] = mget(x+9,y)
		end
	end
	for x=0,7 do
		for y=0,7 do
			val=tempmap[x][y]
			valitem=tempmapitem[x][y]
			if valitem==245 or valitem==246 then
				--mset(x+9,y,247)
				--return
			end
			if fget(val,7) or fget(valitem,7) then
				try_ignite(x-1,y)
				try_ignite(x,y-1)
				try_ignite(x+1,y)
				try_ignite(x,y+1)
				try_ignite(x,y)
				spreaded=true

				if(false) then
					if try_ignite(x-1,y) then 
						spreaded=true
					end
					if try_ignite(x,y-1) then
						spreaded=true
					end
					if try_ignite(x+1,y) then
						spreaded=true
					end
					if try_ignite(x,y+1) then
						spreaded=true
					end
				end
				--return trsuede
				-- move to next anim (which could mean extinguish)
			end
			if fget(val,2) or fget(valitem,2) then
				spreaded=true
				if (val==45 or val==46) then
					status["house"]="burnt_down"
				end
				if fget(val,6) and val%2==1 then
					mset(x,y,val+2)
				elseif fget(val,6) and val%2==0 then
					mset(x,y,val+1)
				end
				if fget(valitem,6) and valitem%2==1 then
					mset(x+9,y,valitem+2)
				elseif fget(valitem,6) and valitem%2==0 then
					mset(x+9,y,valitem+1)
				end
				if fget(valitem,4) then
					status["dude"] = "burnt"
					dude_tile=valitem
				end
				--trigger astar
				if (not solution) then
					calc_sol=true
				end
			end
		end
	end
	return spreaded
end
function try_ignite(x,y)
	val2=mget(x,y)
	valitem=mget(x+9,y)

	ignited=false

	if fget(valitem,4) then
		status["dude"]="burning"
		dude_tile=13
		mset(x+9,y,dude_tile)
	end
	if fget(valitem,5) then
		if fget(valitem,6) and valitem%2==1 then
			mset(x+9,y,valitem+2)
--		elseif fget(valitem,6) and valitem%2==0 then
--			mset(x+9,y,valitem+1)
		else
			mset(x+9,y,valitem+1)
		end
		ignited=true
	end
	if fget(val2,5) then
		if val2==40 then
			status["house"]="on_fire"
		end	
		if fget(val2,6) and val2%2==1 then
			mset(x,y,val2+2)
		else 
			mset(x,y,val2+1)
		end
		ignited=true
	end
	--return ignited
end

function _draw()
	if (intro) then
		intro_draw()
		return
	end
	if (introscreen) then
		introscreen_draw()
		return
	end
	if (main_menu) then
		main_menu_draw()
		return
	end
	if modeselected==3 then
		create_level_draw()
		return
	end
	cls(0)
	--spr(under_log_tile, under_log_tile_x*8, under_log_tile_y*8)
	--spr(under_cartop_tile, under_cartop_tile_x*8, under_cartop_tile_y*8)
	--spr(under_barrel_tile, under_barrel_tile_x*8, under_barrel_tile_y*8)
	map(0,0,0,0,8,8)
	map(9,0,0,0,8,8)
	for i=1,#blasts do
		if blasts[i].time>0 then
			spr(blasts[i].frame, (blasts[i].x-2)*8+4, (blasts[i].y-2)*8+4, 2, 2)
			spr(blasts[i].frame, (blasts[i].x)*8+4, (blasts[i].y)*8+4, 2, 2, true, true)
			spr(blasts[i].frame, (blasts[i].x)*8+4, (blasts[i].y-2)*8+4, 2, 2, true)
			spr(blasts[i].frame, (blasts[i].x-2)*8+4, (blasts[i].y)*8+4, 2, 2, false, true)
		end
	end
	spr(player.sprite, player.x*8, player.y*8, 2, 1)
	spr(player.cargo, player.x*8, (player.y+1)*8)
	if(winnar and not spread_done and not gameover and (player.cargo==116 or player.cargo==119)) then
		printc("good work!", 32, 4,10,0,0)

		printc("press \x91", 32, 44,10,0,0)
		printc("for next level ", 32, 54,10,0,0)
	end
	if (gameover) then
		if status["dude"]=="squished" then
			printc("mr.bernt", 32, 4,10,0,0)
			printc("got squished!", 32, 14,10,0,0)
		elseif status["dude"]=="burnt" then
			printc("mr.bernt", 32, 4,10,0,0)
			printc("got burnt!", 32, 14,10,0,0)
		elseif status["dude"]=="decapitated" then
			printc("decapitation!", 32, 4,10,0,0)

		end
		if status["house"]=="burnt" then
			printc("the cabin", 32, 24,10,0,0)
			printc("burned down!", 32, 34,10,0,0)
		elseif status["house"]=="squished" then
			printc("the cabin", 32, 24,10,0,0)
			printc("was crushed!", 32, 34,10,0,0)
		end
	end

	if (gameover and spread_done) then
		printc("press \x8b", 32, 44,10,0,0)
		printc("to try again ", 32, 54,10,0,0)
	end
	if (solution) then
		--print("yeah" .. path_step .. " " .. #sol_path,0,0,0)
		--print(sol_path[path_step+1][1] .. "," .. sol_path[path_step+1][2],0,10,0)
	end

	if debug then
		print("dude:" .. status["dude"], 0,50,0)
		print("house:" .. status["house"], 0,58,0)
		print(mget(player.x+9, player.y+1) .. " and " .. fget(mget(player.x+9,player.y+1)), 0,48,7)
		for x=0,7 do
			if fget(mget(player.x+9,player.y+1),x) then
				print("1",x*8,58,7)
			else
				print("0",x*8,58,7)
			end
		end
	end
end

function intro_init()
  map_x = 30
  map_y_org = 14
  offs=0
  music(0)
  intro=true
  extra=220
end

function intro_update()
	map_x -= 1
	if btnp(5) or btnp(4) or map_x < -470 then
		intro=false
		music(6)
	end
end

function intro_draw()
	cls(0)
	map_y = map_y_org 
	spr(offs+1, map_x+48, map_y)
	spr(offs+1, map_x+80, map_y)
	spr(offs+1, map_x+96, map_y)

	map_y += 8
	spr(offs+5, map_x+32, map_y)
	spr(offs+7, map_x+40, map_y)
	spr(offs+1, map_x+48, map_y)

	spr(offs+5, map_x+56, map_y)
	spr(offs+7, map_x+64, map_y)
	spr(offs+3, map_x+72, map_y)

	spr(offs+1, map_x+80, map_y)

	spr(offs+1, map_x+96, map_y)

	spr(offs+5, map_x+112, map_y)
	spr(offs+7, map_x+120, map_y)
	spr(offs+1, map_x+128, map_y)

	spr(offs+5, map_x+136, map_y)
	spr(offs+1, map_x+144, map_y)

	spr(offs+5, map_x+152, map_y)
	spr(offs+7, map_x+160, map_y)
	spr(offs+3, map_x+168, map_y)

	spr(offs+5, map_x+176, map_y)
	spr(offs+7, map_x+184, map_y)
	spr(offs+1, map_x+192, map_y)

	spr(offs+5, map_x+200, map_y)
	spr(offs+7, map_x+208, map_y)
	spr(offs+3, map_x+216, map_y)

	map_y += 8
	spr(offs+1, map_x+32, map_y)
	spr(offs+1, map_x+48, map_y)

	spr(offs+1, map_x+56, map_y)
	spr(offs+1, map_x+72, map_y)

	spr(offs+1, map_x+80, map_y)

	spr(offs+1, map_x+96, map_y)

	spr(offs+1, map_x+112, map_y)
	spr(offs+1, map_x+128, map_y)

	spr(offs+1, map_x+136, map_y)

	spr(offs+1, map_x+152, map_y)
	spr(offs+1, map_x+168, map_y)

	spr(offs+1, map_x+176, map_y)
	spr(offs+1, map_x+192, map_y)

	spr(offs+1, map_x+200, map_y)
	spr(offs+6, map_x+216, map_y)

	map_y += 8
	spr(offs+2, map_x+32, map_y)
	spr(offs+7, map_x+40, map_y)
	spr(offs+1, map_x+48, map_y)

	spr(offs+2, map_x+56, map_y)
	spr(offs+7, map_x+64, map_y)
	spr(offs+6, map_x+72, map_y)

	spr(offs+2, map_x+80, map_y)
	spr(offs+1, map_x+88, map_y)

	spr(offs+2, map_x+96, map_y)
	spr(offs+1, map_x+104, map_y)

	spr(offs+2, map_x+112, map_y)
	spr(offs+7, map_x+120, map_y)
	spr(offs+1, map_x+128, map_y)

	spr(offs+1, map_x+136, map_y)

	spr(offs+2, map_x+152, map_y)
	spr(offs+7, map_x+160, map_y)
	spr(offs+6, map_x+168, map_y)

	spr(offs+1, map_x+176, map_y)
	spr(offs+1, map_x+192, map_y)

	spr(offs+2, map_x+200, map_y)
	spr(offs+7, map_x+208, map_y)
	spr(offs+6, map_x+216, map_y)

	map_y-=24
	--map_x+=100

	spr(offs+1, extra+map_x+104, map_y)
	spr(offs+1, extra+map_x+152, map_y)
	spr(offs+4, extra+map_x+168, map_y)

	map_y += 8

	spr(offs+7, extra+map_x+24, map_y)
	spr(offs+7, extra+map_x+32, map_y)
	spr(offs+3, extra+map_x+40, map_y)

	spr(offs+5, extra+map_x+48, map_y)
	spr(offs+1, extra+map_x+56, map_y)

	spr(offs+5, extra+map_x+64, map_y)
	spr(offs+7, extra+map_x+72, map_y)
	spr(offs+3, extra+map_x+80, map_y)
	
	spr(offs+5, extra+map_x+88, map_y)
	spr(offs+7, extra+map_x+96, map_y)
	spr(offs+1, extra+map_x+104, map_y)

	spr(offs+1, extra+map_x+112, map_y)
	
	spr(offs+1, extra+map_x+128, map_y)

	spr(offs+5, extra+map_x+136, map_y)
	spr(offs+1, extra+map_x+144, map_y)

	spr(offs+7, extra+map_x+152, map_y)
	spr(offs+1, extra+map_x+160, map_y)

	spr(offs+1, extra+map_x+168, map_y)

	spr(offs+5, extra+map_x+176, map_y)
	spr(offs+7, extra+map_x+184, map_y)
	spr(offs+3, extra+map_x+192, map_y)

	spr(offs+7, extra+map_x+200, map_y)
	spr(offs+7, extra+map_x+208, map_y)
	spr(offs+3, extra+map_x+216, map_y)

	spr(offs+5, extra+map_x+224, map_y)
	spr(offs+1, extra+map_x+232, map_y)

	map_y += 8

	spr(offs+1, extra+map_x+24, map_y)
	spr(offs+1, extra+ map_x+40, map_y)

	spr(offs+1, extra+map_x+48, map_y)

	spr(offs+1,extra+ map_x+64, map_y)
	spr(offs+1,extra+ map_x+80, map_y)
	
	spr(offs+1,extra+ map_x+88, map_y)
	spr(offs+1,extra+ map_x+104, map_y)

	spr(offs+1,extra+ map_x+112, map_y)
	
	spr(offs+1,extra+ map_x+128, map_y)

	spr(offs+1, extra+map_x+136, map_y)

	spr(offs+1,extra+ map_x+152, map_y)

	spr(offs+1,extra+ map_x+168, map_y)

	spr(offs+1,extra+ map_x+176, map_y)
	spr(offs+1,extra+ map_x+192, map_y)

	spr(offs+1,extra+ map_x+200, map_y)
	spr(offs+1,extra+ map_x+216, map_y)

	spr(offs+2,extra+ map_x+224, map_y)
	spr(offs+3,extra+ map_x+232, map_y)

	map_y += 8

	spr(offs+7, extra+map_x+24, map_y)
	spr(offs+7, extra+map_x+32, map_y)
	spr(offs+6, extra+map_x+40, map_y)

	spr(offs+1, extra+map_x+48, map_y)

	spr(offs+2, extra+map_x+64, map_y)
	spr(offs+7, extra+map_x+72, map_y)
	spr(offs+6, extra+map_x+80, map_y)
	
	spr(offs+2, extra+map_x+88, map_y)
	spr(offs+7, extra+map_x+96, map_y)
	spr(offs+1, extra+map_x+104, map_y)

	spr(offs+2, extra+map_x+112, map_y)
	spr(offs+7, extra+map_x+120, map_y)
	spr(offs+6, extra+map_x+128, map_y)

	spr(offs+2, extra+map_x+136, map_y)
	spr(offs+1, extra+map_x+144, map_y)

	spr(offs+2, extra+map_x+152, map_y)
	spr(offs+1, extra+map_x+160, map_y)

	spr(offs+1, extra+map_x+168, map_y)

	spr(offs+2,extra+ map_x+176, map_y)
	spr(offs+7, extra+map_x+184, map_y)
	spr(offs+6,extra+map_x+192, map_y)

	spr(offs+1, extra+map_x+200, map_y)
	spr(offs+1, extra+map_x+216, map_y)

	spr(offs+7, extra+map_x+224, map_y)
	spr(offs+6, extra+map_x+232, map_y)

	map_y += 8

	spr(offs+1, extra+map_x+24, map_y)

end


--- a star stuff 

function a_star()

-- printh("start...")

 frontier = {}
 insert(frontier, start, 0)
 came_from = {}
 if (start==nil) return false
 came_from[vectoindex(start)] = nil
 cost_so_far = {}
 cost_so_far[vectoindex(start)] = 0

 while (#frontier > 0 and #frontier < 1000) do
  current = popend(frontier)

  if vectoindex(current) == vectoindex(goal) then
   break
  end

  local neighbours = getneighbours(current)
  for next in all(neighbours) do
   local nextindex = vectoindex(next)
  
   local new_cost = cost_so_far[vectoindex(current)] -- add extra costs here

   if (cost_so_far[nextindex] == nil) or (new_cost < cost_so_far[nextindex]) then
    cost_so_far[nextindex] = new_cost
    local priority = new_cost + heuristic(goal, next)
    insert(frontier, next, priority)
    
    came_from[nextindex] = current
    
    if (nextindex != vectoindex(start)) and (nextindex != vectoindex(goal)) then
     --mset(next[1],next[2],19)
    end
   end 
  end
 end

-- printh("find goal..")
 current = came_from[vectoindex(goal)]

 if (nil==current) return nil
 path = {}
 local cindex = vectoindex(current)
 local sindex = vectoindex(start)

 while cindex != sindex do
  add(path, current)
  current = came_from[cindex]
  cindex = vectoindex(current)
 end
 reverse(path)

 for point in all(path) do
  --mset(point[1],point[2],18)
 end

 --printh("..done")

 return path
end

-- manhattan distance on a square grid
function heuristic(a, b)
 return abs(a[1] - b[1]) + abs(a[2] - b[2])
end

-- find all existing neighbours of a position that are not walls
function getneighbours(pos)
 local neighbours={}
 local x = pos[1]
 local y = pos[2]
 if x >= 0 and (false==fget(mget(x-1,y),wallid)) and (false==fget(mget(x+8,y),wallid)) then
  add(neighbours,{x-1,y})
 end
 if x < 8 and (false==fget(mget(x+1,y),wallid)) and (false==fget(mget(x+10,y),wallid)) then
  add(neighbours,{x+1,y})
 end
 if y >= 0 and (false==fget(mget(x,y-1),wallid)) and (false==fget(mget(x+9,y-1),wallid)) then
  add(neighbours,{x,y-1})
 end
 if y < 8 and (false==fget(mget(x,y+1),wallid)) and (false==fget(mget(x+9,y+1),wallid)) then
  add(neighbours,{x,y+1})
 end

 -- for making diagonals
 --if (x+y) % 2 == 0 then
  reverse(neighbours)
 --end
 return neighbours
end

-- find the first location of a specific tile type
function getspecialtile(tileid)
 for x=0,7 do
  for y=0,7 do
   local tile = mget(x,y)
   if tile == tileid then
    return {x,y}
   end
   local tile2 = mget(x+9,y)
   if tile2 == tileid then
    return {x,y}
   end

  end
 end
-- printh("did not find tile: "..tileid)
end

-- insert into start of table
function insert(t, val)
 for i=(#t+1),2,-1 do
  t[i] = t[i-1]
 end
 t[1] = val
end

-- insert into table and sort by priority
function insert(t, val, p)
 if #t >= 1 then
  add(t, {})
  for i=(#t),2,-1 do
   
   local next = t[i-1]
   if p < next[2] then
    t[i] = {val, p}
    return
   else
    t[i] = next
   end
  end
  t[1] = {val, p}
 else
  add(t, {val, p}) 
 end
end

-- pop the last element off a table
function popend(t)
 local top = t[#t]
 del(t,t[#t])
 return top[1]
end

function reverse(t)
 for i=1,(#t/2) do
  local temp = t[i]
  local oppindex = #t-(i-1)
  t[i] = t[oppindex]
  t[oppindex] = temp
 end
end

-- translate a 2d x,y coordinate to a 1d index and back again
function vectoindex(vec)
	--if (nil==vec) printh("vec is null")
 return maptoindex(vec[1],vec[2])
end

function maptoindex(x, y)
 return ((x+1) * 8) + y
end

function indextomap(index)
 local x = (index-1)/8
 local y = index - (x*w)
 return {x,y}
end

-- pop the first element off a table (unused
function pop(t)
 local top = t[1]
 for i=1,(#t) do
  if i == (#t) then
   del(t,t[i])
  else
   t[i] = t[i+1]
  end
 end
 return top
end
__gfx__
eeeeeeee1111111e1111111111eeeeee1111111eeeeee1111111111e111111113366663333333333eeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeaeeeeeeeeeee
eeeeeeee1111111e111111111111eeee1111111eeee111111111111e111111113666666333666633eeeeeeeeeeeeeeeeeeeeeeeeeeaaaeeeeeaaaeeeeeeeeeee
eeeeeeee1111111ee111111111111eee1111111eee111111111111ee111111116666666666666633eeeeeeeeeeeeeeeeeeeeeeeeee999feeef999eeeeeee7eee
eeee00ee1111111ee1111111111111ee1111111ee1111111111111ee111111116666666666666663eeeeeeeeeeefeeeeefefefeef11881eee11881feeeeeeeee
eee0040e1111111eee111111111111ee1111111ee111111111111eee111111116666666666666663e11111eef11111fee11111eeee111eeeee111eeeee77e6ee
ee00400e1111111eeee111111111111e0000000e111111111111eeee111111116666666666666663ef111feeee111eeeee111eeeee4444eee4444eeeeee67eee
ee0400ee1111111eeeeee1111111111eeeeeeeee1111111111eeeeee111111116666666336666633ee444eeeee444eeeee444eeeee4eeeeeeeee4eeeee6ee7ee
eee00eee0000000eeeeeeeee0000000eeeeeeeee00000000eeeeeeee000000003666663333333333ee4e4eeeee4e4eeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeee
333333ccccc333333333333333333333eeeeeeeeeeeeeeeeeeeeeeee3b333b333b333b333b333ba33b333a333ba333a33b3a33aa3a3333a333a333aa33333333
333cccccccccc3333345533333333333eeeeeeeeeeeeeeeeeeeeeeeebbb3bbb3bbb3bbb3bbb3bba3bbb3b9b3baa33a9aba933a993a333a9a3a333a9933333333
33cccccccccccc333555555333333333eeccceeeeeeeeeeeeeeeeeeebbb3b4b3bbb3bbb3bbb3b893bbb3b8b3a9933988a9933989393339883933398935333333
3cccccccccccccc34555555533333333eccccceeeeefeeeeeeefeeee343cc4333433343334333433343334333433334334333343343333433433334334333533
3cccccccccccccc35000500533333333ec111ceeee111eeeee111eee3bcccb333b333b333b333b333b333b333a333ba333a33b3a33333ba333333b3a33333333
cccccccccccccccc4000500433333333ef111feee11111eee11111eebbbcbbb3bbb3bbb3bbb3bbb3bab3bbb3aaa3a9a3aaa3ba9a3a33a9a333a3ba9a33333333
cccccccccccccccc5000555533333333ee444eeeefcccfeeef444feebbb3bbb3bbb3bbb3b9b3bbb3b9b3bbb398a3989398a39893383398933933989333333433
cccccccccccccccc4000444433333333ee4e4eeeeccccceeee4e4eee343334333433343334333433343334333433343334333433343334333433343335333333
cccccccccccc3333eeeeeeee33333333333333333333333333333333333333333333333333333333333333333333a33333333333333aa3333333aaa333333333
ccccccccccccc333eeeeeeee33dd333333dd3333333333333333333333333333334444333344443333444433334aa4333344aa3333aaaaa3333aa9a333333333
cccccccccccccc33eeeeeeee3dd5dd333dd5dd333dddd3333ddd333333d3333335555553355555533555555335a99a5335a99a5335a999a335a999a334555333
cccccccccccccc33eeeeeeee3d55d5d33d55d5d33d55dd333d5ddd333dddd33344444444444aa4444444aa44449889a4449889a4449888944498889445535333
ccccccccccccccc3eeeeeeeedd555d5ddd555d5ddd55d5d3dd5d55d33d5d5d335000500550008905500089055000800550008905500989055009890553335553
ccccccccccccccc3eeeeeeeed5555d5dd5555d5dd5555d5dd555d5d3d55d55d34000400440004004400040044000400440004004400040044000400443335535
cccccccccccccc33eeeeeeeed5555d5dd5555d5dd5555d5dd555d5d3d555d5d35000555550005555500055555000555550005555500055555000555553335535
ccccccccccccc333eeeeeeee3dddddd33dddddd33dddddd33ddddd333ddddd334000444440004444400044444000444440004444400044444000444443335555
33ccc333cccccccc33333333cccccccccccccccc3333cccc33333333333555333335553333333333333333333335553333333333333333333333333333333333
3cccccc3cccccccc33ccccc3cccccccccccccccc33cccccc33333333333565333335653333333333333333333335653333333333333333333333333333b333b3
cccccccccccccccc3ccccccccccccccccccccccc3ccccccc33355555333555333335555555555555555555555555553355555533333333b33333333333333333
cccccccccccccccccccccccccccccccccccccccc3ccccccc33356566333565333335666556656665666566656566653366656533333333333b33333333333333
ccccccccccccccc3cccccccc3ccccccccccccccc3ccccccc333555553335553333355555555555555555555555555533555555333b333333333333333b333333
cccccccc3cccccc3ccccccc33cccccccccccccc33ccccccc33356566333565333335656656666566656666656665653366656533333333333333333333333333
cccccccc3ccccc333cccccc333cccccccccccc3333cccccc3335555533355533333555555555555555555555555555335555553333333b3333333b333333b333
cccccccc33ccc33333cccc333333cccccccc3333333ccccc33356533333565333333333333333333333333333333333333356533333333333333333333333333
eeeeeeeeeeeeeeeee99ee99e9ee99ee93333333333333333333333333333a33333333a33333aaaa33333aaaa3333333333333333333333333333333333333333
eeeeeeeeeeeeeeee9eeeeee9eeeeeeee33888833338a88333388a833338aa8333388aa3333aa9a33333aaa933333333333333333333333733333333333333333
eee8888eeee555ee9eeeeee9eeeeeeee38686633389a66333869a6333899a6333869963338999933389999933355533333555363335553333355533333555333
ee86866eee5e5eeeeeeeeeee9eeeeee9386866333899663338996633389966333899663338999633389999333535335335353333353533333535333335353353
ee86866eee5e5eeeeeeeeeee9eeeeee9888888888888888888888888888888888888888888899888888998883535333335353333353533333535330335353333
ee88888eee55555e9eeeeee9eeeeeeee888888888888888888888888888888888888888888888888888888885555555355555553555555535555555355555553
eeeeeeeeeeeeeeee9eeeeee9eeeeeeee855885588558855885588558855885588558855885588558855885585555555355555553555555535555555355555553
eeeeeeeeeeeeeeeee99ee99e9ee99ee9355335533553355335533553355335533553355335533553355335535dd55dd35dd55dd35dd55dd35dd55dd35dd55dd3
3b3333333333333333333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b5b3b533338a88333388a833eeeeeeeeeeeeeeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
b5bcb453386a66333869a633eeeeeeeeeee8eeeeee8eeeeeeee8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
34ccc4c338a9663338996633eee8eeeeeee8eeeeeee8eeeee8eeee8eeee8eeeeeeeeeeeeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00ee
3bccc5c38888888888888888e11211eee11211eee11211eee11211ee811211eee11211eeeee0040eeee0040eeee0040eeee0040eeee0040eeee0040eeee0040e
bbbcbbb38888888888888888ef111feeef111feeef111feeef111feeef111feeef111feeee00400eee00400eee00400eee00400eee00400eee00400eee00400e
b5bcbbb38558855885588558ee444eeeee444eeeee444eeeee444eeeee444ee88e484eeeee0400eeee0400eeee0400eeee0400eeee0400eeee0400eeee0400ee
343334333553355335533553ee4e4eeeee4e4eeeee4e4eeeee4e4eeeee4e4eeeee4e4eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eeeeee00eee
eeea6eeeeeeeaeee555555666666eeee666666555555eeeeeeee6eeeeeee6eeeeeee6eee33333333eeee6eeeeeee6eee333333333aaaa3aaeeeeeeeeeaeeeeea
eeea91eeeeea91eeeee11111eeee5ee6eee11111eeeee6eeeee111eeeee111eeeee111ee33333333eee11aeeeee111ae3333333aaaaaaaaaeeeeeeeeeaaeeeaa
ee29921eee29921eee1166111111156eee11661111111655ee11d11eee11e11eee41e11e33333333ee41eaaeee41eaae33333aaaaaaaaaaaeeeeeeeeeaaaeeaa
ee82281eee82281eee1666111111165eee1666111111556eee1d5d1eee1ccc1eee4ee41e33333333ee4e99aeee4e99ae3333aaaaaaaaaaaaeeeaeeeeeaaaaaaa
ee88881eee88881eee11111111ee6ee5ee11111111eeee6eee15dd1eee1ccc1e44444414333333334444481444444814333aaaaaaaaaaaaaeeeaaaeeeaaaaaaa
ee28821eee28821eeee111111eeeeeeeeee111111eeeeeeeee11111eee11111e5444441e333333335444441e5444441e33aaaaaaaaaaaaaaeeeeaaaeeaa9aaa9
ee11111eee11111e11e5ee5eeeeeeeee11e5ee5eeeeeeeeeeeeeeeeeeeeeeeeeee11111e33555533ee11111eee11111e33aaaaaaaaaaaaaaeeeeaaaaaaa99aa9
eeeeeeeeeeeeeeeee11111111eeeeeeee11111111eeeeeeeeeeeeeeeeeeeeeeeeeeeeeee33333333eeeeeeeeeeeeeeee3aaaaaaaaaaa9999eeeeeaaaaaa99999
eeee6eeeeeee6eeeeeeeefeeeeee6eeeeeee6eeeeeee6eeeeeeeeeeeeeee6eeeeeee6eeeeeee6eee33333333eeeeeeee3aaaaaaaaa999999eeeeeaaa99999999
eee111eeeee111eeeeeeefeeeee221eeeee111eeeee111eeeeeeeeeeeee111eeeee1a1eeeee11aee33333333eeeeeeeeaaaaaaaaa9999999eeeaaaaa99999999
ee55511eee88881eeeee555eee28821eee11e11eee11e11eeeeeeeeeee11e11eee1aa11eee11aa1e33333333eeeeeeeeaaaaaaaa99999999eaaaa99999999998
e515001ee868661eeee55055ee82281eee1eee1eee1fee1eeeee00eeee1eee1eee1a991eee1e991e33333333eeee00eeaaaaaaaa99999999aaaaaa9999999988
e515001ee868661eeee50005ee88881eee1eee1eee18ee1eeee0040eee1eee1eee19891eee19891e33333333eee0040eaaaaaaa999999988eeeaaaa999998888
e555551ee888881eeee55555ee28821eee1eee1eee11111eee00400eee11111eee11111eee11111e33355333ee00400eaaaaaaa999999888eeeeeaa999998888
ee11111eee11111eeee55555ee11111ee1eeeee1eeeeeeeeee0400eeeeeeeeeeeeeeeeeeeeeeeeee33333333ee0400eeaaaaaaa999998888eeaaaaa999988888
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeeeeeeeeeeeeeeeeeeeeeeeee33333333eee00eeeaaaaaaa999998888aaaaa99999888888
33dd333333dddd3333333333333883333333333333333333333333333333a33333333a33333aaaa33333aaaa33333333333333333333333333333333eeeeeeee
3dd5dd333dd55d33333333333383333333333333333a33333333a333333aa3333333aa3333aaaa33333aaaa333333333333333733333333333333333eeeeeeee
3d55d5d3dd5d55d333333333386866333333333333aa3333333aa333339aa333339aa33333aa993333aaa99333333363333333333333333333333333eeeeeeee
dd555d5dd555d5d433555333386866333333333333993333339933333399333333993333339993333399993333333333333333333333333333333353eeee00ee
d5555d5dd555d5d535444533888888888833338888993388889933888899338888993388889993888899938833333333333333333333330333333333eee0040e
d5555d5ddd55d5d454444453888888888888888888888888888888888888888888888888888888888888888855333353553333535533335355333353ee00400e
8ddddd885dddddd555444553855885588558855885588558855885588558855885588558855885588558855855555553555555535555555355555553ee0400ee
38888883444444443555553335533553355335533553355335533553355335533553355335533553355335535dd55dd35dd55dd35dd55dd35dd55dd3eee00eee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeeaeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeaeeeeeeaeeeeaeeaaeeeeeeeeeeeeeeeeee4eee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
eeeeeeeeeeeeeeeeee4eee4eeeeeeeaeee4eeeaaeeaeeaaeeeaaeaaaeeeeeeeeeeeeeeeeee4ee4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888eeee555ee
eeee00eeee4eee4eee4ee4eeee4eeaaeee4ee999eeaeea9aee9ee99eeeeeeeeeeeeeeeeee4444444eeee00eeeeee00eeeeee00eeeeee00eeee86866eee5e5eee
eee0040eee4ee4eee4444444ee4ee999e4444484ee9ee999e4844884eeee7e7eeeeeeeeee54f444eeee0040eeee0040eeee0040eeee0040eee86866eee5e5eee
ee00400ee444444475444447e444448475444447e484488475444447ee7eeeeeeee7e7ee8f11144eee00400eee00400eee00400eee00400eee88888ee855555e
ee0400eeee7777eee777777eee7777eee777777eee7777eee777777eeee7e7eeeeeeeeeee88888eeee0400eeee0400eeee0400eeee0400ee8f1f144e8f11f44e
eee00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00eeeeee00eeeeee00eeeeee00eeee88888eee88888ee
33333333eeeeeeeeeeeeeeeeeefefeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeaeeeaeeeeeeeeeeeeeeeeeeaeeeaeeeeaeeea33333333
33333333eefefeeeeeeeeeeeee1e1eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeaeeeeeeeeaee9eeeaeee9aeeeaeeeeeeeeeeeeeeeeee9eeaaaee9eeeaa33333333
33433343ee1f1eeeeeeeeeeeee1f1eeeee4eee4eee4eeeaeee4eee4aee4eeaaeee4eeeaaee8eeaaaee8eeeaaeeeeeeeeeeeeeeeeee8ee999ee8ee99933333333
33433433ee111eeeefefefeeee111eeeee4ee4eeee4ee49eee4ee49aee4ee999ee4ee999ee4ee999ee4ee999eeeeeeeeeeeeeeeee4444884e444488433333333
34444444ee111eeee11111eeee111eeee4444444e4444484e4444484e4444484e4444484e4444884e4444884eeeeeeeeeeeeeeeee544444ee544444e3333f333
35444443ee444eeeee111eeeee444eeee544444ee544444ee544444ee544444ee544444ee544444ee544444eeee5555eeee5555e8f1f144e8f1f144e38111144
33333333ee4e4eeeee444eeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55555eee55555eee888888ee888888e8f1f1443
33333333eeeeeeeeee4e4eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee38888833
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333333333333333333333333333333333333333333a333333333333333333333eeeeeeeeeeeeeeeeeeeeeeee00777770
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3333333333333333333333333a33333333a333333aa3333333aa333333333333eeeeeeeeeeeeeeeeeeeeeeee07766677
eeeceeeeeeeeeeeeeefe8efeeeeeeeee433333344a33333443a333344933333449a3333449a333a449aa333a33333333eeeeeeeeeeeeeeeeeeeeeeee07600067
eecfceeeeeefeeeeee11211eeeefeeee44333344493333444933334448333a44483333a4489333aa4893334a33333333eeee00eeeeee00eeeeee00ee07000007
e1c111eeee111eeeeee111eeee155eee4433334444333344443333444433339444333394483333a9483333a953333333eee0040eeee0040eeee0040e00070600
ef111feee11111eeeee444eee15511ee4433334444333344443333444433338444333384443333484433334855333335ee00400eee00400eee00400e00070600
ee444eeeef44cfeeeee4e4eeef444fee4433334444333344443333444433334444333344443333444433334435333355ee0400eeee0400eeee0400ee00070600
ee4e4eeeeece4eeeeeeeeeeeee4e4eee3433334334333343343333433433334334333343343333433433334333333333eee00eeeeee00eeeeee00eee00070600
000eeee000000000ee000000000000000000000e00000000000000000000000000000000555555509999999033333333cccccccc333333333b333b333b333ba3
0a00ee00a02a00a0e00a002a202a020aa202aa0007000067000700000000000000000000000000000000000033333333cccccccc33dd3333bbb3bbb3bbb3bba3
0a200002a00002a0e02a02a0a0000aa2002a02a0670000000767000600000000000000000000000000000000333333b3cccccccc3dd5dd33bbb3bbb3bbb3b893
00a00a0a00a00a0000a00a0000a00a000aaaaa0070000070007670770000000000000000000000000000000033333333cccccccc3d55d5d33433343334333433
e090292902902909929029900290290e0200000e7760067006700060000000000000000600000000000000003b333333ccccccccdd555d5d3b333b333b333b33
e098989009009090090090000900900e0980090e00700700070000760000000000000000000000000000000033333333ccccccccd5555d5dbbb3bbb3bbb3bbb3
e084084084084084840840e0840840ee0044480e06706700670000070000000000000000000000000000000033333b33ccccccccd5555d5dbbb3bbb3b9b3bbb3
e000000000000000000000e0000000eee000000e00000000000700000000000000000000000000000000000033333333cccccccc3dddddd33433343334333433
00000000000000000000000000000000000000000000000007670006eeeeeeeeeeeeeeee55555550999999903ba333a333333333333333333333333333333333
00000000007000070000070007670000700707007000007000767077eeeeeeeeeeeeeeee5eeeee509eeeee90baa33a9a33444433333333333333333333888833
00000000067700670077700067000000706767067760067006700060eeeeeeeeeeeeeeee5eeeee509eeeee90a993398835555553333333333343334338686633
00000000070000700700700070000000767670070070070007000076ee7eeeeeeee7eeee5eeeee509eeeee903433334344444444333f33333343343338686633
00000000670006700677670670000000670670670670670067000007eeee7eeeeeeee7ee5eeeee569eeeee963a333ba350005005f11111f33444444488888888
00000000000000000000000000000000000000000000000000000000e7eeee7eee7eeeee5eeeee509eeeee90aaa3a9a340004004331113333544444388888888
00000000000000000000000000000000000000000000000000000000eee7eeeeeeee7eee5eeeee509eeeee9098a3989350005555334443333333333385588558
00000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeee5eeeee509eeeee903433343340004444334343333333333335533553
33333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeeaeeeeeeeaaaeeeeeeeeeeeeeeeeeeeeeeeee333333333333333333355533333333333335553333355533
33322333eeeeeeeeeee22eeeeeeeaeeeeeea9eeeeeeeaaeeeeea9aaeeeeeeeeeeeeeeeeeeeeeeeee333333333332233333356533333333333335653333356533
33288233eee22eeeee2882eeeeeaaeeeee2992eeeeea9aeeee999aeeeeeeeeeeeeeeeeeeeeeeeeee333555553328823333355555433333345555553333355533
33822833ee2882eeee8228eeee2992eeee8228eeee9999eeee8998eeeeeeeeeeeeeeeeeeeeeeeeee333565663382283333356665443333445666653333356533
33888833ee8228eee788887eee8228eee788887eee8998eee788887eeeeee7eeeeeeeeeeeeeeeeee333555553388883333355555443333445555553333355533
33288233e778877eee7887eee778877eee7887eee778877eee7887eeee7eeeeeeee7eeeeeeeeeeee333565663328823333356565443333445665653333356533
33322333eee77eeeeee77eeeeee77eeeeee77eeeeee77eeeeee77eeeeeee7eeeeeeee7eeeeeeeeee333555553332233333355555443333445555553333355533
33333333eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee333565333333333333333333343333433333333333356533
eeeeeeeeeeeeeeeeeeeeeeeeeeeaaeeeeeeeaaeeeeeeaaaeeeeeeaaaeeeeeeeeeeeeeeeeeee22eee3333333333333333333333cccccc3333cccccccccccccccc
eee22eeeeeea2eeeeee2aeeeeeaa9eeeeeeaaeeeeeea9aaeeeeaaaaeeeeeeeeeeeeeeeeeee2882ee3333333333333333333ccccccccccc33cccccccccccccccc
ee2882eeee29a2eeee29a2eeeea992eeeea992eeeea99aeeeea99aaeeee5eeeeeee5eeeeee8228ee555555335555555533cccccccccccc33cccccccccccccccc
ee8228eeee8228eeee8228eeee8228eeee8228eeee899aeeee899aeee5e55e5ee5e55e5eee8888ee66656533566566653cccccccccccccc3cccccccccccccccc
ee8888eeee8888eeee8888eeee8888eeee8888eeee8888eeee8888eee55005eee55005eee82882ee5555553355555555ccccccccccccccc3cccccccccccccccc
ee2882eeee2882eeee2882eeee2882eeee2882eeee2882eeee2882eeee000055ee000055e88228ee5665653356665665ccccccccccccccccccccccccccccccc3
eee22eeeeee22eeeeee22eeeeee22eeeeee22eeeeee22eeeeee22eeee550055ee550055eee888eee5555553355555555cccccccccccccccc3ccccccccccccc33
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee55e5eeee55e5eeeeeeeee3335653333333333cccccccccccccccc333ccccccccc3333
__label__
33bb33aa3333aaaa33bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb3333333333333333333333333333333333333333333333333333
33bb33aa3333aaaa33bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb3333333333333333333333333333333333333333333333333333
bbaa993333aa9999bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333dddddddd33333333dddddddd33333333dddddddd3333
bbaa993333aa9999bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333dddddddd33333333dddddddd33333333dddddddd3333
aa99993333998899bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb3333dddd55dd55dd3333dddd55dd55dd3333dddd55dd55dd33
aa99993333998899bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb3333dddd55dd55dd3333dddd55dd55dd3333dddd55dd55dd33
3344333333334433334433333344333333443333334433333344333333443333334433333344333333dd5555dd5555dd33dd5555dd5555dd33dd5555dd5555dd
3344333333334433334433333344333333443333334433333344333333443333334433333344333333dd5555dd5555dd33dd5555dd5555dd33dd5555dd5555dd
3333aa3333bb33aa33bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb3333dddd555555dd55dddddd555555dd55dddddd555555dd55dd
3333aa3333bb33aa33bb333333bb333333bb333333bb333333bb333333bb333333bb333333bb3333dddd555555dd55dddddd555555dd55dddddd555555dd55dd
aaaaaa33bbaa99aabbbbbb3300000033bbbbbb000000000000000000bbbb0000000000000000000000000000000000000000005555dd55dddd55555555dd55dd
aaaaaa33bbaa99aabbbbbb3300000033bbbbbb000000000000000000bbbb0000000000000000000000000000000000000000005555dd55dddd55555555dd55dd
9988aa3399889933bbbbbb3300330000bbbb00003300aa3300003300bb0000330000aa33aa00aa3300aa003333aa00aa3333000055dd55dddd55555555dd55dd
9988aa3399889933bbbbbb3300330000bbbb00003300aa3300003300bb0000330000aa33aa00aa3300aa003333aa00aa3333000055dd55dddd55555555dd55dd
3344333333443333334433330033aa00000000aa3300000000aa33003300aa3300aa330033000000003333aa0000aa3300aa3300dddddd3333dddddddddddd33
3344333333443333334433330033aa00000000aa3300000000aa33003300aa3300aa330033000000003333aa0000aa3300aa3300dddddd3333dddddddddddd33
33333333333333333333333300003300003300330000330000330000000033000033000000003300003300000033333333330000333333333333333333333333
33333333333333333333333300003300003300330000330000330000000033000033000000003300003300000033333333330000333333333333333333333333
3333bb333333bb333333333333009900aa99aa9900aa9900aa99009999aa9900aa99990000aa9900aa9900dd00aa0000000000dddddd33333333dddddddd3333
3333bb333333bb333333333333009900aa99aa9900aa9900aa99009999aa9900aa99990000aa9900aa9900dd00aa0000000000dddddd33333333dddddddd3333
33333333333333333333333333009988998899000099000099009900009900009900000000990000990000550099880000990055dd55dd3333dddd55dd55dd33
33333333333333333333333333009988998899000099000099009900009900009900000000990000990000550099880000990055dd55dd3333dddd55dd55dd33
33333333333333333333333333008899008899008899008899008899889900889900330088990088990055550000999999880055dd5555dd33dd5555dd5555dd
33333333333333333333333333008899008899008899008899008899889900889900330088990088990055550000999999880055dd5555dd33dd5555dd5555dd
33bb33333333333333bb33333300000000000000000000000000000000000000000033000000000000005555550000000000005555dd55dddddd555555dd55dd
33bb33333333333333bb33333300000000000000000000000000000000000000000033000000000000005555550000000000005555dd55dddddd555555dd55dd
333333333333333333333333333333333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33dd55555555dd55dddd55555555dd55dddd55555555dd55dd
333333333333333333333333333333333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33dd55555555dd55dddd55555555dd55dddd55555555dd55dd
33333333bb3333333333333333bb33333333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33dd55555555dd55dddd55555555dd55dddd55555555dd55dd
33333333bb3333333333333333bb33333333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33dd55555555dd55dddd55555555dd55dddd55555555dd55dd
3333333333333333333333333333333333333333333333333344333333443333334433333344333333dddddddddddd3333dddddddddddd3333dddddddddddd33
3333333333333333333333333333333333333333333333333344333333443333334433333344333333dddddddddddd3333dddddddddddd3333dddddddddddd33
333333333333cccccccccccc33333333333333333333333333bb333333bb333333bb333333bb3333333333333333333333333333333333333333333333333333
333333333333cccccccccccc33333333333333333333333333bb333333bb333333bb333333bb3333333333333333333333333333333333333333333333333333
333333cccccccccccccccccccccc33333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333333333333333333333333333333333333333333333
333333cccccccccccccccccccccc33333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333333333333333333333333333333333333333333333
3333cccccccccccccccccccccccc3333333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555555555555555555555555555555553333
3333cccccccccccccccccccccccc3333333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555555555555555555555555555555553333
33cccccccccccccccccccccccccccc33333333333333333333443333334433333344333333443333333333556655666655666655666666556666665566553333
33cccccccccccccccccccccccccccc33333333333333333333443333334433333344333333443333333333556655666655666655666666556666665566553333
cccccccccccccccccccccccccccccc3333bb33333333333333bb333333bb333333bb333333bb3333333333555555555555555555555555555555555555553333
cccccccccccccccccccccccccccccc3333bb33333333333333bb333333bb333333bb333333bb3333333333555555555555555555555555555555555555553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655666655666666665566665566665566553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655666655666666665566665566665566553333
cccccccccccccccccccccccccccccccc3333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555555555555555555555555555555553333
cccccccccccccccccccccccccccccccc3333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555555555555555555555555555555553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556655333333333333333333333333335566553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556655333333333333333333333333335566553333
cccccccccccccccccccccccccccccccc333333333333333333bb333333bb333333bb333333bb3333333333555555333333333333333333333333335555553333
cccccccccccccccccccccccccccccccc333333333333333333bb333333bb333333bb333333bb3333333333555555333333333333333333333333335555553333
cccccccccccccccccccccccccccccccc3333bb333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655333333334444444433333333335566553333
cccccccccccccccccccccccccccccccc3333bb333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655333333334444444433333333335566553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555333333555555555555333333335555553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555333333555555555555333333335555553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556655333344444444444444443333335566553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556655333344444444444444443333335566553333
cccccccccccccccccccccccccccccccc33bb33333333333333bb333333bb333333bb333333bb3333333333555555333355000000550000553333335555553333
cccccccccccccccccccccccccccccccc33bb33333333333333bb333333bb333333bb333333bb3333333333555555333355000000550000553333335555553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655333344000000440000443333335566553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655333344000000440000443333335566553333
cccccccccccccccccccccccccccccccc33333333bb333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555333355000000555555553333335555553333
cccccccccccccccccccccccccccccccc33333333bb333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555333355000000555555553333335555553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556655333344000000444444443333335566553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556655333344000000444444443333335566553333
cccccccccccccccccccccccccccccccc333333333333333333bb333333bb333333bb333333bb3333333333555555333333333333333333333333335555553333
cccccccccccccccccccccccccccccccc333333333333333333bb333333bb333333bb333333bb3333333333555555333333333333333333333333335555553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655333333333333333333333333335566553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655333333333333333333333333335566553333
cccccccccccccccccccccccccccccccc333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555544333333333333445555555555553333
cccccccccccccccccccccccccccccccc333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555544333333333333445555555555553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556666665544443333333344445566666666553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333556666665544443333333344445566666666553333
cccccccccccccccccccccccccccccccc33bb33333333333333bb333333bb333333bb333333bb3333333333555555555544443333333344445555555555553333
cccccccccccccccccccccccccccccccc33bb33333333333333bb333333bb333333bb333333bb3333333333555555555544443333333344445555555555553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655665544443333333344445566665566553333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333556655665544443333333344445566665566553333
cccccccccccccccccccccccccccccccc3333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555544443333333344445555555555553333
cccccccccccccccccccccccccccccccc3333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333555555555544443333333344445555555555553333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333333333333333443333333344333333333333333333
cccccccccccccccccccccccccccccccc333333333333333333443333334433333344333333443333333333333333333333443333333344333333333333333333
cccccccccccccccccccccccccccccccc333333333333333333bb333333bb333333bb333333bb333333bb333333bb3333333333333333333333bb333333bb3333
cccccccccccccccccccccccccccccccc333333333333333333bb333333bb333333bb333333bb333333bb333333bb3333333333333333333333bb333333bb3333
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333bb333333bb33bbbbbb33bbbbbb33
cccccccccccccccccccccccccccccccc3333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333bb333333bb33bbbbbb33bbbbbb33
cccccccccccccccccccccccccccccc33333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
cccccccccccccccccccccccccccccc33333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
cccccccccccccccccccccccccccccc33333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
cccccccccccccccccccccccccccccc33333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
33cccccccccccccccccccccccccccc3333bb33333333333333bb333333bb333333bb333333bb333333bb333333bb333333bb33333333333333bb333333bb3333
33cccccccccccccccccccccccccccc3333bb33333333333333bb333333bb333333bb333333bb333333bb333333bb333333bb33333333333333bb333333bb3333
33cccccccccccccccccccccccccc33333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
33cccccccccccccccccccccccccc33333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
3333cccccccccccccccccccccc3333333333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb3333333333bb333333bbbbbb33bbbbbb33
3333cccccccccccccccccccccc3333333333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb3333333333bb333333bbbbbb33bbbbbb33
333333cccccccccccccccc3333333333333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
333333cccccccccccccccc3333333333333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
33333333333333333333333333333333333333333333333333bb333333bb333333bb333333bb333333bb333333bb3333333333333333333333bb333333bb3333
33333333333333333333333333333333333333333333333333bb333333bb333333bb333333bb333333bb333333bb3333333333333333333333bb333333bb3333
3333bb333333bb3333333333333333333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
3333bb333333bb3333333333333333333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
3333333333333333333333333333bb33333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333333333bb33bbbbbb33bbbbbb33
3333333333333333333333333333bb33333333333333bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33333333333333bb33bbbbbb33bbbbbb33
33333333333333333333333333333333333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
33333333333333333333333333333333333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
33bb33333333333333bb33333333333333bb33333333333333bb333333bb333333bb333333bb333333bb333333bb333333bb33333333333333bb333333bb3333
33bb33333333333333bb33333333333333bb33333333333333bb333333bb333333bb333333bb333333bb333333bb333333bb33333333333333bb333333bb3333
333333333333333333333333333333333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
333333333333333333333333333333333333333333333333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333333333bbbbbb33bbbbbb33
33333333bb3333333333333333bb33333333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333bb3333bbbbbb33bbbbbb33
33333333bb3333333333333333bb33333333333333bb3333bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb333333333333bb3333bbbbbb33bbbbbb33
33333333333333333333333333333333333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
33333333333333333333333333333333333333333333333333443333334433333344333333443333334433333344333333333333333333333344333333443333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333bb333333bb3333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333bb333333bb3333
33338888888833333333333333333333333333333333333333333333333333333333bb333333bb3333333333333333333333333333333333bbbbbb33bbbbbb33
33338888888833333333333333333333333333333333333333333333333333333333bb333333bb3333333333333333333333333333333333bbbbbb33bbbbbb33
33886688666633333333333333333333333333333333bb33333333333333bb333333333333333333333333333333bb33333333333333bb33bbbbbb33bbbbbb33
33886688666633333333333333333333333333333333bb33333333333333bb333333333333333333333333333333bb33333333333333bb33bbbbbb33bbbbbb33
338866886666333333ff33ff33ff3333333333333333333333333333333333333333333333333333333333333333333333333333333333333344333333443333
338866886666333333ff33ff33ff3333333333333333333333333333333333333333333333333333333333333333333333333333333333333344333333443333
8888888888888888331111111111333333bb33333333333333bb33333333333333bb33333333333333bb33333333333333bb33333333333333bb333333bb3333
8888888888888888331111111111333333bb33333333333333bb33333333333333bb33333333333333bb33333333333333bb33333333333333bb333333bb3333
8888888888888888333311111133333333333333333333333333333333333333333333333333333333333333333333333333333333333333bbbbbb33bbbbbb33
8888888888888888333311111133333333333333333333333333333333333333333333333333333333333333333333333333333333333333bbbbbb33bbbbbb33
885555888855558833334444443333333333333333bb33333333333333bb333333333333bb3333333333333333bb33333333333333bb3333bbbbbb33bbbbbb33
885555888855558833334444443333333333333333bb33333333333333bb333333333333bb3333333333333333bb33333333333333bb3333bbbbbb33bbbbbb33
33555533335555333333443344333333333333333333333333333333333333333333333333333333333333333333333333333333333333333344333333443333
33555533335555333333443344333333333333333333333333333333333333333333333333333333333333333333333333333333333333333344333333443333

__gff__
01000000000000000101207070d494100303200070703021214545c5c5c5c5000303000909090909204444c4c4c4c40003030303030301010101010101000000010100002145454545c5c54141414141014545606060606060000000000000004080000000000000000040800000000000000000000000004080000000000000
192008212145454545c5c541414181000061614545c5c5450531000000000101217070702145454545c5c50000d5d515707030302044444444c4c40000000000000000000000000000000000030921450000000000000040000000c5207021212161614545c5c54040000121012001012145454545c5c5400031010103030303
__map__
1818181818232323001b18181818232323002323232323232323001818181818181819002323232323282323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3d3d1818232323003f3d3d181823232300181818181818232300181011443d23232300181818373d3f4418000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10113e181836393c0010113e181836393c0018102011283d232300182020183e233d2800181011373d3d3d18000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20203f18183728370020203f1818373d3700182020203e3d232300182020183e23232300182020373d3f3d18000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20203d181838b43b0020203d181838b43b00183320343d3f232300182020183d2323230018333438b4393a18000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33343d1818183f180033343d1818183f18001818181818a4182300182020183f3e2323000b3e3d3d3d181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3e3e1818183d18003f3e3e1818183d18003d3d3e3f3d3e181800183334183d3e0bf0003d3d3d3f3d181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3d3d3d3f3d3d2300443d3d3d3f3d3d23000b3e3e3f3e3d3d1900181818183d3d3e3f001918181818181818000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1910202020202011001823232323232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1820202020202020001a232318283e2323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
183320202020203400181823183e3f2323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1818183d3d18181800181823183e3d2323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3d183f3e183f1800181823183f232323000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3d181818183f1800181823183d232344000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3e3d3d3e3d3d2800181823183e233d0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3d3d3d3d3d3e3f001818181818183f3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d28231818181818003d3d3d3d3d3d3d28000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3d23181823181800193d3d3d3d3d3d3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2318231823181818001818f0f0f0f0f03d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
231823231818181800181818f03d3d3d3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
231823191818181800444444f044444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
23182323233d3d3f003d3d3d3d3d3d3d3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18183e3f3d3d0b3d003d3d3d3d3d3d3d3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3d3d3d3f3d3e3d000b3d3d3d3d3d3d3d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010600001c01128011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002f015300152d01528015300152d01529015280152d0152b0152d015290152d015280152b0152d0152f015300152d015340152f015320152d015300152b0152d015280152901526015280152401526015
011000002301524015210151c01524015210151d0151c0151f0151c015210151d015230151c0151f0152301524012240122401224015210051d00523005210052400523005260052400528005260052b00528005
011000000e150000000e150000000c1500000009150000000e150000000e150000000c1500000009150000000b150000000c1500000010150000000e150000000c150000000b1500000009150000000b15000000
010b00000c04018041180020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0000130400c041180020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e00001c0521c0521d0551d0521c050000001d050000001a050000001800000000170000000018000000001c0521c0521d0551d0521c050000001d050000001805000000180000000000000000000000000000
010c0000006110c6111861100611006110c6111861100611006110c611186110061100611006110c61100611006110c611186110061100611006110c61118611006110c611186110c61100611006110061100611
010e00002875428752287522875229752297522975229752267512675126751267512675126751267512675128754287522875228752297522975229752297522475124751247512475124751247512475124751
011000001c6711a6711a66118651106210c6010c60200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002d0552b0052b0552d05500000000002d055000002d055000002b0552d055000000000024055260552805529005280550000029055280552605524055000000000021005000001f005000002100500000
011000000c0330c6250c605306051c625000000c0330c6250c0330c6250c605000001c62500000000000c6250c0330c62500000000001c625000000c0330c6250c0330c6250c033000000c625000000000000000
011000000c145151050000000000101451014500000111451314500000131451814500000151051514513145111450000015105151051514515145181051714518145000001a1451d14500000000001810511145
011000000c145000000000000000101451014500000111451314500000131451814500000000000000000000111450000015105151051514515145181051714518145000001a1451d14500000000000000000000
01100000210552b0051f055210550000000000210550000021055000001f05521055000000000024055260552805529005280550000029055280552605524055000000000021005000001f005000002100500000
01100000131450000000000000001714517145000001c1451d145000001c1451a14500000151051c1451a14518145000001510515105151451814518105151451314511145101450e1450c145000000000000000
011000000c245006000c345000000c445000000c345000000c245000000c345000000c445000000c3450000005245000000534500000054450000005345000000524500000053450000005445000000534500000
01100000002450060000345000000044500000003450000000245000000034500000004450000000345000000524500000053450000005445000000534500000052450000005345000000544500000053450c105
011000000724500600073450c105074450c105073450000007245000000734500000074450000007345000000024500000003450000000445000000034500000002450000000345000000044500000003450c105
011000000724500600073450c105074450c105073450000007245000000734500000074450000007345000000c245000000c345000000c445000000c345000000c245000000c345000000c445000000c3450c105
011000001f0552b0051d0551f05500000000001f055000001f055000001d0551f05500000000001f0551d05518055290051c055000001d0551f0552305524055000000000021005000001f005000002100500000
011000000c0430c6350c6050c0431c635000000c0430c6350c0430c6350c6050c0431c63500000000000c6350c0430c63500000000001c635000000c0430c6350c0430c6350c043000000c6350c0130c0230c033
011000000c0430c6350c6050c0431c635000000c0430c6350c0430c6350c6050c0431c63500000000000c6350c0430c63500000000001c635000000c0430c6350c0430c6350c043000000c6350c0030c0030c635
011000000c0430c6350c6050c0431c635000000c0430c6350c0430c6350c6050c0431c63500000000000c6350c0430c63500000000001c635000000c0430c6350c0430c6350c043000000c6350c6150c6250c635
011000000c0430c6350c6050c0431c635000000c0430c6350c0430c6350c6050c0431c6251c6251c6250c6350c0430c63500000000001c635000000c0430c6350c0430c6350c043000000c6350c6350c6050c635
011000000c0430c6050c6050c0431c635000000c0030c6350c0430c6050c6050c0431c63500000000000c6050c0430c60500000000001c635000000c0430c6350c0430c6350c043000000c6350c0030c0030c003
011000000c0430c6050c6050c0431c635000000c0030c6050c0030c6050c6050c0431c63500000000000c6050c0430c60500000000001c635000000c0430c6350c0430c6350c043000000c6350c0030c0030c003
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002a7552a750000002a750000002a7552a7522a7522a7522a7022a7552a7552a7552a705000000000025755257500000025750000002575525752257522575200000257552575525755257020000000000
011000002375523750000002375000000237552375223752237522a7022375523755237552a705000000000028755287500000028750000002875528752287522875200000287552875528755257020000000000
011000001e050000001f050000001e050000002105000000230500000022050000001f050000001e050000001c050000001e050000001c050000001f050000001e050000001f0500000021050000002305000000
011000001e050000001f050000001e050000002105000000230500000022050000001f050000001e050000001c050000001e050000001c050000001f050000001e050000001c0501e0001a050000001c05000000
011000001b0501a0001c050000001e0500000021050000001e050000001c050000001a050000001c050000001c050000001e050000001f0500000021050000002505000000210501e0001f050000001e05000000
011000001e0501d052000001c050000001a0501c052000000000000000000001d0001d0501e0511e0021e0021a0501c0520000019050150001705015050130501205015002120500000012050180510000000000
01100000130501300013055130501d0501c0501b0501a0501100000000110051100011050110001105511050130500000013055130501d0501f0501a050180500000000000000000000016050160001605516050
__music__
01 01454346
04 02454347
00 07060844
03 584e0c50
01 180e0c10
00 17140f12
00 19545311
00 19545312
00 19545310
00 1a545313
00 180e0c10
02 17140f12
00 41424344
00 41424344
01 1e0b2144
02 1f0b2244
03 24166144

