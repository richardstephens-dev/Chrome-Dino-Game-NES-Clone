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
game_state: .res 1

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
  cpx #$20 ; 12*4 = 48 bytes in hex = 0x30
  bne load_palettes

;; load dino sprite
  ldx #$00
  ldy #$00
load_dino_sprite:
  lda dino_sprite, x
  sta $0200, x
  inx
  cpx #$30  ; 32 bytes
  bne load_dino_sprite

;; load nametable
load_nametable:
  lda $2002
  lda #$20
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
load_nametable_loop:
  lda nametable, x
  sta $2007
  inx
  cpx #$40 ; 64 bytes
  bne load_nametable_loop

;; load attributes
load_attributes:
  lda #$23
  sta $2006
  lda #$00
  sta $2006
  ldx #$00
load_attributes_loop:
  lda #$00
  sta $2007
  inx
  cpx #$10 ; 16 bytes
  bne load_attributes_loop

; enable interrupts
  cli

; enable NMI
  lda #%10010000 ; ppuctrl
  sta $2000
  lda #%00011110
  sta $2001

forever:
  jmp forever

jump:
  lda $0200, x
  sec
  sbc #$01
  sta $0200, x
  inx
  inx
  inx
  inx
  cpx #$30
  bne jump
  rts

read_controller_input:
latch_controller_input:
  lda #$01
  sta $4016
  lda #$00
  sta $4016

; read controller input
  ldx #$08
read_buttons:
  lda $4016
  lsr a
  rol buttons
  dex
  bne read_buttons

  lda buttons ; p1 a
  and #%10000000
  beq a_done
  ldx #$00
read_a:
  jsr jump
a_done:
  rts

nmi:
  lda #$00
  sta $2003
  lda #$02
  sta $4014
  jsr read_controller_input
  rti

palettes:
  .byte $0f,$00,$30,$0f,$0f,$00,$30,$0f,$0f,$00,$30,$0f,$0f,$00,$30,$0f
  .byte $0f,$00,$30,$0f,$0f,$00,$30,$0f,$0f,$00,$30,$0f,$0f,$00,$30,$0f

nametable:
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$05,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  .byte $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04

attribute:
  .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
  .byte %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

dino_sprite:
  ; .byte y, tile, attributes, x
  ; attributes: 
  ; 76543210
  ; ||||||||
  ; ||||||++- Palette (4 to 7) of sprite
  ; |||+++--- Unimplemented (read 0)
  ; ||+------ Priority (0: in front of background; 1: behind background)
  ; |+------- Flip sprite horizontally
  ; +-------- Flip sprite vertically
  .byte $88, $04, %00000000, $20 ; 
  .byte $88, $05, %00000000, $28
  .byte $90, $12, %00000000, $10
  .byte $90, $13, %00000000, $18
  .byte $90, $14, %00000000, $20
  .byte $90, $15, %00000000, $28
  .byte $98, $22, %00000000, $10
  .byte $98, $23, %00000000, $18
  .byte $98, $24, %00000000, $20
  .byte $a0, $32, %00000000, $10
  .byte $a0, $33, %00000000, $18
  .byte $a0, $34, %00000000, $20
.segment "CHARS"
  .incbin "dino.chr"