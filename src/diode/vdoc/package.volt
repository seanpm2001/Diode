// Copyright © 2016-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
module diode.vdoc;

import io = watt.io;
import watt.text.vdoc;

import diode.errors;
import diode.eval;


/**
 * Type of doc object.
 */
enum Kind
{
	Invalid,
	Arg,
	Enum,
	EnumDecl,
	Alias,
	Class,
	Union,
	Import,
	Return,
	Struct,
	Module,
	Member,
	Function,
	Variable,
	Interface,
	Destructor,
	Constructor,
}

/// Access of a symbool.
enum Access
{
	Public,
	Protected,
	Private,
}

fn accessToString(access: Access) string
{
	final switch (access) with (Access) {
	case Public: return "public";
	case Protected: return "protected";
	case Private: return "private";
	}
}

/// Storage of a variable.
enum Storage
{
	Field,
	Global,
	Local,
}

/**
 * The object that templates accesses the rest of the documentation nodes from.
 */
class VdocRoot : Value
{
public:
	/// All loaded modules.
	modules: Value[];
	/// Current thing that a vdoc template is rendering.
	current: Value;


public:
	override fn ident(n: ir.Node, key: string) Value
	{
		c := Collection.make(modules, key);
		if (c !is null) {
			return c;
		}

		switch (key) {
		case "current": return current is null ? new Nil() : current;
		default: return super.ident(n, key);
		}
	}

	fn getModules() Parent[]
	{
		num := 0u;
		ret := new Parent[](modules.length);
		foreach (v; modules) {
			p := cast(Parent)v;
			if (p is null || p.kind != Kind.Module) {
				continue;
			}

			ret[num++] = p;
		}

		if (num > 0) {
			return ret[0 .. num];
		} else {
			return null;
		}
	}
}

/**
 * Base class for all doc objects.
 */
class Base : Value
{
	kind: Kind;
}

/**
 * Base class for all doc objects that can have names.
 */
class Named : Base
{
public:
	/// Name of this object.
	name: string;
	/// Access of this named object.
	access: Access;
	/// Raw doccomment string.
	raw: string;
	/// Where to find the per thing documentation page, if any.
	url: string;


public:
	override fn ident(n: ir.Node, key: string) Value
	{
		switch (key) {
		case "name": return new Text(name);
		case "url": return makeNilOrText(url);
		case "doc": return makeNilOrText(rawToFull(raw));
		case "brief": return makeNilOrText(rawToBrief(raw));
		case "access": return new Text(accessToString(access));
		default: throw makeNoField(n, key);
		}
	}
}

/**
 * Regular imports and bound imports.
 */
class Import : Named
{
public:
	/// Is this import bound to a name.
	bind: string;


public:
	override fn ident(n: ir.Node,  key: string) Value
	{
		switch (key) {
		case "bind": return makeNilOrText(bind);
		default: return super.ident(n, key);
		}
	}
}

/**
 * A single freestanding enum or value part of a enum.
 */
class EnumDecl : Named
{
public:
	/// Is this a enum 
	isStandalone: bool;


public:
	override fn ident(n: ir.Node, key: string) Value
	{
		switch (key) {
		case "isStandalone": return new Bool(isStandalone);
		default: return super.ident(n, key);
		}
	}
}

/**
 * Base class for things with children, like Module, Class, Structs.
 */
class Parent : Named
{
public:
	/// The children of this Named thing.
	children: Value[];


public:
	override fn ident(n: ir.Node, key: string) Value
	{
		c := Collection.make(children, key);
		if (c !is null) {
			return c;
		}

		return super.ident(n, key);
	}
}

/**
 * Argument to a function.
 */
class Arg : Base
{
public:
	name: string;
	type: string;
	typeFull: string;


public:
	override fn ident(n: ir.Node,  key: string) Value
	{
		switch (key) {
		case "name": return new Text(name);
		case "type": return new Text(type);
		case "typeFull": return new Text(typeFull);
		default: throw makeNoField(n, key);
		}
	}
}

/**
 * Return from a function.
 */
class Return : Base
{
public:
	type: string;
	typeFull: string;


public:
	override fn ident(n: ir.Node,  key: string) Value
	{
		switch (key) {
		case "type": return new Text(type);
		case "typeFull": return new Text(typeFull);
		default: throw makeNoField(n, key);
		}
	}
}

/**
 * A variable or field on a aggregate.
 */
class Variable : Named
{
public:
	type: string;
	typeFull: string;
	storage: Storage;


public:
	override fn ident(n: ir.Node,  key: string) Value
	{
		switch (key) {
		case "type": return makeNilOrText(type);
		case "typeFull": return makeNilOrText(typeFull);
		default: return super.ident(n, key);
		}
	}
}

/**
 * A function or constructor, destructor or method on a aggreegate.
 */
class Function : Named
{
public:
	args: Value[];
	rets: Value[];
	linkage: string;
	hasBody: bool;
	forceLabel: bool;

	isFinal: bool;
	isScope: bool;
	isAbstract: bool;
	isProperty: bool;
	isOverride: bool;


public:
	override fn ident(n: ir.Node,  key: string) Value
	{
		switch (key) {
		case "args": return makeNilOrArray(args);
		case "rets": return makeNilOrArray(rets);
		case "linkage": return makeNilOrText(linkage);
		case "hasBody": return new Bool(hasBody);
		case "isFinal": return new Bool(isFinal);
		case "isScope": return new Bool(isScope);
		case "isAbstract": return new Bool(isAbstract);
		case "isProperty": return new Bool(isProperty);
		case "isOverride": return new Bool(isOverride);
		default: return super.ident(n, key);
		}
	}
}

/**
 * A special array that you can access fields on to filter the members.
 */
class Collection : Array
{
public:
	this(vals: Value[])
	{
		super(vals);
	}

	static fn make(vals: Value[], key: string) Value
	{
		kind: Kind;
		switch (key) with (Kind) {
		case "all":
			if (vals.length > 0) {
				return new Collection(vals);
			} else {
				return new Nil();
			}
		case "enums": kind = Enum; break;
		case "classes": kind = Class; break;
		case "imports": kind = Import; break;
		case "unions": kind = Union; break;
		case "structs": kind = Struct; break;
		case "modules": kind = Module; break;
		case "enumdecls": kind = EnumDecl; break;
		case "functions": kind = Function; break;
		case "variables": kind = Variable; break;
		case "destructors": kind = Destructor; break;
		case "constructors": kind = Constructor; break;
		case "members", "methods": kind = Member; break;
		default: return null;
		}

		num: size_t;
		ret := new Value[](vals.length);
		foreach (v; vals) {
			b := cast(Base)v;
			if (b is null || b.kind != kind) {
				continue;
			}

			ret[num++] = v;
		}

		if (num > 0) {
			return new Collection(ret[0 .. num]);
		} else {
			return new Nil();
		}
	}

	override fn ident(n: ir.Node, key: string) Value
	{
		c := make(vals, key);
		if (c is null) {
			throw makeNoField(n, key);
		} else {
			return c;
		}
	}
}

/**
 * Create a text Value, nil if string is empty.
 */
fn makeNilOrText(text: string) Value
{
	if (text.length == 0) {
		return new Nil();
	} else {
		return new Text(text);
	}
}

/**
 * Create a array Value, nil if string is empty.
 */
fn makeNilOrArray(array: Value[]) Value
{
	if (array.length == 0) {
		return new Nil();
	} else {
		return new Array(array);
	}
}
