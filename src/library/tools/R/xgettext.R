#  File src/library/tools/R/xgettext.R
#  Part of the R package, http://www.R-project.org
#
#  Copyright (C) 1995-2012 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/

xgettext <-
function(dir, verbose = FALSE, asCall = TRUE)
{
    dir <- file_path_as_absolute(dir)
    bn <- basename(dir)
    dir <- file.path(dir, "R")
    exts <- .make_file_exts("code")
    R_files <- list_files_with_exts(dir, exts)
    for(d in c("unix", "windows")) {
        OSdir <- file.path(dir, d)
        if(file_test("-d", OSdir))
            R_files <- c(R_files, list_files_with_exts(OSdir, exts))
    }
    if(bn == "base") {
        ## include loader files in R_HOME/share/R
        shdir <- file.path(dir, "../../../../share/R")
        R_files <- c(R_files, list_files_with_exts(shdir, exts))
    }
    out <- vector("list", length = length(R_files))
    names(out) <- R_files

    find_strings <- function(e) {
        find_strings2 <- function(e, suppress) {
            if(is.character(e)) {
                if(!suppress) strings <<- c(strings, e)
            } else if(is.call(e)) {
                if(is.name(e[[1L]])
                   && (as.character(e[[1L]])
                       %in% c("gettext", "gettextf"))) {
                    domain <- e[["domain"]]
                    suppress <- !is.null(domain) && !is.name(domain) && is.na(domain)
                    if(as.character(e[[1L]]) == "gettextf") {
                        e <- match.call(gettextf, e)
                        e <- e["fmt"] # just look at fmt arg
                    } else if(as.character(e[[1L]]) == "gettext" &&
                              !is.null(names(e))) {
                        e <- e[!(names(e) == "domain")] # remove domain arg
                    }
                }
                for(i in seq_along(e)) find_strings2(e[[i]], suppress)
            }
        }
        if(is.call(e)
           && is.name(e[[1L]])
           && (as.character(e[[1L]])
               %in% c("warning", "stop", "message", "packageStartupMessage",
                      "gettext", "gettextf"))) {
             domain <- e[["domain"]]
             suppress <- !is.null(domain) && !is.name(domain) && is.na(domain)
             ## remove named args
             if(!is.null(names(e)))
                 e <- e[!names(e) %in% c("call.", "immediate.", "domain")]
             if(asCall) {
                 if(!suppress) strings <<- c(strings, as.character(e)[-1L])
             } else for(i in seq_along(e)) find_strings2(e[[i]], suppress)
        } else if(is.recursive(e))
            for(i in seq_along(e)) Recall(e[[i]])
    }

    for(f in R_files) {
        if(verbose) message(gettextf("parsing '%s'", f), domain = NA)
        strings <- character()
        for(e in parse(file = f)) find_strings(e)
        ## strip leading and trailing white space
        strings <- sub("^[ \t\n]*", "", strings)
        strings <- sub("[ \t\n]*$", "", strings)
        out[[f]] <- structure(unique(strings), class="xgettext")
    }

    out[sapply(out, length) > 0L]
}

print.xgettext <-
function(x, ...)
{
    cat(x, sep="\n")
    invisible(x)
}

print.xngettext <-
function(x, ...)
{
    lapply(x, function(x)
           cat("\nmsgid        = ", x[1L],
               "\nmsgid_plural = ", x[2L],
               "\n", sep=""))
    invisible(x)
}

xngettext <-
function(dir, verbose = FALSE)
{
    dir <- file_path_as_absolute(dir)
    dir <- file.path(dir, "R")
    exts <- .make_file_exts("code")
    R_files <- list_files_with_exts(dir, exts)
    for(d in c("unix", "windows", "aqua")) {
        OSdir <- file.path(dir, d)
        if(file_test("-d", OSdir))
            R_files <- c(R_files, list_files_with_exts(OSdir, exts))
    }
    out <- vector("list", length = length(R_files))
    names(out) <- R_files

    find_strings <- function(e) {
        if(is.call(e) && is.name(e[[1L]])
           && as.character(e[[1L]]) %in% "ngettext") {
	    e <- match.call(ngettext, e)
	    if (is.character(e[["msg1"]]) && is.character(e[["msg2"]]))
	    	strings <<- c(strings, list(c(msg1=e[["msg1"]],
	    				      msg2=e[["msg2"]])))
        } else if(is.recursive(e))
            for(i in seq_along(e)) Recall(e[[i]])
    }

    for(f in R_files) {
        if(verbose) message(gettextf("parsing '%s'", f), domain = NA)
        strings <- list()
        for(e in parse(file = f)) find_strings(e)
        out[[f]] <- structure(strings, class="xngettext")
    }

    out[sapply(out, length) > 0L]
}

