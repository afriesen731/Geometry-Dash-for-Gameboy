INCLUDE "const.inc"
INCLUDE "hardware.inc"
INCLUDE "player.inc"

SECTION "Player", rom0




InitPlayer::

    ; left side oam
    ld hl, PLAYER_OBJ_L
    ld a, PLAYER_Y_START          ; y-pos
    ld [hli], a     
    ld a, PLAYER_X_START          ; x-pos
    ld [hli], a
    ld a, 0                 ; tile id
    ld [hli], a
	ld [hli], a


    ; right side oam
    ld hl, PLAYER_OBJ_R
    ld a, PLAYER_Y_START		    ; y-pos
	ld [hli], a 
	ld a, PLAYER_X_START + PLAYER_WIDTH/2        ; x-pos
	ld [hli], a
	ld a, 2				    ; tile id
	ld [hli], a
    ld a, 0
	ld [hli], a



    ; set FP position and velocity
    ld bc, PLAYER_Y_START
    ld a, 4 ; shift 4 bits
    call ShiftWLeft
    
    ld hl, wFPlayerY
    ld a, c
    ld [hli], a
    ld a, b
    ld [hl], a

    ld bc, PLAYER_X_START
    ld a, 4 ; shift 4 bits
    call ShiftWLeft
    
    ld hl, wFPlayerX
    ld a, c
    ld [hli], a
    ld a, b
    ld [hl], a


    ; set FP velocity
    ld a, FP_PLAYER_X_VEL_START

    ld [bFPPlayerVelX], a

    ld a, 0
    ld [bFPPlayerVelY], a

    
    
    ; set player status

    ld a, 0
    ld [bPlayerStatus], a

    



    ret

    

UpdatePlayer::

    
    call CheckCollision

    call HandleJump
    call ApplyVelocity


    call MoveBackground

    call MovePlayer
    call ApplyGravity
    


    
    ret



; if the player is touching the ground
; and the "A" button is pressed apply Y velocity 
HandleJump:
    ; check if "A" is pressed
    ld a, [wCurKeys]
    ld b, %00000001
    and b
    ret z
    
    ;check if not isInAir 
    ld a, [bPlayerStatus]
    ld c, a                     ; save bPlayerStatus in c
    ld b, %00000001
    and b
    ret nz

    ; set isInAir = 1
    ld a, %00000001
    or c            
    ld [bPlayerStatus], a

    ; update velocity
    
    ld a, FP_JUMP_VEL
    ld [bFPPlayerVelY], a
    

    ret

; move the player in OAM object according to fixed point values
MovePlayer::
    ld hl, wFPlayerX
    call FixedPointToInt
    call SetPlayerObjX

    ld hl, wFPlayerY
    call FixedPointToInt
    call SetPlayerObjY
    
    
    ret


; adds velocity to players fixed point position
; does not change OAM postition
ApplyVelocity:
    call ApplyVelocityX
    call ApplyVelocityY
    ret

; TODO 
; move the background according to the x velocity
MoveBackground:

.CheckRight:

    ; if (PlayerX > RightBoundry): adjust background
    ld hl, wFPlayerX
    call FixedPointToInt
    ld b, RIGHT_X_BOUNDRY
    sub b
    
    jp c, .CheckLeft
    jp z, .CheckLeft

.PastRight:
    ; subtracts the difference between the positions from the bg position
    ; call FlipSign8Bit
    call AdjustBGX
    ld c, RIGHT_X_BOUNDRY
    ld a, 4
    call ShiftWLeft
    ld a, c
    ld [wFPlayerX], a
    ld a, b
    ld [wFPlayerX + 1], a

    jp .CheckBottom

.CheckLeft
    ; if (PlayerX > RightBoundry): adjust background
    ld hl, wFPlayerX
    call FixedPointToInt
    ld b, a
    ld a, LEFT_X_BOUNDRY
    sub b
    
    jp c, .CheckBottom
    jp z, .CheckBottom

.PastLeft:
    ; subtracts the difference between the positions from the bg position
    call FlipSign8Bit
    call AdjustBGX
    ld c, LEFT_X_BOUNDRY
    ld a, 4
    call ShiftWLeft
    ld a, c
    ld [wFPlayerX], a
    ld a, b
    ld [wFPlayerX + 1], a

    jp .CheckBottom


.CheckBottom:


.CheckBottom2:
    ; if (PlayerY > BottomBoundry): adjust background
    ld hl, wFPlayerY
    call FixedPointToInt
    ld b, BOTTOM_Y_BOUNDRY
    sub b
    
    jp c, .CheckTop
    jp z, .CheckTop


    


.PastBottom:
    ; subtracts the difference between the positions from the bg position
    ; call FlipSign8Bit
    call AdjustBGY
    ld c, BOTTOM_Y_BOUNDRY
    ld a, 4
    call ShiftWLeft
    ld a, c
    ld [wFPlayerY], a
    ld a, b
    ld [wFPlayerY + 1], a

    ret

