package types

import (
	"encoding/json"
	"testing"

	assertlib "github.com/stretchr/testify/assert"
)

type SampleBoolInput struct {
	Enabled             RequiredBool
	Deletable           NullableBool
	CachedFullAccess    OptionalBool
	CachedManagerAccess OptNullBool
}

func (v *SampleBoolInput) validate() error {
	return Validate([]string{"enabled", "deletable", "cachedFullAccess", "cachedManagerAccess"},
		&v.Enabled, &v.Deletable, &v.CachedFullAccess, &v.CachedManagerAccess)
}

func TestNewBool(t *testing.T) {
	assert := assertlib.New(t)
	var value = true
	n := NewBool(value)
	val, null, set := n.AllAttributes()
	assert.Equal(value, n.Value)
	assert.Equal(value, val)
	assert.True(n.Set)
	assert.True(set)
	assert.False(n.Null)
	assert.False(null)
}

func TestBoolValid(t *testing.T) {
	assert := assertlib.New(t)

	jsonInput := `{ "Enabled": true, "Deletable": false, "CachedFullAccess": true, "CachedManagerAccess": true}`
	input := &SampleBoolInput{}
	assert.NoError(json.Unmarshal([]byte(jsonInput), &input))
	assert.Equal(true, input.Enabled.Value)
	assert.Equal(false, input.Deletable.Value)
	assert.Equal(true, input.CachedFullAccess.Value)
	assert.Equal(true, input.CachedManagerAccess.Value)
	assert.NoError(input.validate())
}

func TestBoolWithNonBool(t *testing.T) {
	assert := assertlib.New(t)

	jsonInput := `{ "Enabled": 1234, "Deletable": true, "CachedFullAccess": false, "CachedManagerAccess": true }`
	input := &SampleBoolInput{}
	assert.Error(json.Unmarshal([]byte(jsonInput), &input))
}

func TestBoolWithDefault(t *testing.T) {
	assert := assertlib.New(t)

	jsonInput := `{ "Enabled": false, "Deletable": false, "CachedFullAccess": false, "CachedManagerAccess": false}`
	input := &SampleBoolInput{}
	assert.NoError(json.Unmarshal([]byte(jsonInput), &input))
	assert.NoError(input.validate())
}

func TestBoolWithNull(t *testing.T) {
	assert := assertlib.New(t)

	jsonInput := `{ "Enabled": null, "Deletable": null, "CachedFullAccess": null, "CachedManagerAccess": null }`
	input := &SampleBoolInput{}
	assert.NoError(json.Unmarshal([]byte(jsonInput), &input))
	assert.Error(input.Enabled.Validate())
	assert.NoError(input.Deletable.Validate())
	assert.Error(input.CachedFullAccess.Validate())
	assert.NoError(input.CachedManagerAccess.Validate())
	assert.Error(input.validate())
}

func TestBoolWithNotSet(t *testing.T) {
	assert := assertlib.New(t)

	jsonInput := `{}`
	input := &SampleBoolInput{}
	assert.NoError(json.Unmarshal([]byte(jsonInput), &input))
	assert.Error(input.Enabled.Validate())
	assert.Error(input.Deletable.Validate())
	assert.NoError(input.CachedFullAccess.Validate())
	assert.NoError(input.CachedManagerAccess.Validate())
	assert.Error(input.validate())
}
