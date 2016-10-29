// Copyright © 2015-2016, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
/**
 * Holds the main function and some small test code.
 */
module main;

import diode.licence;
import diode.interfaces;


fn main(args : string[]) i32
{
	test();
	return 0;
}


/*
 *
 * A bunch of test code.
 *
 */

import watt.io;
import watt.text.sink;
import diode.eval;
import diode.driver;
import diode.parser : parse;
import diode.interfaces;


fn test()
{
	s := new Settings();
	s.workDir = "example";
	s.fillInDefaults();

	d := new DiodeDriver(s);
	d.addLayout(noneFile, "none.html");
	d.addLayout(defaultHtmlFile, "default.html");
	d.addLayout(pageHtmlFile, "page.html");
	d.addDoc(testDocJsonFile, "exp.json");

	d.renderFile(testMdFile, "test.md");
}

enum string testMdFile = r"---
layout: page
title: Test
---
### Header

Some text here

{% for mod in doc.modules %}
```
module {{ mod.name }}

{%


for e in mod.enums
%}{% if forloop.first %}
{% endif %}enum {{ e.name }}
{

}
{% unless forloop.last %}
{% endif %}{% endfor %}{%


for u in mod.unions
%}{% if forloop.first %}
{% endif %}union {{ u.name }}
{

}
{% unless forloop.last %}
{% endif %}{% endfor %}{%


for s in mod.structs
%}{% if forloop.first %}
{% endif %}struct {{ s.name }}
{

}
{% unless forloop.last %}
{% endif %}{% endfor %}{%


for c in mod.classes
%}{% if forloop.first %}
{% endif %}class {{ c.name }}
{

}
{% unless forloop.last %}
{% endif %}{% endfor %}{%


for v in mod.variables
%}{% if forloop.first %}
{% endif %}{{ v.name }}: {{ v.type }};
{% endfor %}{%


for f in mod.constructors
%}{% if forloop.first %}
{% endif %}fn {{ f.name }}();
{% endfor %}{%


if mod.destructors
%}
~this();
{% endif %}{%


for f in mod.functions
%}{% if forloop.first %}
{% endif %}fn {{ f.name }}({%
for arg in f.args %}{{ arg.type
}}{% unless forloop.last %}, {% endif %}{% endfor %}) {%
for r in f.rets %}{{ r.type }}{% endfor %};
{% endfor %}```



{% endfor %}
";

enum string noneFile = "{{ content }}";

enum string pageHtmlFile = `---
layout: default
---
<article>
{{ content }}
</article>
`;

enum string defaultHtmlFile = `<!DOCTYPE html>
<html lang="en">
  <head>
    <link rel="stylesheet" href="style.css" type="text/css">
  </head>
  <body>
{{ content }}
  </body>
</html>`;

enum string testDocJsonFile = `[
{"kind":"module","name":"main","doc":"\nHolds the main function and some small test code.\n","children":[
	{"kind":"fn","name":"main","args":[{"name":"args","type":"string[]","typeFull":"immutable(char)[][]"}],"rets":[{"type":"int"}]},
	{"kind":"fn","name":"test","rets":[{"type":"void"}]}
]},
{"kind":"module","name":"diode.interfaces","children":[
	{"kind":"class","name":"Driver","doc":"\nMain class driving everything.\n","children":[
		{"kind":"var","name":"settings","type":"Settings","typeFull":"diode.interfaces.Settings"},
		{"kind":"ctor","args":[{"name":"settings","type":"Settings","typeFull":"diode.interfaces.Settings"}]},
		{"kind":"member","name":"addLayout","args":[{"name":"source","type":"string","typeFull":"immutable(char)[]"},{"name":"filename","type":"string","typeFull":"immutable(char)[]"}],"rets":[{"type":"void"}]},
		{"kind":"member","name":"renderFile","args":[{"name":"source","type":"string","typeFull":"immutable(char)[]"},{"name":"filename","type":"string","typeFull":"immutable(char)[]"}],"rets":[{"type":"void"}]}
	]},
	{"kind":"class","name":"Settings","doc":"\nHolds settings for Diode.\n","children":[
		{"kind":"var","name":"workDir","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"var","name":"outputDir","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"var","name":"layoutDir","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"var","name":"includeDir","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"var","name":"titleDefault","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"var","name":"layoutDefault","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"var","name":"url","type":"string","typeFull":"immutable(char)[]"},
		{"kind":"member","name":"fillInDefaults","rets":[{"type":"void"}]},
		{"kind":"member","name":"processPath","args":[{"name":"val","type":"string","typeFull":"immutable(char)[]"},{"name":"def","type":"string","typeFull":"immutable(char)[]"}],"rets":[{"type":"void"}]},
		{"kind":"ctor"}
	]}
]}]`;
