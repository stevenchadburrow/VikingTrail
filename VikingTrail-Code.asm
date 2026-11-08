
; ./rgbds/rgbasm -o VikingTrail.o VikingTrail.asm
; ./rgbds/rgblink -o VikingTrail.gb VikingTrail.o
; ./rgbds/rgbfix -v -p $FF VikingTrail.gb
; ./PICboy.o VikingTrail.gb 000


; City - Hedeby
;	Cheap: Wine
;	Expen: none
; City - Gotland
;	Cheap: Amber
;	Expen: Lumber
; City - Sigtuna
;	Cheap: Amber, Swords
; 	Expen: Silk, Spices
; City - Aland (Islands)
;	Cheap: Amber
;	Expen: Lumber
; Planned Event - Neva Delta


; City - Ladoga [ winter over ]
;	Cheap: Furs
;	Expen: Swords
; City - Novgorod
;	Cheap: Furs, Lumber
;	Expen: Wine, Silk
; Planned Event - Portage
;	Upstream to Vitebsk (visit city)
;	Cross Immediately (faster)
; City (if upstream) - Vitebsk
;	Cheap: Furs, Lumber
;	Expen: Ivory
; City - Smolensk
;	Cheap: Honey, Lumber
;	Expen: Swords
; City - Gnezdovo
;	Cheap: 
;	Expen: 
; City - Lyubech
;	Cheap: Honey, Lumber
;	Expen: Amber


; City - Kiev [ winter over ]
;	Cheap: Silk, Wine
;	Expen: Furs, Ivory, Amber
; City - Pereyaslavl
;	Cheap: Honey, Lumber
;	Expen: Swords
; City - Khortytsia (Island)
;	Cheap: Lumber
;	Expen: none
; Planned Event - Rapids
;	Sail Through (high chance of losing cargo)
;	Portage Ships (slower)
; Random Event (if portage) - Bandits
;	Pay Toll (loss of cargo)
;	Fight (double or nothing loss of cargo)
; City - Oleshky
;	Cheap: Wine
;	Expen: Swords
; City - Cherson
;	Cheap: Silk, Wine
;	Expen: Furs, Honey
; City - Varna
;	Cheap: Wine
;	Expen: Furs
; City - Constantinople [ winter over ]
;	Cheap: Silk, Spices, Wine
; 	Expen: Furs, Honey, Ivory


INCLUDE "VikingTrail-Data.asm"

DEF oam_page_high		EQU $C6
DEF oam_page_addr		EQU $C600 ; 160 bytes, 40 sprites, start of page 

DEF trans_addr			EQU $C700 ; 2 bytes

DEF screen_skip			EQU $C702
DEF screen_next			EQU $C703
DEF screen_line			EQU $C704
DEF screen_bank			EQU $C705
DEF screen_clear		EQU $C706 ; 2 bytes
DEF screen_image		EQU $C708 ; 2 bytes

DEF bank_prev			EQU $C70A

DEF joy_curr			EQU $C70B
DEF joy_prev			EQU $C70C

DEF int_line			EQU $C70D

DEF win_dir		  		EQU $C70E
DEF win_pos				EQU $C70F

DEF cursor_pos_x		EQU $C710
DEF cursor_pos_y		EQU $C711

DEF map_loc				EQU $C712
DEF map_add_x			EQU $C713
DEF map_add_y			EQU $C714
DEF map_count			EQU $C715
DEF map_event			EQU $C716
DEF map_date			EQU $C717
DEF map_delay			EQU $C718
DEF map_load			EQU $C719
DEF map_prev_x			EQU $C71A
DEF map_prev_y			EQu $C71B
DEF map_place			EQU $C71C
DEF map_path			EQU $C71D ; 36 bytes
DEF map_rand			EQU $C741 ; 3 bytes

DEF city_loc			EQU $C744
DEF city_sel			EQU $C745

DEF event_loc			EQU $C746
DEF event_sel			EQU $C747
DEF event_code			EQU $C748 ; 8 bytes
DEF event_addr			EQU $C750 ; 4 bytes
DEF event_delay			EQU $C754

DEF trade_loc			EQU $C755
DEF trade_sel			EQU $C756
DEF trade_dir			EQU $C757
DEF trade_money			EQU $C758 ; 3 bytes
DEF trade_price			EQU $C75B ; 9 bytes
DEF trade_flux			EQU $C764 ; 9 bytes
DEF trade_goods			EQU $C76D ; 9 bytes

DEF inv_money			EQU $C776 ; 3 bytes
DEF inv_goods			EQU $C779 ; 9 bytes
DEF inv_weight			EQU $C782
DEF inv_fatigue			EQU $C783
DEF inv_fast			EQU $C784
DEF inv_slow			EQU $C785
DEF inv_stop			EQU $C786

DEF date_month			EQU $C787
DEF date_day			EQU $C788

DEF menu_type			EQU $C789
DEF menu_num			EQU $C78A
DEF menu_trig			EQU $C78B
DEF menu_prev			EQU $C78C

DEF rand_val			EQU $C78D
DEF rand_seed			EQU $C78E



SECTION "VBlankInterrupt", ROM0[$0040]
	JP VBlankInterrupt

SECTION "StatInterrupt", ROM0[$0048]
	JP StatInterrupt

SECTION "Header", ROM0[$0100]
	JP MainEntry

SECTION "Title", ROM0[$0134]
	DB "VIKINGTRAIL" ; title
	DB $00,$00,$00,$00 ; manufacturing
	DB $00,$00,$00,$00 ; GBC, licensee, and SGB
	DB $1B,$06,$03 ; MBC, ROM, and RAM
	DB $00,$00,$00 ; destination and licensee

SECTION "Main", ROM0[$0150]

; ****************
; ****************
; MAIN CODE
; ****************
; ****************

MainEntry:
	; turn off interrupts
	DI
	LD A, $00
	LD [$FFFF], A

	; turn off audio
	LD A, $00
	LD [$FF26], A

	; enable external RAM
	LD A, $0A
	LD [$0000], A

	; default ROM/RAM banks
	LD A, $01
	LD [$2000], A
	LD A, $00
	LD [$3000], A
	LD A, $00
	LD [$4000], A

	; wait for v-blank to turn off LCD
MainVBlankLoop:
	LD A, [$FF44]
	CP A, $90 ; line 144
	JR C, MainVBlankLoop

	; turn off LCD
	LD A, $00
	LD [$FF40], A

	; add OAM DMA routine to HRAM
	LD HL, OamDmaHramCode
	LD BC, $FF80
MainTransferLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, C
	CP A, $8A
	JR NZ, MainTransferLoop

	; clear OAM
	LD HL, oam_page_addr
MainSpriteLoop:
	LD A, $00
	LD [HLI], A
	LD A, H
	CP A, oam_page_high+1
	JR NZ, MainSpriteLoop

	; clear tiles
	LD HL, $8000
MainTilesLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $98
	JR C, MainTilesLoop

	; clear background indices
	LD HL, $9800
MainBackLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $9C
	JR C, MainBackLoop

	; clear window indices
	LD HL, $9C00
MainWinLoop:
	LD [HL], $00
	INC HL
	LD A, H
	CP A, $A0
	JR C, MainWinLoop

	; add font tile data
	LD BC, FontData+$0100 ; numbers and letters only
	LD HL, $8500
MainFontLoop:
	LD A, [BC]
	LD [HLI], A
	INC BC
	LD A, H
	CP A, $88
	JR C, MainFontLoop

	; add wall tile and indice data for window
	LD BC, WallData
	LD HL, $8F80
	LD E, $20
MainWallLoop1:
	LD A, [BC]
	LD [HLI], A
	INC BC
	DEC E
	JR NZ, MainWallLoop1
	LD BC, WallData
	LD HL, $CF80
	LD E, $20
MainWallLoop2:
	LD A, [BC]
	LD [HLI], A
	INC BC
	DEC E
	JR NZ, MainWallLoop2
	LD HL, $9800
MainWallLoop3:
	LD [HL], $F8 ; blank
	INC HL
	LD A, H
	CP A, $9C
	JR C, MainWallLoop3
	LD HL, $D800
MainWallLoop4:
	LD [HL], $F8 ; blank
	INC HL
	LD A, L
	CP A, $DC
	JR C, MainWallLoop4
	LD HL, $9C00
MainWallLoop5:
	LD [HL], $F9 ; wall
	INC HL
	LD A, H
	CP A, $A0
	JR C, MainWallLoop5
	LD HL, $DC00
MainWallLoop6:
	LD [HL], $F9 ; wall
	INC HL
	LD A, H
	CP A, $A0
	JR C, MainWallLoop6

	; load cursor pixel data in VRAM
	LD HL, CursorData
	LD B, $8F
	LD C, $A0
	LD E, $60
MainCursorLoop1:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, MainCursorLoop1
	LD HL, CursorData
	LD B, $CF
	LD C, $A0
	LD E, $60
MainCursorLoop2:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, MainCursorLoop2

	; set palettes for background/obj0/obj1
	LD A, $E4
	LD [$FF47], A
	LD [$FF48], A
	LD A, $D2
	LD [$FF49], A
	
	; set scroll background values
	LD A, $00
	LD [$FF42], A
	LD A, $00
	LD [$FF43], A

	; set scroll window values
	LD A, $00
	LD [$FF4A], A
	LD A, $00
	LD [$FF4B], A

	; long delay before starting the LCD
	LD BC, $FFFF
MainWaitLoop:
	DEC BC
	LD A, B
	CP A, $00
	JR NZ, MainWaitLoop
	LD A, C
	CP A, $00
	JR NZ, MainWaitLoop

	; set transfer address
	LD A, $9C
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A
	LD A, $85
	LD [screen_skip], A
	LD A, $88
	LD [screen_next], A
	LD A, $60
	LD [screen_line], A
	LD [int_line], A
	LD A, $01
	LD [screen_bank], A
	LD A, $DA
	LD [screen_clear+1], A
	LD A, $00
	LD [screen_clear+0], A

	; set window values
	LD A, $00
	LD [win_dir], A
	LD A, $00
	LD [win_pos], A

	; stat interrupt at line 96 (usually)
	LD A, $40
	LD [$FF41], A
	LD A, [int_line]
	LD [$FF45], A

	; turn on LCD
	LD A, $E1
	LD [$FF40], A

	; turn on V-Blank and Stat interrupts
	LD A, $03
	LD [$FFFF], A
	EI
	NOP
	NOP
	NOP
	NOP

	; clear joypad
	LD A, $30
	LD [$FF00], A
	LD A, $FF
	LD [joy_curr], A
	LD [joy_prev], A

	; enable audio
	LD A, $80
	LD [$FF26], A
	LD A, $77
	LD [$FF24], A
	LD A, $FF
	LD [$FF25], A

	; default to loading map each time
	LD A, $01
	LD [map_load], A

	; set date
	LD A, $03
	LD [date_month], A
	LD A, $01
	LD [date_day], A

	; set inventory
	LD A, $00
	LD [inv_money+0], A
	LD A, $04
	LD [inv_money+1], A
	LD A, $00
	LD [inv_money+2], A
	LD A, $08
	LD [inv_weight], A
	LD A, $00
	LD [inv_fatigue], A
	LD A, $00
	LD [inv_fast], A
	LD A, $00
	LD [inv_slow], A
	LD A, $00
	LD [inv_stop], A
	LD A, $00
	LD [event_delay], A
	LD BC, inv_goods
	LD E, $09
	LD A, $00 ; initial amount
