#!/bin/bash

## Script usage:
## bash <script_name> <arg1:username/UID> <arg2:groupname/GID> <arg3:absolute path of directory>

## Bash shell script that takes UID/username, GID/groupname and Absolute path of the directory
## as input. The script checks of the user and group exists. If they both exists it checks if
## user is part of the entered group.
## The script will exit if user or group do not exist and also when entered user is not part 
## the entered group.
## The script then checks for permissions of the files inside a given path.
## The letters after the path U, G or O indicate user, group or other and Y or N indicates yes
## or no for the respective applicable permissions. The script will first check for user
## permission then group permission and then for others.
## The output is displayed on screen as well as saved to USER'S HOME directory as /project/executable_files.txt
## Sample output:
## /home/swapnil/project/qwert12345 : -rwxrw-rw- 1 swapnil swapnil    0 Apr 19 15:29 qwert12345 : UY
## This can be read as:
## absolute_path : ls output : U/G/O Y/N (user, group, other has executable permissions yes/no)

# Users home directory
HOME_DIR_USR="/home/$USER"
# path of /etc/passwd
PASSWD_PATH="/etc/passwd"
# path of /etc/group
GROUP_PATH="/etc/group"

# trap to remove the temporary file in case of program exit
trap 'rm -rf $HOME_DIR_USR/projectfiles12qw; exit' 0 1 2 3 13 15

# function to check if UID/username exist
function checkUID {
	# Grep USER_NAME in /etc/passwd 1st column as username or 3rd column as UID and capture the exit value 
	# Then checking if exit value is not equal to zero which means the username / UID does not exists
	( cut -d : -f 1 $PASSWD_PATH | grep -wq "$USER_NAME" ) || ( cut -d : -f 3 $PASSWD_PATH | grep -wq  "$USER_NAME" )
	EXIT_STATUS_UID=$?
	if [ $EXIT_STATUS_UID -ne 0 ]; then
		echo "The username / UID entered does not exists"
		exit 1
	fi
}

# function to check if GID/groupname exist
function checkGID {
	# Grep GROUP_NAME in /etc/group 1st column as groupname or 3rd column as GID and capture the exit value 
	# Then checking if exit value is not equal to zero which means the groupname / GID does not exists
	( cut -d : -f 1 $GROUP_PATH | grep -wq "$GROUP_NAME" ) || ( cut -d : -f 3 $GROUP_PATH | grep -wq  "$GROUP_NAME" )
	EXIT_STATUS_GID=$?
	if [ $EXIT_STATUS_GID -ne 0 ]; then
		echo "The groupname / GID entered does not exists"
		exit 1
	fi
}

# Function to check if user is part of the group
function UID_part_of_GID {
	##  mapping ID to name   
	# If we have either UID and GID entered as an input converting it to its respective username and groupname
	if [[ $USER_NAME =~ ^[0-9]+$ ]]; then
		UNAME=$(cut -d : -f 1,3 $PASSWD_PATH | grep -w "$USER_NAME" | cut -d : -f 1)
	else
		UNAME=$USER_NAME
	fi

	if [[ $GROUP_NAME =~ ^[0-9]+$ ]]; then
		GNAME=$(cut -d : -f 1,3 $GROUP_PATH | grep -w "$GROUP_NAME" | cut -d : -f 1)
	else
		GNAME=$GROUP_NAME
	fi

	# creating project directory if it does not exist
	[ ! -d "$HOME_DIR_USR"/project ] && mkdir "$HOME_DIR_USR"/project
	
	# For checking if a user exists in a group we are checking in /etc/group file. 
	# For a given groupname found in 1st column we need to check if there exists provided username in 4th column.
	# Then we capture exit value and check if its not equal to zero. If yes then entered username is not part of entered groupname.
	# If no then username exists in the provided groupname.
	grep -w "^$GNAME" $GROUP_PATH | cut -d : -f 4 | grep -wq "$UNAME"
	EXIT_STATUS_U_IN_G=$?

	if [ $EXIT_STATUS_U_IN_G -ne 0 ];then
		echo "Input is $UNAME for user name, $GNAME for group name and $UNAME is NOT a member of $GNAME"
		exit 1
	else
		echo "Input is $UNAME for user name, $GNAME for group name and $UNAME is a member of $GNAME"
		echo "Input is $UNAME for user name, $GNAME for group name and $UNAME is a member of $GNAME" > ~/project/executable_files.txt
	fi
}

# Function to check if the directory is valid
function checkDIR {
	# If directory does not exist exiting the code after displing error.
	[ ! -e "$DIRECTORY" ] && echo "Path $DIRECTORY not found" && exit 1
}

