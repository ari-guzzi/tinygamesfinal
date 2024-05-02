--variables

function _init()
  --game basics
  reload(0x2000, 0x2000, 0x1000)
  coins_collected = 0
  game_over = false
  win_game = false
  make_player()
  player.health = 99 
  max_health = 99
  health_bar_width = 50 -- width of the health bar
  health_bar_height = 5 -- height of the health bar      
  title = true
  timer=0
  gravity=0.3
  friction=0.85
  zeppelin_active = false
  teleported = false
  zeppelin_alive = false
  --drawing
  populate_stars()
  draw_title()
  projectiles = {}
  effects = {}
  store_coin_tiles() 
  reset_coin_tiles()
  --simple camera
  cam_x=0
  y_camera = -5
  --map limits
  map_start=0
  map_end=1024
  map_top = 0
  map_bottom = 1024
  score = 0
  -- enemies
  enemies = {}
  add(enemies, {
  x = 70,
  y = 59,
  w = 8,
  h = 8,
  dx = -1,
  dy = 0,
  speed = 1,
  flp = true
})
setup_enemy_spawn()
  -- make zepplin
  zeppelin = {
  x = -5,  
  y = 21, 
  w = 16,
  h = 16,
  sprites = {69, 70, 85, 86}, -- 2x2 sprite numbers
  speed = 0.5,
  dx = 1,  
  limit_left = 0,  -- left boundary for movement
  limit_right = 248,
  bomb_timer = 0,
  bomb_interval = 2,  
  direct_bomb_timer = 0,
  direct_bomb_interval = 1,
  health = 99,
  max_health = 99,
  health_bar_width = 50,
  flp = true
  }
end

-- Basic set up functions

function wait(a)
  for i = 1, a do
    flip()
  end
end
  
function draw_title()
  spr(128, 32, 35, 8, 4) --sprite, x, y, length, height
  spr(139, 50, 65, 4, 4) --top of jakson square
  spr(64, 50, 97, 4, 4) -- bottom of jackson square
  spr(192, 20, 112, 2, 2) -- top of white building
  spr(194, 20, 96, 2, 2) -- bottom of white building
  spr(224, 36, 108, 2, 2) -- lamp
  spr(196, 105, 112, 2, 2) -- top of blue building
  spr(198, 105, 96, 2, 2) -- bottom of blue building
  spr(200, 89, 112, 2, 2) -- top of purple building
  spr(202, 89, 96, 2, 2) -- bottom of purple building
  spr(39, 5, 67, 2, 2) -- front of trolley
  spr(168, 21, 67, 2, 2) -- back of trolley

end

  function make_player()
    player={}
    player.sp=1
    player.x=59
    player.y=59
    player.w=8
    player.h=8
    player.flp=false
    player.dx=0
    player.dy=0
    player.max_dx=2
    player.max_dy=3
    player.acc=0.5
    player.boost=4
    player.anim=0
    player.running=false
    player.jumping=false
    player.falling=false
    player.sliding=false
    player.landed=false
    player.invincible = true
    player.invincible_time = 30 
    player.invincible_timer = 30
  end

  function setup_enemy_spawn()
    spawn_timer = 0
    spawn_interval = 3.5  -- seconds between spawns
  end

  --update
  
  function _update()
    -- simple camera
    cam_x = player.x - 64 + (player.w / 2)
    cam_x = max(cam_x, map_start)
    cam_x = min(cam_x, map_end - 128)
    if teleported == true then
    camera(cam_x, y_camera)
  else
      camera(cam_x, 0)
  end
  --title state
  if title then
    timer = (timer + 1) % 60
  if btn(4) and timer>30 then
    timer=0
    title = false
    sfx(11)
    music(0)
  end
 else
     if not game_over then
      player_update()
      player_animate()
      update_enemies()
      check_collision_with_enemies()
      check_collision_with_coins()
      teleport()
      update_camera()
      check_collision_with_projectiles()
      if zeppelin_active then
        update_zeppelin()
    end
      foreach(projectiles, function(proj)
        proj.y += proj.dy
    end)
      local player_tile_x = flr((player.x + player.w / 2) / 8)
      local player_tile_y = flr((player.y + player.h / 2) / 8)
  
      if mget(player_tile_x, player_tile_y) == 22 then  -- check if the player is on a death sprite
          game_over = true
      end


    foreach(effects, function(effect)
      effect.timer -= 1
      if effect.timer <= 0 then
          del(effects, effect)
      end
  end)

      spawn_timer += 1/15  -- assuming 15 fps
      if spawn_timer >= spawn_interval then
          spawn_enemy()
          spawn_timer = 0
      end

      
  if game_over and not win_game then
    sfx(6)  -- the game over sound
    wait(1) 
  end

  if game_over and win_game then
    sfx(7)  -- the win game sound
    wait(1) 
  end
    
    else
        if btnp(4) then  
            _init()  -- reset the game by re-initializing
        end  
    end  
