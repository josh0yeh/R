% File src/library/base/man/Foreign.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2012 R Core Team
% Distributed under GPL 2 or later

\name{Foreign}
\alias{Foreign}
\alias{.C}
\alias{.Fortran}
\title{Foreign Function Interface}
\description{
  Functions to make calls to compiled code that has been loaded into \R.
}
\usage{
       .C(.NAME, \dots, NAOK = FALSE, DUP = TRUE, PACKAGE, ENCODING)
 .Fortran(.NAME, \dots, NAOK = FALSE, DUP = TRUE, PACKAGE, ENCODING)
}
\arguments{
  \item{.NAME}{a character string giving the name of a C function or
    Fortran subroutine, or an object of class
    \code{"\link{NativeSymbolInfo}"}, \code{"\link{RegisteredNativeSymbol}"}
    or \code{"\link{NativeSymbol}"} referring to such a name.}
  \item{\dots}{arguments to be passed to the foreign function.  Up to 65.}
  \item{NAOK}{if \code{TRUE} then any \code{\link{NA}} or
    \code{\link{NaN}} or \code{\link{Inf}} values in the arguments are
    passed on to the foreign function.  If \code{FALSE}, the presence of
    \code{NA} or \code{NaN} or \code{Inf} values is regarded as an error.}
  \item{DUP}{if \code{TRUE} then arguments are duplicated before
    their address is passed to C or Fortran.}
  \item{PACKAGE}{if supplied, confine the search for a character string
    \code{.NAME} to the DLL given by this argument (plus the
    conventional extension, \file{.so}, \file{.dll}, \dots).

    This is intended to add safety for packages, which can ensure by
    using this argument that no other package can override their external
    symbols, and also speeds up the search (see \sQuote{Note}).}
  
  \item{ENCODING}{optional name for an encoding to be assumed for
    character vectors.  Allowed but ignored for \code{.Fortran},
    deprecated for \code{.C}.  See \sQuote{Details}.}
}

\details{
  These functions can be used to make calls to compiled C and Fortran 77
  code.  Later interfaces are \code{\link{.Call}} and
  \code{\link{.External}} which are more flexible and have better
  performance.

  Character strings will be translated from the value of \code{ENCODING}
  or any declared encoding (see \code{\link{Encoding}}) to the current
  locale before being passed to the compiled C code.  They will be
  returned encoded in the current locale unless \code{ENCODING} was
  specified, when the output strings are translated to the specified
  encoding.  This is deprecated: convert code to use \code{\link{iconv}}.
  
  These functions are \link{primitive}, and \code{.NAME} is always
  matched to the first argument supplied (which should not be named and
  there will be a warning if it is---and an error in future.).
  The other named arguments follow \code{\dots} and so cannot be
  abbreviated.  For clarity, should avoid using names in the arguments
  passed to \code{\dots} that match or partially match \code{.NAME}.
}

\value{
  A list similar to the \code{\dots} list of arguments passed in
  (including any names given to the arguments), but reflecting any
  changes made by the C or Fortran code.
}

