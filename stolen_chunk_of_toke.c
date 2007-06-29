/*    stolen_chunk_of_toke.c - from perl 5.8.8 toke.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
 *    2000, 2001, 2002, 2003, 2004, 2005, 2006, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *   "It all comes from here, the stench and the peril."  --Frodo
 */

/*
 *   this is all blatantly stolen. I sincerely hopes it doesn't fuck anything
 *   up but if it does blame me (Matt S Trout), not the poor original authors
 */

/* the following #defines are stolen from assorted headers, not toke.c */

#define DPTR2FPTR(t,p) ((t)PTR2nat(p))  /* data pointer to function pointer */
#define FPTR2DPTR(t,p) ((t)PTR2nat(p))  /* function pointer to data pointer */
#define MEM_WRAP_CHECK_(n,t) MEM_WRAP_CHECK(n,t),
#define Newx(v,n,t) (v = (MEM_WRAP_CHECK_(n,t) (t*)safemalloc((MEM_SIZE)((n)*sizeof(t)))))


#define LEX_NORMAL    10 /* normal code (ie not within "...")     */
#define LEX_INTERPNORMAL   9 /* code within a string, eg "$foo[$x+1]" */
#define LEX_INTERPCASEMOD  8 /* expecting a \U, \Q or \E etc          */
#define LEX_INTERPPUSH     7 /* starting a new sublex parse level     */
#define LEX_INTERPSTART    6 /* expecting the start of a $var         */

           /* at end of code, eg "$x" followed by:  */
#define LEX_INTERPEND    5 /* ... eg not one of [, { or ->          */
#define LEX_INTERPENDMAYBE   4 /* ... eg one of [, { or ->              */

#define LEX_INTERPCONCAT   3 /* expecting anything, eg at start of
                string or after \E, $foo, etc       */
#define LEX_INTERPCONST    2 /* NOT USED */
#define LEX_FORMLINE     1 /* expecting a format line               */
#define LEX_KNOWNEXT     0 /* next token known; just return it      */

static const char ident_too_long[] =
  "Identifier too long";
static const char c_without_g[] =
  "Use of /c modifier is meaningless without /g";
static const char c_in_subst[] =
  "Use of /c modifier is meaningless in s///";

#ifdef USE_UTF8_SCRIPTS
#   define UTF (!IN_BYTES)
#else
#   define UTF ((PL_linestr && DO_UTF8(PL_linestr)) || (PL_hints & HINT_UTF8))
#endif

/* Invoke the idxth filter function for the current rsfp.	 */
/* maxlen 0 = read one text line */
I32
Perl_filter_read(pTHX_ int idx, SV *buf_sv, int maxlen)
{
    filter_t funcp;
    SV *datasv = NULL;

    if (!PL_rsfp_filters)
	return -1;
    if (idx > AvFILLp(PL_rsfp_filters)) {       /* Any more filters?	*/
	/* Provide a default input filter to make life easy.	*/
	/* Note that we append to the line. This is handy.	*/
	DEBUG_P(PerlIO_printf(Perl_debug_log,
			      "filter_read %d: from rsfp\n", idx));
	if (maxlen) {
 	    /* Want a block */
	    int len ;
	    const int old_len = SvCUR(buf_sv);

	    /* ensure buf_sv is large enough */
	    SvGROW(buf_sv, (STRLEN)(old_len + maxlen)) ;
	    if ((len = PerlIO_read(PL_rsfp, SvPVX(buf_sv) + old_len, maxlen)) <= 0){
		if (PerlIO_error(PL_rsfp))
	            return -1;		/* error */
	        else
		    return 0 ;		/* end of file */
	    }
	    SvCUR_set(buf_sv, old_len + len) ;
	} else {
	    /* Want a line */
            if (sv_gets(buf_sv, PL_rsfp, SvCUR(buf_sv)) == NULL) {
		if (PerlIO_error(PL_rsfp))
	            return -1;		/* error */
	        else
		    return 0 ;		/* end of file */
	    }
	}
	return SvCUR(buf_sv);
    }
    /* Skip this filter slot if filter has been deleted	*/
    if ( (datasv = FILTER_DATA(idx)) == &PL_sv_undef) {
	DEBUG_P(PerlIO_printf(Perl_debug_log,
			      "filter_read %d: skipped (filter deleted)\n",
			      idx));
	return FILTER_READ(idx+1, buf_sv, maxlen); /* recurse */
    }
    /* Get function pointer hidden within datasv	*/
    funcp = DPTR2FPTR(filter_t, IoANY(datasv));
    DEBUG_P(PerlIO_printf(Perl_debug_log,
			  "filter_read %d: via function %p (%s)\n",
			  idx, datasv, SvPV_nolen_const(datasv)));
    /* Call function. The function is expected to 	*/
    /* call "FILTER_READ(idx+1, buf_sv)" first.		*/
    /* Return: <0:error, =0:eof, >0:not eof 		*/
    return (*funcp)(aTHX_ idx, buf_sv, maxlen);
}

