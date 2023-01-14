; This is a demo project for learning 6502 Assembly for the NES.
; The goal is a bottom-to-top platformer called "Ghost in Limbo".
; Boilerplate template from https://github.com/NesHacker/DevEnvironmentDemo/blob/main/demo.s
.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $00, $00        ; mapper 0, mirroring: horizontal

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
  stx $2000	  ; disable NMI
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
  bit $2002
  bpl vblankwait2

;; load all the palettes
lda $2002 ; Read PPU status to reset address latch
lda #$3f  ; Set the first palette address to 3F
sta $2006 ; Set the PPU address
ldy #$00  ; set the palette index to 0
ldx #$00  ; set the palette color to 0

load_palettes:
  ; Get the first palette address and offset it by the palette index
  lda #$3f
  adc y
  iny
  ; if all 11 palettes have been loaded, continue
  cpy #$0b
  bne load_palette

load_palette:
  ; Load the current palette address
  sta $2006
  ; Load the current palette color
  lda palette, x
  sta $2007
  ; Increment the palette color
  inx
  ; If less than 12 bytes, go to load_palette
  cpx #$0c
  bne load_palette
  ; If not all 11 palettes have been loaded, go to load_palettes
  cpy #$0b
  bne load_palettes

;; load CHR (sprites and backgrounds) data
; Use DMA (direct memory access) $4014 to copy data from RAM to PPU
; 
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer

;; Main game loop
main:
;; TODO: Add game code here

forever:
  jmp forever

nmi:
  rti

; Character memory
.segment "CHARS"

.segment "DATA"
heaven_palette:
  .byte $FF, $FF, $CC, $99, $99, $66, $00, $00, $00, $FF, $FF, $FF
limbo_palette:
  .byte $CC, $FF, $FF, $99, $99, $99, $FF, $FF, $CC, $00, $00, $00
lust_palette:
  .byte $FF, $00, $00, $FF, $99, $00, $FF, $CC, $99, $00, $00, $00
gluttony_palette:
  .byte $66, $00, $66, $00, $66, $00, $66, $33, $00, $00, $00, $00
avarice_palette:
  .byte $00, $00, $66, $00, $00, $00, $66, $66, $66, $FF, $FF, $FF
wrath_palette:
  .byte $FF, $33, $00, $FF, $66, $00, $FF, $FF, $00, $00, $00, $00
heresy_palette:
  .byte $66, $00, $99, $00, $00, $99, $00, $00, $00, $FF, $FF, $FF
violence_palette:
  .byte $FF, $00, $00, $FF, $66, $00, $00, $00, $00, $FF, $FF, $FF
fraud_palette:
  .byte $00, $99, $00, $66, $00, $99, $00, $00, $99, $00, $00, $00
treachery_palette:
  .byte $00, $00, $66, $66, $00, $66, $00, $00, $00, $FF, $FF, $FF
ghost_palette:
  .byte $FF, $FF, $FF, $CC, $CC, $CC, $99, $99, $99, $00, $00, $00