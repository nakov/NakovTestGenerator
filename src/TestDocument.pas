unit TestDocument;

interface

uses
	Classes, SysUtils, StringUtils;

const
	QUESTION_IDENTIFIER = 'Question.';
	MANDATORY_QUESTION_IDENTIFIER = 'Mandatory.Question.';
	END_OF_QUESTIONS_IDENTIFIER = 'Question.End';
	CORRECT_ANSWER_IDENTIFIER = 'Correct.';
	WRONG_ANSWER_IDENTIFIER = 'Wrong.';
  BLOCK_START_IDENTIFIER = '{';
	PARAGRAPH_END_IDENTIFIER = '\par ';
	CELL_END_IDENTIFIER = '\cell ';
	BOLD_FONT_IDENTIFIER = '\b\';

type
	TParserState = (parseHeader, parseQuestion, parseAnswer, parseAfterAnswer);

	TTestQuestion = class;

	TTestDocument = class
	private
		fQuestions: TList;
		fState: TParserState;
		fCurrentQuestion: TTestQuestion;
		fHeaderRtfText: string;
		fCurrentQuestionRtfText: string;
    fCurrentBeforeAnswerRtfText : string;
		fCurrentAnswerRtfText: string;
		fCurrentAfterAnswerRtfText: string;
		fFooterRtfText: string;
		fCurrentAnswerCorrect: boolean;
		procedure ProcessHeaderChar(ch: char);
		procedure ProcessQuestionTextChar(ch: char);
		procedure ProcessAnswerChar(ch: char);
		procedure ProcessAfterAnswerChar(ch: char);
		procedure ProcessNextChar(ch: char);
		procedure AppendCurrentAnswerToCurrentQuestion(
			const beforeAnswerRtfText, answerRtfText, afterAnswerRtfText: string; correct: boolean);
    procedure ProcessFooter;
	public
		constructor Create();
		destructor Destroy(); override;
		property Questions: TList read fQuestions;
		property HeaderRtfText: string
			read fHeaderRtfText write fHeaderRtfText;
		property FooterRtfText: string
			read fFooterRtfText write fFooterRtfText;
		procedure ReadFromRtfFile(const fileName: string);
	end;

	TTestQuestion = class
	private
		fQuestionRtfText: string;
		fAnswers: TList;
    fMandatory: boolean;
	public
		constructor Create();
		destructor Destroy(); override;
		property Mandatory: boolean read fMandatory write fMandatory;
		property QuestionRtfText: string read fQuestionRtfText write fQuestionRtfText;
		property Answers: TList	read fAnswers write fAnswers;
	end;

	TAnswer = class
	private
		fBeforeAnswerRtfText: string;
		fAnswerRtfText: string;
		fAfterAnswerRtfText: string;
		fCorrect: boolean;
	public
		property BeforeAnswerRtfText: string read fBeforeAnswerRtfText write fBeforeAnswerRtfText;
		property AnswerRtfText: string read fAnswerRtfText write fAnswerRtfText;
		property AfterAnswerRtfText: string read fAfterAnswerRtfText write fAfterAnswerRtfText;
		property Correct: boolean read fCorrect write fCorrect;
	end;

implementation

{ TTestDocument }

constructor TTestDocument.Create();
begin
	fQuestions := TList.Create();
end;

destructor TTestDocument.Destroy();
var
	i: integer;
begin
	for i := 0 to fQuestions.Count-1 do
		TTestQuestion(fQuestions[i]).Free();
	fQuestions.Free();
	inherited;
end;

procedure SplitByBeginBlock(var firstText: string; var secondText: string);
var
  lastBlockStart: integer;
begin
  secondText := '';
  lastBlockStart := LastIndexOf(BLOCK_START_IDENTIFIER, firstText);
  if lastBlockStart > 0 then
    begin
      secondText := copy(firstText, lastBlockStart, length(firstText));
      delete(firstText, lastBlockStart, length(firstText));
    end;
end;

