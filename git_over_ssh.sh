#!/bin/bash

# edit git_over_ssh.conf
id_rsa=~/.ssh/id_rsa
connection_str=root@localhost
project_dir=

cd $(dirname $0)
source git_over_ssh.conf

trap "kill 0" SIGTERM
trap "kill 0" SIGINT

function generate_boundary {
	# generate a unique token used to identify end of response 
	echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
};

function make_pipe {
	# create fifo pipe
	if [[ ! -e $1 ]]
	then 
		mkfifo $1
	fi	
};

function response_processor {
	# process responses from ssh
	local divider=$1
	local identifier=
	local is_new_response=0
	while IFS= read -r line
	do 
		if [[ "$line" == "$divider" ]]
		then
			is_new_response=1
			continue
		fi

		if [[ $is_new_response -eq 1 ]]
		then
			identifier=$line
			is_new_response=0
			continue
		fi

		if [[ "$line" == *"$identifier" ]]
		then
			line=$(echo -n "$line" | head -c -64)
			echo -n "$line" >> git_over_ssh.buffer
			cat git_over_ssh.buffer > \
				git_over_ssh.r.$identifier
			> git_over_ssh.buffer
			continue
		else 
			echo "$line" >> git_over_ssh.buffer
			continue
		fi
	done
};

function connection_process {
	# make connection to ssh
	(while cat < git_over_ssh.w; do :; done) | \
		/bin/ssh -i "${id_rsa}" "${connection_str}" | \
			# (while tee -a "response.log"; do :; done) | \
			(response_processor $1)
};

# forces make connection in foreground
if [[ "$1" == "--force-make-connection" ]]
then
	declare divider=$(generate_boundary)
	echo -n $divider > git_over_ssh.divider
	echo "connect: $divider"
	make_pipe git_over_ssh.w
	touch git_over_ssh.running
	connection_process $divider
	rm git_over_ssh.running
	exit
fi

# we are not running so exit to avoid hang
if [[ ! -f git_over_ssh.running ]]
then
	exit 1
fi

declare identifier=$(generate_boundary)
declare divider=$(cat git_over_ssh.divider)

make_pipe git_over_ssh.r.$identifier

echo echo $divider > git_over_ssh.w
echo echo $identifier > git_over_ssh.w

if [[ -n "$project_dir" ]]
then
	echo cd $project_dir > git_over_ssh.w
fi

echo git $@ > git_over_ssh.w
echo echo $identifier > git_over_ssh.w

cat git_over_ssh.r.$identifier
rm git_over_ssh.r.$identifier
