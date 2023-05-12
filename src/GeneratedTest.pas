unit GeneratedTest;

interface

uses
	Classes, SysUtils, Math,
	TestDocument, StringUtils;

const
	TEST_VARIANT_IDENTIFICATOR = '# # #';

type
	TGeneratedTest = class
	private
		fGeneratedQuestions: TList;
		fVariantNumber: integer;
	public
		property GeneratedQuestions: TList read fGeneratedQuestions write fGeneratedQuestions;
		property VariantNumber: integer read fVariantNumber write fVariantNumber;
		function GetVariantNumberAsText(): string;
		constructor Create();
		destructor Destroy(); override;
	end;

	TGeneratedQuestion = class
	private
		fTestQuestion: TTestQuestion;
		fAnswerTexts: TStringList;
		fCorrectAnswerIndex: integer;
	public
		property TestQuestion: TTestQuestion read fTestQuestion;
		property AnswerTexts: TSTringList read fAnswerTexts write fAnswerTexts;
		property CorrectAnswerIndex: integer read fCorrectAnswerIndex;
		constructor Create(const testQuestion: TTestQuestion);
		destructor Destroy(); override;
	end;

	TRandomTestGenerator = class
	private
		class procedure GenerateRandomAnswers(
			generatedQuestion: TGeneratedQuestion; maxAnswersPerQuestion: integer);
		class procedure	AppendAnswersRtfText(testQuestion: TTestQuestion;
      generatedQuestion: TGeneratedQuestion; const lang: string;
      var resultRtfDocument: string);
		class function GetTestAsRtfText(testDocument: TTestDocument;
			generatedTest: TGeneratedTest; const lang: string): string;
	public
		class function GenerateRandomTest(testVariantNumber: integer;
      testDocument: TTestDocument; maxQuestionsToGenerate,
      maxAnswersPerQuestion: integer; const lang: string): TGeneratedTest;
		class procedure WriteTestToFile(testDocument: TTestDocument;
			generatedTest: TGeneratedTest; const fileName: string; const lang: string);
	end;


procedure RandomizeIntegerArray(var arr: array of integer);
procedure RandomizeStringList(var list: TStringList);


implementation


{ TGeneratedTest }

constructor TGeneratedTest.Create;
begin
	fGeneratedQuestions := TList.Create();
end;

destructor TGeneratedTest.Destroy;
begin
	fGeneratedQuestions.Free();
	inherited;
end;


function TGeneratedTest.GetVariantNumberAsText: string;
var
	testVariant: string;
begin
	Str(fVariantNumber, testVariant);
	while Length(testVariant) < 3 do
		testVariant := '0' + testVariant;
	Result := testVariant;
end;

{ TGeneratedQuestion }

constructor TGeneratedQuestion.Create(const testQuestion: TTestQuestion);
begin
	fTestQuestion := testQuestion;
	fAnswerTexts := TStringList.Create();
	fCorrectAnswerIndex := -1;
end;

destructor TGeneratedQuestion.Destroy();
begin
	fAnswerTexts.Free();
	inherited;
end;


{ TRandomTestGenerator }

class procedure TRandomTestGenerator.GenerateRandomAnswers(
	generatedQuestion: TGeneratedQuestion; maxAnswersPerQuestion: integer);
var
	testQuestion: TTestQuestion;
	testAnswers: TList;
	testAnswer: TAnswer;
	correctAnswers, wrongAnswers: TStringList;
	i: integer;
	wrongAnswersCount: integer;
	correctAnswer, wrongAnswer: string;
	randomCorrectAnswerIndex: integer;
