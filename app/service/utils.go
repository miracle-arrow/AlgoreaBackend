package service

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"unicode"
)

// QueryParamToInt64Slice extracts from the query parameter of the request a list of integer separated by commas (',')
// returns `nil` for no IDs
func QueryParamToInt64Slice(req *http.Request, paramName string) ([]int64, error) {
	var ids []int64
	paramValue := req.URL.Query().Get(paramName)
	if paramValue == "" {
		return ids, nil
	}
	idsStr := strings.Split(paramValue, ",")
	for _, idStr := range idsStr {
		id, err := strconv.ParseInt(idStr, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("unable to parse one of the integer given as query arg (value: '%s', param: '%s')", idStr, paramName)
		}
		ids = append(ids, id)
	}
	return ids, nil
}

// ResolveURLQueryGetInt64Field extracts a get-parameter of type int64 from the query
func ResolveURLQueryGetInt64Field(httpReq *http.Request, name string) (int64, error) {
	strValue := httpReq.URL.Query().Get(name)
	int64Value, err := strconv.ParseInt(strValue, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("missing %s", name)
	}
	return int64Value, nil
}

// ResolveURLQueryGetStringField extracts a get-parameter of type string from the query, fails if the value is empty
func ResolveURLQueryGetStringField(httpReq *http.Request, name string) (string, error) {
	strValue := httpReq.URL.Query().Get(name)
	if strValue == "" {
		return "", fmt.Errorf("missing %s", name)
	}
	return strValue, nil
}

// ResolveURLQueryGetBoolField extracts a get-parameter of type bool (0 or 1) from the query, fails if the value is empty
func ResolveURLQueryGetBoolField(httpReq *http.Request, name string) (bool, error) {
	strValue := httpReq.URL.Query().Get(name)
	if strValue == "" {
		return false, fmt.Errorf("missing %s", name)
	}
	return strValue == "1", nil
}

// ConvertSliceOfMapsFromDBToJSON given a slice of maps that represents a DB result data,
// converts it to a slice of maps for rendering JSON so that:
// 1) all maps keys with "__" are considered as paths in JSON (converts "User__ID":... to "user":{"id": ...})
// 2) all maps keys are converted to snake case
// 3) prefixes are stripped, values are converted to needed types accordingly
// 4) fields with nil values are skipped
func ConvertSliceOfMapsFromDBToJSON(dbMap []map[string]interface{}) []map[string]interface{} {
	convertedResult := make([]map[string]interface{}, len(dbMap))
	for index := range dbMap {
		convertedResult[index] = map[string]interface{}{}
		for key, value := range dbMap[index] {
			currentMap := &convertedResult[index]

			subKeys := strings.Split(key, "__")
			for subKeyIndex, subKey := range subKeys {
				if subKeyIndex == len(subKeys)-1 {
					setConvertedValueToJSONMap(subKey, value, currentMap)
				} else {
					subKey = toSnakeCase(subKey)
					shouldCreateSubMap := true
					if subMap, hasSubMap := (*currentMap)[subKey]; hasSubMap {
						if subMap, ok := subMap.(*map[string]interface{}); ok {
							currentMap = subMap
							shouldCreateSubMap = false
						}
					}
					if shouldCreateSubMap {
						(*currentMap)[subKey] = &map[string]interface{}{}
						currentMap = (*currentMap)[subKey].(*map[string]interface{})
					}
				}
			}
		}
	}
	return convertedResult
}

func setConvertedValueToJSONMap(valueName string, value interface{}, result *map[string]interface{}) {
	if value == nil {
		return
	}

	if valueName == "ID" {
		(*result)["id"] = value.(int64)
		return
	}

	if valueName[:2] == "id" {
		valueName = toSnakeCase(valueName[2:]) + "_id"
		(*result)[valueName] = value.(int64)
		return
	}

	switch valueName[0] {
	case 'b':
		value = value == 1
		fallthrough
	case 's':
		fallthrough
	case 'i':
		valueName = valueName[1:]
	}
	(*result)[toSnakeCase(valueName)] = value
}

// toSnakeCase convert the given string to snake case following the Golang format:
// acronyms are converted to lower-case and preceded by an underscore.
func toSnakeCase(in string) string {
	runes := []rune(in)

	var out []rune
	for i := 0; i < len(runes); i++ {
		if i > 0 && (unicode.IsUpper(runes[i]) || unicode.IsNumber(runes[i])) &&
			((i+1 < len(runes) && unicode.IsLower(runes[i+1])) || unicode.IsLower(runes[i-1])) {
			out = append(out, '_')
		}
		out = append(out, unicode.ToLower(runes[i]))
	}

	return string(out)
}
