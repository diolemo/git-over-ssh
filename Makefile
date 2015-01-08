all:
	gcc -std=c99 main.c -o git_over_ssh

connect: 
	bash git_over_ssh.sh --force-make-connection