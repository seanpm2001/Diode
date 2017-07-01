// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
//! Code handle vdoc filters.
module diode.vdoc.filter;

import watt.text.vdoc;

import diode.errors;
import diode.eval;
import diode.vdoc;
import diode.interfaces;
import diode.vdoc.full;
import diode.vdoc.brief;


fn handleDocCommentFilter(d: Driver, e: Engine, root: VdocRoot, v: Value, filter: string, type: string) Value
{
	isHtml: bool;
	isFull: bool;
	isBrief: bool;

	named := cast(Named)v;
	if (named is null) {
		e.handleError("filter argument must be vdoc named thing.");
		return null;
	}

	switch (filter) {
	case "vdoc_find_full", "vdoc_full": isFull = true; break;
	case "vdoc_find_brief", "vdoc_brief": isBrief = true; break;
	default:
		err := format("internal error filter '%s' not known", filter);
		e.handleError(err);
		return null;
	}

	switch (type) {
	case "html": isHtml = true; break;
	default:
		err := format("type '%s' not support for '%s'", type, filter);
		e.handleError(err);
		return null;
	}

	// No doccomment just return empty text.
	if (named.raw is null) {
		return new Text(null);
	}

	if (isFull) {
		return new DocCommentFull(d, root, named);
	} else if (isBrief) {
		return new DocCommentBrief(d, root, named);
	} else {
		e.handleError("internal error");
	}
}

//! Helper class for DocComments.
abstract class DocCommentValue : Value, DocSink
{
public:
	drv: Driver;
	root: VdocRoot;
	named: Named;


public:
	this(d: Driver, root: VdocRoot, named: Named)
	{
		this.drv = d;
		this.root = root;
		this.named = named;
	}

	final fn safeParse(sink: Sink) bool
	{
		if (named is null) {
			return false;
		}
		if (named.raw is null) {
			return false;
		}

		parse(named.raw, this, sink);

		return true;
	}

	override fn briefStart(sink: Sink) { }
	override fn briefEnd(sink: Sink) { }
	override fn p(sink: Sink, state: DocState, d: string) { }
	override fn link(sink: Sink, state: DocState, target: string, text: string) { }
	override fn content(sink: Sink, state: DocState, cnt: string) { }
	override fn paramStart(sink: Sink, direction: string, arg: string) { }
	override fn paramEnd(sink: Sink) { }
	override fn start(sink: Sink) { }
	override fn end(sink: Sink) { }
	override fn defgroup(sink: Sink, group: string, text: string) { }
	override fn ingroup(sink: Sink, group: string) { }
}