MainCountLoop:
	LD [BC], A
	INC BC
	DEC E
	JR NZ, MainCountLoop

	; change trade flux
	LD E, $09
	LD HL, trade_flux
MainFluxLoop:
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	AND A, $03
	LD [HLI], A
	DEC E
	JR NZ, MainFluxLoop

	; zero out seed
	LD A, $00
	LD [rand_seed], A

	; start at city 00
	LD A, $01
	LD [menu_type], A
	LD A, $00
	LD [menu_num], A
	LD A, $00
	LD [menu_trig], A

	JP MenuEntry


; ****************
; ****************
; V-BLANK CODE
; ****************
; ****************

; v-blank interrupt
VBlankInterrupt:
	PUSH AF
	PUSH BC
	PUSH DE
	PUSH HL

	; switch LCDC.4
	LD A, [$FF40]
	AND A, $E3
	LD [$FF40], A

	; transfer X bytes to VRAM
	LD A, [screen_skip]
	LD D, A
	LD A, [trans_addr+1]
	CP A, $9C
	JR Z, VBlankOamDma
	CP A, D
	JR Z, VBlankTransferSkip
	LD B, A
	ADD A, $40
	LD H, A
	LD A, [trans_addr+0]
	LD C, A
	LD L, A
	LD E, $40 ; X bytes to transfer
VBlankTransferLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, VBlankTransferLoop
	LD A, B
	CP A, D
	JR NZ, VBlankTransferCheck
VBlankTransferSkip:
	LD A, [screen_next]
	LD C, $00
VBlankTransferCheck:
	LD [trans_addr+1], A
	LD A, C
	LD [trans_addr+0], A
	
VBlankOamDma:
	; oam dma transfer
	CALL $FF80

	; set previous values for joy
	LD A, [joy_curr]
	LD [joy_prev], A

	; set joy select and settle
	LD A, $10
	LD [$FF00], A
	NOP
	NOP

	; capture buttons
	LD A, [$FF00]
	AND A, $0F
	LD C, A
	
	; set joy select and settle
	LD A, $20
	LD [$FF00], A
	NOP
	NOP

	; capture dpad and combine
	LD A, [$FF00]
	SLA A
	SLA A
	SLA A
	SLA A
	OR A, C
	LD [joy_curr], A

	; check joypad to get seed
	LD A, [joy_curr]
	CP A, $FF
	JR Z, VBlankSeedSkip1
	LD A, [rand_val]
	LD [rand_seed], A
VBlankSeedSkip1:
	; randomize if seed is zero
	LD A, [rand_seed]
	CP A, $00
	JR NZ, VBlankSeedSkip2
	LD A, [rand_val]
	INC A
	LD [rand_val], A
VBlankSeedSkip2:

	; move window in direction
	LD A, [win_dir]
	CP A, $01 ; up
	JR Z, VBlankWindowUp
	CP A, $02 ; down
	JR Z, VBlankWindowDown
	JR VBlankWindowPos
	
VBlankWindowUp:
	; move window up
	LD A, [win_pos]
	CP A, $00
	JR Z, VBlankWindowStop
	SUB A, $04 ; window speed
	LD [win_pos], A

	; turn off sprites
	LD A, [$FF40]
	AND A, $F1
	LD [$FF40], A
	JR VBlankWindowPos

VBlankWindowDown:
	; move window down
	LD A, [win_pos]
	CP A, $90
	JR Z, VBlankWindowStop
	ADD A, $04 ; window speed
	LD [win_pos], A

	; turn off sprites
	LD A, [$FF40]
	AND A, $F1
	LD [$FF40], A
	JR VBlankWindowPos

VBlankWindowStop:
	; stop window
	LD A, $00
	LD [win_dir], A
	LD A, [win_pos]
	CP A, $90
	JR NZ, VBlankWindowPos

	; turn on sprites
	LD A, [$FF40]
	OR A, $02
	LD [$FF40], A

VBlankWindowPos:
	; set window position
	LD A, [win_pos]
	LD [$FF4A], A

	POP HL
	POP DE
	POP BC
	POP AF

	; return
	RETI


; ****************
; ****************
; STAT CODE
; ****************
; ****************

; stat interrupt
StatInterrupt:
	PUSH AF

	; make sure line is set correctly
	LD A, [int_line]
	LD [$FF45], A

	; switch LCDC.4
	LD A, [$FF40]
	OR A, $10
	LD [$FF40], A

	POP AF

	; return		
	RETI


; ****************
; ****************
; RANDOM CODE
; ****************
; ****************

Randomize:
	; current = 5 * previous + 17
	PUSH AF	
	PUSH BC
	LD A, [rand_val]
	LD C, A
	SLA A
	SLA A
	ADD A, C
	ADD A, $11
	LD [rand_val], A
	POP BC
	POP AF
	RET
	


; ****************
; ****************
; DECIMAL CODE
; ****************
; ****************

; value in A, location in BC
DisplayDecimal:
	PUSH DE
	INC BC
	LD E, $00

DisplayDecimalLoop:
	CP A, $0A
	JR C, DisplayDecimalDigit
	SUB A, $0A
	INC E
	JR DisplayDecimalLoop

DisplayDecimalDigit:	
	ADD A, $50
	LD [BC], A
	DEC BC
	LD A, E
	ADD A, $50
	LD [BC], A

	POP DE
	RET



; ****************
; ****************
; DATE CODE
; ****************
; ****************

DateIncrement:
	; increment date
	LD A, [date_day]
	INC A
	LD [date_day], A
	CP A, $1F ; 30 days each month
	JR C, DateIncrementExit
	LD A, $01
	LD [date_day], A
	LD A, [date_month]
	INC A
	LD [date_month], A
	CP A, $0C
	JR C, DateIncrementExit
	LD A, $00
	LD [date_month], A
DateIncrementExit:
	RET

DateDisplay:
	; insert date month
	LD A, [date_month]
	LD C, A
	ADD A, C
	ADD A, C
	LD C, A
	LD B, $00
	LD HL, DateMonthData
	ADD HL, BC
	LD A, [HLI]
	ADD A, $20
	LD [$DA20], A
	LD A, [HLI]
	ADD A, $20
	LD [$DA21], A
	LD A, [HL]
	ADD A, $20
	LD [$DA22], A
	
	; insert date day
	LD BC, $DA23
	LD A, [date_day]
	CALL DisplayDecimal

	RET


; ****************
; ****************
; MONEY CODE
; ****************
; ****************

MoneyAdd:
	; add A to money
	LD C, A
	LD A, [inv_money+0]
	ADD A, C
	LD [inv_money+0], A
	CP A, $64
	JR C, MoneyAddExit
	SUB A, $64
	LD [inv_money+0], A
	LD A, [inv_money+1]
	INC A
	LD [inv_money+1], A
	CP A, $64
	JR C, MoneyAddExit
	SUB A, $64
	LD [inv_money+1], A
	LD A, [inv_money+2]
	INC A
	LD [inv_money+2], A
	CP A, $64
	JR C, MoneyAddExit
	LD A, $63
	LD [inv_money+2], A
	LD [inv_money+1], A
	LD [inv_money+0], A
MoneyAddExit:
	RET

MoneySub:
	; sub A to money
	LD C, A
	LD A, [inv_money+0]
	SUB A, C
	LD [inv_money+0], A
	JR NC, MoneySubExit
	ADD A, $64
	LD [inv_money+0], A
	LD A, [inv_money+1]
	DEC A
	LD [inv_money+1], A
	JR C, MoneySubExit
	ADD A, $64
	LD [inv_money+1], A
	LD A, [inv_money+2]
	DEC A
	LD [inv_money+2], A
	JR C, MoneySubExit
	LD A, $00
	LD [inv_money+2], A
	LD [inv_money+1], A
	LD [inv_money+0], A
MoneySubExit:
	RET

MoneyDisplay:
	; insert money amount
	LD BC, $DA2E
	LD A, [inv_money+2]
	CALL DisplayDecimal
	LD BC, $DA30
	LD A, [inv_money+1]
	CALL DisplayDecimal
	LD BC, $DA32
	LD A, [inv_money+0]
	CALL DisplayDecimal

	; insert weight amounts also
	LD BC, $DA2A
	LD A, [inv_weight]
	SUB A, $08 ; remove base weight
	CALL DisplayDecimal

	; insert weight amounts also
	LD BC, $DA27
	LD A, [inv_fatigue]
	CALL DisplayDecimal

	RET



; ****************
; ****************
; SCREEN CODE
; ****************
; ****************

ScreenEntry:
	; set transfer address
	LD A, $9C
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

	; tell window to move up and wait
	LD A, $01
	LD [win_dir], A
ScreenWindowUpLoop:
	HALT
	NOP
	NOP
	LD A, [win_pos]
	CP A, $00
	JR NZ, ScreenWindowUpLoop

	; set interrupt line
	LD A, [screen_line]
	LD [int_line], A

	; switch banks here
	LD A, [screen_bank]
	LD [$2000], A

	; load image pixel data in VRAM
	LD A, [screen_image+0]
	LD L, A
	LD A, [screen_image+1]
	LD H, A

	; first region
	LD B, $D0
	LD C, $00
ScreenTileLoop1:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, B
	CP A, $D7
	JR NZ, ScreenTileLoop1
	LD A, C
	CP A, $80
	JR NZ, ScreenTileLoop1
	
	; second region
	LD B, $C8
	LD C, $00
ScreenTileLoop2:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, B
	CP A, $CF
	JR NZ, ScreenTileLoop2
	LD A, C
	CP A, $80
	JR NZ, ScreenTileLoop2

	; third region
	LD B, $C0
	LD C, $00
ScreenTileLoop3:
	LD A, [HLI]
	LD [BC], A
	INC BC
	LD A, B
	CP A, $C5
	JR NZ, ScreenTileLoop3
	LD A, C
	CP A, $00
	JR NZ, ScreenTileLoop3

	; load image index data in VRAM
	; 3 groups of 6 make 18 lines
	LD HL, $D800
	LD C, $00
	LD B, $00
	LD D, $06
	LD E, $14
ScreenIndexLoop1:
	LD A, C
	LD [HLI], A
	INC BC
	DEC E
	JR NZ, ScreenIndexLoop1
	LD E, $0C
