{-----------------------------------------------}
program Cradle;

{-----------------------------------------------}
{Constant Declaration}

const TAB = ^I;
const CR = ^M;
const LF = #10;
{-----------------------------------------------}
{Variable Declarations}

var Look: char;         {Lookahead Character}
    LCount: integer;   {Label Counter}
{--------------------------------------------------------}
{Generate a Unique Label}
function NewLabel: string;

var S: string;
begin
     Str(LCount, S);
     NewLabel := 'L' + S;
     Inc(LCount);
end;

{-------------------------------------------------------}
{Post a Label to Output}
procedure PostLabel(L: string);
begin
     WriteLn(L, ':');
end;
{-----------------------------------------------}
{Read New Character from Input Stream}

procedure GetChar;
begin
     Read(Look);
end;

{-----------------------------------------------}
{Report an Error}
procedure Error(s: string);
begin
     Writeln;
     Writeln(^G, 'Error: ', s, '.');
end;
{-----------------------------------------------}
{Report Error and Halt!}

procedure Abort(s: string);
begin
     Error(s);
     Halt;
end;

{-----------------------------------------------}
{Report What Was Expected}

procedure Expected(s: string);
begin
     Abort(s + 'Expected');
end;

{-----------------------------------------------}
{Match a specific input Character}
procedure Match(x : char);
begin
     if Look = x then GetChar
     else Expected(''''+ x + '''');
end;
{-----------------------------------------------}
{Recognize an Alpha Character}

function IsAlpha(c: char): boolean;
begin
     IsAlpha := upcase(c) in ['A'..'Z'];
end;

{Recognize an Addop}
function isAddop(c: char): boolean;
begin
     isAddop := c in ['+','-'];
end;
{-----------------------------------------------}
{Recognize a Boolean Orop}
function IsOrop(c: char): Boolean;
begin
     IsOrop := c in ['|', '~'];
end;

{-----------------------------------------------}
{Recognize a Decimal Digit}

function IsDigit(c: char): boolean;
begin
     IsDigit := c in ['0'..'9']
end;
{Recognize a Relop}

function IsRelop(c: char): boolean;
begin
     IsRelop := c in ['=', '#', '<', '>'];
end;
{-----------------------------------------------}

procedure Fin;
begin
     if Look = CR then GetChar;
     if Look = LF then GetChar;
end;

{Skip a CRLF}
{-----------------------------------------------}
{Get an Identifier}

function GetName: char;
begin
     if not IsAlpha(Look) then Expected('Name');
     GetName := UpCase(Look);
     GetChar;
end;

{-----------------------------------------------}
{Get a Number}

function GetNum: char;
begin
     if not IsDigit(Look) then Expected('Integer');
     GetNum := Look;
     GetChar;
end;

{-------------------------------------------------------}
{Output a String with Tab}

procedure Emit(s: string);
begin
     Write(TAB, s);
end;
{-------------------------------------------------------}
{Recognize a Boolean Literal}

function IsBoolean(c: char): Boolean;
begin
     IsBoolean := UpCase(c) in ['T' , 'F'];
end;
{-------------------------------------------------------}
{Get a Boolean Literal}

function GetBoolean: Boolean;
var c: char;
begin
     if not IsBoolean(Look) then Expected('Boolean Literal');
     GetBoolean := UpCase(Look) = 'T';
     GetChar;
end;

{--
{-------------------------------------------------------}
{Output a string with Tab and CRLF}

procedure EmitLn(s: string);
begin
     Emit(s);
     WriteLn;
end;

{-------------------------------------------------------}
{Recognize and Translate an Identifier}

procedure Ident;
var Name: char;
begin
     Name:= GetName;
     if Look = '(' then begin
     Match('(');
     Match(')');
     EmitLn('BSR ' + Name);
     end
   else
   EmitLn('MOVE ' + Name + '(PC), D0');
end;

{---------------------------------------------------------}
{Parse and Translate a Math Factor}

procedure Expression; Forward;

procedure Factor;
begin
     if Look = '(' then begin
     Match ('(');
     Expression;
     Match(')');
     end
   else if IsAlpha(Look) then
        Ident
   else
   EmitLn('MOVE #' + GetNum + ',D0');
end;

{---------------------------------------------------------}
{Parse and Translate the First Math Factor}

procedure SignedFactor;
begin
     if Look = '+' then
     GetChar;
     if Look = '-' then begin
     GetChar;
     if IsDigit(Look) then
     EmitLn('MOVE #-' + GetNum + ',D0')
     else begin
     Factor;
     EmitLn('NEG D0');
     end;
     end
     else Factor;
end;
{--------------------------------------------------------}
{Parse and Translate a Mulitply}

procedure Multiply;
begin
     Match('*');
     Factor;
     EmitLn('MULS (SP)+, D0');
end;
{--------------------------------------------------------}
{Parse and Translate a Divide}

procedure Divide;
begin
     Match('/');
     Factor;
     EmitLn('MOVE (SP)+, D0');
     EmitLn('EXS.L D0');
     EmitLn('DIVS D1, D0');
end;
{--------------------------------------------------------}
{Parse and Translate a Math Term}

procedure Term;
begin
     SignedFactor;
     while Look in ['*', '/'] do begin
     EmitLn('MOVE D0, -(SP)');
     case Look of
     '*' : Multiply;
     '/' : Divide;
     end;
  end;
end;
{----------------------------------------------------------}
{Recognize and Translate an Add}

procedure Add;
begin
     Match('+');
     Term;
     EmitLn('ADD (SP)+, D0');
end;
{----------------------------------------------------------}
{Recognize and Translate a Subtract}

procedure Subtract;
begin
     Match('-');
     Term;
     EmitLn('SUB (SP)+, D0');
     EmitLn('NEG D0');
end;
{----------------------------------------------------------}
{Parse and Translate an Expression}

procedure Expression;
begin
     Term;
     While isAddop(Look) do begin
     EmitLn('MOVE D0, -(SP)');
     case Look of
     '+' : Add;
     '-' : Subtract;
     end;
end;
end;
{----------------------------------------------------------}
{Recognize and Translate a Relational "Equals"}

procedure Equals;
begin
     Match('=');
     Expression;
     EmitLn('CMP (SP)+, D0');
     EmitLn('SEQ D0');
end;
{-------------------------------------------------------}
{Recognize and Translate a Relational "Not Equals"}

procedure NotEquals;
begin
     Match('#');
     Expression;
     EmitLn('CMP (SP)+, D0');
     EmitLn('SEQ D0');
end;
{--------------------------------------------------------}
{Recognize and Translate a Relational "Less Than"}

procedure Less;
begin
     Match('<');
     Expression;
     EmitLn('CMP (SP)+, D0');
     EmitLn('SLE D0');
end;
{--------------------------------------------------------}
{Recognize and Translate a Relational "Greater Than"}

procedure Greater;
begin
     Match('>');
     Expression;
     EmitLn('CMP (SP)+, D0');
     EmitLn('SLE D0');
end;

{--------------------------------------------------------}
{Parse and Translate a Relation}

procedure Relation;
begin
     Expression;
     if isRelop(Look) then begin
     EmitLn('MOVE D0, -(SP)');
     case look of
     '=': Equals;
     '#': NotEquals;
     '<': Less;
     '>': Greater;
     end;
     EmitLn('TST D0');
     end;
end;

{-------------------------------------------------------}
{Parse and Translate a Bool Factor}
procedure BoolFactor;
begin
     if IsBoolean(Look) then
     if GetBoolean then
     EmitLn('MOVE #-1, D0')
     else
     EmitLn('CLR D0')
     else
     Relation;
end;
{-------------------------------------------------------}
{Parse and Translate a Boolean Facor with NOT}

procedure NotFactor;
begin
     if Look = '!' then begin
     Match('!');
     BoolFactor;
     EmitLn('EOR #-1,D0');
     end
     else
     BoolFactor;
end;
{-------------------------------------------------------}
{Parse and Translate a Boolean Term}

procedure BoolTerm;
begin
     NotFactor;
     while Look = '&' do begin
     EmitLn('MOVE D0,-(SP)');
     Match('&');
     NotFactor;
     EmitLn('AND (SP)+,D0');
   end;
end;

{-------------------------------------------------------}
{Recognize and Translate a Boolean Or}

procedure BoolOr;
begin
     Match('|');
     BoolTerm;
     EmitLn('OR (SP)+, D0');
end;
{--------------------------------------------------------}
{Recognize and Translate an Exclusive Or}

procedure BoolXor;
begin
     Match('~');
     BoolTerm;
     EmitLn('EOR (SP)+, D0');
end;

{-------------------------------------------------------}
{Parse and Translate a Boolean Expression}

procedure BoolExpression;
begin
     BoolTerm;
     while IsOrOp(Look) do begin
        EmitLn('MOVE D0, -(SP)');
     case Look of
     '|': BoolOr;
     '~': BoolXor;
     end;
  end;
end;
{-------------------------------------------------------}
{Recognize and Translate an If Construct}
procedure Block(L: string); Forward;

procedure DoIf(L: string);
var L1, L2: string;
begin
     Match('i');
     BoolExpression;
     L1 := NewLabel;
     L2 := L1;
     EmitLn('BEQ ' +  L1);
     Block(L);
     if Look = 'l' then begin
     Match('l');
     L2 := NewLabel;
     EmitLn('BRA '+ L2);
     PostLabel(L1);
     Block(L);
     end;
     Match('e');
     PostLabel(L2);
end;
{-------------------------------------------------------}
{Parse and Translate a While Statement}
procedure DoWhile;
var L1, L2: string;
begin
     Match('w');
     L1 := NewLabel;
     L2 := NewLabel;
     PostLabel(L1);
     BoolExpression;
     EmitLn('BEQ ' + L2);
     Block(L2);
     Match('e');
     EmitLn('BRA ' + L1);
     PostLabel(L2);
end;
{-------------------------------------------------------}
{Parse and Translate a Loop Statement}
procedure DoLoop;
var L1, L2: string;
begin
     Match('p');
     L1 := NewLabel;
     L2 := NewLabel;
     PostLabel(L1);
     Block(L2);
     Match('e');
     EmitLn('BRA ' + L2);
     PostLabel(L2);
end;
{-------------------------------------------------------}
{Parse and Translate a REPEAT Statement}

procedure DoRepeat;
var L1, L2: string;
begin
     Match('r');
     L1 := NewLabel;
     L2 := NewLabel;
     PostLabel(L1);
     Block(L2);
     Match('u');
     BoolExpression;
     EmitLn('BEQ ' + L1);
     PostLabel(L2);
end;
{-------------------------------------------------------}
{Parse and Translate a FOR Statement}
procedure DoFor;
var L1, L2: string;
    Name: char;
begin
     Match('f');
     L1 := NewLabel;
     L2 := NewLabel;
     Name := GetName;
     Match('=');
     Expression;
     EmitLn('SUBQ #1, D0');
     EmitLn('LEA ' + Name + '(PC),A0');
     EmitLn('MOVE D0, (A0)');
     Expression;
     EmitLn('MOVE D0,-(SP)');
     PostLabel (L1);
     EmitLn('LEA ' + Name + '(PC),A0');
     EmitLn('MOVE (A0), D0');
     EmitLn('ADDQ #1, D0');
     EmitLn('MOVE D0,(A0)');
     EmitLn('CMP (SP),D0');
     EmitLn('BGT ' + L2);
     Block(L2);
     Match('e');
     EmitLn('BRA ' + L1);
     PostLabel(L2);
     EmitLn('ADDQ #2, SP');
end;
{-------------------------------------------------------}
{Parse and Translate a DO Statement}

procedure DoDo; {<----- lol}
var L1, L2: string;
begin
     Match('d');
     L1 := NewLabel;
     L2 := NewLabel;
     Expression;
     EmitLn('SUBQ #1, D0');
     PostLabel(L1);
     EmitLn('MOVE D0,-(SP)');
     Block(L2);
     EmitLn('MOVE (SP)+,D0');
     EmitLn('DBRA D0, ' + L1);
     EmitLn('SUBQ #2, SP');
     PostLabel(L2);
     EmitLn('ADDQ #2, SP');
end;
{-------------------------------------------------------}
{Renognize and Translate a BREAK}

procedure DoBreak(L: string);
begin
     Match('b');
     EmitLn('BRA ' + L);
end;

{-------------------------------------------------------}
{Recognize and Translate an "Other"}
procedure Other;
begin
     EmitLn(GetName);
end;

{--------------------------------------------------------}
{Parse and Translate an Assignment Statement}

procedure Assignment;
var name: char;
begin
     Name := GetName;
     Match('=');
     BoolExpression;
     EmitLn('LEA ' + Name + '(PC), A0');
     EmitLn('MOVE D0, (A0)');
end;
{--------------------------------------------------------}
{Recognize and Translate a Statement Block}
procedure Block(L: string);
begin
     while not (Look in ['e', 'l', 'u']) do begin
           Fin;
           case Look of
           'i': DoIf(L);
           'w': DoWhile;
           'p': DoLoop;
           'r': DoRepeat;
           'f': DoFor;
           'd': DoDo; {lol}
           'b': DoBreak(L);
           else Assignment;
           Fin;
       end;
    end;
end;

{-------------------------------------------------------}
{Parse and Translate a Program}
procedure DoProgram;
begin
     Block('');
     if Look <> 'e' then Expected('End');
     EmitLn('END')
end;

{-------------------------------------------------------}
{ Initialize }

procedure Init;
begin

     GetChar;
     LCount := 0;

end;
{-------------------------------------------------------}
{Main Program}

begin

     Init;
     DoProgram;
end.


































