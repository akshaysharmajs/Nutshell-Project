%{

#include <stdio.h>
#include <stdlib.h>
#include "node.h"
#include <string>
#include <unistd.h>
#include <stddef.h>
#include <limits.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <pwd.h>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <sstream>
#include <readline/readline.h>
#include <readline/history.h>
#include <time.h>



int yylex();

int yyparse();

void yyerror(char *s){
	fprintf(stderr, "error: %s\n",s);
}

int cmd_number = -1;
char* varTbl[128][100];
char* wildcard[100];
char* users[1000];
int wild = 0;
int row = 0;
int col = 0;
char* temp_string = "temp";
char* temp_string2 = "temp";
char* io = "";
LL *list;
int filedesc;

char* alias_expand(char* name)
{
	return command_expand(list, name);
}

bool match(char *first, char * second)
{
    if (*first == '\0' && *second == '\0')
        return true;

    if (*first == '*' && *(first+1) != '\0' && *second == '\0')
        return false;

    if (*first == '?' || *first == *second)
        return match(first+1, second+1);

    if (*first == '*')
        return match(first+1, second) || match(first, second+1);
    return false;
}

%}

%code requires {
#include "node.h"
}

%union {
	char* string;
	int num;
}

%token BYE ENDF CD ALIAS QUOTE UNALIAS SETENV PRINTENV UNSETENV LESS GREATER STAR AND QUESTION DOLLAR OCURL CCURL LS PRINT PWD TILDE TOUCH HEAD TAIL CAT WC ESC MKDIR RM DATE
%token <string> WORD ARG

%%

cmdline:
  | cmdline cmd ;

cmd:
  | bye | cd | alias | unalias | setenv | printenv | unsetenv | redirectIO | ls | echo | pwd | mkdir | rm | envexpand | touch | head | tail | wc | date |cat | word ;


envexpand:
		DOLLAR OCURL WORD CCURL {
			 	printf("%s\n",getenv($3));
			}


params:
		CD {
			temp_string = "cd";
		}
		| UNALIAS {
			temp_string = "unalias";
		}
		|	SETENV {
			temp_string = "setenv";
		}
		| UNSETENV {
			temp_string = "unsetenv";
		}
		| PRINTENV {
			temp_string = "printenv";
		}
		| LS {
			temp_string = "ls";
		}
		| LS ARG{
			temp_string = "ls";
			char buffer[100];
			strcpy(buffer, temp_string);
			strcat(buffer, " ");
			strcat(buffer, $2);
			temp_string = buffer;
		}
		| PRINT {
			temp_string = "echo";
		}
		| WORD {
			temp_string = $1;
		}
		| params WORD {
			char buffer[100];
			strcpy(buffer, temp_string);
			strcat(buffer, " ");
			strcat(buffer, $2);
			temp_string = buffer;
		}

		| params DOLLAR OCURL WORD CCURL  {
			char buffer[100];
			strcpy(buffer, temp_string);
			strcat(buffer, " ");
			strcat(buffer, getenv($4));
			temp_string = buffer;
		}
		| STAR WORD {
			wild = 0;
			struct dirent *dir;
			DIR *d;
			d = opendir(".");
			int matching, length = strlen($2);
			char *stringin = $2, *stringout;
			if(d)
			{
				while ((dir = readdir(d)) != NULL)
				{
					matching = 1;
					stringout = dir->d_name;
					int outlength = strlen(stringout) -1;
					int k;
					for (k = length - 1; k >= 0; k--)
					 {
						if (stringout[outlength] != stringin[k])
						{
							matching = 0;
							break;
						}
						outlength--;
					}
					if (matching == 1)
					{
						temp_string = stringout;
						wildcard[wild] = temp_string;
						wild++;

					}
				}
			closedir(d);
			}
		}
		| WORD STAR {
			wild = 0;
			struct dirent *dir;
			DIR *d;
			d = opendir(".");
			int matching, length = strlen($1);
			char *stringin = $1, *stringout;
			if(d)
			{
				while ((dir = readdir(d)) != NULL)
				{
					matching = 1;
					stringout = dir->d_name;
					int k;
					for (k = 0; k < length; k++)
					{
						if (stringout[k] != stringin[k])
						{
							matching = 0;
							break;
						}
					}
					if (matching == 1)
					{
						temp_string = stringout;
						wildcard[wild] = temp_string;
						wild++;
					}
				}
			closedir(d);
			}
		}
		| WORD QUESTION WORD {
			wild = 0;
			DIR *d;
			struct dirent *dir;
			d = opendir(".");
			char *stringin = $1, *stringinright = $3;
			strcat(stringin,"?");
			strcat(stringin, stringinright);
			if(d)
			{
				while ((dir = readdir(d)) != NULL)
				{
					if (match(stringin, dir->d_name))
					{
						wildcard[wild] = dir->d_name;
						wild++;
					}
				}
			closedir(d);
			}
		}
		| WORD QUESTION {
			printf("%s", $1);
			wild = 0;
			DIR *d;
			struct dirent *dir;
			d = opendir(".");
			char *stringin = $1;
			strcat(stringin,"?");
			if(d)
			{
				while ((dir = readdir(d)) != NULL)
				{
					if (match(stringin, dir->d_name))
					{
						printf("%s", dir->d_name);
						wildcard[wild] = dir->d_name;
						wild++;
					}
				}
			closedir(d);
			}
		};


