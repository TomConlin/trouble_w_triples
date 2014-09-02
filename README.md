This README is an attempt to replicate processes occurring on a local server during 2013-2014 within this Docker image now.

To replicate this process with current data from the three repositories instead of the canned snapshots found in the directory 'rawdata' please see the Fetch_repositories.txt.  
(You will need more disk storage space than this Docker image has.)  

There are many excellent tutorials on starting up a Docker container which will amount to installing Docker then issuing a variant of:
```
   docker pull tomc/trouble_w_triples
   docker run -i -t tomc/trouble_w_triples:initial /bin/bash
```
the remainder of this text assumes you are at the command prompt within the Docker container.

By only keeping the fields from the repositories actually needed to replicate the studies in the triplets paper, the raw data is about 160M uncompressed and about 26M gzipped:

	ls -1 rawdata/
	IC_knownfilter.list						# (P.I.) curated list of institution codes
	VN_vouchers.unl.gz						# well formed DwCT assembled from VertNet's ic cc & cn
	locus_voucher.tab.gz					# the locus and specimen_voucher field from vertebrate GenBank divisions
	sampleid_catalognum_bold_gbacc.tab.gz	# four fields from BOLD chordate records 2 might have DwCTs

The gzipped files are write protected so we always have a pristine copy to fall back on if our experiments become unintentionally destructive. 

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
When we are only looking at alternatively represented DwCT, the canonical DwCT can be counted then filtered out.  
here I am using an '_x' to in the file names to indicate canonical DwD have been removed
### Filter out canonical vouchers:
	grep -Ev  "[A-Z]{2,6}\:[A-Z][a-z]+\:.*[0-9]+.*" data/locus_voucher.tab > data/locus_voucher_x.tab   
	wc -l data/locus_voucher_x.tab  
	585257 data/locus_voucher_x.tab  

check if the locus are a Primary Key (unique):  

	cut -f1 data/locus_voucher_x.tab | sort -u | wc -l  
	585159


LOCUS is not quite a primary key in this case. ~ 100 duplicated locus IDs, but no worries, we are just checking out of curiosity.  (99.98% unique)  

#### Classify:
	bin/classify-dwct.reb --args "-i data/locus_voucher_x.tab" > data/locus_voucher_x_classed.tab 2> data/locus_voucher_x_classed.err
	wc -l data/locus_voucher_x_classed.tab
	433782

The error file has attempts which could not be parsed:

	cat data/locus_voucher_x_classed.err
	::R12074 129 ::cn 

just this one without a viable IC.  

The classification process allows for multiple DwCT per record, so the number of duplicate locus IDs can go up:..

	cut -f1 data/locus_voucher_x_classed.tab | sort -u | wc -l
	423829  

We do not know how many of the original ~100 duplications made it in to this set of duplications
but there are now 9,953 duplications on this parsed side. (down to 97.7% unique)  

#### Filter for known Institution codes:
	bin/filter_known_ic.awk -v"FILTER=rawdata/IC_knownfilter.list" <  data/locus_voucher_x_classed.tab >  data/locus_voucher_x_classed_blessed.tab
	wc -l  data/locus_voucher_x_classed_blessed.tab
	282,056 data/locus_voucher_classed_blessed.tab
	
	cut -f1 data/locus_voucher_classed_blessed.tab | sort -u | wc -l
	279,473

leaving 2,583 locus with alternative (or duplicate) DwCT (back up to 99.08% unique).  


### Report

The classifier reports on the types of issues it comes across changing a string into a DwCT
but the main classes of issues can be seen in the error flag returned.
* a non zero error flag means the classifier found something wrong
* an even error flag means semantic issues exist 
* an odd error flag means syntactic issues exist
* an odd error flag greater than one means both type of issues exist

