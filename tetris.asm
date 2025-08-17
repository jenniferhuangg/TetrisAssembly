#####################################################################
# Bitmap Display Configuration:
# - Unit width in pixels: 16 (update this as needed) 
# - Unit height in pixels: 16 (update this as needed)
# - Display width in pixels: 256 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Easy Features:
# 1. Implement gravity, so that each second that passes will automatically move the tetromino down one row
# 2. Assuming that gravity has been implemented, have the speed of gravity increase gradually over time, or after the player completes a certain number of rows
# Hard Features:
# 1. Track and display the player’s score, which is based on how many lines have been completed so far. This score needs to be displayed in pixels, not on the console display
# 2. Implement the full set of tetrominoes.
# 3. Add some animation to lines when they are completed (e.g. make them go poof)
# How to play:
# To play, click W to rotate the block, A to go left, D to go right, S to go down, whenever the block touches 
# another block/border bottom, it stops. Block cannot go out of bounds. Goal is to place blocks in a way where a line of the grid is filled.
# To fill a line, move and orient the block. Each line gives one point to the score, but for each line completed, the game goes faster! Good luck!
#
#
#####################################################################

##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
# basic display variables
WIDTH: .word 10 # width of grid 
MAXROWS: .word 16 # number of max rows
MAXROWSG: .word 15 # number of max rows in grid 
#colour variables
green: .word 0x00ff00 # green
yellow: .word 0xf5ef40 # yellow
orange: .word 0xf59733 # orange
teal: .word 0x2bfcfc # teal
# colours for digit
digit1: .word 0xc7c5c5
digit2: .word 0xfcfcfc 

#grid colours
gray: .word 0x2d2d2e # gray
gridgray: .word 0x272829 # gray used for grid
black: .word 0x000000 # black used for grid

#tetris blocks (x,y)
otetrominoX: .word 0,0,1,1
otetrominoY: .word 0,1,0,1

itetrominoX: .word 0,0,0,0
itetrominoY: .word 0,1,2,3

stetrominoX: .word 0, 1, 1, 2
stetrominoY: .word 1, 1, 0, 0

ztetrominoX: .word 0,1,1,2
ztetrominoY: .word 0,0,1,1

ltetrominoX: .word 0,0,0,1
ltetrominoY: .word 0,1,2,2

jtetrominoX: .word 1,1,1,0
jtetrominoY: .word 0,1,2,2

ttetrominoX: .word 0,1,1,2
ttetrominoY: .word 0,0,1,0

ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
# current moving block
currentvarX: .space 16 
currentvarY: .space 16

#store blocks with greatest y (lowest block) to check for collision
collisioncX: .space 16
collisioncY: .space 16
#memory
memoryX: .space 480
memoryY: .space 480
memlength: .word 0 # amount of blocks in memory
# score 
score: .word 0

# corresponding colors of blocks

##############################################################################
# Code
##############################################################################
	.text
	.globl main

	# Run the Tetris game.
main:
    addi $s1, $zero, 0          # row counter (y)
    addi $s2, $zero, 0          # column counter (x)
    addi $s6, $zero, 0          # clear row check
    jal initialize 
    j newblock 
# --------- Function: initialize ---------
initialize:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)            # Save return address

    # Initialize the game
    lw   $s0, ADDR_KBRD         # keyboard base address

    # insert grid pattern (gray)
    lw   $t0, ADDR_DSPL         # display base address
    lw   $t4, gridgray          # gray color
    lw   $t5, WIDTH             # width = 10
    lw   $t6, MAXROWS           # height = 16
    addi $t7, $zero, 0          # address offset
    addi $t8, $zero, 0          # row index
    addi $t9, $zero, 0          # column index
    jal  grid1

    # insert secondary grid pattern (black)
    lw   $t4, black
    addi $t7, $zero, 0
    addi $t8, $zero, 0
    addi $t9, $zero, 0
    jal  grid2

    # draw borders
    lw   $t4, gray
    jal  borderl
    jal  borderr
    jal  borderb
    jal testcoll # set score

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
grid1:
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    andi $t1, $t8, 1             # check if row (y) is odd
    beq  $t1, $zero, evenrowc    # if even, go to evenrow
    jal  oddrow                  # call oddrow
    j    nextrow1                 # skip to row increment

evenrowc:
    jal  evenrow                 # call evenrow
    j    nextrow1                 # skip to row increment

nextrow1:
    addi $t8, $t8, 1             # go to next row
    blt  $t8, $t6, grid1          # if not done, 
    lw $ra, 0($sp)               # load $ra back to go back to func call
    addi $sp, $sp, 4
    jr   $ra
grid2:
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    andi $t1, $t8, 1             # check if row (y) is odd
    beq  $t1, $zero, oddrowc    # if even, go to evenrow
    jal  evenrow                  # call oddrow
    j    nextrow2                 # skip to row increment

oddrowc:
    jal  oddrow                 # call evenrow
    j    nextrow2                 # skip to row increment

