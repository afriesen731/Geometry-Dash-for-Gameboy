INCLUDE "hardware.inc"
INCLUDE "const.inc"

SECTION "CopyTiles", rom0


LoadTitleScreen::
    
	call LoadTitleTiles
	call LoadTitleTileMap


	; set scroll positions
	ld a, 0
	ld [rSCY], a
	ld a, 0
	ld [rSCX], a

    ret




LoadVram::
    
	call LoadBGTiles
	call LoadCube
	call LoadTileMap


	; set scroll positions
	ld a, 112
	ld [rSCY], a
	ld a, 0
	ld [rSCX], a

    ret




; shut down LCD so tiles can be loaded
TurnOffLCD::
; Do not turn the LCD off outside of VBlank
.WaitVBlank:
	ld a, [rLY]
	cp 144
	jp c, .WaitVBlank

	; Turn the LCD off
	ld a, 0
	ld [rLCDC], a
    ret







; load bg tile data
LoadBGTiles:
    ld de, Tiles
    ld hl, $9000
    ld bc, TilesEnd - Tiles
	call Memcopy
    ret

; load the tilemap
LoadTileMap:
    ld bc, Tilemap
	ld a, c
	ld [wTilemapPosition], a
	ld a, b
	ld [wTilemapPosition + 1], a

	ld c, 0

.loop:
	push bc
	call LoadNewTileColumn
	pop bc

	inc c
	ld a, 32
	cp a, c
	jr nz, .loop

	
	
    ret



LoadCube:
	ld de, Sprites
	ld hl, $8000
	ld bc, SpritesEnd - Sprites
	call Memcopy
	ret


LoadTitleTileMap:
    ld de, TitleMap
    ld hl, $9800
    ld bc, TitleMapEnd - TitleMap
	call Memcopy
    ret


LoadTitleTiles:
    ld de, TitleTiles
    ld hl, $9000
    ld bc, TitleTilesEnd - TitleTiles
	call Memcopy
    ret


; copy memory from one location to another
; @param `de` memory location of memory to copy
; @param `hl` location to copy to
; @param `bc` number of bytes to copy
Memcopy:
	ld a, [de] 
	ld [hli], a 
	inc de 
	dec bc 
	ld a, b 
	or a, c 
	jp nz, Memcopy 
	ret

