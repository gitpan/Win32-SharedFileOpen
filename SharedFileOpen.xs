/*============================================================================
 *
 * SharedFileOpen.xs
 *
 * DESCRIPTION
 *   C and XS portions of Win32::SharedFileOpen module.
 *
 * COPYRIGHT
 *   Copyright (c) 2001-2004, Steve Hay.  All rights reserved.
 *
 * LICENCE
 *   You may distribute under the terms of either the GNU General Public License
 *   or the Artistic License, as specified in the LICENCE file.
 *
 *============================================================================*/

/*============================================================================
 * C CODE SECTION
 *============================================================================*/

#include <io.h>                         /* For _sopen().                      */
#include <stdio.h>                      /* For _fsopen().                     */
#include <fcntl.h>                      /* For the O_* and _O_* flags.        */
#include <share.h>                      /* For the SH_DENY* flags.            */
#include <string.h>                     /* For strchr().                      */
#include <sys/stat.h>                   /* For the S_* flags.                 */

#define O_SHORT_LIVED _O_SHORT_LIVED    /* We export without leading "_".     */

#define WIN32_LEAN_AND_MEAN             /* Don't pull in too much crap when   */
                                        /* including <windows.h> next.        */
#include <windows.h>                    /* For the DWORD typedef (in          */
                                        /* <windef.h>) and the INFINITE flag  */
                                        /* (in <winbase.h>).                  */

#define PERL_NO_GET_CONTEXT             /* See the "perlguts" manpage.        */

/*
 * Note: We only support Perl 5.6.x upwards -- the Perl scripts and modules
 * (including "Makefile.PL") all enforce this with "use 5.006".
 *
 * The IoTYPE_* constants are not defined in Perl 5.6.0, so we provide suitable
 * definitions for them here.
 *
 * Under Perl 5.6.x "perl.h" includes "iperlsys.h", which in turn includes
 * "perlsdio.h" if PERL_IMPLICIT_SYS is not defined.  The latter provides
 * definitions for PerlIO, PerlIO_importFILE() and more on the basis that PerlIO
 * _is_ the original stdio, which it essentially is in Perl 5.6.x.  Later on in
 * "iperlsys.h" an "extern" declaration for PerlIO_importFILE() is provided if
 * it is not yet defined.  The result is that these symbols are declared
 * "extern" but never actually defined if PERL_IMPLICIT_SYS is enabled: we
 * therefore provide the standard "perlsdio.h" definitions for them here, i.e. a
 * "PerlIO *" _is_ a "FILE *", and PerlIO_importFILE() is a no-op macro.
 * Under Perl 5.8.0 a "real" PerlIO was introduced which raised questions
 * concerning the co-existence of PerlIO with the original stdio, which are
 * dealt with according to whether or not PERLIO_NOT_STDIO is defined and, if it
 * is, whether or not it is true.  (See the "perlapio" mangpage in Perl 5.8.0
 * for more details on this.)  The original stdio functions should now properly
 * be accessed via the PerlSIO_*() macros; these did not exist under earlier
 * versions of Perl, so we provide a suitable definition for the two such macros
 * that we use, namely, PerlSIO_fclose() and PerlSIO_fileno.  The lowio
 * functions should similarly be accessed via the PerlLIO_*() macros; these are
 * available in Perl 5.6.x anyway so we do not need to worry about the
 * PerlLIO_close() and PerlLIO_setmode() macros that we use.
 * See the exchanges between myself and Nick Ing-Simmons on the "perl-xs"
 * mailing list, 20-24 Jan 2003, for more details on all of this.
 */

#include "patchlevel.h"                 /* Get the version numbers first.     */

#if PERL_REVISION == 5
#  if PERL_VERSION == 6
#    if PERL_SUBVERSION == 0
#      define IoTYPE_RDONLY '<'
#      define IoTYPE_WRONLY '>'
#      define IoTYPE_RDWR   '+'
#      define IoTYPE_APPEND 'a'
#    endif
#    ifdef PERL_IMPLICIT_SYS
#      define PerlIO FILE
#      define PerlIO_importFILE(f, fl) (f)
#    endif
#    define PerlSIO_fclose(f) fclose(f)
#    define PerlSIO_fileno(f) fileno(f)
#  else if PERL_VERSION > 6
#    define PERLIO_NOT_STDIO 0
#  endif
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "const-c.inc"

