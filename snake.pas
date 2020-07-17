program snake;
uses crt;
const
	BoxSymb = '_';
	BoxWallSymb = '|';
	SnakeSymb = '0';
	AppleSymb = '@';
	GameOverMsg = 'GAME OVER';
	DelayDuration = 100;

type
	SnakeNodePtr = ^SnakeNode;
	Direction = (down, up, right, left, stop);
	SnakeNode = record
		CurX, CurY: integer;
		delta: Direction;
		next: SnakeNodePtr;
	end;

	AppleRec = record
		x,y: integer;
	end;

procedure TypeSymb(x, y: integer; symb: string; number: byte);
begin
	GoToXY(x, y);
	TextColor(number);
	write(symb);
	GoToXY(1, 1)
end;

procedure IncrementScore(var score: integer);
var
	out: string;
begin
	score := score + 1;
	Str(score, out);
	out := 'SCORE: ' + out;
	TypeSymb((Screenwidth div 2) - length(out), 1, out, 15);
end;

procedure CreateArena();
var
	i: integer;
begin
	for i := 1 to ScreenWidth do
	begin
		TypeSymb(i, 1, BoxSymb, 15);
		TypeSymb(i, ScreenHeight, BoxSymb, 15);
	end;
	for i := 1 to (ScreenHeight - 1) do
	begin
		TypeSymb(1, i, BoxWallSymb, 15);
		TypeSymb(ScreenWidth, i, BoxWallSymb, 15);
	end;
	i := -1;
	IncrementScore(i);
end;

procedure InitSnake(var head, tail: SnakeNodePtr);
begin
	new(head);
	head^.CurX := ScreenWidth div 2;
	head^.CurY := ScreenHeight div 2;
	tail := head;
	TypeSymb(head^.CurX, head^.CurY, SnakeSymb, 2);
end;

procedure HandleKeyPress(var head: SnakeNodePtr;var key: char);
begin
	key := ReadKey;

	case key of
		#0: HandleKeyPress(head, key);
		#80: 
		begin
			if head^.delta <> up then
				head^.delta := down;
		end;
		#72: 
		begin
			if head^.delta <> down then
				head^.delta := up;
		end;
		#77:
		begin
			if head^.delta <> left then
				head^.delta := right;
		end;
		#75:
		begin
			if head^.delta <> right then
				head^.delta := left;
		end;
		#27:
		begin
			clrscr;
			halt(0);
		end;
	end
end;

procedure ChangeCoordinates(var node: SnakeNodePtr; x, y: integer);
begin
	node^.CurX := node^.CurX + x;
	node^.CurY := node^.CurY + y;
end;

procedure MoveSnakeNode(var node, prev: SnakeNodePtr); forward;
procedure HandleSelfCollision(var head: SnakeNodePtr); forward;
procedure HandleWallCollision(var head: SnakeNodePtr); forward;
procedure HandleAppleCollision(var apple: AppleRec; var head, tail: SnakeNodePtr;var score: integer); forward;

procedure MoveHead(var head, tail: SnakeNodePtr; var apple: AppleRec; var score: integer);
begin
	TypeSymb(head^.CurX, head^.CurY, ' ', 2);
	if head^.next <> nil then
		MoveSnakeNode(head^.next, head);
	case head^.delta of
		down: ChangeCoordinates(head, 0, 1);
		up: ChangeCoordinates(head, 0, -1);
		right: ChangeCoordinates(head, 1, 0);
		left: ChangeCoordinates(head, -1, 0);
	end;
	HandleSelfCollision(head);
	HandleWallCollision(head);
	HandleAppleCollision(apple, head, tail, score);
	TypeSymb(head^.CurX, head^.CurY, SnakeSymb, 2);
end;

procedure AddSnakeNode(var tail: SnakeNodePtr);
begin
	new(tail^.next);
	tail := tail^.next;
end;

procedure MoveSnakeNode(var node, prev: SnakeNodePtr);
begin
	TypeSymb(node^.CurX, node^.CurY, ' ', 15);
	if node^.next <> nil then
		MoveSnakeNode(node^.next, node);
	node^.CurX := prev^.CurX;
	node^.CurY := prev^.CurY;
	TypeSymb(node^.CurX, node^.CurY, SnakeSymb, 2)
end;

procedure HandleSelfCollision(var head: SnakeNodePtr);
label TestAgain;
var
	body: ^SnakeNodePtr;
begin
	body := @(head^.next);
TestAgain:
	if body^ = nil then
		exit;
	if (body^^.CurX = head^.CurX) and (body^^.CurY = head^.CurY) then
	begin
		head^.delta := stop;
		TypeSymb(((ScreenWidth div 2) - length(GameOverMsg)), ScreenHeight div 2, GameOverMsg, 4);
		Delay(1000);
		clrscr;
		halt(0);
	end
	else begin
		body := @(body^^.next);
		GoTo TestAgain;
	end
end;

procedure HandleWallCollision(var head: SnakeNodePtr);
begin
	if head^.CurX = 1 then
		head^.CurX := ScreenWidth - 1
	else if head^.CurX = ScreenWidth then
		head^.CurX := 2;
	if head^.CurY = 1 then
		head^.CurY := ScreenHeight - 3
	else if head^.CurY = ScreenHeight - 1 then
		head^.CurY := 2;
end;

procedure CreateApple(var apple: AppleRec; head: SnakeNodePtr); forward;
procedure HandleAppleCollision(var apple: AppleRec;var head, tail: SnakeNodePtr;var score: integer);
begin
	if (head^.CurX = apple.x) and (head^.CurY = apple.y) then
	begin
		IncrementScore(score);
		apple.x := 0;
		apple.y := 0;
		AddSnakeNode(tail);
		CreateApple(apple, head)
	end
end;

function CoordinatesAreAvailable(apple: AppleRec; head: SnakeNodePtr): boolean;
label TestAgain;
var
	snake: ^SnakeNodePtr;
begin
	snake := @(head);
TestAgain:
	if snake^ = nil then
	begin
		CoordinatesAreAvailable := true;
		exit
	end;
	if (apple.x = snake^^.CurX) and (apple.y = snake^^.CurX) then
	begin
		CoordinatesAreAvailable := false;
		exit
	end
	else
		snake := @(snake^^.next);
	GoTo TestAgain
end;

procedure CreateApple(var apple: AppleRec; head: SnakeNodePtr);
label GenerateAgain;
begin
GenerateAgain:
	Randomize;
	apple.x := random(ScreenWidth - 3) + 2;
	apple.y := random(ScreenHeight - 3) + 2;
	if CoordinatesAreAvailable(apple, head) then
		TypeSymb(apple.x, apple.y, AppleSymb, 4)
	else
		GoTo GenerateAgain	
end;

var
	head, tail: SnakeNodePtr;
	apple: AppleRec;
	score: integer;
	key: char;
begin
	clrscr;
	CreateArena();
	InitSnake(head, tail);
	CreateApple(apple, head);
	score := 0;
	while true do
	begin
		if not KeyPressed then
		begin
			MoveHead(head, tail, apple, score);
			Delay(DelayDuration);
			continue;
		end;
		HandleKeyPress(head, key);
		if key = ' ' then
			CreateApple(apple, head);
	end;
	clrscr
end.
