/*------------------------------------------------------------------------------
 * Copyright (c) 2001-2002, Steve Hay. All rights reserved.
 *
 * Module Name:	Win32::SharedFileOpen
 * Source File:	SharedFileOpen.xs
 * Description:	C and XS code for xsubpp
 *------------------------------------------------------------------------------
 */

/*------------------------------------------------------------------------------
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

#define PERL_NO_GET_CONTEXT				/* See the "perlguts" manpage.		*/
#define PERLIO_NOT_STDIO	0			/* See the "perlapio" manpage.		*/
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

/*
 * Function to retrieve the Perl module's $Debug variable.
 */

static int debug(void) {
	/* Get the Perl module's global $Debug variable and coerce it into an int.
	 * (This coercion should not produce any nasty surprises because $Debug is
	 * tie()'d to a class that only allows integer values.) */
	return SvIV(get_sv("Win32::SharedFileOpen::Debug", FALSE));
}

/*
 * Function to store a PerlIO file stream (opened in a mode specified in a form
 * understood by C "stdio"-level open functions) in a glob's IO member.
 * Creates the IO member if it does not already exist.
 */

static void storePerlIO(pTHX_ SV *fh, PerlIO **pio_fp, const char *mode) {
	IO		*io;
	char	type;

	/* Dereference fh to get the glob referred to, then get the IO member of
	 * that glob, adding a new one if necessary. */
	io = GvIOn((GV *)SvRV(fh));

	/* Convert the mode understood by C "stdio"-level open functions to a type
	 * defined in the Perl header file "sv.h".
	 * Note that Microsoft Visual C's file open modes can include 't' and 'b'
	 * characters for "text" and "binary" mode respectively as well as the usual
	 * 'r', 'w', 'a' and '+' characters. The mode must contain exactly one of
	 * the characters 'r', 'w' or 'a', and that character must be first. */
	if (mode[1] != '\0' && strchr(mode + 1, '+') != NULL)
		type = IoTYPE_RDWR;
	else
		switch (mode[0]) {
			case 'r':
				type = IoTYPE_RDONLY;
				break;
			case 'w':
				type = IoTYPE_WRONLY;
				break;
			case 'a':
				type = IoTYPE_APPEND;
				break;
			default:
				PerlIO_close(*pio_fp);
				croak("Unknown mode '%s'", mode);
				break;
		}

	/* Store this type in the glob's IO member. */
	IoTYPE(io) = type;

	/* Store the PerlIO file stream in the glob's IO member. */
	switch (type) {
		case IoTYPE_RDONLY:
			/* Store the PerlIO file stream as the input stream. */
			IoIFP(io) = *pio_fp;
			break;

		case IoTYPE_WRONLY:
		case IoTYPE_APPEND:
			/* Store the PerlIO file stream as the output stream. Apparently it
			 * must be stored as the input stream as well. I don't know why. */
			IoIFP(io) = *pio_fp;
			IoOFP(io) = *pio_fp;
			break;

		case IoTYPE_RDWR:
			/* Store the PerlIO file stream as both the input stream and the
			 * output stream. */
			IoIFP(io) = *pio_fp;
			IoOFP(io) = *pio_fp;
			break;

		default:
			PerlIO_close(*pio_fp);
			croak("Unknown IoTYPE '%d'", type);
			break;
	}
}