end 
end 
---------DRAW FUNCTION------------------------------------------------
function _draw()
  if title then
    cls(1)
    camera(0,0)
    --title screen
    draw_title()	
    print('use arrow keys to play',20,10,7)
    if (timer % 60) < 30 then
    print('press z to start',32,20,7)
    end
    rect(0,0,127,127,12)
  else
  cls(1)
  
  if teleported and zeppelin_active then
    -- test coordinates
    y_camera = 136
    camera(cam_x, y_camera)
    draw_zeppelin()
    draw_zeppelin_health_bar()
    foreach(projectiles, function(p) spr(p.sprite, p.x, p.y) end)
else
    camera(cam_x, 0)
end
  --camera(0, 0)
  draw_health_bar()
  foreach(projectiles, function(proj)
    spr(proj.sprite, proj.x, proj.y)
end)

  map(0,0)
  foreach(effects, function(effect)
    spr(effect.sprite, effect.x, effect.y)
end)
  if not player.invincible or (player.invincible_timer / 2) % 2 == 0 then
    spr(player.sp, player.x, player.y, 1, 1, player.flp)
end
-- teleporting message
 if teleport_message and teleport_message_timer > 0 then
  print(teleport_message, cam_x +15, 15, 7)  -- adjust position and color as needed
  teleport_message_timer -= 1  -- decrement the timer
else
  teleport_message = nil  -- clear the message after time expires
end

  foreach(enemies, function(e)
      --spr(25, e.x, e.y)  
      spr(25, e.x, e.y, 1, 1, e.flp, false)
  end)
  
  camera(0, 0)
  local grade = "f"
  if score >= 0 and score < 500 then
      grade = "d"
  elseif score >= 500 and score < 1000 then
      grade = "c"
  elseif score >= 1000 and score < 1500 then
      grade = "b"
  elseif score >= 1500 then
      grade = "a"
  end
  
  if game_over then
    if win_game then
      print("you win!", 44, 44, 9)
      print("your score: " .. score, 34, 54, 9)
      print("grade:" .. grade, 36, 63, 9)
      print("press z to replay!", 18, 72, 9)
    else
      print("game over!", 44, 44, 7)
      print("your score: " .. score, 34, 54, 7)
      print("press z to play again!", 18, 72, 7)
    end
  end
    print("teas:" .. coins_collected, 0, 6, 7)
    print("score:" .. score, 0, 0, 7)
--end

end
end
  
function populate_stars()
  local star_sprite = 104  -- the sprite number for your star
  local map_width = 128    -- width of the map
  local map_height = 32    -- height of the map area for stars
  local density = 0.05     -- increased density of stars
  local empty_tile = 0     -- assuming 0 is the index for an empty tile

  for x = 0, map_width - 1 do
      for y = 0, map_height - 1 do
          if rnd() < density and mget(x, y) == empty_tile then
              mset(x, y, star_sprite)  -- place star sprite only in empty tiles
          end
      end
  end
end


