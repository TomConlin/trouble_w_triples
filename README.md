This README is an attempt to replicate to some degree 
processes from an actual machine spread out over the last year or so
but within this Docker image now.

To replicate this process with current data from the three repositories
instead of the canned snapshots found in the directory 'rawdata'
please see the Fetch_repositories.txt.  
(You may need more storage space than this Docker image will allow.)  

Only keeping the fields from the repositories actually needed to replicate the counts in the paper
the raw data would be about 160M uncompressed and are about 26M gzipped:

	ls -1 rawdata/
	IC_knownfilter.list						# (P.I.) curated list of institution codes  
	VN_vouchers.unl.gz						# well formed DwCT assembled from VertNet's ic cc & cn   
	locus_voucher.tab.gz					# the locus and specimen_voucher field from vertebrate GenBank divisions  
	sampleid_catalognum_bold_gbacc.tab.gz	# four fields from BOLD chordate records 2 might have DwCTs  


The gziped files are write protected so we always have a pristine copy to fall back on if our experiments become unintentionally destructive.  


The easiest way to begin processing this data is with 'zcat', as in:

	zcat rawdata/VN_vouchers.unl.gz | wc -l  
	8216424  
	zcat rawdata/locus_voucher.tab.gz  | wc -l  
	595744  
	zcat rawdata/sampleid_catalognum_bold_gbacc.tab.gz | wc -l  
	216809

or maybe:  

	zcat rawdata/VN_vouchers.unl.gz > data/VN_vouchers.unl  
	zcat rawdata/locus_voucher.tab.gz >  data/locus_voucher.tab  
	zcat rawdata/sampleid_catalognum_bold_gbacc.tab.gz > data/sampleid_catalognum_bold_gbacc.tab  

if you are going to stare at the originals much.  


## GenBank
When we are just looking at broken DwCT, the canonical ones can be counted/filtered out.  

### Filter out canonical vouchers
:
	grep -Ev  "[A-Z]{2,6}\:[A-Z][a-z]+\:.*[0-9]+.*" data/locus_voucher.tab > data/locus_voucher_x.tab   
	wc -l data/locus_voucher_x.tab  
	585257 data/locus_voucher_x.tab  

check if the locus are a Primary Key (unique):  

	cut -f1 data/locus_voucher_x.tab | sort -u | wc -l  
	585159


LOCUS is not quite a PK. ~ 100 duplicated locus IDs   
but no worries, we are just checking out of curiosity.  (99.98% unique)  

#### Classify
:
	bin/classify-dwct.reb --args "-i data/locus_voucher_x.tab" > data/locus_voucher_x_classed.tab 2> data/locus_voucher_x_classed.err
	wc -l data/locus_voucher_x_classed.tab
	433782


the error file has attempts which could not be parsed
`
cat data/locus_voucher_x_classed.err
::R12074 129 ::cn 
`
just this one without a viable IC.  


the classification process allows for multiple DwCT per record
so the number of duplicate locus IDs can go up  
`
cut -f1 data/locus_voucher_x_classed.tab | sort -u | wc -l  
423829  
`

do not know how many of the original ~100 dups made it in to this set of ~10,000 
but there are now 9,953 on this side. (97.7% unique)


#### Filter for known Institution codes
`
bin/filter_known_ic.awk -v"FILTER=rawdata/IC_knownfilter.list2" <  data/locus_voucher_x_classed.tab >  data/locus_voucher_x_classed_blessed.tab
wc -l  data/locus_voucher_x_classed_blessed.tab
282,056 locus_voucher_classed_blessed.tab
cut -f1 locus_voucher_classed_blessed.tab | sort -u | wc -l
279,473
`
leaving 2,583 locus with alternative (or duplicate) DwCT 
which is back up to 99.08% unique.


### Report

the classifier reports on the types of issues it comes across changing a string into a DwCT
but the main ones can be seen in the error flag returned.
 a non zero error flag means the classifier found something wrong
 an even error flag means the result is triplet
 an odd error flag means the result is a doublet 

