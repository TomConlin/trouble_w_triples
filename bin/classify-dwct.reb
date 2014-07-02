#! /Project/bin/rebol -sq

rebol[
	title: "Darwin Core Triple parser/clasifier"
	author: "Tom Conlin"
	date: 2014-Jun-1
	needs: %parse-dwct.reb
	usage: {classify-dwct.reb --args"-i <filename.tab> "}
	file: %classify-dwct.reb
]
;;; do is like include or use or requires
do %parse-dwct.reb

;;; move from where the script is located to where it is called
change-dir system/options/path

args: parse/all system/script/args  " "
dataset: read/lines to-file select args "-i"

;;; these (tsv) datasets have a pk 
;;; then a string which may be a list of dwct.
forall dataset [
	row: parse/all first dataset "^-"
	candidate: trim second row
	if not none? candidate [
		coersed: parse-dwct candidate
		foreach [dwct flags rule] coersed [ ;;;each input string may be list 
			print rejoin[first row tab dwct tab flags]
		]
	]	
]
