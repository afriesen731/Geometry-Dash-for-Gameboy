INCLUDE "hardware.inc"
INCLUDE "const.inc"
INCLUDE "gbt_player.inc"



SECTION "VBL interrupt vector", ROM0[$0040]

    reti


SECTION "Header", ROM0[$100]

	jp Main

    ds $150 - @, 0 ; Make room for the header


SECTION "Main", rom0

Main:

    
    call SetUpTitleScreen
TitleLoop:

    WaitForVblank
    

    call UpdateKeys

    ; Update music
    call gbt_update


    WaitForVblankEnd
    

    ld a, [wNewKeys]
    ; check for start button
    and a, %0000_1000

    jr z, TitleLoop




    

Reset:
    call SetUpGame


GameLoop:



    WaitForVblank






    call Scroll
    call DMATransfer
    
    call UpdateKeys
    ;run game logic
    call UpdatePlayer

    call CheckGameEnd

    jr nz, .gameEnd


    call CheckAndUpdateColumnCache
    call UpdateStatus



    
    ; Update music
    call gbt_update


    WaitForVblankEnd


    jp GameLoop


.gameEnd:
    call GameEnd
    jp Reset





; Initializes various RAM and register locations prior to game start.
SetUpGame:
	; ; Shut down audio circuitry
	; ld a, 0
	; ld [rNR52], a




    call TurnOffLCD
    call ClearWRam
    call LoadVram
    call ClearOam
    call WriteDMARoutine
    call InitPlayer
    call InitStatus

    call SetUpMusic


    ; turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16

    LD [rLCDC], a




    ; during the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a

    ; initialize object palette
    ld a, %11100100
    ld [rOBP0], a
    
    ; Initialize global variables
    ld a, 0
    ld [wCurKeys], a
    ld [wNewKeys], a

    ld a, 0
	ld [bNextScrollColumn], a

	ld a, 8
	ld [bNextScrollPosition], a
    
    ret







ClearOam:
	ld a, 0
	ld b, 160
	ld hl, _OAMRAM
.ClearOamLoop:
	ld [hli], a
	dec b 
	jp nz, .ClearOamLoop
    ret





; checks if the player died
; @return sets "nz" to True if player dies
CheckGameEnd:
    ld a, [bPlayerStatus]
    and a, %0000_0100
    ret
; pause at game end
GameEnd:
    ld b, 0
.loop
    WaitForVblankEnd
    WaitForVblank
    inc b
    ld a, b
    cp 20

    jp nz, .loop
    ret


; ------------------------------------------------------------------------------
; `func WriteDMARoutine()`
;
; Writes the DMA transfer routine into memory starting at address $FF80. For
; more information see the explanation in the documentation for the
; `DMATransferRoutine` function below.
; ------------------------------------------------------------------------------
WriteDMARoutine:
    ld b, DMATransferRoutineEnd - DMATransferRoutine
    ld de, DMATransferRoutine
    ld hl, DMATransfer
  .load_loop
    ld a, [de]
    inc de
    ld [hli], a
    dec b
    jr nz, .load_loop
    ret
  
  ; ------------------------------------------------------------------------------
  ; `func DMATransferRoutine()`
  ;
  ; This is the DMA transfer routine used to quickly copy sprite object data from
  ; working RAM to video RAM.
  ;
  ; **IMPORTANT:** This routine should not be called directly, in order to prevent
  ; bus conflicts the Game Boy only executes instructions between $FF80-$FFFE
  ; during a DMA transfer. As such this routine is copied to that memory region
  ; and you should call it using the `DMATransfer` routine label instead.
  ; ------------------------------------------------------------------------------
DMATransferRoutine:
    di
    ld a, $C1    ;C1
    ld [rDMA], a
    ld a, 40
.wait_loop:
    dec a
    jr nz, .wait_loop
    ei
    ret
  DMATransferRoutineEnd:



; ------------------------------------------------------------------------------
; `func ClearWRam()`
;
; Clears all working RAM from `$C000` through `$DFFF` by setting each byte to 0.
; ------------------------------------------------------------------------------
ClearWRam:
    ld bc, $2000
    ld hl, $C000
.clear_loop
    ld a, 0
    ld [hli], a
    dec bc
    ld a, b
    or a, c
    jr nz, .clear_loop
    ret



; start the background music
SetUpMusic:
    di


    ld      a,$01
    ld      [rIE],a ; Enable VBL interrupt
    ei

    ld      de,song_data
    ld      bc,BANK(song_data)
    ld      a,$05
    call    gbt_play ; Play song
    ret



; start the background music
SetUpTitleMusic:
    di


    ld      a,$01
    ld      [rIE],a ; Enable VBL interrupt
    ei

    ld      de,title_song_data
    ld      bc,BANK(title_song_data)
    ld      a,$05
    call    gbt_play ; Play song
    ret

SetUpTitleScreen:
    call TurnOffLCD
    call ClearWRam
    call LoadTitleScreen
    call ClearOam
    call SetUpTitleMusic





    ; turn the LCD on
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16

    LD [rLCDC], a




    ; during the first (blank) frame, initialize display registers
    ld a, %11100100
    ld [rBGP], a

    ; initialize object palette
    ld a, %11100100
    ld [rOBP0], a
    
    ; Initialize global variables
    ld a, 0
    ld [wCurKeys], a
    ld [wNewKeys], a


