;;----------------------------------------------------------------------------------------------------------------------
;; Layer 2 Demo
;;----------------------------------------------------------------------------------------------------------------------

L2Demo:

                ; Initialise the palette
                nextreg $43,%00010000           ; Select L2 palette 0 for editing
                nextreg $40,0                   ; Start at palette index 0

                ld      hl,DefPalette
                ld      b,0                     ; 256 colours
.l1             ld      a,(hl)
                inc     hl
                nextreg $44,a                   ; Output data to palette
                ld      a,(hl)
                inc     hl
                nextreg $44,a                   ; 2nd byte
                djnz    .l1

                ; Initialise the screen
                nextreg $12,8                   ; Set first page for L2 (page 16-21)
                nextreg $13,11                  ; Set first page for shadow L2 (page 22-27)

                ; Draw screen
.loop
                halt

                ;ld      a,6
                ;out     ($fe),a

                ; Draw the screen
                ld      a,32
                call    DrawScreen

                xor     a
                out     ($fe),a
                jr      .loop

;;----------------------------------------------------------------------------------------------------------------------
;; DMA routines
;;----------------------------------------------------------------------------------------------------------------------

memcpy_dma:
                db      %11000011       ; R6: Reset
                db      %11000111       ; R6: Reset Port A timing
                db      %11001011       ; R6: Reset Port B timing

                ; Register 0 set up
                db      %01111101       ; R0: A -> B, transfer mode
mc_dma_src:     dw      0               ; Source address
mc_dma_len:     dw      0               ; Length

                ; Register 1 set up (Port A configuration)
                db      %01010100       ; R1: Port A config: increment, variable timing
                db      2               ; R1: Cycle length port A

                ; Register 2 set up (Port B configuration)
                db      %01010000       ; R2: Port B config: address fixed, variable timing
                db      2

                ; Register 4 set up (Operation mode)
                db      %10101101       ; R4: Continuous mode, set destination address
mc_dma_dest:    dw      0               ; Destination address

                ; Register 5 set up (Some control)
                db      %10000010       ; R5: Stop at end of block; read active low

                ; Register 6 (Commands)
                db      %11001111       ; R6: Load
                db      %10000111       ; R6: Enable DMA


memcpy_len      EQU     $-memcpy_dma

memcpy:
        ; Input:
        ;       HL = source address
        ;       DE = destination address
        ;       BC = number of bytes
        ;
                push    bc
                push    hl
                ld      (mc_dma_src),hl         ; Set up the source address
                ld      (mc_dma_len),bc         ; Set up the length
                ld      (mc_dma_dest),de        ; Set up the destination address

                ld      hl,memcpy_dma
                ld      b,memcpy_len
                ld      c,$6b
                otir                            ; Send DMA program
                ei
                pop     hl
                pop     bc
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Layer 2 routines
;;----------------------------------------------------------------------------------------------------------------------

PrepareL2:
        ; Input:
        ;       A: start page to put in MMU6 (A+1 -> MMU7)
        ;       B: which third
        ; Output:
        ;       A: original value + 2 (points to next page after image)
        ;       B: next third

                nextreg $56,a
                inc     a
                nextreg $57,a
                inc     a
                push    af
                ld      a,b
                inc     b
                push    bc
                rrca
                rrca
                or      3               ; L2 visible, write to slot 0/1
                ld      bc,$123b
                out     (c),a
                pop     bc
                pop     af
                ret

CopyThird:
        ; Copies third of L2 from MMU6/7 to L2 mapped at MM0/1
                push    bc
                push    de
                push    hl
                ld      hl,$c000
                ld      de,0
                ld      bc,16384
                call    memcpy
                pop     hl
                pop     de
                pop     bc
                ret

DrawScreen:
        ; Input:
        ;       A: start page of image
        ;
                ld      b,0
                call    PrepareL2
                call    CopyThird
                call    PrepareL2
                call    CopyThird
                call    PrepareL2
                call    CopyThird
                ret

;;----------------------------------------------------------------------------------------------------------------------
;; Data
;;----------------------------------------------------------------------------------------------------------------------

DefPalette:     incbin "data/screen.nip",6

                MMU     6,32
                org     $c000
                incbin  "data/screen.nim",8+$0000,8192

                MMU     7,33
                org     $e000
                incbin  "data/screen.nim",8+$2000,8192

                MMU     6,34
                org     $c000
                incbin  "data/screen.nim",8+$4000,8192

                MMU     7,35
                org     $e000
                incbin  "data/screen.nim",8+$6000,8192

                MMU     6,36
                org     $c000
                incbin  "data/screen.nim",8+$8000,8192

                MMU     7,37
                org     $e000
                incbin  "data/screen.nim",8+$a000,8192


