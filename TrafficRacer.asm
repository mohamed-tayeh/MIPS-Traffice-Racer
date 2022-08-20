######################################################################
# CSCB58 Summer 2022 Project
# University of Toronto, Scarborough
#
# Student Name: Mohamed Tayeh Student Number: 100472246, UTorID: Tayehmoh
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8 
# - Display width in pixels: 256 
# - Display height in pixels: 256 
# - Base Address for Display: 0x10008000
#
# Basic features that were implemented successfully
# - Basic feature A, B and C
#
# Additional features that were implemented successfully
# - Additional feature A, B and C
#
# Link to the video demo
# - https://youtu.be/okZAv7N96oE
#
#
######################################################################

.data
	displayAddress: .space 16384 # middleware display to remove flickering
	bitmapDisplay: .word 0x10008000
	
	# road colors
	whiteStrips: .word 0x00e5e1e4
	orangeStrips: .word 0x00ffc70e
	roadBlack: .word 0x000e0e0e
	
	# car colors
	red: .word 0x00ed1d24
	redWheels: .word 0x00730f12
	orange: .word 0x00ff8026
	orangeWheels: .word 0x007d3f13
	blue: .word 0x003e47cc
	blueWheels: .word 0x001e2264
	green: .word 0x001fe758
	yellow: .word 0x00fff200
	yellowWheels: .word 0x007c7601
	headlights: .word 0x00ffcb0e
	
	# keys
	w: .word 0x00000077
	a: .word 0x00000061	
	s: .word 0x00000073
	d: .word 0x00000064
	q: .word 0x00000071
	
	# lines for debug
	lifeIncrement: .asciiz "Incremented Life: "
	tempPushed: .asciiz "Temp Pushed: "
	tempBeforeDraw: .asciiz "Temp Before Draw: "
	tempAfterDraw: .asciiz "Temp After Draw: "
	lifePrint: .asciiz "lifePrint"
	invinciblePrint: .asciiz "invinciblePrint"
	print: .asciiz "print: "
	before: .asciiz "before: "
	after: .asciiz "after: "
	newline: .asciiz "\n"

.text

##### Notes:
# cols: 0,1,2,3
# rows: -7 - 31
# used rows: -10 - 34 (these are used to know when to generate a new col and color for the car
# $s0: car pos
# $s1: game status of paused 0, start 1, retry 2, userWin 3
# $s2: game speed of 1, 2, 3
# $s6, $s7: obstacle car pos (row, col)
# $s4, $s5: aligned car pos (row, col)
# $k0, $k1: obstacle pos (row, col)
# $s3: curr health
# $t6: score
# $t4, $t5: health pick 
# $a2, $a3: arrow pick up
# $t2: time during invisiblity
# $t3: status of arrow
# $t7: obstacle speed
# $t8: aligned car speed
# $t9: obstacle car speed
# $t1: lvl2 status 

# Plan: 
# 	store all of them in the stack and pop them out after making a fn call
#	store one of them and use that code to store the rest
# Registers for each (need to use the t/a/v registers for it)
#	- $t7, $t8, $t9: speed of obstacle, aligned car, obstacle car (can just impl this naively) 

##### Impl Notes:
# Push to stack just before you call another function. Restore them immediately after
# t0-9, a0-3, v0-1: temp registers
# a0-7, ra: saved registers - callee must restore the values when finishing
# Nested call:
# 	fn: save $ra of main into stack, then args -> restore result, then $ra -> update $ra
#	nested fn: pop args -> do your business -> jr $ra	
# remember to reset the conditions of the game when retrying
# if score is more than 400 then it is level 2 therefore increase the frame rate -> decrease sleep time


##### main program
main:

init: # init location of car
	# init car col
	li $s0, 3
	
	# $s1 is setup at the end
	
	# $s2: game speed: 1, 2, 3
	li $s2, 1 # init 1
	
	# $s3: number of lives: 0, 1, 2, 3
	li $s3, 3
	
	# init opposing blue car
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	
	addi $s7, $a0, 0 # rand col
	li $s6, -39 # init row of the blue car
	
	# init opposing blue car speed
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	add $t9, $a0, $s2 # add 1 so that it is nonzero
	
	# init aligned orange car
	li $v0, 42
	li $a0, 2
	li $a1, 2
	syscall # gets a random number 0-1 inclusive 
	
	addi $s5, $a0, 2 # adds 2 to the random number
	li $s4, 43 # init row of the orange car
	
	# init aligned orange car speed
	li $t8, 4 # init max speed
	
	# init obstacle
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall
	
	addi $k1, $a0, 0
	
# check col of obstacle
checkObstacleSameBlue1:
	bne $k1, $s7, endCheckObstacleSameBlue1
	li $k1, 1
	sub $k1, $k1, $s7
endCheckObstacleSameBlue1:
	li $k0, -29 # init row of obstacle
	
	# init obstacle speed
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	add $t7, $a0, $s2 # add 1 so that it is nonzero
	
	# init score
	li $t6, 0
	
	# init health pickup
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall	
	
	addi $t5, $a0, 0
	
# check col of Health
checkHealthSameBlue1:
	bne $t5, $s7, endCheckHealthSameBlue1
	li $t5, 1
	sub $t5, $t5, $s7
endCheckHealthSameBlue1:	
	li $t4, -63 # init row of health

	# init arrow 
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall

	addi $a3, $a0, 0
# check col of Arrow
checkArrowSameBlue1:
	bne $a3, $s7, endCheckArrowSameBlue1
	li $a3, 1
	sub $a3, $a3, $s7
endCheckArrowSameBlue1:
	li $a2, -183 # init row of arrow
	
	# init invincible status
	li $t3, 0

	# init invincible time
	li $t2, 0

	# init lvl 2 status
	li $t1, 0

	# if this init is from retry go to step 4	
	beq $s1, 2, initFromRetryOrWinOrLvl2
	beq $s1, 3, initFromRetryOrWinOrLvl2
	beq $s1, 4, initFromRetryOrWinOrLvl2
	j initGame
initFromRetryOrWinOrLvl2:
	j step4
initGame:
	# $s1: init game status - pauses
	li $s1, 0 
	
step1:	# Step 1: Check for keyboard input
	# 	a) Update the location of your car accordingly
	#	b) Check for collision events
	
	# detect a key press and calls the corresponding fn
	li $t0, 0xffff0000
	lw $t0, 0($t0)
	beq $t0, 1, ifKeyPress
	j elseKeyPress
ifKeyPress:
	jal pushTemp # push temp
	jal keyPress
	jal popTemp
