program NakovTestGenerator;

{$R *.RES}

uses
  SysUtils,
  IniFiles,
  TestDocument in 'TestDocument.pas',
  StringUtils in 'StringUtils.pas',
  GeneratedTest in 'GeneratedTest.pas',
  Answers in 'Answers.pas';

const
	INI_FILE_NAME = 'NakovTestGenerator.ini';
	INI_GENERAL_SECTION = 'General';
	ID_INPUT_RTF_FILE_NAME = 'INPUT_RTF_FILE_NAME';
	ID_OUTPUT_RTF_FILE_NAME_PREFIX = 'OUTPUT_RTF_FILE_NAME_PREFIX';
	ID_ANSWERS_HTML_OUTPUT_FILE_NAME = 'ANSWERS_HTML_OUTPUT_FILE_NAME';
	ID_NUMBER_OF_TESTS_TO_GENERATE = 'NUMBER_OF_TESTS_TO_GENERATE';
	ID_MAX_QUESTIONS_COUNT = 'MAX_QUESTIONS_COUNT';
	ID_MAX_ANSWERS_PER_QUESTION = 'MAX_ANSWERS_PER_QUESTION';
	ID_LANGUAGE = 'LANG';

var
	InputRtfFileName: string;
	OutputRtfFileNamePrefix: string;
	AnswersHtmlOutputFileName: string;
	NumberOfTestsToGenerate: integer;
	MaxQuestionsCount: integer;
	MaxAnswersPerQuestion: integer;
	AnswersLanguage: string;

procedure LoadSettings();
var
    settingsIniFile: TIniFile;
    path: string;
begin
    path := ExtractFilePath(ParamStr(0));
    settingsIniFile := TIniFile.Create(path + INI_FILE_NAME);
    try
        InputRtfFileName :=
            settingsIniFile.ReadString(INI_GENERAL_SECTION, ID_INPUT_RTF_FILE_NAME, '');
        OutputRtfFileNamePrefix :=
            settingsIniFile.ReadString(INI_GENERAL_SECTION, ID_OUTPUT_RTF_FILE_NAME_PREFIX, '');
        AnswersHtmlOutputFileName :=
            settingsIniFile.ReadString(INI_GENERAL_SECTION, ID_ANSWERS_HTML_OUTPUT_FILE_NAME, '');
        NumberOfTestsToGenerate :=
            settingsIniFile.ReadInteger(INI_GENERAL_SECTION, ID_NUMBER_OF_TESTS_TO_GENERATE, 0);
        MaxQuestionsCount :=
            settingsIniFile.ReadInteger(INI_GENERAL_SECTION, ID_MAX_QUESTIONS_COUNT, 0);
        MaxAnswersPerQuestion :=
            settingsIniFile.ReadInteger(INI_GENERAL_SECTION, ID_MAX_ANSWERS_PER_QUESTION, 0);
        AnswersLanguage :=
            settingsIniFile.ReadString(INI_GENERAL_SECTION, ID_LANGUAGE, 'EN');
    finally
        settingsIniFile.Free();
    end;
end;

var
	test: TTestDocument;
	randomGeneratedTest: TGeneratedTest;
	testNumber: integer;
	generatedAnswers : TGeneratedAnswers;
    outputFileName: string;
begin
    LoadSettings();

	// Create a test document and read it from input RTF file
	test := TTestDocument.Create();
	test.ReadFromRtfFile(InputRtfFileName);

	// Create answers generator
	generatedAnswers := TGeneratedAnswers.Create();

	// Generate tests and save them to RTF output files
	for testNumber := 1 to NumberOfTestsToGenerate do
		begin
			randomGeneratedTest := TRandomTestGenerator.GenerateRandomTest(
				testNumber, test, MaxQuestionsCount, MaxAnswersPerQuestion, AnswersLanguage);
      outputFileName := OutputRtfFileNamePrefix +
        randomGeneratedTest.GetVariantNumberAsText() + '.rtf';
			TRandomTestGenerator.WriteTestToFile(test, randomGeneratedTest, outputFileName, AnswersLanguage);
			generatedAnswers.AppendAnswers(randomGeneratedTest, AnswersLanguage);
			randomGeneratedTest.Free();
		end;
	generatedAnswers.WriteToHtmlFile(AnswersHtmlOutputFileName);

	generatedAnswers.Free();
	test.Free();
end.

