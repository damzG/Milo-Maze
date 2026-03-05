*-----------------------------------------------------------
* Title      : A Text-based Maze Game
* Written by : Oyindamola Olaosun
* Date       : 16th February, 2026
* Description: A simple project explaining nice concepts
*-----------------------------------------------------------

;====CONSTANTS Game Items=======
MAX_MOVES EQU 50 ;Maximum number of moves
MAX_ENERGY EQU 100 ;Total amount of energy
ENERGY_PER_MOVE EQU 2 ;Cost per move
BOOST_SCORE EQU 10  ;Points from pickup
BOOST_ENERGY EQU 15 ; Energy from pickup
CR EQU $0D
LF EQU $0A
MAZE_SIZE EQU 8 ;map size
MAP_CELLS EQU MAZE_SIZE*MAZE_SIZE ;map cells
;0 = empty, 1 = obstacle, 2 = pickup, 3 = goal, 4 = milo on a cell
;.ROUTINE -> local routine

    ORG    $1000
    ;Start of the game with a welcome message
START:
    BSR INITIALIZE_GAME ;Resets all game attributes
    BSR WELCOME
    
MAIN_LOOP:
    BSR DISPLAY_STATUS
    BSR GET_INPUT
    BSR VALIDATE_MOVE

    TST.L D0
    BEQ MAIN_LOOP

    MOVE.W PLAYER_X, OLD_X
    MOVE.W PLAYER_Y, OLD_Y

    BSR EXECUTE_MOVE

    ; If goal reached D0 = 1
    CMP.L #1, D0
    BEQ WIN_GAME

    BSR CHECK_LOSE_CONDITIONS
    TST.L D0
    BNE LOSE_GAME

    BRA MAIN_LOOP
        

INITIALIZE_GAME:
    ;Resets all player items
    CLR.L PLAYER_SCORE
    CLR.L MOVE_COUNT
    
    ;Put max_energy into player energy (before it decreases in the game loop)
    MOVE.L #MAX_ENERGY, PLAYER_ENERGY
    
    ;Reset player position
    CLR.W PLAYER_X
    CLR.W PLAYER_Y
    RTS
    
WELCOME:
    ;Clear screen first
    MOVE.W #$FF00, D1 ;load the entire screen command into D1
    MOVE.L #11, D0 ;load the task code 11 into D0 
    TRAP #15
    
    ;Top border
    LEA WELCOME_MESSAGE1, A1
    MOVE.L #13, D0 ;task code 13 with CR/LF
    TRAP #15
    
    ;Title
    LEA WELCOME_MESSAGE2, A1
    MOVE.L #13, D0
    TRAP #15
    
    ;Bottom border
    LEA WELCOME_MESSAGE3, A1
    MOVE.L #13, D0
    TRAP #15
    
    ;Instructions
    LEA WELCOME_MESSAGE4, A1
    MOVE.L #13, D0
    TRAP #15
    
    ;Controls
    LEA WELCOME_MESSAGE5, A1
    MOVE.L #13, D0
    TRAP #15
    
    ;Blank Line
    LEA WELCOME_MESSAGE6, A1
    MOVE.L #13, D0
    TRAP #15
    
    ;Wait for player to press any key before continuing
    LEA PRESS_KEY_MSG, A1
    MOVE.L #13, D0
    TRAP #15
    
    ;wait for keypress
    MOVE.L #5,D0 ;read single character from the keyboard
    TRAP #15
    
    RTS
    
    