elseKeyPress:
	# check game status
	beq $s1, 0, pause # if game paused
	beq $s1, 2, retry # if user dead
	beq $s1, 3, userWin # if user won
	beq $s1, 4, lvl2 # if game is lvl2 
	j resume
pause:
	# pause game status
	li $s1, 0
	
	# push temp
	jal pushTemp

	# drawRoad on top of curr game
	jal drawRoad
	
	# refresh temp registers
	jal popTemp
	jal pushTemp
	
	# user 
	# enter invincible status, col, row, color
	addi $sp, $sp, -4 
	sw $t3, 0($sp) # pass invincible status of user
	
	add $t0, $zero, $s0
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, 13 # always here
	addi $sp, $sp, -4
	sw $t1, 0($sp)

	addi $t2, $zero, 0 # always 0
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	
	jal drawCar

	jal drawPause
	jal drawLifes
	
	# to refresh the temp values for the next func call
	jal popTemp
	jal pushTemp
	
	# draw score
	addi $sp, $sp, -4 
	sw $t6, 0($sp)

	jal drawScore
	
	jal paintBitmapDisplay
	 
	# pop temp
	jal popTemp
	
	j step4
retry:
	# makes game status 2
	li $s1, 2
	
	# push temp
	jal pushTemp
	
	# should draw on top of the current game that
	jal drawRoad
	
	# user 
	# enter invincible, col, row, color
	# force the user to not be invincible when retrying
	li $t3, 0
	addi $sp, $sp, -4 
	sw $t3, 0($sp)
	
	add $t0, $zero, $s0
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, 13
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	
	addi $t2, $zero, 0
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	
	jal drawCar
	jal drawRetry
	jal drawLifes

	jal paintBitmapDisplay

	# pop temp
	jal popTemp

	j init
userWin:
	# makes game status 3 - userWin
	li $s1, 3
	
	# push temp
	jal pushTemp
	
	# should draw on top of the current game that
	jal drawRoad
	
	# user 
	# enter invincible, col, row, color
	# force the user to not be invincible when retrying
	li $t3, 0
	addi $sp, $sp, -4 
	sw $t3, 0($sp)
	
	add $t0, $zero, $s0
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, 13
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	
	addi $t2, $zero, 0
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	
	jal drawCar
	jal drawWin
	jal drawLifes

	jal paintBitmapDisplay

	# pop temp
	jal popTemp

	j init
lvl2:
	# pause game status
	li $s1, 4 # not reserved when q is pressed
	li $t1, 1 # reserved when q is pressed
	
	# push temp
	jal pushTemp

	# drawRoad on top of curr game
	jal drawRoad
	
	# refresh temp registers
	jal popTemp
	jal pushTemp
	
	# user 
	# enter invincible status, col, row, color
	addi $sp, $sp, -4 
	sw $t3, 0($sp) # pass invincible status of user
	
	add $t0, $zero, $s0
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, 13 # always here
	addi $sp, $sp, -4
	sw $t1, 0($sp)

	addi $t2, $zero, 0 # always 0
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	
	jal drawCar

	jal drawLvl2
	jal drawLifes
	
	# to refresh the temp values for the next func call
	jal popTemp
	jal pushTemp
	
	# draw score
	addi $sp, $sp, -4 
	sw $t6, 0($sp)

	jal drawScore
	
	jal paintBitmapDisplay
	 
	# pop temp
	jal popTemp
	
	j step4
resume:
	# checking for collision events
	
	# if invincible go straight lifePickups
	beq $t3, 1, userInvincibleBoundsCheck
	j userNotInvincible

userInvincibleBoundsCheck:
	beq $s0, -1, makeUser0
	beq $s0, 4, makeUser3
	j userAndLifePickup
makeUser0:
	li $s0, 0
	j userAndLifePickup
makeUser3:
	li $s0, 3
	j userAndLifePickup
userNotInvincible:
	# car moves to the left or right of screen
	beq $s0, -1, userOutBounds
	beq $s0, 4, userOutBounds
	j userAndBlue
	
userOutBounds:	
	# push 0 into the stack 
	add $t0, $zero, 0
	addi $sp, $sp, -4 
	sw $t0, 0($sp)
	
	j loseLife
userAndBlue: # check if user and blue car overlap
	bne $s0, $s7, userAndOrange
	blt $s6, 5, userAndOrange
	bgt $s6, 20, userAndOrange

	# push 1 into the stack 
	add $t0, $zero, 1
	addi $sp, $sp, -4 
	sw $t0, 0($sp)
	
	j loseLife
userAndOrange: # check if user and orange car overlap
	bne $s0, $s5, userAndObstacle
	bgt $s4, 21, userAndObstacle
	blt $s4, 6, userAndObstacle
	
	# push 2 into the stack 
	add $t0, $zero, 2
	addi $sp, $sp, -4 
	sw $t0, 0($sp)
	
	j loseLife
userAndObstacle: # check if user and obstacle overlap
	bne $s0, $k1, userAndLifePickup
	blt $k0, 8, userAndLifePickup
	bgt $k0, 20, userAndLifePickup
	
	# push 3 into the stack 
	add $t0, $zero, 3
	addi $sp, $sp, -4 
	sw $t0, 0($sp)
	
	j loseLife
userAndLifePickup:
	bne $s0, $t5, userAndArrowPickup # not in the same col, no need to check rows
	blt $t4, 10, userAndArrowPickup # check that the car hit the life
	bgt $t4, 20, userAndArrowPickup

	jal gainLife
userAndArrowPickup:
	bne $s0, $a3, step2 # not in the same col, no need to check rows
	blt $a2, 9, step2 # check that the car hit the life
	bgt $a2, 20, step2	

	jal invincible

step2:	# Step 2: Update the location of the other vehicles and obstacles

	# update row of blue car with the speed of the game
	bgt $s6, 40, opposingCarRespawn
	j opposingCarIncrement
opposingCarRespawn:
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	
	addi $s7, $a0, 0
	li $s6, -39
	
	# init speed
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	
	move $t9, $a0 # add 1 so that it is nonzero
	
	j alignedCarCheck
opposingCarIncrement: # increment by speed of the game
	add $s6, $s6, $t9
	add $s6, $s6, $s2
alignedCarCheck:
	# update row of orange car with the speed of the game
	blt $s4, -40, alignedCarRespawn
	j alignedCarIncrement
alignedCarRespawn:
	li $v0, 42
	li $a0, 2
	li $a1, 2
	syscall
	
	addi $s5, $a0, 2
	li $s4, 43
	
	# init speed
	li $t8, 4
	
	j obstacleCheck
