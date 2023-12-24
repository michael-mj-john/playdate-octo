import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/crank"

local gfx <const> = playdate.graphics

-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local playerSprite = {}
local playerVelocity = nil
local playerRotationalVelocity = nil
local rotationCooldown = nil
local rotationCooldownTimer = nil
local bubleSound = nil

-- array to hold frames of sprite animation
local playerImage = {}

-- boost meter
local boostMeter = nil

-- A function to set up our game environment.

function myGameSetUp()

    playerImage[0] =  gfx.image.new("Images/octopus3_48x64_01.png")
    assert( playerImage[0] ) -- make sure the image was where we thought
    playerImage[1] = gfx.image.new("Images/octopus3_48x64_extended.png")
    assert( playerImage[1])

    playerSprite = gfx.sprite.new( playerImage[0] )
    playerSprite:moveTo( 200, 120 ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    playerSprite:add() -- This is critical!

    bubbleSound = playdate.sound.sampleplayer.new("sounds/bubble_01.wav")

    playerVelocity = playdate.geometry.vector2D.new(0, 0)
    playerRotationalVelocity = 0 -- will represent degrees per frame (positive or negative)
    rotationCooldown = 0
    rotationCooldownTimer = 0

    boostMeter = 0

    local backgroundImage = gfx.image.new( "Images/kelp_400x240_background" )
    assert( backgroundImage )

    gfx.sprite.setBackgroundDrawingCallback(
        function( x, y, width, height )
            -- x,y,width,height is the updated area in sprite-local coordinates
            -- The clip rect is already set to this area, so we don't need to set it ourselves
            backgroundImage:draw( 0, 0 )
        end
    )

end

myGameSetUp()


function playdate.update()

  local buttonIsDown

  -- take input and apply to player.
  buttonIsDown = getInput()

  -- function to rotate back to vertical
  rotateToVertical(buttonIsDown)

  movePlayer() 

  -- updates all sprites
  gfx.sprite.update()
--    playdate.timer.updateTimers()

  -- boost meter test
  playdate.graphics.fillRect(10,10,boostMeter,10)
  if boostMeter > 0 then
--    boostMeter -= 0.6
  end

end

function getInput()

    -- Poll the d-pad and set movement vectors.
    local buttonIsDown = false
    local rotationMax = 10

    --separate logic for sound fx
    if playdate.buttonJustPressed(playdate.kButtonA) then
      playSound("burst")
    end

    if playdate.buttonIsPressed( playdate.kButtonRight ) then
      if math.abs(playerRotationalVelocity) < rotationMax then
        playerRotationalVelocity += 1
      end
      buttonIsDown = true
    end

    if playdate.buttonIsPressed( playdate.kButtonLeft ) then
      if math.abs(playerRotationalVelocity) < rotationMax then
        playerRotationalVelocity -= 1
      end
      buttonIsDown = true
    end

    if playdate.buttonIsPressed( playdate.kButtonA ) then
      local angle = playerSprite:getRotation()
      local pushAmount = 0.25
      local boostMax = 400
      local boostMaxProportion = 70
      local boost = boostMeter / boostMax
      if boost > 0 then
        local boostAmount = 1 + boost * boostMaxProportion
        print(boostAmount)
        pushAmount *= boostAmount
      end
      local accelerationVector = playdate.geometry.vector2D.newPolar(pushAmount, angle)
      playerVelocity:addVector( accelerationVector )
      playerSprite:setImage(playerImage[1])
      boostMeter = 0
      buttonIsDown = true
    end

    if (playdate.buttonJustReleased(playdate.kButtonRight) or playdate.buttonJustReleased(playdate.kButtonLeft) ) then
      playerRotationalVelocity = 0
      rotationCooldown = 100
    end

    if playdate.buttonJustReleased(playdate.kButtonA) then
      playerSprite:setImage(playerImage[0])
    end

    if playdate.buttonIsPressed( playdate.kButtonB ) then
      playerSprite:moveTo(200,120)
      playerVelocity:scale(0)
    end

    boostMeter += playdate.getCrankTicks(36)


  return buttonIsDown

end

function rotateToVertical(buttonIsDown)

  local currentRotation = playerSprite:getRotation()

  -- don't mess with any of this if the octo is vertical, or player is still pressing the button
  if math.abs(currentRotation) < 20 then
    return
  end

  if buttonIsDown then
    return
  end

  -- if no button is down and octo is not vertical but rotation continues, then decelerate rotation
  if rotationCooldown > 1 then
    rotationCooldown -= 1
    if(playerRotationalVelocity < 0 ) then
      playerRotationalVelocity += 1.5
    else 
      playerRotationalVelocity -= 1.5
    end
    if math.abs(playerRotationalVelocity) < 2 then
      playerRotationalVelocity = 0
      return
    end
  end

  --start to return the octo to vertical orientation
  --don't do this if it's upside-down. It looks weird
  if currentRotation < 90 or currentRotation > 270 then
    if currentRotation > 180 then
      local rotationPercent = (359-currentRotation) / 180
      playerRotationalVelocity = 2 * rotationPercent
    end
    if currentRotation < 180 then
      local rotationPercent = currentRotation / 180
      playerRotationalVelocity = 2 * rotationPercent * -1
    end
  end

end

function movePlayer() 

   -- apply rotation
   local currentRotation = playerSprite:getRotation()
   currentRotation += playerRotationalVelocity
   playerSprite:setRotation(currentRotation)

  -- test for hitting the edges of the screen
  if playerSprite.x < 20 then
    playerSprite:moveTo(23, playerSprite.y)
    playerVelocity:scale(0)
    return
  end
  if playerSprite.y > 220 then
    playerSprite:moveTo(playerSprite.x, 218)
    playerVelocity:scale(0)
    return
  end
  if playerSprite.y < 20 then
    playerSprite:moveTo(playerSprite.x, 22)
    playerVelocity:scale(0)
    return
  end
  if playerSprite.x > 372 then
    playerSprite:moveTo(370, playerSprite.y)
    playerVelocity:scale(0)
  end

  -- clamp movement speed
  if playerVelocity:magnitude() > 20 then
    playerVelocity:normalize()
    playerVelocity:scale(20)
  end

  -- move player according to current velocity vector
  playerSprite:moveBy(playerVelocity.x,playerVelocity.y)

  --simple function to add friction
  if playerVelocity:magnitude() > 0 then
    playerVelocity:scale(0.93)
  end


end

function  playSound( soundString )
  if( soundString == "burst") then
    bubbleSound:playAt(0)
  end

end

function beginRotation()


end

