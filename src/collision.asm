INCLUDE "const.inc" 
INCLUDE "hardware.inc"
INCLUDE "player.inc"


SECTION "Collision", rom0
    ; array of solid tiles.
    ; $00 is the end value
    solidTiles: db $04, $05, $06, $07, $10, $11, $12, $13, $14, $15, $17, $00

    ; array of spike tiles.
    ; $00 is the end value
    damageTiles: db $02, $03, $08, $09, $0C, $0D, $0E, $0F, $17, $18, $00

    ; array of ground bounce pad tiles
    ; $00 is the end value

    bouncePadTiles: db $12, $13, $14, $15, $00

    ; array of floating bounce pad tiles
    ; $00 is the end value
    floatingBounceTiles: db $16, $00




CheckCollision::
    ld hl, PLAYER_OBJ_L

    call ObjToWorldCords

    ld [bPlayerWorldX], a
    ld c, a
    ld a, b
    ld [bPlayerWorldY], a
    ld a, c

    call GetTile
    ld a, b
    ld [bPlayerColumn], a
    ld a, c
    ld [bPlayerRow], a

    ld a, l
    ld [wPlayerTile], a
    ld a, h
    ld [wPlayerTile + 1], a

    call UpdateTileCache

    ld a, [$FF44]
    call CheckFall
    call TestVertical
    call TestDeath
    call TestBouncePad


    ret


 


; converts object cordinates to the pixel on the tile map
; @param `hl` OAM location of object
; @return `a` x cord
;         `b` y cord
ObjToWorldCords:
    ld a, [hli]
    sub 16                     ; adjust it to screen start point
    ld e, a                    ; "e" player y cord
    ld a, [hl]
    sub 8                       ; adjust to screen start point
    ld d, a                     ; "d" player x cord

    

    ; turn these values to world cordinates


    ld a, [rSCY]
    add a, e
    ld b, a

    ld a, [rSCX]
    add a, d


    ret


; get tile position based on world cordinates
; @param `a` x world cordinate
; @param `b` y world cordinate
; @return `hl` tile position
;         `b` tile column
;         `c` tile row
GetTile:
    ; - tileColumn   = WorldX / 8 = WorldX >> 3
    ; - tileRow      = WorldY / 8 = WorldY >> 3
    and a, %1111_1000
    rrca
    rrca
    rrca
    ld d, a         ; TEMP: move tile column in "d"
    ld a, b         ; move world y into a
    ld b, d         ; save tile column in "b"
    and a, %1111_1000
    ld l, a         ; save in "l" for row calculation
    rrca
    rrca
    rrca
    ld c, a         ; save tileRow in "c"

    ; Then we calclate the starting address for that particular tile in the level
    ; data using some basic math that's been converted to use bitwise operations
    ; (this makes it easier to do in assembly):
    ;
    ; DataAddress  = LevelData + 32 * bTileRow + bTileColumn
    ;              = LevelData + (bTileRow << 5) + bTileColumn
    ;              = LevelData + ((WorldY >> 3) << 5) + (WorldX >> 3)
    ;              = LevelData + ((WorldY & %1111_1000) << 2) + (WorldX >> 3)
    ld h, 0
    ; << 2
    sla l            ; l = (WorldY & %1111_1000)
    rl h
    sla l             
    rl h
    ; hl = tileRow * 32

    ld a, b         ; load column into a
    add a, l        ;tileColumn = 32 * tileRow + tileColumn
    ld l, a
    ld a, 0
    adc h
    ld de, $9800    ; Store the address of the graphics tile in the tilemap
    add hl, de
    ret






; checks the 3 tiles below the player to determine if it is on the ground
CheckFall:
    ld b, 0     ; tile column offset
    ld c, 2     ; tile row offset
    push bc

.loop:
    ; "b" column offset
    ; "c" row offset

    ; if the player is on the tile stop checking
    GetTileFromCache

    ; if tile is empty dont check if tile is solid
    cp a, 0
    jr z, .checkDone

