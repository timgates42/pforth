\ @(#) numberio.fth 98/01/26 1.2
\ numberio.fth
\
\ numeric conversion
\
\ Author: Phil Burk
\ Copyright 1994 3DO, Phil Burk, Larry Polansky, David Rosenboom
\
\ Permission to use, copy, modify, and/or distribute this
\ software for any purpose with or without fee is hereby granted.
\
\ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
\ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
\ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL
\ THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR
\ CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
\ FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
\ CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
\ OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

anew task-numberio.fth
decimal

\ ------------------------ INPUT -------------------------------
\ Convert a single character to a number in the given base.
: DIGIT   ( char base -- n true | char false )
    >r
\ convert lower to upper
    dup ascii a < not
    IF
        ascii a - ascii A +
    THEN
\
    dup dup ascii A 1- >
    IF ascii A - ascii 9 + 1+
    ELSE ( char char )
        dup ascii 9 >
        IF
            ( between 9 and A is bad )
            drop 0 ( trigger error below )
        THEN
    THEN
    ascii 0 -
    dup r> <
    IF dup 1+ 0>
        IF nip true
        ELSE drop FALSE
        THEN
    ELSE drop FALSE
    THEN
;

: >NUMBER ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 , convert till bad char , CORE )
    >r
    BEGIN
        r@ 0>    \ any characters left?
        IF
            dup c@ base @
            digit ( ud1 c-addr , n true | char false )
            IF
                TRUE
            ELSE
                drop FALSE
            THEN
        ELSE
            false
        THEN
    WHILE ( -- ud1 c-addr n  )
        swap >r  ( -- ud1lo ud1hi n  )
        swap  base @ ( -- ud1lo n ud1hi base  )
        um* drop ( -- ud1lo n ud1hi*baselo  )
        rot  base @ ( -- n ud1hi*baselo ud1lo base )
        um* ( -- n ud1hi*baselo ud1lo*basello ud1lo*baselhi )
        d+  ( -- ud2 )
        r> 1+     \ increment char*
        r> 1- >r  \ decrement count
    REPEAT
    r>
;

\ obsolete
: CONVERT  ( ud1 c-addr1 -- ud2 c-addr2 , convert till bad char , CORE EXT )
    256 >NUMBER DROP
;

0 constant NUM_TYPE_BAD
1 constant NUM_TYPE_SINGLE
2 constant NUM_TYPE_DOUBLE

\ Like >number, but temporarily switch BASE.
: (>number-with-base) ( ud c-addr u base -- ud' c-addr' u' )
	base @ >r base ! >number r> base !
;

\ This is similar to the F83 NUMBER? except that it returns a number type
\ and then either a single or double precision number.
: ((NUMBER?))   ( c-addr u -- 0 | n 1 | d 2 , convert string to number )
    dup 0= IF 2drop NUM_TYPE_BAD exit THEN   \ any chars?

    base @ -rot			( base c-addr u )

    \ Recognize prefixes and change base if needed
    over c@ >r			( base c-addr u  ) ( r: char )
    r@ [char] # = if rot drop 10 -rot 1 /string then
    r@ [char] $ = if rot drop 16 -rot 1 /string then
    r@ [char] % = if rot drop  2 -rot 1 /string then
    r@ [char] ' = if
	    \ Recognize '<char>'
	    dup 3 = if
		    over 2 chars + c@ [char] ' = if
			    drop nip rdrop
			    char+ c@ NUM_TYPE_SINGLE exit
		    then
	    then
    then
    r> drop

\ check for '-' at beginning, skip if present
    over c@ ascii - = \ is it a '-'
    dup >r            \ save flag
    IF 1 /string  ( -- base c-addr+1 cnt-1 , skip past minus sign )
    THEN

    ( base c-addr cnt ) ( r: minus-flag )
    rot >r 0 0 2swap r>
    (>number-with-base) dup 0=   \ convert as much as we can
    IF
        2drop    \ drop addr cnt
        drop     \ drop hi part of num
        r@       \ check flag to see if '-' sign used
        IF  negate
        THEN
        NUM_TYPE_SINGLE
    ELSE  ( -- d addr cnt )
        1 = swap             \ if final character is '.' then double
        c@ ascii . =  AND
        IF
            r@      \ check flag to see if '-' sign used
            IF  dnegate
            THEN
            NUM_TYPE_DOUBLE
        ELSE
            2drop
            NUM_TYPE_BAD
        THEN
    THEN
    rdrop
;

: (NUMBER?)   ( $addr -- 0 | n 1 | d 2 , convert string to number )
    count ((number?))
;

' (number?) is number?
\ hex
\ 0sp c" xyz" (number?) .s
\ 0sp c" 234" (number?) .s
\ 0sp c" -234" (number?) .s
\ 0sp c" 234." (number?) .s
\ 0sp c" -234." (number?) .s
\ 0sp c" 1234567855554444." (number?) .s


\ ------------------------ OUTPUT ------------------------------
\ Number output based on F83
variable HLD    \ points to last character added

: hold   ( char -- , add character to text representation)
    -1 hld  +!
    hld @  c!
;
: <#     ( -- , setup conversion )
    pad hld !
;
: #>     ( d -- addr len , finish conversion )
    2drop  hld @  pad  over -
;
: sign   ( n -- , add '-' if negative )
    0<  if  ascii - hold  then
;
: #      ( d -- d , convert one digit )
   base @  mu/mod rot 9 over <
   IF  7 +
   THEN
   ascii 0 + hold
;
: #s     ( d -- d , convert remaining digits )
    BEGIN  #  2dup or 0=
    UNTIL
;


: (UD.) ( ud -- c-addr cnt )
    <# #s #>
;
: UD.   ( ud -- , print unsigned double number )
    (ud.)  type space
;
: UD.R  ( ud n -- )
    >r  (ud.)  r> over - spaces type
;
: (D.)  ( d -- c-addr cnt )
    tuck dabs <# #s rot sign #>
;
: D.    ( d -- )
    (d.)  type space
;
: D.R   ( d n -- , right justified )
    >r  (d.)  r>  over - spaces  type
;

: (U.)  ( u -- c-addr cnt )
    0 (ud.)
;
: U.    ( u -- , print unsigned number )
    0 ud.
;
: U.R   ( u n -- , print right justified )
    >r  (u.)  r> over - spaces  type
;
: (.)   ( n -- c-addr cnt )
    dup abs 0 <# #s rot sign #>
;
: .     ( n -- , print signed number)
   (.)  type space
;
: .R    ( n l -- , print right justified)
    >r  (.)  r> over - spaces type
;
