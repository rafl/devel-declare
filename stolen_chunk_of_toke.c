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

/* the following #defines are stolen from assorted headers, not toke.c (mst) */

#define skipspace(a)            S_skipspace(aTHX_ a)
#define incline(a)              S_incline(aTHX_ a)
#define filter_gets(a,b,c)      S_filter_gets(aTHX_ a,b,c)
#define scan_str(a,b,c)         S_scan_str(aTHX_ a,b,c)
#define scan_word(a,b,c,d,e)    S_scan_word(aTHX_ a,b,c,d,e)
#define scan_ident(a,b,c,d,e)   S_scan_ident(aTHX_ a,b,c,d,e)

STATIC void     S_incline(pTHX_ char *s);
STATIC char*    S_skipspace(pTHX_ char *s);
STATIC char *   S_filter_gets(pTHX_ SV *sv, PerlIO *fp, STRLEN append);
STATIC char*    S_scan_str(pTHX_ char *start, int keep_quoted, int keep_delims);
STATIC char*    S_scan_word(pTHX_ char *s, char *dest, STRLEN destlen, int allow_package, STRLEN *slp);

#define DPTR2FPTR(t,p) ((t)PTR2nat(p))  /* data pointer to function pointer */
#define FPTR2DPTR(t,p) ((t)PTR2nat(p))  /* function pointer to data pointer */
#define PTR2nat(p)       (PTRV)(p)       /* pointer to integer of PTRSIZE */

/* conditionalise these two because as of 5.9.5 we already get them from
   the headers (mst) */
#ifndef Newx
#define Newx(v,n,t) (v = (MEM_WRAP_CHECK_(n,t) (t*)safemalloc((MEM_SIZE)((n)*sizeof(t)))))
#endif
#ifndef SvPVX_const
#define SvPVX_const(sv) ((const char*) (0 + SvPVX(sv)))
#endif
#ifndef MEM_WRAP_CHECK_
#define MEM_WRAP_CHECK_(n,t) MEM_WRAP_CHECK(n,t),
#endif

#define SvPV_renew(sv,n) \
  STMT_START { SvLEN_set(sv, n); \
    SvPV_set((sv), (MEM_WRAP_CHECK_(n,char)     \
        (char*)saferealloc((Malloc_t)SvPVX(sv), \
               (MEM_SIZE)((n)))));  \
     } STMT_END

#define isCONTROLVAR(x) (isUPPER(x) || strchr("[\\]^_?", (x)))

/* On MacOS, respect nonbreaking spaces */
#ifdef MACOS_TRADITIONAL
#define SPACE_OR_TAB(c) ((c)==' '||(c)=='\312'||(c)=='\t')
#else
#define SPACE_OR_TAB(c) ((c)==' '||(c)=='\t')
#endif

/*
 * Normally, during compile time, PL_curcop == &PL_compiling is true. However,
 * Devel::Declare makes the interpreter call back to perl during compile time,
 * which temporarily enters runtime. Then perl space calls various functions
 * from this file, which are designed to work during compile time. They all
 * happen to operate on PL_curcop, not PL_compiling. That doesn't make a
 * difference in the core, but it does for Devel::Declare, which operates at
 * runtime, but still wants to mangle the things that are about to be compiled.
 * That's why we define our own PL_curcop and make it point to PL_compiling
 * here.
 */
#define PL_curcop &PL_compiling

#define CLINE (PL_copline = (CopLINE(PL_curcop) < PL_copline ? CopLINE(PL_curcop) : PL_copline))

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

/* and these two are my own madness (mst) */

#if PERL_REVISION == 5 && PERL_VERSION == 8 && PERL_SUBVERSION >= 8
#define PERL_5_8_8_PLUS
#endif

#if PERL_REVISION == 5 && PERL_VERSION > 8
#define PERL_5_9_PLUS
#endif

#ifdef PERL_5_9_PLUS
/* 5.9+ moves a bunch of things to a PL_parser struct so we need to
   declare the backcompat macros for things to still work (mst) */