alignedCarIncrement:
	sub $s4, $s4, $t8
	add $s4, $s4, $s2
obstacleCheck:
	# update row of orange car with the speed of the game
	bgt $k0, 40, obstacleRespawn
	j obstacleIncrement
obstacleRespawn:
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall
	
	addi $k1, $a0, 0
	
# check col of Obstacle
checkObstacleSameBlue2:
	bne $k1, $s7, endCheckObstacleSameBlue2
	li $k1, 1
	sub $k1, $k1, $s7
endCheckObstacleSameBlue2:
	li $k0, -29 # init row of obstacle
	
	# init speed
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	
	move $t7, $a0 
	
	j lifePickupCheck
obstacleIncrement:
	beq $t1, 0, lifePickupCheck # only incremented when it's level 2
#	add $k0, $k0, $t7 # constant speed so this was removed but if uncommented the functionality is there
	add $k0, $k0, $s2
	
	# check if obstacle is in the same col as the
	# blue if so switch
	bne $k1, $s7, lifePickupCheck
	bgt $k0, 0, lifePickupCheck
	li $k1, 1
	sub $k1, $k1, $s7

lifePickupCheck:
	# update row of health pickup
	bgt $t4, 40, lifePickupRespawn
	j lifePickupIncrement
lifePickupRespawn:
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall
	
	addi $t5, $a0, 0
# check col of Life
checkLifeSameBlue2:
	bne $t5, $s7, endCheckLifeSameBlue2
	li $t5, 1
	sub $t5, $t5, $s7
endCheckLifeSameBlue2:
	li $t4, -63 # init row of health
	
	j arrowCheck
lifePickupIncrement:
	add $t4, $t4, $s2
	# check if lifePickup is in the same col as the
	# blue if so switch
	bne $t5, $s7, arrowCheck
	bgt $t4, 0, arrowCheck
	li $t5, 1
	sub $t5, $t5, $s7	
arrowCheck:
	# update row of health pickup
	bgt $a2, 40, arrowRespawn
	j arrowIncrement
arrowRespawn:
	li $v0, 42
	li $a0, 0
	li $a1, 4
	syscall
	
	addi $a3, $a0, 0
# check col of Arrow
checkArrowSameBlue2:
	bne $a3, $s7, endCheckArrowSameBlue2
	li $a3, 1
	sub $a3, $a3, $s7
endCheckArrowSameBlue2:
	li $a2, -183 # init row of arrow

	j step3
arrowIncrement:
	add $a2, $a2, $s2
	# check if arrowPick is in the same col as the
	# blue if so switch
	bne $a3, $s7, step3
	bgt $a2, 0, step3
	li $a3, 1
	sub $a3, $a3, $s7
step3:	# Step 3: Redraw the screen
	
	# push temp
	jal pushTemp
	
	# road
	jal drawRoad
								
	# obstacle car blue
	# enter invincible status, col, row, color
	li $t3, 0 # force the obstacle colors not to be invincible
	addi $sp, $sp, -4 
	sw $t3, 0($sp)
	
	add $t0, $zero, $s7
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, $s6
	addi $sp, $sp, -4 
	sw $t1, 0($sp)
	
	addi $t2, $zero, 1
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	
	jal drawCar

	# obstacle car orange
	# enter invincible status, col, row, color
	li $t3, 0 # force the obstacle colors not to be invincible
	addi $sp, $sp, -4 
	sw $t3, 0($sp)
	
	add $t0, $zero, $s5
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, $s4
	addi $sp, $sp, -4 
	sw $t1, 0($sp)
	
	addi $t2, $zero, 2
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	
	jal drawCar
	
	# obstacle mark
	# enter col, row
	add $t0, $zero, $k1
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, $k0
	addi $sp, $sp, -4 
	sw $t1, 0($sp)
	
	jal drawObstacle
	jal drawLifes
	
	# refresh the temp registers for the next fn calls
	jal popTemp
	jal pushTemp
	
	# user car
	# enter invincible status, col, row, color
	addi $sp, $sp, -4 
	sw $t3, 0($sp)
	
	add $t0, $zero, $s0
	addi $sp, $sp, -4 
	sw $t0, 0($sp)

	add $t1, $zero, 13
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	
	addi $t2, $zero, 0
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	
	jal drawCar
	
	# lifePickup: refresh the temp registers
	# after making fn calls since we are about to do
	# another func call
	jal popTemp
	jal pushTemp
	
	# draw the life pickup
	# enter col, row
	addi $sp, $sp, -4 
	sw $t5, 0($sp)
	addi $sp, $sp, -4 
	sw $t4, 0($sp)
	
	jal drawLifePickup
	
	# arrow: refresh the temp registers 
	jal popTemp
	jal pushTemp

	# draw arrow
	# enter col, row
	addi $sp, $sp, -4 
	sw $a3, 0($sp)
	addi $sp, $sp, -4 
	sw $a2, 0($sp)

	jal drawArrow
	
	# score: refresh the temp registers
	# after making a fn call
	jal popTemp
	jal pushTemp
	
	# draw the score
	# enter score
	addi $sp, $sp, -4 
	sw $t6, 0($sp)
	
	jal drawScore
	
	jal paintBitmapDisplay
	
	# pop temp
	# since we are about to check for some values, e.g. score
	# and we assume at the top of the stack that we have the values ready to be pushed
	jal popTemp	
	
step4: # Step 4: 
	# level 1: Sleep for 0.1s = 10 frames/s
	beq $t1, 1, lvl2Refresh 
	li $v0, 32
	li $a0, 100
	syscall
	j conditionalIncrements
lvl2Refresh:
	# level 2: Sleep for 0.075s = 15 frames/s
	li $v0, 32
	li $a0, 75
	syscall
conditionalIncrements: 
	# conditional increments
	beq $s1, 0, step5 # game paused
	beq $s1, 2, step5 # game retry
	beq $s1, 3, step5 # game won
	beq $s1, 4, step5 # game lvl2	
		
	add $t6, $t6, $s2 # increment score by game speed

	# if invincible increment $t2 o.w set to 0
	bne $t3, 1, notInvincible
	bgt $t2, 50, notInvincible # frames (10) * seconds
incrementTimeInvincible:
	addi $t2, $t2, 1
	j checkIfWin
notInvincible:
	li $t2, 0
	li $t3, 0
checkIfWin:
	# if the score is longer than the length of the screen, user wins
	# 800 = 33 * 25 (how much each increment accounts for)	
	blt $t6, 825, checkIfLvl2 #!TODO: CHANGE BACK to 828
	j userWin
