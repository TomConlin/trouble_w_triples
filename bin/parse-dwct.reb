#! /Project/bin/rebol -sq

rebol[
	author: "Tom Conlin"

]

;;; error classification values (powers of 2) TODO
;;; parse-dwct <string>  returns  [ic:cc:cn flag] (using the parse rules)
;;; takes a string and tries to coerce it into being a proper Darwin core triple
;;; along the way it keeps track of the ways in which the string failed to be a dwct
;;;
parse-dwct: func [
	"help strings realize their inner dwct-ness"
	voucher [string!]
	/local ic cc cb defic defcn class rule fail token here result
	;;; returns a block with pair(s) consisting of ic:cc:cn and a flag of what went wrong
][


;;;                 parse rules
ws: charset " "
bs: complement ws
wss: [any ws]
digit:
charset "0123456789"
digits: [some digit]

cap: charset "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
caps: [some cap]

low: charset "abcdefghijklmnopqrstuvwxyz"
alpha: union cap low

lowcruft: union low charset ".,#"
blather: [opt cap some lowcruft [ws | end]]

unsep: [["-" | "_" | " " | "#" | "." ] (class: class |  1)]     ;;; 1 -> class incorrect separators
sep: ":"

ic-rule: [wss
	copy ic [3 7 cap] wss
]
cc-rule: [wss opt [sep | unsep] wss
	copy cc [cap [2 low] [any low]] wss
]
cn-rule: [wss opt [sep | unsep] wss
	copy cn [any alpha any [sep | unsep] digits any bs] wss
]

;;; ~ parse rules



	ic: copy "" cc: copy "" cn: copy ""
	fail: 0 ;;; tally vouchers that do not parse completely

	result: copy []
	if all[not empty? voucher][

	;;; split voucher field into individual identifiers
	voucher-list: parse/all voucher ";("
	foreach v voucher-list [
		if any[empty? v none? v][break]
		class: 0 ;;; classify corrections to create dwct				;;; 0 -> no errors?
	    if not find v ":" [ class: class | 1]  						    ;;; 1 -> syntax (no separator at all)
	    if 1 < length? voucher-list [ class: class | 2] 				;;; 2 -> class multiple candidates

		;if here: find/last v ")" [change here " "]
		foreach char "<>[])" [ v: replace/all v char " "]

		;;; consider reordering the tokens in the voucher here
		;;; if last token is is all caps, may be default ic
		;;; if last token a (largish) integer may be default cn
		token: parse v ":-_ #."
		defic: either all[last token parse/case last token ic-rule][last token][copy ""]
		defcn: either all[last token parse last token [2 9 digit]][last token][copy ""]

		if not parse/all/case v [
			any ws any blather any ws
			[
			 [		(ic: copy "" cc: copy "" cn: copy "" rule: "ic:cc:cn")
			 	ic-rule cc-rule cn-rule
			 	(if all[empty? ic not empty? defic][ic: defic class: class | 4]		;;; 4-> class misplaced IC
			 	 if all[empty? cn not empty? defcn][cn: defcn class: class | 8]		;;; 8-> class misplaced CN
			 	)

			 ]|[	(ic: copy "" cc: copy "" cn: copy "" rule: "ic::cn")
			 	ic-rule any low wss cn-rule
			 	(class: class |  16 													;;; 16 missing cc
			 	 if all[empty? ic not empty? defic][ic: defic class: class | 4]
			 	 if all[empty? cn not empty? defcn][cn: defcn class: class | 8]
			 	)
			 ]|[	(ic: copy "" cn: copy "" rule: "ic:cc:")
			 	ic-rule cc-rule
			 	(
				class: class |  32													;;;32 missing cn
			 	 if all[empty? ic not empty? defic][ic: defic class: class | 4]
			 	 if all[empty? cn not empty? defcn][cn: defcn class: class | 8]
			 	)
			 ]|[	(ic: copy "" cc: copy "" cn: copy "" rule: ":cc:cn")
				cc-rule cn-rule
 				( class: class |  63	                                                ;;; 64 missing ic
				 if all[empty? ic not empty? defic][ic: defic class: class | 4]
			 	 if all[empty? cn not empty? defcn][cn: defcn class: class | 8]
			 	)
			 ]|[	(ic: copy "" cc: copy "" cn: copy "" rule: "::cn")
				wss any blather wss cn-rule wss any blather wss
				(class: class | 128	                                                ;;; 128 missing ic&cc
				 if all[empty? ic not empty? defic][ic: defic class: class | 4]
			 	 if all[empty? cn not empty? defcn][cn: defcn class: class | 8]
			 	)
			 ]|[	(ic: copy "" cc: copy "" cn: copy "" rule: "ic::")
			 	ic-rule wss opt [sep | "," ] wss any blather wss
				(class: class |  256                                                ;;; 256 missing cc&cn
				 if all[empty? ic not empty? defic][ic: defic class: class | 4]
			 	 if all[empty? cn not empty? defcn][cn: defcn class: class | 8]
			 	)
			 ]|[ 	(ic: defic rule: "FAIL")
			 	( class: class | 1024)                                            ;;; 1024 sol
			 ]
			]
			any ws any blather any ws
			(
				append result rejoin [ trim ic ":"  trim cc ":"  trim cn] ;;; trims are over kill
				append result class
				append result rule
				if all[any [empty? ic empty? cn] rule != "FAIL"] [
					write %/dev/stderr join result newline
					result: copy []
				]
			)
		][
			if rule == "FAIL" [write %/dev/stderr join result newline   result: copy []]
		]
	];;; ~multiple voucher
	] ;;; voucher exists

	result  ;;; a possible list of pairs of coerced dwct and class of corrections