an error flag of 0 would be no errors, but we filtered for canonical when we began so there should not be any
the zeros here turn out to be cases where they only gave one of the two colons 
and took a foolish shortcut and figured if they were using colons in one part then they were using colons in both parts  
sigh
`
cat data/locus_voucher_x_classed_blessed.tab | cut -f3 | sort | uniq -c | sort -nr
 
 167399 17
  				93903 16
  10365 19
   6724 265
   1349 1
    783 41
    635 0
    444 135
    378 133
     			34 264
     24 267
     10 3
      			7 18
      1 63
`      
--------------------------------
	188112		93944


188,112 syntactic  	(1,984 only)
280,075 semantic
186,128 both		(93,947 only)


############################################
116,909

that is a lot of duplication, 
on average every DwCT shows up more a little more than twice


####################################################################################################
####################################################################################################
####################################################################################################

for comparisons I might want a fresh copy of all GB vouchers ... 
but these will have gone thru the new classifier  numbers might be a little off 

in /home/tomc/Projects/BiSciCol/GenBankII/hillbilly


./classify-dwct.reb --args "-i ../voucher/locus_voucher.tab" > locus_voucher_classed_all.tab 2> locus_voucher_classed_all.err

./filter_known_ic.awk -v"FILTER=../IC_knownfilter.list2" <  locus_voucher_classed_all.tab >  locus_voucher_classed_blessed_all.tab


grep "::" locus_voucher_classed_blessed_all.tab | sort -k2,2 -t $'\t' > locus_voucher_doublets_all.tab
grep -v "::" locus_voucher_classed_blessed_all.tab | sort -k2,2 -t $'\t' > locus_voucher_triplets_all.tab

wc -l locus_voucher_classed_all.tab locus_voucher_classed_blessed_all.tab locus_voucher_doublets_all.tab locus_voucher_triplets_all.tab
  444191 locus_voucher_classed_all.tab
  292453 locus_voucher_classed_blessed_all.tab
  279279 locus_voucher_doublets_all.tab
   13174 locus_voucher_triplets_all.tab
 1029097 total
 

###################################################################

VN GB comparisons

from /home/tomc/Projects/BiSciCol/GenBankII/hillbilly
and ...now where o where did I leave the VN DwCTs? ... 
 
ls -l ../voucher/VN_vouchers.unl
 -rw-rw-r--. 1 tomc biscicol 145440544 Mar 21 12:14 ../voucher/VN_vouchers.unl

wc -l ../voucher/VN_vouchers.unl
8216424 ../voucher/VN_vouchers.unl

that is promising 
head ../voucher/VN_vouchers.unl
CAS:HERP:1
CAS:HERP:10
CAS:HERP:100
CAS:HERP:1000
CAS:HERP:10000
CAS:HERP:100000
CAS:HERP:100001
CAS:HERP:100002
CAS:HERP:100003
CAS:HERP:100004

grep -v "::" ../voucher/VN_vouchers.unl | sort > VN_triplets.unl
grep "::" ../voucher/VN_vouchers.unl  | sort > VN_doublets.unl


# T-T
join -11 -22 VN_triplets.unl locus_voucher_triplets_all.tab  | wc -l
join: file 1 is not in sorted order
4571   no change with explicit tab


sort -c -k2,2 -t $'\t' VN_triplets.unl
sort -c VN_triplets.unl

sigh, these sort incongruities (w/mixed case UTF8) get old.
they may not be sorted w.r.t some collation scheme
but they are ordered by the same rules
(last time I spent a day & the effect was negligible)


# T-T!
join -11 -22 VN_triplets.unl locus_voucher_triplets_all.tab  | cut -f1 |sort -u | wc -l
join: file 1 is not in sorted order
4571


