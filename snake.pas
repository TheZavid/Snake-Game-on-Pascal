program snake;
uses crt;
const
	{symbols that will be used in the game}
	BoxSymb = '_';
	BoxWallSymb = '|';
	SnakeSymb = '0';
	AppleSymb = '@';
	GameOverMsg = 'GAME OVER';
	DelayDuration = 100;

type
	{pointer to the snakenode record}
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
	{types given string in given coordinates in given color then goes to left upper corner}
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
	IncrementScore(i);		{sets the initial score to 0}
end;

procedure InitSnake(var head, tail: SnakeNodePtr);
begin
	new(head);
	head^.CurX := ScreenWidth div 2;
	head^.CurY := ScreenHeight div 2;
	head^.next := nil;		{we make the linked listed correctly empty}
	tail := head;			{when initialised head and tail are the same element}
	TypeSymb(head^.CurX, head^.CurY, SnakeSymb, 2);
end;

procedure HandleKeyPress(var head: SnakeNodePtr;var key: char);
begin
	key := ReadKey;

	case key of
		#0: HandleKeyPress(head, key); {if keycode is zero we call this procedure again to get the extended keycode}
		#80: {down arrow}
		begin
			if head^.delta <> up then
				head^.delta := down;
		end;
		#72: {up arrow} 
		begin
			if head^.delta <> down then
				head^.delta := up;
		end;
		#77: {right arrow}
		begin
			if head^.delta <> left then
				head^.delta := right;
		end;
		#75: {left arrow}
		begin
			if head^.delta <> right then
				head^.delta := left;
		end;
		#27: {escape key}
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

{initializes procedures to whech MoveHead passes on parameters}
procedure MoveSnakeNode(var node, prev: SnakeNodePtr); forward;
procedure HandleSelfCollision(var head: SnakeNodePtr); forward;
procedure HandleWallCollision(var head: SnakeNodePtr); forward;
procedure HandleAppleCollision(var apple: AppleRec; var head, tail: SnakeNodePtr;var score: integer); forward;

{controlls head movement and checks for collisions}
procedure MoveHead(var head, tail: SnakeNodePtr; var apple: AppleRec; var score: integer);
begin
	TypeSymb(head^.CurX, head^.CurY, ' ', 2);
	if head^.next <> nil then			{if snake has body that move it}
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

{adds elements to the end of linked list(snake)}
procedure AddSnakeNode(var tail: SnakeNodePtr);
begin
	new(tail^.next);
	tail := tail^.next;
end;

procedure MoveSnakeNode(var node, prev: SnakeNodePtr);
begin
	TypeSymb(node^.CurX, node^.CurY, ' ', 15);
	if node^.next <> nil then		{moves snake from the end}
		MoveSnakeNode(node^.next, node);
	node^.CurX := prev^.CurX;
	node^.CurY := prev^.CurY;
	TypeSymb(node^.CurX, node^.CurY, SnakeSymb, 2)
end;

procedure HandleSelfCollision(var head: SnakeNodePtr);
label TestAgain;
var
	body: ^SnakeNodePtr; {pointer that we use to get coordinates of each body piece of snake}
begin
	body := @(head^.next); {get the second element in the linked list}
TestAgain:
	if body^ = nil then	{if we reach the end of linked list(snake) then we exit the procedure}
		exit;
		if (body^^.CurX = head^.CurX) and (body^^.CurY = head^.CurY) then	{if head collides its body that we stop the snake, show gameover message for 1000ms then exit program}
	begin
		head^.delta := stop;
		TypeSymb(((ScreenWidth div 2) - length(GameOverMsg)), ScreenHeight div 2, GameOverMsg, 4);
		Delay(1000);
		clrscr;
		halt(0);
	end
	else
		body := @(body^^.next); {if we didnt satisfy any of the exit conditions than check them for the next element}
	GoTo TestAgain;
end;

procedure HandleWallCollision(var head: SnakeNodePtr);
begin
	if head^.CurX = 1 then
		head^.CurX := ScreenWidth - 1
	else if head^.CurX = ScreenWidth then
		head^.CurX := 2;
	if head^.CurY = 1 then
		head^.CurY := ScreenHeight - 2 {for some reson if we set exit coordinate to ScreenHeight - 1 snake destroys bottom border}
	else if head^.CurY = ScreenHeight - 1 then
		head^.CurY := 2;
end;

procedure CreateApple(var apple: AppleRec; head: SnakeNodePtr); forward;
procedure HandleAppleCollision(var apple: AppleRec;var head, tail: SnakeNodePtr;var score: integer);
begin
	if (head^.CurX = apple.x) and (head^.CurY = apple.y) then
	begin
		IncrementScore(score); {one apple = +1 score}
		apple.x := 0; {reset apples coordinates}
		apple.y := 0;
		AddSnakeNode(tail); {add new body piece to snake}
		CreateApple(apple, head) {create new apple}
	end
end;
{similar to HandleWallCollision procedure}
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
	apple.x := random(ScreenWidth - 3) + 2; {create random number in range of 2..ScreenWidth - 1}
	apple.y := random(ScreenHeight - 3) + 2; {create random number in range of 2..ScreenHeight - 1}
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
	while true do {pseudo endless cycle which represents our game}
	begin
		if not KeyPressed then	{if player doesnt press any keys then we move snake in selected direction every amount of time specified by DelayDuration costant defined in the begining of the program}
		begin
			MoveHead(head, tail, apple, score);
			Delay(DelayDuration);
			continue;
		end;
		HandleKeyPress(head, key);
	end;
	clrscr
end.
