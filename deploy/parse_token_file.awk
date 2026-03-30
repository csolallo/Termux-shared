# token should be passed in the command line in the form -v token=<token to search>
# input file should have the tokens 1 per line in the following format 
# token : value

BEGIN { FS = ":" }
NF == 2 && $1 == token { print $2 }