ScreenIndexLoop2:
	LD A, $00
	LD [HLI], A
	DEC E
	JR NZ, ScreenIndexLoop2
	LD E, $14
	DEC D
	JR NZ, ScreenIndexLoop1
	LD D, $06
	INC BC
	INC BC
	INC BC
	INC BC
	INC BC
	INC BC
	INC BC
	INC BC
	LD A, H
	CP A, $DA
	JR NZ, ScreenIndexLoop1
	LD A, L
	CP A, $40
	JR NZ, ScreenIndexLoop1

	; clear bottom rows
	LD A, [screen_clear+0]
	LD L, A
	LD A, [screen_clear+1]
	LD H, A
ScreenIndexLoop3:
	LD A, $F8 ; blank
	LD [HLI], A
	LD A, H
	CP A, $DC
	JR NZ, ScreenIndexLoop3

	; display date at bottom
	CALL DateDisplay

	; display money at bottom
	CALL MoneyDisplay

	; switch banks here
	LD A, [bank_prev]
	LD [$2000], A

	; set transfer address
	LD A, $80
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

ScreenTransferLoop:
	; wait for transfer to complete
	HALT
	NOP
	NOP
	LD A, [trans_addr+1]
	CP A, $9C
	JR NZ, ScreenTransferLoop

	; tell window to move down and wait
	LD A, $02
	LD [win_dir], A
ScreenWindowDownLoop:
	HALT
	NOP
	NOP
	LD A, [win_pos]
	CP A, $90
	JR NZ, ScreenWindowDownLoop

	; return
	RET



; ****************
; ****************
; MAP CODE
; ****************
; ****************

MapEntry:
	; clear oam
	LD HL, oam_page_addr
MapOamLoop:
	LD A, $00
	LD [HLI], A
	LD A, H
	CP A, oam_page_high+1
	JR NZ, MapOamLoop

	; clear icon info
	LD A, $00
	LD [cursor_pos_x], A
	LD A, $00
	LD [cursor_pos_y], A
	LD A, $00

	; set screen variables
	; settings in order: full, half, quarter
	LD A, $85 ; set: $85, $80, $80
	LD [screen_skip], A
	LD A, $88 ; set: $88, $88, $90
	LD [screen_next], A
	LD A, $60 ; set: $60, $60, $30
	LD [screen_line], A
	LD A, $DA ; set: $DA, $D9, $D8
	LD [screen_clear+1], A
	LD A, $00 ; set: $00, $80, $C0
	LD [screen_clear+0], A

	; switch banks
	LD A, $01
	LD [bank_prev], A
	LD [$2000], A

	; find map data
	LD A, [map_loc]
	SRL A
	SRL A
	LD B, A
	LD A, [map_loc]
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A
	LD HL, MapData
	ADD HL, BC
	
	; set screen image
	LD A, [HLI]
	LD [screen_image+0], A
	LD A, [HLI]
	LD [screen_image+1], A
	LD A, [HLI]
	LD [screen_bank], A

	PUSH HL

	; draw screen
	CALL ScreenEntry

	POP HL

	; set text at bottom
	LD BC, $DA00
	LD E, $14
MapTextLoop:
	LD A, [HLI]
	ADD A, $20
	LD [BC], A
	INC BC
	DEC E
	JR NZ, MapTextLoop

	; get random events
	LD A, [HLI]
	LD [map_rand+0], A
	LD A, [HLI]
	LD [map_rand+1], A
	LD A, [HLI]
	LD [map_rand+2], A

	; check to see if coming from event
	LD A, [map_prev_x]
	LD [cursor_pos_x], A
	LD A, [map_prev_y]
	LD [cursor_pos_y], A
	LD A, [map_load]
	CP A, $00
	JR Z, MapPathSkip

	; load cursor oam data
	LD A, [HLI]
	LD [cursor_pos_x], A
	LD A, [HLI]
	LD [cursor_pos_y], A

	; load path
	LD BC, map_path
	LD E, $24 ; 36 remaining bytes
MapPathLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, MapPathLoop
	LD A, $00
	LD [map_place], A
	
	; initial path values
	LD A, [map_path+0]
	LD [map_add_x], A
	LD A, [map_path+1]
	LD [map_add_y], A
	LD A, [map_path+2]
	LD [map_count], A
	LD A, $00
	LD [map_delay], A

MapPathSkip:
	; default to loading map each time
	LD A, $01
	LD [map_load], A

	; reset date
	LD A, $00
	LD [map_date], A

	; set transfer address for text at bottom
	LD A, $98
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

MapHaltLoop:
	HALT
	NOP
	NOP

	; date counter
	LD A, [map_date]
	INC A
	LD [map_date], A
	CP A, $20 ; date amount
	JR NZ, MapDateSkip
	LD A, $00
	LD [map_date], A

	; remove fast
	LD A, [inv_fast]
	CP A, $00
	JR Z, MapFastSkip
	DEC A
	LD [inv_fast], A
MapFastSkip:

	; remove slow
	LD A, [inv_slow]
	CP A, $00
	JR Z, MapSlowSkip
	DEC A
	LD [inv_slow], A
MapSlowSkip:

	; remove stop
	LD A, [inv_stop]
	CP A, $00
	JR Z, MapStopSkip
	DEC A
	LD [inv_stop], A
MapStopSkip:

	; remove event delay
	LD A, [event_delay]
	CP A, $00
	JR Z, MapEventDelaySkip
	DEC A
	LD [event_delay], A
MapEventDelaySkip:

	; increment date
	CALL DateIncrement

	; display date at bottom
	CALL DateDisplay

	; display money at bottom
	CALL MoneyDisplay

	; set transfer address
	LD A, $9A
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A
MapDateSkip:

	; check for stop
	LD A, [inv_stop]
	CP A, $00
	JP NZ, MapCursorUpdate

	; movement delay
	LD A, [inv_weight]
	INC A
	LD C, A
	LD A, [inv_fatigue]
	SLA A
	ADD A, C
	LD C, A
	LD A, [inv_slow]
	SLA A
	SLA A
	SLA A
	SLA A
	ADD A, C
	LD C, A
	LD A, [inv_fast]
	LD B, A
	LD A, C
	SUB A, B
	LD E, A
	LD A, [date_month]
	LD C, A
	LD B, $00
	LD HL, DateSpeedData
	ADD HL, BC
	LD A, [HL]
	ADD A, E
	LD C, A
	LD A, [map_delay]
	INC A
	LD [map_delay], A
	CP A, C ; delay amount
	JP C, MapCursorUpdate
	LD A, $00
	LD [map_delay], A

	; planned events here
	CALL MapEventDate
	CP A, $00
	JR NZ, MapEventSave
	CALL MapEventPlanned
	CP A, $00
	JR NZ, MapEventSave
	CALL MapEventRandom
	CP A, $00
	JR NZ, MapEventSave
	JR MapEventSkip

MapEventSave:
	; save map info when you come back
	PUSH AF
	LD A, [menu_num]
	LD [menu_prev], A
	POP AF
	LD [menu_num], A
	LD A, $02
	LD [menu_type], A
	LD A, $00
	LD [menu_trig], A
	LD A, [cursor_pos_x]
	LD [map_prev_x], A
	LD A, [cursor_pos_y]
	LD [map_prev_y], A
	LD A, $00
	LD [map_load], A
	
	; prevents player exhaustion
	LD A, $07
	LD [event_delay], A

	RET

MapEventSkip:
	; compare to next location
	LD A, [map_count]
	DEC A
	LD [map_count], A
	JR NZ, MapCursorMove
	
MapCursorNext:
	; get path coords
	LD A, [map_place]
	SLA A
	SLA A
	LD C, A
	LD B, $00
	LD HL, map_path
	ADD HL, BC
	LD A, [HLI]
	LD [map_add_x], A
	LD A, [HLI]
	LD [map_add_y], A
	LD A, [HL]
	LD [map_count], A
	LD A, [map_place]
	INC A
	LD [map_place], A

	; check if finished
	LD A, [map_count]
	CP A, $00
	JR NZ, MapCursorMove

	; increment menu location
	LD A, [menu_num]
	INC A
	LD [menu_num], A
	LD A, $01
	LD [menu_type], A
	LD A, $00
	LD [menu_trig], A

	; return
	RET
	
MapCursorMove:
	; move cursor
	LD A, [map_add_x]
	LD C, A
	LD A, [cursor_pos_x]
	ADD A, C
	LD [cursor_pos_x], A

	LD A, [map_add_y]
	LD C, A
	LD A, [cursor_pos_y]
	ADD A, C
	LD [cursor_pos_y], A

MapCursorUpdate:
	; update cursor position
	LD A, [cursor_pos_y]
	SUB A, $10
	LD [oam_page_addr+$00], A
	LD A, [cursor_pos_x]
	SUB A, $04
	LD [oam_page_addr+$01], A
	LD A, $FC
	LD [oam_page_addr+$02], A
	LD A, $00
	LD [oam_page_addr+$03], A

	LD A, [cursor_pos_y]
	SUB A, $08
	LD [oam_page_addr+$04], A
	LD A, [cursor_pos_x]
	SUB A, $04
	LD [oam_page_addr+$05], A
	LD A, $FD
	LD [oam_page_addr+$06], A
	LD A, $00
	LD [oam_page_addr+$07], A

	JP MapHaltLoop

MapEventDate:
	; summer and winter events
	LD A, [date_day]
	CP A, $03
	JR NC, MapEventDateNone
	LD A, [date_month]
	CP A, $04 ; MAY
	JR Z, MapEventDateSummer
	CP A, $0A ; NOV
	JR Z, MapEventDateWinter
MapEventDateNone:
	LD A, $00
	RET
MapEventDateSummer:
	LD A, $10 ; summer event
	RET
MapEventDateWinter:
	LD A, $11; winter event
	RET

MapEventPlanned:
	; jump to planned event
	LD A, [map_place]
	SLA A
	SLA A
	LD C, A
	LD B, $00
	LD HL, map_path
	ADD HL, BC
	INC HL
	INC HL
	INC HL
	LD A, [HL]
	CP A, $00
	JR Z, MapEventPlannedNone
	LD C, A
	LD A, [map_place]
	INC A
	LD [map_place], A
	LD A, C
	RET
MapEventPlannedNone:
	LD A, $00
	RET

MapEventRandom:
	; pick random event
	LD A, [event_delay] ; prevents player exhaustion
	CP A, $00
	JR NZ, MapEventRandomNone
	CALL Randomize
	LD A, [rand_val]
	SRL A ; shift to make higher chances
	CP A, $03
	JR NC, MapEventRandomNone
	LD C, A
	LD B, $00
	LD HL, map_rand
	ADD HL, BC
	LD A, [HL]
	CP A, $01
	JR Z, MapEventRandomSeason
	CP A, $03
	JR Z, MapEventRandomSeason
	CP A, $05
	JR Z, MapEventRandomSeason
	RET
MapEventRandomSeason:
	; if seasonal event, modify accordingly
	LD E, A
	LD A, [date_month]
	LD C, A
	LD B, $00
	LD HL, DateSpeedData
	ADD HL, BC
	LD A, [HL]
	CP A, $00
	JR Z, MapEventRandomNormal
	LD A, E
	INC A
	RET
MapEventRandomNormal:
	LD A, E
	RET
