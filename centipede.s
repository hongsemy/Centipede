.data
	displayAddress: .word 0x10008000
	blasterLocation: .word 1006
	centipedLocation: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
	centipedDirection: .word 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
	mushroomLocation: .word 100, 240, 302, 372, 466, 536, 654, 784, 844, 942
	mushroomLocationLeft: .word 101, 241, 303, 373, 943
	mushroomLocationRight: .word 465, 535, 653, 783, 843
	rightWall: .word 31, 63, 95, 127, 159, 191, 223, 255, 287, 319, 351, 383, 415, 447, 479, 511, 543, 575, 607, 639, 671, 703, 735, 767, 799, 831, 863, 895, 927, 959, 991, 1023
	leftWall: .word 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 480, 512, 544, 576, 608, 640, 672, 704, 736, 768, 800, 832, 864, 896, 928, 960, 992
	topWall: .word 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
.text
initialize_centiped_head_location:
	lw $s1, displayAddress 
	addi $s2, $zero, 1 # represents the direction of centiped (1: right, 0: left)
	addi $s3, $zero, 0 # represents how many shots did hit the centiped

disp_mushrooms:
	addi $a3, $zero, 10
	la $s0, mushroomLocation # load the address of nushroomLocation to $s0 (saved for the rest of the program)
mush_loop:
	lw $t1, 0($s0)	# load a word from the mushroomArray into $t1
	lw $t2, displayAddress # $t2 stores the base address for display
	li $t3, 0x00ff00	# $t3 stores the green colour code
	
	sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset * 4)
	add $t4, $t2, $t4 	# $t4 is the address of the location
	sw $t3, 0($t4)
	
	addi $s0, $s0, 4
	addi $a3, $a3, -1
	bne $a3, $zero, mush_loop
	
	addi $s0, $s0, -40
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4

Loop:
	jal disp_centiped
	jal delay
	jal check_keystroke
	jal centiped_dead
	
	j Loop
	
Exit:
	li $v0, 10		# terminate the program gracefully
	syscall
	
# function to display centiped
disp_centiped:
	# move stack pointer and push ra onto it
	add $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, displayAddress
	 
	addi $a3, $zero, 10		# load a3 with the loop count (10)
	la $a1, centipedLocation	# load the address of the array
	la $a2, centipedDirection
	bne $s1, $t2, update_centiped
	
arr_loop:	# iterate over the loops elements to draw each body in the centiped
	lw $t1, 0($a1)		# load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		# load a word from the centipedDirection array into $t5
	#####
	lw $t2, displayAddress 	# $t2 stores the base address for display
	li $t3, 0xff0000	# $t3 stores the red colour code
	
	sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset * 4)
	add $t4, $t2, $t4	# $t4 is the address of the old centiped location
	sw $t3, 0($t4)

	
	addi $a1, $a1, 4	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4 	# increment $a2 by one, to point to the next element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, arr_loop
	
	add $s1, $zero, $t4
	li $t3, 0x0000ff
	sw $t3, 0($s1)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
update_centiped:
	# move stack pointer and push ra onto it
	add $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a3, $zero, 10		# load a3 with the loop count (10)
	la $a1, centipedLocation	# load the address of the array
	la $a2, centipedDirection
	
	bne $s2, $zero, check_if_touching_right_wall
	jal check_if_touching_left_wall
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

check_if_touching_right_wall:
	addi $t1, $zero, 32		# load t3 with the loop count (3)
	la $t2, rightWall		# load the wall addresses to $t2

check_if_touching_right_wall_loop:
	lw $t3, 0($t2)			# load the current element of $t2 to $t3
	lw $t4, displayAddress 		# t2 stores the displayAddress
	sll $t3, $t3, 2 		# update $t3 withthe bias of the old body location in memeory (offset * 4)
	add $t4, $t4, $t3		# $t4 is the address of the wall
	beq $s1, $t4, arr_loop_update_change_direction_right_to_left
	
	addi $t1, $t1, -1 		# -1 to loop counter
	add $t2, $t2, 4			# increment $t2 by one, to point to the next element in the array
	
	bne $t1, $zero, check_if_touching_right_wall_loop
	
check_if_touching_right_mush:
	addi $t1, $zero, 5		# load t3 with the loop count (3)
	la $t2, mushroomLocationRight	# load the wall addresses to $t2