.checkTile:
    ld b, a             ; "b" is the tile type the player collided with
    ld hl, solidTiles
    call TileInArray

    jp z, .endLoop
    

.checkDone:
    pop bc

    ld a, b
    cp a, 2         ; if (offset < 2) -> continue loop
    ; update and save offset
    ; "c" needs to be 2
    inc b
    push bc

    ; make sure "b" and "c" offsets
    jp c, .loop

    ; make player fall
    ld a, [bPlayerStatus]
    or STATE_IN_AIR
    ld [bPlayerStatus], a
    

.endLoop:
    pop bc
    ret
    

; when the player hits the ground it moves it so it is on top, but not inside the ground
MoveVertical:
    ld hl, wFPlayerY
    call FixedPointToInt
    ld d, a
    ld a, [bPlayerWorldY]
    and %0000_0111
    ld e, a
    ld a, d
    sub a, e
    
    ld c, a
    ld b, 0
    ld a, 4
    call ShiftWLeft
    ld a, c
    ld [wFPlayerY], a
    ld a, b
    ld [wFPlayerY+1], a
    

    ; call MovePlayer
    ret 



; test collision for the player horizontally
; test the 2 tiles on the side the player is moving
; test the 3 tiles on the side the player is moving if in the air
TestDeath:


    ld c, 0                        ; add the row offset

    ; if (xVel < 0) -> check the left side of the player
    ; else -> check the right side of the player (add offset)

    ld b, 0                         ; add the column offset

    ld a, [bFPPlayerVelX]

    and %10000000
    jp nz, .loop


    ld b, 2                        ; add the column offset

    push bc

.loop:

    ; "bc" holds offsets


    GetTileFromCache
    cp 0
    jp z, .endCheck
    

    ; check if tile is solid or a spike
    ld b, a
    ld hl, solidTiles
    call TileInArray
    jp z, .collide

    ; "b" still holds tile value
    ld hl, damageTiles
    call TileInArray
    jp z, .collide

.endCheck:

    pop bc
    inc c
    push bc


    ; if (player.inAir) -> check 3 tiles
    ; else -> check 2 tiles
    ld d, 3

    ld a, [bPlayerStatus]
    and a, STATE_IN_AIR

    jp nz, .inAir
    ld d, 2
    
.inAir:
    ld a, c
    cp a, d

    

    jp nz, .loop

    ; set isColliding to False because the player is not hitting anything
    ; ld a, [bPlayerStatus]
    ; and a, %1111_1101
    ; ld [bPlayerStatus], a

    ; "bc" are still offsets

    jp .endLoop


.collide:
    call Collide

.endLoop:
    pop bc
    ret 


; TODO tests collision for the player vertically
TestVertical:
    ; if player is moving down check tiles under it
    ; else check the top 3 tiles
    

    ; if velocity is negative the player is going up
    ; if on the ground dont check

    ld a, [bFPPlayerVelY]

    and %1000_0000
    jr z, .falling
    

    call CheckUp
    ret
.falling:
    call CheckDown


    ret 


; check if the player hit the 2 tiles above it
; if it is collide
CheckUp:
    

    ret

; check if the player landed on the tiles below it
CheckDown:
    ld b, 0     ; tile column offset
    ld c, 2     ; tile row offset
    push bc

.loop:
    ; "b" column offset
    ; "c" row offset

    ; if the player is on the tile stop checking
    GetTileFromCache
    ; if tile is empty dont check if tile is solid
    cp a, 0
    jr z, .checkDone

.checkTile:
    ld b, a             ; "b" is the tile type the player collided with
    ld hl, solidTiles
    call TileInArray

    jp nz, .checkDone

    ; touch ground

    ; check if previously in air
    ld a, [bPlayerStatus]
    ld b, a
    and %0000_0001
    jr z, .endLoop

    ; set status to not in air
    ld a, b
    and a, %1111_1110
    ld [bPlayerStatus], a

    ; set y vel to 0
    ld a, 0
    ld [bFPPlayerVelY], a


    call MoveVertical

    jp .endLoop
    

