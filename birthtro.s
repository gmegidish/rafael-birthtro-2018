
PPU_CTRL	= $2000
PPU_MASK	= $2001
PPU_STATUS	= $2002
PPU_SCROLL	= $2005
PPU_ADDR	= $2006
PPU_DATA	= $2007

OAM_ADDR	= $2003
OAM_DATA	= $2004
OAM_DMA		= $4014

APU_DMC_CTRL	= $4010
APU_CHAN_CTRL	= $4015

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

ptr: .res 2
delay: .res 1
scroll_y: .res 1
tmp: .res 1

direction: .res 1				; speed*direction of moving face
face_x: .res 1					; position of left topmost pixel

frame_counter: .res 1

.segment "BSS"

spritelist: .res 256				; must be aligned to $ff00

.segment "RODATA"

palette:
	.byt $05				; global background color ($3f00)

	.byt $0c, $38, $16, $05			; palette 0 ($3f01-$3f03)
	.byt $00, $00, $00, $05			; palette 1 ($3f05-$3f07)
	.byt $00, $00, $00, $05			; palette 2 ($3f09-$3f0b)
	.byt $00, $00, $00, $05			; palette 3 ($3f0d-$3f0f)

	.byt $00				; global sprite background ($3f10)
	.byt $0f, $2d, $3d, $05			; sprite palette 0 ($3f11-$3f13)
	.byt $00, $00, $00, $05			; sprite palette 1 ($3f15-$3f17)
	.byt $00, $00, $00, $05			; sprite palette 2 ($3f19-$3f1b)
	.byt $00, $00, $00, $05			; sprite palette 3 ($3f1d-$3f1f)


sinus:
	; sin(2 * x * 3.14 / 180) * 16
	; 0 < x < 180
	.byt $00, $01, $01, $02, $02, $03, $03
	.byt $04, $04, $05, $05, $06, $07, $07, $07
	.byt $08, $08, $09, $09, $0a, $0a, $0b, $0b
	.byt $0b, $0c, $0c, $0c, $0d, $0d, $0d, $0e
	.byt $0e, $0e, $0e, $0f, $0f, $0f, $0f, $0f
	.byt $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
	.byt $0f, $0f, $0f, $0f, $0f, $0f, $0f, $0f
	.byt $0e, $0e, $0e, $0e, $0d, $0d, $0d, $0c
	.byt $0c, $0c, $0b, $0b, $0b, $0a, $0a, $09
	.byt $09, $08, $08, $08, $07, $07, $06, $06
	.byt $05, $04, $04, $03, $03, $02, $02, $01
	.byt $01, $00, $00, $00, $ff, $ff, $fe, $fe
	.byt $fd, $fd, $fc, $fc, $fb, $fb, $fa, $fa
	.byt $f9, $f9, $f8, $f8, $f7, $f7, $f6, $f6
	.byt $f5, $f5, $f5, $f4, $f4, $f4, $f3, $f3
	.byt $f3, $f2, $f2, $f2, $f2, $f1, $f1, $f1
	.byt $f1, $f1, $f1, $f1, $f1, $f1, $f1, $f1
	.byt $f1, $f1, $f1, $f1, $f1, $f1, $f1, $f1
	.byt $f1, $f1, $f2, $f2, $f2, $f2, $f3, $f3
	.byt $f3, $f4, $f4, $f4, $f5, $f5, $f5, $f6
	.byt $f6, $f7, $f7, $f8, $f8, $f8, $f9, $f9
	.byt $fa, $fa, $fb, $fc, $fc, $fd, $fd, $fe
	.byt $fe, $ff, $ff, $00

name_table:
	.incbin "tileset.nam"

rom_spritelist:
	.incbin "rafael-face-spritelist"

.segment "PATTERN0"
	.incbin  "tileset.chr"

.segment "PATTERN1"
	.incbin "rafael-face-chr"

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
	sta frame_counter
	sta face_x		; we start on the left

	lda #2			; we start by moving right
	sta direction

	ldx #$ff
	txs			; initialize stack pointer

	bit PPU_STATUS		; ack vblank nmi
	bit APU_CHAN_CTRL	; ack dmc irq

	jsr copy_sprites_to_ram

	jsr copy_sprites
	jsr copy_palette
	jsr render_background

        lda #VBLANK_NMI|BG_0|SPR_0|NT_0|VRAM_RIGHT|SPR_8x16
	sta PPU_CTRL

	lda #BG_ON|SPR_ON|SHOW_BG_LHS|SHOW_SPR_LHS
	sta PPU_MASK

	jmp endless_loop

copy_sprites_to_ram:

	ldx #$0			; copy spritelist to ram, so we can use DMA
:	lda rom_spritelist,x
	sta spritelist,x
	inx
	bne :-
	rts

copy_sprites:

	lda #$0			; start writing from sprite 0
	sta OAM_ADDR

	lda #>spritelist
	sta OAM_DMA
	rts

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

	ldx #$20		; copy the first 1024 bytes from name_table into $2000
	stx PPU_ADDR
	ldx #$00
	stx PPU_ADDR

	lda #<name_table	; src pointer
	sta ptr+0
	lda #>name_table
	sta ptr+1

	ldx #4			; 4 x 256 bytes
	ldy #0
:	lda (ptr),y
	sta PPU_DATA
	iny
	bne :-
	inc ptr+1
	dex
	bne :-

	rts

vblank:
	bit PPU_STATUS
	bpl vblank		; 7th bit on = we're in vblank
	rts

move_head:
	clc
	lda face_x
	adc direction
	sta face_x

	bne :+
	lda #2
	sta direction
	rts
:	cmp #256-64
	beq :+
	rts
:	lda #$fe
	sta direction
	rts

update_sprites:
	ldx #$0
:	clc			; spr.x += direction
	lda rom_spritelist+3,x
	adc face_x
	sta spritelist+3,x

	stx tmp			; spr.y = original.y+sinus[frame_counter]
	ldx frame_counter
	lda sinus,x
	asl
	ldx tmp
	clc
	adc #80
	adc rom_spritelist+0,x
	sta spritelist+0,x
	inx
	inx
	inx
	inx
	bne :-
	rts

increase_frame_counter:
	inc frame_counter
	lda frame_counter
	cmp #179
	bcc :+
	lda #$00
	sta frame_counter
:	rts

endless_loop:

	; stuff that can be done during render
	jsr move_head
	jsr update_sprites
	jsr increase_frame_counter

	; stuff that can only be updated during a vblank
	jsr vblank
	jsr copy_sprites

	ldx frame_counter
	lda sinus,x
	clc
	adc #256-16
	sta PPU_SCROLL		; x scroll
	lda #$00
	sta PPU_SCROLL		; y scroll

	jmp endless_loop

nmi_isr:
	rti

irq_isr:
	rti






