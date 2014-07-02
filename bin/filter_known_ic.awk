#! /bin/awk -f


# IC_knownfilter.list2 is a list of institution codes
# stdin is a pk, tab, then a well-formed dwcT (ic:cc:cn), then whatever
# stdout is lines of stdin with an ic found in IC_knownfilter.list
# the files need not be ordered

BEGIN {
 	OFS=FS="\t";
 	while ((getline blessed < FILTER )>0)
 		ic[blessed]=1
}
{ 
	split($2,dwct,":");
	if(ic[dwct[1]]>0) print
}

