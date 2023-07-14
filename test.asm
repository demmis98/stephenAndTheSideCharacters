;VARIABLES

PPU_CTRL    =   $2000	; PPU
PPU_MASK    =   $2001
PPU_STATUS  =   $2002	;can be used for vBlank checks
OAM_ADDR    =   $2003
OAM_DATA    =   $2004
PPU_SCROLL  =   $2005
PPU_ADDR    =   $2006
PPU_DATA    =   $2007
OAM_DMA     =   $4014

SQR1_VOLUME =   $4000	; APU
SQR1_SWEEP  =   $4001
SQR1_LOW    =   $4002
SQR1_HIGH   =   $4003
DMC_CONFIG  =   $4010
APU_STATUS  =   $4015
CONTROLLER_1=   $4016
CONTROLLER_2=   $4017
APU_FRAMES  =   $4017


	;my variables
INPUT_TEMP  =   $00
INPUT_1     =   $01
INPUT_2     =   $02

LEVEL_ID    =   $03
LEVEL_MODE  =   $04	;$00 single screen, $01 double screen, $02 double looping screen

	;init
INIT_DONE   =   $0a
INIT_COUNT  =   $0b

INIT_TEMP_0 =   $0c
INIT_TEMP_1 =   $0d
INIT_TEMP_2 =   $0e

NAMETABLES  =   $0f

GAME_MODE   =   $20	;$01 stephen, $02 hosuh, $12 stephen&hosuh, $21 hosuh&stephen

PLAYER_1    =   $30
TEMP_1      =   PLAYER_1 + $00
WALK_STATE_1=   PLAYER_1 + $01
WALK_COUNT_1=   PLAYER_1 + $02

X_1         =   PLAYER_1 + $04
Y_1         =   PLAYER_1 + $05
X_SPEED_1   =   PLAYER_1 + $06
Y_SPEED_1   =   PLAYER_1 + $07
X_SPEED_MAX_1   =   PLAYER_1 + $08

DIRECTION_1 =   PLAYER_1 + $09	;$00 left, $01 right

PALETTE_1_1 =   PLAYER_1 + $0d
PALETTE_1_2 =   PLAYER_1 + $0e
PALETTE_1_3 =   PLAYER_1 + $0f

SPRITES_1_C =   PLAYER_1 + $10	;original
SPRITES_1_V =   PLAYER_1 + $14	;flipped or not

PLAYER_2    =   $50
TEMP_2      =   PLAYER_2 + $00

SPRITES_2_C =   PLAYER_2 + $0c

COLLITIONS  =   $80
C_TEMP      =   COLLITIONS + $00
C_X_0       =   COLLITIONS + $01
C_X_1       =   COLLITIONS + $02
C_X_2       =   COLLITIONS + $03
C_X_3       =   COLLITIONS + $04
C_Y_0       =   COLLITIONS + $05
C_Y_1       =   COLLITIONS + $06
C_Y_2       =   COLLITIONS + $07
C_Y_3       =   COLLITIONS + $08
C_RESULT    =   COLLITIONS + $0a

LEVEL       =   $f0
LEVEL_TEMP  =   LEVEL + $00
LEVEL_TEMP_1=   LEVEL + $01
LEVEL_TEMP_2=   LEVEL + $02
LEVEL_TEMP_3=   LEVEL + $03
LEVEL_OFF_P =   LEVEL + $04	;pixels offset
LEVEL_TILES =   LEVEL + $10
LEVEL_TILES2=   LEVEL_TILES + $0100

	;sprites
H_SPRITES   =   $01	;hosuh
B_SPRITES   =   H_SPRITES + H_SPRITES + $10	;blocks

.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segement for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx APU_FRAMES; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx PPU_CTRL	; disable NMI
  stx PPU_MASK 	; disable rendering
  stx DMC_CONFIG; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit PPU_STATUS
  bpl vblankwait1

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0200, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  inx
  bne clear_memory

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit PPU_STATUS
  bpl vblankwait2

;████████████████████████████████████████████████████████████████

main:

load_palletes:
 lda PPU_STATUS
 lda #$3f
 sta PPU_ADDR
 lda #$10
 sta PPU_ADDR

 ldx #$00
 @loop:
 lda palletes,x
 sta PPU_DATA
 inx
 cpx #$20
 bne @loop

enable_rendering:
 lda #%00100001 	;select nametables
 sta NAMETABLES
 sta PPU_CTRL
 lda #%00011010
 sta PPU_MASK


init_sound:
 lda #$01		;music n stuff
 sta APU_STATUS
 lda #%00000000
 sta SQR1_SWEEP
 sta SQR1_VOLUME
 lda #$40
 sta APU_FRAMES

