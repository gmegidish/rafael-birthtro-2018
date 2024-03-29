
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
PPU_FRAMECNT	= $4017

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
	.byt 2 				; 1 x 16kB PRG block.
	.byt 1 				; 1 x 8kB CHR block.
	; Rest of iNES header defaults to 0, indicating mapper 0, standard RAM size, etc.

.segment "VECTORS"
	.addr nmi_isr, reset, irq_isr

.segment "ZEROPAGE"

ptr: .res 2					; used for copying
tmp: .res 1

direction_x: .res 1				; speed*direction of moving face
direction_y: .res 1
face_x: .res 1					; position of head
face_y: .res 1

.segment "BSS"

spritelist: .res 256				; must be aligned to $ff00

.segment "MUSIC"
	; https://www.zophar.net/music/nintendo-nes-nsf/time-zone
	; interesting tracks: 2, 8, 4
	.incbin "time_zone.nsf", $80	; music, without the header

.segment "RODATA"

palette:
	.byt $05, $0c, $38, $16			; palette 0
	.byt $05, $00, $00, $00
	.byt $05, $00, $00, $00
	.byt $05, $00, $00, $00

	.byt $05, $0f, $3d, $2d			; sprite palette 0
	.byt $05, $00, $00, $00
	.byt $05, $00, $00, $00
	.byt $05, $00, $00, $00

text:
	; 64+13 = taf (last character in hebrew)
	; 64+13+26 = alef (first character in hebrew)
	; see charset
	.byt $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $5b, $67, $53, $4f, $4c, $63, $61, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $00
	.byt $4c, $4c, $4c, $4c, $4c, $4d, $64, $5b, $62, $63, $4c, $5a, $62, $5e, $4c, $62, $5b, $4c, $4e, $5e, $4c, $5a, $62, $5e, $63, $4c, $4c, $4c, $4c, $4c, $00
	.byt $4c, $4c, $4c, $4c, $4c, $4c, $4c, $85, $8a, $8b, $83, $4c, $66, $4c, $62, $59, $5c, $4c, $5a, $5e, $65, $65, $62, $60, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $00
	.byt $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $5b, $67, $53, $4f, $4c, $66, $62, $5f, $4c, $5b, $61, $59, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $00
	.byt $4c, $4d, $62, $5b, $62, $64, $65, $4c, $4d, $62, $67, $56, $53, $62, $50, $4c, $5b, $4e, $4c, $5a, $5e, $57, $4e, $4c, $63, $66, $4f, $63, $5b, $4c, $00
	.byt $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $63, $67, $66, $63, $4c, $63, $57, $4e, $66, $4c, $63, $67, $4f, $4d, $57, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $4c, $00


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

	lda #$0f		; initial apu
	sta APU_CHAN_CTRL

	ldx #$ff		; initialize stack pointer
	txs

	lda #$00
	sta PPU_CTRL		; nmi disabled
	sta PPU_MASK		; disable video output
	sta APU_DMC_CTRL	; disable dmc irq

	ldx #$40		; set up frame counter before music
	stx PPU_FRAMECNT

	lda #$00
	sta face_y		; we start at the top
	sta face_x		; we start on the left

	lda #1			; we start by moving right
	sta direction_x
	sta direction_y

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

	ldx #$0			; ntsc (if applicable)
	lda #1			; track #2
	jsr $beb0		; init time zone nsf

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
	adc direction_x
	sta face_x
	bne :+
	lda #1
	sta direction_x
	jmp move_y
:	cmp #256-64
	beq :+
	jmp move_y
:	lda #256-1
	sta direction_x

move_y:	clc
	lda face_y
	adc direction_y
	sta face_y
	bne :+
	lda #1
	sta direction_y
	rts
:	cmp #240-96
	beq :+
	rts
:	lda #256-1
	sta direction_y
	rts

update_sprites:
	ldx #$0
:	clc			; spr.x += direction
	lda rom_spritelist+3,x
	adc face_x
	sta spritelist+3,x

	lda rom_spritelist+0,x
	adc face_y
	sta spritelist+0,x

	inx
	inx
	inx
	inx
	bne :-
	rts

write_text:
	ldx #$23
	stx PPU_ADDR
	ldx #$80
	stx PPU_ADDR
	ldx #0
:	lda text,x
	beq :+
	sta PPU_DATA
	inx
	jmp :-
:	rts


endless_loop:

	jsr $8094		; play music

	; stuff that can be done during render
	jsr move_head
	jsr update_sprites

	; stuff that can only be updated during a vblank
	jsr vblank

	jsr write_text

	jsr copy_sprites

	lda #$00
	sta PPU_SCROLL
	sta PPU_SCROLL

	jmp endless_loop

nmi_isr:
	rti

irq_isr:
	rti