MapEventRandomNone:
	LD A, $00
	RET
	
	

; ****************
; ****************
; CITY CODE
; ****************
; ****************

CityEntry:
	; clear oam
	LD HL, oam_page_addr
CityOamLoop:
	LD A, $00
	LD [HLI], A
	LD A, H
	CP A, oam_page_high+1
	JR NZ, CityOamLoop

	; clear cursor info
	LD A, $00
	LD [cursor_pos_x], A
	LD A, $00
	LD [cursor_pos_y], A
	LD A, $00

	; set screen variables
	; settings in order: full, half, quarter
	LD A, $80 ; set: $85, $80, $80
	LD [screen_skip], A
	LD A, $88 ; set: $88, $88, $90
	LD [screen_next], A
	LD A, $60 ; set: $60, $60, $30
	LD [screen_line], A
	LD A, $D9 ; set: $DA, $D9, $D8
	LD [screen_clear+1], A
	LD A, $80 ; set: $00, $80, $C0
	LD [screen_clear+0], A

	; switch banks
	LD A, $02
	LD [bank_prev], A
	LD [$2000], A

	; find city data
	LD A, [city_loc]
	SRL A
	SRL A
	SRL A
	LD B, A
	LD A, [city_loc]
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A
	LD HL, CityData
	ADD HL, BC

	; set screen image
	LD A, [HLI]
	LD [screen_image+0], A
	LD A, [HLI]
	LD [screen_image+1], A
	LD A, [HLI]
	LD [screen_bank], A

	PUSH HL

	; draw screen
	CALL ScreenEntry

	POP HL

	; set text at bottom
	LD BC, $D980
	LD E, $14
CityTextLoop:
	LD A, [HLI]
	ADD A, $20
	LD [BC], A
	INC BC
	DEC E
	JR NZ, CityTextLoop

	; set options text
	LD BC, CityOptions
	LD HL, $D9A0
	LD E, $14
	LD D, $04
CityOptionsLoop:
	LD A, [BC]
	ADD A, $20
	LD [HLI], A
	INC BC
	DEC E
	JR NZ, CityOptionsLoop
	PUSH BC
	LD BC, $000C
	ADD HL, BC
	POP BC
	LD E, $14
	DEC D
	JR NZ, CityOptionsLoop

	; remove all fast, slow, and stop
	LD A, $00
	LD [inv_fast], A
	LD [inv_slow], A
	LD [inv_stop], A

	; prevents player exhaustion
	LD A, $07
	LD [event_delay], A

	; load cursor oam data
	LD A, $08
	LD [cursor_pos_x], A
	LD A, $78
	LD [cursor_pos_y], A
	LD A, $00
	LD [city_sel], A

	; set transfer address for text at bottom
	LD A, $98
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

CityHaltLoop:
	HALT
	NOP
	NOP

	; check joypad info
	CALL CityJoyUp
	CALL CityJoyDown
	CALL CityJoyAction
	
	; update joypad info
	LD A, [joy_curr]
	LD [joy_prev], A

	; update cursor position
	LD A, [cursor_pos_y]
	LD [oam_page_addr+$00], A
	LD A, [cursor_pos_x]
	LD [oam_page_addr+$01], A
	LD A, $FA
	LD [oam_page_addr+$02], A
	LD A, $00
	LD [oam_page_addr+$03], A

	LD A, [cursor_pos_y]
	LD [oam_page_addr+$04], A
	LD A, [cursor_pos_x]
	ADD A, $08
	LD [oam_page_addr+$05], A
	LD A, $FB
	LD [oam_page_addr+$06], A
	LD A, $00
	LD [oam_page_addr+$07], A

	; check for menu trigger to return
	LD A, [menu_trig]
	CP A, $00
	JP Z, CityHaltLoop
	LD A, $00
	LD [menu_trig], A
	RET

; check for up
CityJoyUp:
	LD A, [joy_prev]
	AND A, $40
	JR NZ, CityJoyUpSub1
	RET
CityJoyUpSub1:
	LD A, [joy_curr]
	AND A, $40
	JR Z, CityJoyUpSub2
	RET
CityJoyUpSub2:
	LD A, [city_sel]
	CP A, $00
	JR NZ, CityJoyUpSub3
	RET
CityJoyUpSub3:
	LD A, [city_sel]
	DEC A
	LD [city_sel], A
	LD A, [cursor_pos_y]
	SUB A, $08
	LD [cursor_pos_y], A
	RET

; check for down
CityJoyDown:
	LD A, [joy_prev]
	AND A, $80
	JR NZ, CityJoyDownSub1
	RET
CityJoyDownSub1:
	LD A, [joy_curr]
	AND A, $80
	JR Z, CityJoyDownSub2
	RET
CityJoyDownSub2:
	LD A, [city_sel]
	CP A, $03
	JR NZ, CityJoyDownSub3
	RET
CityJoyDownSub3:
	LD A, [city_sel]
	INC A
	LD [city_sel], A
	LD A, [cursor_pos_y]
	ADD A, $08
	LD [cursor_pos_y], A
	RET

; check for action
CityJoyAction:
	LD A, [joy_prev]
	AND A, $01
	JR NZ, CityJoyActionSub1
	RET
CityJoyActionSub1:
	LD A, [joy_curr]
	AND A, $01
	JR Z, CityJoyActionSub2
	RET
CityJoyActionSub2:	
	LD A, [city_sel]
	AND A, $03
	CP A, $00
	JP Z, CityJoyActionSub3
	CP A, $01
	JP Z, CityJoyActionSub4
	CP A, $02
	JP Z, CityJoyActionSub5
	CP A, $03
	JP Z, CityJoyActionSub8

CityJoyActionSub3:
	; change trade flux
	LD E, $09
	LD HL, trade_flux
CityJoyActionFlux1:
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	AND A, $03
	LD [HLI], A
	DEC E
	JR NZ, CityJoyActionFlux1

	; continue
	LD A, $00
	LD [menu_type], A
	LD A, $01
	LD [menu_trig], A
	RET

CityJoyActionSub4:
	; trade goods
	LD A, $03
	LD [menu_type], A
	LD A, $01
	LD [menu_trig], A
	RET

CityJoyActionSub5:
	; rest one week
	LD A, [inv_money+2]
	CP A, $00
	JR NZ, CityJoyActionSub6
	LD A, [inv_money+1]
	CP A, $00
	JR NZ, CityJoyActionSub6
	LD A, [inv_money+0]
	CP A, $04 ; cost to rest
	JR C, CityJoyActionSub7
CityJoyActionSub6:
	LD A, $04 ; cost of rest
	CALL MoneySub
	
	; change trade flux
	LD E, $09
	LD HL, trade_flux
CityJoyActionFlux2:
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	AND A, $03
	LD [HLI], A
	DEC E
	JR NZ, CityJoyActionFlux2

	; refresh screen
	LD A, $01
	LD [menu_type], A
	LD A, $01
	LD [menu_trig], A
	CALL DateIncrement
	CALL DateIncrement
	CALL DateIncrement
	CALL DateIncrement
	CALL DateIncrement
	CALL DateIncrement
	CALL DateIncrement
	LD A, [inv_fatigue]
	CP A, $00
	JR Z, CityJoyActionSub7
	DEC A
	LD [inv_fatigue], A
CityJoyActionSub7:
	RET

CityJoyActionSub8:
	; winter over
	LD A, [date_month]
	LD C, A
	LD B, $00
	LD HL, DateWinterData
	ADD HL, BC
	LD A, [HL]
	LD B, A
	LD A, [inv_money+2]
	CP A, $00
	JR NZ, CityJoyActionSub9
	LD A, [inv_money+1]
	CP A, $00
	JR NZ, CityJoyActionSub9
	LD A, [inv_money+0]
	CP A, B ; cost to winter over
	JR C, CityJoyActionSub10
CityJoyActionSub9:
	LD A, B ; cost to winter over
	CALL MoneySub
	
	; change trade flux
	LD E, $09
	LD HL, trade_flux
CityJoyActionFlux3:
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	AND A, $03
	LD [HLI], A
	DEC E
	JR NZ, CityJoyActionFlux3

	; refresh screen
	LD A, $01
	LD [menu_type], A
	LD A, $01
	LD [menu_trig], A
	LD A, $03
	LD [date_month], A
	LD A, $01
	LD [date_day], A
	LD A, $00
	LD [inv_fatigue], A
CityJoyActionSub10:
	RET
	

CityOptions:
	DB "__CONTINUE_ON_______"
	DB "__TRADE_GOODS_______"
	DB "__REST_ONE_WEEK_____"
	DB "__STAY_THRU_WINTER__"





; ****************
; ****************
; EVENT CODE
; ****************
; ****************

EventEntry:
	; clear oam
	LD HL, oam_page_addr
EventOamLoop:
	LD A, $00
	LD [HLI], A
	LD A, H
	CP A, oam_page_high+1
	JR NZ, EventOamLoop

	; clear cursor info
	LD A, $00
	LD [cursor_pos_x], A
	LD A, $00
	LD [cursor_pos_y], A
	LD A, $00

	; set screen variables
	; settings in order: full, half, quarter
	LD A, $80 ; set: $85, $80, $80
	LD [screen_skip], A
	LD A, $88 ; set: $88, $88, $90
	LD [screen_next], A
	LD A, $60 ; set: $60, $60, $30
	LD [screen_line], A
	LD A, $D9 ; set: $DA, $D9, $D8
	LD [screen_clear+1], A
	LD A, $80 ; set: $00, $80, $C0
	LD [screen_clear+0], A

	; switch banks
	LD A, $03
	LD [bank_prev], A
	LD [$2000], A

	; find event data
	LD A, [event_loc]
	SRL A
	LD B, A
	LD A, [event_loc]
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A
	LD HL, EventData
	ADD HL, BC

	; set screen image
	LD A, [HLI]
	LD [screen_image+0], A
	LD A, [HLI]
	LD [screen_image+1], A
	LD A, [HLI]
	LD [screen_bank], A

	PUSH HL

	; draw screen
	CALL ScreenEntry

	POP HL

	; set text at bottom
	LD BC, $D980
	LD E, $14
EventTextLoop:
	LD A, [HLI]
	ADD A, $20
	LD [BC], A
	INC BC
	DEC E
	JR NZ, EventTextLoop

	; set options
	LD BC, $D9A0
	LD D, $04
	LD E, $14
EventOptionsLoop:
	LD A, [HLI]
	ADD A, $20
	LD [BC], A
	INC BC
	DEC E
	JR NZ, EventOptionsLoop
	PUSH HL
	LD HL, $000C
	ADD HL, BC
	LD B, H
	LD C, L
	POP HL
	LD E, $14
	DEC D
	JR NZ, EventOptionsLoop

	; set code addresses
	LD BC, event_code
	LD E, $08
EventCodeLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, EventCodeLoop

	; load cursor oam data
	LD A, $08
	LD [cursor_pos_x], A
	LD A, $78
	LD [cursor_pos_y], A
	LD A, $00
	LD [event_sel], A

	; set transfer address for text at bottom
	LD A, $98
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