;████████████████████████████████████████████████████████████████

 lda #$01	;
 sta GAME_MODE	;
 lda #$00	;
 sta LEVEL_ID	;
 sta LEVEL_MODE ;

;████████████████████████████████████████████████████████████████

play_init:
 lda #%00100001
 sta NAMETABLES
 sta PPU_CTRL

 ldx #$00
 @loop_level_base_horizontal:

 lda #$03
 sta LEVEL_TILES + $00, x

 lda #$02
 sta LEVEL_TILES + $e0, x
 
 inx
 cpx #$10
 bne @loop_level_base_horizontal

 ldx #$01
 @loop_level_base_vertical:
 txa
 asl
 asl
 asl
 asl
 tay

 lda #$05
 sta LEVEL_TILES + $00, y

 lda #$04
 sta LEVEL_TILES + $0f, y
 
 inx
 cpx #$0e
 bne @loop_level_base_vertical
 
 lda #$06
 sta LEVEL_TILES + $00
 sta LEVEL_TILES + $0f
 sta LEVEL_TILES + $e0
 sta LEVEL_TILES + $ef

 lda LEVEL_MODE

	;load level sprites into the ppu
 lda #$00
 sta LEVEL_TEMP
 @level_wait:
 bit PPU_STATUS
 bmi @level_do
 jmp @level_wait

 @level_do:

 @row:
 lda LEVEL_TEMP
 lsr
 lsr
 lsr
 lsr
 clc
 adc #$20
 sta PPU_ADDR
 lda LEVEL_TEMP
 asl
 asl
 asl
 asl
 sta PPU_ADDR
 lda LEVEL_TEMP
 asl
 asl
 tax

 @x_1:
 lda LEVEL_TILES, x
 tay
 lda tiles_u_l, y
 sta PPU_DATA
 lda tiles_u_r, y
 sta PPU_DATA
 
 inx
 txa
 and #$0f
 cmp #$00
 bne @x_1

 lda LEVEL_TEMP
 asl
 asl
 tax
 @x_2:
 lda LEVEL_TILES, x
 tay
 lda tiles_d_l, y
 sta PPU_DATA
 lda tiles_d_r, y
 sta PPU_DATA
 
 inx
 txa
 and #$0f
 cmp #$00
 bne @x_2

 inc LEVEL_TEMP
 inc LEVEL_TEMP
 inc LEVEL_TEMP
 inc LEVEL_TEMP

 lda LEVEL_TEMP
 cmp #$40
 beq @load_end

 lda LEVEL_TEMP 
 and #$0f
 cmp #$00
 bne @level_wait
 jmp @row

 

 @load_end:

;████████████████████████████████████████████████████████████████

	;initial player position
 lda #$24
 sta X_1
 lda #$a4
 sta Y_1 

 lda GAME_MODE
 and #$01
 cmp #$01
 beq @load_hosuh_1

 lda GAME_MODE
 and #$02
 cmp #$02
 beq @load_stephen_1


 @load_hosuh_1:
 lda #$01
 sta INIT_TEMP_0
 sta INIT_TEMP_1
 jsr load_character


 jmp @end_load_1

 @load_stephen_1:
 lda #$02
 sta INIT_TEMP_0
 lda #$01
 sta INIT_TEMP_1
 jsr load_character

 @end_load_1:


 lda GAME_MODE
 and #$10
 cmp #$10
 beq @load_hosuh_2

 lda GAME_MODE
 and #$20
 cmp #$20
 beq @load_stephen_2

 @load_hosuh_2:
 lda #$01
 sta INIT_TEMP_0
 lda #$02
 sta INIT_TEMP_1
 jsr load_character

 jmp @end_load_2

 @load_stephen_2:
 lda #$02
 sta INIT_TEMP_0
 sta INIT_TEMP_1
 jsr load_character

 @end_load_2:
 jmp play_frame_do

load_character:
 lda INIT_TEMP_1	;load the sprites starting byte
 cmp #$01
 beq @player_1
 cmp #$02
 beq @player_2
 
 @player_1:
 lda #SPRITES_1_C

 jmp @player_end
 @player_2:
 lda #SPRITES_2_C

 jmp @player_end
 @player_end:

 tay
 ldx #$00
 
 lda INIT_TEMP_0
 cmp #$01
 beq @hosuh_loop
 cmp #$02
 beq @stephen_loop

 @hosuh_loop:
 stx INIT_TEMP_0
 lda #H_SPRITES
 clc
 adc INIT_TEMP_0
 sta $00, y

 iny
 inx
 cpx #$04
 bne @hosuh_loop
 jmp @end_load

 @stephen_loop:

 inx
 cpx #$04
 bne @stephen_loop
 jmp @end_load
 @end_load:
 
 rts

