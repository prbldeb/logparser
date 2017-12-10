#!/usr/bin/env perl
# ---------------------------------------------------------------------------
#
# --------------------------------PURPOSE------------------------------------
#
# catalinaLogPareser.pl: For parsing any catalina.out for Java related exception
# works in any linux environment, having perl installed
#
# -------------------------HISTORY OF DEVELOPMENT----------------------------
#
# Current Version 1.0.0
#
# v1.0.0 (17/08/2015, prbldeb)
#  original implementation
#
# ---------------------------------------------------------------------------

# Add modules directory to @INC
BEGIN {
    my $cpanModulepath = ( $0 =~ m/^(.*)\// )[0] . "/modules/CPAN";
	push(@INC, $cpanModulepath);
}

# Flush Log
$| = 1;

# Module Usage
use strict;
use File::ReadBackwards;

# Record start time of operation
my $starttime = time();

# Options and default values
my $maxLine = 100000;
my $minLine = 100;
my $specfiedLine = 0;
my $inputFile = "";
my $exitDecision = 0;
my $searchDateInput = "";

# Check command line options
if ( @ARGV != 0 ) {
	while (( @ARGV != 0 ) and ( $ARGV[0] =~ m/^-/ )) {
		if ( $ARGV[0] =~ m/f/ ) {
            $inputFile = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
	    } elsif ( $ARGV[0] =~ m/l/ ) {
            $specfiedLine = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
        } elsif ( $ARGV[0] =~ m/d/ ) {
            $searchDateInput = $ARGV[1];
			shift(@ARGV);
			shift(@ARGV);
			next;
        } elsif ( $ARGV[0] =~ m/e/ ) {
            $exitDecision = 1;
			shift(@ARGV);
			next;
        } else {
			print "WARNING: Invalid Option " . $ARGV[0] . "\n";
			shift(@ARGV);
			next;
		}
	}
} else {
	print "ERROR: Invalid command line options - Check below Usage\n\n";
	print "USAGE:   $0 -f [Log File] -l [Line Number] -d [Search Date]\n\n\n";
	print "            -f   :   Input Log File, to be parsed (Mandatory)\n\n";
	print "            -l   :   Mention Line Number to search exception, range $minLine - $maxLine, default $minLine (Optional)\n\n";
	print "            -d   :   Mention Log for specific date, Format - yyyy-mm-dd (Optional)\n\n";
	print "            -e   :   If specified it will exit with error code 1, in case of Exception, default False (Optional)\n\n";
	exit (1);
}

# Validate Inputs
unless (($inputFile) && (-r $inputFile)) {
	die ("ERROR: An Input File must be specified, check usage by executing: $0 -h\n");
}
if ($specfiedLine) {
	$specfiedLine = $maxLine if ($specfiedLine > $maxLine);
} else {
	$specfiedLine = $minLine;
}

# Read the File Backward
my @fileContentBackward;
my $bw = File::ReadBackwards->new( $inputFile ) or die "ERROR: can't read $inputFile $!";
for (my $i=0; $i <= $specfiedLine; $i++) {
	if ( defined( my $log_line = $bw->readline ) ) {
		chomp($log_line);
		push (@fileContentBackward, $log_line);
	} else {
		last;
	}
}
$bw->close();

# Parse through cached content
my %errorCounts = ("SEVERE" => 0, "ERROR" => 0, "EXCEPTION" => 0, "WARNING" => 0);
my %errors = ("SEVERE" => "", "ERROR" => "", "EXCEPTION" => "", "WARNING" => "");
my $exitCode = 0;
my $exceptionTracker = 0;
foreach my $line (@fileContentBackward) {
	# Basic Patterns
	if ($line =~ m/SEVERE/) {
		$errors{"SEVERE"} = $errors{"SEVERE"} . "$line\n";
		$errorCounts{"SEVERE"} += 1;
		$exitCode = 1;
	} elsif ($line =~ m/ERROR/) {
		$errors{"ERROR"} = $errors{"ERROR"} . "$line\n";
		$errorCounts{"ERROR"} += 1;
		$exitCode = 1;
	} elsif ($line =~ m/WARNING/) {
		$errors{"WARNING"} = $errors{"WARNING"} . "$line\n";
		$errorCounts{"WARNING"} += 1;
	}
	
	# Java Exception
	if ($line =~ m/(^\s+|\t+)at /) {
		$exceptionTracker = 1;
		$exitCode = 1;
	}
	if (($exceptionTracker) && !($line =~ m/^(\s+|\t+)at /) && ($line ne "")) {
		$errors{"EXCEPTION"} = $errors{"EXCEPTION"} . "$line\n";
		$errorCounts{"EXCEPTION"} += 1;
		$exceptionTracker = 0;
	}
}

# Print the Result
print "==================== EXCEPTIONS =======================\n";
print $errors{"EXCEPTION"};
print "=======================================================\n\n";
print "====================== ERRORS =========================\n";
print $errors{"ERROR"};
print "=======================================================\n\n";
print "====================== SEVERES ========================\n";
print $errors{"SEVERE"};
print "=======================================================\n\n";
print "===================== SUMMARY =========================\n";
foreach my $type (keys %errorCounts) {
	print "Found Total $type \t= " . $errorCounts{$type} . "\n";
}
print "=======================================================\n";

# Exit and End of main Program
if (($exitDecision) && ($exitCode)) {
	print "ERROR: found execpetions and as -e specified, exiting with exit status $exitCode\n";
	exit ($exitCode);
} elsif ($exitCode) {
	print "WARNING: found exception but as -e not specified, exiting with exit status 0\n";
	exit (0);
} else {
	print "SUCCESS: no exception found, hence exeiting with exit status 0\n";
	exit (0);
}