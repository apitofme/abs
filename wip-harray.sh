#! /bin/bash

# apitofme@github >> BASH >> ABS >> harray -- v0.1-alpha


# IMPORTANT:
# ----------
# I did not write the functions for Push, Pop, Shift & Unshift! ( I'm not trying to re-invent the wheel! )
# Credit for these go to 'admica' (?) -- a.k.a the rootninja
# -- see >> http://www.rootninja.com/how-to-push-pop-shift-and-unshift-arrays-in-bash/


# ########################################
# Start of admica/rootninja's functions >>

# Array Push
# @desc Adds an item on the the end of an array (increasing the array length by one)
arr_push() {
	arr=("${arr[@]}" "$1")
}


# Array Pop
# @desc Pops an item off of the end of an array (decreasing the array length by one)
arr_pop() {
	i=$(expr ${#arr[@]} - 1)
	placeholder=${arr[$i]}
	unset arr[$i]
	arr=("${arr[@]}")
}


# Array Shift
# @desc Adds an item to the begining of an array, shifting the previous array elements up by one position (previous indexes increase by 1)
arr_shift() {
	arr=("$1" "${arr[@]}")
}


# Array Un-Shift
# @desc Removes the first item in an array and moves all remaining elements one position down (previous indexes decrease by 1)
arr_unshift() {
	placeholder=${arr[0]}
	unset arr[0]
	arr=("${arr[@]}")
}

# << End of admica/rootninja's functions
# ######################################


# Array Merge [WIP]
# @desc Merges two or more arrays together (with option to sort?)
arr_merge() {
	if [ $# -lt 2 ]; then # Warn user if passing insufficient number of arguments/parameters
		echo "ERROR: Insufficient arguments/parameters passed in!";
		echo "Usage: arr_merge [opts] arr1 arr2 [...]";
		return 1;
	fi
	
	# check if the first parameter is an option
	while getopts ":i s" OPT; do
		case $OPT in
			i) # interleave (i.e. alternate array elements when concatenating)
				# e.g. marr=(arr1[0] arr2[0] arr3[0] arr1[1] arr2[1] arr1[2])
				
				n=0; # highest number of elements contained within any one of the arrays
			
				for a in "$@"
				do # for each array passed in as an argument
					# check if the length of the array is greater than the length of any of the other arrays encountered so far
					if [ ${#a} -gt $n ]
					then
						n=${#a[@]} # if so, update the 'max' number of elements
					fi
				done
			;;
			s) # sort array (once concatenated)
				arr=();
				for a in $@; do 
					arr=("$arr $a") # concatenate the array
				done
			
				sort $arr;
			
				# TODO set up variable for returning values/variables
			
				exit 0;
			;;
		esac
	done
	
}