bye:
  ENDF { exit(0);}
  | BYE { cmd_number = 1;}

redirectIO:
		GREATER {
			io = "greater";
		}
		| LESS {
			io = "less";
		}
		|	GREATER WORD {
			temp_string2 = $2;
			io = "greater";
		}
		|	LESS WORD {
				temp_string2 = $2;
				io = "less";
			};


cd:
	CD {
			cmd_number = 2;
		}
	| CD params {
			cmd_number = 3;
			col = 0;
			varTbl[row][col] = temp_string;
			col++;
			row++;
	}
	| CD TILDE {
		cmd_number = 2;
	}
	| CD TILDE WORD{
		struct passwd *pw;
		if((pw = getpwnam($3)) == NULL)
    {
          fprintf(stderr, "unknown user %s\n", $3);
    }
		else
		{
			cmd_number = 3;
			col = 0;
			varTbl[row][col] = pw->pw_dir;
			col++;
			row++;
		}

	}
	| CD QUOTE params QUOTE{
		cmd_number = 3;
		col = 0;
		varTbl[row][col] = temp_string;
		col++;
		row++;
	}
	| CD params redirectIO {
		cmd_number = 3;
		col= 0;
		varTbl[row][col] = temp_string;
		col++;
		varTbl[row][col] = io;
		col++;
		varTbl[row][col] = temp_string2;
		col++;
		row++;
	}
	| CD TILDE WORD ESC{

		/*while (true) {
		 errno = 0; // so we can distinguish errors from no more entries
		 passwd* entry = getpwent();
		 if (!entry) {
				 if (errno) {
						 std::cerr << "Error reading password database\n";
						 return EXIT_FAILURE;
				 }
				 break;
		 }
		 std::cout << entry->pw_name << '\n';
 }
 endpwent();*/

			struct dirent *dir;
			DIR *d;
			char path[100] = "";
			strcat(path, getenv("HOME"));
			printf("%s early", path);
			strcat(path,"/..");
			d = opendir(path);
			int matching, length = strlen($3);
			char *stringin = $3, *stringout;
			if(d)
			{
				while ((dir = readdir(d)) != NULL)
				{
					matching = 1;
					stringout = dir->d_name;
					int k;
					for (k = 0; k < length; k++)
					{
						if (stringout[k] != stringin[k])
						{
							matching = 0;
							break;
						}
					}
					if (matching == 1)
					{
						temp_string = stringout;
						break;
					}
				}
			closedir(d);
			}
			strcat(path,"/");
			strcat(path,temp_string);
			cmd_number = 3;
			col = 0;
			varTbl[row][col] = path;
			col++;
			row++;

	};


date:
	DATE {
		time_t t = time(NULL);
  struct tm tm = *localtime(&t);
  printf("now: %d-%02d-%02d %02d:%02d:%02d\n", tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday, tm.tm_hour, tm.tm_min, tm.tm_sec);
	}