# D-D  
join -11 -22 VN_doublets.unl locus_voucher_doublets_all.tab  | wc -l
join: file 2 is not in sorted order
0

# not surprising, VN only has a handful of doublets
cut -f1 -d \:  VN_doublets.unl | uniq
TTRS
grep "TTRS::"  locus_voucher_doublets_all.tab

# VN doublets confirmed for nothing.

### treat VN triplets as doublets

sed 's|:[^:]*:|::|g' VN_triplets.unl  | sort > VN_triplets_gutted.unl
head VN_triplets_gutted.unl

CAS::1
CAS::1
CAS::1
CAS::1
CAS::1
CAS::1
CAS::10
CAS::10
CAS::10
CAS::10

sort -u VN_triplets_gutted.unl > VN_triplets_gutted_distinct.unl

wc -l VN_triplets_gutted.unl VN_triplets_gutted_distinct.unl
  8214727 VN_triplets_gutted.unl
  5682825 VN_triplets_gutted_distinct.unl


join -11 -22 VN_triplets_gutted.unl locus_voucher_doublets_all.tab  | wc -l
join: file 2 is not in sorted order
join: file 1 is not in sorted order
104027  no change with explicit tab

join -11 -22 VN_triplets_gutted_distinct.unl locus_voucher_doublets_all.tab  | cut -f1 | sort -u | wc -l
join: file 2 is not in sorted order
join: file 1 is not in sorted order
58116

grep "TTRS:"  locus_voucher_triplets_all.tab

###################################################################

BOLD GB comparisons

bold 
/home/tomc/Projects/BiSciCol/Triples/BOLD_chordata/20131023/hillbilly/reclassify/
Gb
/home/tomc/Projects/BiSciCol/GenBankII/hillbilly


cat ID_sampleid_classified_blessed_only.tab ID_catalognum_classified_blessed_only.tab ID_agree_classified_blessed.tab | grep -v "::" | sort -k2,2 -> ID_all_triplets.tab
cat ID_sampleid_classified_blessed_only.tab ID_catalognum_classified_blessed_only.tab ID_agree_classified_blessed.tab | grep "::" | sort -k2,2 > ID_all_doublets.tab

# T-T
join -j2 -t '\\t' ./../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_triplets.tab locus_voucher_triplets_all.tab  | wc -l
67

# T-T!
join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_triplets.tab locus_voucher_triplets_all.tab | cut -f1 -d ' ' | sort -u |wc -l
60


# T-D
join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_triplets_gutted.tab locus_voucher_doublets_all.tab | wc -l
join: file 2 is not in sorted order
join: file 1 is not in sorted order
69

# T-D!
join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_triplets_gutted.tab locus_voucher_doublets_all.tab | cut -f1  -d ' '| sort -u | wc -l
join: file 2 is not in sorted order
join: file 1 is not in sorted order
30


# D-D
join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_doublets.tab locus_voucher_doublets_all.tab  | wc -l
join: file 2 is not in sorted order
283,875  ... that is a scary number

cut -f2  ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_doublets.tab  | sort | uniq -c | sort -nr | head 
    288 SAIAB::ES08
    115 SAIAB::ES07
     76 ECOCH::7192
     73 ECOCH::7009
     56 MNHN::2009
     52 ECOCH::6416
     42 ECOCH::6109
     41 ECOCH::5911
     35 SAIAB::ES06
     27 UAIC::14963.01
cut -f2  locus_voucher_doublets_all.tab  | sort | uniq -c | sort -nr | head 
   1587 LSUMZ::B927
   1585 LSUMZ::B1980
   1580 LSUMZ::B28330
   1574 LSUMZ::B37197
   1571 LSUMZ::B5354
   1550 LSUMZ::B7513
   1518 LSUMZ::B103926
   1492 LSUMZ::B7923
   1487 LSUMZ::B36554
   1486 LSUMZ::B37257