/* XXX temporary backwards compatibility */
#define PL_lex_brackets         (PL_parser->lex_brackets)
#define PL_lex_brackstack       (PL_parser->lex_brackstack)
#define PL_lex_casemods         (PL_parser->lex_casemods)
#define PL_lex_casestack        (PL_parser->lex_casestack)
#define PL_lex_defer            (PL_parser->lex_defer)
#define PL_lex_dojoin           (PL_parser->lex_dojoin)
#define PL_lex_expect           (PL_parser->lex_expect)
#define PL_lex_formbrack        (PL_parser->lex_formbrack)
#define PL_lex_inpat            (PL_parser->lex_inpat)
#define PL_lex_inwhat           (PL_parser->lex_inwhat)
#define PL_lex_op               (PL_parser->lex_op)
#define PL_lex_repl             (PL_parser->lex_repl)
#define PL_lex_starts           (PL_parser->lex_starts)
#define PL_lex_stuff            (PL_parser->lex_stuff)
#define PL_multi_start          (PL_parser->multi_start)
#define PL_multi_open           (PL_parser->multi_open)
#define PL_multi_close          (PL_parser->multi_close)
#define PL_pending_ident        (PL_parser->pending_ident)
#define PL_preambled            (PL_parser->preambled)
#define PL_sublex_info          (PL_parser->sublex_info)
#define PL_linestr              (PL_parser->linestr)
#define PL_sublex_info          (PL_parser->sublex_info)
#define PL_linestr              (PL_parser->linestr)
#define PL_expect               (PL_parser->expect)
#define PL_copline              (PL_parser->copline)
#define PL_bufptr               (PL_parser->bufptr)
#define PL_oldbufptr            (PL_parser->oldbufptr)
#define PL_oldoldbufptr         (PL_parser->oldoldbufptr)
#define PL_linestart            (PL_parser->linestart)
#define PL_bufend               (PL_parser->bufend)
#define PL_last_uni             (PL_parser->last_uni)
#define PL_last_lop             (PL_parser->last_lop)
#define PL_last_lop_op          (PL_parser->last_lop_op)
#define PL_lex_state            (PL_parser->lex_state)
#define PL_rsfp                 (PL_parser->rsfp)
#define PL_rsfp_filters         (PL_parser->rsfp_filters)
#define PL_in_my                (PL_parser->in_my)
#define PL_in_my_stash          (PL_parser->in_my_stash)
#define PL_tokenbuf             (PL_parser->tokenbuf)
#define PL_multi_end            (PL_parser->multi_end)
#define PL_error_count          (PL_parser->error_count)
#define PL_nexttoke           (PL_parser->nexttoke)
/* these are from the non-PERL_MAD path but I don't -think- I need
   the PERL_MAD stuff since my code isn't really populating things (mst) */
# ifdef PERL_MAD
#  define PL_curforce		(PL_parser->curforce)
#  define PL_lasttoke		(PL_parser->lasttoke)
# else
#  define PL_nexttype           (PL_parser->nexttype)
#  define PL_nextval            (PL_parser->nextval)
# endif
/* end of backcompat macros from 5.9 toke.c (mst) */
#endif

/* when ccflags include -DDEBUGGING we need this for earlier 5.8 perls */
#ifndef SvPV_nolen_const
#define SvPV_nolen_const SvPV_nolen
#endif

/* and now we're back to the toke.c stuff again (mst) */

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

	    /* In perl versions previous to p4-rawid: //depot/perl@32954 -P
	     * preprocessors were supported here. We don't support -P at all, even
	     * on perls that support it, and use the following chunk from blead
	     * perl. (rafl)
	     */

	    /* Close the filehandle.  Could be from
	     * STDIN, or a regular file.  If we were reading code from
	     * STDIN (because the commandline held no -e or filename)
	     * then we don't close it, we reset it so the code can
	     * read from STDIN too.
	     */

	    if ((PerlIO*)PL_rsfp == PerlIO_stdin())
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
/* this chunk was added to S_incline during 5.8.8. I don't know why but I don't
   honestly care since I probably want to be bug-compatible anyway (mst) */

/* ... my kingdom for a perl parser in perl ... (mst) */

#ifdef PERL_5_8_8_PLUS
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
#endif
/* second endif closes out the "are we 5.8.(8+)" conditional */
	CopFILE_free(PL_curcop);
	CopFILE_set(PL_curcop, s);
    }
    *t = ch;
    CopLINE_set(PL_curcop, atoi(n)-1);
}