static const char *_OFlagToBinMode(int oflag);
static const char *_ModeToBinMode(const char *mode);
static char _ModeToType(const char *mode);
static void _StorePerlIO(pTHX_ SV *fh, PerlIO **pio_fp, const char *mode);
static bool _Debug(pTHX);

/*
 * Function to convert an oflag understood by C lowio-level open functions to a
 * mode string understood by C stdio-level open functions, with the "binary"
 * mode character appended.
 */

static const char *_OFlagToBinMode(int oflag)
{
    const char *binmode;

    /* Note: We cannot check for the O_RDONLY bit being set in oflag because
     * its value is zero in Microsoft's C library (as is traditionally the case,
     * according to the "perlopentut" manpage), i.e. there are no bits set to
     * look for.  We therefore assume O_RDONLY if neither O_WRONLY nor O_RDWR
     * are set. */
    if (oflag & O_WRONLY)
        binmode = (oflag & O_APPEND) ? "ab"  : "wb";
    else if (oflag & O_RDWR)
        binmode = (oflag & O_CREAT ) ?
                 ((oflag & O_APPEND) ? "a+b" : "w+b") : "r+b";
    else
        binmode = "rb";

    return binmode;
}

/*
 * Function to force a mode string understood by C stdio-level open functions
 * into "binary" mode.
 */

static const char *_ModeToBinMode(const char *mode)
{
    const char *binmode;

    if (strchr(mode, 'r') != NULL)
        binmode = (strchr(mode, '+') != NULL) ? "r+b"  : "rb";
    else if (strchr(mode, 'w') != NULL)
        binmode = (strchr(mode, '+') != NULL) ? "w+b"  : "wb";
    else if (strchr(mode, 'a') != NULL)
        binmode = (strchr(mode, '+') != NULL) ? "a+b"  : "ab";
    else
        binmode = NULL;

    return binmode;
}

/*
 * Function to convert a mode string understood by C stdio-level open functions
 * to an integer type as defined in the Perl header file "sv.h".
 */

static char _ModeToType(const char *mode)
{
    if (strchr(mode, '+') != NULL)
        return IoTYPE_RDWR;
    else if (strchr(mode, 'r') != NULL)
        return IoTYPE_RDONLY;
    else if (strchr(mode, 'w') != NULL)
        return IoTYPE_WRONLY;
    else if (strchr(mode, 'a') != NULL)
        return IoTYPE_APPEND;
    else
        return -1;
}

/*
 * Function to store a PerlIO file stream (opened in a mode specified by a mode
 * string understood by C stdio-level open functions) in a glob's IO member.
 * Creates the IO member if it does not already exist.
 */

