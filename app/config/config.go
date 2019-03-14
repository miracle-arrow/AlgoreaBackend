package config

import (
	"log"
	"path/filepath"
	"runtime"

	"github.com/go-sql-driver/mysql"
	"github.com/spf13/viper"
)

// Database is the part of the config related to the database
type Database struct {
	Connection mysql.Config
}

// Server is the part of the config for the HTTP Server
type Server struct {
	Port         int32
	ReadTimeout  int32
	WriteTimeout int32
	RootPath     string
}

// ReverseProxy is the part of the config for the Reverse Proxy
type ReverseProxy struct {
	Server string
}

// Logging for all config related to logger
type Logging struct {
	Format        string
	Output        string
	Level         string
	LogSQLQueries bool
}

// Auth is the part of the config related to the user authentication
type Auth struct {
	ProxyURL string
}

// Root is the root of the app configuration
type Root struct {
	Server       Server
	Database     Database
	ReverseProxy ReverseProxy
	Timeout      int32
	Logging      Logging
	Auth         Auth
}

var (
	configName = "config"
	configDir  = configDirectory()
)

var loadedConfig *Root

// Load loads the app configuration from files, flags, env, ..., and maps it to the config struct
// The precedence of config values in viper is the following:
// 1) explicit call to Set
// 2) flag (i.e., settable by command line)
// 3) env
// 4) config file
// 5) key/value store
// 6) default
func Load() (*Root, error) {
	if loadedConfig != nil {
		return loadedConfig, nil
	}

	var err error
	var config *Root
	setDefaults()

	// through env variables
	viper.SetEnvPrefix("algorea") // env variables must be prefixed by "ALGOREA_"
	viper.AutomaticEnv()          // read in environment variables

	// through the config file
	viper.SetConfigName(configName)
	viper.AddConfigPath(configDir)

	if err = viper.ReadInConfig(); err != nil {
		log.Print("Cannot read the config file, ignoring it.")
	}

	// map the given config to a static struct
	if err = viper.Unmarshal(&config); err != nil {
		log.Fatal("Cannot map the given config to the expected configuration struct:", err)
		return nil, err
	}
	loadedConfig = config
	return config, nil
}

// ClearCachedConfig clears the cached config (for testing purposes).
func ClearCachedConfig() {
	loadedConfig = nil
}

func setDefaults() {

	// root
	viper.SetDefault("timeout", 15)

	// server
	viper.SetDefault("server.port", 8080)
	viper.SetDefault("server.readTimeout", 60)  // in seconds
	viper.SetDefault("server.writeTimeout", 60) // in seconds
	viper.SetDefault("server.rootpath", "/")

	// logging
	viper.SetDefault("logging.format", "json")
	viper.SetDefault("logging.output", "file")
	viper.SetDefault("logging.level", "info")
	viper.SetDefault("logging.logSqlQueries", true)
}

func configDirectory() string {
	_, codeFilePath, _, _ := runtime.Caller(0)
	codeDir := filepath.Dir(codeFilePath)
	return filepath.Dir(codeDir + "/../../conf/")
}