begin
	// Extract a list of correct and a list of wrong answers as RTF text
	testQuestion := generatedQuestion.TestQuestion;
	testAnswers := testQuestion.Answers;
	correctAnswers := TStringList.Create();
	wrongAnswers := TStringList.Create();
	for i := 0 to testAnswers.Count-1 do
		begin
			testAnswer := TAnswer(testAnswers[i]);
			if testAnswer.Correct then
				correctAnswers.Add(testAnswer.AnswerRtfText)
			else
				wrongAnswers.Add(testAnswer.AnswerRtfText)
		end;

	// Randomize the correct and wrong answers
	RandomizeStringList(correctAnswers);
	RandomizeStringList(wrongAnswers);

	// Append wrong answers
	wrongAnswersCount := Min(maxAnswersPerQuestion-1, wrongAnswers.Count);
	for i := 0 to wrongAnswersCount-1 do
		begin
			wrongAnswer := wrongAnswers[i];
			generatedQuestion.AnswerTexts.Add(wrongAnswer);
		end;

	// Append one correct answer
	if correctAnswers.Count = 0 then
		raise Exception.Create('Question without any correct answer found.');
	generatedQuestion.fCorrectAnswerIndex := Random(generatedQuestion.AnswerTexts.Count+1);
	randomCorrectAnswerIndex := Random(correctAnswers.Count);
	correctAnswer := correctAnswers[randomCorrectAnswerIndex];
	generatedQuestion.AnswerTexts.Insert(generatedQuestion.CorrectAnswerIndex, correctAnswer);
end;

class procedure TRandomTestGenerator.AppendAnswersRtfText(
	testQuestion: TTestQuestion; generatedQuestion: TGeneratedQuestion;
  const lang: string; var resultRtfDocument: string);

	function GetLetterByIndexAsRtf(const lang: string; index: integer): string;
	begin
    if lang = 'BG' then
  		Result := '\''' + IntToHex($e0 + index, 2)
    else
  		Result := chr(ord('a') + index);
	end;

var
	i: integer;
	originalAnswer, lastAnswer: TAnswer;
	generatedAnswer: string;
begin
  if (generatedQuestion.AnswerTexts.Count > testQuestion.Answers.Count) then
    raise Exception.Create('Answers of some question are less than required.');

	for i := 0 to generatedQuestion.AnswerTexts.Count-1 do
		begin
 			originalAnswer := TAnswer(testQuestion.Answers[i]);
 			resultRtfDocument := resultRtfDocument + originalAnswer.BeforeAnswerRtfText;
			resultRtfDocument := resultRtfDocument + GetLetterByIndexAsRtf(lang, i) + ')';
			generatedAnswer := generatedQuestion.AnswerTexts[i];
			resultRtfDocument := resultRtfDocument + generatedAnswer;
      if (i = generatedQuestion.AnswerTexts.Count-1) then
        begin
          // We are at the last answer of this question
          lastAnswer := TAnswer(testQuestion.Answers[testQuestion.Answers.Count-1]);
     			resultRtfDocument := resultRtfDocument + lastAnswer.AfterAnswerRtfText;
        end
      else
        begin
          resultRtfDocument := resultRtfDocument + originalAnswer.AfterAnswerRtfText;
        end;
		end;
end;

class function TRandomTestGenerator.GenerateRandomTest(
	testVariantNumber: integer; testDocument: TTestDocument;
	maxQuestionsToGenerate, maxAnswersPerQuestion: integer;
  const lang: string): TGeneratedTest;
var
	testQuestionIndexes: array of integer;
	testQuestionIndex: integer;
    mandatoryQuestionsCount, nonMandatoryQuestionsCount, questionsCount: integer;
	testQuestion: TTestQuestion;
	generatedQuestion: TGeneratedQuestion;
	i: integer;
    currentMandatoryQuestionIndex: integer;
	generatedRandomTest: TGeneratedTest;