nextrow2:
    addi $t8, $t8, 1             # go to next row
    blt  $t8, $t6, grid2          # if not done, 
    lw $ra, 0($sp)               # load $ra back to go back to func call
    addi $sp, $sp, 4
    jr   $ra
    
oddrow: 
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    addi $t9, $zero, 1           # set $t9 to 1 (odd row starts at 1)
oddrowloop:
    jal address                  # get address
    sw $t4, 0($t7)               # paint the unit 
    addi $t9, $t9, 2             # increment x by 2 to go to next block
    blt $t9, $t5, oddrowloop     # loop
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                       # if address makes it to end of width, go to next row
evenrow:
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    addi $t9, $zero, 0           # set $t9 to 0 (even row starts at 0)
evenrowloop:
    jal address                  # get address
    sw $t4, 0($t7)               # paint the unit 
    addi $t9, $t9, 2             # increment x by 2 to go to next block
    blt $t9, $t5, evenrowloop    # loop
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                       # if address makes it to end of width, go to next row
testcoll:
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    lw $t4, teal
    # top border
    sw $t4, 232($t0)
    sw $t4, 236($t0)
    sw $t4, 240($t0)
    sw $t4, 244($t0)
    sw $t4, 248($t0)
    sw $t4, 252($t0)
    # bottom border
    sw $t4, 744($t0)
    sw $t4, 748($t0)
    sw $t4, 752($t0)
    sw $t4, 756($t0)
    sw $t4, 760($t0)
    sw $t4, 764($t0)
    # counter
    jal box
    jal printcount
    sw $t4, 0($t7)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra 
printcount:
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    
    lw $t0, score # get score address

    li $t1, 10 # store 10
    div $t0, $t1 # divide score by 10
    mflo $t2 # store ten digit
    mfhi $t3 # store ones digit
    # get corner point
    li $t9, 12 #x
    li $t8, 5 #y
    # load colour
    lw $t4, digit1
    jal digitprint 
    
    #change #
    add $t2, $zero, $t3 # gets one digit
    # add 3 to $t9, $t8 to shift to right digit
    # get corner point
    li $t9, 15 #x
    li $t8, 5 #y
    move $t2, $t3
    # load new colour
    lw $t4, digit2
    jal digitprint
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra   
digitprint:
    addi $sp, $sp, -4            # save $ra
    sw $ra, 0($sp)
    lw $t0, ADDR_DSPL 
    # check what number digit is equal to draw out specified digit
    beq $t2, $zero, zeroprint
    li $t1, 1
    beq $t2, $t1, oneprint
    li $t1, 2
    beq $t2, $t1, twoprint
    li $t1, 3
    beq $t2, $t1, threeprint
    li $t1, 4
    beq $t2, $t1, fourprint
    li $t1, 5
    beq $t2, $t1, fiveprint
    li $t1, 6
    beq $t2, $t1, sixprint
    li $t1, 7
    beq $t2, $t1, sevenprint
    li $t1, 8
    beq $t2, $t1, eightprint
    li $t1, 9
    beq $t2, $t1, nineprint
zeroprint: # draw out 0 on grid
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)

    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
    
oneprint: # draw out one on grid
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
twoprint: # draw out two on grid
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 2
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
threeprint: # draw out three on grid
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 2
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 2
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    j doneprint
fourprint: # draw out four on grid 
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 2
    addi $t8, $t8, 2
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
fiveprint: # draw out five on grid
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)

    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    j doneprint
sixprint: # draw out six on grid
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)

    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    j doneprint
sevenprint: # draw out seven on grid
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, 2
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
eightprint: # draw out eight on grid
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    
    # 8 branch
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1

    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
nineprint: # draw out nine on grid
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, 1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t8, $t8, -2
    jal address
    sw $t4, 0($t7)
    
    # 8 branch
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    addi $t9, $t9, -1

    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    addi $t8, $t8, -1
    jal address
    sw $t4, 0($t7)
    
    addi $t9, $t9, 1
    jal address
    sw $t4, 0($t7)
    j doneprint
doneprint: # finish printing
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra 
    
box: # draw out box behind the digits (used to erase previous digits)
    lw $t4, black
    sw $t4, 296($t0)
    sw $t4, 300($t0)
    sw $t4, 304($t0)
    sw $t4, 308($t0)
    sw $t4, 312($t0)
    sw $t4, 316($t0)
    
    sw $t4, 360($t0)
    sw $t4, 364($t0)
    sw $t4, 368($t0)
    sw $t4, 372($t0)
    sw $t4, 376($t0)
    sw $t4, 380($t0)
    
    sw $t4, 424($t0)
    sw $t4, 428($t0)
    sw $t4, 432($t0)
    sw $t4, 436($t0)
    sw $t4, 440($t0)
    sw $t4, 444($t0)
    
    sw $t4, 488($t0)
    sw $t4, 492($t0)
    sw $t4, 496($t0)
    sw $t4, 500($t0)
    sw $t4, 504($t0)
    sw $t4, 508($t0)
    
    sw $t4, 552($t0)
    sw $t4, 556($t0)
    sw $t4, 560($t0)
    sw $t4, 564($t0)
    sw $t4, 568($t0)
    sw $t4, 572($t0)
    
    sw $t4, 616($t0)
    sw $t4, 620($t0)
    sw $t4, 624($t0)
    sw $t4, 628($t0)
    sw $t4, 632($t0)
    sw $t4, 636($t0)
    
    sw $t4, 680($t0)
    sw $t4, 684($t0)
    sw $t4, 688($t0)
    sw $t4, 692($t0)
    sw $t4, 696($t0)
    sw $t4, 700($t0)
   
    jr $ra 