;████████████████████████████████████████████████████████████████

play_frame_do:

;████████████████████████████████████████████████████████████████

	;process player 1
 ldy #$02
 lda INPUT_1
 and #%01000000
 cmp #%01000000
 bne @not_b_1
 iny
 iny
 @not_b_1:
 sty X_SPEED_MAX_1

 lda #$00
 sta TEMP_1

 lda INPUT_1
 and #%00000001
 cmp #%00000001
 bne @not_right_1
 lda #$01
 sta DIRECTION_1
 sta TEMP_1
 @not_right_1:

 lda INPUT_1
 and #%00000010
 cmp #%00000010
 bne @not_left_1
 sta TEMP_1
 lda #$00
 sta DIRECTION_1
 @not_left_1:

 

;████████████████████████████████████████████████████████████████

 lda TEMP_1
 cmp #$00
 beq @not_moving
 inc X_SPEED_1

 jmp @first_move_loop
 @not_moving:
 lda X_SPEED_1
 cmp #$00
 beq @speed_1_not_0
 dec X_SPEED_1
 @speed_1_not_0:
 @first_move_loop:

 lda DIRECTION_1
 ror
 bcc @move_left
 lda X_1
 clc
 adc X_SPEED_1
 clc	;;;;;;;;;;;;;;;;;;;;
 cmp #$e6	;;;;;;;;;;;;;;;;;;;;;;beta collitions
 bcs @move_end	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 sta X_1

 jmp @move_end
 @move_left:
 lda X_1
 sec
 sbc X_SPEED_1
 sta X_1

 @move_end:

;████████████████████████████████████████████████████████████████
 
play_loop:

	;important processing for player 1
 clc
 lda X_SPEED_1
 cmp X_SPEED_MAX_1
 bcc @not_max_speed_1
 dec X_SPEED_1
 @not_max_speed_1:

;████████████████████████████████████████████████████████████████

	;store sprites for p1
 lda DIRECTION_1
 cmp #$00
 beq @flip_sprites_1
 ldx #$00
 @loop_not_flip_sprites_1:
 lda SPRITES_1_C, x
 sta SPRITES_1_V, x

 inx
 cpx #$04
 bne @loop_not_flip_sprites_1
 jmp @end_sprites_1
 @flip_sprites_1:
 ldx #$00
 @loop_flip_sprites_1:
	;flip if necesary
 lda SPRITES_1_C, x
 inx
 sta SPRITES_1_V, x
 lda SPRITES_1_C, x
 dex
 sta SPRITES_1_V, x
 
 inx
 inx
 cpx #$04
 bne @loop_flip_sprites_1
 @end_sprites_1:

;████████████████████████████████████████████████████████████████

 lda GAME_MODE
 and #$f0
 cmp #$00
 beq @not_player_2

 @not_player_2:

 jsr controller

 bit PPU_STATUS
 bmi vBlankDo
 
 jmp play_loop

vBlankDo:
 lda #$20	;player 1
 sta OAM_ADDR
 
 ldx #$00
 sta TEMP_1
 @player_1_loop:
 lda TEMP_1
 asl
 asl
 asl
 asl
 clc
 adc Y_1
 sta OAM_DATA

 lda SPRITES_1_V, x
 asl
 sta OAM_DATA
 
 lda DIRECTION_1
 asl
 asl
 asl
 asl
 asl
 asl
 clc
 adc #%01000011
 and #%01000011
 sta OAM_DATA
 sta $80

 txa
 and #%0000001
 asl
 asl
 asl
 clc
 adc X_1
 sbc LEVEL_OFF_P
 sta OAM_DATA

 txa
 and #%0000001
 cmp #%0000001
 bne @not_increment_temp_y
 inc TEMP_1
 @not_increment_temp_y:
 inx
 cpx #$04
 bne @player_1_loop

 lda LEVEL_OFF_P
 sta PPU_SCROLL
 lda #$00
 sta PPU_SCROLL

 jmp play_frame_do


;████████████████████████████████████████████████████████████████