xgettext2pot <-
function(dir, potFile)
{
    dir <- file_path_as_absolute(dir)
    if(missing(potFile))
        potFile <- paste0("R-", basename(dir), ".pot")
    tmp <- unique(unlist(xgettext(dir, asCall = FALSE)))
    tmp <- tmp[nzchar(tmp)]
    if(length(tmp) > 0L)
	tmp <- shQuote(encodeString(tmp), type="cmd")  # need to quote \n, \t etc
    con <- file(potFile, "wt")
    on.exit(close(con))
    writeLines(con=con,
               c('msgid ""',
                 'msgstr ""',
                 sprintf('"Project-Id-Version: R %s.%s\\n"',
                         R.version$major, R.version$minor),
                 '"Report-Msgid-Bugs-To: bugs.r-project.org\\n"',
                 paste0('"POT-Creation-Date: ',
                        format(Sys.time(), "%Y-%m-%d %H:%M"), # %z is not portable
                        '\\n"'),
                 '"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"',
                 '"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"',
                 '"Language-Team: LANGUAGE <LL@li.org>\\n"',
                 '"MIME-Version: 1.0\\n"',
                 '"Content-Type: text/plain; charset=CHARSET\\n"',
                 '"Content-Transfer-Encoding: 8bit\\n"', ''))
    for(e in tmp)
        writeLines(con=con, c('', paste('msgid', e), 'msgstr ""'))
    tmp <- xngettext(dir)
    un <- unique(unlist(tmp, recursive=TRUE))
    for(ee in tmp)
        for(e in ee)
            if(e[1L] %in% un) {
                writeLines(con=con, c('',
                           paste('msgid       ',
                                 shQuote(encodeString(e[1L]), type="cmd")),
                           paste('msgid_plural',
                                 shQuote(encodeString(e[2L]), type="cmd")),
                           'msgstr[0]    ""', 'msgstr[1]    ""')
                           )
                un <- un[-match(e, un)]
            }
}

getfmts <- function(s) .Internal(getfmts(s))