check_if_touching_right_mush_loop:
	lw $t3, 0($t2)			# load the current element of $t2 to $t3
	lw $t4, displayAddress 		# t2 stores the displayAddress
	sll $t3, $t3, 2 		# update $t3 withthe bias of the old body location in memeory (offset * 4)
	add $t4, $t4, $t3		# $t4 is the address of the wall
	beq $s1, $t4, arr_loop_update_change_direction_right_to_left
	
	addi $t1, $t1, -1 		# -1 to loop counter
	add $t2, $t2, 4			# increment $t2 by one, to point to the next element in the array
	
	bne $t1, $zero, check_if_touching_right_mush_loop
	
arr_loop_update_move_right:
	# move stack pointer and push ra onto it
	add $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, 0($a1)		# load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		# load a word from the centipedDirection array into $t5
	#####
	addi $t2, $zero, 10
	beq $a3, $t2, skip_black_right
	add $t2, $zero, $s1		# $t2 stores the base address for prev centiped head
	addi $t2, $t2, -36	# $t2 stores the base address for prev centiped tail 
	li $t6, 0x000000 	# $t6 stores the black colour code
	sw $t6, 0($t2) 		# colour black since centiped moved
skip_black_right:
	add $t2, $zero, $s1	# $t2 stores the base address for prev centiped head
	addi $t2, $t2, -32	# $t2, stores the base address for centiped tail + 1
	li $t3, 0xff0000	# $t3 stores the red colour code
	
	sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset * 4)
	add $t4, $t2, $t4	# $t4 is the address of the old centiped location
	sw $t3, 0($t4)

	
	addi $a1, $a1, 4	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4 	# increment $a2 by one, to point to the next element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, arr_loop_update_move_right
	
	add $s1, $zero, $t4
	li $t3, 0x0000ff
	sw $t3, 0($s1)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
arr_loop_update_change_direction_right_to_left:
	# move stack pointer and push ra onto it
	add $sp, $sp, -4
	sw $ra, 0($sp)

paint_body_black:
	lw $t1, 0($a1)		# load centiped location to $t1
	lw $t5, 0($a2)		# load centiped direction to $t5
	#####
	add $t2, $zero, $s1	# $t2 stores the centiped head location
	add $t2, $t2, -36	# $t2 stores the centiped tail location
	li $t6, 0x000000	# store black colour code to $t6
	
	sll $t4, $t1, 2		# $t4 is the bias of the prev body location in memory
	add $t4, $t2, $t4	# $t4 is the address of the old cnetiped location
	sw $t6, 0($t4)	
	
		
	addi $a1, $a1, 4	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4 	# increment $a2 by one, to point to the next element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, paint_body_black
	
	addi $a3, $zero, 10
	addi $a1, $a1, -4
	addi $a2, $a2, -4

paint_new_body:
	lw $t1, 0($a1)		# load centiped location to $t1
	lw $t5, 0($a2)		# load centiped direction to $t5
	#####

	add $t2, $zero, $s1	# $t2 stores the prev centiped head location
	add $t2, $t2, 128	# $t2 stores the new centiped tail location
	add $t2, $t2, -36
	li $t3, 0xff00000	# store red colour code to $t3
	
	sll $t4, $t1, 2		# $t4 is the bias of the prev body location in memory
	add $t4, $t2, $t4	# $t4 is the address of the old cnetiped location
	sw $t3, 0($t4)
	
	addi $a1, $a1, -4	# increment $a1 by one, to point to the prev element in the array
	addi $a2, $a2, -4 	# increment $a2 by one, to point to the prev element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, paint_new_body
	
	add $s1, $zero, $t4	# update centiped head location	
	li $t3, 0x0000ff
	sw $t3, 0($s1)
	addi $s2, $s2, -1	# update direction as left
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

#####

check_if_touching_left_wall:
	addi $t1, $zero, 32		# load t3 with the loop count (32)
	la $t2, leftWall		# load the wall addresses to $t2

