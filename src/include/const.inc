INCLUDE "hardware.inc"



; ------------------------------------------------------------------------------
; `func DMATransfer()`
;
; Transfers sprites from WRAM to VRAM using the DMA.
; ------------------------------------------------------------------------------
DEF DMATransfer EQU $FF80



; WRAM location for Object (Sprite) OAM data that is transferred to VRAM via DMA
; at the end of each frame during the VBLANK period.
DEF pSpriteOAM EQU $C100

DEF PLAYER_OBJ_L EQU pSpriteOAM
DEF PLAYER_OBJ_R EQU pSpriteOAM + 4

DEF STATUS_NUMBER_L EQU pSpriteOAM + 8
DEF STATUS_NUMBER_R EQU pSpriteOAM + 12
DEF STATUS_PERCENT EQU pSpriteOAM + 16



; ------------------------------------------------------------------------------
; `macro WaitForVblank()`
;
; Loops until the LCD enters the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblank
: ld a, [rLY]
  cp a, 144
  jr c, :-
ENDM

; ------------------------------------------------------------------------------
; `macro WaitForVblankEnd()`
;
; Loops until the LCD exits the vertical blanking period.
; ------------------------------------------------------------------------------
MACRO WaitForVblankEnd
: ld a, [rLY]
  cp 144
  jr nc, :-
ENDM


DEF SCREEN_WIDTH EQU 8 * 32


DEF TILE_ROW_WIDTH EQU 32


DEF TILE_WIDTH EQU 8





; gets the tile value in a 3x3 grid around the player
; offset (0, 0) is the top left tile
; @param `c` row
; @param `b` column
; @return `a` tile value
MACRO GetTileFromCache
: 
ld hl, bTileCache           ;3            3
ld a, c                     ;1            1
; multiply row by 3
add a, c                    ;1            1
add a, c                    ;1            1
add a, b                    ;1            1
ld e, a                     ;1            1
ld d, 0                     ;2            2
add hl, de                  ;2            1
ld a, [hl]                  ;2            1
                          ;+___         +___
                          ; 14 cycles    12 bytes
ENDM