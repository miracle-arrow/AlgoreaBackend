package payloadstest

// TaskPayloadFromAlgoreaPlatform is a task token payload generated by a real AlgoreaPlatform instance,
// but all the boolean fields have been modified to become true/false, idAttempt is required.
var TaskPayloadFromAlgoreaPlatform = map[string]interface{}{
	"idItemLocal":         "901756573345831409",
	"bHintPossible":       true,
	"randomSeed":          "556371821693219925",
	"itemUrl":             "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
	"bIsAdmin":            false,
	"bSubmissionPossible": true,
	"idAttempt":           "100",
	"platformName":        "test_dmitry",
	"sLogin":              "test",
	"bHintsAllowed":       false,
	"idTask":              interface{}(nil),
	"date":                "02-05-2019",
	"sHintsRequested":     interface{}(nil),
	"idItem":              interface{}(nil),
	"sSupportedLangProg":  "*",
	"bAccessSolutions":    true,
	"nbHintsGiven":        "0",
	"bReadAnswers":        true,
	"idUser":              "556371821693219925",
}

// TaskPayloadFromAlgoreaPlatformOriginal is a task token payload generated by a real AlgoreaPlatform instance
var TaskPayloadFromAlgoreaPlatformOriginal = map[string]interface{}{
	"idItemLocal":         "901756573345831409",
	"bHintPossible":       true,
	"randomSeed":          "556371821693219925",
	"itemUrl":             "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
	"bIsAdmin":            "0",
	"bSubmissionPossible": true,
	"idAttempt":           interface{}(nil),
	"platformName":        "test_dmitry",
	"sLogin":              "test",
	"bHintsAllowed":       "0",
	"idTask":              interface{}(nil),
	"date":                "02-05-2019",
	"sHintsRequested":     interface{}(nil),
	"idItem":              interface{}(nil),
	"sSupportedLangProg":  "*",
	"bAccessSolutions":    "1",
	"nbHintsGiven":        "0",
	"bReadAnswers":        true,
	"idUser":              "556371821693219925",
}

// AnswerPayloadFromAlgoreaPlatform is an answer token payload generated by a real AlgoreaPlatform instance,
// but idAttempt is required.
var AnswerPayloadFromAlgoreaPlatform = map[string]interface{}{
	"sAnswer": "{\"idSubmission\":\"899146309203855074\",\"langProg\":\"python\"," +
		"\"sourceCode\":\"print(min(int(input()), int(input()), int(input())))\"}",
	"idUser":          "556371821693219925",
	"itemUrl":         "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
	"platformName":    "test_dmitry",
	"randomSeed":      "556371821693219925",
	"sHintsRequested": interface{}(nil),
	"nbHintsGiven":    "0",
	"idItem":          interface{}(nil),
	"idAttempt":       "100",
	"idItemLocal":     "901756573345831409",
	"idUserAnswer":    "251510027138726857",
	"date":            "02-05-2019",
}

// AnswerPayloadFromAlgoreaPlatformOriginal is an answer token payload generated by a real AlgoreaPlatform instance
var AnswerPayloadFromAlgoreaPlatformOriginal = map[string]interface{}{
	"sAnswer": "{\"idSubmission\":\"899146309203855074\",\"langProg\":\"python\"," +
		"\"sourceCode\":\"print(min(int(input()), int(input()), int(input())))\"}",
	"idUser":          "556371821693219925",
	"itemUrl":         "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
	"platformName":    "test_dmitry",
	"randomSeed":      "556371821693219925",
	"sHintsRequested": interface{}(nil),
	"nbHintsGiven":    "0",
	"idItem":          interface{}(nil),
	"idAttempt":       interface{}(nil),
	"idItemLocal":     "901756573345831409",
	"idUserAnswer":    "251510027138726857",
	"date":            "02-05-2019",
}

// HintPayloadFromTaskPlatform is a hint token payload generated by a real TaskPlatform instance
var HintPayloadFromTaskPlatform = map[string]interface{}{
	"itemUrl":   "http://taskplatform.mblockelet.info/task.html?taskId=212873689338185696",
	"idUser":    "556371821693219925",
	"askedHint": 1,
	"date":      "02-05-2019",
}

// ScorePayloadFromGrader is a score token payload generated by a real Grader instance
var ScorePayloadFromGrader = map[string]interface{}{
	"idUser":       "556371821693219925",
	"idItem":       "403449543672183936",
	"itemUrl":      "http://taskplatform.mblockelet.info/task.html?taskId=403449543672183936",
	"idUserAnswer": "251510027138726857",
	"sAnswer": "{\"idSubmission\":\"899146309203855074\",\"langProg\":\"python\"," +
		"\"sourceCode\":\"print(min(int(input()), int(input()), int(input())))\"}",
	"score": "100",
	"date":  "02-05-2019",
}