checkIfLvl2:
	# only show it when the score is equal to 425 = 16 * 25 + 25	
	blt $t6, 425, step5 #!TODO: CHANGE BACK to 425
	beq $t1, 1, step5

	j lvl2
step5: # Step 5: Go back to step 1
	j step1
	
##### Exit	
exit:	
	li $v0, 10 # terminate the program
	syscall

##### Pushes the temp registers to the stack
pushTemp:
	addi $sp, $sp, -4 
	sw $t1, 0($sp)
	addi $sp, $sp, -4 
	sw $t2, 0($sp)
	addi $sp, $sp, -4 
	sw $t3, 0($sp)
	addi $sp, $sp, -4 
	sw $t4, 0($sp)
	addi $sp, $sp, -4 
	sw $t5, 0($sp)
	addi $sp, $sp, -4 
	sw $t6, 0($sp)
	addi $sp, $sp, -4 
	sw $t7, 0($sp)
	addi $sp, $sp, -4 
	sw $t8, 0($sp)
	addi $sp, $sp, -4 
	sw $t9, 0($sp)
	addi $sp, $sp, -4 
	sw $a2, 0($sp)
	addi $sp, $sp, -4 
	sw $a3, 0($sp)

	jr $ra

##### Pops the temp registers from the stack
popTemp:
	lw $a3, 0($sp)
	addi $sp, $sp, 4
	lw $a2, 0($sp)
	addi $sp, $sp, 4
	lw $t9, 0($sp)
	addi $sp, $sp, 4
	lw $t8, 0($sp)
	addi $sp, $sp, 4
	lw $t7, 0($sp)
	addi $sp, $sp, 4
	lw $t6, 0($sp)
	addi $sp, $sp, 4
	lw $t5, 0($sp)
	addi $sp, $sp, 4
	lw $t4, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t2, 0($sp)
	addi $sp, $sp, 4
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

##### Finds which key is pressed and updates the car location accordingly
keyPress:

	# load all the possible keys: w,a,s,d
	la $t0, w 
	lw $t0, 0($t0)
	
	la $t1, a 
	lw $t1, 0($t1)	
	
	la $t2, s 
	lw $t2, 0($t2)	

	la $t3, d 
	lw $t3, 0($t3)

	la $t4, q
	lw $t4, 0($t4)		
	
	# the address of the mips keyword
	li $t5, 0xffff0000
	lw $t5, 4($t5) # offset 4 for the address for the actual key pressed
	
	# $t5 stores the pressed key
	beq $t5, $t0, wPress
	beq $t5, $t1, aPress
	beq $t5, $t2, sPress
	beq $t5, $t3, dPress
	beq $t5, $t4, qPress
	j endKeyPress
wPress:
	beq $s1, 0, endKeyPress # check if game is paused
	beq $s1, 2, endKeyPress # check if game is retry
	beq $s1, 3, endKeyPress # check if game is won
	beq $s1, 4, endKeyPress # check if game is lvl2
	
	# check if speed is at 3
	beq $s2, 3, endKeyPress
	addi $s2, $s2, 1
	
	j endKeyPress
aPress:
	beq $s1, 0, endKeyPress # check if game is paused
	beq $s1, 2, endKeyPress # check if game is retry
	beq $s1, 3, endKeyPress # check if game is won
	beq $s1, 4, endKeyPress # check if game is lvl2
	
	subi $s0, $s0, 1
	j endKeyPress
sPress:
	beq $s1, 0, endKeyPress # check if game is paused
	beq $s1, 2, endKeyPress # check if game is retry
	beq $s1, 3, endKeyPress # check if game is won
	beq $s1, 4, endKeyPress # check if game is lvl2
	
	# check if speed is at 1
	beq $s2, 1, endKeyPress
	subi $s2, $s2, 1
	
	j endKeyPress
dPress:
	beq $s1, 0, endKeyPress # check if game is paused
	beq $s1, 2, endKeyPress # check if game is retry
	beq $s1, 3, endKeyPress # check if game is won
	beq $s1, 4, endKeyPress # check if game is lvl2
	
	addi $s0, $s0, 1
	j endKeyPress
qPress:
	beq $s1, 0, qPress1
	beq $s1, 2, qPress1
	beq $s1, 3, qPress1 # check if game is won
	beq $s1, 4, qPress1 # check if game is lvl2
	addi $s1, $zero, 0 # flip to 0 if was 1
	j endKeyPress
qPress1:
	addi $s1, $zero, 1 # flip 1 if it was 0 or 2 or 3
endKeyPress:
	jr $ra

##### Makes the user invincible to collisions
invincible:
	li $t3, 1 # makes user status invincible
	li $t2, 0 # resets invincible time
	li $a2, 32
	jr $ra

##### User gains a life when colliding with a health pickup
gainLife:
	# check that the health is less than 3
	blt $s3, 3, addLife
	j addLifeEnd
addLife:
	addi $s3, $s3, 1
addLifeEnd:
	li $t4, 32
	jr $ra

##### User loses a life when colliding with an obj given:
# the obj that it collided with
# 0 - the sides; 1 - blue car; 2 - orange car; 3 - obstacle
loseLife:	
	li $t1, 0
	# make the col of the car 3
	li $s0, 3
	# make the speed go back to init
	li $s2, 1
	
	# pop index 
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	bne $s3, 0, notZeroLife
	jal pushTemp
	jal drawLifes # if life is 0, draw then go to retry
	jal popTemp
zeroLifeCheckSides: # ensure car is within screen if the last move made them go off
	bne $a0, 0, zeroLifeEnd
	blt $s0, 0, zeroLifeLeft
	bgt $s0, 3, zeroLifeRight
zeroLifeLeft:
	li $s0, 3 # used to be 0, now makes the car go back to 3 b/c same start pos
	j zeroLifeEnd
zeroLifeRight:
	li $s0, 3		
zeroLifeEnd:
	j retry
notZeroLife: # if life is not 0, subtract 1 from life and draw
	# user loses a life
	li $t6, 0
	subi $s3,$s3, 1
	jal pushTemp
	jal drawLifes
	jal popTemp
	# we make the obstacle go to row 29	
	# if 0, make car go to the right or left
	# if 1, make $s6 = 29
	# if 2, make $s4 = 29
	# if 3, make $k0 = 29
checkSides:
	bne $a0, 0, checkBlue
	blt $s0, 0, makeCarLeft
	bgt $s0, 3, makeCarRight
makeCarLeft:
	li $s0, 3 # used to be 0, now makes the car go back to 3 b/c same start pos
	
	li $a2, 32 # move arrow pickup
	li $t4, 32 # moves health pickup
	li $s6, 32 # moves blue car to 32
	li $s4, -29 # moves orange car to -29
	li $k0, 32 # moves obstacle car to 32
	
	j checkBlue