DISPLAY_STATUS:
    MOVEM.L D0/D1/A1, -(SP)   ; save before displaying
    
    ;Clear screen each loop
    MOVE.W #$FF00, D1
    MOVE.L #11, D0
    TRAP #15

    ;Top border
    LEA STATUS_BORDER, A1
    MOVE.L #13, D0
    TRAP #15

    ; --- Score on its own line ---
    LEA     PLAYER_SCORE_LABEL, A1
    MOVE.L  #14, D0 ;task code 14 without CR/LF
    TRAP    #15
    MOVE.L  PLAYER_SCORE, D1
    MOVE.L  #3, D0
    TRAP    #15

    ; --- Energy on its own line ---
    MOVE.B  #CR, D1        ; Constants CR
    MOVE.L  #6, D0
    TRAP    #15
    MOVE.B  #LF, D1        ; Constants LF
    MOVE.L  #6, D0
    TRAP    #15

    LEA     PLAYER_ENERGY_LABEL, A1
    MOVE.L  #14, D0
    TRAP    #15
    MOVE.L  PLAYER_ENERGY, D1
    MOVE.L  #3, D0
    TRAP    #15

    ; --- Move count on its own line ---
    MOVE.B  #CR, D1
    MOVE.L  #6, D0 ;Display single character in D1.B
    TRAP    #15
    MOVE.B  #LF, D1
    MOVE.L  #6, D0 ;Display single character in D1.B
    TRAP    #15

    LEA     MOVE_COUNT_LABEL, A1
    MOVE.L  #14, D0
    TRAP    #15
    MOVE.L  MOVE_COUNT, D1
    MOVE.L  #3, D0
    TRAP    #15

    ; --- Final newline before prompt ---
    MOVE.B  #CR, D1
    MOVE.L  #6, D0
    TRAP    #15
    MOVE.B  #LF, D1
    MOVE.L  #6, D0
    TRAP    #15

    LEA STATUS_BORDER, A1 ;Bottom border
    MOVE.L #13, D0
    TRAP #15

    BSR DISPLAY_MAZE ;show maze
    BSR DISPLAY_LEGEND ;show legend

    MOVEM.L (SP)+, D0/D1/A1   ;  restore after
    RTS
    
    
GET_INPUT:  
    ;Prints input string
    LEA INPUT_MESSAGE, A1
    MOVE.B #14, D0
    TRAP #15
    
    ;Input a keyboard character like in asphalt nitro game
    MOVE.B #5, D0
    TRAP #15
    ;When you input a character, it lands in D1.B
    MOVE.B D1, INPUT_CHAR
    RTS
    
    
;Validating each character move before execution
VALIDATE_MOVE:    
    MOVE.B INPUT_CHAR, D1
    
    CMP.B #'W', D1
    BEQ MOVE_UP
    CMP.B #'A', D1
    BEQ MOVE_LEFT
    CMP.B #'S', D1
    BEQ MOVE_DOWN
    CMP.B #'D', D1
    BEQ MOVE_RIGHT
    
INVALID:
    LEA ERROR_MSG, A1
    MOVE.B #14, D0
    TRAP #15
    CLR.L D0
    RTS
    
    
EXECUTE_MOVE:
    MOVEM.L D1/D2/D3/A0, -(SP)
    
    ; Compute new position index
    ;Using the offset formula y * (no of columns) + x
    MOVE.W  PLAYER_Y, D2
    MULU.W #MAZE_SIZE, D2
    MOVE.W  PLAYER_X, D3
    ADD.W   D3, D2
    LEA     GAME_MAP, A0

    ; Check GOAL (3)
    CMP.B   #3, (A0, D2)
    BEQ     .GOAL_REACHED

    ; Check PICKUP (2)
    CMP.B   #2, (A0, D2)
    BNE     .NORMAL_MOVE

    BSR     COLLECT_PICKUP
    MOVE.B  #0, (A0, D2) (empty)
    BRA     .AFTER_MOVE

.NORMAL_MOVE:
    MOVE.B  #4, (A0, D2) (player on a cell)

.AFTER_MOVE:
    ;Now clear old position
    MOVE.W OLD_Y, D0
    MULU.W #MAZE_SIZE, D0
    MOVE.W OLD_X, D1
    ADD.W D1, D0
    MOVE.B #0, (A0, D0)
    
    BSR     INCREMENT_MOVES
    BSR     DECREASE_ENERGY

    MOVE.L  #0, D0     ; Normal move
    BRA     .DONE

.GOAL_REACHED:
    ;Now clear old position
    MOVE.W OLD_Y, D0
    MULU.W #MAZE_SIZE, D0
    MOVE.W OLD_X, D1
    ADD.W D1, D0
    MOVE.B #0, (A0, D0)

    BSR     INCREMENT_MOVES
    
    ;Give Goal Bonus Score
    MOVE.L PLAYER_SCORE, D0
    ADD.L #100, D0
    MOVE.L D0, PLAYER_SCORE
    
    MOVE.L  #1, D0     ; Signal win
    BRA .DONE

.DONE:
    MOVEM.L (SP)+, D1/D2/D3/A0
    RTS

INCREMENT_MOVES:              ;increment moves
    MOVE.L  MOVE_COUNT, D0
    ADDQ.L  #1, D0
    MOVE.L  D0, MOVE_COUNT
    RTS
    
    ;Cost per move subtracted from the player energy