EventHaltLoop:
	HALT
	NOP
	NOP

	; check joypad info
	CALL EventJoyUp
	CALL EventJoyDown
	CALL EventJoyAction
	
	; update joypad info
	LD A, [joy_curr]
	LD [joy_prev], A

	; update cursor position
	LD A, [cursor_pos_y]
	LD [oam_page_addr+$00], A
	LD A, [cursor_pos_x]
	LD [oam_page_addr+$01], A
	LD A, $FA
	LD [oam_page_addr+$02], A
	LD A, $00
	LD [oam_page_addr+$03], A

	LD A, [cursor_pos_y]
	LD [oam_page_addr+$04], A
	LD A, [cursor_pos_x]
	ADD A, $08
	LD [oam_page_addr+$05], A
	LD A, $FB
	LD [oam_page_addr+$06], A
	LD A, $00
	LD [oam_page_addr+$07], A

	; check for menu trigger to return
	LD A, [menu_trig]
	CP A, $00
	JP Z, EventHaltLoop
	LD A, $00
	LD [menu_trig], A
	RET

; check for up
EventJoyUp:
	LD A, [joy_prev]
	AND A, $40
	JR NZ, EventJoyUpSub1
	RET
EventJoyUpSub1:
	LD A, [joy_curr]
	AND A, $40
	JR Z, EventJoyUpSub2
	RET
EventJoyUpSub2:
	LD A, [event_sel]
	CP A, $00
	JR NZ, EventJoyUpSub3
	RET
EventJoyUpSub3:
	LD A, [event_sel]
	DEC A
	LD [event_sel], A
	LD A, [cursor_pos_y]
	SUB A, $08
	LD [cursor_pos_y], A
	RET

; check for down
EventJoyDown:
	LD A, [joy_prev]
	AND A, $80
	JR NZ, EventJoyDownSub1
	RET
EventJoyDownSub1:
	LD A, [joy_curr]
	AND A, $80
	JR Z, EventJoyDownSub2
	RET
EventJoyDownSub2:
	LD A, [event_sel]
	CP A, $03
	JR NZ, EventJoyDownSub3
	RET
EventJoyDownSub3:
	LD A, [event_sel]
	INC A
	LD [event_sel], A
	LD A, [cursor_pos_y]
	ADD A, $08
	LD [cursor_pos_y], A
	RET

; check for action
EventJoyAction:
	LD A, [joy_prev]
	AND A, $01
	JR NZ, EventJoyActionSub1
	RET
EventJoyActionSub1:
	LD A, [joy_curr]
	AND A, $01
	JR Z, EventJoyActionSub2
	RET
EventJoyActionSub2:	
	; set up jump address
	LD A, $CD
	LD [event_addr+0], A
	LD A, $C9
	LD [event_addr+3], A
	LD A, [event_sel]
	SLA A
	LD C, A
	LD B, $00
	LD HL, event_code
	ADD HL, BC
	LD A, [HLI]
	LD [event_addr+1], A
	LD A, [HL]
	LD [event_addr+2], A
	CALL event_addr
	RET
	


; ****************
; ****************
; TRADE CODE
; ****************
; ****************

TradeEntry:
	; clear oam
	LD HL, oam_page_addr
TradeOamLoop:
	LD A, $00
	LD [HLI], A
	LD A, H
	CP A, oam_page_high+1
	JR NZ, TradeOamLoop

	; clear cursor info
	LD A, $00
	LD [cursor_pos_x], A
	LD A, $00
	LD [cursor_pos_y], A
	LD A, $00

	; set screen variables
	; settings in order: full, half, quarter
	LD A, $80 ; set: $85, $80, $80
	LD [screen_skip], A
	LD A, $90 ; set: $88, $88, $90
	LD [screen_next], A
	LD A, $30 ; set: $60, $60, $30
	LD [screen_line], A
	LD A, $D8 ; set: $DA, $D9, $D8
	LD [screen_clear+1], A
	LD A, $C0 ; set: $00, $80, $C0
	LD [screen_clear+0], A

	; switch banks
	LD A, $04
	LD [bank_prev], A
	LD [$2000], A

	; find trade data
	LD A, [trade_loc]
	SRL A
	SRL A
	LD B, A
	LD A, [trade_loc]
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	SLA A
	LD C, A
	LD HL, TradeData
	ADD HL, BC

	; set screen image
	LD A, [HLI]
	LD [screen_image+0], A
	LD A, [HLI]
	LD [screen_image+1], A
	LD A, [HLI]
	LD [screen_bank], A

	PUSH HL

	; draw screen
	CALL ScreenEntry

	; set options text
	LD BC, TradeOptions
	LD HL, $D8E0
	LD E, $14
	LD D, $0A
TradeOptionsLoop:
	LD A, [BC]
	ADD A, $20
	LD [HLI], A
	INC BC
	DEC E
	JR NZ, TradeOptionsLoop
	PUSH BC
	LD BC, $000C
	ADD HL, BC
	POP BC
	LD E, $14
	DEC D
	JR NZ, TradeOptionsLoop

	POP HL

	; set text at bottom
	LD BC, $D8C0
	LD E, $14
TradeTextLoop:
	LD A, [HLI]
	ADD A, $20
	LD [BC], A
	INC BC
	DEC E
	JR NZ, TradeTextLoop

	; set options prices
	LD E, $09
	LD BC, trade_price
TradePriceLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, TradePriceLoop

	; set options values
	LD E, $09
	LD BC, trade_goods
TradeCountLoop:
	LD A, [HLI]
	LD [BC], A
	INC BC
	DEC E
	JR NZ, TradeCountLoop

	; set options money
	LD A, [HLI]
	LD [trade_money+2], A
	LD A, [HLI]
	LD [trade_money+1], A
	LD A, [HLI]
	LD [trade_money+0], A

	; load cursor/icon oam data
	LD A, $68
	LD [cursor_pos_x], A
	LD A, $48
	LD [cursor_pos_y], A
	LD A, $00
	LD [trade_sel], A
	LD [trade_dir], A

	; display money at top
	LD BC, $D8CE
	LD A, [trade_money+2]
	CALL DisplayDecimal
	LD BC, $D8D0
	LD A, [trade_money+1]
	CALL DisplayDecimal
	LD BC, $D8D2
	LD A, [trade_money+0]
	CALL DisplayDecimal

	; reload trade counts
	CALL TradeUpdate

	; reload money display
	CALL MoneyDisplay

	; set transfer address for text at bottom
	LD A, $98
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

TradeHaltLoop:
	HALT
	NOP
	NOP

	; check joypad info
	CALL TradeJoyUp
	CALL TradeJoyDown
	CALL TradeJoyLeft
	CALL TradeJoyRight
	CALL TradeJoyAction
	
	; update joypad info
	LD A, [joy_curr]
	LD [joy_prev], A

	; check direction for cursor
	LD A, [trade_dir]
	CP A, $01
	JR Z, TradeFlipCursor

	; update cursor position
	LD A, [cursor_pos_y]
	LD [oam_page_addr+$00], A
	LD A, [cursor_pos_x]
	LD [oam_page_addr+$01], A
	LD A, $FA
	LD [oam_page_addr+$02], A
	LD A, $00
	LD [oam_page_addr+$03], A

	LD A, [cursor_pos_y]
	LD [oam_page_addr+$04], A
	LD A, [cursor_pos_x]
	ADD A, $08
	LD [oam_page_addr+$05], A
	LD A, $FB
	LD [oam_page_addr+$06], A
	LD A, $00
	LD [oam_page_addr+$07], A

	JR TradeExitCheck

TradeFlipCursor:
	; update cursor position
	LD A, [cursor_pos_y]
	LD [oam_page_addr+$00], A
	LD A, [cursor_pos_x]
	LD [oam_page_addr+$01], A
	LD A, $FA
	LD [oam_page_addr+$02], A
	LD A, $00
	LD [oam_page_addr+$03], A

	LD A, [cursor_pos_y]
	LD [oam_page_addr+$04], A
	LD A, [cursor_pos_x]
	ADD A, $08
	LD [oam_page_addr+$05], A
	LD A, $FB
	LD [oam_page_addr+$06], A
	LD A, $00
	LD [oam_page_addr+$07], A

	JR TradeExitCheck

TradeExitCheck:
	; check for menu trigger to return
	LD A, [menu_trig]
	CP A, $00
	JP Z, TradeHaltLoop
	LD A, $00
	LD [menu_trig], A
	RET

; check for up
TradeJoyUp:
	LD A, [joy_prev]
	AND A, $40
	JR NZ, TradeJoyUpSub1
	RET
TradeJoyUpSub1:
	LD A, [joy_curr]
	AND A, $40
	JR Z, TradeJoyUpSub2
	RET
TradeJoyUpSub2:
	LD A, [trade_sel]
	CP A, $00
	JR NZ, TradeJoyUpSub3
	RET
TradeJoyUpSub3:
	LD A, [trade_sel]
	DEC A
	LD [trade_sel], A
	LD A, [cursor_pos_y]
	SUB A, $08
	LD [cursor_pos_y], A
	RET

; check for down
TradeJoyDown:
	LD A, [joy_prev]
	AND A, $80
	JR NZ, TradeJoyDownSub1
	RET
TradeJoyDownSub1:
	LD A, [joy_curr]
	AND A, $80
	JR Z, TradeJoyDownSub2
	RET
TradeJoyDownSub2:
	LD A, [trade_sel]
	CP A, $09
	JR NZ, TradeJoyDownSub3
	RET
TradeJoyDownSub3:
	LD A, [trade_sel]
	INC A
	LD [trade_sel], A
	LD A, [cursor_pos_y]
	ADD A, $08
	LD [cursor_pos_y], A
	LD A, [trade_sel]
	CP A, $09
	JR Z, TradeJoyDownSub4
	RET
TradeJoyDownSub4:
	LD A, $00
	LD [trade_dir], A
	LD A, $68
	LD [cursor_pos_x], A
	RET

; check for left
TradeJoyLeft:
	LD A, [joy_prev]
	AND A, $20
	JR NZ, TradeJoyLeftSub1
	RET
TradeJoyLeftSub1:
	LD A, [joy_curr]
	AND A, $20
	JR Z, TradeJoyLeftSub2
	RET
TradeJoyLeftSub2:
	LD A, $00
	LD [trade_dir], A
	LD A, $68
	LD [cursor_pos_x], A
	RET

; check for right
TradeJoyRight:
	LD A, [joy_prev]
	AND A, $10
	JR NZ, TradeJoyRightSub1
	RET
TradeJoyRightSub1:
	LD A, [joy_curr]
	AND A, $10
	JR Z, TradeJoyRightSub2
	RET
TradeJoyRightSub2:
	LD A, [trade_sel]
	CP A, $09
	JR NZ, TradeJoyRightSub3
	RET
TradeJoyRightSub3:
	LD A, $01
	LD [trade_dir], A
	LD A, $88
	LD [cursor_pos_x], A
	RET