An error flag of 0 would be no errors, but we filtered for canonical when we began so there should not be any
the zeros here turn out to be cases where they only gave one of the two colons 
and I took a foolish shortcut and figured if they were using colons in one part then they were using colons in both parts: (TODO: fix & rerun)

	cat data/locus_voucher_x_classed_blessed.tab | wc -l
	282,056

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
	
	--------------------------------
		188,112		93,944

	188,112 syntactic  	( 1,984 only)  
	280,075 semantic    (93,947 only) 
	186,128 both		 



	cut -f2 data/locus_voucher_x_classed_blessed.tab | sort -u | wc -l
	116,909 


  282,056 / 116,909 = 2.412
Appears to a fair amount of duplication, on _average_ every non-canonical DwCT seems to shows up more than twice
lets see if that is true.  

Remember this next command produces a distribution of counts for duplications, so the first number is how many non-canonical DwCT appeared, the second number of times":

	cut -f2 data/locus_voucher_x_classed_blessed.tab |sort | uniq -c | awk '{print $1}' | sort -n | uniq -c | sort -k1,1nr -k2,2n
    73958 1  (unique non-canonical DwCT)
    18999 2
     8075 3
     4982 4
     3374 5
     2078 6
     1338 7
     1210 8
      784 10
      583 9
      219 12
      172 13
      141 11
      130 14
       99 17
       97 15
       93 16
       53 21
       49 18
       42 20
       36 22
       34 35
       33 19
       32 28
       28 23
       27 27
       26 26
       25 25
       22 24
       22 29
       13 30
       10 43
       8 33
       8 42
       7 34
       7 45
       6 36
       6 46
       5 31
       5 32
       5 38
       5 41
       4 40
       4 44
       4 48
       3 37
       3 39
       3 49
       3 50
      1 53
      1 62
      1 67
      1 76
      1 85
      1 91
      1 120
      1 327
      1 533
      1 593
      1 602
      1 649
      1 653
      1 670
      1 694
      1 731
      1 753
      1 756
      1 959
      1 1117
      1 1130
      1 1257
      1 1296
      1 1337
      1 1351
      1 1425
      1 1450
      1 1464
      1 1476
      1 1486
      1 1487
      1 1492
      1 1518
      1 1550
      1 1571
      1 1574
      1 1580
      1 1585
      1 1587

Since a couple dozen non-canonical DwCT appeared around a thousand times each 
and a majority of the non-canonical DwCT appeared only once (73,958 of the 116,909 or 63.26%) I think it is safe to assume we have fundamentally different populations mixed together here, a slight majority where there is __a__ sequence per specimen and another where there are __many__ sequences per specimen. 

---
####We are also interested in all DwCT (without filtering out canonical):


	bin/classify-dwct.reb --args "-i data/locus_voucher.tab" > data/locus_voucher_classed_all.tab 2> data/locus_voucher_classed_all.err
	bin/filter_known_ic.awk -v"FILTER=rawdata/IC_knownfilter.list" <  data/locus_voucher_classed_all.tab >  data/locus_voucher_classed_blessed_all.tab
	grep "::" data/locus_voucher_classed_blessed_all.tab | sort -k2,2 -t $'\t' > data/locus_voucher_doublets_all.tab
	grep -v "::" data/locus_voucher_classed_blessed_all.tab | sort -k2,2 -t $'\t' > data/locus_voucher_triplets_all.tab
	
	wc -l data/locus_voucher_classed_all.tab data/locus_voucher_classed_blessed_all.tab data/locus_voucher_doublets_all.tab data/locus_voucher_triplets_all.tab
	  444191 locus_voucher_classed_all.tab
	  292453 locus_voucher_classed_blessed_all.tab
	  279279 locus_voucher_doublets_all.tab
	   13174 locus_voucher_triplets_all.tab
	 1029097 total


=========
#VN GB comparisons