borderl:
    sw $t4, 0($t0)               # paint the unit for left border
    sw $t4, 64($t0)
    sw $t4, 128($t0)
    sw $t4, 192($t0)
    sw $t4, 256($t0)
    sw $t4, 320($t0)
    sw $t4, 384($t0)
    sw $t4, 448($t0)
    sw $t4, 512($t0)
    sw $t4, 576($t0)
    sw $t4, 640($t0)
    sw $t4, 704($t0)
    sw $t4, 768($t0)
    sw $t4, 832($t0)
    sw $t4, 896($t0)
    sw $t4, 960($t0)
    jr $ra
borderr:
    sw $t4, 36($t0)               # paint the unit for right border
    sw $t4, 100($t0)
    sw $t4, 164($t0)
    sw $t4, 228($t0)
    sw $t4, 292($t0)
    sw $t4, 356($t0)
    sw $t4, 420($t0)
    sw $t4, 484($t0)
    sw $t4, 548($t0)
    sw $t4, 612($t0)
    sw $t4, 676($t0)
    sw $t4, 740($t0)
    sw $t4, 804($t0)
    sw $t4, 868($t0)
    sw $t4, 932($t0)
    sw $t4, 996($t0)
    sw $t4, 1060($t0)
    jr $ra
borderb:
    sw $t4, 964($t0)           # paint the unit for bottom border
    sw $t4, 968($t0)
    sw $t4, 972($t0)
    sw $t4, 976($t0)
    sw $t4, 980($t0)
    sw $t4, 984($t0)
    sw $t4, 988($t0)
    sw $t4, 992($t0)
    jr $ra
    
# --------- loadtetshape - load the tetromino shape into current tetromino ----------
loadtetshape:
    add $t4, $t8, $s0         # currentvarX + i
    add $t5, $t1, $s0         # currentvarY + i
    add $t3, $t9, $s0         # tetrominoX + i
    add $t6, $t2, $s0         # tetrominoY + i


    lw $s4, 0($t3) # load tetromino x
    lw $s5, 0($t6) # load tetromino y 
    
    sw $s4, 0($t4) # currentvarX=tetrominox
    sw $s5, 0($t5) # currentvarY=tetrominoy

    addi $s0, $s0, 4 # increment by 4 
    bne $s0, $s1, loadtetshape# if counter does not equal # of tetrominos, keep looking
    jr $ra

# --------- address - return address of function ----------
address:
    mul $t7, $t8, 16        # y * WIDTH
    add $t7, $t7, $t9        # + x
    sll $t7, $t7, 2          # * 4
    add $t7, $t7, $t0        # + base address
    jr $ra

# --------- drawcurrb - draw tetromino on console ----------
drawcurrb:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
loop_draw:
    add $t4, $t1, $t6         # $t4 = currentvarY + i
    add $t5, $t2, $t6         # $t5 = currentvarX + i

    lw $t8, 0($t4)            # $t8 = Y[i]  (row)
    lw $t9, 0($t5)            # $t9 = X[i]  (col)

    jal address
    
    sw $s5, 0($t7)            # store color
    addi $t6, $t6, 4          # increment 
    blt $t6, $s1, loop_draw   # if counter does not equal # of tetrominos, keep looking
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
# ----- Transfer current array into collision ------
collisionarrmake:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    add $t4, $zero, $zero 
    add $t5, $zero, $zero 
    add $t3, $zero, $zero 
    add $s0, $zero, $zero              # $s0 = loop index
    add $s1, $zero, 16                 # 4 words = 16 bytes

    la $t8, collisioncX                # destination X array
    la $t1, collisioncY                # destination Y array
    la $t9, currentvarX                # source X array
    la $t2, currentvarY                # source Y array
    jal loadtetshape                   # copy itetromino to currentvar

# ---- test movement in collision array ------
collisionmovetest:
    li   $t0, 0          # loop index i = 0
    li   $t3, 16         # loop end (4 words = 16 bytes)
    la   $t2, collisioncX  # default to X array
    la   $t1, collisioncY  # default to Y array
    beq $s3, 0x77, Wt     # Check if the key w was pressed
    beq $s3, 0x61, At     # Check if the key a was pressed
    beq $s3, 0x73, St     # Check if the key s was pressed
    beq $s3, 0x64, Dt     # Check if the key d was pressed
