unit StringUtils;

interface


function StringStartsWith(const s, prefix: string): boolean;

function StringEndsWith(const s, suffix: string): boolean;

procedure RemoveLastNChars(var s: string; n: integer);

function ReplaceAllSubstrings(const s, sourceSubstring, destSubstring: string): string;

function LastIndexOf(const substr, str: string): integer;

implementation

uses
  StrUtils;


function StringEndsWith(const s, suffix: string): boolean;
var
	i: integer;
begin
	if length(s) < length(suffix) then
		begin
			Result := false;
			Exit;
		end;
	for i := 1 to length(suffix) do
		if s[length(s) - length(suffix) + i] <> suffix[i] then
			begin
				Result := false;
				Exit;
			end;
	Result := true;
end;


function StringStartsWith(const s, prefix: string): boolean;
var
	i: integer;
begin
	if length(s) < length(prefix) then
		begin
			Result := false;
			Exit;
		end;
	for i := 1 to length(prefix) do
		if s[i] <> prefix[i] then
			begin
				Result := false;
				Exit;
			end;
	Result := true;
end;

procedure RemoveLastNChars(var s: string; n: integer);
begin
	delete(s, length(s) - n + 1, n);
end;


function ReplaceAllSubstrings(const s, sourceSubstring, destSubstring: string): string;
var
	substringIndex: integer;
begin
	Result := s;
	while (true) do
		begin
			substringIndex := Pos(sourceSubstring, Result);
			if substringIndex > 0 then
				begin
					delete(Result, substringIndex, length(sourceSubstring));
					insert(destSubstring, Result, substringIndex);
				end
			else
				break;
		end;
end;

function LastIndexOf(const substr, str: string): integer;
var
  index: integer;
begin
  Result := 0;
  index := 0;
  repeat
    index := PosEx(substr, str, index+1);
    if (index > 0) then
      Result := index;
  until index = 0;
end;

end.