function collide_map(obj,aim,flag)
  --obj = table needs x,y,w,h
  --aim = left,right,up,down
 
  local x=obj.x  local y=obj.y
  local w=obj.w  local h=obj.h
 
  local x1=0	 local y1=0
  local x2=0  local y2=0
 
  if aim=="left" then
    x1=x-1  y1=y
    x2=x    y2=y+h-1
 
  elseif aim=="right" then
    x1=x+w-1    y1=y
    x2=x+w  y2=y+h-1
 
  elseif aim=="up" then
    x1=x+2    y1=y-1
    x2=x+w-3  y2=y
 
  elseif aim=="down" then
    x1=x+2      y1=y+h
    x2=x+w-3    y2=y+h
  end
 
  --pixels to tiles
  x1/=8    y1/=8
  x2/=8    y2/=8
 
  if fget(mget(x1,y1), flag)
  or fget(mget(x1,y2), flag)
  or fget(mget(x2,y1), flag)
  or fget(mget(x2,y2), flag) then
    return true
  else
    return false
  end
 
 end
  
  --player
  
  function player_update()
    --physics
    player.dy+=gravity
    player.dx*=friction
    if player.invincible then
      player.invincible_timer -= 1
      if player.invincible_timer <= 0 then
          player.invincible = false  -- turn off invincibility when timer runs out
      end
  end
    --controls
    if btn(⬅️) then
      player.dx-=player.acc
      player.running=true
      player.flp=true
    end
    if btn(➡️) then
      player.dx+=player.acc
      player.running=true
      player.flp=false
    end
  
    --slide
    if player.running
    and not btn(⬅️)
    and not btn(➡️)
    and not player.falling
    and not player.jumping then
      player.running=false
      player.sliding=true
    end
  
    --jump
    --jump
if btnp(2) and player.landed then
    player.dy -= player.boost
    player.landed = false
    sfx(2)  -- play the jump sound effect
  end
  
    --check collision up and down
    if player.dy>0 then
      player.falling=true
      player.landed=false
      player.jumping=false
  
      player.dy=limit_speed(player.dy,player.max_dy)
  
      if collide_map(player,"down",0) then
        player.landed=true
        player.falling=false
        player.dy=0
        player.y-=((player.y+player.h+1)%8)-1
      end
    elseif player.dy<0 then
      player.jumping=true
      if collide_map(player,"up",1) then
        player.dy=0
      end
    end
  
    --check collision left and right
    if player.dx<0 then
  
      player.dx=limit_speed(player.dx,player.max_dx)
  
      if collide_map(player,"left",1) then
        player.dx=0
      end
    elseif player.dx>0 then
  
      player.dx=limit_speed(player.dx,player.max_dx)
  
      if collide_map(player,"right",1) then
        player.dx=0
      end
    end
  
    --stop sliding
    if player.sliding then
      if abs(player.dx)<.2
      or player.running then
        player.dx=0
        player.sliding=false
      end
    end
  
    player.x+=player.dx
    player.y+=player.dy
  
    --limit player to map
    if player.x<map_start then
      player.x=map_start
    end
    if player.x>map_end-player.w then
      player.x=map_end-player.w
    end
  end
  
  function player_animate()
        if player.jumping then
            player.sp = 7
        elseif player.falling then
            player.sp = 8
        elseif player.sliding then
            player.sp = 9
        elseif player.running then
            if time() - player.anim > 0.1 then
                player.anim = time()
                player.sp += 1
                if player.sp > 6 then
                    player.sp = 3
                end
            end
        else -- player idle
            if time() - player.anim > 0.3 then
                player.anim = time()
                player.sp += 1
                if player.sp > 2 then
                    player.sp = 1
            end
        end
    end
end

  
  function limit_speed(num,maximum)
    return mid(-maximum,num,maximum)
  end


  function spawn_enemy()
    local spawn_x = cam_x + 200  -- spawn to the right of the visible screen
    local spawn_y = -16  -- start above the top of the visible screen
    local initial_dx = -1  -- moving left
    local initial_flp = true 
    add(enemies, {
        x = spawn_x,
        y = spawn_y,
        w = 8,
        h = 8,
        dx = initial_dx,
        dy = 0,
        speed = 1,
        falling = true,
        flp = initial_flp
    })
end