.CheckTop:

    ; if (PlayerX > RightBoundry): adjust background
    ld hl, wFPlayerY
    call FixedPointToInt
    ld b, a
    ld a, TOP_Y_BOUNDRY
    sub b
    
    ret c
    ret z

.PastTop:
    ; subtracts the difference between the positions from the bg position
    call FlipSign8Bit
    call AdjustBGY
    ld c, TOP_Y_BOUNDRY
    ld a, 4
    call ShiftWLeft
    ld a, c
    ld [wFPlayerY], a
    ld a, b
    ld [wFPlayerY + 1], a

    
    ret


; TODO 
; update the players velocity based on gravity
ApplyGravity:
    ; check if in air
    ld a, [bPlayerStatus]
    ld b, STATE_IN_AIR
    and b
    ret z

    ld a, [bFPPlayerVelY]
    
    add a, DECELERATION_Y

    ; stop at max fall speed
    
    ; if negative (jumping) dont check
    ld b, %1000_0000
    ld c, a         ; save vel in c
    and a, b
    ld a, c
    jp nz, .SavePosition

    cp MAX_FALL_SPEED
    jp c, .SavePosition
    ld a, MAX_FALL_SPEED

.SavePosition:
    ld [bFPPlayerVelY], a
    ret





; adds the player's x velocity to its position
ApplyVelocityX:
	ld a, [bFPPlayerVelX]
	ld b, a
    
    cp a, 0

    jr nz, .checkNegative
    ret         ; return if no velocity

.checkNegative 
    and a, %1000_0000
    jr nz, .negative

.positive
    xor a                   ; clears carry flag
    ld a, b
    ld hl, wFPlayerX
    add [hl]                ; add lower bits
    ld [hli], a     
    ld c, a
    ld a, 0
    adc [hl]                ; add upper bits
    ld [hl], a 
    ret



.negative
    ld a, b
    ld hl, wFPlayerX
    cpl
    inc a
    ld b, a
    ld a, [hl]
    sbc b
    ld [hli], a
    ld a, [hl]
    sbc 0
    ld [hl], a
    

    ret








; adds the player's y velocity to its position
ApplyVelocityY:
	ld a, [bFPPlayerVelY]
	ld b, a
    
    cp a, 0

    jr nz, .checkNegative
    ret         ; return if no velocity

.checkNegative 
    and a, %1000_0000
    jr nz, .negative

.positive
    xor a                   ; clears carry flag
    ld a, b
    ld hl, wFPlayerY
    add [hl]                ; add lower bits
    ld [hli], a     
    ld c, a
    ld a, 0
    adc [hl]                ; add upper bits
    ld [hl], a 
    
    ret


.negative
    ld a, b
    ld hl, wFPlayerY
    cpl
    inc a
    ld b, a
    ld a, [hl]
    sbc b
    ld [hli], a
    ld a, [hl]
    sbc 0
    ld [hl], a
    
    ; update position
    dec hl
    call FixedPointToInt
    ld [PLAYER_OBJ_L], a
    ld [PLAYER_OBJ_R], a
    ret   


; adjusts background x position by a value
; @param a value to adjust window by
AdjustBGX:
    ld b, a
    ld a, [rSCX]
    add b
    ld [rSCX], a
    ret

; adjusts background y position by a value
; @param a value to adjust window by
AdjustBGY:
    ld b, a
    ld a, [rSCY]
    add b
    ld [rSCY], a
    ret

; moves the sprite x position
; @param a x cordinate to move player to
SetPlayerObjX:
    ld [PLAYER_OBJ_L + 1], a
    add 8                   ; add player width
    ld [PLAYER_OBJ_R + 1], a
    ret

; moves the sprite y position
; @param a y cordinate to move player to
SetPlayerObjY:
    ld [PLAYER_OBJ_L], a
    ld [PLAYER_OBJ_R], a
    ret


; sub [hl], bc (hl - bc)
; @param hl address of 16 bit value to compare to bc
; @param bc value to compare to hl
; @return a has result (only 8 bits) and flag registers 
; Flags:
;   - Z: Set if result is 0 ([hl] == bc)
;   - N: 1
;   - H: Set if no borrow from bit 4
;   - C: Set if no borrow ([hl] < bc)
WCompare::
    inc hl
    ld a, [hld]
    sub a, b

    ; compare lower bits
    ld a, [hl]
    sbc a, c
    ret



SECTION "Player Data", wram0
    wFPlayerY:: dw
    wFPlayerX:: dw
    bFPPlayerVelX:: db
    bFPPlayerVelY:: db

    ; bit 0: isInAir
    ; bit 1: isColliding (if the player is colliding with a deadly object)
    ; bit 2: reset (resets the game)
    bPlayerStatus:: db