; check for action
TradeJoyAction:
	LD A, [joy_prev]
	AND A, $01
	JR NZ, TradeJoyActionSub1
	RET
TradeJoyActionSub1:
	LD A, [joy_curr]
	AND A, $01
	JR Z, TradeJoyActionSub2
	RET
TradeJoyActionSub2:	
	LD A, [trade_sel]
	CP A, $09
	JR NZ, TradeJoyActionSub3
	LD A, $01
	LD [menu_type], A
	LD A, $01
	LD [menu_trig], A
	RET
TradeJoyActionSub3:
	LD A, [trade_dir]
	CP A, $00
	JR Z, TradeJoyActionSub5
	
	; sell
	LD A, [trade_sel]
	LD C, A
	LD B, $00
	LD HL, trade_price
	ADD HL, BC
	LD A, [HL]
	LD E, A

	LD A, [trade_money+2]
	CP A, $00
	JR NZ, TradeJoyActionSub4
	LD A, [trade_money+1]
	CP A, $00
	JR NZ, TradeJoyActionSub4
	LD A, [trade_money+0]
	CP A, E
	JR C, TradeJoyActionSub7

TradeJoyActionSub4:
	LD A, [trade_sel]
	LD C, A
	LD B, $00
	LD HL, inv_goods
	ADD HL, BC
	LD A, [HL]
	CP A, $00
	JR Z, TradeJoyActionSub7
	DEC A
	LD [HL], A

	LD A, [trade_sel]
	LD C, A
	LD B, $00
	LD HL, trade_goods
	ADD HL, BC
	LD A, [HL]
	INC A
	; check for 99x here
	LD [HL], A

	LD A, E
	PUSH AF
	CALL TradeSub
	POP AF
	CALL MoneyAdd

	JR TradeJoyActionSub7

TradeJoyActionSub5:
	; buy
	LD A, [trade_sel]
	LD C, A
	LD B, $00
	LD HL, trade_price
	ADD HL, BC
	LD A, [HL]
	LD E, A
	
	LD A, [inv_money+2]
	CP A, $00
	JR NZ, TradeJoyActionSub6
	LD A, [inv_money+1]
	CP A, $00
	JR NZ, TradeJoyActionSub6
	LD A, [inv_money+0]
	CP A, E
	JR C, TradeJoyActionSub7

TradeJoyActionSub6:
	LD A, [trade_sel]
	LD C, A
	LD B, $00
	LD HL, trade_goods
	ADD HL, BC
	LD A, [HL]
	CP A, $00
	JR Z, TradeJoyActionSub7
	DEC A
	LD [HL], A

	LD A, [trade_sel]
	LD C, A
	LD B, $00
	LD HL, inv_goods
	ADD HL, BC
	LD A, [HL]
	INC A
	; check for 99x here
	LD [HL], A

	LD A, E
	PUSH AF
	CALL MoneySub
	POP AF
	CALL TradeAdd

TradeJoyActionSub7:
	; calculate weight
	CALL TradeCalculate

	; reload trade counts
	CALL TradeUpdate

	; reload money display
	CALL MoneyDisplay

	; display money at top
	LD BC, $D8CE
	LD A, [trade_money+2]
	CALL DisplayDecimal
	LD BC, $D8D0
	LD A, [trade_money+1]
	CALL DisplayDecimal
	LD BC, $D8D2
	LD A, [trade_money+0]
	CALL DisplayDecimal

	; set transfer address for text at bottom
	LD A, $98
	LD [trans_addr+1], A
	LD A, $00
	LD [trans_addr+0], A

	RET

; updates trade count values
TradeUpdate:
	LD BC, $D8EA
	LD HL, trade_price
	LD E, $09 ; minus one
TradeUpdateLoop1:
	LD A, [HLI]
	CALL DisplayDecimal
	PUSH HL
	LD HL, $0020
	ADD HL, BC
	LD B, H
	LD C, L
	POP HL
	DEC E
	JR NZ, TradeUpdateLoop1

	LD BC, $D8EE
	LD HL, inv_goods
	LD E, $09 ; minus one
TradeUpdateLoop2:
	LD A, [HLI]
	CALL DisplayDecimal
	PUSH HL
	LD HL, $0020
	ADD HL, BC
	LD B, H
	LD C, L
	POP HL
	DEC E
	JR NZ, TradeUpdateLoop2

	LD BC, $D8F2	
	LD HL, trade_goods
	LD E, $09 ; minus one
TradeUpdateLoop3:
	LD A, [HLI]
	CALL DisplayDecimal
	PUSH HL
	LD HL, $0020
	ADD HL, BC
	LD B, H
	LD C, L
	POP HL
	DEC E
	JR NZ, TradeUpdateLoop3

	RET

TradeAdd:
	; add A to money
	LD C, A
	LD A, [trade_money+0]
	ADD A, C
	LD [trade_money+0], A
	CP A, $64
	JR C, TradeAddExit
	SUB A, $64
	LD [trade_money+0], A
	LD A, [trade_money+1]
	INC A
	LD [trade_money+1], A
	CP A, $64
	JR C, TradeAddExit
	SUB A, $64
	LD [trade_money+1], A
	LD A, [trade_money+2]
	INC A
	LD [trade_money+2], A
	CP A, $64
	JR C, TradeAddExit
	LD A, $63
	LD [trade_money+2], A
	LD [trade_money+1], A
	LD [trade_money+0], A
TradeAddExit:
	RET

TradeSub:
	; sub A to money
	LD C, A
	LD A, [trade_money+0]
	SUB A, C
	LD [trade_money+0], A
	JR NC, TradeSubExit
	ADD A, $64
	LD [trade_money+0], A
	LD A, [trade_money+1]
	DEC A
	LD [trade_money+1], A
	JR C, TradeSubExit
	ADD A, $64
	LD [trade_money+1], A
	LD A, [trade_money+2]
	DEC A
	LD [trade_money+2], A
	JR C, TradeSubExit
	LD A, $00
	LD [trade_money+2], A
	LD [trade_money+1], A
	LD [trade_money+0], A
TradeSubExit:
	RET
	

TradeCalculate:
	; calculate weights
	LD HL, $0000
	LD D, $00

TradeCalculateSub1:
	PUSH HL
	LD C, D
	LD B, $00
	LD HL, inv_goods
	ADD HL, BC
	LD A, [HL]
	CP A, $00
	JR Z, TradeCalculateSub3
	LD E, A
	LD HL, TradeWeights
	ADD HL, BC
	LD A, [HL]
	LD C, A
	LD B, $00
	POP HL
TradeCalculateSub2:
	ADD HL, BC
	DEC E
	JR NZ, TradeCalculateSub2
	PUSH HL
TradeCalculateSub3:
	POP HL
	INC D
	LD A, D
	CP A, $09
	JR NZ, TradeCalculateSub1

	LD A, H ; only high byte
	ADD A, $08 ; add base weight
	LD [inv_weight], A
	RET

TradeOptions:
	DB "FURS________________"
	DB "LUMBER______________"
	DB "AMBER_______________"
	DB "HONEY_______________"
	DB "WINE________________"
	DB "SPICES______________"
	DB "IVORY_______________"
	DB "SWORDS______________"
	DB "SILK________________"
	DB "______________BACK__"

TradeWeights:
	DB $10
	DB $40
	DB $04
	DB $08
	DB $20
	DB $04
	DB $08
	DB $20
	DB $08
	DB $00



; ****************
; ****************
; MENU CODE
; ****************
; ****************

MenuEntry:
	; redirect to correct menu
	LD A, [menu_type]
	AND A, $03
	CP A, $00
	JR Z, MenuMap
	CP A, $01
	JR Z, MenuCity
	CP A, $02
	JR Z, MenuEvent
	CP A, $03
	JR Z, MenuTrade

MenuMap:
	LD A, [menu_num]
	LD [map_loc], A
	CALL MapEntry
	JR MenuEntry

MenuCity:
	LD A, [menu_num]
	LD [city_loc], A
	CALL CityEntry
	JR MenuEntry

MenuEvent:
	LD A, [menu_num]
	LD [event_loc], A
	CALL EventEntry
	JR MenuEntry

MenuTrade:
	LD A, [menu_num]
	LD [trade_loc], A
	CALL TradeEntry
	JR MenuEntry




; transfer this to $FF80 in HRAM then call to transfer oam data
OamDmaHramCode:
	DB $3E, oam_page_high, $E0, $46, $3E, $28, $3D, $20, $FD, $C9

DateMonthData:
	DB "JAN"
	DB "FEB"
	DB "MAR"
	DB "APR"
	DB "MAY"
	DB "JUN"
	DB "JUL"
	DB "AUG"
	DB "SEP"
	DB "OCT"
	DB "NOV"
	DB "DEC"

DateSpeedData:
	DB $20 ; JAN
	DB $20
	DB $10
	DB $08 ; APR
	DB $00 ; MAY
	DB $00
	DB $00
	DB $00
	DB $00
	DB $00 ; OCT
	DB $08 ; NOV
	DB $10 ; DEC

DateWinterData:
	DB $0A ; JAN
	DB $08
	DB $04
	DB $50 ; APR
	DB $46 ; MAY
	DB $3C
	DB $32
	DB $28
	DB $1E
	DB $14 ; OCT
	DB $10 ; NOV
	DB $0C ; DEC

; two tiles: blank and wall
WallData:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	DB $20,$20,$50,$70,$A8,$D8,$55,$8D,$8A,$07,$05,$02,$02,$00,$00,$00

; three sets of two sprites
CursorData:
	DB $00,$00,$7F,$7F,$3F,$20,$1F,$10,$1F,$10,$3F,$20,$7F,$7F,$00,$00
	DB $00,$00,$F8,$F8,$04,$FC,$82,$7E,$82,$7E,$04,$FC,$F8,$F8,$00,$00
	DB $00,$00,$42,$42,$66,$66,$7E,$5A,$7E,$42,$7E,$42,$7E,$42,$7E,$42
	DB $5A,$66,$42,$7E,$42,$7E,$42,$7E,$42,$7E,$24,$3C,$18,$18,$00,$00
	DB $00,$00,$1F,$1F,$3A,$26,$74,$4C,$74,$4C,$3A,$26,$1F,$1F,$00,$00
	DB $00,$00,$F8,$F8,$5C,$64,$2E,$32,$2E,$32,$5C,$64,$F8,$F8,$00,$00