controller:
 lda #$01	;init controller 1
 sta CONTROLLER_1
 sta INPUT_TEMP
 lda #$00
 sta CONTROLLER_1
 
 @controller_loop_1:
 lda CONTROLLER_1
 lsr
 rol INPUT_TEMP
 bcc @controller_loop_1
 lda INPUT_TEMP
 sta INPUT_1

 lda #$01	;init controller 2
 sta CONTROLLER_2
 sta INPUT_TEMP
 lda #$00
 sta CONTROLLER_2
 
 @controller_loop_2:
 lda CONTROLLER_2
 lsr
 rol INPUT_TEMP
 bcc @controller_loop_2
 lda INPUT_TEMP
 sta INPUT_2

 rts

;████████████████████████████████████████████████████████████████

collition:
 lda #$00
 ldx C_X_0
 clc
 cpx C_X_3
 bcs @1st
 adc #$01
 @1st:

 ldx C_X_1
 clc
 cpx C_X_2
 bcc @2nd
 clc
 adc #$02
 @2nd:

 ldx C_Y_0
 clc
 cpx C_Y_3
 bcs @3rd
 adc #$04
 @3rd:

 ldx C_Y_1
 clc
 cpx C_Y_2
 bcc @4th
 clc
 adc #$08
 @4th:

 sta C_RESULT

 rts

;████████████████████████████████████████████████████████████████

nmi:
 rti

;████████████████████████████████████████████████████████████████

	;palletes and stuff
palletes:
	;oem sprites
 .byte $0f, $03, $13, $23
 .byte $0f, $04, $14, $24
 .byte $0f, $06, $16, $26
 .byte $0f, $00, $10, $20

	;background
 .byte $2c, $04, $14, $34
 .byte $20, $04, $14, $34
 .byte $0f, $04, $14, $24
 .byte $0f, $06, $16, $26


music_notes:
 .byte $fd, $c9, $a9, $e1, $a9, $86

tiles_u_l:
 .byte $00, B_SPRITES+$00, B_SPRITES+$01, B_SPRITES+$00, B_SPRITES+$03, B_SPRITES+$00, B_SPRITES+$00
tiles_u_r:
 .byte $00, B_SPRITES+$00, B_SPRITES+$01, B_SPRITES+$00, B_SPRITES+$00, B_SPRITES+$04, B_SPRITES+$00
tiles_d_l:
 .byte $00, B_SPRITES+$00, B_SPRITES+$00, B_SPRITES+$02, B_SPRITES+$03, B_SPRITES+$00, B_SPRITES+$00
tiles_d_r:
 .byte $00, B_SPRITES+$00, B_SPRITES+$00, B_SPRITES+$02, B_SPRITES+$00, B_SPRITES+$04, B_SPRITES+$00

;████████████████████████████████████████████████████████████████