makeCarRight:
	li $s0, 3

	li $a2, 32 # move arrow pickup
	li $t4, 32 # moves health pickup
	li $s6, 32 # moves blue car to 29
	li $s4, -29 # moves orange car to 29
	li $k0, 32 # moves obstacle car to 29
	
checkBlue:
	bne $a0, 1, checkOrange
	li $s6, 32 # moves blue car to 29
	
	# move all to 29 since game positions restart
	li $a2, 32 # move arrow pickup
	li $t4, 32 # moves health pickup
	li $s4, -29 # moves orange car to 29
	li $k0, 32 # moves obstacle car to 29
checkOrange:
	bne $a0, 2, checkObstacle
	li $s4, -29 # moves orange car to 29
	
	# move all to 29 since game positions restart
	li $a2, 32 # move arrow pickup
	li $t4, 32 # moves health pickup
	li $s6, 32 # moves blue car to 29
	li $k0, 32 # moves obstacle car to 29
checkObstacle:
	bne $a0, 3, checkEnd
	li $k0, 32 # moves obstacle car to 29
	
	# move all to 29 since game positions restart
	li $a2, 32 # move arrow pickup
	li $t4, 32 # moves health pickup
	li $s4, -29 # moves orange car to 29
	li $s6, 32 # moves blue car to 29
checkEnd:

	j step2

##### Draws the current lives that the user has
drawLifes:
	la $t0, displayAddress # $t0 stores the base address for display
	
	# drawLifesLoop Prep 
	
	# load color
	la $t1, green 
	lw $t1, 0($t1)
	li $t2, 0
	
drawLifesLoop:
	beq $t2, $s3, drawLifesLoopEnd # if $t1 == $s3, we're done, jump to roadLoopEnd
	
	# paint health bar 
	sw $t1, 0($t0)
	
	addi $t0, $t0, 4 # incrememnt address
	addi $t2, $t2, 1 # increment $t3 (i)
 
	j drawLifesLoop # jump back to carLoop
drawLifesLoopEnd:
	jr $ra 

##### Draws the curr score given:
# currScore
drawScore:
	la $t0, displayAddress # $t0 stores the base address for display
	
	addi $t0, $t0, 3968 # increment to the last row since score is bot to top
	
	# curr score in $a0
	lw $a0, 0($sp)
	addi $sp, $sp, 4
		
	# divide score by 25 so that it takes time to win
	li $v0, 25 #!TODO: CHANGE BACK TO 25 
	div $a0, $v0
	mflo $a0
	
	# load color
	la $t1, red 
	lw $t1, 0($t1)
	li $t2, 0
	
drawScoreLoop:
	beq $t2, $a0, drawScoreLoopEnd # if $t2 == $a0, we're done, jump to drawScoreLoopEnd:
	
	# paint the curr score 
	sw $t1, 0($t0) # paint red strip at bottom
	
	addi $t0, $t0, 4 # decrement address
	addi $t2, $t2, 1 # increment $t2 (i)
 
	j drawScoreLoop # jump back to drawScoreLoop
drawScoreLoopEnd:
	jr $ra 

##### Draws a life pickup given:
# col: 0, 1, 2, 3 signifying the lane
# row: 0-31 specifying the pixel row
drawArrow:
	la $t0, displayAddress # $t0 stores the base address for display
	
	# pop row, col 
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	
	# calculate the start pixel by row and col
	# col 0 - 4 * 3 | col 1 - 4 * 11| col 2 - 4 * 20 | col 3 - 4 * 28 | 
	# row 0 - 0 | row 1 - 128 | row 2 - 128 * 2 | row 3 - 128 * 3
	# car start position = base address + row + col
	
	# calculate row in $t1
	addi $t1, $zero, 128
	mult $a0, $t1       # $a0 (row) * 128
	mflo $t1
	
	# calculate col and add to $t1 
	beq $a1, 0, arrowCol0
	beq $a1, 1, arrowCol1
	beq $a1, 2, arrowCol2
	beq $a1, 3, arrowCol3
arrowCol0:
	addi $t1, $t1, 12
	j arrowColFinish
arrowCol1:
	addi $t1, $t1, 44
	j arrowColFinish
arrowCol2: 
	addi $t1, $t1, 80 
	j arrowColFinish
arrowCol3:
	addi $t1, $t1, 112
arrowColFinish:
	# make $t1 point to the base address + row + col
	add $t1, $t0, $t1
	  
	# load color
	la $t2, yellow 
	lw $t2, 0($t2)
	
	# draw it
	sw $t2, 0($t1)
	sw $t2, 256($t1)
	sw $t2, 384($t1)
	sw $t2, 124($t1)
	sw $t2, 132($t1)
	sw $t2, 248($t1)
	sw $t2, 264($t1)	
arrowEnd:
	jr $ra

##### Draws a life pickup given:
# col: 0, 1, 2, 3 signifying the lane
# row: 0-31 specifying the pixel row
drawLifePickup:
	la $t0, displayAddress # $t0 stores the base address for display
	
	# pop row, col 
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	
	# calculate the start pixel by row and col
	# col 0 - 4 * 3 | col 1 - 4 * 11| col 2 - 4 * 20 | col 3 - 4 * 28 | 
	# row 0 - 0 | row 1 - 128 | row 2 - 128 * 2 | row 3 - 128 * 3
	# car start position = base address + row + col
	
	# calculate row in $t1
	addi $t1, $zero, 128
	mult $a0, $t1       # $a0 (row) * 128
	mflo $t1 
	
	# calculate col and add to $t1 
	beq $a1, 0, lifePickupCol0
	beq $a1, 1, lifePickupCol1
	beq $a1, 2, lifePickupCol2
	beq $a1, 3, lifePickupCol3
lifePickupCol0:
	addi $t1, $t1, 12
	j lifePickupColFinish
lifePickupCol1:
	addi $t1, $t1, 44
	j lifePickupColFinish
lifePickupCol2: 
	addi $t1, $t1, 80 
	j lifePickupColFinish
lifePickupCol3:
	addi $t1, $t1, 112
lifePickupColFinish:
	# make $t1 point to the base address + row + col
	add $t1, $t0, $t1
	  
	# load color
	la $t2, green 
	lw $t2, 0($t2)
	
	# draw it
	sw $t2, 0($t1)	
	sw $t2, 124($t1)
	sw $t2, 128($t1)
	sw $t2, 132($t1)
	sw $t2, 256($t1)
lifePickupEnd:
	jr $ra