check_if_touching_left_wall_loop:
	lw $t3, 0($t2)			# load the current element of $t2 to $t3
	lw $t4, displayAddress 		# t2 stores the displayAddress
	sll $t3, $t3, 2 		# update $t3 withthe bias of the old body location in memeory (offset * 4)
	add $t4, $t4, $t3		# $t4 is the address of the wall
	beq $s1, $t4, arr_loop_update_change_direction_left_to_right
	
	addi $t1, $t1, -1 		# -1 to loop counter
	add $t2, $t2, 4			# increment $t2 by one, to point to the next element in the array
	
	bne $t1, $zero, check_if_touching_left_wall_loop
	
check_if_touching_left_mush:
	addi $t1, $zero, 5		# load t3 with the loop count (3)
	la $t2, mushroomLocationLeft	# load the wall addresses to $t2

check_if_touching_left_mush_loop:
	lw $t3, 0($t2)			# load the current element of $t2 to $t3
	lw $t4, displayAddress 		# t2 stores the displayAddress
	sll $t3, $t3, 2 		# update $t3 withthe bias of the old body location in memeory (offset * 4)
	add $t4, $t4, $t3		# $t4 is the address of the wall
	beq $s1, $t4, arr_loop_update_change_direction_left_to_right
	
	addi $t1, $t1, -1 		# -1 to loop counter
	add $t2, $t2, 4			# increment $t2 by one, to point to the next element in the array
	
	bne $t1, $zero, check_if_touching_left_mush_loop
	
arr_loop_update_move_left:
	# move stack pointer and push ra onto it
	add $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, 0($a1)		# load a word from the centipedLocation array into $t1
	lw $t5, 0($a2)		# load a word from the centipedDirection array into $t5
	#####
	addi $t2, $zero, 10
	beq $a3, $t2, skip_black_left
	add $t2, $zero, $s1		# $t2 stores the base address for prev centiped head
	addi $t2, $t2, 36	# $t2 stores the base address for prev centiped tail 
	li $t6, 0x000000 	# $t6 stores the black colour code
	sw $t6, 0($t2) 		# colour black since centiped moved
skip_black_left:
	add $t2, $zero, $s1	# $t2 stores the base address for prev centiped head
	addi $t2, $t2, 32	# $t2, stores the base address for centiped tail + 1
	li $t3, 0xff0000	# $t3 stores the red colour code
	
	sll $t4, $t1, 2		# $t4 is the bias of the old body location in memory (offset * 4)
	sub $t4, $zero, $t4	# change sign (+ values become - values)
	add $t4, $t2, $t4	# $t4 is the address of the old centiped location
	sw $t3, 0($t4)

	
	addi $a1, $a1, 4	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4 	# increment $a2 by one, to point to the next element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, arr_loop_update_move_left
	
	add $s1, $zero, $t4
	li $t3, 0x0000ff
	sw $t3, 0($s1)
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
arr_loop_update_change_direction_left_to_right:
	# move stack pointer and push ra onto it
	add $sp, $sp, -4
	sw $ra, 0($sp)

paint_body_black_left:
	lw $t1, 0($a1)		# load centiped location to $t1
	lw $t5, 0($a2)		# load centiped direction to $t5
	#####
	add $t2, $zero, $s1	# $t2 stores the centiped head location
	add $t2, $t2, 36	# $t2 stores the centiped tail location
	li $t6, 0x000000	# store black colour code to $t6
	
	sll $t4, $t1, 2		# $t4 is the bias of the prev body location in memory
	sub $t4, $zero, $t4	# change sign (+ values become - values)
	add $t4, $t2, $t4	# $t4 is the address of the old cnetiped location
	sw $t6, 0($t4)	
	
		
	addi $a1, $a1, 4	# increment $a1 by one, to point to the next element in the array
	addi $a2, $a2, 4 	# increment $a2 by one, to point to the next element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, paint_body_black_left
	
	addi $a3, $zero, 10
	addi $a1, $a1, -4
	addi $a2, $a2, -4

paint_new_body_left:
	lw $t1, 0($a1)		# load centiped location to $t1
	lw $t5, 0($a2)		# load centiped direction to $t5
	#####

	add $t2, $zero, $s1	# $t2 stores the prev centiped head location
	add $t2, $t2, 128	# $t2 stores the new centiped tail location
	add $t2, $t2, 36
	li $t3, 0xff00000	# store red colour code to $t3
	
	sll $t4, $t1, 2		# $t4 is the bias of the prev body location in memory
	sub $t4, $zero, $t4	# change sign (+ values become - values)
	add $t4, $t2, $t4	# $t4 is the address of the old cnetiped location
	sw $t3, 0($t4)
	
	addi $a1, $a1, -4	# increment $a1 by one, to point to the prev element in the array
	addi $a2, $a2, -4 	# increment $a2 by one, to point to the prev element in the array
	addi $a3, $a3, -1	# decrement $a3 by 1
	bne $a3, $zero, paint_new_body_left
	
	add $s1, $zero, $t4	# update centiped head location	
	li $t3, 0x0000ff
	sw $t3, 0($s1)
	addi $s2, $s2, 1	# update direction as left
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra	
	
	
	

