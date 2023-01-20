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
  lda #%10011000 ; ppuctrl
  sta $2000
  lda #%00011110
  sta $2001

forever:
  jmp forever

move_up:
  lda $0200, x
  sec
  sbc #$01
  sta $0200, x
  rts

move_down:
  lda $0200, x
  clc
  adc #$01
  sta $0200, x
  rts

read_controller_input:
latch_controller_input:
  lda #$01
  sta $4016
  lda #$00
  sta $4016

; read controller input
  ldx #$08
read_downuttons:
  lda $4016
  lsr a
  rol buttons
  dex
  bne read_downuttons

  lda buttons ; p1 up
  and #%00001000
  beq up_done
  ldx #$00
read_up:
  jsr move_up
  inx
  inx
  inx
  inx
  cpx #$20
  bne read_up
up_done:

  lda buttons ; p1 down
  and #%00000100
  beq down_done
  ldx #$00
read_down:
  jsr move_down
  inx
  inx
  inx
  inx
  cpx #$20
  bne read_down
down_done:
  rts

nmi:
  lda #$00
  sta $2003
  lda #$02
  sta $4014
  jsr read_controller_input
  rti

palettes:
  .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
  .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17  ;sprite palette data

sprites:
  ; y, tile, attributes, x
  .byte $08, $f9, %11000000, $08
  .byte $08, $f9, %10000000, $10
  .byte $10, $f8, %00000000, $08
  .byte $10, $f8, %00000000, $10
  .byte $18, $f8, %00000000, $08
  .byte $18, $f8, %00000000, $10
  .byte $20, $f9, %01000000, $08
  .byte $20, $f9, %00000000, $10
.segment "CHARS"
  .incbin "hellomario.chr"