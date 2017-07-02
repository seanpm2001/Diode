// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
//! Code to process vdoc objects raw doccomments.
module diode.vdoc.processor;

import watt.text.sink : Sink, StringSink;
import watt.text.string : strip, indexOf;
import watt.text.format : format;
import watt.text.vdoc;

import diode.vdoc;


/*!
 * Processes the given VdocRoot.
 *
 * Setting various fields and adding objects to groups.
 */
fn process(vdocRoot: VdocRoot)
{
	p := new Processor(vdocRoot);

	foreach (group; vdocRoot.groups) {
		p.processNamed(group);
	}

	foreach (mod; vdocRoot.modules) {
		p.processParent(mod);
	}
}

//! Main class for processing vdoc objects.
class Processor : DocCommentParser
{
public:
	groups: Parent[string];


public:
	this(root: VdocRoot)
	{
		super(root);

		foreach (group; root.groups) {
			groups[group.search] = group;
		}
	}
}

//! Results from a doccomment parsing.
struct DocCommentResult
{
	//! The main content for this doccomment.
	content: string;

	//! Brief doccomment.
	brief: string;

	//! The groups this comment is in.
	ingroups: string[];

	//! Return documentation.
	ret: string;

	//! Params for functions.
	params: DocCommentParam[];

	//! The doccomment content form the return command.
	returnContent: string;
}

//! A single parameter result.
class DocCommentParam
{
	arg: string;
	dir: string;
	doc: string;
}

//! Helper class for DocComments.
class DocCommentParser : DocSink
{
public:
	root: VdocRoot;

	brief: StringSink;
	autoBrief: StringSink;
	full: StringSink;

	//! Current param.
	param: DocCommentParam;
	//! String sink for params.
	temp: StringSink;

	results: DocCommentResult;

	isAuto: bool;
	hasBrief: bool;


public:
	this(root: VdocRoot)
	{
		this.root = root;
	}

	final fn parseRaw(raw: string)
	{
		results = DocCommentResult.init;
		hasBrief = false;
		isAuto = false;

		parse(raw, this, null);

		// Set the full string.
		results.content = full.toString();
		full.reset();

		// Handle auto brief if @brief command was not used.
		if (!hasBrief) {
			results.brief = strip(autoBrief.toString());
			autoBrief.reset();
		}
	}

	override fn ingroup(sink: Sink, group: string)
	{
		results.ingroups ~= group;
	}

	override fn paramStart(sink: Sink, direction: string, arg: string)
	{
		param = new DocCommentParam();
		param.arg = arg;
		param.dir = direction;
	}

	override fn paramEnd(sink: Sink)
	{
		// Just in case.
		if (param is null) {
			return;
		}

		results.params ~= param;

		param.doc = temp.toString();
		param = null;

		temp.reset();
	}

	override fn returnStart(sink: Sink)
	{

	}

	override fn returnEnd(sink: Sink)
	{
		results.ret = temp.toString();
		temp.reset();
	}

	override fn start(sink: Sink)
	{
		isAuto = !hasBrief;
	}

	override fn end(sink: Sink)
	{
		// Stop auto generating brief.
		isAuto = false;
	}

	override fn briefStart(sink: Sink)
	{
		// Stop auto generating brief.
		isAuto = false;

		hasBrief = true;
	}

	override fn briefEnd(sink: Sink)
	{
		// Set the brief string.
		results.brief = brief.toString();
		brief.reset();
	}

	override fn p(sink: Sink, state: DocState, d: string)
	{
		final switch (state) with (DocState) {
		case Brief: sink(d); break;
		case Content:
			if (isAuto) {
				autoBrief.sink(d);
			}
			full.sink("`");
			full.sink(d);
			full.sink("`");
			break;
		case Param, Return:
			temp.sink("`");
			temp.sink(d);
			temp.sink("`");
			break;
		}
	}

	override fn link(sink: Sink, state: DocState, target: string, text: string)
	{
		text = strip(text);
		url: string;
		name: string;
		md: string;

		if (n := root.findNamed(target)) {

			// If we have no text use the name from the object.
			if (text is null) {
				text = n.name;
			}

			// Does this named thing has a URL?
			if (n.url !is null) {
				md = format(`[%s](%s)`, text, n.url);
			} else {
				md = text;
			}

		} else if (text is null) {
			text = target;
			md = target;
		}

		final switch (state) with (DocState) {
		case Brief: brief.sink(text); break;
		case Content:
			if (isAuto) {
				autoBrief.sink(text);
			}
			full.sink(md);
			break;
		case Param, Return:
			temp.sink(md);
			break;
		}
	}

	override fn content(sink: Sink, state: DocState, d: string)
	{
		final switch (state) with (DocState) {
		case Param, Return: temp.sink(d); return;
		case Brief: brief.sink(d); return;
		case Content: break;
		}

		// Content path, for full comment send as is.
		full.sink(d);

		// Handle auto brief.
		if (!isAuto || d.length <= 0 || state != DocState.Content) {
			return;
		}

		index := d.indexOf(".");
		if (index < 0) {
			return autoBrief.sink(d);
		}

		autoBrief.sink(d[0 .. index + 1]);
		isAuto = false;
	}

	override fn defgroup(sink: Sink, group: string, text: string) { }
}

private fn processParent(p: Processor, n: Parent)
{
	p.processNamed(n);

	foreach (child; n.children) {
		if (c := cast(Parent)child) {
			p.processParent(c);
		} else if (c := cast(Function)child) {
			p.processFunction(c);
		} else if (c := cast(Named)child) {
			p.processNamed(c);
		}
	}
}

private fn processFunction(p: Processor, n: Function)
{
	if (!p.processNamed(n)) {
		return;
	}

	foreach (param; p.results.params) {
		arg: Arg;

		foreach (v; n.args) {
			arg = cast(Arg)v;

			if (param.arg == arg.name) {
				arg.content = param.doc;
				break;
			} else {
				arg = null;
			}
		}
	}

	if (n.rets !is null) {
		ret := cast(Return)n.rets[0];
		if (ret !is null) {
			ret.content = p.results.ret;
		}
	}
}

private fn processNamed(p: Processor, n: Named) bool
{
	if (n.raw is null) {
		return false;
	}

	p.parseRaw(n.raw);

	n.content = p.results.content;
	n.brief = p.results.brief;

	foreach (ident; p.results.ingroups) {
		group := p.groups.get(ident, null);
		if (group is null) {
			group = p.root.addGroup(ident, null, null);
			p.groups[ident] = group;
		}
		group.children ~= n;
		n.ingroup ~= group;
	}

	return true;
}