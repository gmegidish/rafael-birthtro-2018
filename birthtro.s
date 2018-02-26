
PPU_CTRL        = $2000
PPU_MASK        = $2001
PPU_STATUS      = $2002
PPU_SCROLL      = $2005
PPU_ADDR        = $2006
PPU_DATA        = $2007
APU_DMC_CTRL    = $4010
APU_CHAN_CTRL   = $4015

; NOTE: Many of these are expressed in binary,
; to highlight which bit(s) they pertain to:
NT_0            = %00       ; Use nametable 0 ($2000).
NT_1            = %01       ; Use nametable 1 ($2400).
NT_2            = %10       ; Use nametable 2 ($2800).
NT_3            = %11       ; Use nametable 3 ($2C00).
VRAM_RIGHT      = %000      ; Increment nametable address rightwards, after a write.
VRAM_DOWN       = %100      ; Increment nametable address downwards, after a write.
SPR_0           = %0000     ; Use sprite pattern table 0.
SPR_1           = %1000     ; Use sprite pattern table 1.
BG_0            = %00000    ; Use background pattern table 0 ($0000).
BG_1            = %10000    ; Use background pattern table 1 ($1000).
SPR_8x8         = %00000    ; Use standard 8x8 sprites.
SPR_8x16        = %100000   ; Use 8x16 sprites, instead of 8x8.
NO_VBLANK_NMI   = %00000000 ; Don't generate VBLANK NMIs.
VBLANK_NMI      = %10000000 ; DO generate VBLANK NMIs.

; PPU_MASK bit flags:
COLOR_NORMAL    = %0
COLOR_GRAYSCALE = %1
HIDE_BG_LHS     = %00       ; Hide left-most 8 pixels of the background.
SHOW_BG_LHS     = %10       ; Show left-most 8 pixels of BG.
HIDE_SPR_LHS    = %000      ; Prevent displaying sprites in left-most 8 pixels of screen.
SHOW_SPR_LHS    = %100      ; Show sprites in left-most 8 pixels of screen.
BG_OFF          = %0000     ; Hide background.
BG_ON           = %1000     ; Show background.
SPR_OFF         = %00000    ; Hide sprites.
SPR_ON          = %10000    ; Show sprites.


.segment "INESHDR"
	.byt "NES",$1A
	.byt 1 				; 1 x 16kB PRG block.
	.byt 1 				; 1 x 8kB CHR block.
	; Rest of iNES header defaults to 0, indicating mapper 0, standard RAM size, etc.

.segment "VECTORS"
	.addr nmi_isr, reset, irq_isr

.segment "ZEROPAGE"

delay:    .res 1
scroll_y: .res 1

.segment "RODATA"

palette:
	.byt $07, $0c, $38, $16			; palette 0
	.byt $05, $00, $01, $02			; palette 1

	.byt $07, $0c, $38, $16			; palette 2
	.byt $05, $00, $01, $02			; palette 3

	.byt $07, $0c, $38, $16			; sprite palette 0
	.byt $05, $00, $01, $02			; sprite palette 1

	.byt $07, $0c, $38, $16			; sprite palette 2
	.byt $05, $00, $01, $02			; sprite palette 3

.segment "PATTERN0"
	.incbin "tileset.chr"

.segment "CODE"

reset:
	cld
	sei			; disable interrupts

	lda #$00
	sta PPU_CTRL		; nmi disabled
	sta PPU_MASK		; disable video output
	sta APU_DMC_CTRL	; disable dmc irq

	sta delay
	sta scroll_y

	ldx #$ff
	txs			; initialize stack pointer

	bit PPU_STATUS		; ack vblank nmi
	bit APU_CHAN_CTRL	; ack dmc irq

	jsr copy_palette
	jsr render_background

        lda #VBLANK_NMI|BG_0|SPR_0|NT_0|VRAM_RIGHT
	sta PPU_CTRL

	lda #BG_ON|SPR_ON
	sta PPU_MASK

	jmp endless_loop

copy_palette:
	lda #$3f		; set ppu_addr to $3f00 (palette)
	sta PPU_ADDR
	lda #$00
	sta PPU_ADDR

	ldx #0
:	lda palette, x
	sta PPU_DATA
	inx
	cpx #32
	bne :-
	rts

render_background:

	ldx #$20
	stx PPU_ADDR
	ldx #$00
	stx PPU_ADDR

	ldx #$00
:	stx PPU_DATA
	inx
	bne :-

	rts

vblank:
	bit PPU_STATUS
	bpl vblank		; 7th bit on = we're in vblank
	rts

endless_loop:

	jsr vblank

	dec scroll_y
	lda scroll_y
	sta PPU_SCROLL
	lda #$0
	sta PPU_SCROLL

	jmp endless_loop

nmi_isr:
	rti

irq_isr:
	rti