DECREASE_ENERGY:
    MOVE.L PLAYER_ENERGY, D0
    SUB.L  #ENERGY_PER_MOVE, D0

    TST.L  D0
    BGT    .STORE

    MOVE.L #0, D0

.STORE:
    MOVE.L D0, PLAYER_ENERGY
    RTS
    
    ;When goal is reached time for win
WIN_GAME:
    MOVE.W  #$FF00, D1
    MOVE.L  #11, D0
    TRAP    #15
    LEA     WIN_BORDER, A1
    MOVE.L  #13, D0
    TRAP    #15
    LEA     WIN_MESSAGE, A1
    MOVE.L  #13, D0
    TRAP    #15
    LEA     WIN_BORDER, A1
    MOVE.L  #13, D0
    TRAP    #15

    BRA END_GAME    
    
    ;When player energy runs out
LOSE_GAME:
    MOVE.W  #$FF00, D1
    MOVE.L  #11, D0
    TRAP    #15
    LEA     LOSE_BORDER, A1
    MOVE.L  #13, D0
    TRAP    #15
    LEA     LOSE_MESSAGE, A1
    MOVE.L  #13, D0
    TRAP    #15
    LEA     LOSE_BORDER, A1
    MOVE.L  #13, D0
    TRAP    #15
    BRA END_GAME
    
    ;Time to finish the game and display result   
END_GAME:
    LEA     FINAL_LABEL, A1
    MOVE.L  #14, D0
    TRAP    #15
    MOVE.L  PLAYER_SCORE, D1
    MOVE.L  #3, D0
    TRAP    #15
    LEA     FINAL_MOVES, A1
    MOVE.L  #14, D0
    TRAP    #15
    MOVE.L  MOVE_COUNT, D1
    MOVE.L  #3, D0
    TRAP    #15
    ; --- Energy on its own line ---
    MOVE.B  #CR, D1        ; CR
    MOVE.L  #6, D0
    TRAP    #15
    MOVE.B  #LF, D1        ; LF
    MOVE.L  #6, D0
    TRAP    #15
    LEA     GOODBYE, A1
    MOVE.L  #13, D0
    TRAP    #15
    ;Terminate
    SIMHALT
    
;==Collect pickup===
COLLECT_PICKUP:
    MOVEM.L D0, -(SP)

    ; --- Add to score ---
    MOVE.L  PLAYER_SCORE, D0
    ADD.L   #BOOST_SCORE, D0
    MOVE.L  D0, PLAYER_SCORE

    ; --- Add to energy ---
    MOVE.L  PLAYER_ENERGY, D0
    ADD.L   #BOOST_ENERGY, D0

    ; --- Cap energy at maximum ---
    CMP.L   #MAX_ENERGY, D0
    BLE.S   .STORE
    MOVE.L  #MAX_ENERGY, D0

.STORE:
    MOVE.L  D0, PLAYER_ENERGY

    MOVEM.L (SP)+, D0   ; RESTORE REGISTER
    RTS

BLOCKED:
    MOVE.L #0, D0
    RTS


MOVE_UP:
    ;Goes from row 2 to row 1 so it will subtract
    MOVE.W PLAYER_Y, D0
    SUB.W #1, D0
    ;Check before saving
    CMP.W #0, D0 ; are you at the top edge
    BLT BLOCKED ;if less than 0, can't move there
    MOVE.W D0, D3
    MOVE.W PLAYER_X, D1
    BSR OBSTACLE_CHECK
    TST.L D0 ;check if blocked
    BEQ .DONE
    MOVE.W D3, PLAYER_Y ;only save now
    MOVE.W #1, D0 ;successfull move
    LEA UP_MESSAGE, A1
    MOVE.L #14, D0
    TRAP #15
    MOVE.L #1, D0
.DONE:
    RTS

MOVE_LEFT:
    ;Goes from column 2 to column 1 so it will subtract
    MOVE.W PLAYER_X, D1
    SUB.W #1, D1
    CMP.W #0, D1 ; are you at the leftmost edge
    BLT BLOCKED ; if less than 0, can't move there
    MOVE.W D1, D3
    MOVE.W PLAYER_Y, D0
    BSR OBSTACLE_CHECK ;check for obstacle
    TST.L D0 ;check if blocked
    BEQ .DONE
    MOVE.W D3, PLAYER_X ;only save now
    MOVE.W #1, D0 ;successfull move
    LEA LEFT_MESSAGE, A1
    MOVE.L #14, D0
    TRAP #15
    MOVE.L #1, D0
.DONE:
    RTS

