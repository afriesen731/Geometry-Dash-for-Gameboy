INCLUDE "hardware.inc"
INCLUDE "const.inc"

SECTION "Background Movement", rom0

    ; ; *bit 0: tile map value
    ; ; *bit 1-: replacement values
    ; ; null terminated
    ; bBlock1: db $FE, $04, $05, $00
    ; ; *bit 0: tile map value
    ; ; *bit 1-: replacement values
    ; ; null terminated
    ; bBlock2: db $FF, $06, $07, $00

    ; ; list of locations for blocks null terminated
    ; wBlocks: dw bBlock1, block2, $0000





; update tile cache
; replaces the tile column that most recently left the screen with the next one
; @param `wTilemapPosition` column location
; @return `wTilemapPosition` column end location
UpdateColumnCache::
    ; column location
    ld a, [wTilemapPosition]
    ld e, a
    ld a, [wTilemapPosition + 1]
    ld d, a


    ; stop at end
    ld hl, TilemapEnd

    ld a, e
    sub a, l
    ld c, a

    ld a, d 
    sub a, h
    or a, c 
    ret z




    ld b, 0


    
    
    


    ld hl, bColumnCache       ; bColumnCache location
    

.loop:
    ld a, [de]

    cp a, $00
    jr z, .addEmpty


    cp a, $FE 
    jr z, .addBlock1 

    cp a, $FF
    jr z, .addBlock2


    ld [hli], a

    
    inc b
    inc de 

    
.checkDone:
    ld a, b
    cp a, 32
    jr nz, .loop

    ; save column location
    ld a, e
    ld [wTilemapPosition], a 
    ld a, d
    ld [wTilemapPosition + 1], a 

    ret


.addEmpty:
    

    ; load tile count into "c"
    inc de
    ld a, [de]
    ld c, a
    inc de


    ; increment row counter
    add a, b
    ld b, a

    ld a, $00
.emptyLoop:

    ld [hli], a



    ; count down the number of tiles
    dec c
    cp a, c     ; "a" holds zero "c" has the count
    jr nz, .emptyLoop
    jr .checkDone

.addBlock1:
    ; load tile count into "c"
    inc de
    ld a, [de]
    ld c, a

    inc de


    ; increment row counter
    sla a       ; multiply by 2 because the height of each block is 2
    add a, b

    
    ld b, a


.addBlock1Loop:

    ld a, $04
    ld [hli], a

    ld a, $05
    ld [hli], a

    ; count down the number of tiles
    dec c
    ld a, c
    cp a, 0     ; "a" holds count
    jr nz, .addBlock1Loop
    jr .checkDone


.addBlock2:
    ; load tile count into "c"
    inc de
    ld a, [de]
    ld c, a


    inc de


    ; increment row counter
    sla a       ; multiply by 2 because the height of each block is 2
    add a, b

    
    ld b, a


.addBlock2Loop:

    ld a, $06
    ld [hli], a

    ld a, $07
    ld [hli], a

    ; count down the number of tiles
    dec c
    ld a, c
    cp a, 0     ; "a" holds count
    jr nz, .addBlock2Loop
    jp z, .checkDone




; checks if it is time to update cache and updates
CheckAndUpdateColumnCache::
   ; check if past scroll position

   ld a, [bNextScrollPosition]

   cp a, 0
   ld b, a
   ld a, [rSCX]
   jp z, .checkWrap


   cp a, b                     ; if (rSCX < bNextScrollPosition) -> return
   jr nc, .doneCheck
   ret

.checkWrap:
   ; check wrap around
   add a, SCREEN_WIDTH / 2
   ld c, a
   ld a, b
   add a, SCREEN_WIDTH / 2
   ld b, a
   ld a, c
   cp a, b
   ret c

.doneCheck:
    call UpdateColumnCache

    ret

;   load in a new set of tiles each frame
Scroll::

    ; check if new cache
    ; $FF is the beginning of the cache if not updated
    
    ld a, [bColumnCache]
    cp a, $FF
    ret z

    ; ld c, a
    ; ld a, b

    ; ; "c" = (rSCX - bNextScrollPosition) // 8
    ; sub a, c
    ; srl a
    ; srl a
    ; srl a
    ; ld c, a
    

    ; .loop:
    ; push bc
    
    ; if past position get next column
    ld a, [bNextScrollColumn]
    ld c, a
    
    call LoadTileColumn


    ; update bNextScrollColumn
    ld a, [bNextScrollColumn]
    inc a
    and a, %0001_1111
    ld [bNextScrollColumn], a
    
    ; update bNextScrollPosition

    ld a, [bNextScrollPosition]
    add a, 8 
    ld [bNextScrollPosition], a



    ; ; if (c < 2) -> return
    ; ; else -> loop
    ; pop bc

    ; ld a, c
    ; dec c
    ; cp a, 0
    ; jr nz, .loop
    ret 





; copy memory from `bColumnCache` to a tilemap column
; @param `c` column (0-31)
LoadTileColumn:
    ld hl, _SCRN0
    ld b, 0
    add hl, bc
    ld de, bColumnCache 
    ld c, 32
.loop:
    ld a, [de] 
	ld [hl], a

    dec c 
    inc de 
    ld a, c
    ld bc, 32 
    add hl, bc
    ld c, a

    cp a, 0 
	jp nz, .loop 



    ld a, $FF 
    ld [bColumnCache], a

	ret



; only for loading at the start
; @param `c` column (0-31)
LoadNewTileColumn::
    push bc
    call UpdateColumnCache
    pop bc
    call LoadTileColumn
    ret

SECTION "Background Scroll", wram0
    ; the location of the next section of the tile map to load
    wTilemapPosition:: dw

    ; the next column to load a row into
    bNextScrollColumn:: db
    ; the next offset to load new tiles at
    bNextScrollPosition:: db

    ; 
    bColumnCache:
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 
        db 