function check_collision_with_enemies()
  foreach(enemies, function(enemy)
      -- check if player collides with enemy
      if (player.x < enemy.x + enemy.w) and (player.x + player.w > enemy.x) and
         (player.y < enemy.y + enemy.h) and (player.y + player.h > enemy.y) then
          
          -- check for bottom collision (player defeats the enemy)
          if (player.dy > 0 and player.y + player.h < enemy.y + enemy.h / 2)  then
              -- optional: defeat the enemy, make it disappear or deactivate
              add(effects, {
                x = enemy.x,
                y = enemy.y,
                sprite = 26,
                timer = 30  -- number of frames to display the effect
            })
              del(enemies, enemy)  -- removes the enemy from the list
              sfx(5) --noise when squish enemy
              score += 100
              if score % 500 == 0 and player.health != 99 then
                player.health += 33
                add(effects, {
                  x = player.x + player.w/2 - 4,  -- Center the sprite above the player (assuming sprite width of 8px)
                  y = player.y - 8,  -- Position above the player
                  sprite = 38,
                  timer = 20  -- Duration the sprite should appear (e.g., 60 frames)
              })
              end
          else
            if not player.invincible then
              player.health = (player.health - 33)  -- deduct 1/3 of max_health
              sfx(1) --noise when hurt
              if player.health <= 0 then
                  game_over = true
              else
                  player.invincible = true
                  player.invincible_timer = player.invincible_time
              end
          end
      end
  end
end)
end


function update_enemies()
  foreach(enemies, function(enemy)
      -- always apply gravity to handle vertical movement
      enemy.dy += gravity
      enemy.y += enemy.dy

      -- check if the enemy is currently supported by the ground
      if collide_map({x = enemy.x, y = enemy.y, w = enemy.w, h = enemy.h}, 'down', 0, 1) then
          if enemy.falling then
              enemy.dy = 0  -- stop vertical movement if on ground
              --enemy.falling = false
              enemy.y = flr(enemy.y / 8) * 8  -- snap to grid to align after landing
          end
      else
          enemy.falling = true  -- start falling if no ground is detected below
      end

            -- calculate next horizontal position
      local next_x = enemy.x + enemy.dx * enemy.speed

      -- check for wall collisions and reverse direction if necessary
      if collide_map({x = next_x, y = enemy.y, w = enemy.w, h = enemy.h}, enemy.dx > 0 and 'right' or 'left', 1) then
          enemy.dx = -enemy.dx  -- reverse direction on collision
          enemy.flp = (enemy.dx < 0)  -- update orientation immediately when direction changes
      else
          enemy.x = next_x  -- update horizontal position if no collision
      end
      enemy.flp = (enemy.dx < 0)  -- update sprite flip based on direction regardless of collision

  end)
end

function draw_health_bar()
  local screen_width = 128 
  local margin = 5          -- Margin from the screen edge
  local heart_width = 8     -- Assuming each heart sprite is 8 pixels wide
  local spacing = 2         -- Space between hearts

  -- Calculate the x position of the health bar based on the camera position
  local bar_x = cam_x + screen_width - (3 * heart_width) - (2 * spacing) - margin
  local bar_y = y_camera + 10  -- y-coordinate of the top right corner of the health area

  -- Determine the number of full hearts to draw based on player health
  local full_hearts = flr(player.health / 33)
  local empty_hearts = 3 - full_hearts

  -- Draw filled hearts
  for i = 0, full_hearts - 1 do
      spr(102, bar_x + (i * (heart_width + spacing)), bar_y)  -- Sprite 102 for filled heart
  end

  -- Draw empty hearts
  for i = full_hearts, full_hearts + empty_hearts - 1 do
      spr(101, bar_x + (i * (heart_width + spacing)), bar_y)  -- Sprite 101 for empty heart
  end
end


  original_coin_tiles = {}
function store_coin_tiles()
    for i=0,127 do
        for j=0,127 do
            if mget(i, j) == 37 then  -- assuming 37 is the coin sprite index
                add(original_coin_tiles, {x=i, y=j, sprite=37})
            end
        end
    end
end