alias:
		 ALIAS WORD params {
			cmd_number = 4;
			char *name = $2;
			char *value = temp_string;
			varTbl[row][col] = name;
			col++;
			varTbl[row][col] = value;
			col++;
			row++;
		}
		| ALIAS WORD QUOTE params QUOTE {
			char *name = $2;
			char *value = temp_string;
			push_LL(list, name, value);
		}
		| ALIAS {
			print_LL(list);
		};


unalias:
			UNALIAS WORD{
			char *name = $2;
			remove_node(list, name);
		}
			| UNALIAS DOLLAR OCURL WORD CCURL {
				char *name = getenv($4);
				remove_node(list, name);
			};



setenv:
		SETENV WORD WORD {
			cmd_number = 5;
			col = 0;
			char* name = $2;
			char* value = $3;
			varTbl[row][col] = name;
			col++;
			varTbl[row][col] = value;
			col++;
			row++;
		}
		| SETENV WORD QUOTE params QUOTE {
			cmd_number = 5;
			col = 0;
			char* name = $2;
			char* value = temp_string;
			varTbl[row][col] = name;
			col++;
			varTbl[row][col] = value;
			col++;
			row++;
		}
	| SETENV WORD WORD AND {
		cmd_number = 5;
		col = 0;
		char* name = $2;
		char* value = $3;
		varTbl[row][col] = name;
		col++;
		varTbl[row][col] = value;
		col++;
		varTbl[row][col] = "&";
		col++;
		row++;
	}
	| SETENV WORD params redirectIO {
		cmd_number = 5;
		col = 0;
		char* name = $2;
		char* value = temp_string;
		char* file = temp_string2;
		varTbl[row][col] = name;
		col++;
		varTbl[row][col] = value;
		col++;
		varTbl[row][col] = io;
		col++;
		varTbl[row][col] = file;
		col++;
		row++;
	};


unsetenv:
			UNSETENV WORD {
				cmd_number = 6;
				col = 0;
				char* name = $2;
				varTbl[row][col] = name;
				col++;
				row++;
			}

			| UNSETENV WORD AND {
				cmd_number = 6;
				col = 0;
				char* name = $2;
				varTbl[row][col] = name;
				col++;
				varTbl[row][col] = "&";
				col++;
				row++;
			}
			| UNSETENV WORD redirectIO {
				cmd_number = 6;
				col = 0;
				varTbl[row][col] = $2;
				col++;
				varTbl[row][col] = io;
				col++;
				varTbl[row][col] = temp_string2;
				col++;
				row++;
			};


printenv:
				PRINTENV {
					cmd_number = 7;
				}
				| PRINTENV redirectIO {
					cmd_number = 7;
					col = 0;
					varTbl[row][col] = io;
					col++;
					varTbl[row][col] = temp_string2;
					col++;
					row++;
				};


ls:
 		LS {
				cmd_number = 9;
			}
			| LS params{
				col = 0;
				cmd_number = 10;
				varTbl[row][col] = temp_string;
				col++;
				row++;
			}
			| LS redirectIO {
				col = 0;
				cmd_number = 9;
				varTbl[row][col] = temp_string;
				col++;
				varTbl[row][col] = io;
				col++;
				varTbl[row][col] = temp_string2;
				col++;
				row++;
			}
			| LS params redirectIO {
				col = 0;
				cmd_number = 10;
				varTbl[row][col] = temp_string;
				col++;
				varTbl[row][col] = io;
				col++;
				varTbl[row][col] = temp_string2;
				col++;
				row++;
			}
			| LS ARG{
				col = 0;
				cmd_number = 11;
				varTbl[row][col] = temp_string;
				col++;
				varTbl[row][col] = $2;
				col++;
				row++;
			};


touch:
		TOUCH WORD{
			cmd_number = 12;
			varTbl[row][col] = $2;
			row++;
			col++;
		}
		| TOUCH QUOTE WORD QUOTE
		{
			cmd_number = 12;
			varTbl[row][col] = $3;
			row++;
			col++;
		};

head:
		HEAD WORD{
				varTbl[row][col] = $2;
				row++;
				col++;
				cmd_number = 13;
		}
		| HEAD WORD redirectIO {
			varTbl[row][col] = $2;
			col++;
			varTbl[row][col] = io;
			col++;
			varTbl[row][col] = temp_string2;
			row++;
			col++;
			cmd_number = 13;
		}
		| HEAD ARG WORD{
			varTbl[row][col] = $2;
			col++;
			varTbl[row][col] = $3;
			row++;
			col++;
			cmd_number = 14;
		}