; 1024 bytes of font data
; ASCII value minus $20
FontData:
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$30,$30,$78,$78,$78,$78,$78,$78,$30,$30,$00,$00,$30,$30
	DB $00,$00,$6C,$6C,$6C,$6C,$24,$24,$48,$48,$00,$00,$00,$00,$00,$00
	DB $00,$00,$6C,$6C,$FE,$FE,$6C,$6C,$6C,$6C,$6C,$6C,$FE,$FE,$6C,$6C
	DB $00,$00,$10,$10,$7E,$7E,$D0,$D0,$7C,$7C,$16,$16,$FC,$FC,$10,$10
	DB $00,$00,$42,$42,$A6,$A6,$4C,$4C,$18,$18,$34,$34,$6A,$6A,$C4,$C4
	DB $00,$00,$70,$70,$D8,$D8,$70,$70,$DA,$DA,$CE,$CE,$C6,$C6,$7C,$7C
	DB $00,$00,$30,$30,$30,$30,$10,$10,$20,$20,$00,$00,$00,$00,$00,$00
	DB $00,$00,$1C,$1C,$30,$30,$60,$60,$60,$60,$60,$60,$30,$30,$1C,$1C
	DB $00,$00,$70,$70,$18,$18,$0C,$0C,$0C,$0C,$0C,$0C,$18,$18,$70,$70
	DB $00,$00,$6C,$6C,$38,$38,$6C,$6C,$00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$10,$10,$10,$10,$7C,$7C,$10,$10,$10,$10
	DB $00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$10,$10,$20,$20
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7C,$7C,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$30,$30,$30,$30
	DB $00,$00,$04,$04,$0C,$0C,$18,$18,$30,$30,$60,$60,$C0,$C0,$80,$80
	DB $00,$00,$7C,$7C,$C6,$C6,$8E,$8E,$9A,$9A,$B2,$B2,$E6,$E6,$7C,$7C
	DB $00,$00,$78,$78,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$7E,$7E
	DB $00,$00,$7C,$7C,$C6,$C6,$0C,$0C,$38,$38,$60,$60,$C0,$C0,$FE,$FE
	DB $00,$00,$7C,$7C,$C6,$C6,$06,$06,$3C,$3C,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$1E,$1E,$36,$36,$66,$66,$C6,$C6,$FE,$FE,$06,$06,$06,$06
	DB $00,$00,$FE,$FE,$C0,$C0,$FC,$FC,$06,$06,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$7C,$7C,$C6,$C6,$C0,$C0,$FC,$FC,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$FE,$FE,$C6,$C6,$0C,$0C,$18,$18,$30,$30,$60,$60,$C0,$C0
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$7C,$7C,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$7E,$7E,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00,$30,$30,$30,$30
	DB $00,$00,$00,$00,$00,$00,$30,$30,$30,$30,$00,$00,$30,$30,$10,$10
	DB $00,$00,$00,$00,$00,$00,$1C,$1C,$38,$38,$70,$70,$38,$38,$1C,$1C
	DB $00,$00,$00,$00,$00,$00,$00,$00,$7C,$7C,$00,$00,$7C,$7C,$00,$00
	DB $00,$00,$00,$00,$00,$00,$70,$70,$38,$38,$1C,$1C,$38,$38,$70,$70
	DB $00,$00,$7C,$7C,$C6,$C6,$06,$06,$3C,$3C,$30,$30,$00,$00,$30,$30
	DB $00,$00,$7C,$7C,$C6,$C6,$D6,$D6,$D6,$D6,$DC,$DC,$C0,$C0,$7C,$7C
	DB $00,$00,$38,$38,$6C,$6C,$C6,$C6,$C6,$C6,$FE,$FE,$C6,$C6,$C6,$C6
	DB $00,$00,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC
	DB $00,$00,$7C,$7C,$C6,$C6,$C0,$C0,$C0,$C0,$C0,$C0,$C6,$C6,$7C,$7C
	DB $00,$00,$F8,$F8,$CC,$CC,$C6,$C6,$C6,$C6,$C6,$C6,$CC,$CC,$F8,$F8
	DB $00,$00,$FE,$FE,$C0,$C0,$C0,$C0,$F8,$F8,$C0,$C0,$C0,$C0,$FE,$FE
	DB $00,$00,$FE,$FE,$C0,$C0,$C0,$C0,$F8,$F8,$C0,$C0,$C0,$C0,$C0,$C0
	DB $00,$00,$7E,$7E,$C0,$C0,$C0,$C0,$DE,$DE,$C6,$C6,$C6,$C6,$7E,$7E
	DB $00,$00,$C6,$C6,$C6,$C6,$C6,$C6,$FE,$FE,$C6,$C6,$C6,$C6,$C6,$C6
	DB $00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$7E,$7E
	DB $00,$00,$1E,$1E,$06,$06,$06,$06,$06,$06,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$C6,$C6,$CC,$CC,$D8,$D8,$F0,$F0,$D8,$D8,$CC,$CC,$C6,$C6
	DB $00,$00,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$FE,$FE
	DB $00,$00,$C6,$C6,$EE,$EE,$FE,$FE,$D6,$D6,$C6,$C6,$C6,$C6,$C6,$C6
	DB $00,$00,$C6,$C6,$E6,$E6,$F6,$F6,$DE,$DE,$CE,$CE,$C6,$C6,$C6,$C6
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC,$C0,$C0,$C0,$C0,$C0,$C0
	DB $00,$00,$7C,$7C,$C6,$C6,$C6,$C6,$C6,$C6,$DE,$DE,$CC,$CC,$7A,$7A
	DB $00,$00,$FC,$FC,$C6,$C6,$C6,$C6,$FC,$FC,$D8,$D8,$CC,$CC,$C6,$C6
	DB $00,$00,$7C,$7C,$C6,$C6,$C0,$C0,$7C,$7C,$06,$06,$C6,$C6,$7C,$7C
	DB $00,$00,$7E,$7E,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18,$18
	DB $00,$00,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$7C,$7C
	DB $00,$00,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$6C,$6C,$38,$38,$10,$10
	DB $00,$00,$C6,$C6,$C6,$C6,$D6,$D6,$FE,$FE,$EE,$EE,$C6,$C6,$C6,$C6
	DB $00,$00,$C6,$C6,$EE,$EE,$7C,$7C,$38,$38,$7C,$7C,$EE,$EE,$C6,$C6
	DB $00,$00,$66,$66,$66,$66,$66,$66,$3C,$3C,$18,$18,$18,$18,$18,$18
	DB $00,$00,$FE,$FE,$0E,$0E,$1C,$1C,$38,$38,$70,$70,$E0,$E0,$FE,$FE
	DB $00,$00,$7C,$7C,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$7C,$7C
	DB $00,$00,$40,$40,$60,$60,$30,$30,$18,$18,$0C,$0C,$06,$06,$02,$02
	DB $00,$00,$7C,$7C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C,$7C,$7C
	DB $00,$00,$10,$10,$38,$38,$6C,$6C,$C6,$C6,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; space
	;DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FE,$FE ; underscore


SECTION "Bank1", ROMX[$4000], BANK[1]

; image location and icon start and icon slopes
; 64 bytes each
MapData:
	; location 0
	DW MapOneImage ; address
	DB $05 ; bank
	DB "HEDEBY_TO_GOTLAND___" ; name
	DB $01, $03, $05 ; random events
	DB $1E, $8A ; coordinates
	DB $00, $00, $02, $00 ; slopes, count, and event
	DB $02, $00, $10, $00
	DB $02, $FF, $10, $00
	DB $02, $00, $02, $00
	DB $02, $FF, $11, $00
	DB $01, $FF, $1A, $00
	DB $00, $FE, $01, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00

	; location 1
	DW MapOneImage ; address
	DB $05 ; bank
	DB "GOTLAND_TO_SIGTUNA__" ; name
	DB $01, $03, $05 ; random events
	DB $9E, $4C ; coordinates
	DB $00, $00, $02, $00 ; slopes, count, and event
	DB $00, $FE, $0D, $00
	DB $FF, $FF, $08, $00
	DB $FE, $00, $02, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00

	; location 2
	DW MapTwoImage ; address
	DB $05 ; bank
	DB "SIGTUNA_TO_ALAND____" ; name
	DB $01, $03, $05 ; random events
	DB $19, $54 ; coordinates
	DB $00, $00, $02, $00 ; slopes, count, and event
	DB $01, $01, $06, $00
	DB $01, $FF, $0A, $00
	DB $02, $00, $0D, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00
	DB $00, $00, $00, $00

	; location 3
	DW MapTwoImage ; address
	DB $05 ; bank
	DB "ALAND_TO_LADOGA_____" ; name
	DB $01, $03, $05 ; random events
	DB $43, $50 ; coordinates
	DB $00, $00, $02, $00 ; slopes, count, and event
	DB $01, $01, $04, $00
	DB $02, $00, $1C, $00
	DB $01, $FF, $04, $00
	DB $01, $FF, $04, $12 ; Neva Delta
	DB $01, $01, $0A, $00
	DB $01, $FF, $0D, $00
	DB $01, $01, $05, $00
	DB $00, $00, $00, $00

SECTION "Bank2", ROMX[$4000], BANK[2]

; 32 bytes each
CityData:
	; location 0
	DW CityHedebyImage ; address
	DB $06 ; bank
	DB "HEDEBY______________" ; name
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 1
	DW CityGotlandImage ; address
	DB $06 ; bank
	DB "GOTLAND_____________" ; name
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 2
	DW CitySigtunaImage ; address
	DB $06 ; bank
	DB "SIGTUNA_____________" ; name
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 3
	DW CityAlandImage ; address
	DB $06 ; bank
	DB "ALAND_______________" ; name
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 4
	DW CityLadogaImage ; address
	DB $07 ; bank
	DB "LADOGA______________" ; name
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

SECTION "Bank3", ROMX[$4000], BANK[3]

