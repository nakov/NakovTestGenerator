unit Answers;

interface

uses
	Classes, SysUtils,
	GeneratedTest;

const
	HEADER_FILE_NAME = 'answers_header.inc';
	FOOTER_FILE_NAME = 'answers_footer.inc';
	CRLF = #13#10;

type
	TGeneratedAnswers = class
		fHeaderHtmlText: string;
		fBodyHtmlText: string;
		fFooterHtmlText: string;
		fHeaderTableRowGenerated: boolean;
		function GetAsHtmlText(): string;
		function GetFileContentsAsString(const fileName: string): string;
		procedure GenerateHeaderTableRow(questionsCount: integer);
	public
		constructor Create();
		procedure AppendAnswers(generatedTest: TGeneratedTest; const lang: string);
		procedure WriteToHtmlFile(const fileName: string);
	end;

implementation

{ GeneratedAnswers }

procedure TGeneratedAnswers.AppendAnswers(generatedTest: TGeneratedTest; const lang: string);
var
	i: integer;
	testVariant: string;
	generatedQuestion: TGeneratedQuestion;
	correctAnswer: string;
begin
	// Generate table first (header) row if not generated yet
	if not fHeaderTableRowGenerated then
		begin
			GenerateHeaderTableRow(generatedTest.GeneratedQuestions.Count);
			fHeaderTableRowGenerated := true;
		end;

	// Generate next table row and put correct answers from generatedTest in it
	testVariant := generatedTest.GetVariantNumberAsText();
	fBodyHtmlText := fBodyHtmlText +
		' <tr style=''height:3.15pt''>' + CRLF +
		'  <td width=34 valign=top style=''width:25.35pt;border:solid windowtext 1.0pt;' + CRLF +
		'  padding:2.85pt 0cm 2.85pt 0cm;height:3.15pt''>' + CRLF +
		'  <p class=MsoNormal align=center style=''text-align:center;text-indent:0cm''><span' + CRLF +
		'  style=''font-size:10.0pt;font-family:Tahoma''>' + testVariant + '</span></p>' + CRLF +
		'  </td>' + CRLF;
	for i := 0 to generatedTest.GeneratedQuestions.Count-1 do
		begin
			generatedQuestion := TGeneratedQuestion(generatedTest.GeneratedQuestions[i]);
      if lang = 'BG' then
  			correctAnswer := chr(ord('а') + generatedQuestion.CorrectAnswerIndex)
      else
  			correctAnswer := chr(ord('a') + generatedQuestion.CorrectAnswerIndex);
			fBodyHtmlText := fBodyHtmlText +
				'  <td width=22 style=''width:16.6pt;border:solid windowtext 1.0pt;border-left:' + CRLF +
				'  none;padding:2.85pt 0cm 2.85pt 0cm;height:3.15pt''>' + CRLF +
				'  <p class=MsoNormal align=center style=''text-align:center;text-indent:0cm''' + CRLF +
				'  ><span lang=EN-US style=''font-size:10.0pt;font-family:Tahoma''>' + correctAnswer + '</span></p>' + CRLF +
				'  </td>' + CRLF;
		end;
	fBodyHtmlText := fBodyHtmlText +
		' </tr>';
end;

constructor TGeneratedAnswers.Create();
begin
	fHeaderHtmlText := GetFileContentsAsString(HEADER_FILE_NAME);
	fBodyHtmlText := '';
	fFooterHtmlText := GetFileContentsAsString(FOOTER_FILE_NAME);
	fHeaderTableRowGenerated := false;
end;

procedure TGeneratedAnswers.GenerateHeaderTableRow(questionsCount: integer);
var
	i: integer;
begin
	// Generate table first row
	fBodyHtmlText := fBodyHtmlText +
		' <tr style=''height:3.15pt''>' + CRLF +
		'  <td width=34 valign=top style=''width:25.35pt;border:solid windowtext 1.0pt;' + CRLF +
		'  padding:2.85pt 0cm 2.85pt 0cm;height:3.15pt''>' + CRLF +
		'  <p class=MsoNormal align=center style=''text-align:center;text-indent:0cm''><span' + CRLF +
		'  style=''font-size:10.0pt;font-family:Tahoma''>Вар.</span></p>' + CRLF +
		'  </td>' + CRLF;
	for i := 1 to questionsCount do
		fBodyHtmlText := fBodyHtmlText +
			'  <td width=22 style=''width:16.6pt;border:solid windowtext 1.0pt;border-left:' + CRLF +
			'  none;padding:2.85pt 0cm 2.85pt 0cm;height:3.15pt''>' + CRLF +
			'  <p class=MsoNormal align=center style=''text-align:center;text-indent:0cm''' + CRLF +
			'  ><span lang=EN-US style=''font-size:10.0pt;font-family:Tahoma''>' +
				IntToStr(i) + '</span></p>' + CRLF +
			'  </td>' + CRLF;
	fBodyHtmlText := fBodyHtmlText +
		' </tr>';
end;

function TGeneratedAnswers.GetAsHtmlText(): string;
begin
	Result := fHeaderHtmlText + fBodyHtmlText + fFooterHtmlText;
end;

function TGeneratedAnswers.GetFileContentsAsString(const fileName: string): string;
var
	inFile: TFileStream;
begin
	inFile := TFileStream.Create(fileName, fmOpenRead + fmShareDenyNone);
	try
		SetLength(Result, inFile.Size);
		inFile.Read(Result[1], inFile.Size);
	finally
		inFile.Free();
	end;
end;

procedure TGeneratedAnswers.WriteToHtmlFile(const fileName: string);
var
	outputFile: TFileStream;
	resultHtmlDocument: string;
begin
	outputFile := TFileStream.Create(fileName, fmCreate);
	try
		resultHtmlDocument := GetAsHtmlText();
		outputFile.Write(resultHtmlDocument[1], length(resultHtmlDocument));
	finally
		outputFile.Free();
	end;
end;

end.
