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

NAMETABLES  =   $0f

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
 lda #%00000001 	;select nametables
 sta NAMETABLES
 sta PPU_CTRL
 lda #%00011000
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

game_loop:

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

 bit PPU_STATUS
 bmi vBlankDo
 
 jmp game_loop

vBlankDo:
 jmp game_loop

nmi:
 rti

;████████████████████████████████████████████████████████████████

;palletes and stuff
palletes:
;oem sprites
 .byte $0f, $1d, $10, $20
 .byte $0f, $03, $13, $23
 .byte $0f, $04, $14, $24
 .byte $0f, $06, $16, $26
;background
 .byte $2c, $04, $14, $34
 .byte $0f, $03, $13, $23
 .byte $0f, $04, $14, $24
 .byte $0f, $06, $16, $26

music_notes:
 .byte $fd, $c9, $a9, $e1, $a9, $86

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

