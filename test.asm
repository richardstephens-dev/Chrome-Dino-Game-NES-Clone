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

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

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

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

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

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

;; set up PPU
  lda $2002
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

;; load sprites
  ldx #$00
load_sprites:
  lda sprites, x
  sta $0200, x
  inx
  cpx #$20  ; 32 bytes
  bne load_sprites

;; clear the nametables
  ldx #$00
  ldy #$00
  lda $2002
  lda #$20
  sta $2006
  lda #$00
  sta $2006
clear_nametable:
  sta $2007
  inx
  bne clear_nametable
  iny
  cpy #$08
  bne clear_nametable

; enable interrupts
  cli

; enable NMI
  lda #%10010000 ; enable NMI, change background color to use second set of chr tiles
  sta $2000
  lda #%00011110 ; enable sprites and background
  sta $2001

forever:
  jmp forever

nmi:
  lda #$02  ; copy sprite data from $0200 to ppu memory
  sta $4014
  rti

palettes:
  .byte $22,$29,$1A,$0F,$22,$36,$17,$0f,$22,$30,$21,$0f,$22,$27,$17,$0F  ;background palette data
  .byte $22,$16,$27,$18,$22,$1A,$30,$27,$22,$16,$30,$27,$22,$0F,$36,$17  ;sprite palette data

sprites:
  .byte $08, $00, $00, $08
  .byte $08, $01, $00, $10
  .byte $10, $02, $00, $08
  .byte $10, $03, $00, $10
  .byte $18, $04, $00, $08
  .byte $18, $05, $00, $10
  .byte $20, $06, $00, $08
  .byte $20, $07, $00, $10

; Character memory
.segment "CHARS"
  .incbin "hellomario.chr"