.checkDone:
    pop bc

    ld a, b
    cp a, 2         ; if (offset < 2) -> continue loop
    ; cp a
    ; update and save offset
    ; "c" needs to be 2
    inc b
    push bc

    ; make sure "b" and "c" offsets
    jp c, .loop



    ld a, [bPlayerStatus]
    or %0000_0001
    
    ld [bPlayerStatus], a


.endLoop:
    pop bc
    ret






; check if the player landed on a bounce pad or
; jumped on a floating one
TestBouncePad:

    ; if on ground
    ; check the 3 tiles underneath the player for bounce pads

    ld a, [bPlayerStatus]
    and a, STATE_IN_AIR
    
    jr nz, .checkFloatingBouncePad

    ld b, 0     ; tile column offset
    ld c, 2     ; tile row offset
    push bc

.loop:
    ; "b" column offset
    ; "c" row offset

    ; if the player is on the tile stop checking
    GetTileFromCache
    ; if tile is empty dont check if tile is a bounce pad
    cp a, 0
    jr z, .checkDone

.checkTile:
    ld b, a             ; "b" is the tile type the player collided with
    ld hl, bouncePadTiles
    call TileInArray

    jp nz, .checkDone

    ; bounce

    ld a, [bPlayerStatus]
    or a, STATE_IN_AIR
    ld [bPlayerStatus], a

    ld a, FP_BOUNCE_PAD_VEL
    ld [bFPPlayerVelY], a

    

.checkDone:
    pop bc

    inc b

    ld a, b
    ; TODO make sure this works
    cp a, 3         ; if (offset < 3) -> continue loop
    ; update and save offset
    ; "c" needs to be 2
    push bc
    

    ; make sure "b" and "c" offsets
    jp c, .loop

    

.endLoop:
    pop bc



.checkFloatingBouncePad:
    ; if jump button is just pressed and in air
    ; check if the player is on a bounce pad
    ld a, [wNewKeys]
    and %00000001
    ret z


    ; "b" column offset
    ; "c" row offset
    ld b, 0
    ld c, 0

.floatingLoop:
    ; "b" column offset
    ; "c" row offset
    push bc


    ; if the player is on the tile stop checking
    GetTileFromCache
    ; if tile is empty dont check if tile is a bounce pad
    cp a, 0
    jp z, .checkDoneFloating

    ; TODO create a loop that checks all the tiles the player is on for a floating bounce pad

.checkTileFloating
    ld b, a
    ld hl, floatingBounceTiles
    call TileInArray

    jr nz, .checkDoneFloating

    ld a, FP_FLOATING_BOUNCE_PAD_VEL
    ld [bFPPlayerVelY], a
    pop bc
    ret

.checkDoneFloating:
    pop bc
    inc c
    ld a, c
    cp a, 3 ; was 2
    jr nz, .floatingLoop 



.nextColumn:
    ld c, 0
    inc b
    ld a, b
    cp a, 3 ; was 2
    
    jr nz, .floatingLoop
    

    ret



; kill player after a collision.
Collide:
    ; Give player one extra frame when they hit something
    
    ld a, [bPlayerStatus]
;     ld b, a
;     and a, %0000_0010

;     ld a, b

;     jr z, .die 

;     or a, %0000_0010

;     ret

; .die:
    or a, %0000_0100
    
    ld [bPlayerStatus], a
    
    ret


; Axis-Aligned Boundry Box (AABB) collision detection for a tile and a sprite. 
; Sets `a` to zero if there is no collision, sets it to the value of the
; tile in level data if there is.`only works with square sprites`
; * `hl` - The address to the level data for the tile to check.
; * `a` - The sprite width in pixels
; * `b` - The sprite tile map y cord (in pixels)
; * `c` - The sprite tile map x cord (in pixels)
; * `d` - The column in the background for the tile.
; * `e` - The row in the background for the tile.
CheckTileCollision:
    push af     ; save player width to stack
    
    ld a, [hl]
    
    ld h, a     ; "h" = tile map value
    cp 0        ; compare tile value to an empty tile
    jr nz, .checkXAxis
    pop bc      ; clear stack



    ret         ; return if tile is empty