STATIC char *
S_filter_gets(pTHX_ register SV *sv, register PerlIO *fp, STRLEN append)
{
#ifdef PERL_CR_FILTER
    if (!PL_rsfp_filters) {
	filter_add(S_cr_textfilter,NULL);
    }
#endif
    if (PL_rsfp_filters) {
	if (!append)
            SvCUR_set(sv, 0);	/* start with empty line	*/
        if (FILTER_READ(0, sv, 0) > 0)
            return ( SvPVX(sv) ) ;
        else
	    return Nullch ;
    }
    else
        return (sv_gets(sv, fp, append));
}

/*
 * S_skipspace
 * Called to gobble the appropriate amount and type of whitespace.
 * Skips comments as well.
 */

STATIC char *
S_skipspace(pTHX_ register char *s)
{
    if (PL_lex_formbrack && PL_lex_brackets <= PL_lex_formbrack) {
	while (s < PL_bufend && SPACE_OR_TAB(*s))
	    s++;
	return s;
    }
    for (;;) {
	STRLEN prevlen;
	SSize_t oldprevlen, oldoldprevlen;
	SSize_t oldloplen = 0, oldunilen = 0;
	while (s < PL_bufend && isSPACE(*s)) {
	    if (*s++ == '\n' && PL_in_eval && !PL_rsfp)
		incline(s);
	}

	/* comment */
	if (s < PL_bufend && *s == '#') {
	    while (s < PL_bufend && *s != '\n')
		s++;
	    if (s < PL_bufend) {
		s++;
		if (PL_in_eval && !PL_rsfp) {
		    incline(s);
		    continue;
		}
	    }
	}

	/* only continue to recharge the buffer if we're at the end
	 * of the buffer, we're not reading from a source filter, and
	 * we're in normal lexing mode
	 */
	if (s < PL_bufend || !PL_rsfp || PL_sublex_info.sub_inwhat ||
		PL_lex_state == LEX_FORMLINE)
	    return s;

	/* try to recharge the buffer */
	if ((s = filter_gets(PL_linestr, PL_rsfp,
			     (prevlen = SvCUR(PL_linestr)))) == Nullch)
	{
	    /* end of file.  Add on the -p or -n magic */
	    if (PL_minus_p) {
		sv_setpv(PL_linestr,
			 ";}continue{print or die qq(-p destination: $!\\n);}");
		PL_minus_n = PL_minus_p = 0;
	    }
	    else if (PL_minus_n) {
		sv_setpvn(PL_linestr, ";}", 2);
		PL_minus_n = 0;
	    }
	    else
		sv_setpvn(PL_linestr,";", 1);

	    /* reset variables for next time we lex */
	    PL_oldoldbufptr = PL_oldbufptr = PL_bufptr = s = PL_linestart
		= SvPVX(PL_linestr);
	    PL_bufend = SvPVX(PL_linestr) + SvCUR(PL_linestr);
	    PL_last_lop = PL_last_uni = Nullch;

	    /* Close the filehandle.  Could be from -P preprocessor,
	     * STDIN, or a regular file.  If we were reading code from
	     * STDIN (because the commandline held no -e or filename)
	     * then we don't close it, we reset it so the code can
	     * read from STDIN too.
	     */

	    if (PL_preprocess && !PL_in_eval)
		(void)PerlProc_pclose(PL_rsfp);
	    else if ((PerlIO*)PL_rsfp == PerlIO_stdin())
		PerlIO_clearerr(PL_rsfp);
	    else
		(void)PerlIO_close(PL_rsfp);
	    PL_rsfp = Nullfp;
	    return s;
	}

	/* not at end of file, so we only read another line */
	/* make corresponding updates to old pointers, for yyerror() */
	oldprevlen = PL_oldbufptr - PL_bufend;
	oldoldprevlen = PL_oldoldbufptr - PL_bufend;
	if (PL_last_uni)
	    oldunilen = PL_last_uni - PL_bufend;
	if (PL_last_lop)
	    oldloplen = PL_last_lop - PL_bufend;
	PL_linestart = PL_bufptr = s + prevlen;
	PL_bufend = s + SvCUR(PL_linestr);
	s = PL_bufptr;
	PL_oldbufptr = s + oldprevlen;
	PL_oldoldbufptr = s + oldoldprevlen;
	if (PL_last_uni)
	    PL_last_uni = s + oldunilen;
	if (PL_last_lop)
	    PL_last_lop = s + oldloplen;
	incline(s);

	/* debugger active and we're not compiling the debugger code,
	 * so store the line into the debugger's array of lines
	 */
	if (PERLDB_LINE && PL_curstash != PL_debstash) {
	    SV * const sv = NEWSV(85,0);

	    sv_upgrade(sv, SVt_PVMG);
	    sv_setpvn(sv,PL_bufptr,PL_bufend-PL_bufptr);
            (void)SvIOK_on(sv);
            SvIV_set(sv, 0);
	    av_store(CopFILEAV(PL_curcop),(I32)CopLINE(PL_curcop),sv);
	}
    }
}