checkPoFile <- function(f, strictPlural = FALSE)
{
    lines <- readLines(f, encoding = "bytes")
    i <- 0
    noCformat <- FALSE
    f1_plural <- NULL
    ref <- NA
    fuzzy <- FALSE

    result <- matrix(character(0), ncol = 5, nrow = 0)
    while (i < length(lines)) {
	i <- i + 1

	if (grepl("^#,", lines[i], useBytes = TRUE)) {
	    noCformat <- noCformat || grepl("no-c-format", lines[i], useBytes = TRUE)
	    fuzzy <- fuzzy || grepl("fuzzy", lines[i], useBytes = TRUE)
	} else if (grepl("^#:", lines[i], useBytes = TRUE)) {
	    if (!is.na(ref))
		ref <- paste(ref, "etc.")
	    else
		ref <- sub("^#:[[:blank:]]*", "", lines[i])
	} else if (grepl("^msgid ", lines[i], useBytes = TRUE)) {
	    s1 <- sub('^msgid[[:blank:]]+["](.*)["][[:blank:]]*$', "\\1", lines[i])
	    while (grepl('^["]', lines[i+1], useBytes = TRUE)) {
		i <- i + 1
		s1 <- paste0(s1, sub('^["](.*)["][[:blank:]]*$', "\\1", lines[i]))
	    }
	    f1 <- try(.Internal(getfmts(s1)), silent = TRUE)
	    j <- i + 1

	    if (noCformat || inherits(f1, "try-error")) {
		noCformat <- FALSE
		next
	    }

	    while (j <= length(lines)) {
		if (grepl("^msgid_plural[[:blank:]]", lines[j], useBytes = TRUE))
		    statement <- "msgid_plural"
		else if (grepl("^msgstr[[:blank:]]", lines[j], useBytes = TRUE))
		    statement <- "msgstr"
		else if (grepl("^msgstr\\[[[:digit:]]+\\][[:blank:]]", lines[j], useBytes = TRUE))
		    statement <- sub("^(msgstr)\\[([[:digit:]]+)\\].*$", "\\1\\\\[\\2\\\\]", lines[j])
		else
		    break

		s2 <- sub( paste0("^", statement, "[[:blank:]]+[\"](.*)[\"][[:blank:]]*$"),
		                 "\\1", lines[j])
		while (grepl('^["]', lines[j+1], useBytes = TRUE)) {
		    j <- j + 1
		    s2 <- paste0(s2, sub('^["](.*)["][[:blank:]]*$', "\\1", lines[j]))
		}

		if (s1 == "") { # The header
		    encoding <- sub(".*Content-Type:[^\\]*charset=([^\\[:space:]]*)[[:space:]]*\\\\n.*", "\\1", s2)
		    lines <- iconv(lines, encoding, "UTF-8")
		    break
		}

		f2 <- try(.Internal(getfmts(s2)), silent = TRUE)

		if (statement == "msgid_plural") {
		    if (!strictPlural) {
			f1_plural <- f2
			j <- j+1
			next
		    }
		}

		if (s2 != "" &&
		     !(identical(f1, f2) || identical(f1_plural, f2))) {
		    location <- paste0(f, ":", j)
		    if (inherits(f2, "try-error"))
			diff <- conditionMessage(attr(f2, "condition"))
		    else {
		    	if (length(f1) < length(f2)) {
			    diff <- "too many entries"
			    length(f2) <- length(f1)
		    	} else if (length(f1) > length(f2)) {
			    diff <- "too few entries"
			    length(f1) <- length(f2)
			} else
			    diff <- ""
			diffs <- which(f1 != f2)
			if (length(diffs)) {
			    if (diff != "")
			    	diff <- paste0(diff, ", ")
			    if (length(diffs) > 1)
				diff <- paste(paste0(diff, "differences in entries"),
			                      paste(diffs, collapse = ","))
			    else
				diff <- paste(paste0(diff, "difference in entry"),
				              diffs)
			}
			if (grepl("\u066A", s2, fixed=TRUE))
			    diff <- paste0(diff, ", translation contains arabic percent sign U+066A")
			if (grepl("\uFE6A", s2, fixed=TRUE))
			    diff <- paste0(diff, ", translation contains small percent sign U+FE6A")
			if (grepl("\uFF05", s2, fixed=TRUE))
			    diff <- paste0(diff, ", translation contains wide percent sign U+FF05")
		    }
                    if (!fuzzy)
                        result <- rbind(result, c(location, ref, diff, s1, s2))
		}
		j <- j+1
	    }
	    i <- j-1
	    noCformat <- FALSE
	    f1_plural <- NULL
	    ref <- NA
            fuzzy <- FALSE
	}
    }
    structure(result, class = "check_po_files")
}

checkPoFiles <- function(language, dir=".")
{
    files <- list.files(path = dir, pattern = paste0(language, "[.]po$"),
                        full.names = TRUE, recursive = TRUE)
    result <- matrix(character(0), ncol = 5, nrow = 0)
    for (f in files) {
	errs <- checkPoFile(f, strictPlural = grepl("^R-", basename(f)))
	if (nrow(errs) > 0) result <- rbind(result, errs)
    }
    structure(result, class = "check_po_files")
}

print.check_po_files <- function(x, ...)
{
    if (!nrow(x))
	cat("No errors\n")
    else
	for (i in 1:nrow(x)) {
	    if (is.na(x[i, 2])) cols <- c(1, 3:5)
	    else cols <- 1:5
	    cat(x[i, cols], sep = "\n")
	    cat("\n")
	}
}