.checkXAxis:
    ; d <- tileX = tileCol * 8 = tileCol << 3 = d << 3

    sla d 
    sla d
    sla d     ; d <- tileX

.checkTooFarLeft:
    ; if (spriteX + SPRITE_WIDTH < tileX) -> No Collision
    pop af  ; remove player width from the stack
    ld l, a ; "l" = sprite width
    

    add a, c ; a = SPRITE_WIDTH + spriteX
    ; sub 1      ; temp
    cp a, d  ; (spriteX + SPRITE_WIDTH) - tileX



    jr nc, .checkTooFarRight

.checkWrapLeft:
    ; TODO add to tileX half the screen
    push hl  ; add tile and sprite width to stack

    add a, SCREEN_WIDTH / 2 ; spriteX + SPRITE_WIDTH + SCREEN_WIDTH / 2
    ld h, a
    
    ld a, d
    add a, SCREEN_WIDTH / 2 ; tileX + SCREEN_WIDTH / 2
    cp a, h                 ; (tileX + SCREEN_WIDTH / 2) - (spriteX + SPRITE_WIDTH + SCREEN_WIDTH / 2)
  
    pop hl  ; remove tile and sprite width to stack
    jr nc, .noHit
    


    
.checkTooFarRight:
    ; if (tileX + TILE_WIDTH < spriteX)   -> No Collision
    ld a, d     ; "a" = tileX
    add a, TILE_WIDTH
    ; sub 2      ; temp

    cp a, c     ; (tileX + TILE_WIDTH) - spriteX
    jr nc, .checkYAxis
.checkWrapRight:
    push hl

    add a, SCREEN_WIDTH / 2 ; (tileX + TILE_WIDTH + SCREEN_WIDTH / 2)
    ld h, a
    ld a, c

    add a, SCREEN_WIDTH / 2 ; spriteX + SCREEN_WIDTH / 2
    ld c, a
    ld a, h

    cp a, c ; (tileX + TILE_WIDTH + SCREEN_WIDTH / 2) - spriteX + SCREEN_WIDTH / 2

    pop hl

    jr c, .noHit

    

.checkYAxis:
    

    ; e <- tileY = bTileRow * 8 = bTileRow << 3 = e << 3
    sla e
    sla e
    sla e 

.checkTooFarAbove:
    ; if (spriteY + SPRITE_WIDTH < tileY)  -> No Collision
    ld a, b         ; spriteY
    add a, l        ; spriteY + SPRITE_WIDTH
    cp a, e         ; (spriteY + SPRITE_WIDTH) - tileY
    jr nc, .checkTooFarBelow
    
    jr .noHit

.checkTooFarBelow:
    ; if (tileY + TILE_WIDTH < spriteY): -> No Collision

    ld a, e
    add a, TILE_WIDTH
    cp a, b
    jr nc, .collisionDetected

.noHit:
    ld a, 0
    cp 0
    ret

.collisionDetected:
    ld a, h
    cp 0
    ret





; checks if the player has collided with a specific tile offset
; @param `b` column offset (x) (positive is right)
; @param `c`  row offset  (y)  (positive is left)
; @return `a` tile type
CheckPlayerTileCollision:

    push bc
    ; load arguments

    ; load tile column
    ld a, [bPlayerColumn]
    add a, b              ; add column offset
    ld d, a



    ; load tile row
    ld a, [bPlayerRow]
    add a, c            ; add row offset               
    ld e, a





    ; load tile memory location in tilemap
    ld a, [wPlayerTile]
    ld l, a
    ld a, [wPlayerTile + 1]
    ld h, a

    ; add offset
    ld c, b
    ld b, 0
    add hl, bc                      ; add column offset in "c"

    ; if (column < 32) -> dont adjust
    ld a, d
    cp a, 32
    jp c, .endColumnAdjust

    sub a, 32 
    ld d, a

    ; ; adjust tilemap position if overflow
    ld bc, -32
    add hl, bc


