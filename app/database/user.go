package database

// User represents data associated with the user (from the `users` table)
type User struct {
	ID                   int64
	Login                string
	DefaultLanguage      string
	DefaultLanguageID    int64
	IsAdmin              bool
	IsTempUser           bool `sql:"column:temp_user"`
	SelfGroupID          *int64
	OwnedGroupID         *int64
	AccessGroupID        *int64
	AllowSubgroups       bool
	NotificationReadDate *Time
}

// Clone returns a deep copy of the given User structure
func (u *User) Clone() *User {
	result := *u
	if result.NotificationReadDate != nil {
		notificationReadDateCopy := *result.NotificationReadDate
		result.NotificationReadDate = &notificationReadDateCopy
	}
	return &result
}
