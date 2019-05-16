package payloads

import (
	"fmt"
	"reflect"
	"strings"

	"github.com/France-ioi/AlgoreaBackend/app/formdata"
)

// Binder is an interface for managing payloads.
type Binder interface {
	Bind() error
}

// ParseMap converts a map into a structure and validates fields
func ParseMap(raw map[string]interface{}, target interface{}) error {
	if err := formdata.NewFormData(target).ParseMapData(raw); err != nil {
		typeName := reflect.TypeOf(target).Elem().Name()
		return fmt.Errorf("invalid %s: %s", typeName, err.Error())
	}

	if binder, ok := target.(Binder); ok {
		return binder.Bind()
	}

	return nil
}

// ConvertIntoMap converts a struct into a map
// Fields without a `json` tag or having '-' as a json field name are skipped.
func ConvertIntoMap(source interface{}) map[string]interface{} {
	sourceValue := reflect.ValueOf(source)
	for sourceValue.Kind() == reflect.Ptr {
		sourceValue = sourceValue.Elem()
	}

	sourceType := sourceValue.Type()
	fieldsNumber := sourceValue.NumField()
	out := make(map[string]interface{}, fieldsNumber)
	for i := 0; i < fieldsNumber; i++ {
		field := sourceType.Field(i)
		jsonName := getJSONFieldName(&field)
		if jsonName != "-" {
			fieldValue := sourceValue.Field(i)
			if fieldValue.CanInterface() { // skip unexported fields
				for fieldValue.IsValid() && fieldValue.Type().Kind() == reflect.Ptr && !fieldValue.IsNil() {
					fieldValue = fieldValue.Elem()
				}
				if fieldValue.Kind() == reflect.Struct {
					out[jsonName] = ConvertIntoMap(fieldValue.Addr().Interface())
				} else {
					out[jsonName] = fieldValue.Interface()
				}
			}
		}
	}
	return out
}

func getJSONFieldName(structField *reflect.StructField) string {
	jsonTagParts := strings.Split(structField.Tag.Get("json"), ",")
	if jsonTagParts[0] == "" {
		return "-"
	}
	return jsonTagParts[0]
}