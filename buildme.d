#!~/bin/dmd -run

/**
 * A program to easily build D DBI.
 *
 * The default release switches are -inline -O -ofdbi.lib -release.
 *
 * The default debug switches are -debug -g -ofdbi.lib -w.  To specify that this is a debug
 * build, use -debug when compiling buildme.
 *
 * The list of all databases is loaded automatically upon execution.  Anything that isn't
 * on that list is passed to the compiler.
 *
 * The use of odbc on a non-Windows system isn't allowed.
 *
 * Build is currently required.  It can be found at http://www.dsource.org/projects/build.
 *
 * This file must be run in the directory below dbi.
 *
 * Throws:
 *	Exception if odbc is requested on a non-Windows system.
 *
 *	Exception if a non-existant file is used as an argument.
 *
 *	Exception if a file is removed from the list of files to build despite it not being
 *	there to start with.
 *
 * Example:
 *	---
 *	dmd -run buildme.d all -oracle -d -D -mysql
 *	---
 *
 * See_Also:
 *	http://www.dsource.org/projects/ddbi/wiki/HowToBuild
 *
 * Authors:
 *	Written by James Pelcis.  Based on the building process used in the Derelict project.
 */
module buildme;

private import std.file, std.path, std.process, std.string;

/// The list of all the files that can be compiled.
bool[char[]] allList;

/// The files to pass to the compiler.
bool[char[]] toBuild;

/// The switches to pass to the compiler.
bool[char[]] switchesCompiler;

void main (char[][] args) {
	// Add the default switches.
	debug {
		switchesCompiler["-debug"] = true;
		switchesCompiler["-g"] = true;
		switchesCompiler["-w"] = true;
	} else {
		switchesCompiler["-release"] = true;
		switchesCompiler["-inline"] = true;
		switchesCompiler["-O"] = true;
	}
	switchesCompiler["-ofdbi"] = true;
	switchesCompiler["-allobj"] = true;
	switchesCompiler["-clean"] = true;
	switchesCompiler["-full"] = true;
	switchesCompiler["-lib"] = true;

	// Make the "all" list.
	chdir("dbi");
	foreach (char[] dir; listdir(getcwd())) {
		if (isdir(dir)) {
			allList[dir] = true;
		}
	}
	chdir(pardir);
	version (Windows) {
	} else {
		allList.remove("odbc");
	}

	// Parse the command line arguments.
	foreach (char[] arg; args[1 .. length]) {
		if (arg == "all") {
			toBuild = allList;
		} else if (arg in allList) {
			if (arg == "odbc") {
				version (Windows) {
					toBuild[arg] = true;
					break;
				} else {
					throw new Exception("Invalid argument \"odbc.\"  odbc can only be used on Windows.");
				}
			} else {
				toBuild[arg] = true;
			}
		} else if ((arg[0] == '-') && (arg[1 .. length] in allList)) {
			if (arg[1 .. length] in toBuild) {
				toBuild.remove(arg[1 .. length]);
			} else {
				throw new Exception("Invalid argument \"" ~ arg ~ ".\"  \"" ~ arg[1 .. length] ~ "\" isn't on the list of DBDs to build.");
			}
		} else {
			switchesCompiler[arg] = true;
		}
	}

	// Build the files.
	char[][] buildCommand = switchesCompiler.keys;
	buildCommand ~= "dbi" ~ sep ~ "all.d";
	foreach (char[] file; toBuild.keys) {
		buildCommand ~= ("dbi" ~ sep ~ file ~ sep ~ "all.d");
	}
	if (system("build " ~ std.string.join(buildCommand, " "))) {
		system("pause");
	}
}