join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_doublets.tab locus_voucher_doublets_all.tab | cut -f1 -d ' '| sort |uniq -c | sort -nr | head
join: file 2 is not in sorted order
 221778 INIDEP::T
  16426 ZMMU::SVK
    858 NME::A
    670 ZMMU::RAN
    450 ZMMU::RYA
    364 NMP::6V
    364 BPBM::FR
    256 PIN::RVV
    256 MCZ::335
    192 SIO::93-298


ahh good old spaces within identifiers ...
2910202   INIDEP::T 0224

# Ctrl-v<tab> the -t 
join -j2 -t'' ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_doublets.tab locus_voucher_doublets_all.tab  | wc -l
join: file 1 is not in sorted order
42975


# D-D!
join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_doublets.tab locus_voucher_doublets_all.tab  | cut -f1  -d ' '| sort -u | wc -l
join: file 2 is not in sorted order
27,936

sed 's|:[^:]*:|::|g' locus_voucher_triplets_all.tab  | sort > locus_voucher_triplets_all_gutted.tab

# D-T

join -j2 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/ID_all_.tab locus_voucher_doublets_all_gutted.tab | wc -l
0
########################################################################
 
VN BOLD comparisons

from
/home/tomc/Projects/BiSciCol/Triples/BOLD_chordata/20131023/hillbilly/reclassify
and
/home/tomc/Projects/BiSciCol/GenBankII/hillbilly

# T-T
join -12 -21  ID_all_triplets.tab  ../../../../../GenBankII/hillbilly/VN_triplets.unl | wc -l
join: file 2 is not in sorted order
103   checked w/explicit tab: same

# T-D
join -12 -21  ID_all_doublets.tab  ../../../../../GenBankII/hillbilly/VN_triplets_gutted.unl |wc -l
join: file 2 is not in sorted order
30,161 checked w/explicit tab: same

# T-D!
join -12 -21  ID_all_doublets.tab  ../../../../../GenBankII/hillbilly/VN_triplets_gutted.unl | cut -f1 | sort -u |wc -l
join: file 2 is not in sorted order
18,766

# D-T
join -12 -21  ID_all_triplets_gutted.tab  ../../../../../GenBankII/hillbilly/VN_doublets.unl |wc -l
join: file 1 is not in sorted order
0     not checked as it ain't getting smaller

# D-D
join -12 -21  ID_all_doublets.tab ../../../../../GenBankII/hillbilly/VN_doublets.unl |wc -l
0


###########################################################################################
###################################################################################################
###################################################################################################
###################################################################################################
for the diagrams I really want just "all matches between sources" 

But to find the ones common to all three when they are all sliced and diced 
and needing to be reassembled is not a warm and fuzzy.

... in a sense we would gain some numbers (and accuracy) over the existing
process since it glosses over corner cases such as if a doublet matched a canonical.

least work would be to do bold in common with the other two 
then compare the results in the next round


so classify bold catalognum & sampleid then filter on IC
merge but only keep one copy of the overlap

../classify-dwct.reb --args "-i ../ID_sampleid.tab" > ID_sampleid_classified_all.tab 2> ID_sampleid_classified_all.err 
../classify-dwct.reb --args "-i ../ID_catalognum.tab" > ID_catalognum_classified_all.tab 2> ID_catalognum_classified_all.err

filter for blessed IC

../filter_known_ic.awk -v "FILTER=../../../../../GenBankII/IC_knownfilter.list2" <  ID_sampleid_classified_all.tab >  ID_sampleid_classified_blessed_all.tab
../filter_known_ic.awk -v "FILTER=../../../../../GenBankII/IC_knownfilter.list2" <  ID_catalognum_classified_all.tab >  ID_catalognum_classified_blessed_all.tab

