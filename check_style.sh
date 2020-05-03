#!/bin/sh
# Requires some non-POSIX features found eg in GNU or FreeBSD's bsdgrep, namely
#   --include
#   -R
# Apart from that, this should work on any POSIX-compliant system

# This Script checks for some common styling issues. Ideally a commit should pass
# ./check_style.sh, but passing ./check_style.sh does not guarantee the abscence
# of styling issues


cd "$(dirname $0)"

# Setup vars
flag=0
tab="$(printf '\t')"
# Useful (E)RE snippets
ere_par_kw='(if|for|while|switch)'
re_alnum='[a-zA-Z0-9]'

if [ -z "$NOCOLORS" ] ; then
    cstart='\e[1;31m'
    cend='\e[0m'
else
    cstart=''
    cend=''
fi

# Helper functions
print_err() {
    flag=1
    echo "$cstart$1$cend" >&2
}

# Call print_err $2 if  $1 -eq 0. Do nothing otherwise
print_err_cond() {
    if [ "$#" -ne 2 ] ; then
        print_err "[DBG]: print_err_cond used with $# vars instead of 2. Abort"
        exit 2
    elif [ "$1" -eq 0 ] ; then
        print_err "$2"
    fi
}

# Print error and exit on unset variables (NOCOLORS might be unset)
set -u

# Tabs vs Spaces
grep --include='*.c' --include='*.h' -Rn "$tab" .
print_err_cond "$?" "Found tabs instead of spaces !"

# Trailing whitespace
grep --include='*.c' --include='*.h' -Rn -E '[ '"$tab"']+$' .
print_err_cond "$?" "Found lines with trailing whitespace !"

# Keywords space delimited from parentheses and brackets
grep --include='*.c' --include='*.h' -Rn \
 -E "$ere_par_kw"'\(|'"$re_alnum"'\{|\}'"$re_alnum" .
print_err_cond "$?" \
 "Keyword etc not delimited by whitespace from parentheses or brackets !"

grep --include='*.c' --include='*.h' -Rn \
 -E '( |^)'"$ere_par_kw"'  +\(|'"$re_alnum"'  +\{|\}  +'"$re_alnum" .
print_err_cond "$?" \
 "Keyword etc delimited with too much whitespace from '(','{' or '}' !"

# Just parentheses and brackets
grep --include='*.c' --include='*.h' -Rn '){' .
print_err_cond "$?" "Parenthesis and bracket not delimited by whitespace !"

# No space after sizeof
grep --include='*.c' --include='*.h' -Rn -E 'sizeof +\(' .
print_err_cond "$?" "'sizeof' should not be delimited by whitespace !"


# Finish
if [ "$flag" -ne 0 ] ; then
    print_err "[Not-OK]: see messages above"
else
    echo "[OK]: No style violations found." >&2
fi

exit "$flag"