# make movement in collision array
Wt: 
 jal respond_to_W
 j gobackg
At: 
 jal respond_to_A
 j gobackg
St: 
 jal respond_to_S
 j gobackg
Dt: 
 jal respond_to_D
 gobackg:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
# ----- check if collision array movement is valid ------
 checkvalidmove:
     la   $t2, collisioncX  # default to X array
     la   $t1, collisioncY  # default to Y array
     addi $s0, $zero, 0 # reset count of $s0 to loop
     addi $s7, $zero, 0 # reset count of $s7 to check validity
     addi $a1, $zero, 16 # end loop
     addi $sp, $sp, -4
     sw $ra, 0($sp)
 checkvalidmoveloop:
    add $t9, $t1 , $s0 # get address of collisionY
    add $t5, $t2 , $s0 # get address of collisionX
    lw $t8, 0($t9)     # get y value
    lw $t9, 0($t5)     # get x value
    # check if points are in current array, if so colour don't matter + valid
    addi $s1, $zero, 0 # use as indicator if point in array
    addi $s5, $zero, 16     # max limit to search
    addi $a0, $zero, 0 # set index to 0 
    la $t3, currentvarY   # store address of currentvarY
    la $t4, currentvarX   # store address of currentvarX
    jal checkincurr 
    bne $s1, $zero, checkvothers # if it is a point in currentvar, skip checking rest
    # check if colours are gridgray and black, if not, not valid 
    lw $t0, ADDR_DSPL  # load base keyboard in case
    jal address        # get address of block
    lw $t3, 0($t7)     # get colour of current block
    lw $t4, gridgray       # load gridgray 
    beq $t3, $t4, checkvothers # if it is gridgray, it is valid, check other blocks
    lw $t4, black       # load black from border
    beq $t3, $t4, checkvothers # if it is gridgray, it is valid, check other block
    add $s7, $s7, 1 # if it is not the grid colours, invalid 
checkvothers:
    addi $s0, $s0, 4          # increment 
    bne $s0, $a1, checkvalidmoveloop   # if counter does not equal # of tetrominos, keep looking
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#---- check if collision occurred ----------
collisioncheck:
     la   $t2, collisioncX  # default to X array
     la   $t1, collisioncY  # default to Y array
     addi $s0, $zero, 0 # reset count of $s0 to loop
     addi $s7, $zero, 0 # reset count of $s7 to check validity
     addi $a1, $zero, 16 # end loop
     addi $sp, $sp, -4
     sw $ra, 0($sp)
collisioncheckloop:
    add $t6, $t1 , $s0 # get address of collisionY
    add $t5, $t2 , $s0 # get address of collisionX
    lw $t8, 0($t6)     # get y value
    lw $t9, 0($t5)     # get x value
    
    # add y+1 to go below 
    addi $t8, $t8, 1 # increase y by 1

    # check if points are in current array, if so colour don't matter -> not collision
    addi $s1, $zero, 0 # use as indicator if point in array
    addi $s5, $zero, 16     # max limit to search
    addi $a0, $zero, 0 # set index to 0 
    la $t3, currentvarY   # store address of currentvarY
    la $t4, currentvarX   # store address of currentvarX
    jal checkincurr 
    bne $s1, $zero, collsioncheckloopc # if it is a point in currentvar, skip checking 
    lw $t0, ADDR_DSPL  # load base keyboard in case
    jal address # get address
    lw $t3, 0($t7)     # get colour of current block
    lw $t4, gridgray       # load gridgray 
    beq $t3, $t4, collsioncheckloopc # if it is gridgray, no collision
    lw $t4, black       # load black
    beq $t3, $t4, collsioncheckloopc# if it is black, no collision
    addi $s7, $s7, 1 # if it is not the grid colours, valid for collision
collsioncheckloopc:
    addi $s0, $s0, 4          # increment 
    bne $s0, $a1, collisioncheckloop   # if counter does not equal # of tetrominos, keep looking
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
#----- check if points in current array ---------
checkincurr: 
    add $t0, $t3, $a0 # get address of currentvarY
    add $t5, $t4, $a0 # get address of currentvarX
    lw $t6, 0($t0) # get currentvarY Y[i]
    lw $t7, 0($t5) # get currentvarX X[i]
    # check if x and y are exact same -> same point 
    bne $t6, $t8, checkincurrloop
    bne $t7, $t9, checkincurrloop
    addi $s1, $s1, 1 # add 1 to $s1 to indicate found same point
checkincurrloop:
    addi $a0, $a0, 4          # increment 
    blt $a0, $s5, checkincurr   # if counter does not equal # of tetrominos, keep looking
    jr $ra

# --- Update memory length when collision occurs ------
updatememlength: 
    lw $t5, memlength # get memlength
    addi $t5, $t5, 1 # update it by amount added to memory
    sw $t5, memlength # store it back
    jr $ra
