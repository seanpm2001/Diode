// Copyright © 2015-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
/**
 * Holds the main function and some small test code.
 */
module main;

import diode.tester;
import diode.license;
import diode.interfaces;


fn main(args: string[]) i32
{
	if (args.length == 1) {
		io.error.writefln("Usage:");
		io.error.writefln("\t--test   <source.liquid> <result.txt>");
		io.error.writefln("\t--src    <sourceDir>");
		io.error.writefln("\t--out    <outputDir>");
		io.error.flush();
		return 0;
	}

	if (args.length > 1 && args[1] == "--test") {
		return runTest(args);
	}
	return test(args);
}


/*
 *
 * A bunch of test code.
 *
 */

import io = watt.io;
import watt.io.streams;
import watt.io.file : read, exists, searchDir, isDir, isFile;
import watt.path : dirSeparator;
import watt.text.string : endsWith;
import watt.text.sink;
import watt.text.format;

import diode.driver;
import diode.interfaces;

enum ParseState
{
	Normal,
	OutputDir,
	SourceDir,
}

fn parseArgs(args: string[], s: Settings) string[]
{
	state := ParseState.Normal;
	files: string[];

	foreach (arg; args[1 .. $]) {
		final switch (state) with (ParseState) {
		case Normal:
			switch (arg) {
			case "--src": state = SourceDir; break;
			case "--out": state = OutputDir; break;
			default:
				files ~= arg;
			}
			continue;
		case SourceDir: s.sourceDir = arg; break;
		case OutputDir: s.outputDir = arg; break;
		}
		state = ParseState.Normal;
	}

	return files;
}

fn test(args: string[]) i32
{
	s := new Settings();
	s.sourceDir = "example";
	s.outputDir = "output";
	files := parseArgs(args, s);
	s.fillInDefaults();

	d := new DiodeDriver(s);
	d.addBuiltins();
	d.addLayouts();
	d.addIncludes();
	d.addVdocTemplates();
	d.addFiles(files);
	d.processDoc();
	d.renderFiles();

	return 0;
}

fn addFiles(d: DiodeDriver, files: string[])
{
	foreach (file; files) {
		if (!file.endsWith(".json")) {
			io.error.writefln("unknown file type '%s'", file);
			io.error.flush();
			continue;
		}

		if (!isFile(file)) {
			io.error.writefln("file not found '%s'", file);
			io.error.flush();
			continue;
		}

		str := cast(string)read(file);
		d.addDoc(str, file);
	}
}

fn renderFiles(d: Driver)
{
	srcDir := d.settings.sourceDir;
	outDir := d.settings.outputDir;

	if (!isDir(srcDir)) {
		d.info("source dir not found '%s'", srcDir);
		return;
	}
	if (!isDir(outDir)) {
		d.info("output dir not found '%s'", outDir);
		return;
	}

	fn hit(file: string) {
		srcPath := srcDir ~ dirSeparator ~ file;
		outPath := outDir ~ dirSeparator ~ file;

		if (!isFile(srcPath)) {
			return;
		}

		if (endsWith(outPath, ".md")) {
			outPath = outPath[0 .. $ - 3] ~ ".html";
		}


		str := cast(string)read(srcPath);
		str = d.renderFile(str, srcPath);

		d.info("writing '%s' to '%s'", srcPath, outPath);

		o := new OutputFileStream(outPath);
		o.writefln("%s", str);
		o.flush();
		o.close();
	}

	searchDir(srcDir, "*", hit);
}

fn addLayouts(d: Driver)
{
	dir := d.settings.layoutDir;
	if (!isDir(dir)) {
		d.info("dir not found '%s'", dir);
		return;
	}

	fn hit(file: string) {
		if (isDir(file)) {
			return;
		}
		fullpath := dir ~ dirSeparator ~ file;
		str := cast(string)read(fullpath);
		d.addLayout(str, fullpath);
	}

	searchDir(dir, "*.html", hit);
}

fn addIncludes(d: Driver)
{
	dir := d.settings.includeDir;
	if (!isDir(dir)) {
		d.info("dir not found '%s'", dir);
		return;
	}

	fn hit(file: string) {
		if (isDir(file)) {
			return;
		}
		fullpath := dir ~ dirSeparator ~ file;
		str := cast(string)read(fullpath);
		d.addInclude(str, fullpath);
	}

	// Add user provided includes, these can overwite the builtin ones.
	searchDir(dir, "*", hit);
}

fn addVdocTemplates(d: Driver)
{
	dir := d.settings.vdocDir;
	if (!isDir(dir)) {
		d.info("dir not found '%s'", dir);
		return;
	}

	fn hit(file: string) {
		if (isDir(file)) {
			return;
		}
		fullpath := dir ~ dirSeparator ~ file;
		str := cast(string)read(fullpath);
		d.addDocTemplate(str, fullpath);
	}

	searchDir(dir, "*.md", hit);
	searchDir(dir, "*.html", hit);
}