\section{Argument types}{
  The mapping of the types of \R arguments to C or Fortran arguments is

  \tabular{lll}{
    \R \tab     C \tab     Fortran\cr
    integer \tab int * \tab integer\cr
    numeric \tab double * \tab double precision\cr
    -- or -- \tab float * \tab real\cr
    complex \tab Rcomplex * \tab double complex\cr
    logical \tab int * \tab integer \cr
    character \tab char ** \tab [see below]\cr
    raw \tab unsigned char * \tab not allowed\cr
    list \tab SEXP *\tab not allowed\cr
    other \tab SEXP\tab not allowed\cr
  }

  Numeric vectors in \R will be passed as type \code{double *} to C (and
  as \code{double precision} to Fortran) unless (i) \code{DUP} is true
  and (ii) the argument has attribute \code{Csingle} set to \code{TRUE}
  (use \code{\link{as.single}} or \code{\link{single}}).  This mechanism
  is only intended to be used to facilitate the interfacing of existing
  C and Fortran code.

  The C type \code{Rcomplex} is defined in \file{Complex.h} as a
  \code{typedef struct {double r; double i;}}.  It may or may not be
  equivalent to the C99 \code{double complex} type, depending on the
  compiler used.

  Logical values are sent as \code{0} (\code{FALSE}), \code{1}
  (\code{TRUE}) or \code{INT_MIN = -2147483648} (\code{NA}, but only if
  \code{NAOK = TRUE}), and the compiled code should return one of these
  three values: however non-zero values other than \code{INT_MIN} are
  mapped to \code{TRUE}.

  \emph{Note:} The C types corresponding to \code{integer} and
  \code{logical} are \code{int}, not \code{long} as in S.  This
  difference matters on most 64-bit platforms, where \code{int} is
  32-bit and \code{long} is 64-bit (but not on 64-bit Windows).
  
  \emph{Note:} The Fortran type corresponding to \code{logical} is
  \code{integer}, not \code{logical}: the difference matters on some
  Fortran compilers.
  
  Missing (\code{NA}) string values are passed to \code{.C} as the string
  "NA". As the C \code{char} type can represent all possible bit patterns
  there appears to be no way to distinguish missing strings from the
  string \code{"NA"}.  If this distinction is important use \code{\link{.Call}}.

  \code{.Fortran} passes the first (only )character string of a character
  vector is passed as a C character array to Fortran: that may be usable
  as \code{character*255} if its true length is passed separately.  Only
  up to 255 characters of the string are passed back.  (How well this
  works, and even if it works at all, depends on the C and Fortran
  compilers and the platform.)
  
  Lists, functions are other \R objects can (for historical reasons) be
  passed to \code{.C}, but the \code{\link{.Call}} interface is much
  preferred.  All inputs apart from atomic vectors should be regarded as
  read-only, and all apart from vectors (including lists), functions and
  environments are now deprecated.
}
%%-- This note by Thomas Lumley, (minimally edited by MM,
%%      edited by BDR for 1.2.0's non-moving garbage collector):
\section{Warning}{
  \emph{\code{DUP = FALSE} is dangerous.}

  People concerned about memory usage are strongly recommended to use
  the \code{\link{.Call}} interface instead of these interfaces.

  If you pass a local variable to \code{.C}/\code{.Fortran} with
  \code{DUP = FALSE}, your compiled code can alter the local variable and
  not just the copy in the return list.  Worse, if you pass a local
  variable that is a formal parameter of the calling function, you may
  be able to change not only the local variable but the variable one
  level up.  This will be very hard to trace.

  Character vectors cannot be used with \code{DUP = FALSE}.

  It is safe and useful to set \code{DUP = FALSE} if you do not change any
  of the variables that might be affected, e.g.,

  \code{.C("Cfunction", input = x, output = numeric(10))}.

  In this case the \code{output} variable did not exist before the call
  so it cannot cause trouble (but as from \R 2.15.1 it is not copied
  even with \code{DUP = TRUE}).  If the \code{input} variable is not
  changed in the C code of \code{Cfunction} you are safe.

  Note that if \code{DUP = TRUE} there are up to two copies involved.
  Prior to \R 2.15.1 this was always the case for vectors (one before
  calling the compiled code and one to collect the results), and this is
  still the case for character vectors.  For other atomic vectors, the
  argument is not copied before calling the compiled code if it is not
  otherwise used in the calling code (such as \code{output} in the
  example above).  Non-atomic-vector objects are read-only to the C code
  and are never copied.
}

\section{Fortran symbol names}{
  All Fortran compilers known to be usable to compile \R map symbol names
  to lower case, and so does \code{.Fortran}.

  Symbol names containing underscores are not valid Fortran 77 (although
  they are valid in Fortran 9x).  Many Fortran 77 compilers will allow
  them but may translate them in a different way to names not containing
  underscores.  Such names will often work with \code{.Fortran} (since
  how they are translated is detected when \R is built and the
  information used by \code{.Fortran}), but portable code should not use
  Fortran names containing underscores.

  Use \code{.Fortran} with care for compiled Fortran 9x code: it may not
  work if the Fortran 9x compiler used differs from the Fortran 77 compiler
  used when configuring \R, especially if the subroutine name is not
  lower-case or includes an underscore.  It is also possible to use
  \code{.C} and do any necessary symbol-name translation yourself.
}

\note{
  If one of these functions is to be used frequently, do specify
  \code{PACKAGE} (to confine the search to a single DLL) or pass
  \code{.NAME} as one of the native symbol objects.  Searching for
  symbols can take a long time, especially when many namespaces are loaded.
  
  You may see \code{PACKAGE = "base"} for symbols linked into \R.  Do
  not use this in your own code: such symbols are not part of the API
  and may be changed without warning.
  
  \code{PACKAGE = ""} is accepted, but will become an error in \R 2.16.0.
  
  The way \link{pairlist}s were passed by \code{.C} prior to \R 2.15.0
  was not as documented.  This has been corrected, but the
  \code{\link{.Call}} and \code{\link{.External}} interfaces are much
  preferred for passing anything other than atomic vectors.
}

\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.
}
\seealso{
  \code{\link{dyn.load}}, \code{\link{.Call}}.

  The \sQuote{Writing R Extensions} manual.
}
\keyword{programming}