Initial datasource:
```
	wc -l data/VN_vouchers.unl
	8216424 data/VN_vouchers.unl

	grep -v "::" data/VN_vouchers.unl | sort > data/VN_triplets.unl
	grep "::" data/VN_vouchers.unl  | sort > data/VN_doublets.unl

```
### T-T: (triple to triple comparison)
	join -11 -22 data/VN_triplets.unl data/locus_voucher_triplets_all.tab  | wc -l
	4571
	
#### T-T!: (unique! triple to triple comparison)
	join -11 -22 data/VN_triplets.unl data/locus_voucher_triplets_all.tab  | cut -f1 |sort -u | wc -l
	4571


#### D-D: (doublet to doublet comparison)
	join -11 -22 data/VN_doublets.unl data/locus_voucher_doublets_all.tab  | wc -l
	0

not surprising, VN only has a handful of doublets:
	cut -f1 -d \:  data/VN_doublets.unl | uniq
	TTRS
	grep "TTRS::"  data/locus_voucher_doublets_all.tab

VN doublets confirmed for not existing in GB doublets.  

### treat VN triplets as doublets: (omit the collection code)
	sed 's|:[^:]*:|::|g' data/VN_triplets.unl  | sort > data/VN_triplets_gutted.unl
	head data/VN_triplets_gutted.unl
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
	
	sort -u data/VN_triplets_gutted.unl > data/VN_triplets_gutted_distinct.unl
	
	wc -l data/VN_triplets_gutted.unl data/VN_triplets_gutted_distinct.unl
	  8214727 data/VN_triplets_gutted.unl
	  5682825 data/VN_triplets_gutted_distinct.unl
	
	join -11 -22 data/VN_triplets_gutted.unl data/locus_voucher_doublets_all.tab  | wc -l
	104027
	
	join -11 -22 data/VN_triplets_gutted_distinct.unl data/locus_voucher_doublets_all.tab  | cut -f1 | sort -u | wc -l
	58116

	grep "TTRS:"  data/locus_voucher_triplets_all.tab

just checking if the institution with VN doublets appears in GB triples. it does not.
========

#BOLD GB comparisons


	`cat data/ID_sampleid_classified_blessed_only.tab data/ID_catalognum_classified_blessed_only.tab data/ID_agree_classified_blessed.tab | grep -v "::" | sort -k2,2 -> data/ID_all_triplets.tab`
  
	`cat data/ID_sampleid_classified_blessed_only.tab data/ID_catalognum_classified_blessed_only.tab data/ID_agree_classified_blessed.tab | grep "::" | sort -k2,2 > data/ID_all_doublets.tab`  

#### T-T:
	join -j2 -t '\\t' data/ID_all_triplets.tab data/locus_voucher_triplets_all.tab  | wc -l
	67

#### T-T!:
	join -j2 data/ID_all_triplets.tab data/locus_voucher_triplets_all.tab | cut -f1 -d ' ' | sort -u |wc -l
	60

#### T-D:
	join -j2 data/ID_all_triplets_gutted.tab data/locus_voucher_doublets_all.tab | wc -l
	join: file 2 is not in sorted order
	join: file 1 is not in sorted order
	69

#### T-D!:
	join -j2 data/ID_all_triplets_gutted.tab data/locus_voucher_doublets_all.tab | cut -f1  -d ' '| sort -u | wc -l
	join: file 2 is not in sorted order
	join: file 1 is not in sorted order
	30


#### D-D:
	join -j2 data/ID_all_doublets.tab data/locus_voucher_doublets_all.tab  | wc -l
	join: file 2 is not in sorted order
	283,875  ... that is a scary number
	
	cut -f2  data/ID_all_doublets.tab  | sort | uniq -c | sort -nr | head 
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

	cut -f2  data/locus_voucher_doublets_all.tab  | sort | uniq -c | sort -nr | head 
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
	
	join -j2 data/ID_all_doublets.tab data/locus_voucher_doublets_all.tab | cut -f1 -d ' '| sort |uniq -c | sort -nr | head
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


ahh good! the old spaces within identifiers ...
2910202   INIDEP::T 0224