-- reset coin tiles during game restart
function reset_coin_tiles()
    foreach(original_coin_tiles, function(tile)
        mset(tile.x, tile.y, tile.sprite)
    end)
end

  -- boss level thngs
  
  function teleport()
    local player_tile_x = flr((player.x + player.w / 2) / 8)
    local player_tile_y = flr((player.y + player.h / 2) / 8)

    -- check if the player is standing on a tile with the coin sprite (sprite 37)
    if ((mget(player_tile_x, player_tile_y) == 56) or (mget(player_tile_x, player_tile_y) == 184)) then
        if coins_collected < 5 then
          teleport_message = "get more tea to be\n allowed on the trolley"
            teleport_message_timer = 120  -- display for 2 seconds, assume 60 fps
        else
          zeppelin_alive = true
          teleported = true
        zeppelin_active = true
        player.x = 5 * 8
        player.y = 30 * 8
        --zeppelin.x = player.x - 20  -- start the zeppelin relative to the new player position
        zeppelin.y = player.y - 105
        update_camera()
        end
    end
end


  function update_camera()
    -- simple camera follow logic
    cam_x = player.x - 64 + (player.w / 2)
    cam_x = max(cam_x, map_start)
    cam_x = min(cam_x, map_end - 128)

    cam_y = player.y - 64 + (player.h / 2) - 48
    cam_y = max(cam_y, map_top)
    cam_y = min(cam_y, map_bottom - 128)  -- assuming the screen height is 128 pixels

    -- set camera position
    camera(cam_x, cam_y)
end

  function check_collision_with_coins()
    local player_tile_x = flr((player.x + player.w / 2) / 8)
    local player_tile_y = flr((player.y + player.h / 2) / 8)

    -- check if the player is standing on a tile with the coin sprite (sprite 37)
    if mget(player_tile_x, player_tile_y) == 37 then
        -- collision detected with coin (sprite 37)
        mset(player_tile_x, player_tile_y, 0)  -- update the map tile to a blank tile
        coins_collected += 1  -- increment collected coins count
        sfx(4)  -- play a sound effect indicating coin collection
    end
end
-- zepplin things
function update_zeppelin()
  -- update the position based on dx
  zeppelin.x += zeppelin.dx

if zeppelin_alive == true then
  -- check boundaries and reverse direction if necessary
  if zeppelin.x >= zeppelin.limit_right or zeppelin.x <= zeppelin.limit_left then
      zeppelin.dx = -zeppelin.dx  -- reverse the direction
      zeppelin.flp = (zeppelin.dx < 0)  -- toggle the flip flag when changing direction
      -- make sure the zeppelin doesn't go past the boundary
      zeppelin.x = mid(zeppelin.limit_left, zeppelin.x, zeppelin.limit_right)
  end
  zeppelin.flp = (zeppelin.dx < 0)

-- direct bombing logic in update_zeppelin()
zeppelin.direct_bomb_timer += 1/30
if abs(zeppelin.x + zeppelin.w/2 - player.x) < 10 then
  if zeppelin.direct_bomb_timer >= zeppelin.direct_bomb_interval then
      drop_bomb(zeppelin.x + zeppelin.w/2, zeppelin.y + zeppelin.h)
      zeppelin.direct_bomb_timer = 0
  end
end
end
end

function drop_bomb(x, y)
  local target_x, target_y

  -- common target settings for both moving and stationary player
  target_x = player.x + (player.w / 2) -- center the target horizontally on the player
  target_y = player.y + (player.h / 2) -- center the target vertically on the player

  -- calculate the differences in x and y positions
  local target_dx = target_x - x
  local target_dy = target_y - y

  -- determine the bomb's speed
  local bomb_speed = 3  -- vertical speed of the bomb

  -- ensure there is no division by zero in vertical distance
  if target_dy == 0 then
    target_dy = 1
  end

  -- calculate the time to impact based on bomb speed
  local time_to_impact = abs(target_dy) / bomb_speed

  -- calculate horizontal speed to align the bomb's landing with the target time to impact
  local horizontal_speed = target_dx / time_to_impact

  -- if the player is directly under the zeppelin and moving very little or not at all
  if abs(player.dx) < 1 and abs(zeppelin.x + zeppelin.w/2 - target_x) < 10 then
    -- adjust the initial x position of the bomb to be directly over the player
    x = target_x
    horizontal_speed = 0  -- no horizontal movement needed if directly overhead
  end

  add(projectiles, {   -- create the bomb with the adjusted trajectory
    x = x,
    y = y,
    dx = horizontal_speed,
    dy = bomb_speed,
    w = 3,
    h = 3,
    sprite = 72  -- bomb sprite
  })