.endColumnAdjust:



    pop bc        ; "c" is row offset

    ; set the upper bits to $FF if c is negative
    ld a, c
    and %1000_0000

    ld b, 0
    jr z, .positiveUpper
    ld b, $FF


.positiveUpper:




    ; multiply row offset by 32
    sla c
    rl b

    sla c
    rl b

    sla c
    rl b

    sla c
    rl b

    sla c
    rl b


    ; add row offset
    add hl, bc


            
    ld a, [bPlayerWorldX]
    ld c, a

    ld a, [bPlayerWorldY]
    ld b, a

    ld a, PLAYER_WIDTH

    call CheckTileCollision
    ret


; checks if a tile is in an array of values (ending with $00)
; @param `b` tile value
; @param `hl` array memory location
; @return `b` tile value (always the same as the input)
;         `z` is True if in array. else False
TileInArray:
    ; if (b == 0) -> return False
    ld a, b
    cp a, 0
    jp z, .exitLoop
.loop:
    ; for (tile in tileArray): if (tile == b): return
    ld a, [hli]
    cp b
    ret z
    
    ; stop .checkTileLoop if at end of solidTiles
    cp 0
    jr nz, .loop
.exitLoop:
    cp 1                    ; set zero flag to False
    ret


; updates the 9 values of tiles near the player at "bTileCache"
UpdateTileCache:
    ld d, 0     ; "d" column
    ld e, 0     ; "e" row
    
    ld a, [wPlayerTile]
    ld l, a
    ld a, [wPlayerTile + 1]
    ld h, a

    ld bc, bTileCache
    


    ;  tile cach
    ;   X | X | X
    ;  ___|___|___
    ;   X | X | X
    ;  ___|___|___
    ;   X | X | X
    ;     |   |



.loop:
    ; if the offset goes past the final column make it wrap around to the start
    ld a, [bPlayerColumn]
    add a, d        ; "a" = playerColumn + offset
    cp a, 32        ; if ((playerColumn + offset) >= 32) -> then wrap around
    jr c, .noWrap

    push bc

    ld bc, -32
    add hl, bc

    ld a, [hli]

    ld bc, 32
    add hl, bc

    pop bc

    jr .doneRead

.noWrap
    ld a, [hli]
    

.doneRead:
    ld [bc], a

    inc bc
    inc d
    ld a, d

    cp a, 3
    jr c, .loop


    inc e
    ld d, 0

    ; move to next row of tile map
    push bc

    ld bc, 32 - 3   ; go to the begining of the next row
    add hl, bc

    pop bc

    ld a, e
    cp a, 3
    jr c, .loop

    

    ; right
    ;     |   | X
    ;  ___|___|___
    ;     |   | X
    ;  ___|___|___
    ;     |   | X
    ;     |   |


    ; if player is only ontop of 2 tiles horizontaly then fill the right column with "0"


    ; check if on top of only 2 tiles
    ld a, [bPlayerWorldX]
    ld b, a
    and a, %1111_1000
    cp a, b
    ret nz



    ; save "0" to cache
    ld a, 0

    ld [bTileCache + 2], a

    ld [bTileCache + 5], a

    ld [bTileCache + 8], a

    ret




    


SECTION "Collision Variables", wram0
    ; the tile map location of the top left of the player
    wPlayerTile: dw
    ; the row number in the tile map for the top left of the player
    bPlayerRow: db
    ; the column number in the tile map for the top left of the player
    bPlayerColumn: db
    ; the player's x position on the tile map
    bPlayerWorldX: db
    ; the player's y position on the tile map
    bPlayerWorldY: db


    ; the 9 tiles near the player
    ; index = 3 * row + column
    ; first tile is the top left of the player
    ; *  0 | 1 | 2   
    ; *  3 | 4 | 5
    ; *  6 | 7 | 8
    bTileCache: db 
    db 
    db 
    db 
    db 
    db 
    db 
    db 
    db
    ; $00, $00, $00, $00, $00, $00, $00, $00, $00