# function to detect any keystroke
check_keystroke:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
	beq $t8, 1, get_keyboard_input # if key is pressed, jump to get this key
	addi $t8, $zero, 0
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# function to get the input key
get_keyboard_input:
	# move stack pointer and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t2, 0xffff0004
	addi $v0, $zero, 0
	beq $t2, 0x6A, respond_to_j
	beq $t2, 0x6B, respond_to_k
	beq $t2, 0x78, respond_to_x
	beq $t2, 0x73, respond_to_s
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of j key
respond_to_j:
	# move stack pointer and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, blasterLocation	# load the address of bugLocation from memory
	lw $t1, 0($t0)		# load the blaster location itself in $t1
	
	lw $t2, displayAddress  # $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4, $t1, 2		# $t4, the bias of the blasterLocation
	add $t4, $t2, $t4	# $t4 is the address of the old bug location
	sw $t3, 0($t4)		# paint the first (top left) unit black
	
	beq $t1, 992, skip_movement # prevent the bug from getting out of the canvas
	addi $t1, $t1, -1 	# move the bug one location to the right

skip_movement:
	sw $t1, 0($t0)		# save the bug location
	
	li $t3, 0xffffff 	# $t3 stores the white colour code
	
	sll $t4, $t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# point the first (top left) unit white

	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
# Call back function of k key
respond_to_k:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0, blasterLocation	# load the address of blasterLocation
	lw $t1, 0($t0)		# load the blaster location itself in $t1
	
	lw $t2, displayAddress 	# $t2 stores the base address for display
	li $t3, 0x000000	# $t3 stores the black colour code
	
	sll $t4, $t1, 2		# $t4 the bias of the old blasterLocation
	add $t4, $t2, $t4	# $t4 is the address of the old blasterLocation
	sw $t3, 0($t4)		# paint the block with black
	
	beq $t1, 1023, skip_movement2 #prevent the bug from getting out of the canvas
	addi $t1, $t1, 1 	# move the bug one location to the right
skip_movement2:
	sw $t1, 0($t0) 		# save the blasterLocation
	
	li $t3, 0xffffff	# $t3 stores the white colour code
	
	sll $t4, $t1, 2
	add $t4, $t2, $t4
	sw $t3, 0($t4)		# paint the block with white
	
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_x:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 3
	la $s6, centipedLocation
	la $s7, topWall
	lw $t4, displayAddress
	
	la $t0, blasterLocation	# load the address of blasterLocation
	lw $t1, 0($t0)		# load the blaster location itself in $t1
	
	sll $t1, $t1, 2
	add $t9, $t4, $t1

check_next_bullet_location:
	addi $t5, $t9, -128	# next location of bullet

loop_here_check_bullet:
	li $a3, 5000
		
	la $s6, centipedLocation
	la $s7, topWall
	lw $t4, displayAddress
	la $s5, mushroomLocation
delay_loop_little:
	addi, $a3, $a3, -1
	bgtz $a3, delay_loop_little
	# check if it hit topWall,
	addi $t6, $zero, 32	# load t6 with loop counter 32
check_bullet_hits_top_wall:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t7, 0($s7)		# load each element of topWall
	
	sll $t7, $t7, 2		# offset * 4
	add $t7, $t4, $t7	# display address plus offset and save it to $t7
	
	bne $t5, $t7, small_loop_wall
	# pop a word off the stack and move the stack pointer 
	li $t8, 0x000000
	addi $t5, $t5, 128
	sw $t8, 0($t5)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

small_loop_wall:
	addi $s7, $s7, 4
	addi $t6, $t6, -1
	bne $t6, $zero, check_bullet_hits_top_wall
	
	addi $t6, $zero, 10
