INCLUDE "const.inc"

SECTION "Status", rom0

InitStatus::



    ld a, 14
    ld [STATUS_NUMBER_L], a
    ld a, 8 + 80
    ld [STATUS_NUMBER_L + 1], a
    ld a, 4
    ld [STATUS_NUMBER_L + 2], a
    ld a, 0
    ld [STATUS_NUMBER_L + 3], a


    ld a, 14
    ld [STATUS_NUMBER_R], a
    ld a, 8 + 89
    ld [STATUS_NUMBER_R + 1], a
    ld a, 4
    ld [STATUS_NUMBER_R + 2], a
    ld a, 0
    ld [STATUS_NUMBER_R + 3], a



    ld a, 14
    ld [STATUS_PERCENT], a
    ld a, 8 + 98
    ld [STATUS_PERCENT + 1], a
    ld a, 25
    ld [STATUS_PERCENT + 2], a
    ld a, 0
    ld [STATUS_PERCENT + 3], a

    ; save negative tilemap
    ld hl, Tilemap
    ld a, l 
    cpl 
    ld l, a

    ld a, h 
    cpl 
    ld h, a
    inc hl

    ld a, l
    ld [wNegativeTilemap], a


    ld a, h
    ld [wNegativeTilemap + 1], a


    ld bc, TilemapEnd
    add hl, bc


    call FindShifts
    ld a, l
    ld [wBitShiftMap], a
    ld a, h
    ld [wBitShiftMap + 1], a



    ret


; find the percentage of completion and set the numbers
UpdateStatus::


    ; load current tile map position
    ld a, [wTilemapPosition]
    ld l, a
    ld a, [wTilemapPosition + 1]
    ld h, a

    ; subtract Tilemap position
    ld a, [wNegativeTilemap]
    ld c, a
    ld a, [wNegativeTilemap + 1]
    ld b, a

    ; "hl" = current distance from beggining
    ; "hl" =  wTilemapPosition - Tilemap
    add hl, bc      


    call GetPercent
    


    ld b, c
    call BToBCD

    ld b, a
    ld a, %1111_0000
    and a, b
    swap a
    add a, 2
    sla a

    ld [STATUS_NUMBER_L + 2], a


    ld a, %0000_1111
    and a, b
    add a, 2
    sla a
    ld [STATUS_NUMBER_R + 2], a



    ret


; make work for 16 bit
; create a bitmap representing the the positions to find the percentage
; @param `hl` value to create the bitmap for
; @return `hl` bit map for percentage 
FindShifts:
    ; "hl" = value

    ; divide "hl" until it is a 8-bit number

    ; "e" = offset
    ld e, 0
.divideValueLoop:

    ; if ("h" == 0) -> break loop
    ld a, h
    cp a, 0
    jr z, .doneDivideValueLoop



    ; "hl" >> 1
    srl h
    rr l

    ; offset++
    inc e

    jr .divideValueLoop

.doneDivideValueLoop:
    ld c, l
    ; "c" = value



    ld b, 0         ; "b" = total

    ld d, 1         ; "d" = currentBit

    ld l, 0         ; "h" = bitmap
    



.loop:
    ; if ( value == 0 ) -> return
    
    ld a, c
    cp a, 0

    jr z, .done




    ; if (total + value <= 100) -> add current bit to bitmap. add value to total
    ld a, b
    add a, c    ; "a" = value + total
    cp a, 100
    jp z, .is100
    jp nc, .doneIf

.is100:


    ; bitmap = bitmap | currentBit;

    ld a, l
    or a, d
    ld l, a

    ; total += value;
    ld a, b
    add a, c
    ld b, a

    cp a, 100
    jr z, .done

.doneIf:
    srl c

    sla d
    

    jr .loop



.done:

    ld h, 0

.shiftLoop:




    ld a, e
    cp a, 0
    ret z
    dec e

    sla l
    rl h

    
    jr .shiftLoop



; find the percentage of completion for the level
; @param "hl" value to find percentage for
; @param "wBitShiftMap" determines divisions for percentage
; @return "c" value out of 100
GetPercent:
    ld a, [wBitShiftMap]
    ld e, a
    ld a, [wBitShiftMap + 1]
    ld d, a 
    
    ld c, 0         ; "c" = total



.loop:


    bit 0, e 

    jp z, .doneIf

    ld a, c
    add a, l
    ld c, a





.doneIf:

    ; bitMap = bitMap >> 1;
    sra h
    rr l 

    ; value = value >> 1;

    sra d
    rr e



    ld a, d
    or a, e
    ret z


    jp .loop


; convert a value (0-99) to binary coded decimal
; @param `b` value to convert to decimal
; @return `a` value in BCD
BToBCD:
    ld c, 7
    ld e, %0000_1111
    ld h, 5
    ld l, 3
    ld a, 0

.loop:

    sla b
    rl a

    ld d, a
    and a, e

    cp a, h
    ld a, d
    jr c, .noAdjust

    add a, l


.noAdjust:

    dec c
    jp nz, .loop
    sla b
    rl a


    ret
    
    

SECTION "Status ram", wram0
    ; holds the positions to find the percentage
    wBitShiftMap: dw
    wNegativeTilemap: dw