##### Draws an obstacle given:
# col: 0, 1, 2, 3 signifying the lane
# row: 0-31 specifying the pixel row
drawObstacle:
	la $t0, displayAddress # $t0 stores the base address for display
	
	# pop row, col 
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	
	# calculate the start pixel by row and col
	# col 0 - 4 * 3 | col 1 - 4 * 11| col 2 - 4 * 20 | col 3 - 4 * 28 | 
	# row 0 - 0 | row 1 - 128 | row 2 - 128 * 2 | row 3 - 128 * 3
	# car start position = base address + row + col
	
	# calculate row in $t1
	addi $t1, $zero, 128
	mult $a0, $t1       # $a0 (row) * 128
	mflo $t1 
	
	# calculate col and add to $t1 
	beq $a1, 0, obstacleCol0
	beq $a1, 1, obstacleCol1
	beq $a1, 2, obstacleCol2
	beq $a1, 3, obstacleCol3
obstacleCol0:
	addi $t1, $t1, 12
	j obstacleColFinish
obstacleCol1:
	addi $t1, $t1, 44
	j obstacleColFinish
obstacleCol2: 
	addi $t1, $t1, 80 
	j obstacleColFinish
obstacleCol3:
	addi $t1, $t1, 112
obstacleColFinish:
	# make $t1 point to the base address + row + col
	add $t1, $t0, $t1
	  
	# load color
	la $t2, red 
	lw $t2, 0($t2)
	
	# draw it
	sw $t2, 0($t1)	
	sw $t2, 128($t1)
	sw $t2, 256($t1)
	sw $t2, 512($t1)
obstacleDrawEnd:
	jr $ra

##### Draws a car given:
# col: 0, 1, 2, 3 signifying the lane
# row: 0-31 specifying the pixel row
# color: 0 - red, 1 - blue, 2 - orange
# if color == 0: user car and head lights are at the top; else at the bottom
drawCar:
	la $t0, displayAddress # $t0 stores the base address for display
	
	# pop color, row, col, invincible
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	lw $a2, 0($sp)
	addi $sp, $sp, 4
	lw $a3, 0($sp)
	addi $sp, $sp, 4
			
	# load the car color and wheels color
	beq $a0, 0, carRed
	beq $a0, 1, carBlue
	beq $a0, 2, carOrange
carRed:
	la $t1, red 
	lw $t1, 0($t1)
	
	la $t2, redWheels 
	lw $t2, 0($t2)

	j carInvincible
carBlue:
	la $t1, blue 
	lw $t1, 0($t1)
	
	la $t2, blueWheels 
	lw $t2, 0($t2)
	
	j carInvincible
carOrange:
	la $t1, orange 
	lw $t1, 0($t1)
	
	la $t2, orangeWheels 
	lw $t2, 0($t2)

carInvincible:
	# check if invincible and that
	# it is the user by not the and combination
	bne $a3, 1, carLoopPrep
	bne $a0, 0, carLoopPrep
	
	la $t1, yellow 
	lw $t1, 0($t1)
	
	la $t2, yellowWheels 
	lw $t2, 0($t2)

#Prep carLoop
carLoopPrep:
	# calculate the start pixel by row and col - using any $t3+
	# col 0 - 4 * 1 | col 1 - 4 * 9| col 2 - 4 * 18 | col 3 - 4 * 26 | 
	# row 0 - 0 | row 1 - 128 | row 2 - 128 * 2 | row 3 - 128 * 3
	# car start position = base address + row + col
	
	# calculate row in $t3
	addi $t3, $zero, 128
	mult $a1, $t3       # $a1 (row) * 128
	mflo $t3 
	
	# calculate col and add to $t3
	beq $a2, 0, col0
	beq $a2, 1, col1
	beq $a2, 2, col2
	beq $a2, 3, col3

col0:
	addi $t3, $t3, 4
	j colFinish
col1:
	addi $t3, $t3, 36
	j colFinish
col2: 
	addi $t3, $t3, 72 
	j colFinish
col3:
	addi $t3, $t3, 104
colFinish: 
	# store car start pos in $t4
      	add $t4, $t0, $t3
      	
	# make $t5 point to $t4
      	add $t5, $t0, $t3 # $t5 = curr address
      	add $t6, $zero, $zero # $t6 = 0
	addi $t7, $zero, 8  # $t7 = 8 (height of the car)

# loop over row and make 7 cols red
carLoop:
	beq $t6, $t7, carLoopEnd # if $t6 == $t7, we're done, jump to roadLoopEnd
	
	# paint car 
	sw $t1, 0($t5)
	sw $t1, 4($t5)
	sw $t1, 8($t5)
	sw $t1, 12($t5)
	sw $t1, 16($t5)
	
	addi $t5, $t5, 128 # incrememnt address
	addi $t6, $t6, 1 # increment $t3 (i)
        
	j carLoop # jump back to carLoop
carLoopEnd:
	#add the wheels
	sw $t2, 128($t4)
	sw $t2, 144($t4)
	sw $t2, 768($t4)
	sw $t2, 784($t4)
	
	# add the headlights 
	la $t1, headlights 
	lw $t1, 0($t1)
	
	la $t2, roadBlack 
	lw $t2, 0($t2)
	
	beq $a0, 0, carForwardLightsWindow
	beq $a0, 2, carForwardLightsWindow # for the alongside orange car
carObstacleLightsWindow:
	# lights
	sw $t1, 900($t4)
	sw $t1, 908($t4)
	
	# windows
	sw $t2, 644($t4)
	sw $t2, 648($t4)
	sw $t2, 652($t4)
	
	j drawCarEnd
carForwardLightsWindow:
	# lights
	sw $t1, 4($t4)
	sw $t1, 12($t4)
	
	# windows
	sw $t2, 260($t4)
	sw $t2, 264($t4)
	sw $t2, 268($t4)
drawCarEnd:
	jr $ra

###### Draws the road
drawRoad:
	la $t0, displayAddress # $t0 stores the base address for display
	
	# Draw black portion
	la $t1, roadBlack 
	lw $t1, 0($t1)
      	
      	# Prep roadLoop
      	add $t2, $t0, $zero # store the curr address  
      	add $t3, $zero, $zero # $t3 = 0
	addi $t4, $zero, 1024  # $t4 = 1024 (end cond)
	
roadLoop:
	beq $t3, $t4, roadLoopEnd # if $t3 == $t4, we're done, jump to roadLoopEnd
	sw $t1, 0($t2) # paint road 
	addi $t2, $t2, 4 # incrememnt address
	addi $t3, $t3, 1 # increment $t3 (i)
        
	j roadLoop # jump back to roadLoop
      	