# --- Update memory when collision occurs ------
addmemory:
    la $a0, memoryY       # load memory and collision arrays 
    la $a1, memoryX
    la $t4, collisioncY
    la $t6, collisioncX

    lw $s5, memlength
    li $t0, 16
    mult $s5, $t0
    mflo $s5              # byte offset into memory arrays for memory length

    addi $s1, $zero, 16   # loop over 4 values
    li $s0, 0             # index into currentvarX/Y

addmemoryloop:
    add $t9, $a0, $s5     # base of memoryY + offset for new block
    add $t5, $a1, $s5     # base of memoryX + offset for new block
    add $t3, $t4, $s0     # currentvarY + i
    add $t7, $t6, $s0     # currentvarX + i

    lw $t1, 0($t3)        # get values for currentvarX and currentvarY
    lw $t2, 0($t7)

    sw $t1, 0($t9)        # store into memory
    sw $t2, 0($t5)

    addi $s0, $s0, 4
    addi $s5, $s5, 4      # advance write pointer only
    bne $s0, $s1, addmemoryloop
    jr $ra

#---- Check if any rows needs to be cleared out -------
checkcrow:
    add $t6, $zero, 0 # count if there are 0 gridgrays/black
    addi $t9, $zero, 1 #initialize x
    addi $t1, $zero, 9 # to end row checking
    addi $sp, $sp, -4 # save $ra
    sw $ra, 0($sp)
checkcrowloop:
    # check if any row has 0 gridgray or black
    jal address 
    lw $t3, 0($t7) # get the colour
    lw $t4, gridgray # load gridgray
    beq $t3, $t4, rowgray
    lw $t4, black # load black 
    beq $t3, $t4, rowgray 
checkcrowloopupdate:
    add $t9, $t9, 1 # increment x by 1 
    blt $t9, $t1, checkcrowloop # continue loop if not done row (if less than 9) 
    lw $ra, 0($sp) # return $t6
    addi $sp, $sp, 4
    jr $ra
rowgray:
    add $t6, $t6, 1 # increment if there is gridgray or black seen
    j checkcrowloopupdate 
    
#------ Clear completed row + update score -------
clearrow:
    addi $sp, $sp, -4 # to save return result
    sw   $ra, 0($sp)

    addi $t9, $zero, 0       # initial x
    addi $t5, $zero, 9       # max row width
    lw   $t0, ADDR_DSPL  # base display address
    
    andi $t1, $t8, 1     # check if row is odd (1) or even (0)
    beq  $t1, $zero, clear_even # if it is 0, go to clear even
    
# if not go to odd
clear_odd:
    lw   $t4, orange   # load color to paint
    jal  oddrow          # paint oddrow pattern with gridgray
    lw   $t4, yellow
    jal  evenrow         # paint evenrow pattern with black
    lw $t4 gray
    jal borderl
    
    li $v0, 32
    li $a0, 1000 # Wait one second (1000 milliseconds)
    syscall
    
    lw   $t4, yellow   # load color to paint
    jal  oddrow          # paint oddrow pattern with gridgray
    lw   $t4, orange
    jal  evenrow         # paint evenrow pattern with black
    lw $t4 gray
    jal borderl
    
    li $v0, 32
    li $a0, 1000 # Wait one second (1000 milliseconds)
    syscall
    
    lw   $t4, orange   # load color to paint
    jal  oddrow          # paint oddrow pattern with gridgray
    lw   $t4, yellow
    jal  evenrow         # paint evenrow pattern with black
    lw $t4, gray
    jal borderl

    j clear_finish
clear_even:
    lw   $t4, yellow      # load color to paint
    jal  oddrow         # paint evenrow pattern with black
    lw   $t4, orange   # paint oddrow pattern with gridgray
    jal  evenrow
    lw $t4 gray
    jal borderl
    
    li $v0, 32
    li $a0, 1000 # Wait one second (1000 milliseconds)
    syscall
    
    lw   $t4, orange      # load color to paint
    jal  oddrow         # paint evenrow pattern with black
    lw   $t4, yellow   # paint oddrow pattern with gridgray
    jal  evenrow
    lw $t4 gray
    jal borderl
    
    li $v0, 32
    li $a0, 1000 # Wait one second (1000 milliseconds)
    syscall
    
    lw   $t4, yellow      # load color to paint
    jal  oddrow         # paint evenrow pattern with black
    lw   $t4, orange   # paint oddrow pattern with gridgray
    jal  evenrow
    lw $t4 gray
    jal borderl
clear_finish:
    lw $s2, score 
    addi $s2, $s2, 1    # add score
    sw $s2, score
    lw $t4 gray
    jal borderl
    lw   $ra, 0($sp)     # return 
    addi $sp, $sp, 4
    jr   $ra
# ---- If the player loses by not clearing enough rows ------
endgame:
    # set $s5 to total memory byte length
    lw $s5, memlength
    li $t0, 16
    mult $s5, $t0
    mflo $s5 

    # Base addresses of memory arrays
    la $t4, memoryY
    la $t6, memoryX

    addi $s0, $zero, 0 # memory index
