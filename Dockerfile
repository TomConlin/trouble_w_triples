# Dockerfile for the BiDciCol projects 
# "Trouble with Triples" datasets
# pin to  "CentOS release 6.5 (Final)" ?

FROM saltstack/centos-6-minimal

# append a new date or something to force nocache 
MAINTAINER  Tom Conlin
CMD ["yum -y update"]

# set up a non root user just because? 
#RUN useradd -m -p $(perl -e'print crypt("", "aa")') doc

# set up a place to do the work
RUN mkdir -p /Project/bin
WORKDIR /Project

RUN mkdir /Project/rawdata

ENV PATH /Project/bin/:/usr/local/bin:/bin:/usr/bin

####################################################
# we have a number of shell scripts 
# and the Rebol interpreter to collect under bin/
# (it will not add wildcards )
# cp ../GenBankII/hillbilly/filter_known_ic.awk bin/filter_known_ic.awk
# cp ../GenBankII/hillbilly/classify-dwct.reb bin/classify-dwct.reb
# cp ../GenBankII/hillbilly/parse-dwct.reb bin/parse-dwct.reb

ADD bin/filter_known_ic.awk /Project/bin/
ADD bin/classify-dwct.reb /Project/bin/
ADD bin/parse-dwct.reb /Project/bin/
ADD bin/rebol /Project/bin/

################################################
# Bring in the voucher related data fields 
# isolated from the repositories (~160M)
# and the set of IC codes curated by Nico & Rob
# and protect them from changing
#
# cp /home/tomc/Projects/BiSciCol/Triples/BOLD_chordata/20131023/sampleid_catalognum_bold_gbacc.tab rawdata/sampleid_catalognum_bold_gbacc.tab
# cp /home/tomc/Projects/BiSciCol/GenBankII/voucher/locus_voucher.tab rawdata/locus_voucher.tab
# cp /home/tomc/Projects/BiSciCol/GenBankII/voucher/VN_vouchers.unl rawdata/VN_vouchers.unl 
# cp /home/tomc/Projects/BiSciCol/GenBankII/IC_knownfilter.list2 rawdata/IC_knownfilter.list

ADD rawdata/sampleid_catalognum_bold_gbacc.tab.gz /Project/rawdata/
ADD rawdata/locus_voucher.tab.gz /Project/rawdata/
ADD rawdata/VN_vouchers.unl.gz /Project/rawdata/
ADD rawdata/IC_knownfilter.list /Project/rawdata/
RUN chmod -R a-w /Project/rawdata


########################################
# set up Rebol interpreter environment 
# (this one in bin still has a legacy 32 bit dependency)
RUN yum -y install glibc.i686

##################################################
# with infrastructure in place 
# continue towards process

# A place to put processed data files
RUN mkdir /Project/data

ADD README /Project/
ADD  Fetch_Repositories.txt /Project/

# put something up for folks just getting started?
# ADD tldr  /Project/
# CMD ["cat /Project/tldr"]