STATIC char *
S_scan_word(pTHX_ register char *s, char *dest, STRLEN destlen, int allow_package, STRLEN *slp)
{
    register char *d = dest;
    register char * const e = d + destlen - 3;  /* two-character token, ending NUL */
    for (;;) {
	if (d >= e)
	    Perl_croak(aTHX_ ident_too_long);
	if (isALNUM(*s))	/* UTF handled below */
	    *d++ = *s++;
	else if (*s == '\'' && allow_package && isIDFIRST_lazy_if(s+1,UTF)) {
	    *d++ = ':';
	    *d++ = ':';
	    s++;
	}
	else if (*s == ':' && s[1] == ':' && allow_package && s[2] != '$') {
	    *d++ = *s++;
	    *d++ = *s++;
	}
	else if (UTF && UTF8_IS_START(*s) && isALNUM_utf8((U8*)s)) {
	    char *t = s + UTF8SKIP(s);
	    while (UTF8_IS_CONTINUED(*t) && is_utf8_mark((U8*)t))
		t += UTF8SKIP(t);
	    if (d + (t - s) > e)
		Perl_croak(aTHX_ ident_too_long);
	    Copy(s, d, t - s, char);
	    d += t - s;
	    s = t;
	}
	else {
	    *d = '\0';
	    *slp = d - dest;
	    return s;
	}
    }
}

/*
 * S_incline
 * This subroutine has nothing to do with tilting, whether at windmills
 * or pinball tables.  Its name is short for "increment line".  It
 * increments the current line number in CopLINE(PL_curcop) and checks
 * to see whether the line starts with a comment of the form
 *    # line 500 "foo.pm"
 * If so, it sets the current line number and file to the values in the comment.
 */

STATIC void
S_incline(pTHX_ char *s)
{
    char *t;
    char *n;
    char *e;
    char ch;

    CopLINE_inc(PL_curcop);
    if (*s++ != '#')
	return;
    while (SPACE_OR_TAB(*s)) s++;
    if (strnEQ(s, "line", 4))
	s += 4;
    else
	return;
    if (SPACE_OR_TAB(*s))
	s++;
    else
	return;
    while (SPACE_OR_TAB(*s)) s++;
    if (!isDIGIT(*s))
	return;
    n = s;
    while (isDIGIT(*s))
	s++;
    while (SPACE_OR_TAB(*s))
	s++;
    if (*s == '"' && (t = strchr(s+1, '"'))) {
	s++;
	e = t + 1;
    }
    else {
	for (t = s; !isSPACE(*t); t++) ;
	e = t;
    }
    while (SPACE_OR_TAB(*e) || *e == '\r' || *e == '\f')
	e++;
    if (*e != '\n' && *e != '\0')
	return;		/* false alarm */

    ch = *t;
    *t = '\0';
    if (t - s > 0) {
#ifndef USE_ITHREADS
	const char *cf = CopFILE(PL_curcop);
	if (cf && strlen(cf) > 7 && strnEQ(cf, "(eval ", 6)) {
	    /* must copy *{"::_<(eval N)[oldfilename:L]"}
	     * to *{"::_<newfilename"} */
	    char smallbuf[256], smallbuf2[256];
	    char *tmpbuf, *tmpbuf2;
	    GV **gvp, *gv2;
	    STRLEN tmplen = strlen(cf);
	    STRLEN tmplen2 = strlen(s);
	    if (tmplen + 3 < sizeof smallbuf)
		tmpbuf = smallbuf;
	    else
		Newx(tmpbuf, tmplen + 3, char);
	    if (tmplen2 + 3 < sizeof smallbuf2)
		tmpbuf2 = smallbuf2;
	    else
		Newx(tmpbuf2, tmplen2 + 3, char);
	    tmpbuf[0] = tmpbuf2[0] = '_';
	    tmpbuf[1] = tmpbuf2[1] = '<';
	    memcpy(tmpbuf + 2, cf, ++tmplen);
	    memcpy(tmpbuf2 + 2, s, ++tmplen2);
	    ++tmplen; ++tmplen2;
	    gvp = (GV**)hv_fetch(PL_defstash, tmpbuf, tmplen, FALSE);
	    if (gvp) {
		gv2 = *(GV**)hv_fetch(PL_defstash, tmpbuf2, tmplen2, TRUE);
		if (!isGV(gv2))
		    gv_init(gv2, PL_defstash, tmpbuf2, tmplen2, FALSE);
		/* adjust ${"::_<newfilename"} to store the new file name */
		GvSV(gv2) = newSVpvn(tmpbuf2 + 2, tmplen2 - 2);
		GvHV(gv2) = (HV*)SvREFCNT_inc(GvHV(*gvp));
		GvAV(gv2) = (AV*)SvREFCNT_inc(GvAV(*gvp));
	    }
	    if (tmpbuf != smallbuf) Safefree(tmpbuf);
	    if (tmpbuf2 != smallbuf2) Safefree(tmpbuf2);
	}
#endif
	CopFILE_free(PL_curcop);
	CopFILE_set(PL_curcop, s);
    }
    *t = ch;
    CopLINE_set(PL_curcop, atoi(n)-1);
}