# Function to check the executable permission
function checkEXE {
	
	# creating a temporary directory
	mkdir "$HOME_DIR_USR"/projectfiles12qw
	
	# removing the last / from the provided path if entered for better displing output
	[[ $DIRECTORY == */ ]] && DIRECTORY=${DIRECTORY%?}
	
	#stdout output of ls -al for the provided path 
	# ls -alR : a for hidden; L for use a long listing format; R for recusive
	ls -alR "$DIRECTORY" > "$HOME_DIR_USR"/projectfiles12qw/fileslist.txt
	
	#removing the first line if the provided path is directory
	#[ -d "$DIRECTORY" ] && sed -i '1d' $HOME_DIR_USR/projectfiles12qw/fileslist.txt
	
	#temporary variable
	var_two=""

	#Process substitution. Loop below will read the file with output of ls -al and process it a line at a time
	while read -r line
	do
		# check if the line contains path if yes storing it to var_two
		# This helps in adding absolute path in the output of ls -alR
		# Then var_one is the file name.
		# var_two + var_one will provide the complete absolute path of the file.
		[[ $line == /* ]] && var_two="${line//:/}/"#remove colen and add /
		var_one=$(echo "$line" | awk '{ print $9 }')
		modified_line="$var_two$var_one : $line"
		
		# if var_one is blank OR . OR .. skip that line
		# This step just remove unwanted lines from ls -alR output.
		# in case if . and .. path needs to be shown in output remove them from if condition
		if [[ "$var_one" != "" && "$var_one" != "." && "$var_one" != ".." ]]; then
			# check if the user entered is same as the user of the file
			# grep if 5rd column(user of the file) is same to the username entered as input and capturing a variable.
			LS_UNAME=$(echo "$modified_line" | awk '{ print $5; }')
			# grep if 6th column(group of the file) is same to the groupname entered as input and capturing a variable.
			LS_GNAME=$(echo "$modified_line" | awk '{ print $6; }')
			#if exit value for user is 0(i.e if user of files matches username entered)
			if [ "$LS_UNAME" == "$UNAME" ]; then
				# check if user has executable permissions with the help of below regex and capturing exit value 
				echo "$modified_line" | awk '{ print $3; }' | grep -Eq "[a-z-]{3}[x][a-z-]{6}"
				EXITSTATUS_USR_PERX=$?
				# check if exit value of user executable permissions is 0. if yes user has executable permissions
				# if no user has no executable permissions
				[ $EXITSTATUS_USR_PERX -eq 0 ] && echo "$modified_line : UY" && echo "$modified_line : UY" >> ~/project/executable_files.txt
				[ $EXITSTATUS_USR_PERX -ne 0 ] && echo "$modified_line : UN" && echo "$modified_line : UN" >> ~/project/executable_files.txt
			#if exit value of group is 0(i.e if group of files matches groupname entered)
			elif [ "$LS_GNAME" == "$GNAME"  ]; then
				# check if group has executable permissions with the help of below regex and capturing exit value
				echo "$modified_line" | awk '{ print $3; }' | grep -Eq "[a-z-]{6}[x][a-z-]{3}"
				EXITSTATUS_GRP_PERX=$?
				# check if exit value of group executable permissions is 0. if yes group has executable permissions
				# if no group has no executable permissions
				[ $EXITSTATUS_GRP_PERX -eq 0 ] && echo "$modified_line : GY" && echo "$modified_line : GY" >> ~/project/executable_files.txt
				[ $EXITSTATUS_GRP_PERX -ne 0 ] && echo "$modified_line : GN" && echo "$modified_line : GN" >> ~/project/executable_files.txt
			else
				# checking for other if user and group entered don't match to user and group of the file
				# check if other has executable permissions with the help of below regex and capturing exit value 
				echo "$modified_line" | awk '{ print $3; }' | grep -Eq "[a-z-]{9}[x]"
				EXITSTATUS_OTH_PERX=$?
				# if exit value of other executable permissions is 0. if yes other has executable permissions
				# if no other has no executable permissions
				[ $EXITSTATUS_OTH_PERX -eq 0 ] && echo "$modified_line : OY" && echo "$modified_line : OY" >> ~/project/executable_files.txt
				[ $EXITSTATUS_OTH_PERX -ne 0 ] && echo "$modified_line : ON" && echo "$modified_line : ON" >> ~/project/executable_files.txt
			fi
		fi
	done < "$HOME_DIR_USR"/projectfiles12qw/fileslist.txt
}

# when there are no input arguments take input from user interactively
if [ $# -eq 0 ]; then
	#echo "No arguments supplied"
	echo "Enter username"
	read -r USER_NAME
	checkUID #calling function to check UID/username
	echo "Enter groupname"
	read -r GROUP_NAME 
	checkGID #calling function to check GID/groupname
	UID_part_of_GID #calling function to check user is part of that group
	echo "Enter absolute path of the directory to search in"
	read -r DIRECTORY
	checkDIR #calling function to check if entered directory exists
	checkEXE #calling function to get the executable permission output
# Invalid usage when there are input arguments and they are greater than or equal to 4
elif [ $# -ge 4 ]; then
	echo "Invalid Usage: No more than 3 arguments allowed."
	echo "Usage: bash <script_name> <arg1:username/UID> <arg2:groupname/GID> <arg3:absolute path of directory> "
# Invalid usage when there are input arguments and they are less than or equal to 2
elif [ $# -le 2 ]; then
	echo "Invalid Usage: No less than 3 arguments allowed."
	echo "Usage: bash <script_name> <arg1:username/UID> <arg2:groupname/GID> <arg3:absolute path of directory> "
# When input arguments are equal to 3 take the arguments as valid input
else
	USER_NAME=$1
	checkUID #calling function to check UID/username
	GROUP_NAME=$2
	checkGID #calling function to check GID/groupname
	UID_part_of_GID #calling function to check user is part of that group
	DIRECTORY=$3
	checkDIR #calling function to check if entered directory exists
	checkEXE #calling function to get the executable permission output
fi

exit 0