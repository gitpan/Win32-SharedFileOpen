/*------------------------------------------------------------------------------
 * Copyright (c) 2001-2002, Steve Hay. All rights reserved.
 *
 * Module Name:	Win32::SharedFileOpen
 * Source File:	SharedFileOpen.xs
 * Description:	C and XS code for xsubpp
 *------------------------------------------------------------------------------
 */

/*-----------------------------------------------------------------------------
 *
 * C code to be copied verbatim by xsubpp.
 */

#include <io.h>							/* For _sopen().					*/
#include <stdio.h>						/* For _fsopen().					*/
#include <fcntl.h>						/* For the _O_* flags.				*/
#include <share.h>						/* For the _SH_DENY* flags.			*/
#include <sys/stat.h>					/* For the _S_* flags.				*/
#define WIN32_LEAN_AND_MEAN				/* Don't pull in too much crap when	*/
										/* including <windows.h> next.		*/
#include <windows.h>					/* For the DWORD typedef (in		*/
										/* <windef.h>) and the INFINITE		*/
										/* flag (in <winbase.h>).			*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
 * Function to expose relevant C #define's.
 * Sets errno to EINVAL and returns 0 if the requested name is not one of ours;
 * sets errno to ENOENT and returns 0 if the requested name is one of ours but
 * is not defined;
 * otherwise sets errno to 0 and returns the value of the requested name.
 */

static DWORD constant(const char *name, int len, int arg) {
	errno = 0;

	switch (*name) {
		case 'I':
			if (strEQ(name, "INFINITE"))
				#ifdef INFINITE
					return INFINITE;
				#else
					goto not_there;
				#endif
		case 'O':
			if (strEQ(name, "O_APPEND"))
				#ifdef _O_APPEND
					return _O_APPEND;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_BINARY"))
				#ifdef _O_BINARY
					return _O_BINARY;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_CREAT"))
				#ifdef _O_CREAT
					return _O_CREAT;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_EXCL"))
				#ifdef _O_EXCL
					return _O_EXCL;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_NOINHERIT"))
				#ifdef _O_NOINHERIT
					return _O_NOINHERIT;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_RANDOM"))
				#ifdef _O_RANDOM
					return _O_RANDOM;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_RDONLY"))
				#ifdef _O_RDONLY
					return _O_RDONLY;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_RDWR"))
				#ifdef _O_RDWR
					return _O_RDWR;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_SEQUENTIAL"))
				#ifdef _O_SEQUENTIAL
					return _O_SEQUENTIAL;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_SHORT_LIVED"))
				#ifdef _O_SHORT_LIVED
					return _O_SHORT_LIVED;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_TEMPORARY"))
				#ifdef _O_TEMPORARY
					return _O_TEMPORARY;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_TEXT"))
				#ifdef _O_TEXT
					return _O_TEXT;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_TRUNC"))
				#ifdef _O_TRUNC
					return _O_TRUNC;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "O_WRONLY"))
				#ifdef _O_WRONLY
					return _O_WRONLY;
				#else
					goto not_there;
				#endif
		case 'S':
			if (strEQ(name, "S_IREAD"))
				#ifdef _S_IREAD
					return _S_IREAD;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "S_IWRITE"))
				#ifdef _S_IWRITE
					return _S_IWRITE;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "SH_DENYNO"))
				#ifdef _SH_DENYNO
					return _SH_DENYNO;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "SH_DENYRD"))
				#ifdef _SH_DENYRD
					return _SH_DENYRD;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "SH_DENYRW"))
				#ifdef _SH_DENYRW
					return _SH_DENYRW;
				#else
					goto not_there;
				#endif
			if (strEQ(name, "SH_DENYWR"))
				#ifdef _SH_DENYWR
					return _SH_DENYWR;
				#else
					goto not_there;
				#endif
			break;

		default:
			break;
	}

    errno = EINVAL;
    return 0;

not_there:
	errno = ENOENT;
	return 0;
}

/*-----------------------------------------------------------------------------
 */

MODULE = Win32::SharedFileOpen	PACKAGE = Win32::SharedFileOpen		

PROTOTYPES: ENABLE

#-------------------------------------------------------------------------------
#
# XS code to be converted to C code by xsubpp.
#

# Function to expose the C function constant() defined above.
# This is only intended to be used by AUTOLOAD() in the Perl module.

DWORD
_constant(sv, arg)
	PREINIT:
		STRLEN		len;
	INPUT:
		SV			*sv;
		const char	*name = SvPV(sv, len);
		int			arg
	CODE:
		RETVAL = constant(name, len, arg);
	OUTPUT:
		RETVAL

# Function to expose the Microsoft Visual C function _fsopen().
# This is only intended to be used by fsopen() in the Perl module. (We return
# the fileno() of the file stream opened here because it is easier to return an
# 'int' than a 'FILE *' and have to worry about whether it is a 'T_IN', a
# 'T_OUT' or a 'T_INOUT'. The Perl fsopen() effectively does an fdopen() on the
# file descriptor returned from here to get a Perl filehandle.)

int
_fsopen(file, mode, shflag)
		const char	*file;
		const char	*mode;
		int			shflag;

	PROTOTYPE: $$$

	PREINIT:
		FILE		*fp;

	CODE:
		RETVAL = ((fp = _fsopen(file, mode, shflag)) != NULL) ? fileno(fp) : -1;

	OUTPUT:
		RETVAL

# Function to expose the Microsoft Visual C function _sopen().
# This is only intended to be used by sopen() in the Perl module. (We return the
# file descriptor returned by _sopen() itself, and then effectively do an
# fdopen() in the Perl sopen() to get a Perl filehandle, rather than do an
# actual fdopen() here, because that would involve returning a 'FILE *' and
# having to worry about whether it is a 'T_IN', a 'T_OUT' or a 'T_INOUT'.)

int
_sopen(file, oflag, shflag, ...)
		const char	*file;
		int			oflag;
		int			shflag;

	PROTOTYPE: $$$;$

	PREINIT:
		int			pmode;

	CODE:
		if (items > 3) {
			pmode = SvIV(ST(3));
			RETVAL = _sopen(file, oflag, shflag, pmode);
		}
		else {
			RETVAL = _sopen(file, oflag, shflag);
		}

	OUTPUT:
		RETVAL

#-------------------------------------------------------------------------------
