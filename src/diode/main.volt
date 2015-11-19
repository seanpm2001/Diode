// Copyright © 2015, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
module diode.main;

import diode.parser : parse;


int main(string[] args)
{
	auto f = parse(text, "test.md");
	test(f);
	test(buildTest());
	return 0;
}


/*
 *
 * A bunch of test code.
 *
 */

import diode.eval;
import watt.io;

void test(ir.File f)
{
	Set set = buildInbuilt();
	auto e = new Engine(set);

	void sink(const(char)[] str) {
		write(str);
	}

	f.accept(e, sink);
}

Set buildInbuilt()
{
	auto base = new Set();
	auto site = new Set();
	base.ctx["site"]  = site;
	site.ctx["base"]  = new Text("http://helloworld.com");
	auto p1 = new Set();
	p1.ctx["title"]   = new Text("The Title");
	p1.ctx["content"] = new Text("the content");
	auto p2 = new Set();
	p2.ctx["title"]   = new Text("Another Title");
	p2.ctx["content"] = new Text("the content");
	auto p3 = new Set();
	p3.ctx["title"]   = new Text("The last Title");
	p3.ctx["content"] = new Text("the content");
	site.ctx["posts"] = new Array(p1, p2, p3);
	return base;
}


enum string text = `---
layout: default
title: Test
---
### Header

Some text here

{% for post in site.posts %}
#### {{ post.title }}
{{ post.content }}

ender
{% endfor %}
`;

import ir = diode.ir;
import diode.ir.build : bFile, bText, bPrint, bFor, bAccess, bIdent,
                        bChain, bPrintChain;

ir.File buildTest()
{
	auto f = bFile();
	f.nodes ~= bText(part1);
	f.nodes ~= bFor("post", bChain("site", "posts"),
		[cast(ir.Node)bText(part2),
		bPrintChain("post", "title"),
		bText(part3),
		bPrintChain("post", "content"),
		bText(part4),
		]);
	f.nodes ~= bChain("site", "base");
	f.nodes ~= bText("foof");
	return f;
}

enum string part1 =
`### Header

Some text here

`;

enum string part2 =
`
#### `;

enum string part3 =
`
`;

enum string part4 =
`

ender
`;