; 128 bytes each
EventData:
	; location 0 (unused)
	DW $4000 ; address
	DB $01 ; bank
	DB "____________________" ; name
	DB "____________________" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeContinue ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 1 (seasonal summer)
	DW EventFogImage ; address
	DB $08 ; bank
	DB "HEAVY_FOG___________" ; name
	DB "__CONTINUE_AS_USUAL_" ; options
	DB "__SLOW_DOWN_________"
	DB "____________________"
	DB "____________________"
	DW EventCodeObstacleFast ; code addresses
	DW EventCodeObstacleSlow
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 2 (seasonal winter)
	DW EventIceImage ; address
	DB $08 ; bank
	DB "ICE_DEBRIS__________" ; name
	DB "__CONTINUE_AS_USUAL_" ; options
	DB "__SLOW_DOWN_________"
	DB "____________________"
	DB "____________________"
	DW EventCodeObstacleFast ; code addresses
	DW EventCodeObstacleSlow
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 3 (seasonal summer)
	DW EventStormImage ; address
	DB $08 ; bank
	DB "STORM_______________" ; name
	DB "__CONTINUE_AS_USUAL_" ; options
	DB "__SLOW_DOWN_________"
	DB "__WAIT_IT_OUT_______"
	DB "____________________"
	DW EventCodeStormFast ; code addresses
	DW EventCodeStormSlow
	DW EventCodeStormStop
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 4 (seasonal winter)
	DW EventBlizzardImage ; address
	DB $08 ; bank
	DB "BLIZZARD____________" ; name
	DB "__CONTINUE_AS_USUAL_" ; options
	DB "__SLOW_DOWN_________"
	DB "__WAIT_IT_OUT_______"
	DB "____________________"
	DW EventCodeStormFast ; code addresses
	DW EventCodeStormSlow
	DW EventCodeStormStop
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 5 (seaonsal summer)
	DW EventInjuryImage ; address
	DB $09 ; bank
	DB "INJURY______________" ; name
	DB "__CONTINUE_AS_USUAL_" ; options
	DB "__SLOW_DOWN_________"
	DB "__REST_HERE_________"
	DB "____________________"
	DW EventCodeInjuryFast ; code addresses
	DW EventCodeInjurySlow
	DW EventCodeInjuryStop
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 6 (seasonal winter)
	DW EventSicknessImage ; address
	DB $09 ; bank
	DB "SICKNESS____________" ; name
	DB "__CONTINUE_AS_USUAL_" ; options
	DB "__SLOW_DOWN_________"
	DB "__REST_HERE_________"
	DB "____________________"
	DW EventCodeInjuryFast ; code addresses
	DW EventCodeInjurySlow
	DW EventCodeInjuryStop
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 7
	DW $4000 ; address
	DB $01 ; bank
	DB "BANDIT_AMBUSH_______" ; name
	DB "__PAY_TOLL__________" ; options
	DB "__SURRENDER_________"
	DB "__FIGHT_BACK________"
	DB "____________________"
	DW EventCodeBanditsFirst ; code addresses
	DW EventCodeBanditsSecond
	DW EventCodeBanditsThird
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 8
	DW $4000 ; address
	DB $01 ; bank
	DB "VESSEL_OVERTURNED___" ; name
	DB "__LEAVE_REMAINS_____" ; options
	DB "__GATHER_ITEMS______"
	DB "____________________"
	DB "____________________"
	DW EventCodeOverturnedFirst ; code addresses
	DW EventCodeOverturnedSecond
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 9
	DW $4000 ; address
	DB $01 ; bank
	DB "OVERNIGHT_THEFT_____" ; name
	DB "__MOVE_ONWARD_______" ; options
	DB "__SEARCH_NEARBY_____"
	DB "____________________"
	DB "____________________"
	DW EventCodeTheftFirst ; code addresses
	DW EventCodeTheftSecond
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 10
	DW $4000 ; address
	DB $01 ; bank
	DB "SPOILED_GOODS_______" ; name
	DB "__DUMP_AND_LEAVE____" ; options
	DB "__SALVAGE_PARTS_____"
	DB "____________________"
	DB "____________________"
	DW EventCodeSpoiledFirst ; code addresses
	DW EventCodeSpoiledSecond
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 11
	DW $4000 ; address
	DB $01 ; bank
	DB "MISSIONARY__________" ; name
	DB "__BECOME_BAPTIZED___" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeContinue ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 12
	DW $4000 ; address
	DB $01 ; bank
	DB "FAIR_WINDS__________" ; name
	DB "__MOVE_QUICKER______" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeWinds ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 13
	DW $4000 ; address
	DB $01 ; bank
	DB "FISH_CAUGHT_________" ; name
	DB "__HOLD_FEAST________" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeFeast ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 14
	DW $4000 ; address
	DB $01 ; bank
	DB "ABANDONED_CARGO_____" ; name
	DB "__SEARCH_GOODS______" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeFound ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 15
	DW $4000 ; address
	DB $01 ; bank
	DB "FRIENDLY_LOCALS_____" ; name
	DB "__ACCEPT_COINS______" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeCoins ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00



	; location 16
	DW EventSummerImage ; address
	DB $09 ; bank
	DB "SUMMER_STARTS_______" ; name
	DB "__CELEBRATE_________" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeDate ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

	; location 17
	DW EventWinterImage ; address
	DB $09 ; bank
	DB "WINTER_STARTS_______" ; name
	DB "__CELEBRATE_________" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeDate ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00



	; location 18
	DW EventNevaImage ; address
	DB $0A ; bank
	DB "NEVA_DELTA__________" ; name
	DB "__CONTINUE__________" ; options
	DB "____________________"
	DB "____________________"
	DB "____________________"
	DW EventCodeContinue ; code addresses
	DW EventCodeBlank
	DW EventCodeBlank
	DW EventCodeBlank
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00

EventCodeBlank:
	RET

EventCodeContinue:
	LD A, $00
	LD [menu_type], A
	LD A, $01
	LD [menu_trig], A
	LD A, [menu_prev]
	LD [menu_num], A
	RET

EventCodeGoodsLost:
	; lose 'A' goods here
	LD E, A
	LD D, $10
EventCodeGoodsLostLoop:
	DEC D ; in case zero inventory
	JP Z, EventCodeContinue
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	CP A, $09
	JR NC, EventCodeGoodsLostLoop
	LD C, A
	LD B, $00
	LD HL, inv_goods
	ADD HL, BC
	LD A, [HL]
	CP A, $00
	JR Z, EventCodeGoodsLostLoop
	DEC A
	LD [HL], A
	LD D, $10
	DEC E
	JR NZ, EventCodeGoodsLostLoop
	JP EventCodeContinue

EventCodeGoodsGained:
	; gain 'A' goods here
	LD E, A
EventCodeGoodsGainedLoop:
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	CP A, $09
	JR NC, EventCodeGoodsGainedLoop
	LD C, A
	LD B, $00
	LD HL, inv_goods
	ADD HL, BC
	LD A, [HL]
	INC A
	; check for 99x here
	LD [HL], A
	DEC E
	JR NZ, EventCodeGoodsGainedLoop
	JP EventCodeContinue

EventCodeObstacleFast:
	LD A, [inv_fatigue]
	INC A
	LD [inv_fatigue], A
	JP EventCodeContinue

EventCodeObstacleSlow:
	LD A, $04
	LD [inv_slow], A
	JP EventCodeContinue

EventCodeStormFast:
	LD A, [inv_fatigue]
	ADD A, $02
	LD [inv_fatigue], A
	LD A, $04
	JP EventCodeGoodsLost

EventCodeStormSlow:
	LD A, [inv_fatigue]
	INC A
	LD [inv_fatigue], A
	LD A, $06
	LD [inv_slow], A
	LD A, $02
	JP EventCodeGoodsLost

EventCodeStormStop:
	LD A, $07
	LD [inv_stop], A
	JP EventCodeContinue

EventCodeInjuryFast:
	LD A, [inv_fatigue]
	ADD A, $03
	LD [inv_fatigue], A
	JP EventCodeContinue

EventCodeInjurySlow:
	LD A, [inv_fatigue]
	ADD A, $02
	LD [inv_fatigue], A
	LD A, $06
	LD [inv_slow], A
	JP EventCodeContinue

EventCodeInjuryStop:
	LD A, [inv_fatigue]
	INC A
	LD [inv_fatigue], A
	LD A, $07
	LD [inv_stop], A
	JP EventCodeContinue

EventCodeBanditsFirst:
	LD A, [inv_money+2]
	CP A, $00
	JR NZ, EventCodeBanditsSub
	LD A, [inv_money+1]
	CP A, $00
	JR NZ, EventCodeBanditsSub
	LD A, [inv_money+0]
	CP A, $32
	JR C, EventCodeBanditsSecond
EventCodeBanditsSub:
	LD A, $32
	CALL MoneySub
	JP EventCodeContinue

EventCodeBanditsSecond:
	LD A, $08
	JP EventCodeGoodsLost

EventCodeBanditsThird:
	LD A, [inv_fatigue]
	ADD A, $04
	LD [inv_fatigue], A
	LD A, $04
	JP EventCodeGoodsLost

EventCodeOverturnedFirst:
	LD A, $06
	JP EventCodeGoodsLost

EventCodeOverturnedSecond:
	LD A, [inv_fatigue]
	ADD A, $03
	LD [inv_fatigue], A
	LD A, $03
	JP EventCodeGoodsLost

EventCodeTheftFirst:
	LD A, $04
	JP EventCodeGoodsLost

EventCodeTheftSecond:
	LD A, [inv_fatigue]
	ADD A, $02
	LD [inv_fatigue], A
	LD A, $02
	JP EventCodeGoodsLost

EventCodeSpoiledFirst:
	LD A, $02
	JP EventCodeGoodsLost

EventCodeSpoiledSecond:
	LD A, [inv_fatigue]
	INC A
	LD [inv_fatigue], A
	LD A, $01
	JP EventCodeGoodsLost

EventCodeWinds:
	LD A, $06
	LD [inv_fast], A
	LD A, $00
	LD [inv_slow], A
	LD A, $00
	LD [inv_stop], A
	JP EventCodeContinue

EventCodeFeast:
	LD A, [inv_fatigue]
	CP A, $00
	JP Z, EventCodeContinue
	DEC A
	LD [inv_fatigue], A
	JP EventCodeContinue

EventCodeFound:
	LD A, $02
	JP EventCodeGoodsGained

EventCodeCoins:
	CALL Randomize
	LD A, [rand_val]
	SRL A
	SRL A
	SRL A
	SRL A
	ADD A, $04
	CALL MoneyAdd
	JP EventCodeContinue

EventCodeDate:
	LD A, $03 ; skips a day or two
	LD [date_day], A
	JP EventCodeContinue


SECTION "Bank4", ROMX[$4000], BANK[4]

; 64 bytes each
TradeData:
	; location 0
	DW CityHedebyImage+$0500 ; address
	DB $06 ; bank
	DB "HEDEBY______________" ; name
	DB $18,$04,$1F,$0B,$12,$35,$35,$21,$44 ; prices
	DB $04,$14,$08,$08,$14,$06,$03,$0F,$04 ; goods
	DB $00,$10,$32 ; money
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00

	; location 1
	DW CityGotlandImage+$0500 ; address
	DB $06 ; bank
	DB "GOTLAND_____________" ; name
	DB $12,$06,$1A,$0B,$1B,$38,$37,$29,$40 ; prices
	DB $0A,$04,$14,$07,$05,$04,$05,$05,$06 ; goods
	DB $00,$09,$00 ; money
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00

	; location 2
	DW CitySigtunaImage+$0500 ; address
	DB $06 ; bank
	DB "SIGTUNA_____________" ; name
	DB $10,$04,$20,$0C,$1D,$40,$2E,$23,$50 ; prices
	DB $10,$12,$06,$05,$00,$00,$0C,$0A,$00 ; goods
	DB $00,$07,$32 ; money
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00

	; location 3
	DW CityAlandImage+$0500 ; address
	DB $06 ; bank
	DB "ALAND_______________" ; name
	DB $14,$06,$1C,$0D,$1C,$44,$34,$2D,$53 ; prices
	DB $06,$03,$0C,$02,$02,$00,$02,$00,$00 ; goods
	DB $00,$03,$32 ; money
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00

	; location 4
	DW CityLadogaImage+$0500 ; address
	DB $07 ; bank
	DB "LADOGA______________" ; name
	DB $0E,$04,$24,$08,$1E,$3A,$38,$2E,$3D ; prices
	DB $14,$0E,$02,$14,$00,$03,$00,$01,$08 ; goods
	DB $00,$06,$32 ; money
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00,$00,$00,$00,$00
	DB $00,$00,$00,$00