roadLoopEnd:
	
	# white color
	la $a0, whiteStrips
	lw $a0, 0($a0)

	# orange color
	la $a1, orangeStrips 
	lw $a1, 0($a1)

	# Prep strips loop
      	add $t2, $t0, $zero # store the curr address  
      	add $t3, $zero, $zero # $t3 = 0
	addi $t4, $zero, 32  # $t4 = 32 (end cond)
	
stripsLoop:
	beq $t3, $t4, stripsLoopEnd # if $t3 == $t4, we're done, jump to roadLoopEnd

	sw $a0, 28($t2) # paint white strip 1
	sw $a1, 60($t2) # paint orange strip 1
	sw $a1, 64($t2) # paint orange strip 2
	sw $a0, 96($t2) # paint white strip 2

	addi $t2, $t2, 128 # incrememnt address
	addi $t3, $t3, 1 # increment $t3 (i) by a row 
        
	j stripsLoop # jump back to roadLoop
	
stripsLoopEnd:
	
	# Draw black portion
	la $a0, roadBlack 
	lw $a0, 0($a0)
	
	# Prep black strips loop
      	addi $t2, $t0, 384 # store the start address of the black strips 
      	add $t3, $zero, 3  # $t3 = 3 (starting from the 4th row)
	addi $t4, $zero, 32  # $t4 = 32 (end cond)
	
blackStripsLoop:
	bgt $t3, $t4, blackStripsLoopEnd # if $t3 > $t4, we're done, jump to blackStripsLoopEnd

	sw $a0, 28($t2) # paint black strip 1 row 1
	sw $a0, 96($t2) # paint white strip 2 row 1
	
	sw $a0, 156($t2) # paint white strip 1 row 2
	sw $a0, 224($t2) # paint white strip 2 row 2

	# problem with increment

	addi $t2, $t2, 640 # incrememnt address by 5 rows (since we are drawing 2 rows at a time)
	addi $t3, $t3, 5 # increment $t3 (i) by 5 rows
        
	j blackStripsLoop # jump back to roadLoop
	
blackStripsLoopEnd:
	jr $ra

##### Paints everything to $gp from displayAddress
paintBitmapDisplay:
	
	la $t0, displayAddress # $t0 stores the base address for display
	lw $t1, bitmapDisplay # $t1 stores the base address for bitmap display
	
	# Prep paintLoop
      	add $t2, $t0, $zero # store the curr display address 
	add $t3, $t1, $zero # store the curr bitmap address   
	
      	add $t4, $zero, $zero # $t4 = 0
	addi $t5, $zero, 1024  # $t5 = 1024 (end cond)
	
paintLoop:
	beq $t4, $t5, paintLoopEnd # if $t4 == $t5, we're done, jump to paintLoopEnd
	lw $t6, 0($t2)# load what is in the road
	sw $t6, 0($t3) # paint bitmap 
	addi $t2, $t2, 4 # incrememnt display address
	addi $t3, $t3, 4 # incrememnt bitmap address
	addi $t4, $t4, 1 # increment $t4 (i)
        
	j paintLoop # jump back to roadLoop

paintLoopEnd:
	jr $ra

##### Draws the pause word on screen
drawPause:
	la $t0, displayAddress # $t0 stores the base address for display
	
	la $t1, red 
	lw $t1, 0($t1)
	
	# drawing paused on screen
        sw $t1, 924($t0)
        sw $t1, 1052($t0)
        sw $t1, 1180($t0)
        sw $t1, 1308($t0)
        sw $t1, 1436($t0)
        sw $t1, 928($t0) 
        sw $t1, 1184($t0)
        sw $t1, 932($t0) 
        sw $t1, 1060($t0)
        sw $t1, 1188($t0)
        sw $t1, 940($t0) 
        sw $t1, 1068($t0)
        sw $t1, 1196($t0)
        sw $t1, 1324($t0)
        sw $t1, 1452($t0)
        sw $t1, 944($t0) 
        sw $t1, 1200($t0)
        sw $t1, 948($t0)
        sw $t1, 1076($t0)
        sw $t1, 1204($t0)
        sw $t1, 1332($t0)
        sw $t1, 1460($t0)
        sw $t1, 956($t0)
        sw $t1, 1084($t0)
        sw $t1, 1212($t0)
        sw $t1, 1340($t0)
        sw $t1, 1468($t0)
        sw $t1, 1472($t0)
        sw $t1, 964($t0)
        sw $t1, 1092($t0)
        sw $t1, 1220($t0)
        sw $t1, 1348($t0)
        sw $t1, 1476($t0)
        sw $t1, 972($t0)
        sw $t1, 1100($t0)
        sw $t1, 1228($t0)
        sw $t1, 1484($t0)
        sw $t1, 976($t0)
        sw $t1, 1232($t0)
        sw $t1, 1488($t0)
        sw $t1, 980($t0)
        sw $t1, 1236($t0)
        sw $t1, 1364($t0)
        sw $t1, 1492($t0)
        sw $t1, 988($t0)
        sw $t1, 1116($t0)
        sw $t1, 1244($t0)
        sw $t1, 1372($t0)
        sw $t1, 1500($t0)
        sw $t1, 992($t0)
        sw $t1, 1248($t0)
        sw $t1, 1504($t0)
        sw $t1, 996($t0)
        sw $t1, 1252($t0)
        sw $t1, 1508($t0)
	
        sw $t1, 2504($t0)
        sw $t1, 2632($t0)
        sw $t1, 2760($t0)
        sw $t1, 2888($t0)
        sw $t1, 2508($t0)
        sw $t1, 2892($t0)
        sw $t1, 2512($t0)
        sw $t1, 2768($t0)
        sw $t1, 2896($t0)
        sw $t1, 2516($t0)
        sw $t1, 2644($t0)
        sw $t1, 2772($t0)
        sw $t1, 2900($t0)
        sw $t1, 3032($t0)
        sw $t1, 3164($t0)
	
	jr $ra