check_bullet_hits_mush:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t7, 0($s5)		# load each element of mush
	
	sll $t7, $t7, 2		# offset * 4
	add $t7, $t4, $t7	# display address plus offset and save it to $t7
	
	bne $t5, $t7, small_loop_mush
	# pop a word off the stack and move the stack pointer 
	li $t8, 0x000000
	addi $t5, $t5, 128
	sw $t8, 0($t5)
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

small_loop_mush:
	addi $s5, $s5, 4
	addi $t6, $t6, -1
	bne $t6, $zero, check_bullet_hits_mush
	
	addi $t6, $zero, 10	#load t6 with loop counter 10
check_bullet_hits_centiped:
	bne $s2, $zero, centi_moving_right
centi_moving_left:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t7, 0($s6)		# load each element of CentipedLoc
	
	sll $t7, $t7, 2		# offset * 4
	add $t7, $s1, $t7	# head address plus offest and save it to $t7
	
	bne $t5, $t7, small_loop_left # if hit
	
	li $t8, 0x000000
	addi $t5, $t5, 128
	sw $t8, 0($t5)
	
	addi $s3, $s3, 1
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
small_loop_left:
	addi $s6, $s6, 4
	addi $t6, $t6, -1
	bne $t6, $zero, centi_moving_left
	
	j colour_location

centi_moving_right:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t7, 0($s6)		# load each element of CentipedLoc
	
	sll $t7, $t7, 2		# offset * 4
	sub $t7, $zero, $t7
	add $t7, $s1, $t7	# head address plus offest and save it to $t7
	
	bne $t5, $t7, small_loop_right
		
	li $t8, 0x000000
	addi $t5, $t5, 128
	sw $t8, 0($t5)
	
	addi $s3, $s3, 1
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
small_loop_right:
	addi $s6, $s6, 4
	addi $t6, $t6, -1
	bne $t6, $zero, centi_moving_right

	# colour location
colour_location:
	li $t8, 0xc1c1c1
	sw $t8, 0($t5)
	addi $t9, $t5, 128
	add $t7, $t1, $t4
	beq $t9, $t7, skip_colouring
	li $t8, 0x000000
	sw $t8, 0($t9)
skip_colouring:
	addi $t5, $t5, -128
	j loop_here_check_bullet

returning:	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
respond_to_s:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $v0, $zero, 4
	
	jal gameover
	
	j initialize_centiped_head_location
	
	# pop a word off the stack and move the stack pointer
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra

delay:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $a2, 20000
delay_loop:
	addi, $a2, $a2, -1
	bgtz $a2, delay_loop
	
	# pop a word off the stack and move the stack pointer 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
gameover:
	# move stack pointer a work and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $a3, $zero, 0	# load 1024 to $a3
	
gameover_loop:
	lw $t1, displayAddress	# load display address to $t1
	li $t3, 0x000000	# load black colour code to $t2
	
	sll $t5, $a3, 2		# set offset * 4 to $t5
	add $t4, $t5, $t1	# $t4 is the address of the location
	sw $t3, 0($t4)
	
	addi $a3, $a3, 1
	addi $t6, $zero, 1024
	bne $a3, $t6, gameover_loop
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
	
#####
centiped_dead:
	# move stack pointer and push ra onto it
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $t1, $zero, 3
	bne $s3, $t1, dead_returning
	
	la $a1, centipedLocation	# save centipedLocation to $a1
	li $t2, 0x000000 		# black colour code

loop_dead:
	beq $s2, $zero, left_dead_loop
	addi $a2, $zero, 10
right_dead_loop:
	lw $t3, 0($a1)
	sll $t3, $t3, 2
	sub $t3, $zero, $t3
	add $t3, $s1, $t3
	
	sw $t2, 0($t3)
	
	addi $a1, $a1, 4
	addi $a2, $a2, -1
	bne $a2, $zero, right_dead_loop
	
	j before_returning
left_dead_loop:
	lw $t3, 0($a1)
	sll $t3, $t3, 2
	add $t3, $s1, $t3
	
	sw $t2, 0($t3)
	
	addi $a1, $a1, 4
	addi $a2, $a2, -1
	bne $a2, $zero, left_dead_loop
	
before_returning:
	addi $s3, $zero, -3
	lw $s1, displayAddress
	
dead_returning:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra
