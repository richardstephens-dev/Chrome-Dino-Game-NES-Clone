; This is a demo project for learning 6502 Assembly for the NES.
; The goal is a bottom-to-top platformer called "Ghost in Limbo".
; Boilerplate template from https://github.com/NesHacker/DevEnvironmentDemo/blob/main/demo.s
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

.segment "ZEROPAGE"
; variable to hold world data pointer
world: .res 2
score: .res 1
buttons: .res 1

RIGHTWALL =$02
LEFTWALL =$F6
BOTTOMWALL =$D8
TOPWALL =$20

.segment "STARTUP"

vblankwait:
  bit $2002
  bpl vblankwait
  rts

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

  jsr vblankwait

clear_memory:
  lda #$00
  sta $0000, x
  sta $0100, x
  sta $0300, x
  sta $0400, x
  sta $0500, x
  sta $0600, x
  sta $0700, x
  lda #$ff
  sta $0200, x ; for storing chr data
  lda #$00
  inx
  bne clear_memory
  
  jsr vblankwait

;; set up PPU
  lda #$02
  sta $4014
  nop

;; set up CHR memory
  lda #$3f
  sta $2006
  lda #$00
  sta $2006

;; load chr data
  ldx #$00

  lda #$3f
  sta $2006
  lda #$00
  sta $2006

;; load palettes 
  ldx #$00
load_palettes:
  lda palettes, x
  sta $2007
  inx
  cpx #$20
  bne load_palettes

;; load world data TUTORIAL
  ; initialize world var to point to the start of the world data
  lda #<world_data ; lo byte
  sta world ; store in world var
  lda #>world_data ; hi byte
  sta world+1 ; store in world var

  ; set up address in PPU memory for world -> nametable data
  ; using table at $2000
  ; first reset ppu latch
  bit $2002
  lda #$20
  sta $2006 ; hi byte
  lda #$00
  sta $2006 ; lo byte

  ldx #$00 ; index to count how many times we got to 255
  ldy #$00 ; index to 255  
load_world_data:
  lda (world), y
  sta $2007
  iny
  cpx #$03
  bne :+
  cpy #$c0
  beq done_loading_world_data
:
  cpy #$00
  bne load_world_data
  inx
  inc world+1
  jmp load_world_data

done_loading_world_data:

;; set up attribute table
  ldx #$00
set_attrs:
  lda #$55
  sta $2007
  inx
  cpx #$40 ; 64 bytes
  bne set_attrs

  ldx #$00
  ldy #$00
load_sprites:
  lda sprites, x
  sta $0200, x
  inx
  cpx #$20  ; 32 bytes
  bne load_sprites

; enable interrupts
  cli

; enable NMI
  lda #%10010000 ; enable NMI, change background color to use second set of chr tiles
  sta $2000
  lda #%00011110 ; enable sprites and background
  sta $2001

forever:
  jmp forever

move_right:
  lda $0203, x
  sec
  sbc #$01
  sta $0203, x
  rts

move_left:
  lda $0203, x
  clc
  adc #$01
  sta $0203, x
  rts

read_controller_input:
; latch controller input
  lda #$01
  sta $4016
  lda #$00
  sta $4016

; read controller input
  ldx #$08
read_buttons:
  lda $4016
  lsr a
  rol buttons ; push last bit into carry flag and out again
  dex
  bne read_buttons

  lda buttons ; p1 a
  and #%10000000
  beq a_done
  ldx #$00
read_a:
  jsr move_left
  inx
  inx
  inx
  inx
  cpx #$20
  bne read_a
a_done:

  lda buttons ; p1 a
  and #%01000000
  beq b_done
  ldx #$00
read_b:
  jsr move_right
  inx
  inx
  inx
  inx
  cpx #$20
  bne read_b
b_done:
  rts

nmi:
  lda #$00
  sta $2003
  lda #$02  ; copy sprite data from $0200 to ppu memory
  sta $4014

  jsr read_controller_input

  rti

palettes:
  .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
  .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17  ;sprite palette data

; TUTORIAL
world_data:
  .incbin "world.bin"

sprites:
  .byte $20, $00, %11000000, $10
  .byte $20, $01, %11000000, $08
  .byte $18, $02, %11000000, $10
  .byte $18, $03, %11000000, $08
  .byte $10, $04, %11000000, $10
  .byte $10, $05, %11000000, $08
  .byte $08, $06, %11000000, $10
  .byte $08, $07, %11000000, $08; Character memory
.segment "CHARS"
  .incbin "hellomario.chr"