/* scan_str
   takes: start position in buffer
	  keep_quoted preserve \ on the embedded delimiter(s)
	  keep_delims preserve the delimiters around the string
   returns: position to continue reading from buffer
   side-effects: multi_start, multi_close, lex_repl or lex_stuff, and
   	updates the read buffer.

   This subroutine pulls a string out of the input.  It is called for:
   	q		single quotes		q(literal text)
	'		single quotes		'literal text'
	qq		double quotes		qq(interpolate $here please)
	"		double quotes		"interpolate $here please"
	qx		backticks		qx(/bin/ls -l)
	`		backticks		`/bin/ls -l`
	qw		quote words		@EXPORT_OK = qw( func() $spam )
	m//		regexp match		m/this/
	s///		regexp substitute	s/this/that/
	tr///		string transliterate	tr/this/that/
	y///		string transliterate	y/this/that/
	($*@)		sub prototypes		sub foo ($)
	(stuff)		sub attr parameters	sub foo : attr(stuff)
	<>		readline or globs	<FOO>, <>, <$fh>, or <*.c>
	
   In most of these cases (all but <>, patterns and transliterate)
   yylex() calls scan_str().  m// makes yylex() call scan_pat() which
   calls scan_str().  s/// makes yylex() call scan_subst() which calls
   scan_str().  tr/// and y/// make yylex() call scan_trans() which
   calls scan_str().

   It skips whitespace before the string starts, and treats the first
   character as the delimiter.  If the delimiter is one of ([{< then
   the corresponding "close" character )]}> is used as the closing
   delimiter.  It allows quoting of delimiters, and if the string has
   balanced delimiters ([{<>}]) it allows nesting.

   On success, the SV with the resulting string is put into lex_stuff or,
   if that is already non-NULL, into lex_repl. The second case occurs only
   when parsing the RHS of the special constructs s/// and tr/// (y///).
   For convenience, the terminating delimiter character is stuffed into
   SvIVX of the SV.
*/

