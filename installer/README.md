This directory contains scripts to create a windows msi installer.
The hard work to make an executable with an embeded perl interpreter
is done by [PAR-Packer] [1]. It may seems rather pointless to go that
length, only to bundle a perl script that acts as a call wrapper for
a c++ library. Nevertheless I had all the ingredients available and
well tested and it took me only a few hours to put it all together. 

[1]: http://search.cpan.org/~rschupp/PAR-Packer-1.025/lib/PAR/Packer.pm