endgameloop:
    add $t3, $t4, $s0 # memoryY address
    add $t5, $t6, $s0 # memoryX address
    lw $t1, 0($t3)    # get y value

    ble $t1, $zero, end # if at last row, end game
    addi $s0, $s0, 4
    blt $s0, $s5, endgameloop
    jr $ra
end:
    jal redrawmemory
	li $v0, 10                      # Quit gracefully
	syscall

# ---- Clear memory out of erased row by shifting ------
clearmemory:
    # set $s5 to total memory byte length
    lw $s5, memlength
    li $t0, 16
    mult $s5, $t0
    mflo $s5 

    # Base addresses of memory arrays
    la $t4, memoryY
    la $t6, memoryX

    addi $s0, $zero, 0 # memory index
clearmemoryloop:
    add $t3, $t4, $s0 # memoryY address
    add $t5, $t6, $s0 # memoryX address
    lw $t1, 0($t3)    # get y value
    blt $t1, $t8, clearout # if matches or less then row to clear
    beq $t1, $t8, clearout2 # if this is the row to be cleared, put all the way away
clearmloop:
    addi $s0, $s0, 4
    blt $s0, $s5, clearmemoryloop
    jr $ra
clearout2:
    addi $t1, $zero, 15 # make y become 15
    sw $t1, 0($t3)
    j clearmloop
clearout:
    addi $t1, $t1, 1 # add 1 to y to move it down
    sw $t1, 0($t3) # load it back to change y 
    j clearmloop

#----- randomize shape - make tetromino different -------
randomizeshape:
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall        # $a0 = random number 0-6

    # Directly jump to color
    beq $zero, $a0, set_i # if 0 make itetromino 
    addi $t1, $zero, 1 # make $t1 1 
    beq $t1, $a0, set_s # if 1 make stetromino
    addi $t1, $t1, 1  # make $t1 2
    beq $t1, $a0, set_z # if 2 make ztetromino
    addi $t1, $t1, 1  # make $t1 3
    beq $t1, $a0, set_o # if 3 make otetromino
    addi $t1, $t1, 1  # make $t1 4
    beq $t1, $a0, set_l # if 4 make ltetromino
    addi $t1, $t1, 1  # make $t1 5
    beq $t1, $a0, set_j # if 5 make jtetromino
    addi $t1, $t1, 1  # make $t1 6
    beq $t1, $a0, set_t # if 6 make ttetromino

    j shapeend

set_i:
    la $t9, itetrominoX               # source X array
    la $t2, itetrominoY               # source Y 
    j shapeend
set_s:
    la $t9, stetrominoX               # source X array
    la $t2, stetrominoY               # source Y 
    j shapeend
set_z:
    la $t9, ztetrominoX               # source X array
    la $t2, ztetrominoY               # source Y 
    j shapeend
set_o:
    la $t9, otetrominoX               # source X array
    la $t2, otetrominoY               # source Y 
    j shapeend
set_l:
    la $t9, ltetrominoX               # source X array
    la $t2, ltetrominoY               # source Y 
    j shapeend
set_j:
    la $t9, jtetrominoX               # source X array
    la $t2, jtetrominoY               # source Y 
    j shapeend
set_t:
    la $t9, ttetrominoX               # source X array
    la $t2, ttetrominoY               # source Y 

shapeend:
    jr $ra

#----- randomize start - make tetromino start at a random location ------
randomizestart:
    add $t6, $zero, $zero     # reset loop index
    li $v0, 42                # syscall: random number
    li $a0, 0
    li $a1, 6                 # max number to add
    syscall 
    addi $a0, $a0, 1          # shift into range 1–9

randomizesloop:
    add $t4, $t2, $t6         # currentvarX + i
    lw  $t9, 0($t4)           # X[i]
    add $t9, $t9, $a0         # X[i] += rand
    sw  $t9, 0($t4)           # store back

    addi $t6, $t6, 4          # next word
    bne  $t6, $s1, randomizesloop
    jr $ra

# --------- newblock - to load new block ----------
newblock:
    # ---- Setup for loading shape ----

    jal randomizeshape 

    add $t4, $zero, $zero 
    add $t5, $zero, $zero 
    add $t3, $zero, $zero 
    add $s0, $zero, $zero              # $s0 = loop index
    add $s1, $zero, 16                 # 4 words = 16 bytes

    la $t8, currentvarX                # destination X array
    la $t1, currentvarY                # destination Y array
    jal loadtetshape                   # copy itetromino to currentvar
    la $t2, currentvarX    # target for randomizing
    la $t1, currentvarY    # stays unchanged

    jal randomizestart                # randomize X values of currentvarX

    # ---- Setup for drawing shape ----
    add $t6, $zero, $zero              # draw loop index

    la $t1, currentvarY                # destination Y array
    la $t8, currentvarX                # destination X array


    add $s1, $zero, 16                 # loop count
    
    
    lw $s5, green              # color value
    lw $t5, WIDTH                      # WIDTH = 10
    lw $t0, ADDR_DSPL                  # base display address
    add $t7, $t0, $zero

    jal drawcurrb
    addi $s7, $zero, 0          # reset if block can move counter
    li $v0, 32                  # show block briefly
    li $a0, 700
    syscall