begin
	Randomize();
	generatedRandomTest := TGeneratedTest.Create();

    // Calculate the count of the mandatory questions
  mandatoryQuestionsCount := 0;
	for i := 0 to testDocument.Questions.Count-1 do
        if TTestQuestion(testDocument.Questions[i]).Mandatory then
            inc(mandatoryQuestionsCount);

	// Generate a random sequence of question indexes of non-mandatory questions
  nonMandatoryQuestionsCount := testDocument.Questions.Count-mandatoryQuestionsCount;
	SetLength(testQuestionIndexes, nonMandatoryQuestionsCount);
  testQuestionIndex := 0;
	for i := 0 to testDocument.Questions.Count-1 do
        if not TTestQuestion(testDocument.Questions[i]).Mandatory then
            begin
            	testQuestionIndexes[testQuestionIndex] := i;
                inc(testQuestionIndex);
            end;
	RandomizeIntegerArray(testQuestionIndexes);

	// Calculate the count of questions to produce
	questionsCount := Min(maxQuestionsToGenerate, testDocument.Questions.Count);

	// Ensure the question index array has enough length
    SetLength(testQuestionIndexes, questionsCount);

    // Add the mandatory questions in the end of the list (replacing some elements from the end)
    currentMandatoryQuestionIndex := questionsCount-1;
    for i := testDocument.Questions.Count-1 downto 0 do
        if TTestQuestion(testDocument.Questions[i]).Mandatory then
            begin
                testQuestionIndexes[currentMandatoryQuestionIndex] := i;
                dec(currentMandatoryQuestionIndex);
                if currentMandatoryQuestionIndex < 0 then
                    break;
            end;

	// Create the randomly generated list of questions
	for i := 0 to questionsCount-1 do
		begin
			testQuestionIndex := testQuestionIndexes[i];
			testQuestion := TTestQuestion(testDocument.Questions[testQuestionIndex]);
			generatedQuestion := TGeneratedQuestion.Create(testQuestion);
			generatedRandomTest.GeneratedQuestions.Add(generatedQuestion);
			GenerateRandomAnswers(generatedQuestion, maxAnswersPerQuestion);
		end;

	generatedRandomTest.VariantNumber := testVariantNumber;
	Result := generatedRandomTest;
end;

class function TRandomTestGenerator.GetTestAsRtfText(
	testDocument: TTestDocument; generatedTest: TGeneratedTest; const lang: string): string;
var
	resultRtfDocument: string;
	questionIndex: integer;
	generatedQuestion: TGeneratedQuestion;
	testQuestion: TTestQuestion;
	header, testVariant: string;
  testQuestionText, questionNumberText: string;
begin
	resultRtfDocument := '';
	testVariant := generatedTest.GetVariantNumberAsText();
	header := ReplaceAllSubstrings(
		testDocument.HeaderRtfText, TEST_VARIANT_IDENTIFICATOR, testVariant);
	resultRtfDocument := resultRtfDocument + header;
	for questionIndex := 0 to generatedTest.GeneratedQuestions.Count-1 do
		begin
			generatedQuestion := TGeneratedQuestion(generatedTest.GeneratedQuestions[questionIndex]);
			testQuestion := generatedQuestion.TestQuestion;
      testQuestionText := testQuestion.QuestionRtfText;
      questionNumberText := IntToStr(1 + questionIndex) + '.';
      testQuestionText := ReplaceAllSubstrings(
        testQuestionText, MANDATORY_QUESTION_IDENTIFIER, questionNumberText);
      testQuestionText := ReplaceAllSubstrings(
        testQuestionText, QUESTION_IDENTIFIER, questionNumberText);
			resultRtfDocument := resultRtfDocument + testQuestionText;
			AppendAnswersRtfText(testQuestion, generatedQuestion, lang, resultRtfDocument);
		end;
	resultRtfDocument := resultRtfDocument + testDocument.FooterRtfText;
	Result := resultRtfDocument;
end;

class procedure TRandomTestGenerator.WriteTestToFile(testDocument: TTestDocument;
	generatedTest: TGeneratedTest; const fileName: string; const lang: string);
var
	outputFile: TFileStream;
	resultRtfDocument: string;
begin
	outputFile := TFileStream.Create(fileName, fmCreate);
	try
		resultRtfDocument := GetTestAsRtfText(testDocument, generatedTest, lang);
		outputFile.Write(resultRtfDocument[1], length(resultRtfDocument));
	finally
		outputFile.Free();
	end;
end;


{ Utility functions }

procedure RandomizeStringList(var list: TStringList);
var
	len, i, index1, index2: integer;
	temp : string;
begin
	len := list.Count;
	for i := 1 to len do
		begin
			index1 := Random(len);
			index2 := Random(len);
			temp := list[index1];
			list[index1] := list[index2];
			list[index2] := temp;
		end;
end;

procedure RandomizeIntegerArray(var arr: array of integer);
var
	len, i, index1, index2, temp: integer;
begin
	len := length(arr);
	for i := 1 to len do
		begin
			index1 := Random(len);
			index2 := Random(len);
			temp := arr[index1];
			arr[index1] := arr[index2];
			arr[index2] := temp;
		end;
end;


end.
