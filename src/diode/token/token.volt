// Copyright © 2015, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/diode/license.volt (BOOST ver. 1.0).
module diode.token.token;


final class Token
{
	TokenKind kind;
	string value;
}

enum TokenKind
{
	None = 0,

	// Special
	Begin,
	End,

	// Control Tokens.
	Text,
	OpenExp,
	CloseExp,
	OpenStatement,
	CloseStatement,

	// Symbols
	Dot,
	Pipe,

	// Keywords
	In,
	For,
	EndFor,
	If,
	EndIf,
	Else,
	ElseIf,
	ElseFor,
	Identifier,
}

TokenKind identifierKind(string ident)
{
	switch (ident) with (TokenKind) {
	case "in":      return In;
	case "for":     return For;
	case "endfor":  return EndFor;
	case "if":      return If;
	case "endif":   return EndIf;
	case "else":    return Else;
	case "elseif":  return ElseIf;
	case "elsefor": return ElseFor;
	default:        return Identifier;
	}
}