tail:
			TAIL WORD{
				varTbl[row][col] = $2;
				row++;
				col++;
				cmd_number = 15;
		}
		| TAIL ARG WORD{
			varTbl[row][col] = $2;
			col++;
			varTbl[row][col] = $3;
			row++;
			col++;
			cmd_number = 16;
		}


echo:
		PRINT WORD {
			printf("%s", $2);
		}
		| PRINT QUOTE WORD QUOTE{
			printf("%s", $3);
		}
		| PRINT QUOTE envexpand QUOTE {

		}


pwd:
	PWD{
		char cwd[PATH_MAX];
		getcwd(cwd, sizeof(cwd));
		printf("%s\n",cwd);
	}


cat:
	CAT WORD {
		int fd, ch;
		fd = open($2,O_RDONLY);            /*open the file in READONLY mode*/

		if(fd < 0) {
			printf("error opening file or file doesn't exist\n");

		}
		else
		{
			while(read(fd,&ch,1))                   /*Read one byte at a time*/
				write(STDOUT_FILENO,&ch,1);
		}

	}
	| CAT QUOTE WORD QUOTE {
		int fd, ch;
		fd = open($3 ,O_RDONLY);            /*open the file in READONLY mode*/

		if(fd < 0) {
			printf("error opening file or file doesn't exist\n");

		}
		else
		{
			while(read(fd,&ch,1))                   /*Read one byte at a time*/
				write(STDOUT_FILENO,&ch,1);
		}
	};


mkdir:
		MKDIR WORD{
			int check = mkdir($2,0777);

    // check if directory is created or not
	    if (!check)
	        printf("Directory created\n");
	    else {
	        printf("Unable to create directory\n");
    }
		}


rm:
	RM WORD{
		remove($2);
	}


wc:
	WC WORD {
			std::string line;
	    std::fstream file;
			file.open($2);
			if(file != NULL)
			{
				int numlines=0, numwords = 0;
				while(getline(file, line))
				{
				    ++numlines;
				    std::stringstream lineStream(line);
				    while(getline(lineStream, line, ' '))
				    {
				        ++numwords;
				    }
				}

				printf("%d %d %d %s\n",numlines, numwords, (int)file.tellg(), $2);
			}
			else
			{
				printf("error opening file or file doesn't exist\n");
			}
			file.close();

	}

word:
	WORD {

		char *expand = command_expand(list, $1);
		cmd_number = 20;
		struct stat sb;
  	if(stat($1, &sb) == 0 && sb.st_mode & S_IXUSR)
		{
			pid_t p;
			int mutex, wpid;
			p = fork();
			if (p < 0)
			{
				printf("fork failed");
			}
			else if (p == 0)
			{
				char *symlinkpath = $1;
				char actualpath [PATH_MAX+1];
				char *ptr;
				ptr = realpath(symlinkpath, actualpath);
				execl(ptr, "cmdvalue.txt", 0);
			}
			else
			{
				while ((wpid = wait(&mutex)) > 0)
				{
					//parent process waits until child exits
				}
			}
		}
		else if(strcmp("Command not found", expand) == 0)
		{
			printf("%s : command not found", $1);
		}
		else
		{

			int pipe1[2]; //pipe with two ends, read and write
			pid_t p;
			int mutex, wpid;
			pipe(pipe1); //creates pipe
			p = fork();
			if (p < 0)
			{
				printf("fork failed");
			}
			else if (p == 0)
			{
				FILE *f;
				f = fopen("cmdvalue.txt", "w");
				fprintf(f, "%s\n", expand);
				fclose(f);
				f = fopen("cmdvalue.txt", "r");
				int filedesc = fileno(f);
				dup2(filedesc, fileno(stdin));
				fclose(f);
				char dest[100];
				strcpy(dest, getenv("PWD"));
				strcat(dest, "/");
				strcat(dest, "cmdvalue.txt");
				execl(dest, "cmdvalue.txt", 0);
			}
			else
			{
				while ((wpid = wait(&mutex)) > 0)
				{
					//parent process waits until child exits
				}
			}
		}
		printf("\n");
};

  %%