comm -12 ID_catalognum_classified_blessed_all.tab ID_sampleid_classified_blessed_all.tab | wc -l
2248 (including ID and classification which don't matter)

cut -f2  ID_catalognum_classified_blessed_all.tab | sort >  catalognum_alldone.list
cut -f2   ID_sampleid_classified_blessed_all.tab | sort >   sampleid_alldone.list

comm -12  catalognum_alldone.list sampleid_alldone.list | wc -l
2280	meh
 
comm -12  catalognum_alldone.list sampleid_alldone.list > shared_alldone.list
comm -13  catalognum_alldone.list sampleid_alldone.list > sampleid_only_alldone.list
comm -23  catalognum_alldone.list sampleid_alldone.list > catalognum_only_alldone.list

wc -l shared_alldone.list sampleid_only_alldone.list catalognum_only_alldone.list
  2280 shared_alldone.list
 37701 sampleid_only_alldone.list
 25299 catalognum_only_alldone.list
 65280 total                          that is up about 600

cat shared_alldone.list sampleid_only_alldone.list catalognum_only_alldone.list |sort > bold_dwct_all.list
sort -u  bold_dwct_all.list | wc -l
57225                                    unique bold DwCT available


bolds list of 65,280 effective DwCT 
/home/tomc/Projects/BiSciCol/Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list

###################################################################################################
find ALL effective GenBank specimen_voucher DwcT 
starting in
/home/tomc/Projects/BiSciCol/GenBankII/hillbilly
starting with
/home/tomc/Projects/BiSciCol/GenBankII/voucher/locus_voucher.tab


./classify-dwct.reb  --args "-i ../voucher/locus_voucher.tab" > locus_voucher_classed_all.tab  2> locus_voucher_classed_all.err
./filter_known_ic.awk -v"FILTER=../IC_knownfilter.list2" <  locus_voucher_classed_all.tab  >  locus_voucher_classed_blessed_all.tab
 
 looks like I already did that ... 
 
 cut -f2 locus_voucher_classed_blessed_all.tab | sort > genbank_dwct_all.list

wc -l genbank_dwct_all.list
292,453 
sort -u genbank_dwct_all.list | wc -l 
123,111

GenBanks list of 292,453 effective DwCT 

/home/tomc/Projects/BiSciCol/GenBankII/hillbilly/genbank_dwct_all.list
#########################################################################################

VN should be easy 

sort -c VN_triplets.unl
yep.

----------------------------------------------------------------------------------
# exact (triplet or doublet)

comm  -12 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list genbank_dwct_all.list  > bold_genbank_exact.list
comm  -12 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list VN_triplets.unl  > bold_vn_exact.list

comm  -12 genbank_dwct_all.list VN_triplets.unl  > genbank_vertnet_exact.list

wc -l  bold_genbank_exact.list bold_vn_exact.list genbank_vertnet_exact.list
 32242 bold_genbank_exact.list
   103 bold_vn_exact.list
  2219 genbank_vertnet_exact.list
 34564 total

comm -12  bold_genbank_exact.list bold_vn_exact.list > bold_genbank_vn_exact.list
wc -l bold_genbank_vn_exact.list
45  --> all UAM:Mamm:xxx

----------------------------------------------------------------------------------------------------

# inexact with only one or the other being a natural doublet

comm  -23 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list genbank_dwct_all.list  > b-g.list
comm  -23 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list VN_triplets.unl  > b-v.list
comm  -23 genbank_dwct_all.list VN_triplets.unl  > g-v.list

comm  -13 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list genbank_dwct_all.list  > g-b.list
comm  -13 ../../Triples/BOLD_chordata/20131023/hillbilly/reclassify/bold_dwct_all.list VN_triplets.unl  > v-b.list
comm  -13 genbank_dwct_all.list VN_triplets.unl  > v-g.list



wc -l b-g.list  b-v.list  g-b.list  v-b.list g-v.list v-g.list
    33038 b-g.list
    65177 b-v.list
   260211 g-b.list
  8214624 v-b.list
   290234 g-v.list
  8212508 v-g.list

# force a new set of doublets the old natural doublets can try to match
# the (natural) ones that matched the first time are already merged co cna't be recounted now. 
cat bold_genbank_exact.list g-b.list | sed 's/:[^:]*:/::/g'| sort > bgUg-b_doublet.list
cat bold_vn_exact.list v-b.list | sed 's/:[^:]*:/::/g' | sort > bvUv-b_doublet.list
cat genbank_vertnet_exact.list v-g.list | sed 's/:[^:]*:/::/g' | sort > gvUv-g_doublet.list

head bgUg-b_doublet.list bvUv-b_doublet.list gvUv-g_doublet.list
wc -l bgUg-b_doublet.list bvUv-b_doublet.list gvUv-g_doublet.list
   292453 bgUg-b_doublet.list
  8214727 bvUv-b_doublet.list
  8214727 gvUv-g_doublet.list  
  
comm -12 b-g.list bgUg-b_doublet.list > bold_gb_inexact.list
comm -12 b-v.list bvUv-b_doublet.list > bold_vn_inexact.list
comm -12 g-v.list gvUv-g_doublet.list > gb_vn_inexact.list
 
wc -l bold_gb_inexact.list  bold_vn_inexact.list gb_vn_inexact.list
   466 bold_gb_inexact.list
 18200 bold_vn_inexact.list
 39755 gb_vn_inexact.list

-------------------------------------------------------------

cat  bold_genbank_exact.list b-g.list | sed 's/:[^:]*:/::/g'| sort > bgUb-g_doublet.list
cat  bold_vn_exact.list b-v.list      | sed 's/:[^:]*:/::/g'| sort > bvUb-v_doublet.list
cat genbank_vertnet_exact.list g-v.list | sed 's/:[^:]*:/::/g' | sort > gvUg-v_doublet.list

wc -l bgUb-g_doublet.list bvUb-v_doublet.list  gvUg-v_doublet.list
  65280 bgUb-g_doublet.list
  65280 bvUb-v_doublet.list
 292453 gvUg-v_doublet.list

comm -12 g-b.list bgUb-g_doublet.list > bold_gb_inexact2.list
comm -12 v-b.list bvUb-v_doublet.list > bold_vn_inexact2.list
comm -12 v-g.list gvUg-v_doublet.list > gb_vn_inexact2.list

wc -l  bold_gb_inexact2.list bold_vn_inexact2.list  gb_vn_inexact2.list
 2688 bold_gb_inexact2.list
    0 bold_vn_inexact2.list
    0 gb_vn_inexact2.list
 
comm -12  bold_gb_inexact.list bold_gb_inexact2.list
(nothing in common -> good)

cat bold_gb_inexact.list bold_gb_inexact2.list bold_genbank_exact.list | sort > bold_genbank_match_II_all.list
cat bold_vn_inexact.list bold_vn_inexact2.list bold_vn_exact.list | sort > bold_vernet__match_II_all.list

cat gb_vn_inexact.list gb_vn_inexact2.list genbank_vertnet_exact.list | sort > genbank_vernet__match_II_all.list

wc -l bold_genbank_match_II_all.list bold_vernet__match_II_all.list genbank_vernet__match_II_all.list
 35396 bold_genbank_match_II_all.list                                      ********************
 18303 bold_vernet__match_II_all.list                                      ********************
 41974 genbank_vernet__match_II_all.list                                  ********************
  95673 total


comm -12  bold_genbank_match_II_all.list bold_vernet__match_II_all.list > bold_genbank_vertnet_match_II_all
 wc -l bold_genbank_vertnet_match_II_all
16048   ding ding ding that is pretty much the number we needed.          ********************  

____________________________________________________________________________________________________

if we only want to count unique matches
sort -u  genbank_vernet__match_II_all.list | wc -l
sort -u  bold_vernet__match_II_all.list | wc -l
sort -u  bold_genbank_match_II_all.list | wc -l		
sort -u  bold_genbank_vertnet_match_II_all | wc -l

35280
17737
31139
15847 
 
 