# Ctrl-v<tab> the -t 
join -j2 -t'' data/ID_all_doublets.tab data/locus_voucher_doublets_all.tab  | wc -l
join: file 1 is not in sorted order
42975


#### D-D!:
	join -j2 data/ID_all_doublets.tab data/locus_voucher_doublets_all.tab  | cut -f1  -d ' '| sort -u | wc -l
	join: file 2 is not in sorted order
	27,936
	
	sed 's|:[^:]*:|::|g' data/locus_voucher_triplets_all.tab  | sort > data/locus_voucher_triplets_all_gutted.tab

### D-T:
	join -j2 data/reclassify/ID_all_.tab data/locus_voucher_doublets_all_gutted.tab | wc -l
	0

========

#VN BOLD comparisons



#### T-T:
	join -12 -21  data/ID_all_triplets.tab  data/VN_triplets.unl | wc -l
	join: file 2 is not in sorted order
	103   checked w/explicit tab: same

#### T-D:
	join -12 -21  data/ID_all_doublets.tab  data/VN_triplets_gutted.unl |wc -l
	join: file 2 is not in sorted order
	30,161 checked w/explicit tab: same

#### T-D!:
	join -12 -21  data/ID_all_doublets.tab  data/VN_triplets_gutted.unl | cut -f1 | sort -u |wc -l
	join: file 2 is not in sorted order
	18,766

#### D-T:
	join -12 -21  data/ID_all_triplets_gutted.tab  data/VN_doublets.unl |wc -l
	join: file 1 is not in sorted order
	0     not checked as it ain't getting no smaller

#### D-D:
	join -12 -21  data/ID_all_doublets.tab data/VN_doublets.unl |wc -l
	0


=========
=========
For the diagrams I really just want "all matches between sources"   

But to find the ones common to all three when they are all sliced and diced 
and needing to be reassembled is not a warm and fuzzy.  

... in a sense we would gain some numbers (and accuracy) over the existing
process since it glosses over corner cases such as if a doublet matched a canonical.  

least work would be to do bold in common with the other two then compare the results in the next round  


so classify bold catalognum & sampleid then filter on IC merge but only keep one copy of the overlap:\
	bin/classify-dwct.reb --args "-i data/ID_sampleid.tab" > data/ID_sampleid_classified_all.tab 2> data/ID_sampleid_classified_all.err 
	bin/classify-dwct.reb --args "-i data/ID_catalognum.tab" > data/ID_catalognum_classified_all.tab 2> data/ID_catalognum_classified_all.err

