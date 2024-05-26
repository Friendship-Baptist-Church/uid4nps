# Introduction
They are a set of Java classes that can be used to parse DTS-formatted accounting logs provided by a Microsoft NPS (Radius Server) and pushing them to a PANOS cluster as login/logout UserID API events

## Features

  * Parsing DTS-formatted log files. Processing only Start (“Acct-Status-Type” = 1), Interim (“Acct-Status-Type” = 3) and Stop (“Acct-Status-Type” = 2) log records
  * Filtering capability to limit records to be processed based on user provided pattern matching
  * Buffering userID events with synch flushing to avoid PANOS API overload in peak hours
  * Support file LOG rotation by NPS as far as they are the only “.log” files in the monitored directory
  * Support deploying the main class as a Windows Service (`start()` and `stop()` methods provided)
  * Support two-member PANOS clusters. The application establishes connections with both members but only sends updates to one of them at a given time
  * Supports registering the IP addresses from the users as PANOS 6.0 dynamic address objects using the NAS-Identifier value in the DTS record as TAG

## Configuration File Attributes
  * *fw1Url*: (i.e. `https\://172.16.214.103`)  - URL to reach the first PANOS device in the cluster
  * *fw2Url*: (i.e. `https\://172.16.214.103`)  - URL to reach the second PANOS device in the cluster (use the same value as fw1Url if needed but don’t let the field blank)
  * *fw1PanosKey* : (i.e. `LUFRPT14MW5xOEo1R09KVlBZNnpnemh0VHRBOWl6TGM9bXcwM3JHUGVhRlNiY0dCR0srNERUQT09`) – PANOS API Key
  * *fw2PanosKey*: use the same value as fw1PanosKey if needed but don’t let the field blank)
  * *vsys*: The target vsys for the user-id messages. Use "none" if you don't want to use the multi-vsys feature.
  * *logLevel*:  (i.e. `INFO`) – Possible values = `ERROR, WARNING, INFO, FINE, FINEST`
  * *outputLogFile*: (i.e. `userid4nps.log`) – File that will host the log messages provided by the classes
  * *maxPendingEntries*: (i.e. `100`) – How many login/logout events will we buffer before sending the update to the PANOS cluster
  * *panosBufferedTime*: (i.e. `2000`) – Time (in milliseconds) we’ll keep events in the buffer before flushing it
  * *defaultDomain*: (i.e. `corppro`) – Domain to be appended to each user identification provided it doesn’t already include a domain
  * *useridTimeout*: (i.e. `1440`) - Timeout (in milliseconds) for any entry send to the PANOS device
  * *npsLogDir*: (i.e. ```C\:/tmp`) – Directory were the DTS-formated log files are stored
  * *includePattern*: (i.e. `.*CG-WISMB.*`) - Regular expression to be matched to accept a NPS log for processing
  * *dynAddressFeature*: (i.e. `true | false`) – Set to `true` if you want IP addresses to be registered using the PANOS 6.0 dynamic address object feature

## Running uid4nps as a standalone application
Just invoke the jar file from any java7 enabled server passing the config file as a command line argument
```
apple$ java -jar userid4nps.jar
usage: userid4nps -config=<config_file>
apple$
apple$ java -jar userid4nps.jar –config=userid4nps.cfg 
mar 27, 2014 10:17:36 AM uid4nps.userid4nps tryNewFile
INFO: Opening log file 'newlog.log'
mar 27, 2014 10:17:36 AM uid4nps.userid4nps tryNewFile
INFO: Positioning at the end of the log file 'newlog.log'
```

## Deploying userid4nps as a Windows Service
You can use any Service Wrapper you feel comfortable with. The following instructions are valid for the PROCRUN service wrapper tools from the Apache Commons project [http://commons.apache.org/proper/commons-daemon/procrun.html]

### Step 1: Install the service
This is a very basic step that only requires executing the following command from the directory “procrun” was downloaded to:
```powershell
> prunsrv //IS//uid4nps
```
Be careful of using the right “prunsrv” version based on our architecture (i32, amd64 or ia64)
===Step 2: Configure the service===
Once the service is installed you can configure it with the following command also launched from the directory “procrun” was donwloaded to:
```
> prunmgr //ES//uid4nps
```
The following are parameters that must be correctly configured in the prunmgr tabs
  * *Logging TAB*: Add file pointers to the "redirect" fields so you can get traces in case of error
  * *Java TAB*:
   * Java Virtual Machine: Pointer to the jvm.dll server (i.e. C:\Program Files\Java\jre7\bin\server\jvm.dll)
   * Java Classpath: Full path name to uid4nps.jar
  * *Startup TAB*:
   * Class: `uid4nps.userid4nps`
   * Working Path: the directory where the userid4nps log file will be stored
   * Method: `start`
   * Arguments: `-config=userid4nps.cfg`
   * Mode: `jvm`
  * *Shutdown TAB*:
   * Class: `uid4nps.userid4nps`
   * Working Path: the directory where the userid4nps log file will be stored
   * Method: `stop`
   * Arguments: No arguments needed for the `stop` method
   * Timeout: `60`
   * Mode: `jvm`
## Microsoft Network Policy Server (NPS) configuration
MS NPS must be configured to write accounting log records in “DTS compliant” format. The following attributes must be configured (reachable in the NPS console Accounting -> Log File Properties -> Change Log File Properties)
  * *Settings TAB*:
   * Check `Accounting requests`
  * *Log File TAB*:
   * Directory: Choose a exclusive directory for NPS ".log" files (no log files from other applications should be stored in this directory)
   * Format: `DTS Compliant`
## Tips and Tricks
  * Configuration file: If the configuration file doesn’t exist the application will create one with example values
  * Log Levels: The valid log levels in the configuration file are “SEVERE”, “WARNING”, “INFO”, “FINE” and “FINEST”. Use “FINEST” for debugging purposes and “INFO” for normal operations
  * Configuration file escaped chars: The colon char (“:”) must be escaped.
  * Dual FW strategy: The application can establish individual connections with each cluster member. Only FW1 will be used for publishing as far as it is available. FW2 will only be used if FW1 becomes irresponsible falling back to FW1 when it becomes back in service. In cases of single FW or using “in-band” management strategy for the cluster, it is recommended to use the same values for fw1Url & fw2Url as well as fw1PanosKey & fw2PanosKey. If fw2Url & fw2PanosKeys are set to empty or wrong values the application will keep trying to establish connection forever logging connection warning messages.
  * NPS logs: NPS must store its logs as “.log” files into a dedicated directory (no other “.log” files from any other applications should be stored in that directory).