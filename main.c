#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>

int main(int argc, char* argv[])
{
	char* base_dir = (char*) malloc(1024);
	readlink("/proc/self/exe", base_dir, 1024);
	dirname(base_dir);

	const char* format = "bash %s/git_over_ssh.sh %s";
	int concat_args_size = 1;

	for (int i = 1; i < argc; i++)
	{
		concat_args_size += strlen(argv[i]);
		concat_args_size++;
	}

	char* concat_args = (char*) malloc(concat_args_size);
	concat_args[0] = '\0';

	for (int i = 1; i < argc; i++)
	{
		if (i > 1) strcat(concat_args, " ");
		strcat(concat_args, argv[i]);
	}

	int command_size = 1;
	command_size += strlen(base_dir);
	command_size += strlen(format);
	command_size += strlen(concat_args);

	char* command = (char*) malloc(command_size);
	sprintf(command, format, base_dir, concat_args);

	return system(command);
}