MOVE_DOWN: 
    ;Goes from row 1 to row 2 so it will add 1
    MOVE.W PLAYER_Y, D0 
    ADD.W #1, D0
    ;Check before saving
    CMP.W #(MAZE_SIZE-1), D0 ;are you at the last row 
    BGT BLOCKED
    MOVE.W D0, D3
    MOVE.W PLAYER_X, D1
    BSR OBSTACLE_CHECK ;Check for obstacle
    TST.L D0 ;check if blocked
    BEQ .DONE
    MOVE.W D3, PLAYER_Y ; only save now
    MOVE.W #1, D0 ; successful move
    LEA DOWN_MESSAGE, A1
    MOVE.L #14, D0
    TRAP #15
    MOVE.L #1, D0
.DONE:
    RTS
    
MOVE_RIGHT:
    ;Goes from column 1 to column 2
    MOVE.W PLAYER_X, D1
    ADD.W #1, D1
    CMP.W #(MAZE_SIZE-1), D1 ;are you at the last column
    BGT BLOCKED
    ;check obstacle
    MOVE.W D1, D3
    MOVE.W PLAYER_Y, D0
    BSR OBSTACLE_CHECK
    TST.L D0 ;check if blocked
    BEQ .DONE ;if D0=0 hit, skip saving
    MOVE.W D3, PLAYER_X ;only save now
    MOVE.W #1, D0 ;successful move
    LEA RIGHT_MESSAGE, A1
    MOVE.L #14, D0
    TRAP #15
    MOVE.L #1, D0 ; restore D0=1 AFTER trap call
.DONE:
    RTS
    
OBSTACLE_CHECK:
    MOVEM.L D1/D3/A0, -(SP)

    MULU.W  #MAZE_SIZE, D0
    ADD.W   D1, D0
    LEA     GAME_MAP, A0

    CMP.B   #1, (A0, D0) ; is this cell a wall (1)
    BEQ     .BLOCKED

    MOVE.L  #1, D0
    BRA     .DONE

.BLOCKED:
    MOVE.L  #0, D0

.DONE:
    MOVEM.L (SP)+, D1/D3/A0
    RTS
  
CHECK_LOSE_CONDITIONS:
    ;Compares player move count and MAX_MOVES
    MOVE.L MOVE_COUNT, D0
    CMP.L #MAX_MOVES, D0
    BHS .LOSE
    
    MOVE.L PLAYER_ENERGY, D0
    TST.L D0
    BEQ .LOSE
    
    MOVE.L #0, D0
    RTS     
.LOSE:
    MOVE.L #1, D0
    RTS
    
DISPLAY_MAZE:
    MOVEM.L D0/D1/D2/D3/D4/D5/A0/A1, -(SP)  ;save A1 too
    LEA     GAME_MAP, A0 ;A0 = base address (used for reference)
    LEA     GAME_MAP, A1      ; A1 walks through map byte by byte
    CLR.L   D2                ; row counter starts at 0
;Outer loop - rows
.ROW_LOOP:
    CLR.L   D3                ; reset col counter to 0 each new row
;Inner loop - columns
.COL_LOOP:
    MOVE.B  (A1)+, D4         ; read byte and advance pointer directly
    ;D4 holds the raw map value for this cell while D2/D3 track 
    ;where we are for player position
    MOVE.W  PLAYER_Y, D5
    CMP.W   D2, D5 ;does current row match player row?
    BNE     .NOT_PLAYER
    MOVE.W  PLAYER_X, D5
    CMP.W   D3, D5 ; does current col match player col?
    BNE     .NOT_PLAYER

    MOVE.B  #'M', D1 ;both match - print player marker
    MOVE.L  #6, D0
    TRAP    #15
    BRA     .NEXT_COL

;D4 0, 1,2 ,3 ,4 -> Empty cell, wall, pickup, goal, previously visited
.NOT_PLAYER:
    CMP.B   #0, D4
    BNE     .CHECK_WALL
    MOVE.B  #'.', D1
    BRA     .PRINT

.CHECK_WALL:
    CMP.B   #1, D4
    BNE     .CHECK_PICKUP
    MOVE.B  #'#', D1
    BRA     .PRINT

.CHECK_PICKUP:
    CMP.B   #2, D4
    BNE     .CHECK_GOAL
    MOVE.B  #'*', D1
    BRA     .PRINT

.CHECK_GOAL:
    CMP.B   #3, D4
    BNE     .CHECK_TRAIL
    MOVE.B  #'G', D1
    BRA     .PRINT

