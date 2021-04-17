/* A Bison parser, made by GNU Bison 3.7.6.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_PARSER_TAB_H_INCLUDED
# define YY_YY_PARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 69 "parser.y"

#include "node.h"

#line 53 "parser.tab.h"

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    BYE = 258,                     /* BYE  */
    ENDF = 259,                    /* ENDF  */
    CD = 260,                      /* CD  */
    ALIAS = 261,                   /* ALIAS  */
    QUOTE = 262,                   /* QUOTE  */
    UNALIAS = 263,                 /* UNALIAS  */
    SETENV = 264,                  /* SETENV  */
    PRINTENV = 265,                /* PRINTENV  */
    UNSETENV = 266,                /* UNSETENV  */
    LESS = 267,                    /* LESS  */
    GREATER = 268,                 /* GREATER  */
    STAR = 269,                    /* STAR  */
    AND = 270,                     /* AND  */
    QUESTION = 271,                /* QUESTION  */
    DOLLAR = 272,                  /* DOLLAR  */
    OCURL = 273,                   /* OCURL  */
    CCURL = 274,                   /* CCURL  */
    LS = 275,                      /* LS  */
    PRINT = 276,                   /* PRINT  */
    PWD = 277,                     /* PWD  */
    TILDE = 278,                   /* TILDE  */
    TOUCH = 279,                   /* TOUCH  */
    HEAD = 280,                    /* HEAD  */
    TAIL = 281,                    /* TAIL  */
    CAT = 282,                     /* CAT  */
    WC = 283,                      /* WC  */
    ESC = 284,                     /* ESC  */
    MKDIR = 285,                   /* MKDIR  */
    RM = 286,                      /* RM  */
    DATE = 287,                    /* DATE  */
    WORD = 288,                    /* WORD  */
    ARG = 289                      /* ARG  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 73 "parser.y"

	char* string;
	int num;

#line 109 "parser.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_PARSER_TAB_H_INCLUDED  */