; Character memory
.segment "CHARS"

  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; BLANK

  .byte %00000000; 0
  .byte %00001100
  .byte %00011110
  .byte %00011010
  .byte %00011010
  .byte %00011010
  .byte %00001100
  .byte %00000000
  .byte %00000000;
  .byte %00001100
  .byte %00010010
  .byte %00010010
  .byte %00010010
  .byte %00010010
  .byte %00001100
  .byte %00000000

	;hosuh
  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; BLANK

  .byte %00000000; oxipital
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000011
  .byte %00000111
  .byte %00000111
  .byte %00001011
  .byte %00000000;
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00001111
  .byte %00001011
  .byte %00000011
  .byte %00000101

  .byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; BLANK

  .byte %00000000; forehead
  .byte %00100000
  .byte %01000000
  .byte %00010100
  .byte %00100100
  .byte %11111000
  .byte %10101000
  .byte %10101000
  .byte %11100000;
  .byte %11010000
  .byte %10111000
  .byte %11101000
  .byte %11011000
  .byte %00100000
  .byte %11110000
  .byte %11110000

  .byte %00000110; back
  .byte %00000001
  .byte %00000001
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00001111
  .byte %00001111
  .byte %00011001;
  .byte %00011100
  .byte %00001100
  .byte %00000000
  .byte %00000011
  .byte %00000111
  .byte %00000110
  .byte %00000101

  .byte %00011111; back leg
  .byte %00011111
  .byte %00001111
  .byte %00000111
  .byte %00000111
  .byte %00000111
  .byte %00000111
  .byte %00000011
  .byte %00001101;
  .byte %00001101
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000011
  .byte %00000000

  .byte %11111000; front
  .byte %11110000
  .byte %11100000
  .byte %11000000
  .byte %11100000
  .byte %11100000
  .byte %11110000
  .byte %11111000
  .byte %11110000;
  .byte %01100000
  .byte %10000000
  .byte %10000000
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %11010000

  .byte %11111000; front leg
  .byte %11110000
  .byte %11100000
  .byte %11100000
  .byte %11100000
  .byte %11110000
  .byte %11110000
  .byte %11100000
  .byte %11010000;
  .byte %11000000
  .byte %11000000
  .byte %01000000
  .byte %01000000
  .byte %10100000
  .byte %10100000
  .byte %00000000

  .byte %00001011; back for animation 1
  .byte %00000001
  .byte %00000001
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00011111
  .byte %00011111
  .byte %00110101;
  .byte %00111000
  .byte %00011000
  .byte %00000000
  .byte %00000001
  .byte %00000111
  .byte %00001101
  .byte %00001101

  .byte %00111111; back leg for animation 1
  .byte %00111111
  .byte %00011111
  .byte %00000111
  .byte %00001111
  .byte %00001111
  .byte %00001111
  .byte %00000110
  .byte %00011011;
  .byte %00011011
  .byte %00000011
  .byte %00000011
  .byte %00000101
  .byte %00000110
  .byte %00000110
  .byte %00000000

  .byte %11111000; front for animation 1
  .byte %11110000
  .byte %11100000
  .byte %11000000
  .byte %11100000
  .byte %11110000
  .byte %11111100
  .byte %11111110
  .byte %11110000;
  .byte %01100000
  .byte %10000000
  .byte %10000000
  .byte %11000000
  .byte %11100000
  .byte %11110000
  .byte %11011100

  .byte %11111110; front leg for animation 1
  .byte %11101100
  .byte %11100000
  .byte %11110000
  .byte %11111000
  .byte %11111000
  .byte %11110000
  .byte %01100000
  .byte %11001100;
  .byte %11000000
  .byte %11000000
  .byte %11000000
  .byte %10110000
  .byte %11110000
  .byte %01100000
  .byte %00000000

  .byte %00001011; back for animation 2
  .byte %00000001
  .byte %00000001
  .byte %00000011
  .byte %00000111
  .byte %00001111
  .byte %00001111
  .byte %00001111
  .byte %00000101;
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000011
  .byte %00000111
  .byte %00000110
  .byte %00000111

  .byte %00000111; back leg for animation 2
  .byte %00000111
  .byte %00000111
  .byte %00001111
  .byte %00011111
  .byte %00011111
  .byte %00001111
  .byte %00000110
  .byte %00000011;
  .byte %00000000
  .byte %00000011
  .byte %00000111
  .byte %00001100
  .byte %00001110
  .byte %00000110
  .byte %00000000

  .byte %11111000; front for animation 2
  .byte %11110000
  .byte %11100000
  .byte %11000000
  .byte %11100000
  .byte %11110000
  .byte %11110000
  .byte %11111000
  .byte %11110000;
  .byte %01100000
  .byte %10000000
  .byte %10000000
  .byte %11000000
  .byte %11100000
  .byte %11100000
  .byte %00100000

  .byte %11111000; front leg for animation 2
  .byte %11110000
  .byte %11110000
  .byte %11111100
  .byte %11111110
  .byte %01111110
  .byte %00111100
  .byte %00011000
  .byte %11000000;
  .byte %11000000
  .byte %00100000
  .byte %11100000
  .byte %01101100
  .byte %00111100
  .byte %00011000
  .byte %00000000

	;blocks
  .byte %11111111; floor
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111;
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

  .byte %11111111; top of the floor
  .byte %01010101
  .byte %00000000
  .byte %10101010
  .byte %01010101
  .byte %11111111
  .byte %10101010
  .byte %11111111
  .byte %00000000;
  .byte %10101010
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

  .byte %11111111; bottom of the floor
  .byte %01010101
  .byte %11111111
  .byte %10101010
  .byte %01010101
  .byte %00000000
  .byte %10101010
  .byte %11111111
  .byte %11111111;
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %01010101
  .byte %00000000

  .byte %11001101; left of the floor
  .byte %10010111
  .byte %11001101
  .byte %10010111
  .byte %11001101
  .byte %10010111
  .byte %11001101
  .byte %10010111
  .byte %00111111;
  .byte %01111111
  .byte %00111111
  .byte %01111111
  .byte %00111111
  .byte %01111111
  .byte %00111111
  .byte %01111111

  .byte %11101001; right of the floor
  .byte %10110011
  .byte %11101001
  .byte %10110011
  .byte %11101001
  .byte %10110011
  .byte %11101001
  .byte %10110011
  .byte %11111110;
  .byte %11111100
  .byte %11111110
  .byte %11111100
  .byte %11111110
  .byte %11111100
  .byte %11111110
  .byte %11111100




  .byte %00000000; empty but in binary
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000;
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
  .byte %00000000