/*------------------------------------------------------------------------------
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
# This is only intended to be used by fsopen() in the Perl module.

SV *
_fsopen(fh, file, mode, shflag)
		SV			*fh;
		const char	*file;
		const char	*mode;
		int			shflag;

	PROTOTYPE: *$$$

	PREINIT:
		int			last_errno;
		DWORD		last_error;
		FILE		*fp;
		PerlIO		*pio_fp;

	CODE:
		# Call the MSVC function _fsopen() to get a C file stream.
		fp = _fsopen(file, mode, shflag);

		if (fp != Null(FILE *)) {
			# Call the Perl API function PerlIO_importFILE() to get a PerlIO
			# file stream.
			pio_fp = PerlIO_importFILE(fp, mode);

			if (pio_fp != Nullfp) {
				# Store the PerlIO file stream in the IO member of the supplied
				# glob (i.e. the Perl filehandle (or indirect filehandle) passed
				# to us).
				storePerlIO(aTHX_ fh, &pio_fp, mode);

				# Return success.
				RETVAL = &PL_sv_yes;
			}
			else {
				if (debug() > 1)
					fprintf(stderr, "Perl API function PerlIO_importFILE(%s, "
							"\"%s\") failed for file '%s'\n", "fp", mode, file);

				# Close the C file stream before returning, making sure that we
				# don't affect the value of the errno or last-error variables.
				last_errno = errno;
				last_error = GetLastError();
				fclose(fp);
				errno = last_errno;
				SetLastError(last_error);

				# Return failure.
				RETVAL = &PL_sv_no;
			}
		}
		else {
			if (debug() > 1)
				fprintf(stderr, "MSVC function _fsopen(\"%s\", \"%s\", %d) "
						"failed\n", file, mode, shflag);

			# Return failure.
			RETVAL = &PL_sv_no;
		}

	OUTPUT:
		fh
		RETVAL

# Function to expose the Microsoft Visual C function _sopen().
# This is only intended to be used by sopen() in the Perl module.

SV *
_sopen(fh, file, oflag, shflag, ...)
		SV			*fh;
		const char	*file;
		int			oflag;
		int			shflag;

	PROTOTYPE: *$$$;$

	PREINIT:
		int			last_errno;
		DWORD		last_error;
		int			pmode;
		int			fd;
		const char	*mode;
		PerlIO		*pio_fp;

	CODE:
		# Call the MSVC function _sopen() to get a C file descriptor.
		if (items > 4) {
			pmode = SvIV(ST(4));
			fd = _sopen(file, oflag, shflag, pmode);
		}
		else {
			fd = _sopen(file, oflag, shflag);
		}

		if (fd != -1) {
			# Call the Perl API function PerlIO_fdopen() to get a PerlIO file
			# stream.

			# First convert the oflag understood by the MSVC function _sopen()
			# to a mode understood by the C function fdopen().
			# We cannot explicitly test for O_RDONLY because it is 0 on MSVC (as
			# is traditionally the case, according to the "perlopentut"
			# manpage), i.e. there are no bits set to look for. Therefore assume
			# O_RDONLY if neither O_WRONLY nor O_RDWR are set.
			if (oflag & O_WRONLY)
				mode = (oflag & O_APPEND) ? "a"  : "w";
			else if (oflag & O_RDWR)
				mode = (oflag & O_CREAT ) ?
					  ((oflag & O_APPEND) ? "a+" : "w+") : "r+";
			else
				mode = "r";

			pio_fp = PerlIO_fdopen(fd, mode);

			if (pio_fp != Nullfp) {
				# Store the PerlIO file stream in the IO member of the supplied
				# glob (i.e. the Perl filehandle (or indirect filehandle) passed
				# to us).
				storePerlIO(aTHX_ fh, &pio_fp, mode);

				# Return success.
				RETVAL = &PL_sv_yes;
			}
			else {
				if (debug() > 1)
					fprintf(stderr, "Perl API function PerlIO_fdopen(%d, "
							"\"%s\") failed for file '%s'\n", fd, mode, file);

				# Close the C file descriptor before returning, making sure that
				# we don't affect the value of the errno or last-error
				# variables.
				last_errno = errno;
				last_error = GetLastError();
				close(fd);
				errno = last_errno;
				SetLastError(last_error);

				# Return failure.
				RETVAL = &PL_sv_no;
			}
		}
		else {
			if (debug() > 1)
				if (items > 4)
					fprintf(stderr, "MSVC function _sopen(\"%s\", %d, %d, %d) "
							"failed\n", file, oflag, shflag, pmode);
				else
					fprintf(stderr, "MSVC function _sopen(\"%s\", %d, %d) "
							"failed\n", file, oflag, shflag);

			# Return failure.
			RETVAL = &PL_sv_no;
		}

	OUTPUT:
		fh
		RETVAL

#if defined(_DEBUG) && PERL_VERSION >= 7

## Function to demonstrate how 06_fsopen_access.t test 29 fails on Perl 5.8.0.
## After fopen()'ing a FILE stream in text mode and then getting a PerlIO stream
## by calling PerlIO_importFILE() with the same mode, any attempt to change to
## binary mode, either by calling the Perl builtin function binmode() on a Perl
## filehandle which the PerlIO stream has been associated with (as in the above-
## cited test) or by calling PerlIO_binmode() directly on the PerlIO stream (as
## done here) doesn't work, although all the function calls return success. The
## file created wrongly ends with \cM\cJ instead of just \cJ.
##
## Interestingly, if the PerlIO_binmode() call is changed to put the file stream
## into text mode (even though it is already):
## 		if (PerlIO_binmode(p, type, O_TEXT, ":crlf") != 1)
## then the file created ends with \cM\cM\cJ, and if the above call is repeated
## then we get \cM\cM\cM\cJ. In other words the PerlIO_binmode() function is
## pushing IO layers onto a stack so that we end up converting \n to \cM\cJ
## multiple times over, once from the original file stream's layers and once
## more for each layer we have pushed.
##
## Is it possible, then, that the attempt to put the file stream into binary
## mode simply pushes a ":raw" (or maybe ":perlio") layer onto the stack, but
## doesn't remove the original file stream's layers? In this case the
## PerlIO_binmode() function has succeeded (... in pushing another IO layer onto
## the stack), and we now have two layers: the original file stream's layer that
## does text mode conversions followed by another layer which does "nothing",
## the result of which is clearly that text mode conversions *are* being done.
##
## Question: If the above conclusions are correct then how do we *remove* the
## existing text mode conversion layer from the stack in order to get the binary
## mode that we require?
##
## TODO: Determine exactly what is going on here and hence fix the bug in
## fsopen() highlighted by the test suite failure referred to above.

void
_testme(file)
		const char	*file;

	PROTOTYPE: $

	PREINIT:
		const char	type  = '>';
		const char	*mode = "w";
		FILE		*f;
		PerlIO		*p;

	CODE:
		if ((f = fopen(file, mode)) != Null(FILE *)) {
			if ((p = PerlIO_importFILE(f, mode)) != Nullfp) {
				if (PerlIO_binmode(p, type, O_BINARY, Nullch) != 1)
					fprintf(stderr, "PerlIO_binmode() failed\n");
				if (PerlIO_printf(p, "Hello, world.\n") < 0)
					fprintf(stderr, "PerlIO_printf() failed\n");
				if (PerlIO_close(p) != 0)
					fprintf(stderr, "PerlIO_close() failed\n");
			}
			else {
				fprintf(stderr, "PerlIO_importFILE() failed\n");
			}
		}
		else {
			fprintf(stderr, "fopen() failed\n");
		}

#endif

#-------------------------------------------------------------------------------