STATIC char *
S_scan_str(pTHX_ char *start, int keep_quoted, int keep_delims)
{
    SV *sv;				/* scalar value: string */
    char *tmps;				/* temp string, used for delimiter matching */
    register char *s = start;		/* current position in the buffer */
    register char term;			/* terminating character */
    register char *to;			/* current position in the sv's data */
    I32 brackets = 1;			/* bracket nesting level */
    bool has_utf8 = FALSE;		/* is there any utf8 content? */
    I32 termcode;			/* terminating char. code */
    /* 5.8.7+ uses UTF8_MAXBYTES but also its utf8.h defs _MAXLEN to it so
       I'm reasonably hopeful this won't destroy anything (mst) */
    U8 termstr[UTF8_MAXLEN];		/* terminating string */
    STRLEN termlen;			/* length of terminating string */
    char *last = NULL;			/* last position for nesting bracket */

    /* skip space before the delimiter */
    if (isSPACE(*s))
	s = skipspace(s);

    /* mark where we are, in case we need to report errors */
    CLINE;

    /* after skipping whitespace, the next character is the terminator */
    term = *s;
    if (!UTF) {
	termcode = termstr[0] = term;
	termlen = 1;
    }
    else {
	termcode = utf8_to_uvchr((U8*)s, &termlen);
	Copy(s, termstr, termlen, U8);
	if (!UTF8_IS_INVARIANT(term))
	    has_utf8 = TRUE;
    }

    /* mark where we are */
    PL_multi_start = CopLINE(PL_curcop);
    PL_multi_open = term;

    /* find corresponding closing delimiter */
    if (term && (tmps = strchr("([{< )]}> )]}>",term)))
	termcode = termstr[0] = term = tmps[5];

    PL_multi_close = term;

    /* create a new SV to hold the contents.  87 is leak category, I'm
       assuming.  79 is the SV's initial length.  What a random number. */
    sv = NEWSV(87,79);
    sv_upgrade(sv, SVt_PVIV);
    SvIV_set(sv, termcode);
    (void)SvPOK_only(sv);		/* validate pointer */

    /* move past delimiter and try to read a complete string */
    if (keep_delims)
	sv_catpvn(sv, s, termlen);
    s += termlen;
    for (;;) {
	if (PL_encoding && !UTF) {
	    bool cont = TRUE;

	    while (cont) {
		int offset = s - SvPVX_const(PL_linestr);
		const bool found = sv_cat_decode(sv, PL_encoding, PL_linestr,
					   &offset, (char*)termstr, termlen);
		const char *ns = SvPVX_const(PL_linestr) + offset;
		char *svlast = SvEND(sv) - 1;

		for (; s < ns; s++) {
		    if (*s == '\n' && !PL_rsfp)
			CopLINE_inc(PL_curcop);
		}
		if (!found)
		    goto read_more_line;
		else {
		    /* handle quoted delimiters */
		    if (SvCUR(sv) > 1 && *(svlast-1) == '\\') {
			const char *t;
			for (t = svlast-2; t >= SvPVX_const(sv) && *t == '\\';)
			    t--;
			if ((svlast-1 - t) % 2) {
			    if (!keep_quoted) {
				*(svlast-1) = term;
				*svlast = '\0';
				SvCUR_set(sv, SvCUR(sv) - 1);
			    }
			    continue;
			}
		    }
		    if (PL_multi_open == PL_multi_close) {
			cont = FALSE;
		    }
		    else {
			const char *t;
			char *w;
			if (!last)
			    last = SvPVX(sv);
			for (t = w = last; t < svlast; w++, t++) {
			    /* At here, all closes are "was quoted" one,
			       so we don't check PL_multi_close. */
			    if (*t == '\\') {
				if (!keep_quoted && *(t+1) == PL_multi_open)
				    t++;
				else
				    *w++ = *t++;
			    }
			    else if (*t == PL_multi_open)
				brackets++;

			    *w = *t;
			}
			if (w < t) {
			    *w++ = term;
			    *w = '\0';
			    SvCUR_set(sv, w - SvPVX_const(sv));
			}
			last = w;
			if (--brackets <= 0)
			    cont = FALSE;
		    }
		}
	    }
	    if (!keep_delims) {
		SvCUR_set(sv, SvCUR(sv) - 1);
		*SvEND(sv) = '\0';
	    }
	    break;
	}

    	/* extend sv if need be */
	SvGROW(sv, SvCUR(sv) + (PL_bufend - s) + 1);
	/* set 'to' to the next character in the sv's string */
	to = SvPVX(sv)+SvCUR(sv);

	/* if open delimiter is the close delimiter read unbridle */
	if (PL_multi_open == PL_multi_close) {
	    for (; s < PL_bufend; s++,to++) {
	    	/* embedded newlines increment the current line number */
		if (*s == '\n' && !PL_rsfp)
		    CopLINE_inc(PL_curcop);
		/* handle quoted delimiters */
		if (*s == '\\' && s+1 < PL_bufend && term != '\\') {
		    if (!keep_quoted && s[1] == term)
			s++;
		/* any other quotes are simply copied straight through */
		    else
			*to++ = *s++;
		}
		/* terminate when run out of buffer (the for() condition), or
		   have found the terminator */
		else if (*s == term) {
		    if (termlen == 1)
			break;
		    if (s+termlen <= PL_bufend && memEQ(s, (char*)termstr, termlen))
			break;
		}
		else if (!has_utf8 && !UTF8_IS_INVARIANT((U8)*s) && UTF)
		    has_utf8 = TRUE;
		*to = *s;
	    }
	}
	
	/* if the terminator isn't the same as the start character (e.g.,
	   matched brackets), we have to allow more in the quoting, and
	   be prepared for nested brackets.
	*/
	else {
	    /* read until we run out of string, or we find the terminator */
	    for (; s < PL_bufend; s++,to++) {
	    	/* embedded newlines increment the line count */
		if (*s == '\n' && !PL_rsfp)
		    CopLINE_inc(PL_curcop);
		/* backslashes can escape the open or closing characters */
		if (*s == '\\' && s+1 < PL_bufend) {
		    if (!keep_quoted &&
			((s[1] == PL_multi_open) || (s[1] == PL_multi_close)))
			s++;
		    else
			*to++ = *s++;
		}
		/* allow nested opens and closes */
		else if (*s == PL_multi_close && --brackets <= 0)
		    break;
		else if (*s == PL_multi_open)
		    brackets++;
		else if (!has_utf8 && !UTF8_IS_INVARIANT((U8)*s) && UTF)
		    has_utf8 = TRUE;
		*to = *s;
	    }
	}
	/* terminate the copied string and update the sv's end-of-string */
	*to = '\0';
	SvCUR_set(sv, to - SvPVX_const(sv));

	/*
	 * this next chunk reads more into the buffer if we're not done yet
	 */

  	if (s < PL_bufend)
	    break;		/* handle case where we are done yet :-) */

#ifndef PERL_STRICT_CR
	if (to - SvPVX_const(sv) >= 2) {
	    if ((to[-2] == '\r' && to[-1] == '\n') ||
		(to[-2] == '\n' && to[-1] == '\r'))
	    {
		to[-2] = '\n';
		to--;
		SvCUR_set(sv, to - SvPVX_const(sv));
	    }
	    else if (to[-1] == '\r')
		to[-1] = '\n';
	}
	else if (to - SvPVX_const(sv) == 1 && to[-1] == '\r')
	    to[-1] = '\n';
#endif
	
     read_more_line:
	/* if we're out of file, or a read fails, bail and reset the current
	   line marker so we can report where the unterminated string began
	*/
	if (!PL_rsfp ||
	 !(PL_oldoldbufptr = PL_oldbufptr = s = PL_linestart = filter_gets(PL_linestr, PL_rsfp, 0))) {
	    sv_free(sv);
	    CopLINE_set(PL_curcop, (line_t)PL_multi_start);
	    return Nullch;
	}
	/* we read a line, so increment our line counter */
	CopLINE_inc(PL_curcop);

	/* update debugger info */
	if (PERLDB_LINE && PL_curstash != PL_debstash) {
	    SV *sv = NEWSV(88,0);

	    sv_upgrade(sv, SVt_PVMG);
	    sv_setsv(sv,PL_linestr);
            (void)SvIOK_on(sv);
            SvIV_set(sv, 0);
	    av_store(CopFILEAV(PL_curcop), (I32)CopLINE(PL_curcop), sv);
	}

	/* having changed the buffer, we must update PL_bufend */
	PL_bufend = SvPVX(PL_linestr) + SvCUR(PL_linestr);
	PL_last_lop = PL_last_uni = Nullch;
    }

    /* at this point, we have successfully read the delimited string */

    if (!PL_encoding || UTF) {
	if (keep_delims)
	    sv_catpvn(sv, s, termlen);
	s += termlen;
    }
    if (has_utf8 || PL_encoding)
	SvUTF8_on(sv);

    PL_multi_end = CopLINE(PL_curcop);

    /* if we allocated too much space, give some back */
    if (SvCUR(sv) + 5 < SvLEN(sv)) {
	SvLEN_set(sv, SvCUR(sv) + 1);
/* 5.8.8 uses SvPV_renew, no prior version actually has the damn thing (mst) */
#ifdef PERL_5_8_8_PLUS
	SvPV_renew(sv, SvLEN(sv));
#else
	Renew(SvPVX(sv), SvLEN(sv), char);
#endif
    }

    /* decide whether this is the first or second quoted string we've read
       for this op
    */

    if (PL_lex_stuff)
	PL_lex_repl = sv;
    else
	PL_lex_stuff = sv;
    return s;
}

