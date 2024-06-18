SECTION "helper", rom0
; flips the sign of an 8bit 2's compliment number
; @param a number to flip
; @return a fliped number
FlipSign8Bit::
    ld b, a         ; save a in b

    and a           ; check if zero
    ret z

    and a, %1000_0000   
    jr nz, .negative

.positive
    ld a, b
    cpl
    inc a
    ret
.negative
    ld a, b
    dec a
    cpl
    ret


; shifts a 16 bit number to the left
; @param a number of shifts
; @param bc value to shift
; @ret bc value shifted
ShiftWLeft::
    ld d, a
    
.Loop

    sla c
    rl b
    ; check if loop condition is zero
    dec d

    ld a, 0
    cp d
    ret z
    jp .Loop





; Convert a pixel position to a tilemap address
; hl = $9800 + X + Y * 32
; @param b: X
; @param c: Y
; @return hl: tile address
GetTileByPixel:
    ; First, we need to divide by 8 to convert a pixel position to a tile position.
    ; After this we want to multiply the Y position by 32.
    ; These operations effectively cancel out so we only need to mask the Y value.
    ld a, c
    and a, %11111000
    ld l, a
    ld h, 0
    ; Now we have the position * 8 in hl
    add hl, hl ; position * 16
    add hl, hl ; position * 32
    ; Convert the X position to an offset.
    ld a, b
    srl a ; a / 2
    srl a ; a / 4
    srl a ; a / 8
    ; Add the two offsets together.
    add a, l
    ld l, a
    adc a, h
    sub a, l
    ld h, a
    ; Add the offset to the tilemap's base address, and we are done!
    ld bc, $9800
    add hl, bc
    ret





; ------------------------------------------------------------------------------
; `func FixedPointToInt(hl)`
;
; Converts a 12.4 fixed point value to an 8-bit integer and stores the result in
; the `a` register.
;
; - Param `hl` - The address to the low byte of the 12.4 fixed point value to be
;   converted.
; - Return `a` - The converted value.
; ------------------------------------------------------------------------------
FixedPointToInt::
    inc hl
    ld a, [hld]
    ld b, a
    ld a, [hl]
    srl b
    rr a
    srl b
    rr a
    srl b
    rr a
    srl b
    rr a
    ret