end






function check_collision_with_projectiles()
  foreach(projectiles, function(proj)
      -- check if the projectile collides with the player
      if (player.x < proj.x + proj.w) and (player.x + player.w > proj.x) and
         (player.y < proj.y + proj.h) and (player.y + player.h > proj.y) then
          
          if not player.invincible then  -- handle the collision by reducing the player's health
              player.health = (player.health - 33)  -- deduct health for projectile hit
              sfx(1) -- sound effect when hurt
              if player.health <= 0 then
                  game_over = true
              else
                  player.invincible = true
                  player.invincible_timer = player.invincible_time
              end
              
              del(projectiles, proj)-- remove the projectile upon hitting the player
          end
      end

       -- check collision with map tiles (target sprite 10)
          local tile_x = flr(proj.x / 8)
          local tile_y = flr(proj.y / 8)
          if mget(tile_x, tile_y) == 10 then
              mset(tile_x, tile_y, 0)  -- clear the tile
              add(effects, {
                x = proj.x,
                y = proj.y,
                sprite = 42,
                timer = 30  -- number of frames to display the effect
            })
              del(projectiles, proj)
              zeppelin.health -= 33  -- reduce zeppelin health
              sfx(5)
              if zeppelin.health <= 0 then
                zeppelin.sprites = {42, 42, 42, 42}

                win_game = true
                game_over = true
                
                zeppelin_alive = false
                
              end
          end
  end)
end




function draw_zeppelin_health_bar()
  local screen_width = 128
  local margin = 32
  local bar_x = cam_x + screen_width - health_bar_width - margin 
  local bar_y = y_camera + 112  
  local health_percentage = zeppelin.health / zeppelin.max_health
  local bar_length = flr(zeppelin.health_bar_width * health_percentage)

  rectfill(bar_x, bar_y, bar_x + zeppelin.health_bar_width, bar_y + 5, 12)-- draw the background of the health bar
  rectfill(bar_x, bar_y, bar_x + bar_length, bar_y + 5, 9)  -- draw the health bar

end


function spawn_projectile(x, y)
  add(projectiles, {
      x = x,
      y = y,
      dx = 0,
      dy = 2,
      w = 3,
      h = 3,
      sprite = 72 
  })
end

function draw_zeppelin()
  local flip_sprite = zeppelin.flp

  if flip_sprite then
    -- draw the sprite segments flipped
    spr(zeppelin.sprites[2], zeppelin.x, zeppelin.y, 1, 1, flip_sprite) -- top right goes to top left
    spr(zeppelin.sprites[1], zeppelin.x + 8, zeppelin.y, 1, 1, flip_sprite) -- top left goes to top right
    spr(zeppelin.sprites[4], zeppelin.x, zeppelin.y + 8, 1, 1, flip_sprite) -- bottom right goes to bottom left
    spr(zeppelin.sprites[3], zeppelin.x + 8, zeppelin.y + 8, 1, 1, flip_sprite) -- bottom left goes to bottom right
  else
    -- draw the sprite segments normally
    spr(zeppelin.sprites[1], zeppelin.x, zeppelin.y, 1, 1, flip_sprite) -- top left
    spr(zeppelin.sprites[2], zeppelin.x + 8, zeppelin.y, 1, 1, flip_sprite) -- top right
    spr(zeppelin.sprites[3], zeppelin.x, zeppelin.y + 8, 1, 1, flip_sprite) -- bottom left
    spr(zeppelin.sprites[4], zeppelin.x + 8, zeppelin.y + 8, 1, 1, flip_sprite) -- bottom right
  end
end





----------------------------------