procedure TTestDocument.ProcessHeaderChar(ch: char);
begin
	fHeaderRtfText := fHeaderRtfText + ch;
	if StringEndsWith(fHeaderRtfText, QUESTION_IDENTIFIER) then
		begin
      SplitByBeginBlock(fHeaderRtfText, fCurrentQuestionRtfText);
			fState := parseQuestion;
		end;
end;

procedure TTestDocument.ProcessQuestionTextChar(ch: char);

	procedure AnswerIdentificatorFound();
  var
    mandatoryIndex: integer;
	begin
		// Create a new question object and append it to the questions list
		fCurrentQuestion := TTestQuestion.Create();

    // Process special king of questions called "Mandatory"
    mandatoryIndex := Pos(MANDATORY_QUESTION_IDENTIFIER, fCurrentQuestionRtfText);
    if mandatoryIndex > 0 then
      begin
        fCurrentQuestion.Mandatory := true;
        Delete(fCurrentQuestionRtfText, mandatoryIndex, length(MANDATORY_QUESTION_IDENTIFIER));
      end;

    // Append the question to the list of parsed questions
    SplitByBeginBlock(fCurrentQuestionRtfText, fCurrentBeforeAnswerRtfText);
		fCurrentQuestion.QuestionRtfText := fCurrentQuestionRtfText;
		fQuestions.Add(fCurrentQuestion);
		fCurrentAnswerRtfText := '';
		fState := parseAnswer;
	end;

begin
	fCurrentQuestionRtfText := fCurrentQuestionRtfText + ch;
	if StringEndsWith(fCurrentQuestionRtfText, CORRECT_ANSWER_IDENTIFIER) then
		begin
			RemoveLastNChars(fCurrentQuestionRtfText, length(CORRECT_ANSWER_IDENTIFIER));
			fCurrentAnswerCorrect := true;
			AnswerIdentificatorFound();
		end;
	if StringEndsWith(fCurrentQuestionRtfText, WRONG_ANSWER_IDENTIFIER) then
		begin
			RemoveLastNChars(fCurrentQuestionRtfText, length(WRONG_ANSWER_IDENTIFIER));
			fCurrentAnswerCorrect := false;
			AnswerIdentificatorFound();
		end;
end;

procedure TTestDocument.ProcessAnswerChar(ch: char);
begin
	fCurrentAnswerRtfText := fCurrentAnswerRtfText + ch;
	if StringEndsWith(fCurrentAnswerRtfText, PARAGRAPH_END_IDENTIFIER) then
		begin
			fCurrentAfterAnswerRtfText := '';
			fState := parseAfterAnswer;
		end;
	if StringEndsWith(fCurrentAnswerRtfText, CELL_END_IDENTIFIER) then
		begin
      SplitByBeginBlock(fCurrentAnswerRtfText, fCurrentAfterAnswerRtfText);
			fState := parseAfterAnswer;
		end;
end;

procedure TTestDocument.ProcessAfterAnswerChar(ch: char);
var
  nextBeforeAnswerRtfText: string;
begin
	fCurrentAfterAnswerRtfText := fCurrentAfterAnswerRtfText + ch;
	if StringEndsWith(fCurrentAfterAnswerRtfText, CORRECT_ANSWER_IDENTIFIER) then
		begin
			RemoveLastNChars(fCurrentAfterAnswerRtfText, length(CORRECT_ANSWER_IDENTIFIER));
      SplitByBeginBlock(fCurrentAfterAnswerRtfText, nextBeforeAnswerRtfText);
			AppendCurrentAnswerToCurrentQuestion(fCurrentBeforeAnswerRtfText,
				fCurrentAnswerRtfText, fCurrentAfterAnswerRtfText, fCurrentAnswerCorrect);
      fCurrentBeforeAnswerRtfText := nextBeforeAnswerRtfText;
			fCurrentAnswerCorrect := true;
			fCurrentAnswerRtfText := '';
			fState := parseAnswer;
		end;
	if StringEndsWith(fCurrentAfterAnswerRtfText, WRONG_ANSWER_IDENTIFIER) then
		begin
			RemoveLastNChars(fCurrentAfterAnswerRtfText, length(WRONG_ANSWER_IDENTIFIER));
      SplitByBeginBlock(fCurrentAfterAnswerRtfText, nextBeforeAnswerRtfText);
			AppendCurrentAnswerToCurrentQuestion(fCurrentBeforeAnswerRtfText,
				fCurrentAnswerRtfText, fCurrentAfterAnswerRtfText, fCurrentAnswerCorrect);
      fCurrentBeforeAnswerRtfText := nextBeforeAnswerRtfText;
			fCurrentAnswerCorrect := false;
			fCurrentAnswerRtfText := '';
			fState := parseAnswer;
		end;
	if StringEndsWith(fCurrentAfterAnswerRtfText, QUESTION_IDENTIFIER) then
		begin
      SplitByBeginBlock(fCurrentAfterAnswerRtfText, fCurrentQuestionRtfText);
			AppendCurrentAnswerToCurrentQuestion(fCurrentBeforeAnswerRtfText,
				fCurrentAnswerRtfText, fCurrentAfterAnswerRtfText, fCurrentAnswerCorrect);
			fState := parseQuestion;
		end;