game_loop:
    beq $s7, 2, newblock # add new block
gamestart:
    # 1a. Check if key has been pressed
    addi $s6, $zero, 0 # reset 
    lw $t0, ADDR_KBRD               # $t0 = base address for keyboard
    lw $s3, 0($t0)                  # Load word from keyboard
    bne $s3, 1, autofall          # If first word not 1, key is not pressed
    # 1b. Check which key has been pressed
    lw $s3, 4($t0)                  # Load 2nd word from keyboard
    beq $s3, 0x71, respond_to_Q     # Check if the key q was pressed

    # 2a. Check for collisions
    jal collisionarrmake # make collision array + apply movement
checkvalidity:
    jal checkvalidmove # check if keyboard input is valid
    bne $s7, $zero, redrawc # if there are things blocking tetromino do not change position 
    # 3. Run collision detection based on key input
    jal collisioncheck # check if collision occurred
    beq $s7, $zero, gamecollisions # for no collision 
    addi $s7, $zero, 3 # update it to 3 for collision
    # 2b. Update locations (paddle, ball)
gamecollisions:
    li   $t0, 0          # loop index i = 0
    li   $t3, 16         # loop end (4 words = 16 bytes)
    la   $t2, currentvarX  # default to X array
    la   $t1, currentvarY  # default to Y array
    addi $s4, $s4, 0 # set rotation indicator as 0 
	beq $s3, 0x71, respond_to_Q     # Check if the key q was pressed
    beq $s3, 0x77, W     # Check if the key w was pressed
    beq $s3, 0x61, A     # Check if the key a was pressed
    beq $s3, 0x73, S     # Check if the key s was pressed
    beq $s3, 0x64, D     # Check if the key d was pressed
draw:
    jal redraw
    jal redrawmemory
	# 4. Sleep
sleep:
    li $v0, 32
    li $a0, 30 # Wait one second (1000 milliseconds)
    syscall

    #5. Go back to 1
    addi $s0, $s0, 8 # $s1 = $s1++
    b game_loop

	# 3. Draw the screen
redrawc:
    jal redraw
    jal redrawmemory
    j sleep
redraw:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # initialize grid 
    jal initialize 

    # Skip drawing current block if collision occurred
    li $t1, 3              # $t1 = 3
    beq $s7, $t1, skip_draw_current

    # call regular draw for current block
    add $t6, $zero, $zero              # draw loop index
    la $t2, currentvarX                # use updated X values
    la $t1, currentvarY                # use same Y values
    add $s1, $zero, 16                 # loop count
    lw $s5, green                      # color value
    lw $t5, WIDTH                     # WIDTH = 10
    lw $t0, ADDR_DSPL                 # base display address
    addi $t7, $t0, 0
    jal drawcurrb

skip_draw_current:
    li $t1, 3                         # reset $t1 = 3
    beq $s7, $t1, collisionupdate     # go do collision commands if there is one
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
redrawmemory:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    # redraw memory
    li $t8, 0        # reset y
    li $t9, 0        # reset x 
    addi $t6, $zero, 0              # draw loop index

    la $t2, memoryX                # use updated X values
    la $t1, memoryY                # use same Y values

    # edit loop count based on memory length x 4 
    lw $s1, memlength
    mul $s1, $s1, 16 

    lw $s5, green                        # color value (temp)
    lw $t5, WIDTH                      # WIDTH = 10
    lw $t0, ADDR_DSPL                  # base display address
    add $t7, $t0, $zero
    jal drawcurrb
    # border of gray
    lw $t4, gray 
    jal  borderl # to hide red square
    jal borderb # hide shifted memory
    # check if row needs to be cleared
    li $t1, 4              # $t1 = 4
    beq $s6, $t1, checkrow
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
checkrow:
    # initialize x, y to check
    addi $t8, $zero, 0 # initialize y (start checking first row)
checkrowloop:
# add loop
    lw $t1, MAXROWSG # get value for MAXROWSG
    bge $t8, $t1, sleep # end loop when done
    jal checkcrow # check row 
    beq $t6, $zero, clearrowfr # if a row needs to be cleared
    addi $t8, $t8, 1 # increment row/y 
    j checkrowloop  # loop     
clearrowfr:
    jal clearrow                # clear painted row

    li $v0, 32                  # show empty row briefly
    li $a0, 1000
    syscall
    add $s6, $zero, $t8 # save $t8 for when it gets changed by score
    jal initialize
    add $t8, $zero, $s6 # restore $t8
    jal clearmemory             # update Y positions

    jal redrawmemory              # update screen
    j checkrow
    