filter for blessed IC:
	bin/filter_known_ic.awk -v "FILTER=rawdata/IC_knownfilter.list" <  data/ID_sampleid_classified_all.tab >  data/ID_sampleid_classified_blessed_all.tab
	bin/filter_known_ic.awk -v "FILTER=rawdata/GenBankII/IC_knownfilter.list" <  data/ID_catalognum_classified_all.tab >  data/ID_catalognum_classified_blessed_all.tab
	
	comm -12 data/ID_catalognum_classified_blessed_all.tab data/ID_sampleid_classified_blessed_all.tab | wc -l
	2248 (including ID and classification which don't matter)
	
	cut -f2 data/ID_catalognum_classified_blessed_all.tab | sort >  data/catalognum_alldone.list
	cut -f2 data/ID_sampleid_classified_blessed_all.tab | sort >   data/sampleid_alldone.list
	
	comm -12  data/catalognum_alldone.list data/sampleid_alldone.list | wc -l
	2280	meh
	
	comm -12  data/catalognum_alldone.list data/sampleid_alldone.list > data/shared_alldone.list
	comm -13  data/catalognum_alldone.list data/sampleid_alldone.list > data/sampleid_only_alldone.list
	comm -23  data/catalognum_alldone.list data/sampleid_alldone.list > data/catalognum_only_alldone.list
	
	wc -l data/shared_alldone.list data/sampleid_only_alldone.list data/catalognum_only_alldone.list
	  2280 data/shared_alldone.list
	 37701 data/sampleid_only_alldone.list
	 25299 data/catalognum_only_alldone.list
	 65280 total                          that is up about 600
	
	cat data/shared_alldone.list data/sampleid_only_alldone.list data/catalognum_only_alldone.list |sort > data/bold_dwct_all.list
	sort -u  data/bold_dwct_all.list | wc -l
	57225                                    unique bold DwCT available

bolds list of 65,280 effective DwCT 
	data/bold_dwct_all.list


find ALL effective GenBank specimen_voucher DwcT: 

	bin/classify-dwct.reb  --args "-i data/locus_voucher.tab" > data/locus_voucher_classed_all.tab  2> data/locus_voucher_classed_all.err
	bin/filter_known_ic.awk -v"FILTER=rawdata/IC_knownfilter.list" <  data/locus_voucher_classed_all.tab  >  data/locus_voucher_classed_blessed_all.tab
 
 
	cut -f2 data/locus_voucher_classed_blessed_all.tab | sort > data/genbank_dwct_all.list

	wc -l data/genbank_dwct_all.list
	292,453 
	sort -u data/genbank_dwct_all.list | wc -l 
	123,111

GenBanks list of 292,453 effective DwCT 

	data/genbank_dwct_all.list


VN should be easy 

	sort -c data/VN_triplets.unl
yep.

----------------------------------------------------------------------------------
### exact (triplet or doublet)

	comm  -12 data/bold_dwct_all.list data/genbank_dwct_all.list  > data/bold_genbank_exact.list
	comm  -12 data/bold_dwct_all.list data/VN_triplets.unl  > data/bold_vn_exact.list
	comm  -12 data/genbank_dwct_all.list data/VN_triplets.unl  > data/genbank_vertnet_exact.list
	
	wc -l  data/bold_genbank_exact.list data/bold_vn_exact.list data/genbank_vertnet_exact.list
 32242 data/bold_genbank_exact.list
   103 data/bold_vn_exact.list
  2219 data/genbank_vertnet_exact.list
 34564 total

comm -12  data/bold_genbank_exact.list data/bold_vn_exact.list > data/bold_genbank_vn_exact.list
wc -l data/bold_genbank_vn_exact.list
45  --> all UAM:Mamm:xxx

----------------------------------------------------------------------------------------------------

#### inexact with only one or the other being a natural doublet

	comm -23 data/bold_dwct_all.list data/genbank_dwct_all.list  > data/b-g.list
	comm -23 data/bold_dwct_all.list data/VN_triplets.unl  > data/b-v.list
	comm -23 genbank_dwct_all.list data/VN_triplets.unl  > data/g-v.list

	comm -13 data/bold_dwct_all.list data/genbank_dwct_all.list  > data/g-b.list
	comm -13 data/bold_dwct_all.list data/VN_triplets.unl  > data/v-b.list
	comm -13 data/genbank_dwct_all.list data/VN_triplets.unl  > data/v-g.list


	wc -l data/b-g.list  data/b-v.list  data/g-b.list  data/v-b.list data/g-v.list data/v-g.list
      33038 data/b-g.list
      65177 data/b-v.list
     260211 data/g-b.list
    8214624 data/v-b.list
     290234 data/g-v.list
    8212508 data/v-g.list

force a new set of doublets the old natural doublets can try to match the (natural) ones that matched the first time are already merged so can't be recounted now.:
 
	cat data/bold_genbank_exact.list data/g-b.list | sed 's/:[^:]*:/::/g'| sort > data/bgUg-b_doublet.list
	cat data/bold_vn_exact.list data/v-b.list | sed 's/:[^:]*:/::/g' | sort > data/bvUv-b_doublet.list
	cat data/genbank_vertnet_exact.list data/v-g.list | sed 's/:[^:]*:/::/g' | sort > data/gvUv-g_doublet.list

	#head data/bgUg-b_doublet.list data/bvUv-b_doublet.list data/gvUv-g_doublet.list
	wc -l data/bgUg-b_doublet.list data/bvUv-b_doublet.list data/gvUv-g_doublet.list
   292453 data/bgUg-b_doublet.list
  8214727 data/bvUv-b_doublet.list
  8214727 data/gvUv-g_doublet.list  
  
	comm -12 data/b-g.list data/bgUg-b_doublet.list > data/bold_gb_inexact.list
	comm -12 data/b-v.list data/bvUv-b_doublet.list > data/bold_vn_inexact.list
	comm -12 data/g-v.list data/gvUv-g_doublet.list > data/gb_vn_inexact.list
 
wc -l data/bold_gb_inexact.list  data/bold_vn_inexact.list data/gb_vn_inexact.list
   466 data/bold_gb_inexact.list
 18200 data/bold_vn_inexact.list
 39755 data/gb_vn_inexact.list

-------------------------------------------------------------

	cat data/bold_genbank_exact.list b-g.list | sed 's/:[^:]*:/::/g'| sort > data/bgUb-g_doublet.list
	cat data/bold_vn_exact.list b-v.list      | sed 's/:[^:]*:/::/g'| sort > data/bvUb-v_doublet.list
	cat data/genbank_vertnet_exact.list g-v.list | sed 's/:[^:]*:/::/g' | sort > data/gvUg-v_doublet.list

	wc -l data/bgUb-g_doublet.list data/bvUb-v_doublet.list  data/gvUg-v_doublet.list
    65280 data/bgUb-g_doublet.list
    65280 data/bvUb-v_doublet.list
   292453 data/gvUg-v_doublet.list

	comm -12 g-b.list data/bgUb-g_doublet.list > data/bold_gb_inexact2.list
	comm -12 v-b.list data/bvUb-v_doublet.list > data/bold_vn_inexact2.list
	comm -12 v-g.list data/gvUg-v_doublet.list > data/gb_vn_inexact2.list

	wc -l data/bold_gb_inexact2.list data/bold_vn_inexact2.list  data/gb_vn_inexact2.list
   2688 data/bold_gb_inexact2.list
      0 data/bold_vn_inexact2.list
      0 data/gb_vn_inexact2.list
 
	comm -12  data/bold_gb_inexact.list data/bold_gb_inexact2.list
(nothing in common -> good)

	cat data/bold_gb_inexact.list data/bold_gb_inexact2.list data/bold_genbank_exact.list | sort > data/bold_genbank_match_II_all.list
	cat data/bold_vn_inexact.list data/bold_vn_inexact2.list data/bold_vn_exact.list | sort > data/bold_vernet__match_II_all.list

	cat gb_vn_inexact.list gb_vn_inexact2.list genbank_vertnet_exact.list | sort > data/genbank_vernet__match_II_all.list

wc -l data/bold_genbank_match_II_all.list data/bold_vernet__match_II_all.list data/genbank_vernet__match_II_all.list
   35396 data/bold_genbank_match_II_all.list                                     ********************
   18303 data/bold_vernet__match_II_all.list                                     ********************
   41974 data/genbank_vernet__match_II_all.list                                  ********************
   95673 total


	comm -12  data/bold_genbank_match_II_all.list data/bold_vernet__match_II_all.list > data/bold_genbank_vertnet_match_II_all
 	wc -l data/bold_genbank_vertnet_match_II_all
	16,048   ding ding ding that is pretty much the number we needed.          ********************  

____________________________________________________________________________________________________

####if we only want to count unique matches:
	sort -u  data/genbank_vernet_match_II_all.list | wc -l
	sort -u  data/bold_vernet_match_II_all.list | wc -l
	sort -u  data/bold_genbank_match_II_all.list | wc -l		
	sort -u  data/bold_genbank_vertnet_match_II_all | wc -l

35280
17737
31139
15847 