end;

procedure TTestDocument.AppendCurrentAnswerToCurrentQuestion(
	const beforeAnswerRtfText, answerRtfText, afterAnswerRtfText: string; correct: boolean);
var
	answer: TAnswer;
begin
	answer := TAnswer.Create();
	answer.BeforeAnswerRtfText := beforeAnswerRtfText;
	answer.AnswerRtfText := ReplaceAllSubstrings(answerRtfText, BOLD_FONT_IDENTIFIER, '\');
	answer.AfterAnswerRtfText := afterAnswerRtfText;
	answer.Correct := correct;
	fCurrentQuestion.Answers.Add(answer);
end;

procedure TTestDocument.ProcessNextChar(ch: char);
begin
	case fState of
		parseHeader:
			ProcessHeaderChar(ch);
		parseQuestion:
			ProcessQuestionTextChar(ch);
		parseAnswer:
			ProcessAnswerChar(ch);
		parseAfterAnswer:
			ProcessAfterAnswerChar(ch);
		else
			raise Exception.Create('Invalid state in TTestDocument.ProcessNextChar()');
	end;
end;

procedure TTestDocument.ProcessFooter();
var
  index: integer;
  startIndex, endIndex: integer;
begin
  fFooterRtfText := fCurrentQuestionRtfText;
  index := Pos(END_OF_QUESTIONS_IDENTIFIER, fFooterRtfText);
  if index = 0 then
    raise Exception.Create('Can not find: ' + END_OF_QUESTIONS_IDENTIFIER + ' at the end of the file.');
  startIndex:= index;
  while (startIndex > 1) and (fFooterRtfText[startIndex] <> '{') do
    startIndex := startIndex - 1;

  endIndex:= index;
  while (endIndex < length(fFooterRtfText)) and (fFooterRtfText[endIndex] <> '}') do
    endIndex := endIndex + 1;
  endIndex := endIndex + 1;
  while (endIndex < length(fFooterRtfText)) and (fFooterRtfText[endIndex] <> '}') do
    endIndex := endIndex + 1;
  delete(fFooterRtfText, startIndex, endIndex-startIndex+1);
end;

procedure TTestDocument.ReadFromRtfFile(const fileName: string);
var
	inFile: TFileStream;
	nextChar: char;
	bytesRead: integer;
begin
	fState := parseHeader;
	fHeaderRtfText := '';
	inFile := TFileStream.Create(fileName, fmOpenRead + fmShareDenyNone);
	try
		while (true) do
			begin
				bytesRead := inFile.Read(nextChar, 1);
				processNextChar(nextChar);
				if bytesRead = 0 then
					break;
			end;
    ProcessFooter();
	finally
		inFile.Free();
	end;
end;

{ TTestQuestion }

constructor TTestQuestion.Create();
begin
	fAnswers := TList.Create();
    fMandatory := false;
end;

destructor TTestQuestion.Destroy();
var
	i: integer;
begin
	for i := 0 to fAnswers.Count-1 do
		TAnswer(fAnswers[i]).Free();
	fAnswers.Free();
	inherited;
end;

end.