/*
 * S_force_next
 * When the lexer realizes it knows the next token (for instance,
 * it is reordering tokens for the parser) then it can call S_force_next
 * to know what token to return the next time the lexer is called.  Caller
 * will need to set PL_nextval[], and possibly PL_expect to ensure the lexer
 * handles the token correctly.
 */

STATIC void
S_force_next(pTHX_ I32 type)
{
#ifdef PERL_MAD
    dVAR;
    if (PL_curforce < 0)
    start_force(PL_lasttoke);
    PL_nexttoke[PL_curforce].next_type = type;
    if (PL_lex_state != LEX_KNOWNEXT)
    PL_lex_defer = PL_lex_state;
    PL_lex_state = LEX_KNOWNEXT;
    PL_lex_expect = PL_expect;
    PL_curforce = -1;
#else
    PL_nexttype[PL_nexttoke] = type;
    PL_nexttoke++;
    if (PL_lex_state != LEX_KNOWNEXT) {
  PL_lex_defer = PL_lex_state;
  PL_lex_expect = PL_expect;
  PL_lex_state = LEX_KNOWNEXT;
    }
#endif
}

#define XFAKEBRACK 128

STATIC char *
S_scan_ident(pTHX_ register char *s, register const char *send, char *dest, STRLEN destlen, I32 ck_uni)
{
    register char *d;
    register char *e;
    char *bracket = Nullch;
    char funny = *s++;

    if (isSPACE(*s))
	s = skipspace(s);
    d = dest;
    e = d + destlen - 3;	/* two-character token, ending NUL */
    if (isDIGIT(*s)) {
	while (isDIGIT(*s)) {
	    if (d >= e)
		Perl_croak(aTHX_ ident_too_long);
	    *d++ = *s++;
	}
    }
    else {
	for (;;) {
	    if (d >= e)
		Perl_croak(aTHX_ ident_too_long);
	    if (isALNUM(*s))	/* UTF handled below */
		*d++ = *s++;
	    else if (*s == '\'' && isIDFIRST_lazy_if(s+1,UTF)) {
		*d++ = ':';
		*d++ = ':';
		s++;
	    }
	    else if (*s == ':' && s[1] == ':') {
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
	    else
		break;
	}
    }
    *d = '\0';
    d = dest;
    if (*d) {
	if (PL_lex_state != LEX_NORMAL)
	    PL_lex_state = LEX_INTERPENDMAYBE;
	return s;
    }
    if (*s == '$' && s[1] &&
	(isALNUM_lazy_if(s+1,UTF) || s[1] == '$' || s[1] == '{' || strnEQ(s+1,"::",2)) )
    {
	return s;
    }
    if (*s == '{') {
	bracket = s;
	s++;
    }
    /* we always call this with ck_uni == 0 (rafl) */
    /*
    else if (ck_uni)
	check_uni();
    */
    if (s < send)
	*d = *s++;
    d[1] = '\0';
    if (*d == '^' && *s && isCONTROLVAR(*s)) {
	*d = toCTRL(*s);
	s++;
    }
    if (bracket) {
	if (isSPACE(s[-1])) {
	    while (s < send) {
		const char ch = *s++;
		if (!SPACE_OR_TAB(ch)) {
		    *d = ch;
		    break;
		}
	    }
	}
	if (isIDFIRST_lazy_if(d,UTF)) {
	    d++;
	    if (UTF) {
		e = s;
		while ((e < send && isALNUM_lazy_if(e,UTF)) || *e == ':') {
		    e += UTF8SKIP(e);
		    while (e < send && UTF8_IS_CONTINUED(*e) && is_utf8_mark((U8*)e))
			e += UTF8SKIP(e);
		}
		Copy(s, d, e - s, char);
		d += e - s;
		s = e;
	    }
	    else {
		while ((isALNUM(*s) || *s == ':') && d < e)
		    *d++ = *s++;
		if (d >= e)
		    Perl_croak(aTHX_ ident_too_long);
	    }
	    *d = '\0';
	    while (s < send && SPACE_OR_TAB(*s)) s++;
	    if ((*s == '[' || (*s == '{' && strNE(dest, "sub")))) {
		/* we don't want perl to guess what is meant. the keyword
		 * parser decides that later. (rafl)
		 */
		/*
		if (ckWARN(WARN_AMBIGUOUS) && keyword(dest, d - dest)) {
		    const char *brack = *s == '[' ? "[...]" : "{...}";
		    Perl_warner(aTHX_ packWARN(WARN_AMBIGUOUS),
			"Ambiguous use of %c{%s%s} resolved to %c%s%s",
			funny, dest, brack, funny, dest, brack);
		}
		*/
		bracket++;
		PL_lex_brackstack[PL_lex_brackets++] = (char)(XOPERATOR | XFAKEBRACK);
		return s;
	    }
	}
	/* Handle extended ${^Foo} variables
	 * 1999-02-27 mjd-perl-patch@plover.com */
	else if (!isALNUM(*d) && !isPRINT(*d) /* isCTRL(d) */
		 && isALNUM(*s))
	{
	    d++;
	    while (isALNUM(*s) && d < e) {
		*d++ = *s++;
	    }
	    if (d >= e)
		Perl_croak(aTHX_ ident_too_long);
	    *d = '\0';
	}
	if (*s == '}') {
	    s++;
	    if (PL_lex_state == LEX_INTERPNORMAL && !PL_lex_brackets) {
		PL_lex_state = LEX_INTERPEND;
		PL_expect = XREF;
	    }
	    if (funny == '#')
		funny = '@';
	    /* we don't want perl to guess what is meant. the keyword
	     * parser decides that later. (rafl)
	     */
	    /*
	    if (PL_lex_state == LEX_NORMAL) {
		if (ckWARN(WARN_AMBIGUOUS) &&
		    (keyword(dest, d - dest) || get_cv(dest, FALSE)))
		{
		    Perl_warner(aTHX_ packWARN(WARN_AMBIGUOUS),
			"Ambiguous use of %c{%s} resolved to %c%s",
			funny, dest, funny, dest);
		}
	    }
	    */
	}
	else {
	    s = bracket;		/* let the parser handle it */
	    *dest = '\0';
	}
    }
    /* don't intuit. we really just want the string. (rafl) */
    /*
    else if (PL_lex_state == LEX_INTERPNORMAL && !PL_lex_brackets && !intuit_more(s))
	PL_lex_state = LEX_INTERPEND;
    */
    return s;
}
