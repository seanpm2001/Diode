// Copyright © 2015, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
module diode.parser.header;

import watt.text.ascii;
import watt.text.string;
import watt.text.source;

import diode.errors;


class Header
{
public:
	map : string[string];
}

fn parse(src : Source) Header
{
	if (!src.isTrippleDash()) {
		return null;
	}
	// Skip the dashes and the rest of the line.
	src.skipEndOfLine();

	header := new Header();

	//writefln("DFD %s", src.mSrc.mLastIndex);

	while (!src.eof && !src.isTrippleDash()) {
		// If it is a empty line, just skip it.
		if (src.skipWhiteAndCheckIfEmptyLine()) {
			continue;
		}

		// We now know that this is not a tripple dash line
		// and the character that src is point on is not a
		// whitespace character.
		key := src.getIdent();
		src.skipWhiteTillAfterColon();
		val := src.getRestOfLine().strip();

		// Update the key in the header.
		header.map[key] = val;
	}

	// Skip the dashes and the rest of the line.
	src.skipEndOfLine();

	return header;
}

/**
 * Does not advance the source, just check if the next 3 chars are dashes.
 */
fn isTrippleDash(src : Source) bool
{
	eof : bool;

	return src.lookahead(0, out eof) == '-' &&
	       src.lookahead(1, out eof) == '-' &&
	       src.lookahead(2, out eof) == '-';
}

/**
 * Does what it says on the tin, yes I felt bad naming this function.
 */
fn skipWhiteAndCheckIfEmptyLine(src : Source) bool
{
	d := src.front;
	while (d != '\n' && d.isWhite() && !src.eof) {
		src.popFront();
		d == src.front;
	}

	if (d == '\n') {
		src.popFront();
		return true;
	} else {
		return false;
	}
}

fn skipWhiteTillAfterColon(src : Source)
{
	d := src.front;
	while (d != ':' && !src.eof) {
		if (!src.front.isWhite()) {
			throw makeBadHeader(ref src.loc);
		}
		src.popFront();
		d = src.front;
	}
	if (d == ':') {
		src.popFront();
	}
}

fn getIdent(src : Source) string
{
	mark := src.save();
	if (!src.front.isAlpha()) {
		throw makeBadHeader(ref src.loc);
	}

	src.popFront();
	while (src.front.isAlpha() ||
	       src.front.isDigit() ||
	       src.front == '_') {
		src.popFront();
	}
	return src.sliceFrom(mark);
}

fn getRestOfLine(src : Source) string
{
	mark := src.save();
	d := src.front;
	while (d != '\n' && !src.eof) {
		src.popFront();
		d = src.front;
	}
	ret := src.sliceFrom(mark);
	if (d == '\n') {
		src.popFront();
	}
	return ret;
}
