.DB "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

.define PPUCTRL $2000
.define PPUMASK $2001
.define PPUSTATUS $2002
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define JOYPAD1 $4016
.define scrollX $01
.define buttons $02
.define next_line $03
.define max_length $04
.define nametable_counter $05
.define nametable0 $06
.define nametable1 $07
.define current_nametable $08
.define nametable_number $09
.define background_scroll_x $0A
.define sprite_scroll_x $0B
.define sprite_scroll_y $0C

.ORG $8000

start:
    LDA #$10
    STA next_line
    LDA #$10
    STA max_length
    LDA #$00
    STA nametable_counter
    LDA #$20
    STA nametable0
    LDA #$24
    STA nametable1
    LDA #$00
    STA nametable_number


    ;set ppu mask
    LDA #%10000000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK

    ;background palette
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR
    ;palette colors
    LDA #$2C
    STA PPUDATA
    LDA #$0F
    STA PPUDATA
    LDA #$28
    STA PPUDATA
    LDA #$0F
    STA PPUDATA
    ;sprite palette
    LDA #$3F
    STA PPUADDR
    LDA #$10
    STA PPUADDR 
    ;palette colors
    LDA #$2C
    STA PPUDATA
    LDA #$30
    STA PPUDATA
    LDA #$16
    STA PPUDATA
    LDA #$02
    STA PPUDATA

    ;nametables
    LDA nametable0
    STA PPUADDR
    STA current_nametable
    LDA #$00
    STA PPUADDR
    
    LDX #$00
    
    JSR draw_background
    
    LDA PPUSTATUS

    LDA nametable1
    STA PPUADDR
    STA current_nametable
    LDA #$00
    STA PPUADDR
    
    LDX #$00
    LDA #$00
    STA nametable_counter
    LDA #$10
    STA next_line
    STA max_length
    LDY #$00
    JSR draw_background
    JSR draw_sprite
        

draw_background:
    STX PPUDATA
        INX
        
        CPX #$FF ;check end tile
        BEQ check
        
        CPX max_length
        BNE draw_background

        JSR go_down
        JMP draw_background

        check:
            LDA nametable_number
            CLC
            CMP #$01
            BEQ draw_sprite
        
        INC nametable_number
        RTS

draw_sprite:
    LDA #$00
    STA OAMADDR
    LDA #$54
    STA OAMDATA
    STA sprite_scroll_y
    LDA #$74
    STA OAMDATA
    LDA #%10000000
    STA OAMDATA
    LDA #$80
    STA OAMDATA
    STA sprite_scroll_x
    JMP loop


loop:
  JMP loop


go_down:
    CLC
    PHA
    LDA next_line
    CMP #$F0
    BEQ reset_and_add
    
    then:
        LDA current_nametable
        CLC
        ADC nametable_counter
        STA PPUADDR
        LDA next_line
        ADC #$10
        CLC
        STA PPUADDR
        ADC #$10
        STA next_line
        
        LDA max_length
        ADC #$10
        STA max_length
        PLA
        RTS
    
    reset_and_add:
        INY
        STY nametable_counter
        LDA #$00
        SEC
        SBC #$10
        STA next_line
        JMP then


readjoy:
    lda #$01
    sta JOYPAD1
    sta buttons
    lsr a
    sta JOYPAD1
joyloop:
    lda JOYPAD1
    lsr a 
    rol buttons
    bcc joyloop
    rts


nmi:
    PHA
    JSR readjoy
    PLA
    LDA buttons
    AND #%00000001
    BNE move_background_right
    LDA buttons
    AND #%00000010
    BNE move_background_left
    LDA buttons
    AND #%00001000
    BNE move_sprite_up
    LDA buttons
    AND #%00000100
    BNE move_sprite_down
    JMP load_scroll

    move_background_right:
        LDA background_scroll_x
        CMP #$00
        BEQ move_sprite_right
        INC background_scroll_x
        JMP move_sprite_right
        
    move_background_left:
        LDA background_scroll_x
        CMP #$82
        BEQ move_sprite_left
        DEC background_scroll_x
        JMP move_sprite_left

    move_sprite_right:
        LDA sprite_scroll_x
        CMP #$F8
        BEQ load_scroll
        INC sprite_scroll_x
        JMP load_scroll

     move_sprite_left:
        LDA sprite_scroll_x
        CMP #$00
        BEQ load_scroll
        DEC sprite_scroll_x
        JMP load_scroll

    move_sprite_up:
        LDA sprite_scroll_y
        CMP #$00
        BEQ load_scroll
        DEC sprite_scroll_y
        JMP load_scroll
        
    move_sprite_down:
        LDA sprite_scroll_y
        CMP #$E7
        BEQ load_scroll
        INC sprite_scroll_y
        JMP load_scroll

    load_scroll:
        LDA background_scroll_x
        STA PPUSCROLL
        LDA #$00
        STA PPUSCROLL
        LDA #$00
        STA OAMADDR
        LDA sprite_scroll_y
        STA OAMDATA 
        LDA #$03
        STA OAMADDR
        LDA sprite_scroll_x
        STA OAMDATA 

        
RTI


irq:
    RTI





.goto $FFFA

.dw nmi
.dw start
.dw irq

.incbin "aiv256.chr"
.incbin "aiv256.chr"