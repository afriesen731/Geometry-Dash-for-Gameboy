DEF PLAYER_WIDTH EQU 16
; integer for top left of the players Y starting position
DEF PLAYER_Y_START EQU 144 - 16
; integer for top left of the players Left starting position
DEF PLAYER_X_START EQU 8

DEF FP_PLAYER_X_VEL_START EQU %00100111


DEF FP_JUMP_VEL EQU %1000_1111
DEF FP_BOUNCE_PAD_VEL EQU %1000_0000
DEF FP_FLOATING_BOUNCE_PAD_VEL EQU %1000_0000



DEF DECELERATION_Y EQU %0000_1001



DEF MAX_FALL_SPEED EQU %0101_0000 

DEF STATE_IN_AIR EQU %00000001
                    
; the fixed point position where the background is moved instead of the player on the right side of the screen
DEF RIGHT_X_BOUNDRY EQU 20; 20
; the fixed point position where the background is moved instead of the player on the left side of the screen
DEF LEFT_X_BOUNDRY EQU 8 ; 8



; the fixed point position where the background is moved instead of the player on the top of the screen
DEF TOP_Y_BOUNDRY EQU 48 ; 16 + 32 = 48

; the fixed point position where the background is moved instead of the player on the bottom of the screen
DEF BOTTOM_Y_BOUNDRY EQU 120 ; 144 - 16 = 128

; stop scrolling when on ground
DEF MAX_Y_SCROLL EQU 112 