##### Draws the retry word on screen
drawRetry:
	la $t0, displayAddress # $t0 stores the base address for display
	
	la $t1, red 
	lw $t1, 0($t1)
	
	# drawing retry on screen
        sw $t1, 920($t0)
        sw $t1, 1048($t0)
        sw $t1, 1176($t0)
        sw $t1, 1304($t0)
        sw $t1, 1432($t0)
        sw $t1, 924($t0) 
        sw $t1, 1180($t0)
        sw $t1, 928($t0) 
        sw $t1, 1056($t0)
        sw $t1, 1312($t0)
        sw $t1, 1440($t0)
        sw $t1, 936($t0) 
        sw $t1, 1064($t0)
        sw $t1, 1192($t0)
        sw $t1, 1320($t0)
        sw $t1, 1448($t0)
        sw $t1, 940($t0) 
        sw $t1, 1196($t0)
        sw $t1, 1452($t0)
        sw $t1, 944($t0) 
        sw $t1, 1200($t0)
        sw $t1, 1456($t0)
        sw $t1, 952($t0) 
        sw $t1, 956($t0) 
        sw $t1, 1084($t0)
        sw $t1, 1212($t0)
        sw $t1, 1340($t0)
        sw $t1, 1468($t0)
        sw $t1, 960($t0) 
        sw $t1, 968($t0) 
        sw $t1, 1096($t0)
        sw $t1, 1224($t0)
        sw $t1, 1352($t0)
        sw $t1, 1480($t0)
        sw $t1, 972($t0) 
        sw $t1, 1228($t0)
        sw $t1, 976($t0) 
        sw $t1, 1104($t0)
        sw $t1, 1360($t0)
        sw $t1, 1488($t0)
        sw $t1, 984($t0) 
        sw $t1, 1112($t0)
        sw $t1, 1240($t0)
        sw $t1, 1496($t0)
        sw $t1, 1244($t0)
        sw $t1, 1500($t0)
        sw $t1, 992($t0) 
        sw $t1, 1120($t0)
        sw $t1, 1248($t0)
        sw $t1, 1376($t0)
        sw $t1, 1504($t0)
        
        sw $t1, 2504($t0)
        sw $t1, 2632($t0)
        sw $t1, 2760($t0)
        sw $t1, 2888($t0)
        sw $t1, 2508($t0)
        sw $t1, 2892($t0)
        sw $t1, 2512($t0)
        sw $t1, 2768($t0)
        sw $t1, 2896($t0)
        sw $t1, 2516($t0)
        sw $t1, 2644($t0)
        sw $t1, 2772($t0)
        sw $t1, 2900($t0)
        sw $t1, 3032($t0)
        sw $t1, 3164($t0)
	
	jr $ra
	
##### Draws the win word on screen
drawWin:
	la $t0, displayAddress # $t0 stores the base address for display
	
	la $t1, red 
	lw $t1, 0($t1)
	
	# drawing win on screen
        sw $t1, 924($t0)
        sw $t1, 1052($t0)  
        sw $t1, 1180($t0)  
        sw $t1, 1308($t0)  
        sw $t1, 1436($t0)  
        sw $t1, 1440($t0)  
        sw $t1, 1188($t0)  
        sw $t1, 1316($t0)  
        sw $t1, 1444($t0)  
        sw $t1, 1448($t0)  
        sw $t1, 940($t0)   
        sw $t1, 1068($t0)  
        sw $t1, 1196($t0)  
        sw $t1, 1324($t0)  
        sw $t1, 1452($t0)  
        sw $t1, 952($t0)   
        sw $t1, 1464($t0)  
        sw $t1, 956($t0)   
        sw $t1, 1084($t0)  
        sw $t1, 1212($t0)  
        sw $t1, 1340($t0)  
        sw $t1, 1468($t0)  
        sw $t1, 960($t0)   
        sw $t1, 1088($t0)  
        sw $t1, 1216($t0)  
        sw $t1, 1344($t0)  
        sw $t1, 1472($t0)  
        sw $t1, 964($t0)   
        sw $t1, 1476($t0)  
        sw $t1, 976($t0)   
        sw $t1, 1104($t0)  
        sw $t1, 1232($t0)  
        sw $t1, 1360($t0)  
        sw $t1, 1488($t0)  
        sw $t1, 1108($t0)  
        sw $t1, 1240($t0)  
        sw $t1, 1372($t0)  
        sw $t1, 992($t0)   
        sw $t1, 1120($t0)  
        sw $t1, 1248($t0)  
        sw $t1, 1376($t0)  
        sw $t1, 1504($t0)

        sw $t1, 2504($t0)
        sw $t1, 2632($t0)
        sw $t1, 2760($t0)
        sw $t1, 2888($t0)
        sw $t1, 2508($t0)
        sw $t1, 2892($t0)
        sw $t1, 2512($t0)
        sw $t1, 2768($t0)
        sw $t1, 2896($t0)
        sw $t1, 2516($t0)
        sw $t1, 2644($t0)
        sw $t1, 2772($t0)
        sw $t1, 2900($t0)
        sw $t1, 3032($t0)
        sw $t1, 3164($t0)
       
	jr $ra

##### Draws the win lvl2 on screen
drawLvl2:
	la $t0, displayAddress # $t0 stores the base address for display
	
	la $t1, red 
	lw $t1, 0($t1)
	
	# drawing lvl2 on screen
        sw $t1, 928($t0)
        sw $t1, 1056($t0)  
        sw $t1, 1184($t0)  
        sw $t1, 1312($t0)  
        sw $t1, 1440($t0)  
        sw $t1, 1444($t0)  
        sw $t1, 1192($t0)  
        sw $t1, 1324($t0)  
        sw $t1, 1456($t0)  
        sw $t1, 1332($t0)  
        sw $t1, 1208($t0)  
        sw $t1, 960($t0)   
        sw $t1, 1088($t0)  
        sw $t1, 1216($t0)  
        sw $t1, 1344($t0)  
        sw $t1, 1472($t0)  
        sw $t1, 1476($t0)  
        sw $t1, 976($t0)   
        sw $t1, 1232($t0)  
        sw $t1, 1360($t0)  
        sw $t1, 1488($t0)  
        sw $t1, 980($t0)   
        sw $t1, 1236($t0)  
        sw $t1, 1492($t0)  
        sw $t1, 984($t0)   
        sw $t1, 1240($t0)  
        sw $t1, 1496($t0)  
        sw $t1, 988($t0)   
        sw $t1, 1116($t0)  
        sw $t1, 1244($t0)  
        sw $t1, 1500($t0)
        
        sw $t1, 2504($t0)
        sw $t1, 2632($t0)
        sw $t1, 2760($t0)
        sw $t1, 2888($t0)
        sw $t1, 2508($t0)
        sw $t1, 2892($t0)
        sw $t1, 2512($t0)
        sw $t1, 2768($t0)
        sw $t1, 2896($t0)
        sw $t1, 2516($t0)
        sw $t1, 2644($t0)
        sw $t1, 2772($t0)
        sw $t1, 2900($t0)
        sw $t1, 3032($t0)
        sw $t1, 3164($t0)
        
	jr $ra


