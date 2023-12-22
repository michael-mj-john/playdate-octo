import "CoreLibs/graphics"
import "CoreLibs/sprites"

local gfx <const> = playdate.graphics

-- Here's our player sprite declaration. We'll scope it to this file because
-- several functions need to access it.

local playerSprite = nil
local playerVelocity = nil
local playerRotationalVelocity = nil
local rotationCooldown = nil
local rotationCooldownTimer = nil
-- A function to set up our game environment.

function myGameSetUp()

    local playerImage = gfx.image.new("Images/octoSprite_001_48x48")
    assert( playerImage ) -- make sure the image was where we thought

    playerSprite = gfx.sprite.new( playerImage )
    playerSprite:moveTo( 200, 120 ) -- this is where the center of the sprite is placed; (200,120) is the center of the Playdate screen
    playerSprite:add() -- This is critical!

    playerVelocity = playdate.geometry.vector2D.new(0, 0)
    playerRotationalVelocity = 0 -- will represent degrees per frame (positive or negative)
    rotationCooldown = 0
    rotationCooldownTimer = 0

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
  
    gfx.sprite.update()
--    playdate.timer.updateTimers()

end

function getInput()

    -- Poll the d-pad and set movement vectors.
    local buttonIsDown = false
    local rotationMax = 10

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
      local accelerationVector = playdate.geometry.vector2D.newPolar(0.15, angle)
      playerVelocity:addVector( accelerationVector )
      buttonIsDown = true
    end

    if playdate.buttonJustReleased(playdate.kButtonRight) then
      rotationCooldown = 100
    end

    if playdate.buttonIsPressed( playdate.kButtonB ) then
      playerSprite:moveTo(200,120)
    end

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
  if currentRotation > 180 then
    local rotationPercent = (359-currentRotation) / 180
    playerRotationalVelocity = 2 * rotationPercent
  end
  if currentRotation < 180 then
    local rotationPercent = currentRotation / 180
    playerRotationalVelocity = 2 * rotationPercent * -1
  end

--  playerRotationalVelocity *= .95
  if playerVelocity:magnitude() > 0 then
    playerVelocity:scale(0.95)
  end

end

function movePlayer() 

   -- apply rotation
   local currentRotation = playerSprite:getRotation()
   currentRotation += playerRotationalVelocity
   playerSprite:setRotation(currentRotation)

  -- test for hitting the edges of the screen
  if playerSprite.x < 20 then
    playerSprite.x = 20;
    return
  end
  if playerSprite.y > 220 then
    playerSprite.y = 220
    return
  end
  if playerSprite.y < 20 then
    playerSprite.y = 20
    return
  end
  if playerSprite.x > 368 then
    playerSprite.x = 368
  end

  -- clamp movement speed
  if playerVelocity:magnitude() > 20 then
    playerVelocity:normalize()
    playerVelocity:scale(20)
  end
  -- move player according to current velocity vector
  playerSprite:moveBy(playerVelocity.x,playerVelocity.y)

end

function beginRotation()


end

