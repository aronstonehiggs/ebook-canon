#!/usr/bin/perl
use strict;
use warnings;
use File::Copy qw(copy move);
use File::Spec;
use Time::HiRes qw(usleep);  # For precise microsecond sleep

# Main function
sub main {
    my ($md_filename, $directory) = @_;

    # Construct full path to the Markdown file
    my $md_filepath = File::Spec->catfile($directory, "$md_filename.md");

    # Validate input parameters
    validate_inputs($md_filepath, $directory);

    # Extract filenames from the Markdown file
    my @file_names = extract_filenames($md_filepath);

    # Update creation times of the extracted files
    update_creation_times(\@file_names, $directory);
}

# Validate that the directory and Markdown file exist
sub validate_inputs {
    my ($md_filepath, $directory) = @_;

    die "Usage: $0 <Markdown file> [Target directory]\n" unless $md_filepath;
    die "Error: File '$md_filepath' not found!\n" unless -e $md_filepath;
    die "Error: Directory '$directory' not found!\n" unless -d $directory;
}

# Extract filenames from the Markdown file
sub extract_filenames {
    my ($md_filepath) = @_;
    
    # Get the base filename (without .md extension)
    my ($md_filename) = $md_filepath =~ m{([^/]+)\.md$};

    # First item in the list is the original Markdown file itself
    my @file_names = ();

    open my $fh, '<', $md_filepath or die "Cannot open file '$md_filepath': $!\n";

    while (<$fh>) {
        # Extract the right-hand side of `|` in `[[...|filename]]`
        if (/\[\[.*?\|(.*?)\]\]/) {
            push @file_names, "$1.md";
        }
    }
    
    close $fh;
    return @file_names;
}

# Update file creation times by copying and replacing files
sub update_creation_times {
    my ($file_names_ref, $directory) = @_;

    foreach my $file (@$file_names_ref) {
        my $file_path = File::Spec->catfile($directory, $file);  # Construct full file path

        if (-e $file_path) {
            print "Updating creation time: $file_path\n";
            my $temp_file = "$file_path.tmp";

            # Copy the file to a temporary file
            copy($file_path, $temp_file) or die "Error: Cannot copy $file_path: $!\n";

            # Replace the original file with the copied one to reset creation time
            move($temp_file, $file_path) or die "Error: Cannot replace $file_path: $!\n";

            # Wait 1 millisecond before processing the next file
            usleep(10000);  # 1000 microseconds = 1 millisecond
        } else {
            print "Warning: File not found: $file_path\n";
        }
    }

    print "All matching files have been updated.\n";
}

# Read command-line arguments
my $md_file = shift @ARGV or die "Usage: $0 <Markdown file> [Target directory]\n";
my $target_dir = shift @ARGV // ".";  # Default to current directory if not specified

# Run the script
main($md_file, $target_dir);