.CHECK_TRAIL:
    CMP.B   #4, D4
    BNE     .PRINT_UNKNOWN
    MOVE.B  #'+', D1
    BRA     .PRINT

.PRINT_UNKNOWN:
    MOVE.B  #'?', D1

.PRINT:
    MOVE.L  #6, D0 ;Print out character in the loop
    TRAP    #15
    
;Print space and advance column
.NEXT_COL:
    MOVE.B  #' ', D1 ;space between cells for readability
    MOVE.L  #6, D0
    TRAP    #15

    ADDQ.L  #1, D3  ;col++
    CMP.L   #MAZE_SIZE, D3 ; reached end of row?
    BLT     .COL_LOOP

    ;New line after each row
    MOVE.B  #CR, D1
    MOVE.L  #6, D0
    TRAP    #15
    MOVE.B  #LF, D1
    MOVE.L  #6, D0
    TRAP    #15

    ADDQ.L  #1, D2
    CMP.L   #MAZE_SIZE, D2
    BLT     .ROW_LOOP

    ;Restore and return
    MOVEM.L (SP)+, D0/D1/D2/D3/D4/D5/A0/A1  ;
    RTS    
DISPLAY_LEGEND:
    LEA LEGEND_MSG1, A1
    MOVE.L #13, D0
    TRAP #15
    LEA LEGEND_MSG2, A1
    MOVE.L #13, D0
    TRAP #15
    RTS
    
;The Milo Maze
GAME_MAP:
     DC.B 0,0,2,0,1,0,0,0
     DC.B 1,0,0,0,0,0,1,0
     DC.B 0,2,1,2,0,0,0,0
     DC.B 0,0,0,0,1,0,2,0
     DC.B 2,0,1,0,0,0,0,0
     DC.B 0,0,0,1,0,0,1,0
     DC.B 0,1,0,0,0,2,0,0
     DC.B 0,0,0,1,0,0,0,3     
        
;=====Variables========

;===Player Attributes===
PLAYER_SCORE: dc.l 0
PLAYER_ENERGY: dc.l 100
INPUT_CHAR: dc.b 0
MOVE_COUNT: dc.l 0
PLAYER_X: dc.w 0
PLAYER_Y: dc.w 0
OLD_X: dc.w 0
OLD_Y: dc.w 0

;===Game message===
INPUT_MESSAGE: dc.b 'Enter your preferred direction: ', 0
WELCOME_MESSAGE1:   DC.B '==============================', 0
WELCOME_MESSAGE2:   DC.B '       *** MILO MAZE ***      ', 0
WELCOME_MESSAGE3:   DC.B '==============================', 0
WELCOME_MESSAGE4:   DC.B 'Navigate Milo through the maze', 0
WELCOME_MESSAGE5:   DC.B 'W=Up  A=Left  S=Down  D=Right ', 0
WELCOME_MESSAGE6:   DC.B '------------------------------', 0

ERROR_MSG: dc.b '!! Invalid input - Use W A S D only',0
WIN_MESSAGE: dc.b 'Milo made it out!', 0
WIN_BORDER:   DC.B  '*** YOU WIN! ***', 0
LOSE_BORDER:  DC.B  '!!! GAME OVER !!!', 0
LOSE_MESSAGE: dc.b 'Milo is lost in a ditch...', 0
FINAL_LABEL:  DC.B  'Final Score: ', 0
FINAL_MOVES:  DC.B  '  Total Moves: ', 0
GOODBYE:      DC.B  'Thanks for playing Milo Maze!', 0
FINAL_SCORE_MESSAGE: dc.b 'Final Score: ', 0
STATUS_BORDER: DC.B '--------------------------------', 0
PLAYER_SCORE_LABEL: dc.b 'Score: ', 0
PLAYER_ENERGY_LABEL: dc.b ' | Energy: ', 0
MOVE_COUNT_LABEL: dc.b ' | Moves: ', 0
UP_MESSAGE:     DC.B  '>> Moving Up...   ', 0
DOWN_MESSAGE:   DC.B  '>> Moving Down... ', 0
LEFT_MESSAGE:   DC.B  '>> Moving Left... ', 0
RIGHT_MESSAGE:  DC.B  '>> Moving Right...', 0
PRESS_KEY_MSG: DC.B 'Press any key to start...',0
LEGEND_MSG1: DC.B 'M=You  .=Empty  #=Wall', 0
LEGEND_MSG2: DC.B '*=Pickup  G=Goal  +=Visited', 0

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