static void _StorePerlIO(pTHX_ SV *fh, PerlIO **pio_fp, const char *mode)
{
    IO *io;
    char type;

    /* Dereference fh to get the glob referred to, then get the IO member of
     * that glob, adding a new one if necessary. */
    io = GvIOn((GV *)SvRV(fh));

    /* Convert the stdio mode string to a type understood by Perl. */
    if ((type = _ModeToType(mode)) == -1) {
        PerlIO_close(*pio_fp);
        croak("Unknown mode '%s'", mode);
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
            /* Store the PerlIO file stream as the output stream.  Apparently it
             * must be stored as the input stream as well.  I don't know why. */
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

/*
 * Function to retrieve the Perl module's $Debug variable.
 */

static bool _Debug(pTHX) {
    /* Get the Perl module's global $Debug variable and coerce it into a
     * bool. */
    return SvTRUE(get_sv("Win32::SharedFileOpen::Debug", FALSE));
}

MODULE = Win32::SharedFileOpen PACKAGE = Win32::SharedFileOpen     

#===============================================================================
# XS CODE SECTION
#===============================================================================

PROTOTYPES:   ENABLE
VERSIONCHECK: ENABLE

INCLUDE: const-xs.inc

# Version 3.00 of this module had a bug whereby under Perl 5.8.0, if a file was
# opened in "text" mode by fsopen() then it could not subsequently be changed to
# "binary" mode.  The reason is that in Perl 5.8.0 a "real" PerlIO was
# introduced which applies IO "layers" on top of some "base" layer.  The "base"
# layer is determined by the mode of the "FILE *" that is initially imported
# into the "PerlIO *": layers can be pushed on top of that, and any layers that
# have been pushed on can be popped off again, but it is not possible to remove
# the "base" layer(s).  Thus, when a file is opened in "text" mode (with a
# ":crlf" layer), all we can do is push further layers on top and pop them off
# again; we can't remove the "text" mode base layer.
# This behaviour is a characteristic of PerlIO_importFILE(): the "PerlIO *"
# created by it potentially has a "text" mode base layer, when perhaps it would
# be better to always have a "binary" mode base layer with a "text" mode layer
# pushed on top if appropriate.  Later Perls may be changed to operate this way,
# but in order to get this working with Perl 5.8.0 we employ exactly that
# strategy here: thus, fsopen() has been modified to *always* set the "FILE *"
# to "binary" mode *before* it is imported into the "PerlIO *", and then push a
# "text" mode (":crlf") layer on top of that if "text" mode is what was actually
# asked for.  In that way the end user will now be able to remove that "text"
# mode layer, putting the file handle into "binary" mode, if desired.
# The intention was to call
#
#   PerlIO_binmode(pio_fp, type, O_TEXT, ":crlf")
#
# after PerlIO_importFILE() if the mode is not "binary", but as of Perl 5.8.0
# this fails to compile under Perls with PERL_IMPLICIT_SYS enabled (due, it is
# believed, to teething problems with stdio/PerlIO co-existence is such Perls),
# and the PerlIO_binmode() macro is not available under Perl 5.6.x anyway.  So
# instead the "text" mode layer is pushed onto the "PerlIO *" by calling the
# Perl built-in function binmode() back in the Perl module.
# The same philosophy has been applied to sopen() as well for the sake of
# consistency.  It didn't actually exhibit the same bug in version 3.00 anyway,
# probably due to differences between the PerlIO_fdopen() call that it makes and
# the PerlIO_importFILE() call that fsopen() makes; in particular it is possible
# that PerlIO_fdopen() already employs the "binary" base layer strategy outlined
# above.
# We also ensure that the "mode" argument passed to both PerlIO_importFILE() and
# PerlIO_fdopen() includes "b" (and not "t") to be sure that the "PerlIO *" that
# we initially create really is in binary mode (as opposed to just having a
# "binary" mode base layer).
#
# See the exchanges between myself and Nick Ing-Simmons on the "perl-xs" mailing# list, 20-24 Jan 2003, for more details on all of this.

# Private function to expose the Microsoft C library function _fsopen().

SV *
_fsopen(fh, file, mode, shflag)
    PROTOTYPE: *$$$

    INPUT:
        SV         *fh;
        const char *file;
        const char *mode;
        int        shflag;

    CODE:
    {
        int last_errno;
        DWORD last_error;
        FILE *fp;
        const char *binmode;
        PerlIO *pio_fp;

        /* Call the MSVC function _fsopen() to get a C file stream. */
        fp = _fsopen(file, mode, shflag);

        if (fp != Null(FILE *)) {
            /* Set the C file stream into "binary" mode if it wasn't opened that
             * way already.  (See comments above for why.) */
            if (strchr(mode, 'b') == NULL) {
                if (PerlLIO_setmode(PerlSIO_fileno(fp), O_BINARY) == -1) {
                    if (_Debug(aTHX))
                        warn("Could not set binary mode on C file stream for "
                             "file '%s'\n", file);
                }
            }

            /* Convert the stdio mode string to a stdio mode string in "binary"
             * mode. */
            if ((binmode = _ModeToBinMode(mode)) == NULL) {
                PerlSIO_fclose(fp);
                croak("Unknown mode '%s'", mode);
            }

            /* Call the Perl API function PerlIO_importFILE() to get a PerlIO
             * file stream.  Use the new "binary" mode string to be sure that it
             * is still in "binary" mode. */
            pio_fp = PerlIO_importFILE(fp, binmode);

            if (pio_fp != Nullfp) {
                /* Store the PerlIO file stream in the IO member of the supplied
                 * glob (i.e. the Perl filehandle (or indirect filehandle)
                 * passed to us). */
                _StorePerlIO(aTHX_ fh, &pio_fp, binmode);

                RETVAL = &PL_sv_yes;
            }
            else {
                if (_Debug(aTHX))
                    warn("Perl API function PerlIO_importFILE(%s, \"%s\") "
                         "failed for file '%s'\n", "fp", binmode, file);

                /* Close the C file stream before returning, making sure that we
                 * don't affect the value of the errno or last-error
                 * variables. */
                last_errno = errno;
                last_error = GetLastError();
                PerlSIO_fclose(fp);
                errno = last_errno;
                SetLastError(last_error);

                RETVAL = &PL_sv_no;
            }
        }
        else {
            if (_Debug(aTHX))
                warn("MSVC function _fsopen(\"%s\", \"%s\", %d) failed\n", file,
                     mode, shflag);

            RETVAL = &PL_sv_no;
        }
    }

    OUTPUT:
        RETVAL

# Private function to expose the Microsoft C library function _sopen().

SV *
_sopen(fh, file, oflag, shflag, ...)
    PROTOTYPE: *$$$;$

    INPUT:
        SV         *fh;
        const char *file;
        int        oflag;
        int        shflag;

    CODE:
    {
        int last_errno;
        DWORD last_error;
        int pmode;
        int fd;
        const char *binmode;
        PerlIO *pio_fp;

        /* Call the MSVC function _sopen() to get a C file descriptor. */
        if (items > 4) {
            pmode = SvIV(ST(4));
            fd = _sopen(file, oflag, shflag, pmode);
        }
        else {
            fd = _sopen(file, oflag, shflag);
        }

        if (fd != -1) {
            /* Set the C file descriptor into "binary" mode if it wasn't opened
             * that way already.  (See comments above _fsopen() for why.) */
            if (!(oflag & O_BINARY)) {
                if (PerlLIO_setmode(fd, O_BINARY) == -1) {
                    if (_Debug(aTHX))
                        warn("Could not set binary mode on C file stream for "
                             "file '%s'\n", file);
                }
            }

            /* Convert the lowio oflag to a stdio mode string in "binary"
             * mode. */
            binmode = _OFlagToBinMode(oflag);

            /* Call the Perl API function PerlIO_fdopen() to get a PerlIO file
             * stream.  Use the new "binary" mode string to be sure that it is
             * still in "binary" mode. */
            pio_fp = PerlIO_fdopen(fd, binmode);

            if (pio_fp != Nullfp) {
                /* Store the PerlIO file stream in the IO member of the supplied
                 * glob (i.e. the Perl filehandle (or indirect filehandle)
                 * passed to us). */
                _StorePerlIO(aTHX_ fh, &pio_fp, binmode);

                RETVAL = &PL_sv_yes;
            }
            else {
                if (_Debug(aTHX))
                    warn("Perl API function PerlIO_fdopen(%d, \"%s\") failed "
                         "for file '%s'\n", fd, binmode, file);

                /* Close the C file descriptor before returning, making sure
                 * that we don't affect the value of the errno or last-error
                 * variables. */
                last_errno = errno;
                last_error = GetLastError();
                PerlLIO_close(fd);
                errno = last_errno;
                SetLastError(last_error);

                RETVAL = &PL_sv_no;
            }
        }
        else {
            if (_Debug(aTHX))
                if (items > 4)
                    warn("MSVC function _sopen(\"%s\", %d, %d, %d) failed\n",
                         file, oflag, shflag, pmode);
                else
                    warn("MSVC function _sopen(\"%s\", %d, %d) failed\n",
                         file, oflag, shflag);

            RETVAL = &PL_sv_no;
        }
    }

    OUTPUT:
        RETVAL

#===============================================================================