collisionupdate:
    # if there was collision
    jal addmemory # add collsion block to memory
    jal updatememlength # update memory length to add current block to memory

    
    addi $s7, $zero, 2 # set $s7 to 2 to call for newblock after keyboard input
    jal endgame # check if last block fills up to the rim
    addi $s6, $zero, 4 # set $s6 to 4 to call for checking of clear row 
    jal redrawmemory # skip drawin current block (added to collision), draw memory
    j sleep # end change

# jump to call corresponding keyboard movement -> then go to draw tetromino movement
W:
    jal respond_to_W
    j draw
A:
    jal respond_to_A
    j draw        
S:
    jal respond_to_S
    j draw
D:
    jal respond_to_D
    j draw
    
respond_to_W: 
    lw $s0, 4($t1)      # pivot Y[i]
    lw $t4, 4($t2)      # pivot X[i]
respond_to_Wloop:
    add $t5, $t1, $t0   # currentvarY + i
    add $t6, $t2, $t0   # currentvarX + i
    lw $t8, 0($t5)      # Y[i]
    lw $t9, 0($t6)      # X[i]
    
    sub $t7, $t8, $s0 # to do y - pivotY[i]
    sub $s1, $t9, $t4 # to do x - pivotX[i]
    
    add $t9, $t4, $t7 # to do pivotX[i] + y - pivotY[i]
    sub $t8, $s0, $s1 # to do pivotY[i] + x - pivotX[i]

    # load changes values back 
    sw $t8, 0($t5)     
    sw $t9, 0($t6)
    addi $t0, $t0, 4
    blt $t0, $t3, respond_to_Wloop #
    jr $ra
    
respond_to_A:
    li $t0, 0               # initialize loop index
respond_to_A_loop:
    add $t5, $t2, $t0 # $t5 = currentvarX(A) + i
    lw $t9, 0($t5) # $t9 = currentvarX(A)
    # subtract by 1 to go left
    addi $t9, $t9, -1 
    #store it back
    sw $t9, 0($t5) 
    addi $t0, $t0, 4 # $t0 = $t0++
    bne $t0, $t3, respond_to_A_loop # branch back if $t0<16
    jr $ra
    
respond_to_S:
    li $t0, 0               # initialize loop index
respond_to_S_loop:
    add $t5, $t1, $t0 # $t5 = currentvarY(A) + i
    lw $t9, 0($t5) # $t9 = currentvarY(A)
    # add by 1 to go down
    addi $t9, $t9, 1 
    #store it back
    sw $t9, 0($t5) 
    addi $t0, $t0, 4 # $t0 = $t0++
    blt $t0, $t3, respond_to_S_loop # branch back if $t0<16
    jr $ra

respond_to_D:
    li $t0, 0               # initialize loop index
respond_to_D_loop:
    add $t5, $t2, $t0 # $t5 = currentvarX(A) + i
    lw $t9, 0($t5) # $t9 = currentvarX(A)
    # add by 1 to go right
    addi $t9, $t9, 1 
    #store it back
    sw $t9, 0($t5) 
    addi $t0, $t0, 4 # $t0 = $t0++
    bne $t0, $t3, respond_to_D_loop # branch back if $t0<16
    jr $ra
    
respond_to_Q:
    # put quit screen
	li $v0, 10                      # Quit gracefully
	syscall
    
autofall:
    li   $t0, 0          # loop index i = 0
    li   $t3, 16         # loop end (4 words = 16 bytes)
    la   $t1, currentvarY  # default to Y array
    addi $s4, $s4, 0 # set rotation indicator as 0 
    li $s3, 0x73
    
    jal respond_to_S
    beq $s3, 0x71, respond_to_Q     # Check if the key q was pressed

    
    jal collisionarrmake # make collision array + apply movement
    jal checkvalidmove # check if keyboard input is valid
    bne $s7, $zero, redrawc # if there are things blocking tetromino do not change position 
    # 3. Run collision detection based on key input
    jal collisioncheck # check if collision occurred
 
    #make $s7 = 3 to allow collision 
    beq $s7, $zero, autofallloop # for no collision 
    addi $s7, $zero, 3 # update it to 3 for collision
autofallloop:
    jal redraw       # redraw memory
    jal redrawmemory
    
    lw $s2, score # get score
    
    # based on score, define speed (speed increases as score increases)
    li $t1, 1
    blt $s2, $t1, speed1
    li $t1, 2
    blt $s2, $t1, speed2
    li $t1, 3
    blt $s2, $t1, speed3
    j speed4
speed1:
    li $v0, 32    # define speed by lowering duration of delay (making it faster)
    li $a0, 800       
    syscall
    j gamestart
speed2:
    li $v0, 32
    li $a0, 600       
    syscall
    j gamestart
speed3:
    li $v0, 32
    li $a0, 400       
    syscall
    j gamestart
speed4:
    li $v0, 32
    li $a0, 200       
    syscall
    j gamestart
    
